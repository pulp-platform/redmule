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

`include "redundancy_cells/voters.svh"
`include "common_cells/registers.svh"

module redmule_z_buffer
  import fpnew_pkg::*;
  import redmule_pkg::*;
#(
parameter int unsigned           DW       = 288,
parameter fpnew_pkg::fp_format_e FpFormat = fpnew_pkg::FP16,
parameter int unsigned           Width    = ARRAY_WIDTH,   // Number of parallel index
parameter int unsigned           REP      = 1,             // Number of Replicas of Internal FSM
localparam int unsigned          BITW     = fpnew_pkg::fp_width(FpFormat), // Number of bits for the given format                          
localparam int unsigned          W        = Width,
localparam int unsigned          D        = DW/BITW
)(
  input  logic                             clk_i,
  input  logic                             rst_ni,
  input  logic                   [REP-1:0] clear_i,
  input  logic                   [REP-1:0] reg_enable_i,
  input  z_buffer_ctrl_t         [REP-1:0] ctrl_i,
  input  logic           [W-1:0][BITW-1:0] z_buffer_i,
  input  logic                    [DW-1:0] y_buffer_i,
  output logic                    [DW-1:0] z_buffer_o,
  output logic           [W-1:0][BITW-1:0] y_buffer_o,
  output z_buffer_flgs_t         [REP-1:0] flags_o,
  output logic                             fault_o
);

logic [REP-1:0] buffer_clock;
for (genvar r = 0; r < REP; r++) begin: gen_clock_gate_cells
  tc_clk_gating i_z_buffer_clock_gating (
    .clk_i     ( clk_i                   ),
    .en_i      ( ctrl_i[r].buffer_clk_en ),
    .test_en_i ( '0                      ),
    .clk_o     ( buffer_clock[r]         )
  );
end

// Counter to track when the output buffer is full
logic [REP-1:0][$clog2(D):0] fill_shift_b, fill_shift_v, fill_shift_d, fill_shift_q;
logic fill_shift_fault;

for (genvar r = 0; r < REP; r++) begin: gen_full_counter_next_state
  always_comb begin
    flags_o[r].full = 1'b0;

    if (fill_shift_q[r] == D - 1 && ctrl_i[r].fill) begin
      fill_shift_v[r] = '0;
      flags_o[r].full = 1'b1;
    end else if (clear_i[r]) begin
      fill_shift_v[r] = '0;
    end else if (ctrl_i[r].fill) begin
      fill_shift_v[r] = fill_shift_q[r] + 1; 
    end else begin
      fill_shift_v[r] = fill_shift_q[r];
    end
  end
end

`VOTEXXF(REP, fill_shift_v, fill_shift_d, fill_shift_fault);

for (genvar r = 0; r < REP; r++) begin: gen_full_counter_default_state
  assign fill_shift_b[r] = '0;
end

for (genvar r = 0; r < REP; r++) begin: gen_full_counter_clock_gated_ffs
  `FFARN(fill_shift_q[r], fill_shift_d[r], fill_shift_b[r], buffer_clock[r], rst_ni);
end

// Counter to track the number of store rows
logic [REP-1:0][$clog2(W):0] store_shift_b, store_shift_v, store_shift_d, store_shift_q;
logic store_index_fault;

for (genvar r = 0; r < REP; r++) begin: gen_store_rows_next_state
  always_comb begin
    flags_o[r].empty = 1'b0;

    if (store_shift_q[r] == W) begin
      store_shift_v[r] = '0;
      flags_o[r].empty = 1'b1;
    end else if (clear_i[r]) begin
      store_shift_v[r] = '0;
    end else if (ctrl_i[r].store) begin
      store_shift_v[r] = store_shift_q[r] + 1; 
    end else begin
      store_shift_v[r] = store_shift_q[r];
    end
  end
end

`VOTEXXF(REP, store_shift_v, store_shift_d, store_index_fault);

for (genvar r = 0; r < REP; r++) begin: gen_store_rows_default_state
  assign store_shift_b[r] = '0;
end

for (genvar r = 0; r < REP; r++) begin: gen_store_rows_clock_gated_ffs
  `FFARN(store_shift_q[r], store_shift_d[r], store_shift_b[r], buffer_clock[r], rst_ni);
end

// Counter to track the rows that have to be loaded
logic [REP-1:0][$clog2(W):0] w_index_b, w_index_v, w_index_d, w_index_q;
logic w_index_fault;

for (genvar r = 0; r < REP; r++) begin: gen_load_rows_next_state
  always_comb begin
    flags_o[r].loaded = 1'b0;

    if (w_index_q[r] == W) begin
      w_index_v[r] = '0;
      flags_o[r].loaded = 1'b1;
    end else if (clear_i[r]) begin
      w_index_v[r] = '0;
    end else if (ctrl_i[r].load && ctrl_i[r].y_valid) begin
      w_index_v[r] = w_index_q[r] + 1; 
    end else begin
      w_index_v[r] = w_index_q[r];
    end
  end
end

`VOTEXXF(REP, w_index_v, w_index_d, w_index_fault);

for (genvar r = 0; r < REP; r++) begin: gen_load_rows_default_state
  assign w_index_b[r] = '0;
end

for (genvar r = 0; r < REP; r++) begin: gen_load_rows_clock_gated_ffs
  `FFARN(w_index_q[r], w_index_d[r], w_index_b[r], buffer_clock[r], rst_ni);
end

// Combinational logic for d_index_d
logic [REP-1:0][$clog2(D):0] d_index_b, d_index_v, d_index_d, d_index_q;
logic d_index_fault;

for (genvar r = 0; r < REP; r++) begin: gen_d_index_next_state
  always_comb begin
    flags_o[r].y_pushed = 1'b0;

    if (d_index_q[r] == D - 1 && reg_enable_i[r]) begin
      d_index_v[r] = '0;
      flags_o[r].y_pushed = 1'b1;
    end else if (clear_i[r]) begin
      d_index_v[r] = '0;
    end else if (ctrl_i[r].y_push_enable && reg_enable_i[r]) begin
      d_index_v[r] = d_index_q[r] + 1;
    end else begin
      d_index_v[r] = d_index_q[r];
    end
  end
end

`VOTEXXF(REP, d_index_v, d_index_d, d_index_fault);

for (genvar r = 0; r < REP; r++) begin: gen_d_index_default_state
  assign d_index_b[r] = '0;
end

for (genvar r = 0; r < REP; r++) begin: gen_d_index_clock_gated_ffs
  `FFARN(d_index_q[r], d_index_d[r], d_index_b[r], buffer_clock[r], rst_ni);
end

// From here on out we use the signal of the first replica.
// If a fault happens on it then we can detect it since there is no more recursive dependency

// Main Storage Elemenet
logic [D-1:0][W-1:0][BITW-1:0] z_buffer_d, z_buffer_q;
logic [$clog2(D):0] depth;
logic [$clog2(W):0] y_width;

assign depth = (ctrl_i[0].cols_lftovr == '0) ? D : ctrl_i[0].cols_lftovr;
assign y_width = (ctrl_i[0].rows_lftovr == '0) ? W : ctrl_i[0].rows_lftovr;

always_comb begin
  z_buffer_d = z_buffer_q;
  if (clear_i[0]) begin
    z_buffer_d = '0;
  end else if (ctrl_i[0].fill || ctrl_i[0].y_push_enable) begin
    if (reg_enable_i[0]) begin
      for (int d = 0; d < D; d++) begin    
        for (int w = 0; w < W; w++)
          z_buffer_d[d][w] = (d == 0) ? z_buffer_i[w] : z_buffer_q[d-1][w];
      end
    end
  end else if (ctrl_i[0].store && ctrl_i[0].ready) begin
    for (int w = 0; w < W; w++) begin
      for (int d = 0; d < D; d++)
        z_buffer_d[d][w] = (w < W - 1) ? z_buffer_q[d][w+1] : '0;
    end
  end else if (ctrl_i[0].load && ctrl_i[0].y_valid) begin
    for (int d = 0; d < D; d++)
      z_buffer_d[D - d - 1][w_index_q[0]] = (d < depth && w_index_q[0] < y_width) ? y_buffer_i[d*BITW+:BITW] : '0;
  end
end

`FFARN(z_buffer_q, z_buffer_d, '0, buffer_clock[0], rst_ni);


// Output assignment
generate
  for (genvar d = 0; d < D; d++)
    assign z_buffer_o[d*BITW+:BITW] = z_buffer_q[D - d - 1][0];

  for (genvar w = 0; w < W; w++)
    assign y_buffer_o[w] = (ctrl_i[0].y_push_enable) ? z_buffer_q[D - 1][w] : '0;
endgenerate

assign fault_o = fill_shift_fault || store_index_fault || w_index_fault || d_index_fault;

endmodule : redmule_z_buffer
