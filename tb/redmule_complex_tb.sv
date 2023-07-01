/*
 * Copyright (C) 2022-2023 ETH Zurich, University of Bologna
 * Copyright and related rights are licensed under the Solderpad Hardware
 * License, Version 0.51 (the "License"); you may not use this file except in
 * compliance with the License.  You may obtain a copy of the License at
 * http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
 * or agreed to in writing, software, hardware and materials distributed under
 * this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 * SPDX-License-Identifier: SHL-0.51
 *
 * Author: Yvan Tortorella (yvan.tortorella@unibo.it)
 *
 * RedMulE testbench for Questa simulation
 */

`include "hci/typedef.svh"
`include "hci/assign.svh"

timeunit 1ps;
timeprecision 1ps;

import snitch_pkg::*;

module redmule_complex_tb;

  // parameters
  parameter int unsigned PROB_STALL = 0;
  parameter int unsigned NC = 1;
  parameter int unsigned ID = 10;
  parameter int unsigned DW = 288;
  parameter int unsigned MP = DW/32;
  parameter int unsigned MEMORY_SIZE = 192*1024;
  parameter int unsigned STACK_MEMORY_SIZE = 192*1024;
  parameter int unsigned PULP_XPULP = 1;
  parameter int unsigned FPU = 0;
  parameter int unsigned PULP_ZFINX = 0;
  parameter logic [31:0] BASE_ADDR = 32'h1c000000;
  parameter logic [31:0] HWPE_ADDR_BASE_BIT = 20;
  parameter string STIM_INSTR = "../../stim_instr.txt";
  parameter string STIM_DATA  = "../../stim_data.txt";

  // global signals
  logic clk;
  logic rst_n;
  logic test_mode;
  logic fetch_enable;
  logic [31:0] core_boot_addr;
  logic redmule_busy;

  hwpe_stream_intf_tcdm instr[0:0]  (.clk(clk));
  hwpe_stream_intf_tcdm stack[0:0]  (.clk(clk));
  hwpe_stream_intf_tcdm tcdm [MP:0] (.clk(clk));

  logic [NC-1:0][1:0] evt;

  logic [MP-1:0]       tcdm_req;
  logic [MP-1:0]       tcdm_gnt;
  logic [MP-1:0][31:0] tcdm_add;
  logic [MP-1:0]       tcdm_wen;
  logic [MP-1:0][3:0]  tcdm_be;
  logic [MP-1:0][31:0] tcdm_data;
  logic [MP-1:0][31:0] tcdm_r_data;
  logic [MP-1:0]       tcdm_r_valid;
  logic                tcdm_r_opc;
  logic                tcdm_r_user;
   
  logic          periph_req;
  logic          periph_gnt;
  logic [31:0]   periph_add;
  logic          periph_wen;
  logic [3:0]    periph_be;
  logic [31:0]   periph_data;
  logic [ID-1:0] periph_id;
  logic [31:0]   periph_r_data;
  logic          periph_r_valid;
  logic [ID-1:0] periph_r_id;

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

  // ATI timing parameters.
  localparam TCP = 1.0ns; // clock period, 1 GHz clock
  localparam TA  = 0.2ns; // application time
  localparam TT  = 0.8ns; // test time

  // Performs one entire clock cycle.
  task cycle;
    clk <= #(TCP/2) 0;
    clk <= #TCP 1;
    #TCP;
  endtask

  // The following task schedules the clock edges for the next cycle and
  // advances the simulation time to that cycles test time (localparam TT)
  // according to ATI timings.
  task cycle_start;
    clk <= #(TCP/2) 0;
    clk <= #TCP 1;
    #TT;
  endtask

  // The following task finishes a clock cycle previously started with
  // cycle_start by advancing the simulation time to the end of the cycle.
  task cycle_end;
    #(TCP-TT);
  endtask

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

  typedef struct packed {
    snitch_pkg::acc_addr_e addr;
    logic [4:0]  id;
    logic [31:0] data_op;
    logic [31:0] data_arga;
    logic [31:0] data_argb;
    logic [31:0] data_argc;
  } redmule_ctrl_req_t;

  typedef struct packed {
    logic [4:0]  id;
    logic        error;
    logic [31:0] data;
  } redmule_ctrl_rsp_t;

  `HCI_TYPEDEF_REQ_T(redmule_data_req_t, logic [31:0], logic [DW-1:0], logic [DW/8-1:0], logic signed [DW/32-1:0][31:0], logic)
  `HCI_TYPEDEF_RSP_T(redmule_data_rsp_t, logic [DW-1:0], logic)

  core_inst_req_t core_inst_req;
  core_inst_rsp_t core_inst_rsp;

  core_data_req_t core_data_req;
  core_data_rsp_t core_data_rsp;

  redmule_data_req_t redmule_data_req;
  redmule_data_rsp_t redmule_data_rsp;

  // bindings
  always_comb begin : bind_periph
    // periph_req     = core_data_req.req & core_data_req.addr[HWPE_ADDR_BASE_BIT];
    periph_req     = '0;
    periph_add     = core_data_req.addr;
    periph_wen     = ~core_data_req.we;
    periph_be      = core_data_req.be;
    periph_data    = core_data_req.data;
    periph_id      = '0;
    periph_r_valid = '0;
  end

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
    stack[0].req  = core_data_req.req & (core_data_req.addr[31:24] == '0) &
                    ~core_data_req.addr[HWPE_ADDR_BASE_BIT];
    stack[0].add  = core_data_req.addr;
    stack[0].wen  = ~core_data_req.we;
    stack[0].be   = core_data_req.be;
    stack[0].data = core_data_req.data;
  end

  logic other_r_valid;
  always_ff @(posedge clk or negedge rst_n) begin
    if (~rst_n)
      other_r_valid <= '0;
    else
      other_r_valid <= core_data_req.req & (core_data_req.addr[31:24] == 8'h80);
  end

  for(genvar ii=0; ii<MP; ii++) begin : tcdm_binding
    assign tcdm[ii].req  = redmule_data_req.req;
    assign tcdm[ii].add  = redmule_data_req.add + ii*4;
    assign tcdm[ii].wen  = redmule_data_req.wen;
    assign tcdm[ii].be   = redmule_data_req.be[(ii+1)*4-1:ii*4];
    assign tcdm[ii].data = redmule_data_req.data[(ii+1)*32-1:ii*32];
    assign tcdm_gnt[ii]     = tcdm[ii].gnt;
    assign tcdm_r_valid[ii] = tcdm[ii].r_valid;
    assign tcdm_r_data[ii]  = tcdm[ii].r_data;
  end
  assign redmule_data_rsp.gnt     = &tcdm_gnt;
  assign redmule_data_rsp.r_data  = { >> {tcdm_r_data} };
  assign redmule_data_rsp.r_valid = &tcdm_r_valid;
  assign redmule_data_rsp.r_opc   = '0;
  assign redmule_data_rsp.r_user  = '0;

  assign tcdm[MP].req  = core_data_req.req &
                         (core_data_req.addr[31:24] != '0) &
                         (core_data_req.addr[31:24] != 8'h80) &
                         ~core_data_req.addr[HWPE_ADDR_BASE_BIT];
  assign tcdm[MP].add  = core_data_req.addr;
  assign tcdm[MP].wen  = ~core_data_req.we;
  assign tcdm[MP].be   = core_data_req.be;
  assign tcdm[MP].data = core_data_req.data;

  assign core_data_rsp.gnt = periph_req ?
                             periph_gnt : stack[0].req ?
                                          stack[0].gnt : tcdm[MP].req ?
                                                         tcdm[MP].gnt : '1;

  assign core_data_rsp.data = periph_r_valid   ? periph_r_data    :
                              stack[0].r_valid ? stack[0].r_data  :
                                                 tcdm[MP].r_valid ? tcdm[MP].r_data : '0;
  assign core_data_rsp.valid = periph_r_valid   |
                               stack[0].r_valid |
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
    .clk_i          ( clk           ),
    .rst_ni         ( rst_n         ),
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
    .clk_i          ( clk         ),
    .rst_ni         ( rst_n       ),
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
    .clk_i               ( clk               ),
    .rst_ni              ( rst_n             ),
    .clk_delayed_i       ( '0                ),
    .randomize_i         ( 1'b0              ),
    .enable_i            ( 1'b1              ),
    .stallable_i         ( 1'b0              ),
    .tcdm                ( stack             )
  );

  redmule_complex #(
    .CoreType           ( redmule_pkg::CV32   ), // CV32E40P, IBEX, SNITCH, CVA6
    .ID_WIDTH           ( ID                  ),
    .N_CORES            ( NC                  ),
    .DW                 ( DW                  ), // TCDM port dimension (in bits)
    .MP                 ( DW/32               ),
    .NumIrqs            ( 0                   ),
    .AddrWidth          ( 32                  ),
    .core_data_req_t    ( core_data_req_t     ),
    .core_data_rsp_t    ( core_data_rsp_t     ),
    .core_inst_req_t    ( core_inst_req_t     ),
    .core_inst_rsp_t    ( core_inst_rsp_t     ),
    .redmule_data_req_t ( redmule_data_req_t  ),
    .redmule_data_rsp_t ( redmule_data_rsp_t  ),
    .redmule_ctrl_req_t ( redmule_ctrl_req_t  ),
    .redmule_ctrl_rsp_t ( redmule_ctrl_rsp_t  )
  ) i_dut               (
    .clk_i              ( clk              ),
    .rst_ni             ( rst_n            ),
    .test_mode_i        ( test_mode        ),
    .fetch_enable_i     ( fetch_enable     ),
    .boot_addr_i        ( core_boot_addr   ),
    .irq_i              ( '0               ),
    .irq_id_o           (                  ),
    .irq_ack_o          (                  ),
    .core_sleep_o       ( core_sleep       ),
    .core_inst_rsp_i    ( core_inst_rsp    ),
    .core_inst_req_o    ( core_inst_req    ),
    .core_data_rsp_i    ( core_data_rsp    ),
    .core_data_req_o    ( core_data_req    ),
    .redmule_data_rsp_i ( redmule_data_rsp ),
    .redmule_data_req_o ( redmule_data_req )
  );

  initial begin
    clk <= 1'b0;
    rst_n <= 1'b0;
    core_boot_addr = 32'h0;
    for (int i = 0; i < 20; i++)
      cycle();
    rst_n <= #TA 1'b1;
    core_boot_addr = 32'h1C000084;

    for (int i = 0; i < 10; i++)
      cycle();
    rst_n <= #TA 1'b0;
    for (int i = 0; i < 10; i++)
      cycle();
    rst_n <= #TA 1'b1;

    while(1) begin
      cycle();
    end

  end
  
  integer f_t0, f_t1;
  integer f_x, f_W, f_y, f_tau;
  logic start;

  int errors = -1;
  always_ff @(posedge clk)
  begin
    if((data_addr == 32'h80000000 ) && (data_we & data_req == 1'b1)) begin
      errors = data_wdata;
    end
    if((data_addr == 32'h80000004 ) && (data_we & data_req == 1'b1)) begin
      $write("%c", data_wdata);
    end
  end

  initial begin
    integer id;
    int cnt_rd, cnt_wr;

    test_mode = 1'b0;
    fetch_enable = 1'b0;

    f_t0 = $fopen("time_start.txt");
    f_t1 = $fopen("time_stop.txt");

    // load instruction memory
    $readmemh(STIM_INSTR, redmule_complex_tb.i_dummy_imemory.memory);
    $readmemh(STIM_DATA,  redmule_complex_tb.i_dummy_dmemory.memory);

    #(100*TCP);
    fetch_enable = 1'b1;

    #(100*TCP);
    // end WFI + returned != -1 signals end-of-computation
    while(~core_sleep || errors==-1)
      #(TCP);
    cnt_rd = redmule_complex_tb.i_dummy_dmemory.cnt_rd[0] +
             redmule_complex_tb.i_dummy_dmemory.cnt_rd[1] +
             redmule_complex_tb.i_dummy_dmemory.cnt_rd[2] +
             redmule_complex_tb.i_dummy_dmemory.cnt_rd[3] +
             redmule_complex_tb.i_dummy_dmemory.cnt_rd[4] +
             redmule_complex_tb.i_dummy_dmemory.cnt_rd[5] +
             redmule_complex_tb.i_dummy_dmemory.cnt_rd[6] +
             redmule_complex_tb.i_dummy_dmemory.cnt_rd[7] +
             redmule_complex_tb.i_dummy_dmemory.cnt_rd[8];

    cnt_wr = redmule_complex_tb.i_dummy_dmemory.cnt_wr[0] +
             redmule_complex_tb.i_dummy_dmemory.cnt_wr[1] +
             redmule_complex_tb.i_dummy_dmemory.cnt_wr[2] +
             redmule_complex_tb.i_dummy_dmemory.cnt_wr[3] +
             redmule_complex_tb.i_dummy_dmemory.cnt_wr[4] +
             redmule_complex_tb.i_dummy_dmemory.cnt_wr[5] +
             redmule_complex_tb.i_dummy_dmemory.cnt_wr[6] +
             redmule_complex_tb.i_dummy_dmemory.cnt_wr[7] +
             redmule_complex_tb.i_dummy_dmemory.cnt_wr[8];

    $display("cnt_rd=%-8d", cnt_rd);
    $display("cnt_wr=%-8d", cnt_wr);
    if(errors != 0)
      $error("errors=%08x", errors);
    else
      $display("errors=%08x", errors);
    $finish;

  end

endmodule // redmule_tb
