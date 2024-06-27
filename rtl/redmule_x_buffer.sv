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

module redmule_x_buffer
  import fpnew_pkg::*;
  import redmule_pkg::*;
#(
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

`include "voters.svh"
`include "common_cells/registers.svh"


// W Index Counnter
logic [$clog2(W):0] w_index_d, w_index_q;
logic [$clog2(W):0] w_limit;

assign w_limit = (ctrl_i.rows_lftovr != '0) ? ctrl_i.rows_lftovr : W;

always_comb begin
  flags_o.full = 1'b0;

  if (w_index_q == w_limit || w_index_q == W) begin
    w_index_d = '0;
    flags_o.full = 1'b1;
  end else if (clear_i) begin
    w_index_d = '0;
  end else if (ctrl_i.load) begin
    w_index_d = w_index_q + 1;
  end else begin
    w_index_d = w_index_q;
  end
end

`FF(w_index_q, w_index_d, '0);


// Depth Shift Counter with partial deactivation
logic [$clog2(D):0] d_shift_d, d_shift_q;
logic [$clog2(D):0] empty_count_d, empty_count_q;
logic [$clog2(TOT_DEPTH):0] depth;
logic rst_d_shift, rst_empty;

always_comb begin
  if (rst_d_shift || clear_i) begin
    d_shift_d = '0;
  end else if (ctrl_i.blck_shift) begin
    d_shift_d = d_shift_q + 2;
  end else if (ctrl_i.d_shift) begin
    d_shift_d = d_shift_q + 1;
  end else begin
    d_shift_d = d_shift_q;
  end
end

`FF(d_shift_q, d_shift_d, '0);

always_comb begin
  if (clear_i || rst_empty) begin
    empty_count_d = D;
  end else if (ctrl_i.cols_lftovr != '0) begin
    empty_count_d = ctrl_i.slots;
  end else begin
    empty_count_d = empty_count_q;
  end
end

`FF(empty_count_q, empty_count_d, '0);

always_comb begin : empty_gen_and_shift_count_rst
  flags_o.empty = 1'b0;
  rst_d_shift = 1'b0;
  rst_empty = 1'b0;

  if (d_shift_q == empty_count_q) begin
    flags_o.empty = 1'b1;
    rst_d_shift = 1'b1;
    if (empty_count_q != depth) begin
      rst_empty = 1'b1;
    end
  end
end

assign depth = (ctrl_i.cols_lftovr == '0) ? TOT_DEPTH : ctrl_i.cols_lftovr;


// H shift counter
logic [$clog2(H)-1:0]       h_index_d, h_index_q;

always_comb begin
  if (clear_i) begin
    h_index_d = '0;
  end else if (ctrl_i.h_shift) begin
    h_index_d = h_index_q + 1;
  end else begin
    h_index_d = h_index_q;
  end
end

`FF(h_index_q, h_index_d, '0);


// Main storage element
logic [D-1:0][W-1:0][H-1:0][BITW-1:0]     x_pad_d, x_pad_q;
logic [(D/2)-1:0][W-1:0][H-1:0][BITW-1:0] x_buffer_d, x_buffer_q;

always_comb begin
  if (clear_i) begin
      x_pad_d = '0;
      x_buffer_d = '0;

  end else begin
    x_pad_d = x_pad_q;
    x_buffer_d = x_buffer_q;
    if (ctrl_i.load) begin
      for (int d = 0; d < D; d++) begin
        for (int h = 0; h < H; h++) begin
          x_pad_d[d][w_index_q][h] = ((H * d + h) < depth) ? x_buffer_i[(H * d + h) * BITW +: BITW] : '0;
        end
      end
    end
    if (ctrl_i.d_shift) begin
      for (int w = 0; w < W; w++) begin
        for (int h = 0; h < H; h++) begin
          for (int d = 0; d < D; d++) begin
            x_pad_d[d][w][h] = (d < D - 1) ? x_pad_q[d + 1][w][h] : '0;
          end
          x_buffer_d[HALF_D - 1][w][h] = x_pad_q[0][w][h];
        end
      end
    end
    if (ctrl_i.blck_shift) begin
      for (int w = 0; w < W; w++) begin
        for (int h = 0; h < H; h++) begin
          for (int d = 0; d < D; d++) begin
            x_pad_d[d][w][h] = (d < HALF_D) ? x_pad_q[d + 2][w][h] : '0;
          end
          for (int dd = 0; dd < HALF_D; dd++) begin
            x_buffer_d[dd][w][h] = x_pad_q[dd][w][h];
          end
        end
      end
    end
    if (ctrl_i.h_shift) begin
      for (int w = 0; w < W; w++) begin
        for (int h = 0; h < H; h++) begin
          x_buffer_d[0][w][h_index_q] = x_buffer_q[1][w][h_index_q];
        end
      end
    end
  end
end

`FF(x_pad_q, x_pad_d, '0);
`FF(x_buffer_q, x_buffer_d, '0);

// Output assignment
generate
  for (genvar w = 0; w < W; w++) begin
    for (genvar h = 0; h < H; h++) begin
      assign x_buffer_o[w][h] = x_buffer_q[0][w][h];
    end
  end
endgenerate

endmodule : redmule_x_buffer
