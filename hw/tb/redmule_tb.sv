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

timeunit 1ps;
timeprecision 1ps;

module redmule_tb;

  // parameters
  parameter PROB_STALL = 0;
  parameter NC = 8;
  parameter ID = 10;
  parameter DW = 288;
  parameter MP = DW/32;
  parameter MEMORY_SIZE = 192*1024;
  parameter STACK_MEMORY_SIZE = 192*1024;
  parameter BASE_ADDR = 0;
  parameter HWPE_ADDR_BASE_BIT = 20;
  parameter STIM_INSTR = "../../stim_instr.txt";
  parameter STIM_DATA  = "../../stim_data.txt";

  // global signals
  logic                         clk_i  = '0;
  logic                         rst_ni = '1;
  logic                         test_mode_i = '0;
  // local enable
  logic                         enable_i = '1;
  logic                         clear_i  = '0;

  logic fetch_enable = 1'b0;
  logic busy = 1'b1;
  logic randomize_conv     = 1'b0;
  logic force_ready_feat   = 1'b0;
  logic force_ready_weight = 1'b0;
  logic randomize_mem      = 1'b0;
  logic stallable_mem      = 1'b0;
  logic enable_conv        = 1'b1;
  logic enable_feat        = 1'b1;
  logic enable_weight      = 1'b1;
  logic enable_mem         = 1'b1;
  logic tpu_busy;
  int in_len;
  int out_len;
  int threshold_shift;

  hwpe_stream_intf_tcdm instr[0:0]  (.clk(clk_i));
  hwpe_stream_intf_tcdm stack[0:0]  (.clk(clk_i));
  hwpe_stream_intf_tcdm tcdm [MP:0] (.clk(clk_i));

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

  // ATI timing parameters.
  localparam TCP = 1.0ns; // clock period, 1 GHz clock
  localparam TA  = 0.2ns; // application time
  localparam TT  = 0.8ns; // test time

  // Performs one entire clock cycle.
  task cycle;
    clk_i <= #(TCP/2) 0;
    clk_i <= #TCP 1;
    #TCP;
  endtask

  // The following task schedules the clock edges for the next cycle and
  // advances the simulation time to that cycles test time (localparam TT)
  // according to ATI timings.
  task cycle_start;
    clk_i <= #(TCP/2) 0;
    clk_i <= #TCP 1;
    #TT;
  endtask

  // The following task finishes a clock cycle previously started with
  // cycle_start by advancing the simulation time to the end of the cycle.
  task cycle_end;
    #(TCP-TT);
  endtask

  // bindings
  always_comb
  begin : bind_periph
    periph_req  = data_req & data_addr[HWPE_ADDR_BASE_BIT];
    periph_add  = data_addr;
    periph_wen  = ~data_we;
    periph_be   = data_be;
    periph_data = data_wdata;
    periph_id   = '0;
  end

  always_comb
  begin : bind_instrs
    instr[0].req  = instr_req;
    instr[0].add  = instr_addr;
    instr[0].wen  = 1'b1;
    instr[0].be   = '0;
    instr[0].data = '0;
    instr_gnt    = instr[0].gnt;
    instr_rdata  = instr[0].r_data;
    instr_rvalid = instr[0].r_valid;
  end

  always_comb
  begin : bind_stack
    stack[0].req  = data_req & (data_addr[31:24] == '0) & ~data_addr[HWPE_ADDR_BASE_BIT];
    stack[0].add  = data_addr;
    stack[0].wen  = ~data_we;
    stack[0].be   = data_be;
    stack[0].data = data_wdata;
  end

  logic other_r_valid;
  always_ff @(posedge clk_i)
  begin
    other_r_valid <= data_req & (data_addr[31:24] == 8'h80);
  end

  generate
    for(genvar ii=0; ii<MP; ii++) begin : tcdm_binding
      assign tcdm[ii].req  = tcdm_req  [ii];
      assign tcdm[ii].add  = tcdm_add  [ii];
      assign tcdm[ii].wen  = tcdm_wen  [ii];
      assign tcdm[ii].be   = tcdm_be   [ii];
      assign tcdm[ii].data = tcdm_data [ii];
      assign tcdm_gnt     [ii] = tcdm[ii].gnt;
      assign tcdm_r_data  [ii] = tcdm[ii].r_data;
      assign tcdm_r_valid [ii] = tcdm[ii].r_valid;
    end
    assign tcdm[MP].req  = data_req & (data_addr[31:24] != '0) & (data_addr[31:24] != 8'h80) & ~data_addr[HWPE_ADDR_BASE_BIT];
    assign tcdm[MP].add  = data_addr;
    assign tcdm[MP].wen  = ~data_we;
    assign tcdm[MP].be   = data_be;
    assign tcdm[MP].data = data_wdata;
    assign tcdm_r_opc   = 0;
    assign tcdm_r_user  = 0;
    assign data_gnt    = periph_req ? periph_gnt : stack[0].req ? stack[0].gnt : tcdm[MP].req ? tcdm[MP].gnt : '1;
    assign data_rdata  = periph_r_valid ? periph_r_data : stack[0].r_valid ? stack[0].r_data : tcdm[MP].r_valid ? tcdm[MP].r_data : '0;
    assign data_rvalid = periph_r_valid | stack[0].r_valid | tcdm[MP].r_valid | other_r_valid;
  endgenerate

  redmule_wrap #(
    .ID_WIDTH          ( ID             ),
    .N_CORES           ( NC             ),
    .DW                ( DW             ),
    .MP                ( DW/32          )
  ) i_redmule_wrap     (
    .clk_i             ( clk_i          ),
    .rst_ni            ( rst_ni         ),
    .test_mode_i       ( test_mode_i    ),
    .evt_o             ( evt            ),
    .busy_o            ( tpu_busy       ),
    .tcdm_req          ( tcdm_req       ),
    .tcdm_add          ( tcdm_add       ),
    .tcdm_wen          ( tcdm_wen       ),
    .tcdm_be           ( tcdm_be        ),
    .tcdm_data         ( tcdm_data      ),
    .tcdm_gnt          ( tcdm_gnt       ),
    .tcdm_r_data       ( tcdm_r_data    ),
    .tcdm_r_valid      ( tcdm_r_valid   ),
    .tcdm_r_opc        ( tcdm_r_opc     ),
    .tcdm_r_user       ( tcdm_r_user    ),
    .periph_req        ( periph_req     ),
    .periph_gnt        ( periph_gnt     ),
    .periph_add        ( periph_add     ),
    .periph_wen        ( periph_wen     ),
    .periph_be         ( periph_be      ),
    .periph_data       ( periph_data    ),
    .periph_id         ( periph_id      ),
    .periph_r_data     ( periph_r_data  ),
    .periph_r_valid    ( periph_r_valid ),
    .periph_r_id       ( periph_r_id    )
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
    .clk_delayed_i  ( '0            ),
    .randomize_i    ( randomize_mem ),
    .enable_i       ( enable_mem    ),
    .stallable_i    ( busy          ),
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
    .clk_delayed_i       ( '0                ),
    .randomize_i         ( 1'b0              ),
    .enable_i            ( 1'b1              ),
    .stallable_i         ( 1'b0              ),
    .tcdm                ( stack             )
  );

  zeroriscy_core #(
    .N_EXT_PERF_COUNTERS ( 0            ),
    .RV32E               ( 0            ),
    .RV32M               ( 1            )
  ) i_zeroriscy          (
    .clk_i               ( clk_i        ),
    .rst_ni              ( rst_ni       ),
    .clock_en_i          ( 1'b1         ),
    .test_en_i           ( 1'b0         ),
    .core_id_i           ( '0           ),
    .cluster_id_i        ( '0           ),
    .boot_addr_i         ( '0           ),
    .instr_req_o         ( instr_req    ),
    .instr_gnt_i         ( instr_gnt    ),
    .instr_rvalid_i      ( instr_rvalid ),
    .instr_addr_o        ( instr_addr   ),
    .instr_rdata_i       ( instr_rdata  ),
    .data_req_o          ( data_req     ),
    .data_gnt_i          ( data_gnt     ),
    .data_rvalid_i       ( data_rvalid  ),
    .data_we_o           ( data_we      ),
    .data_be_o           ( data_be      ),
    .data_addr_o         ( data_addr    ),
    .data_wdata_o        ( data_wdata   ),
    .data_rdata_i        ( data_rdata   ),
    .data_err_i          ( data_err     ),
    .irq_i               ( evt[0][0]    ),
    .irq_id_i            ( '0           ),
    .irq_ack_o           (              ),
    .irq_id_o            (              ),
    .debug_req_i         ( '0           ),
    .debug_gnt_o         (              ),
    .debug_rvalid_o      (              ),
    .debug_addr_i        ( '0           ),
    .debug_we_i          ( '0           ),
    .debug_wdata_i       ( '0           ),
    .debug_rdata_o       (              ),
    .debug_halted_o      (              ),
    .debug_halt_i        ( '0           ),
    .debug_resume_i      ( '0           ),
    .fetch_enable_i      ( fetch_enable ),
    .ext_perf_counters_i ( '0           )
  );

  initial begin
    #(20*TCP);

    // Reset phase.
    rst_ni <= #TA 1'b0;
    #(20*TCP);
    rst_ni <= #TA 1'b1;

    for (int i = 0; i < 10; i++)
      cycle();
    rst_ni <= #TA 1'b0;
    for (int i = 0; i < 10; i++)
      cycle();
    rst_ni <= #TA 1'b1;

    while(1) begin
      cycle();
    end

  end
  
  integer f_t0, f_t1;
  integer f_x, f_W, f_y, f_tau;
  logic start;

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

    integer id;
    int cnt_rd, cnt_wr;

    f_t0 = $fopen("time_start.txt");
    f_t1 = $fopen("time_stop.txt");

    // load instruction memory
    $readmemh(STIM_INSTR, redmule_tb.i_dummy_imemory.memory);
    $readmemh(STIM_DATA,  redmule_tb.i_dummy_dmemory.memory);

    #(60*TCP);
    fetch_enable = 1'b1;

    #(100*TCP);
    // end WFI + returned != -1 signals end-of-computation
    while(~redmule_tb.i_zeroriscy.sleeping || errors==-1)
      #(TCP);
    cnt_rd = redmule_tb.i_dummy_dmemory.cnt_rd[0] + redmule_tb.i_dummy_dmemory.cnt_rd[1] + redmule_tb.i_dummy_dmemory.cnt_rd[2] + redmule_tb.i_dummy_dmemory.cnt_rd[3] + redmule_tb.i_dummy_dmemory.cnt_rd[4] + redmule_tb.i_dummy_dmemory.cnt_rd[5] + redmule_tb.i_dummy_dmemory.cnt_rd[6] + redmule_tb.i_dummy_dmemory.cnt_rd[7] + redmule_tb.i_dummy_dmemory.cnt_rd[8];
    cnt_wr = redmule_tb.i_dummy_dmemory.cnt_wr[0] + redmule_tb.i_dummy_dmemory.cnt_wr[1] + redmule_tb.i_dummy_dmemory.cnt_wr[2] + redmule_tb.i_dummy_dmemory.cnt_wr[3] + redmule_tb.i_dummy_dmemory.cnt_wr[4] + redmule_tb.i_dummy_dmemory.cnt_wr[5] + redmule_tb.i_dummy_dmemory.cnt_wr[6] + redmule_tb.i_dummy_dmemory.cnt_wr[7] + redmule_tb.i_dummy_dmemory.cnt_wr[8];
    $display("cnt_rd=%-8d", cnt_rd);
    $display("cnt_wr=%-8d", cnt_wr);
    if(errors != 0)
      $error("errors=%08x", errors);
    else
      $display("errors=%08x", errors);
    $finish;

  end

endmodule // redmule_tb
