// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
//

module redmule_w_buffer
  import fpnew_pkg::*;
  import redmule_pkg::*;
#(
parameter int unsigned  DW       = 288               ,
parameter fp_format_e   FpFormat = FP16              ,
parameter int unsigned  Height   = ARRAY_HEIGHT      , // Number of PEs per row
localparam int unsigned BITW     = fp_width(FpFormat), // Number of bits for the given format                          
localparam int unsigned H        = Height            ,
localparam int unsigned D        = DW/BITW
)(
  input  logic                             clk_i     ,
  input  logic                             rst_ni    ,
  input  logic                             clear_i   ,
  input  w_buffer_ctrl_t                   ctrl_i    ,
  output w_buffer_flgs_t                   flags_o   ,
  output logic           [H-1:0][BITW-1:0] w_buffer_o,
  input logic                     [DW-1:0] w_buffer_i
);

logic [$clog2(H):0]            w_row;
logic [$clog2(H):0]            count_limit;
logic [$clog2(D):0]            depth;
logic [H-1:0][D-1:0][BITW-1:0] w_buffer_q;

always_ff @(posedge clk_i or negedge rst_ni) begin : w_trailer
  if(~rst_ni) begin
    w_buffer_q <= '0;
  end else begin
    if (clear_i)
      w_buffer_q <= '0;
    else if ({ctrl_i.load, ctrl_i.shift} == 2'b10 || {ctrl_i.load, ctrl_i.shift} == 2'b11) begin
      for (int d = 0; d < D; d++) begin
        w_buffer_q[w_row][d] <= (d < depth && w_row < count_limit) ? w_buffer_i[d*BITW+:BITW] : '0;
        for (int h = 0; h < H; h++) begin
          if (h != w_row)
             w_buffer_q[h][d] <= (d < D - 1) ? w_buffer_q[h][d+1] : '0;
        end
      end
    end else if ({ctrl_i.load, ctrl_i.shift} == 2'b01) begin
      for (int h = 0; h < H; h++) begin
        for (int d = 0; d < D; d++)
          w_buffer_q[h][d] <= (d < D - 1) ? w_buffer_q[h][d+1] : '0;
      end
    end else 
      w_buffer_q <= w_buffer_q; 
  end
end

// Counter to track the number of shifts per row
always_ff @(posedge clk_i or negedge rst_ni) begin : row_load_counter
  if(~rst_ni) begin
    w_row <= '0;
  end else begin	
    if (clear_i || w_row == H )
      w_row <= '0;
    else if (ctrl_i.load)
      w_row <= w_row + 1; 
    else
      w_row <= w_row;	
  end
end

assign depth       = (ctrl_i.cols_lftovr == '0) ? D : ctrl_i.cols_lftovr;
assign count_limit = (ctrl_i.rows_lftovr != '0) ? ctrl_i.rows_lftovr : Height;

// Output assignment
generate
  for (genvar h = 0; h < H; h++)
    assign w_buffer_o[h] = w_buffer_q[h][0];
endgenerate

endmodule : redmule_w_buffer
