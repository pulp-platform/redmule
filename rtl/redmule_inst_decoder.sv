// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Andrea Belano <andrea.belano2@unibo.it>
//

module redmule_inst_decoder
  import redmule_pkg::*;
  import cv32e40x_pkg::*;
#(
  parameter  int unsigned InstFifoDepth         = 4,
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
  input  logic            busy_i,
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

  localparam int unsigned HartIdWidth = XifNumHarts > 1 ? $clog2(XifNumHarts) : 1;

  logic [XifNumHarts-1:0] issue_fifo_full,  register_fifo_full,
                          issue_fifo_empty, register_fifo_empty;
  logic [HartIdWidth-1:0] current_hartid_d, current_hartid_q;

  x_issue_req_t [XifNumHarts-1:0] cur_issue;
  x_register_t  [XifNumHarts-1:0] cur_register;

  logic [HartIdWidth-1:0]                  rr_counter_d, rr_counter_q;
  logic [XifNumHarts-1:0][HartIdWidth-1:0] rr_priority;
  logic [HartIdWidth-1:0]                  winner;

  logic legal_inst;

  redmule_config_t [XifNumHarts-1:0] config_d, config_q;

  always_comb begin : legal_inst_assignment
    legal_inst = 1'b0;

    unique case (x_issue_req_i.instr[6:0])
      MCNFIG, MARITH: legal_inst = 1'b1;
      default: legal_inst = 1'b0;
    endcase
  end

  assign x_issue_resp_o.accept        = legal_inst;
  assign x_issue_resp_o.writeback     = '0; // We never perform writebacks
  assign x_issue_resp_o.register_read = 7;  // We always read 3 registers

  assign x_result_valid_o  = ~issue_fifo_empty[winner] && ~register_fifo_empty[winner] && x_result_ready_i;
  assign x_result_o.hartid = cur_issue[winner].hartid;
  assign x_result_o.id     = cur_issue[winner].id;
  assign x_result_o.data   = '0;
  assign x_result_o.rd     = '0;
  assign x_result_o.we     = '0;

  assign config_o = config_d[winner];
  assign config_valid_o = ~issue_fifo_empty[winner] && ~register_fifo_empty[winner] && x_result_ready_i && cur_issue[winner].instr[6:0] == MARITH;

  always_comb begin : x_issue_ready_assignment
    x_issue_ready_o = 1'b0;

    for (int unsigned i = 0; i < XifNumHarts; i++) begin
      if (x_issue_req_i.hartid == i) begin
        x_issue_ready_o = ~issue_fifo_full[i];
      end
    end
  end

  always_comb begin : x_register_ready_assignment
    x_register_ready_o = 1'b0;

    for (int unsigned i = 0; i < XifNumHarts; i++) begin
      if (x_register_i.hartid == i) begin
        x_register_ready_o = ~register_fifo_full[i];
      end
    end
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin : round_robin_counter
    if(~rst_ni) begin
      rr_counter_q <= '0;
    end else begin
      if (clear_i) begin
        rr_counter_q <= '0;
      end else if (~busy_i && |(~issue_fifo_empty & ~register_fifo_empty)) begin
        rr_counter_q <= rr_counter_d;
      end
    end
  end

  assign rr_counter_d = rr_counter_q == XifNumHarts-1 ? 0 : rr_counter_q + 1;

  always_comb begin : round_robin_priority
    for(int i = 0; i < XifNumHarts; i++) begin
      rr_priority[i] = (rr_counter_q + i < XifNumHarts) ? rr_counter_q + i : rr_counter_q + i - XifNumHarts;
    end
  end

  always_comb begin : winner_assignment
    winner = rr_counter_q;

    for(int i = 0; i < XifNumHarts; i++) begin
      if (~issue_fifo_empty[rr_priority[i]] && ~register_fifo_empty[rr_priority[i]]) begin
        winner = rr_priority[i];
      end
    end
  end

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

    assign commit_id_d = (x_commit_valid_i && ~x_commit_i.commit_kill && x_commit_i.hartid == i) ? x_commit_i.id : commit_id_q;

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

    assign commit_id_valid_d     = (x_commit_valid_i && ~x_commit_i.commit_kill && x_commit_i.hartid == i) ? 1'b1 : commit_id_valid_q;
    assign commit_id_valid_flush = issue_pop && cur_issue[i].id == commit_id_d && ~issue_fifo_empty[i];

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

    assign kill_id_d = (x_commit_valid_i && x_commit_i.commit_kill && x_commit_i.hartid == i) ? x_commit_i.id : kill_id_q;

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

    assign kill_id_valid_d       = (x_commit_valid_i && x_commit_i.commit_kill && x_commit_i.hartid == i) ? 1'b1 : kill_id_valid_q;
    assign kill_id_valid_flush   = fifo_flush;

    assign fifo_flush   = cur_issue[i].id == kill_id_d && kill_id_valid_d && ~issue_fifo_empty[i];

    assign issue_push   = x_issue_valid_i & legal_inst & x_commit_i.hartid == i;
    assign issue_pop    = winner == i && ~busy_i && x_result_ready_i && ~issue_fifo_empty[i] && ~register_fifo_empty[i];
    assign register_pop = issue_pop;

    fifo_v3 #(
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

    if (XifIssueRegisterSplit == 0) begin : gen_register_fifo // Register packets are guaranteed to arrive at the same time as the issue signal
      assign register_push = x_register_valid_i & legal_inst & x_commit_i.hartid == i;

      fifo_v3 #(
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
        .data_o     ( cur_register[i]           ),
        .pop_i      ( register_pop           )
      );

    end else begin : gen_register_buffer // If register split is enabled, we could receive register packets out of order
      // When an instruction is marked as valid, reserve a slot for the instruction in the buffer

      // The buffer has a number of slots equal to InstFifoDepth

      $fatal("Not yet implemented!!!!");
    end

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

    always_comb begin : config_assignment
      config_d[i] = config_q[i];

      unique case (cur_issue[i].instr[6:0])
        MCNFIG: begin
          config_d[i].m_size = cur_register[i].rs[0][15:0];
          config_d[i].n_size = cur_register[i].rs[1][31:0];
          config_d[i].k_size = cur_register[i].rs[0][31:16];
        end
        MARITH: begin
          config_d[i].x_addr        = cur_register[i].rs[0][31:0];
          config_d[i].w_addr        = cur_register[i].rs[1][31:0];
          config_d[i].z_addr        = cur_register[i].rs[2][31:0];
          config_d[i].pace_in_addr  = cur_register[i].rs[1][31:0];
          config_d[i].pace_out_addr = cur_register[i].rs[2][31:0];
          // assign config_d[i].pace_tot_len   = reg_file_i.hwpe_params[MCFIG0][31:16] / (DATAW/BITW); FIXME this is K SIZE
          // config_d[i].pace_mode      = reg_file_i.hwpe_params[MACFG][13]; FIXME
          // config_d[i].pace_in_addr   = reg_file_i.hwpe_params[W_ADDR];
          // config_d[i].pace_out_addr  = reg_file_i.hwpe_params[Z_ADDR];
          // assign config_d[i].r_addr          = reg_file_i.hwpe_params[R_ADDR_R];  FIXME
          // assign config_d[i].red_init        = reg_file_i.hwpe_params[MACFG][16];  FIXME
          // assign config_d[i].red_op          = red_op_t'(reg_file_i.hwpe_params[MACFG][15:14]);    FIXME
          config_d[i].gemm_ops        = cur_issue[i].instr[12:10];
          config_d[i].gemm_input_fmt  = cur_issue[i].instr[ 9: 7];
          config_d[i].gemm_output_fmt = cur_issue[i].instr[ 9: 7];
          config_d[i].receive_x       = cur_issue[i].instr[13];
          config_d[i].send_x          = cur_issue[i].instr[14];
          config_d[i].receive_w       = cur_issue[i].instr[25];
          config_d[i].send_w          = cur_issue[i].instr[26];
        end
      endcase
    end
  end

endmodule: redmule_inst_decoder
