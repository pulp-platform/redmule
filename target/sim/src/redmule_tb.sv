// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
//
// Memory-mapped (HWPE-target) RedMulE testbench: a CV32E40P core configures
// RedMulE through the RDL-generated register file and shares the TCDM data
// memory with it. RedMulE is instantiated via redmule_mm_wrap, which exposes a
// modern hci_core_intf TCDM initiator and a hwpe_ctrl_intf_periph register slave.
//

timeunit 1ps; timeprecision 1ps;

import hci_package::*;

module redmule_tb
  import redmule_pkg::*;
#(
  parameter TCP = 1.0ns, // clock period, 1 GHz clock
  parameter TA  = 0.2ns, // application time
  parameter TT  = 0.8ns,  // test time
  parameter int unsigned Height = 8,
  parameter int unsigned Width  = 8,
  parameter bit EnableReordering = 1'b0,
  parameter int unsigned RobSlots = 16,
  parameter real  PROB_STALL    = 0.0
)(
  input logic clk_i,
  input logic rst_ni,
  input logic fetch_enable_i
);

  // parameters
  localparam int unsigned NC = 1;
  localparam int unsigned ID = 4; // matches the OpIdWidth used inside redmule_top's target decoder
  // The datapath/TCDM width is constrained by the array Height by the tiler invariant
  // DataW == Height*(NumPipeRegs+1)*16 (rtl/redmule_tiler.sv).
  localparam int unsigned NumPipeRegs  = 1; // drives both the derivation and the wrapper port
  localparam int unsigned RedmuleDataW = Height*(NumPipeRegs+1)*16; // = D*16
  localparam int unsigned DW = RedmuleDataW + 32; // TCDM data width including MisalignedAccessSupport=1 (+32b word)
  localparam int unsigned MP = DW/32;
  localparam int unsigned UW = EnableReordering ? $clog2(RobSlots) : hci_package::DEFAULT_UW;
  localparam int unsigned UserFifoDepth = 1 << UW;
  // HCI size parameter for RedMulE's TCDM port. It must be forwarded to
  // redmule_mm_wrap (redmule_top forwards it verbatim to the streamer, with no
  // fallback), otherwise the internal OoO multiplexer sees BW=0 and fails to
  // elaborate. The `redmule_tcdm` interface below must match these dimensions.
  // When reordering is enabled, widen UW so the HCI-side ROB can track more
  // outstanding transactions (ROB_NW = 2**UW in rtl/redmule_streamer.sv).
  localparam hci_size_parameter_t HciSizeTcdm = '{
    DW:  DW,
    AW:  hci_package::DEFAULT_AW,
    BW:  hci_package::DEFAULT_BW,
    UW:  UW,
    IW:  hci_package::DEFAULT_IW,
    EW:  hci_package::DEFAULT_EW,
    EHW: hci_package::DEFAULT_EHW
  };
  localparam int unsigned MEMORY_SIZE = 192*1024;
  localparam int unsigned STACK_MEMORY_SIZE = 192*1024;
  localparam int unsigned PULP_XPULP = 1;
  localparam int unsigned FPU = 0;
  localparam int unsigned PULP_ZFINX = 0;
  localparam logic [31:0] BASE_ADDR = 32'h1c000000;
  localparam logic [31:0] HWPE_ADDR_BASE_BIT = 20;

  // global signals
  string stim_instr, stim_data;
  logic test_mode;
  logic [31:0] core_boot_addr;
  logic redmule_busy;
  logic redmule_evt;

  hwpe_stream_intf_tcdm instr[0:0]  (.clk(clk_i));
  hwpe_stream_intf_tcdm stack[0:0]  (.clk(clk_i));
  hwpe_stream_intf_tcdm tcdm [MP:0] (.clk(clk_i));

  // RedMulE modern interfaces
  hci_core_intf #(
    .DW ( DW ),
    .UW ( UW )
  ) redmule_tcdm (.clk(clk_i));
  hwpe_ctrl_intf_periph #(.ID_WIDTH(ID)) periph      (.clk(clk_i));

  logic [MP-1:0]       tcdm_gnt;
  logic [MP-1:0][31:0] tcdm_r_data;
  logic [MP-1:0]       tcdm_r_valid;
  typedef logic [hci_package::iomsb(UW):0] hci_user_t;
  typedef logic [hci_package::iomsb(hci_package::DEFAULT_IW):0] hci_id_t;
  hci_user_t user_fifo_rdata;
  hci_id_t id_fifo_rdata;
  logic user_fifo_full, user_fifo_empty;
  logic [$clog2(UserFifoDepth)-1:0] user_fifo_usage;
  logic id_fifo_full, id_fifo_empty;
  logic [$clog2(UserFifoDepth)-1:0] id_fifo_usage;
  logic redmule_req_fire, redmule_rsp_fire;

  logic          instr_req;
  logic          instr_gnt;
  logic          instr_rvalid;
  logic [31:0]   instr_addr;
  logic [31:0]   instr_rdata;

  logic          data_req;
  logic          data_gnt;
  logic          data_rvalid;
  logic          data_we;
  logic [3:0]    data_be;
  logic [31:0]   data_addr;
  logic [31:0]   data_wdata;
  logic [31:0]   data_rdata;
  logic          data_err;
  logic          core_sleep;

  // Register-file (peripheral) port: the core drives the master side of `periph`.
  always_comb begin : bind_periph
    periph.req  = data_req & data_addr[HWPE_ADDR_BASE_BIT];
    periph.add  = data_addr;
    periph.wen  = ~data_we;
    periph.be   = data_be;
    periph.data = data_wdata;
    periph.id   = '0;
  end

  always_comb begin : bind_instrs
    instr[0].req  = instr_req;
    instr[0].add  = instr_addr;
    instr[0].wen  = 1'b1;
    instr[0].be   = '0;
    instr[0].data = '0;
    instr_gnt    = instr[0].gnt;
    instr_rdata  = instr[0].r_data;
    instr_rvalid = instr[0].r_valid;
  end

  always_comb begin : bind_stack
    stack[0].req  = data_req & (data_addr[31:24] == '0) & ~data_addr[HWPE_ADDR_BASE_BIT];
    stack[0].add  = data_addr;
    stack[0].wen  = ~data_we;
    stack[0].be   = data_be;
    stack[0].data = data_wdata;
  end

  logic other_r_valid;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni)
      other_r_valid <= '0;
    else
      other_r_valid <= data_req & (data_addr[31:24] == 8'h80);
  end

  // RedMulE TCDM initiator fanned out over MP word-wide banks of the data memory.
  for(genvar ii=0; ii<MP; ii++) begin : tcdm_binding
    assign tcdm[ii].req  = redmule_tcdm.req;
    assign tcdm[ii].add  = redmule_tcdm.add + ii*4;
    assign tcdm[ii].wen  = redmule_tcdm.wen;
    assign tcdm[ii].be   = redmule_tcdm.be[(ii+1)*4-1:ii*4];
    assign tcdm[ii].data = redmule_tcdm.data[(ii+1)*32-1:ii*32];
    assign tcdm_gnt     [ii] = tcdm[ii].gnt;
    assign tcdm_r_data  [ii] = tcdm[ii].r_data;
    assign tcdm_r_valid [ii] = tcdm[ii].r_valid;
  end
  assign redmule_tcdm.gnt     = &tcdm_gnt;
  assign redmule_tcdm.r_data  = { >> {tcdm_r_data} };
  assign redmule_tcdm.r_valid = &tcdm_r_valid;
  assign redmule_tcdm.r_opc   = '0;
  assign redmule_tcdm.r_user  = user_fifo_rdata;
  assign redmule_tcdm.r_id    = id_fifo_rdata;
  assign redmule_req_fire     = redmule_tcdm.req & redmule_tcdm.gnt;
  assign redmule_rsp_fire     = redmule_tcdm.r_valid & redmule_tcdm.r_ready;

  fifo_v3 #(
    .FALL_THROUGH ( 1'b0          ),
    .DEPTH        ( UserFifoDepth ),
    .dtype        ( hci_user_t    )
  ) i_user_fifo (
    .clk_i      ( clk_i                ),
    .rst_ni     ( rst_ni               ),
    .flush_i    ( 1'b0                 ),
    .testmode_i ( 1'b0                 ),
    .full_o     ( user_fifo_full       ),
    .empty_o    ( user_fifo_empty      ),
    .usage_o    ( user_fifo_usage      ),
    .data_i     ( redmule_tcdm.user    ),
    .push_i     ( redmule_req_fire     ),
    .data_o     ( user_fifo_rdata      ),
    .pop_i      ( redmule_rsp_fire     )
  );

  fifo_v3 #(
    .FALL_THROUGH ( 1'b0          ),
    .DEPTH        ( UserFifoDepth ),
    .dtype        ( hci_id_t      )
  ) i_id_fifo (
    .clk_i      ( clk_i             ),
    .rst_ni     ( rst_ni            ),
    .flush_i    ( 1'b0              ),
    .testmode_i ( 1'b0              ),
    .full_o     ( id_fifo_full      ),
    .empty_o    ( id_fifo_empty     ),
    .usage_o    ( id_fifo_usage     ),
    .data_i     ( redmule_tcdm.id   ),
    .push_i     ( redmule_req_fire  ),
    .data_o     ( id_fifo_rdata     ),
    .pop_i      ( redmule_rsp_fire  )
  );

  // Core data-side port (last bank of the data memory).
  assign tcdm[MP].req  = data_req & (data_addr[31:24] != '0) & (data_addr[31:24] != 8'h80) & ~data_addr[HWPE_ADDR_BASE_BIT];
  assign tcdm[MP].add  = data_addr;
  assign tcdm[MP].wen  = ~data_we;
  assign tcdm[MP].be   = data_be;
  assign tcdm[MP].data = data_wdata;

  assign data_gnt    = periph.req ?
                       periph.gnt : stack[0].req ?
                                    stack[0].gnt : tcdm[MP].req ?
                                                   tcdm[MP].gnt : '1;
  assign data_rdata  = periph.r_valid ? periph.r_data  :
                                        stack[0].r_valid ? stack[0].r_data  :
                                                           tcdm[MP].r_valid ? tcdm[MP].r_data : '0;
  assign data_rvalid = periph.r_valid   |
                       stack[0].r_valid |
                       tcdm[MP].r_valid |
                       other_r_valid    ;

  redmule_mm_wrap #(
    .HCI_SIZE_tcdm           ( HciSizeTcdm              ),
    .DataW                   ( RedmuleDataW             ),
    .MisalignedAccessSupport ( EnableReordering ? 0 : 1 ),
    .EnableReordering        ( EnableReordering         ),
    .Height                  ( Height                   ),
    .Width                   ( Width                    ),
    .NumPipeRegs             ( NumPipeRegs              )
  ) i_redmule_wrap (
    .clk_i       ( clk_i        ),
    .rst_ni      ( rst_ni       ),
    .test_mode_i ( test_mode    ),
    .busy_o      ( redmule_busy ),
    .evt_o       ( redmule_evt  ),
    .sync_o      (              ),
    .sync_i      ( 1'b0         ),
    .tcdm        ( redmule_tcdm ),
    .target      ( periph       )
  );

  tb_dummy_memory  #(
    .MP             ( MP + 1        ),
    .MEMORY_SIZE    ( MEMORY_SIZE   ),
    .BASE_ADDR      ( 32'h1c010000  ),
    .PROB_STALL     ( PROB_STALL    ),
    .TCP            ( TCP           ),
    .TA             ( TA            ),
    .TT             ( TT            )
  ) i_dummy_dmemory (
    .clk_i          ( clk_i         ),
    .rst_ni         ( rst_ni        ),
    .clk_delayed_i  ( '0            ),
    .randomize_i    ( 1'b0          ),
    .enable_i       ( 1'b1          ),
    .stallable_i    ( 1'b1          ),
    .tcdm           ( tcdm          )
  );

  tb_dummy_memory  #(
    .MP             ( 1           ),
    .MEMORY_SIZE    ( MEMORY_SIZE ),
    .BASE_ADDR      ( BASE_ADDR   ),
    .PROB_STALL     ( 0           ),
    .TCP            ( TCP         ),
    .TA             ( TA          ),
    .TT             ( TT          )
  ) i_dummy_imemory (
    .clk_i          ( clk_i       ),
    .rst_ni         ( rst_ni      ),
    .clk_delayed_i  ( '0          ),
    .randomize_i    ( 1'b0        ),
    .enable_i       ( 1'b1        ),
    .stallable_i    ( 1'b0        ),
    .tcdm           ( instr       )
  );

  tb_dummy_memory       #(
    .MP                  ( 1                 ),
    .MEMORY_SIZE         ( STACK_MEMORY_SIZE ),
    .BASE_ADDR           ( BASE_ADDR         ),
    .PROB_STALL          ( 0                 ),
    .TCP                 ( TCP               ),
    .TA                  ( TA                ),
    .TT                  ( TT                )
  ) i_dummy_stack_memory (
    .clk_i               ( clk_i             ),
    .rst_ni              ( rst_ni            ),
    .clk_delayed_i       ( '0                ),
    .randomize_i         ( 1'b0              ),
    .enable_i            ( 1'b1              ),
    .stallable_i         ( 1'b0              ),
    .tcdm                ( stack             )
  );

  cv32e40p_core #(
    .PULP_XPULP     ( PULP_XPULP ),
    .FPU            ( FPU        ),
    .PULP_ZFINX     ( PULP_ZFINX )
  ) i_cv32e40p_core (
    // Clock and Reset
    .clk_i               ( clk_i          ),
    .rst_ni              ( rst_ni         ),
    .pulp_clock_en_i     ( 1'b1           ),  // PULP clock enable (only used if PULP_CLUSTER = 1)
    .scan_cg_en_i        ( 1'b0           ),  // Enable all clock gates for testing
    // Core ID, Cluster ID, debug mode halt address and boot address are considered more or less static
    .boot_addr_i         ( core_boot_addr ),
    .mtvec_addr_i        ( '0             ),
    .dm_halt_addr_i      ( '0             ),
    .hart_id_i           ( '0             ),
    .dm_exception_addr_i ( '0             ),
    // Instruction memory interface
    .instr_req_o         ( instr_req    ),
    .instr_gnt_i         ( instr_gnt    ),
    .instr_rvalid_i      ( instr_rvalid ),
    .instr_addr_o        ( instr_addr   ),
    .instr_rdata_i       ( instr_rdata  ),
    // Data memory interface
    .data_req_o          ( data_req     ),
    .data_gnt_i          ( data_gnt     ),
    .data_rvalid_i       ( data_rvalid  ),
    .data_we_o           ( data_we      ),
    .data_be_o           ( data_be      ),
    .data_addr_o         ( data_addr    ),
    .data_wdata_o        ( data_wdata   ),
    .data_rdata_i        ( data_rdata   ),
    // apu-interconnect
    // handshake signals
    .apu_req_o           (              ),
    .apu_gnt_i           ( '0           ),
    // request channel
    .apu_operands_o      (              ),
    .apu_op_o            (              ),
    .apu_flags_o         (              ),
    // response channel
    .apu_rvalid_i        ( '0           ),
    .apu_result_i        ( '0           ),
    .apu_flags_i         ( '0           ),
    // Interrupt inputs
    .irq_i               ({28'd0, redmule_evt, 3'd0}),  // CLINT interrupts + CLINT extension interrupts
    .irq_ack_o           (              ),
    .irq_id_o            (              ),
    // Debug Interface
    .debug_req_i         ( '0           ),
    .debug_havereset_o   (              ),
    .debug_running_o     (              ),
    .debug_halted_o      (              ),
    // CPU Control Signals
    .fetch_enable_i      ( fetch_enable_i ),
    .core_sleep_o        ( core_sleep     )
  );

  integer f_x, f_W, f_y, f_tau;
  logic start;
  int cnt_rd, cnt_wr;
  int unsigned cnt_cycles;

  always_ff @(posedge clk_i or negedge rst_ni)
  begin
    if(~rst_ni)
      cnt_cycles <= 0;
    else if(redmule_busy)
      cnt_cycles <= cnt_cycles + 1;
  end

  int errors = -1;
  always_ff @(posedge clk_i)
  begin
    if((data_addr == 32'h80000000 ) && (data_we & data_req == 1'b1)) begin
      errors = data_wdata;
    end
    if((data_addr == 32'h80000004 ) && (data_we & data_req == 1'b1)) begin
      $write("%c", data_wdata);
    end
  end

  initial begin

    if (!$value$plusargs("STIM_INSTR=%s", stim_instr)) stim_instr = "../../../sw/build/stim_instr.txt";
    if (!$value$plusargs("STIM_DATA=%s", stim_data)) stim_data = "../../../sw/build/stim_data.txt";
    $display("Height = %d", Height);
    $display("Width = %d", Width);
    $display("EnableReordering = %0d", EnableReordering);
    $display("RobSlots = %0d", RobSlots);
    $display("PROB_STALL = %f", PROB_STALL);

    test_mode = 1'b0;
    core_boot_addr = 32'h1C000084;

    // Load instruction and data memory
    $readmemh(stim_instr, redmule_tb.i_dummy_imemory.memory);
    $readmemh(stim_data,  redmule_tb.i_dummy_dmemory.memory);

    // End: WFI + returned != -1 signals end-of-computation
    while(~core_sleep || errors==-1) @(posedge clk_i);
    cnt_rd = 0;
    cnt_wr = 0;
    for (int i=0; i<=MP; i++) begin
      cnt_rd += redmule_tb.i_dummy_dmemory.cnt_rd[i];
      cnt_wr += redmule_tb.i_dummy_dmemory.cnt_wr[i];
    end
    $display("[TB] - cnt_rd=%-8d", cnt_rd);
    $display("[TB] - cnt_wr=%-8d", cnt_wr);
    $display("# hwpe cycles = %0d", cnt_cycles);
    if(errors != 0) begin
      $display("[TB] - Fail!");
      $error("[TB] - errors=%08x", errors);
    end else begin
      $display("[TB] - Success!");
      $display("[TB] - errors=%08x", errors);
    end
    $finish;
  end

endmodule // redmule_tb
