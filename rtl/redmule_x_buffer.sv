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

`include "redundancy_cells/voters.svh"
`include "common_cells/registers.svh"

module redmule_x_buffer
  import fpnew_pkg::*;
  import redmule_pkg::*;
#(
parameter int unsigned           DW        = 288,
parameter fpnew_pkg::fp_format_e FpFormat  = fpnew_pkg::FP16,
parameter int unsigned           Height    = ARRAY_HEIGHT,  // Number of PEs per row
parameter int unsigned           Width     = ARRAY_WIDTH,   // Number of parallel index
parameter int unsigned           REP       = 1,             // Number of Replicas of Internal FSM
localparam int unsigned          BITW      = fpnew_pkg::fp_width(FpFormat), // Number of bits for the given format                          
localparam int unsigned          H         = Height,
localparam int unsigned          W         = Width,
localparam int unsigned          D         = DW/(H*BITW),
localparam int unsigned          HALF_D    = D/2,
localparam int unsigned          TOT_DEPTH = H*D
)(
  input  logic                                               clk_i,
  input  logic                                               rst_ni,
  input  logic                                     [REP-1:0] clear_i, 
  input  x_buffer_ctrl_t                           [REP-1:0] ctrl_i,
  output x_buffer_flgs_t                           [REP-1:0] flags_o,
  output logic                      [W-1:0][H-1:0][BITW-1:0] x_buffer_o,
  input logic                                       [DW-1:0] x_buffer_i,
  output logic                                               fault_o
);

// W Index Counnter
logic [REP-1:0][$clog2(W):0] w_index_b, w_index_v, w_index_d, w_index_q;
logic [REP-1:0][$clog2(W):0] w_limit_v;
logic w_fault;

for (genvar r = 0; r < REP; r++) begin: gen_w_counter_next_state
  assign w_limit_v[r] = (ctrl_i[r].rows_lftovr != '0) ? ctrl_i[r].rows_lftovr : W;

  always_comb begin
    flags_o[r].full = 1'b0;

    if (w_index_q[r] == w_limit_v[r] || w_index_q[r] == W) begin
      w_index_v[r] = '0;
      flags_o[r].full = 1'b1;
    end else if (clear_i[r]) begin
      w_index_v[r] = '0;
    end else if (ctrl_i[r].load) begin
      w_index_v[r] = w_index_q[r] + 1;
    end else begin
      w_index_v[r] = w_index_q[r];
    end
  end
end

`VOTEXXF(REP, w_index_v, w_index_d, w_fault);

for (genvar r = 0; r < REP; r++) begin: gen_w_counter_default_state
  assign w_index_b[r] = '0;
end

`FF(w_index_q, w_index_d, w_index_b);

// Depth Shift Counter with partial deactivation
logic [REP-1:0][$clog2(D):0] d_shift_b, d_shift_v, d_shift_d, d_shift_q;
logic [REP-1:0][$clog2(D):0] empty_count_b, empty_count_v, empty_count_d, empty_count_q;
logic [REP-1:0][$clog2(TOT_DEPTH):0] depth_v;
logic [REP-1:0]rst_d_shift_v, rst_empty_v;
logic depth_fault, empty_fault;

for (genvar r = 0; r < REP; r++) begin: gen_d_shift_next_state
  always_comb begin
    if (rst_d_shift_v[r] || clear_i[r]) begin
      d_shift_v[r] = '0;
    end else if (ctrl_i[r].blck_shift) begin
      d_shift_v[r] = d_shift_q[r] + 2;
    end else if (ctrl_i[r].d_shift) begin
      d_shift_v[r] = d_shift_q[r] + 1;
    end else begin
      d_shift_v[r] = d_shift_q[r];
    end
  end
end

`VOTEXXF(REP, d_shift_v, d_shift_d, depth_fault);

for (genvar r = 0; r < REP; r++) begin: gen_d_shift_default_state
  assign d_shift_b[r] = '0;
end

`FF(d_shift_q, d_shift_d, d_shift_b);

for (genvar r = 0; r < REP; r++) begin: gen_empty_next_state
  always_comb begin
    if (clear_i[r] || rst_empty_v[r]) begin
      empty_count_v[r] = D;
    end else if (ctrl_i[r].cols_lftovr != '0) begin
      empty_count_v[r] = ctrl_i[r].slots;
    end else begin
      empty_count_v[r] = empty_count_q[r];
    end
  end
end

`VOTEXXF(REP, empty_count_v, empty_count_d, empty_fault);

for (genvar r = 0; r < REP; r++) begin: gen_empty_default_state
  assign empty_count_b[r] = '0;
end

`FF(empty_count_q, empty_count_d, empty_count_b);

for (genvar r = 0; r < REP; r++) begin: gen_depth_shift_counter_reset
  always_comb begin : empty_gen_and_shift_count_rst
    flags_o[r].empty = 1'b0;
    rst_d_shift_v[r] = 1'b0;
    rst_empty_v[r] = 1'b0;

    if (d_shift_q[r] == empty_count_q[r]) begin
      flags_o[r].empty = 1'b1;
      rst_d_shift_v[r] = 1'b1;
      if (empty_count_q[r] != depth_v[r]) begin
        rst_empty_v[r] = 1'b1;
      end
    end
  end

  assign depth_v[r] = (ctrl_i[r].cols_lftovr == '0) ? TOT_DEPTH : ctrl_i[r].cols_lftovr;
end


// H shift counter
logic [REP-1:0][$clog2(H)-1:0] h_index_b, h_index_v, h_index_d, h_index_q;
logic h_counter_fault;

for (genvar r = 0; r < REP; r++) begin: gen_h_counter_next_state
  always_comb begin
    if (clear_i[r]) begin
      h_index_v[r] = '0;
    end else if (ctrl_i[r].h_shift) begin
      h_index_v[r] = h_index_q[r] + 1;
    end else begin
      h_index_v[r] = h_index_q[r];
    end
  end
end

`VOTEXXF(REP, h_index_v, h_index_d, h_counter_fault);

for (genvar r = 0; r < REP; r++) begin: gen_h_counter_default_state
  assign h_index_b[r] = '0;
end

`FF(h_index_q, h_index_d, h_index_b);

// From here on out we use the signal of the first replica.
// If a fault happens on it then we can detect it since there is no more recursive dependency

// Main storage element
logic [D-1:0][W-1:0][H-1:0][BITW-1:0]     x_pad_d, x_pad_q;
logic [(D/2)-1:0][W-1:0][H-1:0][BITW-1:0] x_buffer_d, x_buffer_q;

always_comb begin
  if (clear_i[0]) begin
      x_pad_d = '0;
      x_buffer_d = '0;

  end else begin
    x_pad_d = x_pad_q;
    x_buffer_d = x_buffer_q;
    if (ctrl_i[0].load) begin
      for (int d = 0; d < D; d++) begin
        for (int h = 0; h < H; h++) begin
          x_pad_d[d][w_index_q[0]][h] = ((H * d + h) < depth_v[0]) ? x_buffer_i[(H * d + h) * BITW +: BITW] : '0;
        end
      end
    end
    if (ctrl_i[0].d_shift) begin
      for (int w = 0; w < W; w++) begin
        for (int h = 0; h < H; h++) begin
          for (int d = 0; d < D; d++) begin
            x_pad_d[d][w][h] = (d < D - 1) ? x_pad_q[d + 1][w][h] : '0;
          end
          x_buffer_d[HALF_D - 1][w][h] = x_pad_q[0][w][h];
        end
      end
    end
    if (ctrl_i[0].blck_shift) begin
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
    if (ctrl_i[0].h_shift) begin
      for (int w = 0; w < W; w++) begin
        for (int h = 0; h < H; h++) begin
          x_buffer_d[0][w][h_index_q[0]] = x_buffer_q[1][w][h_index_q[0]];
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

assign fault_o = w_fault || depth_fault || empty_fault || h_counter_fault;

endmodule : redmule_x_buffer
