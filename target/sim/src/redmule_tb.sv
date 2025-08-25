// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
//

timeunit 1ps; timeprecision 1ps;

import hci_package::*;

module redmule_tb
  import redmule_pkg::*;
#(
  parameter TCP = 1.0ns, // clock period, 1 GHz clock
  parameter TA  = 0.2ns, // application time
  parameter TT  = 0.8ns,  // test time
  parameter logic UseXif = 1'b0,
  parameter real  PROB_STALL = 0
)(
  input logic clk_i,
  input logic rst_ni,
  input logic fetch_enable_i
);

  // parameters
  localparam int unsigned NC = 1;
  localparam int unsigned ID = 10;
  localparam int unsigned DW = redmule_pkg::DATA_W;
  localparam int unsigned UW = redmule_pkg::USER_W;
  localparam int unsigned IW = redmule_pkg::ID_W;
  localparam int unsigned MP = DW/32;
  localparam int unsigned MEMORY_SIZE = 192*1024;
  localparam int unsigned STACK_MEMORY_SIZE = 192*1024;
  localparam int unsigned PULP_XPULP = 1;
  localparam int unsigned FPU = 0;
  localparam int unsigned PULP_ZFINX = 0;
  localparam logic [31:0] BASE_ADDR = 32'h1c000000;
  localparam logic [31:0] HWPE_ADDR_BASE_BIT = 20;
  localparam bit          USE_ECC = 0;
  localparam int unsigned EW = (USE_ECC) ? 72 : DEFAULT_EW;
  localparam redmule_pkg::core_type_e CoreType = UseXif ? redmule_pkg::CV32X
                                                        : redmule_pkg::CV32P;

  localparam hci_package::hci_size_parameter_t HciRedmuleSize = '{
    DW:  DW,
    AW:  hci_package::DEFAULT_AW,
    BW:  hci_package::DEFAULT_BW,
    UW:  UW,
    IW:  IW,
    EW:  EW,
    EHW: hci_package::DEFAULT_EHW,
    default: '0
  };

  // global signals
  string stim_instr, stim_data, stack_init;
  logic test_mode;
  logic [31:0] core_boot_addr;
  logic redmule_busy;
  logic scan_cg_en;

  hwpe_stream_intf_tcdm instr[0:0]  (.clk(clk_i));
  hwpe_stream_intf_tcdm stack[0:0]  (.clk(clk_i));
  hwpe_stream_intf_tcdm tcdm [MP:0] (.clk(clk_i));

  logic [NC-1:0][1:0]  evt;
  logic [MP-1:0]       tcdm_gnt;
  logic [MP-1:0][31:0] tcdm_r_data;
  logic [MP-1:0]       tcdm_r_valid;
  logic [IW-1:0]       tcdm_r_id;
  logic [UW-1:0]       tcdm_r_user;

  typedef struct packed {
    logic        req;
    logic [31:0] addr;
  } core_inst_req_t;

  typedef struct packed {
    logic        gnt;
    logic        valid;
    logic [31:0] data;
  } core_inst_rsp_t;

  typedef struct packed {
    logic req;
    logic we;
    logic [3:0] be;
    logic [31:0] addr;
    logic [31:0] data;
  } core_data_req_t;

  typedef struct packed {
    logic gnt;
    logic valid;
    logic [31:0] data;
  } core_data_rsp_t;

  hci_outstanding_intf #(
  	.DW(DW),
  	.UW(3) ) redmule_tcdm (.clk(clk_i));

  core_inst_req_t core_inst_req;
  core_inst_rsp_t core_inst_rsp;

  core_data_req_t core_data_req;
  core_data_rsp_t core_data_rsp;

  always_comb begin : bind_instrs
    instr[0].req  = core_inst_req.req;
    instr[0].add  = core_inst_req.addr;
    instr[0].wen  = 1'b1;
    instr[0].be   = '0;
    instr[0].data = '0;
    core_inst_rsp.gnt   = instr[0].gnt;
    core_inst_rsp.valid = instr[0].r_valid;
    core_inst_rsp.data  = instr[0].r_data;
  end

  always_comb begin : bind_stack
    stack[0].req  = core_data_req.req & (core_data_req.addr[31:16] == 16'h1c04) &
                    ~core_data_req.addr[HWPE_ADDR_BASE_BIT];
    stack[0].add  = core_data_req.addr;
    stack[0].wen  = ~core_data_req.we;
    stack[0].be   = core_data_req.be;
    stack[0].data = core_data_req.data;
  end

  logic other_r_valid;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      other_r_valid <= '0;
      tcdm_r_user <= '0;
      tcdm_r_id   <= '0;
    end else begin
      other_r_valid <= core_data_req.req & (core_data_req.addr[31:24] == 8'h80);
  	  tcdm_r_user <= redmule_tcdm.req_user;
  	  tcdm_r_id   <= redmule_tcdm.req_id;
  	end 
  end

  for(genvar ii=0; ii<MP; ii++) begin : tcdm_binding
    assign tcdm[ii].req  = redmule_tcdm.req_valid;
    assign tcdm[ii].add  = redmule_tcdm.req_add + ii*4;
    assign tcdm[ii].wen  = redmule_tcdm.req_wen;
    assign tcdm[ii].be   = redmule_tcdm.req_be[(ii+1)*4-1:ii*4];
    assign tcdm_gnt[ii]     = tcdm[ii].gnt;
    assign tcdm_r_valid[ii] = tcdm[ii].r_valid;
    assign tcdm_r_data[ii]  = tcdm[ii].r_data;
  end
  assign redmule_tcdm.req_ready  = &tcdm_gnt;
  assign redmule_tcdm.resp_data  = { >> {tcdm_r_data} };
  assign redmule_tcdm.resp_valid = &tcdm_r_valid;
  assign redmule_tcdm.resp_id    = tcdm_r_id;
  assign redmule_tcdm.resp_opc   = '0;
  assign redmule_tcdm.resp_user  = tcdm_r_user;

  if (USE_ECC) begin : gen_ecc
    logic [EW-1:0] tcdm_r_ecc;
    // RESPONSE PHASE ENCODING
    logic [MP-1:0][38:0] tcdm_r_data_enc;
    for(genvar ii=0; ii<MP; ii++) begin : gen_rdata_encoders
      hsiao_ecc_enc #(
        .DataWidth ( 32 )
      ) i_r_data_enc (
        .in  (tcdm_r_data[ii]),
        .out (tcdm_r_data_enc[ii])
      );
      assign tcdm_r_ecc[(ii+1)*7-1:ii*7] = tcdm_r_data_enc[ii][38:32];
    end
    assign tcdm_r_ecc[EW-1:(7*MP)] = '0;
    assign redmule_tcdm.r_ecc  = tcdm_r_ecc;

    // REQUEST PHASE DECODING
    for(genvar ii=0; ii<MP; ii++) begin : gen_data_decoders
      hsiao_ecc_dec #(
        .DataWidth ( 32 )
      ) i_data_dec (
        .in         ( { redmule_tcdm.ecc[(ii+1)*7-1+9:ii*7+9], redmule_tcdm.data[(ii+1)*32-1:ii*32] } ),
        .out        ( tcdm[ii].data ),
        .syndrome_o ( ),
        .err_o      ( )
      );
    end

    // FixMe: How should we drive these?
    // assign redmule_tcdm.egnt = '1;
    // assign redmule_tcdm.r_evalid = '0;

  end else begin: gen_no_ecc
    for(genvar ii=0; ii<MP; ii++)
      assign tcdm[ii].data = redmule_tcdm.req_data[(ii+1)*32-1:ii*32];

  end

  assign tcdm[MP].req  = core_data_req.req &
                         (core_data_req.addr[31:24] != '0) &
                         (core_data_req.addr[31:24] != 8'h80) &
                         ~core_data_req.addr[HWPE_ADDR_BASE_BIT];
  assign tcdm[MP].add  = core_data_req.addr;
  assign tcdm[MP].wen  = ~core_data_req.we;
  assign tcdm[MP].be   = core_data_req.be;
  assign tcdm[MP].data = core_data_req.data;

  assign core_data_rsp.gnt = stack[0].req ?
                             stack[0].gnt : tcdm[MP].req ?
                                            tcdm[MP].gnt : '1;

  assign core_data_rsp.data = stack[0].r_valid ? stack[0].r_data  :
                                                 tcdm[MP].r_valid ? tcdm[MP].r_data : '0;
  assign core_data_rsp.valid = stack[0].r_valid |
                               tcdm[MP].r_valid |
                               other_r_valid    ;

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

`ifdef TARGET_VERILATOR
  assign scan_cg_en = UseXif ? 1'b1 : 1'b0;
`else
  assign scan_cg_en = 1'b0;
`endif
  redmule_complex #(
    .CoreType           ( CoreType            ), // CV32E40P, CV32E40X, IBEX, SNITCH, CVA6
    .ID_WIDTH           ( ID                  ),
    .N_CORES            ( NC                  ),
    .NumIrqs            ( 1                   ),
    .AddrWidth          ( 32                  ),
    .HciRedmuleSize     ( HciRedmuleSize      ),
    .core_data_req_t    ( core_data_req_t     ),
    .core_data_rsp_t    ( core_data_rsp_t     ),
    .core_inst_req_t    ( core_inst_req_t     ),
    .core_inst_rsp_t    ( core_inst_rsp_t     )
  ) i_dut               (
    .clk_i              ( clk_i            ),
    .rst_ni             ( rst_ni           ),
    .test_mode_i        ( test_mode        ),
    .fetch_enable_i     ( fetch_enable_i   ),
    .scan_cg_en_i       ( scan_cg_en       ),
    .redmule_clk_en_i   ( 1'b1             ),
    .boot_addr_i        ( core_boot_addr   ),
    .irq_i              ( '0               ),
    .irq_id_o           (                  ),
    .irq_ack_o          (                  ),
    .core_sleep_o       ( core_sleep       ),
    .core_inst_rsp_i    ( core_inst_rsp    ),
    .core_inst_req_o    ( core_inst_req    ),
    .core_data_rsp_i    ( core_data_rsp    ),
    .core_data_req_o    ( core_data_req    ),
    .tcdm               ( redmule_tcdm     )
  );

  integer f_x, f_W, f_y, f_tau;
  logic start;

  int errors = -1;
  always_ff @(posedge clk_i)
  begin
    if((core_data_req.addr == 32'h80000000) &&
       (core_data_req.we & core_data_req.req == 1'b1)) begin
      errors = core_data_req.data;
    end
    if((core_data_req.addr == 32'h80000004 ) &&
       (core_data_req.we & core_data_req.req == 1'b1)) begin
      $write("%c", core_data_req.data);
    end
  end

  initial begin
    integer id;
    int cnt_rd, cnt_wr;

    if (!$value$plusargs("STIM_INSTR=%s", stim_instr)) stim_instr = "";
    if (!$value$plusargs("STIM_DATA=%s", stim_data)) stim_data = "";
    if (!$value$plusargs("STACK_INIT=%s", stack_init)) stack_init = "";
    $display("Please find STIM_INSTR loaded from %s", stim_instr);
    $display("Please find STIM_DATA loaded from %s", stim_data);
    $display("Please find STACK_INIT loaded from %s", stack_init);

    test_mode = 1'b0;
    core_boot_addr = 32'h1C000084;

    // Load instruction and data memory
    $readmemh(stim_instr, redmule_tb.i_dummy_imemory.memory);
    $readmemh(stim_data,  redmule_tb.i_dummy_dmemory.memory);
    $readmemh(stack_init, redmule_tb.i_dummy_stack_memory.memory);

    // End: WFI + returned != -1 signals end-of-computation
    while(~core_sleep || errors==-1) @(posedge clk_i);
    cnt_rd = redmule_tb.i_dummy_dmemory.cnt_rd[0] +
             redmule_tb.i_dummy_dmemory.cnt_rd[1] +
             redmule_tb.i_dummy_dmemory.cnt_rd[2] +
             redmule_tb.i_dummy_dmemory.cnt_rd[3] +
             redmule_tb.i_dummy_dmemory.cnt_rd[4] +
             redmule_tb.i_dummy_dmemory.cnt_rd[5] +
             redmule_tb.i_dummy_dmemory.cnt_rd[6] +
             redmule_tb.i_dummy_dmemory.cnt_rd[7] +
             redmule_tb.i_dummy_dmemory.cnt_rd[8];

    cnt_wr = redmule_tb.i_dummy_dmemory.cnt_wr[0] +
             redmule_tb.i_dummy_dmemory.cnt_wr[1] +
             redmule_tb.i_dummy_dmemory.cnt_wr[2] +
             redmule_tb.i_dummy_dmemory.cnt_wr[3] +
             redmule_tb.i_dummy_dmemory.cnt_wr[4] +
             redmule_tb.i_dummy_dmemory.cnt_wr[5] +
             redmule_tb.i_dummy_dmemory.cnt_wr[6] +
             redmule_tb.i_dummy_dmemory.cnt_wr[7] +
             redmule_tb.i_dummy_dmemory.cnt_wr[8];

    $display("[TB] - cnt_rd=%-8d", cnt_rd);
    $display("[TB] - cnt_wr=%-8d", cnt_wr);
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
