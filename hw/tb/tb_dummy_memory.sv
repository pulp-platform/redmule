/* 
 * tb_dummy_memory.sv
 * Francesco Conti <fconti@iis.ee.ethz.ch>
 *
 * Copyright (C) 2014-2018 ETH Zurich, University of Bologna
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
 * Dummy memory transaction.
 */

timeunit 1ps;
timeprecision 1ps;

`ifdef VERILATOR
  `define clk_verilated clk_delayed_i
`else
  `define clk_verilated clk_delayed
`endif

module tb_dummy_memory
#(
  parameter MP          = 1,
  parameter MEMORY_SIZE = 1024,
  parameter BASE_ADDR   = 0,
  parameter PROB_STALL  = 0.0,
`ifndef VERILATOR
  parameter time TCP = 1.0ns, // clock period, 1GHz clock
  parameter time TA  = 0.2ns, // application time
  parameter time TT  = 0.8ns  // test time
`else
  parameter time TCP = 1.0,   // clock period, 1GHz clock
  parameter time TA  = 0.2,   // application time
  parameter time TT  = 0.8    // test time
`endif
)
(
  input  logic                clk_i,
  input  logic                clk_delayed_i,
  input  logic                randomize_i,
  input  logic                enable_i,
  input  logic                stallable_i,
  hwpe_stream_intf_tcdm.slave tcdm [MP-1:0]
);

  logic [31:0] memory [MEMORY_SIZE];
  int cnt = 0;

  int cnt_req  [MP-1:0];
  int cnt_rval [MP-1:0];
  int cnt_rd   [MP-1:0];
  int cnt_wr   [MP-1:0];

  logic [MP-1:0]       tcdm_req;
  logic [MP-1:0]       tcdm_gnt;
  logic [MP-1:0][31:0] tcdm_add;
  logic [MP-1:0]       tcdm_wen;
  logic [MP-1:0][3:0]  tcdm_be;
  logic [MP-1:0][31:0] tcdm_data;
  logic [MP-1:0][31:0] tcdm_r_data;
  logic [MP-1:0]       tcdm_r_valid;
  logic [MP-1:0][31:0] tcdm_r_data_int;
  logic [MP-1:0]       tcdm_r_valid_int;

  real probs [MP-1:0];

  logic clk_delayed;

  always_ff @(posedge clk_i)
  begin : probs_proc
    for (int i=0; i<MP; i++) begin
      automatic logic [31:0] ran = $random();
      probs[i] = real'(ran[9:0])/1024.0;
    end
  end

  generate

    for(genvar i=0; i<MP; i++) begin
      
      assign tcdm_gnt[i] = (probs[i] < PROB_STALL) & stallable_i ? 1'b0 : 1'b1;
    end

    for(genvar ii=0; ii<MP; ii++) begin : binding_gen
      assign tcdm_req  [ii] = tcdm[ii].req;
      assign tcdm_add  [ii] = tcdm[ii].add;
      assign tcdm_wen  [ii] = tcdm[ii].wen;
      assign tcdm_be   [ii] = tcdm[ii].be;
      assign tcdm_data [ii] = tcdm[ii].data;
      assign tcdm[ii].gnt     = tcdm_gnt [ii] & tcdm_req [ii];
      assign tcdm[ii].r_data  = tcdm_r_data  [ii];
      assign tcdm[ii].r_valid = tcdm_r_valid [ii];
    end

    always_ff @(posedge clk_i)
    begin
      if(randomize_i)
        for(int i=0; i<MEMORY_SIZE; i++)
          memory[i] = $random();
    end

  endgenerate

  // assign clk_delayed = #(TA) clk_i;
`ifndef VERILATOR
  always @(clk_i)
  begin
    clk_delayed <= #(TA) clk_i;
  end
`endif

  logic [MP-1:0][31:0] write_data;

  generate
    for(genvar i=0; i<MP; i++)
      for(genvar j=0; j<4; j++)
        always_comb
        begin
          write_data[i][(j+1)*8-1:j*8] = memory[(tcdm_add[i]-BASE_ADDR) >> 2][(j+1)*8-1:j*8];
          if(tcdm_be[i][j])
            write_data[i][(j+1)*8-1:j*8] = tcdm_data[i][(j+1)*8-1:j*8];
        end
  endgenerate

  always_ff @(posedge clk_i)
  begin : dummy_proc
    for (int i=0; i<MP; i++) begin
      if ((tcdm_req[i] & enable_i) == 1'b0) begin
        tcdm_r_data_int  [i] <= 'x;
        tcdm_r_valid_int [i] <= 1'b0;
      end
      else begin
        // read
        if (tcdm_gnt[i] & tcdm_wen[i]) begin
          tcdm_r_data_int  [i] <= memory[(tcdm_add[i]-BASE_ADDR) >> 2];
          tcdm_r_valid_int [i] <= tcdm_gnt[i];
        end
        // write
        else if (tcdm_gnt[i] & ~tcdm_wen[i]) begin
          memory[(tcdm_add[i]-BASE_ADDR) >> 2] <= write_data [i];
          tcdm_r_data_int  [i] <= write_data [i];
          tcdm_r_valid_int [i] <= 1'b1;
        end
        // no-grant
        else if (~tcdm_gnt[i]) begin
          tcdm_r_data_int  [i] <= 'x;
          tcdm_r_valid_int [i] <= 1'b0;
        end
        else begin
          tcdm_r_data_int  [i] <= 'x;
          tcdm_r_valid_int [i] <= 1'b0;
        end
      end
    end
  end

`ifndef VERILATOR
  always_ff @(posedge `clk_verilated)
  begin
    tcdm_r_data  <= tcdm_r_data_int;
    tcdm_r_valid <= tcdm_r_valid_int;
  end
`else
  assign tcdm_r_data  = tcdm_r_data_int;
  assign tcdm_r_valid = tcdm_r_valid_int;
`endif

  generate;

    for(genvar ii=0; ii<MP; ii++) begin
      initial begin
        cnt_req[ii] = 0;
        cnt_rval[ii] = 0;
        cnt_wr[ii] = 0;
        cnt_rd[ii] = 0;
      end

      always @(posedge `clk_verilated) begin
        if(tcdm_req[ii])
          cnt_req[ii] ++;
        if(tcdm_r_valid[ii])
          cnt_rval[ii] ++;
        if(tcdm_req[ii] & tcdm_gnt[ii] & ~tcdm_wen[ii])
          cnt_wr[ii] ++;
        if(tcdm_req[ii] & tcdm_gnt[ii] & tcdm_wen[ii])
          cnt_rd[ii] ++;
      end
    end

  endgenerate

endmodule // tb_dummy_memory
