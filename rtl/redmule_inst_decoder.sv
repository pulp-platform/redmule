// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Andrea Belano <andrea.belano2@unibo.it>
//

module redmule_inst_decoder
  import redmule_pkg::*;
#(
  parameter logic [6:0]   McnfigOpCode          = 7'b0001011,
  parameter logic [6:0]   MarithOpCode          = 7'b0001011,
  parameter logic [6:0]   MopcntOpCode          = 7'b0001011,
  parameter logic [2:0]   McnfigFunct3          = 3'b000,
  parameter logic [2:0]   MarithFunct3          = 3'b001,
  parameter logic [2:0]   MopcntFunct3          = 3'b010,
  parameter logic [1:0]   McnfigFunct2          = 2'b00,
  parameter logic [1:0]   MarithFunct2          = 2'b00,
  parameter logic [1:0]   MopcntFunct2          = 2'b00,
  parameter  int unsigned InstFifoDepth         = 4,
  parameter  int unsigned OpIdWidth             = 4,
  parameter  int unsigned XifIdWidth            = 4,
  parameter  int unsigned XifNumHarts           = 1,
  parameter  int unsigned XifIssueRegisterSplit = 0,
  parameter type          x_issue_req_t         = logic,
  parameter type          x_issue_resp_t        = logic,
  parameter type          x_register_t          = logic,
  parameter type          x_commit_t            = logic,
  parameter type          x_result_t            = logic
)(
  input  logic            clk_i,
  input  logic            rst_ni,
  input  logic            clear_i,
  input  logic            config_ready_i,
  input  logic            op_done_i,
  output logic            config_valid_o,
  output redmule_config_t config_o,
  input  x_issue_req_t    x_issue_req_i,
  output x_issue_resp_t   x_issue_resp_o,
  input  logic            x_issue_valid_i,
  output logic            x_issue_ready_o,
  input  x_register_t     x_register_i,
  input  logic            x_register_valid_i,
  output logic            x_register_ready_o,
  input  x_commit_t       x_commit_i,
  input  logic            x_commit_valid_i,
  output x_result_t       x_result_o,
  output logic            x_result_valid_o,
  input  logic            x_result_ready_i
);

  // Calculate the width needed to represent hart IDs (minimum 1 bit)
  localparam int unsigned HartIdWidth = XifNumHarts > 1 ? $clog2(XifNumHarts) : 1;

  // Compose full instruction encoding patterns for the three custom instructions:
  // MCNFIG: Matrix configuration (sets dimensions, data flow control)
  // MARITH: Matrix arithmetic operation (triggers computation with addresses)
  // MOPCNT: Matrix operation count (returns number of completed operations)
  localparam logic [11:0] MCNFIG = {McnfigFunct2,McnfigFunct3,McnfigOpCode};
  localparam logic [11:0] MARITH = {MarithFunct2,MarithFunct3,MarithOpCode};
  localparam logic [11:0] MOPCNT = {MopcntFunct2,MopcntFunct3,MopcntOpCode};

  // Per-hart FIFO status flags for instruction and register packets
  logic [XifNumHarts-1:0] issue_fifo_full,  register_fifo_full,
                          issue_fifo_empty, register_fifo_empty;
  
  // Hart ID of the currently executing operation (tracked through pipeline)
  logic [HartIdWidth-1:0] current_hartid_d, current_hartid_q;

  // Current instruction issue request and register data at head of each hart's FIFO
  x_issue_req_t [XifNumHarts-1:0] cur_issue;
  x_register_t  [XifNumHarts-1:0] cur_register;

  // TODO unused:
  x_result_t                      x_result_d, x_result_q;

  // Per-hart operation ID counters:
  // op_id_counter_in_q:  Increments when operations are issued (tags for tracking)
  // op_id_counter_out_q: Increments when operations complete (for MOPCNT instruction)
  logic [XifNumHarts-1:0] [OpIdWidth-1:0] op_id_counter_in_q, op_id_counter_out_q;

  // Round-robin arbitration state for fair scheduling across harts
  logic [HartIdWidth-1:0]                  rr_counter_d, rr_counter_q;
  logic [XifNumHarts-1:0][HartIdWidth-1:0] rr_priority;
  logic [HartIdWidth-1:0]                  winner;

  // Flag indicating whether the incoming instruction is a recognized RedMule custom instruction
  logic legal_inst;

  // Per-hart configuration registers holding matrix operation parameters
  redmule_config_t [XifNumHarts-1:0] config_d, config_q;

  // Control signal to enable popping from instruction FIFOs (delayed for MARITH until tiler ready)
  logic pop_enable;

  // Decode incoming instruction to determine if it's a legal RedMule custom instruction
  // Checks funct2[26:25], funct3[14:12], and opcode[6:0] fields
  always_comb begin : legal_inst_assignment
    legal_inst = 1'b0;

    unique case ({x_issue_req_i.instr[26:25],x_issue_req_i.instr[14:12],x_issue_req_i.instr[6:0]})
      MCNFIG, MARITH, MOPCNT: legal_inst = 1'b1;
      default: legal_inst = 1'b0;
    endcase
  end

  // Generate XIF issue response indicating whether instruction is accepted and resource needs
  always_comb begin : x_issue_resp_assignment
    // Accept instruction only if it's a legal RedMule custom instruction
    x_issue_resp_o.accept = legal_inst;

    unique case ({x_issue_req_i.instr[26:25],x_issue_req_i.instr[14:12],x_issue_req_i.instr[6:0]})
      MCNFIG: begin
        // MCNFIG: No writeback (configuration only), reads 3 source registers
        x_issue_resp_o.writeback     = 'b0;
        x_issue_resp_o.register_read = 'b111;  // Read rs1, rs2, rs3
      end
      MARITH: begin
        // MARITH: Writeback if rd != x0 (returns operation ID), reads 3 source registers
        x_issue_resp_o.writeback     = x_issue_req_i.instr[11:7] != 0;
        x_issue_resp_o.register_read = 'b111;  // Read rs1, rs2, rs3 (addresses)
      end
      MOPCNT: begin
        // MOPCNT: Writeback if rd != x0 (returns completion count), no register reads
        x_issue_resp_o.writeback     = x_issue_req_i.instr[11:7] != 0;
        x_issue_resp_o.register_read = 'b0;    // No source registers needed
      end
      default: begin
        x_issue_resp_o.writeback     = 'b0;
        x_issue_resp_o.register_read = 'b0;
      end
    endcase
  end


  // Construct result packet to write back to CPU register file
  always_comb begin : x_result_assignment
    // Result valid when both instruction and register data available for winning hart
    x_result_valid_o  = ~issue_fifo_empty[winner] && ~register_fifo_empty[winner];
    x_result_o.hartid = cur_issue[winner].hartid;
    x_result_o.id     = cur_issue[winner].id;
    x_result_o.rd     = cur_issue[winner].instr[11:7];  // Destination register

    unique case ({cur_issue[winner].instr[26:25],cur_issue[winner].instr[14:12],cur_issue[winner].instr[6:0]})
      MCNFIG: begin
        // MCNFIG: No writeback, configuration stored internally
        x_result_o.we   = 'b0;
        x_result_o.data = 'b0;
      end
      MARITH: begin
        // MARITH: Write operation ID to rd (for tracking/synchronization)
        x_result_o.we   = cur_issue[winner].instr[11:7] != 0;
        x_result_o.data = op_id_counter_in_q[winner];
      end
      MOPCNT: begin
        // MOPCNT: Write completion counter to rd (number of finished operations)
        x_result_o.we   = cur_issue[winner].instr[11:7] != 0;
        x_result_o.data = op_id_counter_out_q[winner];
      end
      default: begin
        x_result_o.we   = 'b0;
        x_result_o.data = 'b0;
      end
    endcase
  end

  // Output configuration from the winning hart to the RedMule tiler/controller
  assign config_o = config_d[winner];
  
  // Configuration valid only for MARITH instructions when both FIFOs have data and CPU is ready
  // (MCNFIG updates config but doesn't trigger execution)
  assign config_valid_o = ~issue_fifo_empty[winner] && ~register_fifo_empty[winner] && x_result_ready_i && {cur_issue[winner].instr[26:25],cur_issue[winner].instr[14:12],cur_issue[winner].instr[6:0]} == MARITH;

  // Signal readiness to accept new instruction issue based on target hart's FIFO availability
  always_comb begin : x_issue_ready_assignment
    x_issue_ready_o = 1'b0;

    // Find the hart matching the incoming request and check its issue FIFO status
    for (int unsigned i = 0; i < XifNumHarts; i++) begin
      if (x_issue_req_i.hartid == i) begin
        x_issue_ready_o = ~issue_fifo_full[i];
      end
    end
  end

  // Signal readiness to accept new register packet based on target hart's FIFO availability
  always_comb begin : x_register_ready_assignment
    x_register_ready_o = 1'b0;

    // Find the hart matching the incoming register data and check its register FIFO status
    for (int unsigned i = 0; i < XifNumHarts; i++) begin
      if (x_register_i.hartid == i) begin
        x_register_ready_o = ~register_fifo_full[i];
      end
    end
  end

  // Round-robin counter for fair arbitration across multiple harts
  // Advances each time a configuration is successfully accepted by downstream logic
  always_ff @(posedge clk_i, negedge rst_ni) begin : round_robin_counter
    if(~rst_ni) begin
      rr_counter_q <= '0;
    end else begin
      if (clear_i) begin
        rr_counter_q <= '0;
      end else if (config_ready_i && config_valid_o) begin
        rr_counter_q <= rr_counter_d;
      end
    end
  end

  // Wrap counter to 0 after reaching the last hart
  assign rr_counter_d = rr_counter_q == XifNumHarts-1 ? 0 : rr_counter_q + 1;

  // Calculate priority order for round-robin arbitration
  // Creates a rotated sequence starting from current counter position
  always_comb begin : round_robin_priority
    for(int i = 0; i < XifNumHarts; i++) begin
      rr_priority[i] = (rr_counter_q + i < XifNumHarts) ? rr_counter_q + i : rr_counter_q + i - XifNumHarts;
    end
  end

  // Select winning hart using round-robin priority among harts with ready instructions
  // Scans in priority order and selects first hart with both issue and register data available
  always_comb begin : winner_assignment
    winner = rr_counter_q;  // Default to current counter position

    // Override with first ready hart in priority order
    for(int i = 0; i < XifNumHarts; i++) begin
      if (~issue_fifo_empty[rr_priority[i]] && ~register_fifo_empty[rr_priority[i]]) begin
        winner = rr_priority[i];
      end
    end
  end

  // FIFO tracking which hart each in-flight operation belongs to
  // Pushed when operation starts, popped when operation completes
  // Used to correctly increment the completion counter for MOPCNT instruction
  redmule_config_fifo #(
    .FALL_THROUGH ( 0                           ),
    .DEPTH        ( InstFifoDepth * XifNumHarts ),
    .DATA_WIDTH   ( HartIdWidth                 )
  ) i_current_hartid_fifo (
    .clk_i      ( clk_i                            ),
    .rst_ni     ( rst_ni                           ),
    .flush_i    ( clear_i                          ),
    .testmode_i ( '0                               ),
    .full_o     (                                  ),
    .empty_o    (                                  ),
    .usage_o    (                                  ),
    .data_i     ( winner                           ),          // Push winning hart ID
    .push_i     ( config_ready_i && config_valid_o ),          // On operation issue
    .data_o     ( current_hartid_q                 ),          // Hart of completing op
    .pop_i      ( op_done_i                        )           // On operation completion
  );

  // Per-hart operation ID counters for tracking issued and completed operations
  for (genvar i = 0; i < XifNumHarts; i++) begin : gen_op_id_counters
    // Input counter: increments when MARITH instruction is issued to this hart
    // Returns this value to CPU as operation ID for software tracking
    always_ff @(posedge clk_i or negedge rst_ni) begin : op_id_counter_in
      if (~rst_ni) begin
        op_id_counter_in_q[i] <= 0;
      end else begin
        if (clear_i) begin
          op_id_counter_in_q[i] <= 0;
        end else if (winner == i && x_result_ready_i && x_result_valid_o && {cur_issue[i].instr[26:25],cur_issue[i].instr[14:12],cur_issue[i].instr[6:0]} == MARITH) begin
          op_id_counter_in_q[i] <= op_id_counter_in_q[i] + 1;
        end
      end
    end

    // Output counter: increments when any operation from this hart completes
    // Returns this value for MOPCNT instruction to check completion status
    // Initialized to all 1's to detect first completion (wraps to 0)
    always_ff @(posedge clk_i or negedge rst_ni) begin : op_id_counter_out
      if (~rst_ni) begin
        op_id_counter_out_q[i] <= '1;
      end else begin
        if (clear_i) begin
          op_id_counter_out_q[i] <= '1;
        end else if (current_hartid_q == i && op_done_i) begin
          op_id_counter_out_q[i] <= op_id_counter_out_q[i] + 1;
        end
      end
    end
  end

  // Control when to pop instruction/register FIFOs:
  // - MARITH: delay pop until config accepted by tiler (config_ready_i && config_valid_o)
  // - Others: pop immediately since they don't require tiler resources
  assign pop_enable = ({cur_issue[winner].instr[26:25],cur_issue[winner].instr[14:12],cur_issue[winner].instr[6:0]} == MARITH ? config_ready_i && config_valid_o : 1'b1);

  for (genvar i = 0; i < XifNumHarts; i++) begin : gen_instruction_fifos
    logic [XifIdWidth-1:0] commit_id_d, commit_id_q,
                           kill_id_d, kill_id_q;

    logic commit_id_valid_d, commit_id_valid_q,
          kill_id_valid_d, kill_id_valid_q;

    logic commit_id_valid_flush,
          kill_id_valid_flush;

    logic fifo_flush;

    logic issue_push, register_push,
          issue_pop,  register_pop;

    // Register holding the most recent committed (non-killed) instruction ID for this hart
    // Used to track successful instruction commits from the CPU
    always_ff @(posedge clk_i or negedge rst_ni) begin : commit_id_register
      if (~rst_ni) begin
        commit_id_q <= '0;
      end else begin
        if (clear_i) begin
          commit_id_q <= '0;
        end else begin
          commit_id_q <= commit_id_d;
        end
      end
    end

    // Capture commit ID when a valid, non-killed commit occurs for this hart
    assign commit_id_d = (x_commit_valid_i && ~x_commit_i.commit_kill && x_commit_i.hartid == i) ? x_commit_i.id : commit_id_q;

    // Valid flag for commit_id, indicates whether we have a pending committed instruction
    // Cleared when the matching instruction is popped from FIFO
    always_ff @(posedge clk_i or negedge rst_ni) begin : commid_id_valid_register
      if (~rst_ni) begin
        commit_id_valid_q <= 1'b0;
      end else begin
        if (clear_i || commit_id_valid_flush) begin
          commit_id_valid_q <= 1'b0;
        end else begin
          commit_id_valid_q <= commit_id_valid_d;
        end
      end
    end

    // Set valid when commit arrives, hold until instruction processed
    assign commit_id_valid_d     = (x_commit_valid_i && ~x_commit_i.commit_kill && x_commit_i.hartid == i) ? 1'b1 : commit_id_valid_q;
    // Clear valid flag when the committed instruction is popped from FIFO
    assign commit_id_valid_flush = issue_pop && cur_issue[i].id == commit_id_d && ~issue_fifo_empty[i];

    // Register holding the most recent killed instruction ID for this hart
    // CPU sends kill signal for speculative instructions that should be discarded
    always_ff @(posedge clk_i or negedge rst_ni) begin : kill_id_register
      if (~rst_ni) begin
        kill_id_q <= '0;
      end else begin
        if (clear_i) begin
          kill_id_q <= '0;
        end else begin
          kill_id_q <= kill_id_d;
        end
      end
    end

    // Capture kill ID when a commit with kill flag occurs for this hart
    assign kill_id_d = (x_commit_valid_i && x_commit_i.commit_kill && x_commit_i.hartid == i) ? x_commit_i.id : kill_id_q;

    // Valid flag for kill_id, indicates whether we have a pending kill request
    // Cleared after FIFO flush completes
    always_ff @(posedge clk_i or negedge rst_ni) begin : kill_id_valid_register
      if (~rst_ni) begin
        kill_id_valid_q <= 1'b0;
      end else begin
        if (clear_i || kill_id_valid_flush) begin
          kill_id_valid_q <= 1'b0;
        end else begin
          kill_id_valid_q <= kill_id_valid_d;
        end
      end
    end

    // Set valid when kill arrives, hold until FIFO flushed
    assign kill_id_valid_d       = (x_commit_valid_i && x_commit_i.commit_kill && x_commit_i.hartid == i) ? 1'b1 : kill_id_valid_q;
    // Clear valid flag after FIFO has been flushed
    assign kill_id_valid_flush   = fifo_flush;

    // Trigger FIFO flush when head instruction matches a killed instruction ID
    assign fifo_flush   = cur_issue[i].id == kill_id_d && kill_id_valid_d && ~issue_fifo_empty[i];

    // Push to issue FIFO when: legal instruction, FIFO not full, matches this hart
    assign issue_push   = x_issue_valid_i && legal_inst && ~issue_fifo_full[i] && x_commit_i.hartid == i;
    // Pop from issue FIFO when: this hart wins arbitration, pop enabled, CPU ready, both FIFOs have data
    assign issue_pop    = winner == i && pop_enable && x_result_ready_i && ~issue_fifo_empty[i] && ~register_fifo_empty[i];
    // Register FIFO pops in sync with issue FIFO
    assign register_pop = issue_pop;

    redmule_config_fifo #(
      .FALL_THROUGH ( 0             ),
      .DEPTH        ( InstFifoDepth ),
      .dtype        ( x_issue_req_t )
    ) i_instr_fifo (
      .clk_i      ( clk_i                 ),
      .rst_ni     ( rst_ni                ),
      .flush_i    ( clear_i || fifo_flush ),
      .testmode_i ( '0                    ),
      .full_o     ( issue_fifo_full[i]    ),
      .empty_o    ( issue_fifo_empty[i]   ),
      .usage_o    (                       ),
      .data_i     ( x_issue_req_i         ),
      .push_i     ( issue_push            ),
      .data_o     ( cur_issue[i]          ),
      .pop_i      ( issue_pop             )
    );

    // Non-split mode: register packets arrive synchronously with issue
    if (XifIssueRegisterSplit == 0) begin : gen_register_fifo
      // Push to register FIFO in sync with valid register packet for legal instruction
      assign register_push = x_register_valid_i & legal_inst & x_commit_i.hartid == i;

      redmule_config_fifo #(
        .FALL_THROUGH ( 0             ),
        .DEPTH        ( InstFifoDepth ),
        .dtype        ( x_register_t  )
      ) i_instr_fifo (
        .clk_i      ( clk_i                  ),
        .rst_ni     ( rst_ni                 ),
        .flush_i    ( clear_i || fifo_flush  ),
        .testmode_i ( '0                     ),
        .full_o     ( register_fifo_full[i]  ),
        .empty_o    ( register_fifo_empty[i] ),
        .usage_o    (                        ),
        .data_i     ( x_register_i           ),
        .push_i     ( register_push          ),
        .data_o     ( cur_register[i]        ),
        .pop_i      ( register_pop           )
      );

    end else begin : gen_register_buffer
      // Split mode: register packets may arrive out-of-order relative to issue
      // When an instruction is marked as valid, reserve a slot for the instruction in the buffer
      // The buffer has a number of slots equal to InstFifoDepth
      // TODO: implement out-of-order register packet buffering
    end

    // Configuration register for this hart, holds accumulated matrix operation parameters
    // Updated when instructions are popped (MCNFIG sets params, MARITH uses them)
    always_ff @(posedge clk_i or negedge rst_ni) begin : config_register
      if (~rst_ni) begin
        config_q[i] <= '0;
      end else begin
        if (clear_i) begin
          config_q[i] <= '0;
        end else if (issue_pop) begin
          config_q[i] <= config_d[i];
        end
      end
    end

    // Decode instruction and extract configuration parameters from register file values
    always_comb begin : config_assignment
      config_d[i] = config_q[i];  // Default: retain previous configuration

      unique case ({cur_issue[i].instr[26:25],cur_issue[i].instr[14:12],cur_issue[i].instr[6:0]})
        MCNFIG: begin
          // Matrix configuration: extract dimensions and data flow control from rs1, rs2, rs3
          config_d[i].m_size          = cur_register[i].rs[0][15:0];   // M dimension (rows of X/Z)
          config_d[i].n_size          = cur_register[i].rs[1][15:0];   // N dimension (cols of W/Z)
          config_d[i].k_size          = cur_register[i].rs[0][31:16];  // K dimension (cols of X, rows of W)
          config_d[i].receive_x       = cur_register[i].rs[1][16];     // Receive X from external stream
          config_d[i].send_x          = cur_register[i].rs[1][17];     // Broadcast X to external stream
          config_d[i].receive_w       = cur_register[i].rs[1][18];     // Receive W from external stream
          config_d[i].send_w          = cur_register[i].rs[1][19];     // Broadcast W to external stream
          config_d[i].gemm_ops        = cur_register[i].rs[1][20] ? MATMUL : GEMM;
          config_d[i].y_offs          = cur_register[i].rs[2][31:0];   // Y buffer offset for bias addition
        end
        MARITH: begin
          // Matrix arithmetic: extract memory addresses from rs1, rs2, rs3
          config_d[i].x_addr          = cur_register[i].rs[0][31:0];   // X matrix base address
          config_d[i].w_addr          = cur_register[i].rs[1][31:0];   // W matrix base address
          config_d[i].z_addr          = cur_register[i].rs[2][31:0];   // Z matrix base address (output)
          // TODO: These operation parameters are fixed for now, could be made configurable
          config_d[i].gemm_input_fmt  = redmule_pkg::Float16;
          config_d[i].gemm_output_fmt = redmule_pkg::Float16;
        end
        default: config_d[i] = config_q[i];  // Other instructions don't modify config
      endcase
    end
  end

endmodule: redmule_inst_decoder
