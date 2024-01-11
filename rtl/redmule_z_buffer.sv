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

logic rst_store  ,
      rst_fill   ,
      rst_w_load ,
      rst_d_count;
logic                          buffer_clock;
logic [$clog2(D):0]            fill_shift , d_index, depth;
logic [$clog2(W):0]            store_shift, w_index, y_width;
logic [D-1:0][W-1:0][BITW-1:0] z_buffer_q;

tc_clk_gating i_z_buffer_clock_gating (
  .clk_i     ( clk_i                ),
  .en_i      ( ctrl_i.buffer_clk_en ),
  .test_en_i ( '0                   ),
  .clk_o     ( buffer_clock         )
);

always_ff @(posedge buffer_clock or negedge rst_ni) begin : z_buffer
  if(~rst_ni) begin
    z_buffer_q <= '0;
  end else begin
    if (clear_i)
      z_buffer_q <= '0;
    else if (ctrl_i.fill || ctrl_i.y_push_enable) begin
        if (reg_enable_i) begin
          for (int d = 0; d < D; d++) begin
            for (int w = 0; w < W; w++)
              z_buffer_q[d][w] <= (d == 0) ? z_buffer_i[w] : z_buffer_q[d-1][w];
          end
        end else
          z_buffer_q <= z_buffer_q;
    end else if (ctrl_i.store && ctrl_i.ready) begin
      for (int w = 0; w < W; w++) begin
        for (int d = 0; d < D; d++)
          z_buffer_q[d][w] <= (w < W - 1) ? z_buffer_q[d][w+1] : '0;
      end
	  end else if (ctrl_i.load && ctrl_i.y_valid) begin
	    for (int d = 0; d < D; d++)
	      z_buffer_q[D - d - 1][w_index] <= (d < depth && w_index < y_width) ? y_buffer_i[d*BITW+:BITW] : '0;
    end else
      z_buffer_q <= z_buffer_q;
  end
end

assign depth = (ctrl_i.cols_lftovr == '0) ? D : ctrl_i.cols_lftovr;
assign y_width = (ctrl_i.rows_lftovr == '0) ? W : ctrl_i.rows_lftovr;

// Counter to track when the output buffer is full
always_ff @(posedge buffer_clock or negedge rst_ni) begin : buffer_fill_counter
  if(~rst_ni) begin
    fill_shift <= '0;
  end else begin
    if (rst_fill || clear_i)
      fill_shift <= '0;
    else if (ctrl_i.fill)
      fill_shift <= fill_shift + 1; 
    else
      fill_shift <= fill_shift;
  end
end
// Reset for the fill value
always_comb begin : fill_shift_rst
  rst_fill      = 1'b0;
  flags_o.full  = 1'b0;
  if (fill_shift == D - 1 && ctrl_i.fill) begin
    rst_fill     = 1'b1;
    flags_o.full = 1'b1;
  end else begin
    rst_fill     = 1'b0;
    flags_o.full = 1'b0;
  end
end

// Counter to track the number of store rows
always_ff @(posedge buffer_clock or negedge rst_ni) begin : stored_rows_counter
  if(~rst_ni) begin
    store_shift <= '0;
  end else begin
    if (rst_store || clear_i)
      store_shift <= '0;
    else if (ctrl_i.store)
      store_shift <= store_shift + 1; 
    else
      store_shift <= store_shift;
  end
end
// Reset for the store value
always_comb begin : store_shift_rst
  rst_store     = 1'b0;
  flags_o.empty = 1'b0;
  if (store_shift == W) begin
  	rst_store     = 1'b1;
  	flags_o.empty = 1'b1;
  end else begin
    rst_store     = 1'b0;
    flags_o.empty = 1'b0;
  end
end

// Counter to track the rows that have to be loaded
always_ff @(posedge buffer_clock or negedge rst_ni) begin : row_loaded_counter
  if(~rst_ni) begin
    w_index <= '0;
  end else begin
    if (rst_w_load || clear_i)
      w_index <= '0;
    else if (ctrl_i.load && ctrl_i.y_valid)
      w_index <= w_index + 1; 
    else
      w_index <= w_index;
  end
end

always_comb begin : reset_y_load_counter
  rst_w_load     = 1'b0;
  flags_o.loaded = 1'b0;
  if (w_index == W) begin
    rst_w_load     = 1'b1;
    flags_o.loaded = 1'b1;
  end else begin
    rst_w_load     = 1'b0;
    flags_o.loaded = 1'b0;
  end
end

always_ff @(posedge buffer_clock or negedge rst_ni) begin : depth_read_counter
  if(~rst_ni) begin
    d_index <= '0;
  end else begin
    if (rst_d_count || clear_i)
      d_index <= '0;
    else if (ctrl_i.y_push_enable && reg_enable_i)
      d_index <= d_index + 1;
    else
      d_index <= d_index;
  end
end

always_comb begin : reset_depth_counter
  rst_d_count    = 1'b0;
  flags_o.y_pushed = 1'b0;
  if (d_index == D - 1 && reg_enable_i) begin
    rst_d_count    = 1'b1;
    flags_o.y_pushed = 1'b1;
  end else begin
    rst_d_count    = 1'b0;
    flags_o.y_pushed = 1'b0;
  end
end

// Output assignment
genvar d, w;
generate
  for (d = 0; d < D; d++)
    assign z_buffer_o[d*BITW+:BITW] = z_buffer_q[D - d - 1][0];

  for (w = 0; w < W; w++)
    assign y_buffer_o[w] = (ctrl_i.y_push_enable) ? z_buffer_q[D - 1][w] : '0;
endgenerate

endmodule : redmule_z_buffer
