/*
 * Copyright (C) 2022-2023 ETH Zurich and University of Bologna
 *
 * Licensed under the Solderpad Hardware License, Version 0.51 
 * (the "License"); you may not use this file except in compliance 
 * with the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: SHL-0.51
 *
 * Authors:  Yvan Tortorella <yvan.tortorella@unibo.it>
 * 
 * RedMulE X Buffer
 */

import fpnew_pkg::*;
import redmule_pkg::*;

module redmule_x_buffer #(
parameter int unsigned           DW        = 288,
parameter fpnew_pkg::fp_format_e FpFormat  = fpnew_pkg::FP16,
parameter int unsigned           Height    = ARRAY_HEIGHT,  // Number of PEs per row
parameter int unsigned           Width     = ARRAY_WIDTH,   // Number of parallel index
localparam int unsigned          BITW      = fpnew_pkg::fp_width(FpFormat), // Number of bits for the given format                          
localparam int unsigned          H         = Height,
localparam int unsigned          W         = Width,
localparam int unsigned          D         = DW/(H*BITW),
localparam int unsigned          HALF_D    = D/2,
localparam int unsigned          TOT_DEPTH = H*D
)(
  input  logic                                               clk_i     ,
  input  logic                                               rst_ni    ,
  input  logic                                               clear_i   ,  
  input  x_buffer_ctrl_t                                     ctrl_i    ,
  output x_buffer_flgs_t                                     flags_o   ,
  output logic                      [W-1:0][H-1:0][BITW-1:0] x_buffer_o,
  input logic                                       [DW-1:0] x_buffer_i
);

logic                       rst_w_load, rst_d_shift, rst_h_shift, empty_rst;
logic [$clog2(W):0]         w_index, w_limit;
logic [$clog2(H)-1:0]       h_index;
logic [$clog2(D):0]         d_shift, empty_count, empty_count_q;
logic [$clog2(TOT_DEPTH):0] depth;
logic [D-1:0][W-1:0][H-1:0][BITW-1:0]     x_pad_q;
logic [(D/2)-1:0][W-1:0][H-1:0][BITW-1:0] x_buffer_q;

always_ff @(posedge clk_i or negedge rst_ni) begin : bump_register
  if(~rst_ni) begin
    x_pad_q     <= '0;
    x_buffer_q  <= '0;
  end else begin
    if (clear_i) begin
    	x_pad_q    <= '0;
    	x_buffer_q <= '0;
    end else
    if (ctrl_i.load) begin
      for (int d = 0; d < D; d++) begin
        for (int h = 0; h < H; h++) begin
          x_pad_q[d][w_index][h] <= ( (H*d + h) < depth ) ? x_buffer_i[(H*d + h)*BITW+:BITW] : '0;
        end
      end
    end
    if (ctrl_i.d_shift) begin
      for (int w = 0; w < W; w++) begin
        for (int h = 0; h < H; h++) begin
          for (int d = 0; d < D; d++) begin
            x_pad_q[d][w][h] <= (d < D - 1) ? x_pad_q[d+1][w][h] : '0;
            x_buffer_q[HALF_D-1][w][h] <= x_pad_q[0][w][h];
          end
        end
      end
    end 
    if (ctrl_i.blck_shift) begin
      for (int w = 0; w < W; w++) begin
        for (int h = 0; h < H; h++) begin
          for (int d = 0; d < D; d++)
    	    x_pad_q[d][w][h] <= (d < HALF_D) ? x_pad_q[d+2][w][h] : '0;
          for (int dd = 0; dd < HALF_D; dd++)
    	    x_buffer_q[dd][w][h] <= x_pad_q[dd][w][h];
        end
      end
    end
    if (ctrl_i.h_shift) begin
      for (int w = 0; w < W; w++) begin
        for (int h = 0; h < H; h++) begin
          for (int d = 0; d < D; d++)
            x_buffer_q[0][w][h_index] <= x_buffer_q[1][w][h_index];
        end
      end
    end
  end
end

assign depth = (ctrl_i.cols_lftovr == '0) ? TOT_DEPTH : ctrl_i.cols_lftovr;

// Counter to track the rows that have to be loaded
always_ff @(posedge clk_i or negedge rst_ni) begin : row_loaded_counter
  if(~rst_ni) begin
    w_index <= '0;
  end else begin
    if (rst_w_load || clear_i)
      w_index <= '0;
    else if (ctrl_i.load)
      w_index <= w_index + 1; 
    else
      w_index <= w_index;
  end
end

assign w_limit = (ctrl_i.rows_lftovr != '0) ? ctrl_i.rows_lftovr : W;

always_comb begin : load_count_rst
  rst_w_load   = 1'b0;
  flags_o.full = 1'b0;
  if (w_index == w_limit || w_index == W) begin
    rst_w_load   = 1'b1;
    flags_o.full = 1'b1;
  end else begin
    rst_w_load   = 1'b0;
    flags_o.full = 1'b0;
  end
end

// Depth shift counter
always_ff @(posedge clk_i or negedge rst_ni) begin : d_shift_counter
if(~rst_ni) begin
  d_shift <= '0;
end else begin
  if (rst_d_shift || clear_i)
    d_shift <= '0;
  else if (ctrl_i.blck_shift)
    d_shift <= d_shift + 2;
  else if (ctrl_i.d_shift)
    d_shift <= d_shift + 1;
  else
    d_shift <= d_shift;
end
end

always_comb begin
  if (ctrl_i.cols_lftovr != '0)
    empty_count = ctrl_i.slots;
  else
    empty_count = D;
end

always_ff @(posedge clk_i or negedge rst_ni) begin : empty_count_reg
  if(~rst_ni) begin
    empty_count_q <= '0;
  end else begin
    if (clear_i || empty_rst)
      empty_count_q <= D;
    else begin
      if (ctrl_i.cols_lftovr != '0)
        empty_count_q <= ctrl_i.slots;
    end
  end
end

always_comb begin : empty_gen_and_shift_count_rst
  flags_o.empty = 1'b0;
  rst_d_shift   = 1'b0;
  empty_rst     = 1'b0;
  if (d_shift == empty_count_q) begin
    flags_o.empty = 1'b1;
    rst_d_shift   = 1'b1;
    if (empty_count_q != D)
      empty_rst = 1'b1;
  end else begin
    flags_o.empty = 1'b0;
    rst_d_shift   = 1'b0;
    empty_rst     = 1'b0;
  end
end

// H shift counter
always_ff @(posedge clk_i or negedge rst_ni) begin : h_shift_counter
  if(~rst_ni) begin
    h_index <= '0;
  end else begin
    if (rst_h_shift || clear_i) 
      h_index <= '0;
    else if(ctrl_i.h_shift)
      h_index <= h_index + 1;
    else
      h_index <= h_index;
  end
end

// Output assignment
generate
  for (genvar w = 0; w < W; w++) begin
    for (genvar h = 0; h < H; h++) begin
      assign x_buffer_o[w][h] = x_buffer_q[0][w][h];
    end
  end
endgenerate

endmodule : redmule_x_buffer
