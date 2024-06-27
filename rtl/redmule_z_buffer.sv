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
 * Authors: Yvan Tortorella <yvan.tortorella@unibo.it>
 * 
 * RedMulE Z Buffer
 */

module redmule_z_buffer
  import fpnew_pkg::*;
  import redmule_pkg::*;
#(
parameter int unsigned           DW       = 288,
parameter fpnew_pkg::fp_format_e FpFormat = fpnew_pkg::FP16,
parameter int unsigned           Width    = ARRAY_WIDTH,   // Number of parallel index
localparam int unsigned          BITW     = fpnew_pkg::fp_width(FpFormat), // Number of bits for the given format                          
localparam int unsigned          W        = Width,
localparam int unsigned          D        = DW/BITW
)(
  input  logic                             clk_i       ,
  input  logic                             rst_ni      ,
  input  logic                             clear_i     ,
  input  logic                             reg_enable_i,
  input  z_buffer_ctrl_t                   ctrl_i      ,
  input  logic           [W-1:0][BITW-1:0] z_buffer_i  ,
  input  logic                    [DW-1:0] y_buffer_i  ,
  output logic                    [DW-1:0] z_buffer_o  ,
  output logic           [W-1:0][BITW-1:0] y_buffer_o  ,
  output z_buffer_flgs_t                   flags_o
);

`include "voters.svh"
`include "common_cells/registers.svh"

// Clock gating Cell
logic buffer_clock;
tc_clk_gating i_z_buffer_clock_gating (
  .clk_i     ( clk_i                ),
  .en_i      ( ctrl_i.buffer_clk_en ),
  .test_en_i ( '0                   ),
  .clk_o     ( buffer_clock         )
);


// Counter to track when the output buffer is full
logic [$clog2(D):0] fill_shift_d, fill_shift_q;

always_comb begin
  flags_o.full = 1'b0;

  if (fill_shift_q == D - 1 && ctrl_i.fill) begin
    fill_shift_d = '0;
    flags_o.full = 1'b1;
  end else if (clear_i) begin
    fill_shift_d = '0;
  end else if (ctrl_i.fill) begin
    fill_shift_d = fill_shift_q + 1; 
  end else begin
    fill_shift_d = fill_shift_q;
  end
end

`FFARN(fill_shift_q, fill_shift_d, '0, buffer_clock, rst_ni);


// Counter to track the number of store rows
logic [$clog2(W):0] store_shift_d, store_shift_q;

always_comb begin
  flags_o.empty = 1'b0;

  if (store_shift_q == W) begin
    store_shift_d = '0;
    flags_o.empty = 1'b1;
  end else if (clear_i) begin
    store_shift_d = '0;
  end else if (ctrl_i.store) begin
    store_shift_d = store_shift_q + 1; 
  end else begin
    store_shift_d = store_shift_q;
  end
end

`FFARN(store_shift_q, store_shift_d, '0, buffer_clock, rst_ni);


// Counter to track the rows that have to be loaded
logic [$clog2(W):0] w_index_d, w_index_q;

always_comb begin
  flags_o.loaded = 1'b0;

  if (w_index_q == W) begin
    w_index_d = '0;
    flags_o.loaded = 1'b1;
  end else if (clear_i) begin
    w_index_d = '0;
  end else if (ctrl_i.load && ctrl_i.y_valid) begin
    w_index_d = w_index_q + 1; 
  end else begin
    w_index_d = w_index_q;
  end
end

`FFARN(w_index_q, w_index_d, '0, buffer_clock, rst_ni);


// Combinational logic for d_index_d
logic [$clog2(D):0] d_index_d, d_index_q;

always_comb begin
  flags_o.y_pushed = 1'b0;

  if (d_index_q == D - 1 && reg_enable_i) begin
    d_index_d = '0;
    flags_o.y_pushed = 1'b1;
  end else if (clear_i) begin
    d_index_d = '0;
  end else if (ctrl_i.y_push_enable && reg_enable_i) begin
    d_index_d = d_index_q + 1;
  end else begin
    d_index_d = d_index_q;
  end
end

`FFARN(d_index_q, d_index_d, '0, buffer_clock, rst_ni);


// Main Storage Elemenet
logic [D-1:0][W-1:0][BITW-1:0] z_buffer_d, z_buffer_q;
logic [$clog2(D):0] depth;
logic [$clog2(W):0] y_width;

assign depth = (ctrl_i.cols_lftovr == '0) ? D : ctrl_i.cols_lftovr;
assign y_width = (ctrl_i.rows_lftovr == '0) ? W : ctrl_i.rows_lftovr;

always_comb begin
  z_buffer_d = z_buffer_q;
  if (clear_i) begin
    z_buffer_d = '0;
  end else if (ctrl_i.fill || ctrl_i.y_push_enable) begin
    if (reg_enable_i) begin
      for (int d = 0; d < D; d++) begin    
        for (int w = 0; w < W; w++)
          z_buffer_d[d][w] = (d == 0) ? z_buffer_i[w] : z_buffer_q[d-1][w];
      end
    end
  end else if (ctrl_i.store && ctrl_i.ready) begin
    for (int w = 0; w < W; w++) begin
      for (int d = 0; d < D; d++)
        z_buffer_d[d][w] = (w < W - 1) ? z_buffer_q[d][w+1] : '0;
    end
  end else if (ctrl_i.load && ctrl_i.y_valid) begin
    for (int d = 0; d < D; d++)
      z_buffer_d[D - d - 1][w_index_q] = (d < depth && w_index_q < y_width) ? y_buffer_i[d*BITW+:BITW] : '0;
  end
end

`FFARN(z_buffer_q, z_buffer_d, '0, buffer_clock, rst_ni);


// Output assignment
generate
  for (genvar d = 0; d < D; d++)
    assign z_buffer_o[d*BITW+:BITW] = z_buffer_q[D - d - 1][0];

  for (genvar w = 0; w < W; w++)
    assign y_buffer_o[w] = (ctrl_i.y_push_enable) ? z_buffer_q[D - 1][w] : '0;
endgenerate

endmodule : redmule_z_buffer
