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
 * RedMulE W Buffer
 */

`include "redundancy_cells/voters.svh"
`include "common_cells/registers.svh"

module redmule_w_buffer
  import fpnew_pkg::*;
  import redmule_pkg::*;
#(
parameter int unsigned  DW       = 288               ,
parameter fp_format_e   FpFormat = FP16              ,
parameter int unsigned  Height   = ARRAY_HEIGHT      , // Number of PEs per row
parameter int unsigned  REP      = 1                 , // Number of Replicas of Internal FSM
localparam int unsigned BITW     = fp_width(FpFormat), // Number of bits for the given format
localparam int unsigned H        = Height            ,
localparam int unsigned D        = DW/BITW
)(
  input  logic                             clk_i     ,
  input  logic                             rst_ni    ,
  input  logic                   [REP-1:0] clear_i   ,
  input  w_buffer_ctrl_t         [REP-1:0] ctrl_i    ,
  output w_buffer_flgs_t         [REP-1:0] flags_o   ,
  output logic           [H-1:0][BITW-1:0] w_buffer_o,
  input logic                     [DW-1:0] w_buffer_i,
  output logic                             fault_o
);


  // Counter to track the number of shifts per row
  logic [REP-1:0][$clog2(H):0]    w_row_b, w_row_v, w_row_d, w_row_q;

  for (genvar r = 0; r < REP; r++) begin: gen_next_state
    always_comb begin : row_load_counter
        if (clear_i[r])
          w_row_v[r] = '0;
        else if (ctrl_i[r].load)
          w_row_v[r] = (w_row_q[r] + 1) % H;
        else
          w_row_v[r] = w_row_q[r];
    end
  end

  `VOTEXXF(REP, w_row_v, w_row_d, fault_o);

  // Default State
  for (genvar r = 0; r < REP; r++) begin: gen_default_state
    assign w_row_b[r] = '0;
  end

  `FF(w_row_q, w_row_d, w_row_b);

  // From here on out we use the signal of the first replica.
  // If a fault happens on it then we can detect it since there is no more recursive dependency

  // Find out usable bounds
  logic [$clog2(H):0]            count_limit;
  logic [$clog2(D):0]            depth;

  assign depth       = (ctrl_i[0].cols_lftovr == '0) ? D : ctrl_i[0].cols_lftovr;
  assign count_limit = (ctrl_i[0].rows_lftovr == '0) ? H : ctrl_i[0].rows_lftovr;

  // Main storage element
  logic [D-1:0][H-1:0][BITW-1:0] w_buffer_d, w_buffer_q;

  always_comb begin: w_trailer_comb
    if (clear_i[0]) begin
      w_buffer_d = '0;

    end else if (ctrl_i[0].shift | ctrl_i[0].load) begin // Load always means shift as well

      // Shift elements in in d direction
      for (int d = 0; d < D - 1; d++) w_buffer_d[d] = w_buffer_q[d+1];
      w_buffer_d[D - 1] = '0;

      // If load is set Overwrite (!) elements in w_row_q
      if (ctrl_i[0].load) begin
        for (int d = 0; d < D; d++) begin
          // Elements outside of usable bounds get set to 0
          if (d < depth && w_row_q[0] < count_limit) begin
            w_buffer_d[d][w_row_q[0]] = w_buffer_i[d*BITW+:BITW];
          end else begin
            w_buffer_d[d][w_row_q[0]] = '0;
          end
        end
      end

    end else begin
        w_buffer_d = w_buffer_q;
    end
  end

  `FF(w_buffer_q, w_buffer_d, '0);

  // Output assignment
  assign w_buffer_o = w_buffer_q[0];

endmodule : redmule_w_buffer
