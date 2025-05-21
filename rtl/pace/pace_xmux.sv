// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Arpan Suravi Prasad <prasadar@iis.ee.ethz.ch>
//
// This unit takes the x_buffer output and MUXes it to provide the right breakpoints and coefficients to the Engine


`ifdef PACE_ENABLED
module pace_xmux
  import fpnew_pkg::*;
  import redmule_pkg::*;
#(
  parameter int unsigned  H,
  parameter int unsigned  W,
  localparam int unsigned PIDW = redmule_pkg::PIDW,
  parameter int unsigned  BITW
)(
  input  logic [H-1:0][W-1:0][BITW-1:0]    x_input_i,
  input  logic                             enable_i,
  input  logic [H-1:0][W-1:0][PIDW-1:0]    part_id_i,
  output logic [H-1:0][W-1:0][BITW-1:0]    x_output_o
);
  logic [H-1:0][W-1:0][BITW-1:0]    pace_mux_output;
  generate
    for (genvar w = 0; w < W; w++) begin : gen_along_row
      localparam int GroupSize = 1 << w;
      if (w < PACE_PART_BST_STAGES) begin : gen_along_col_BST_part_stages
        for (genvar h = 0; h < H; h++) begin : gen_along_col
          if (GroupSize == 1) begin : gen_single_group
            assign pace_mux_output[h][w] = x_input_i[h][w];
          end else begin : gen_grouped
            localparam int GroupIndex = (h % (PACE_PART_BST_STAGES+PACE_NPOLY+1)) / GroupSize;
            logic [BITW-1:0] x_flat_array [GroupSize];
            for (genvar gid = 0; gid < GroupSize; gid++) begin : gen_gid_loop
              localparam int BstIndex = GroupIndex * GroupSize + gid;
              assign x_flat_array[gid] = x_input_i[BstIndex][w];
            end
            assign pace_mux_output[h][w] = x_flat_array[part_id_i[h][w]];
          end
        end
      end else if (w <= PACE_PART_BST_STAGES+PACE_NPOLY) begin : gen_along_col_poly_stages
        for (genvar h = 0; h < H; h++) begin : gen_along_col
          logic [BITW-1:0] x_flat_array [H];
          for (genvar gid = 0; gid < H; gid++) begin : gen_gid
            assign x_flat_array[gid] = x_input_i[gid][w];
          end
          assign pace_mux_output[h][w] = x_flat_array[part_id_i[h][w]];
        end
      end else begin : gen_zeros
        for (genvar h = 0; h < H; h++) begin : gen_along_col
          assign pace_mux_output[h][w] = '0;
        end
      end
    end
  endgenerate

  assign x_output_o = enable_i ? pace_mux_output : x_input_i;
endmodule
`endif
