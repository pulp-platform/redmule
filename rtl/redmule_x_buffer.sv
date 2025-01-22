// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
// Andrea Belano <andrea.belano2@unibo.it>
//

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
  input  logic                                               clk_i      ,
  input  logic                                               rst_ni     ,
  input  logic                                               clear_i    ,
  input  x_buffer_ctrl_t                                     ctrl_i     ,
  output x_buffer_flgs_t                                     flags_o    ,
  output logic                      [W-1:0][H-1:0][BITW-1:0] x_buffer_o ,
  input  logic                                      [DW-1:0] x_buffer_i ,
  input  logic                             [$clog2(D*H)-1:0] next_wrow_i,   //Tentative name
  output logic                                               next_wrow_ready_o 
);

logic                           rst_w_load, rst_d_shift, rst_h_shift, empty_rst;
logic [$clog2(W):0]             w_index, w_limit;
logic [$clog2(H)-1:0]           h_index_r, h_index_w;
logic [$clog2(D):0]             d_shift, empty_count, empty_count_q;
logic [$clog2(TOT_DEPTH):0]     depth;
logic [W-1:0][BITW-1:0]         x_pad_q;
logic [H-1:0][W-1:0][BITW-1:0]  x_buffer_q;

logic [$clog2(TOT_DEPTH)-1:0]   pad_r_addr_d, pad_r_addr_q;
logic                           buf_r_addr, buf_w_addr;

logic h_shift_del;

logic first_block, refilling;

logic pad_read_enable;

always_ff @(posedge clk_i or negedge rst_ni) begin : first_block_register
  if(~rst_ni) begin
    first_block <= '0;
  end else begin
    if (clear_i || pad_r_addr_q == 2*H-1)
      first_block <= '0;
    else if (ctrl_i.blck_shift || flags_o.full)
      first_block <= '1;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : refill_flag_register
  if(~rst_ni) begin
    refilling <= '0;
  end else begin
    if (clear_i || flags_o.full)
      refilling <= '0;
    else if (flags_o.empty)
      refilling <= '1;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : h_shift_delay
  if(~rst_ni) begin
    h_shift_del <= '0;
  end else begin
    if (clear_i)
      h_shift_del <= '0;
    else if (first_block)
      h_shift_del <= ctrl_i.h_shift;
  end
end

for (genvar w = 0; w < W; w++) begin : gen_x_pad
  redmule_fifo_scm #(
    .ADDR_WIDTH ( $clog2(TOT_DEPTH) ),
    .DATA_WIDTH ( BITW              ),
    .N_INPUTS   ( TOT_DEPTH         ) 
  ) (
    .clk          ( clk_i                                                                          ),
    .rst_n        ( rst_ni                                                                         ),
    .ReadEnable   ( ctrl_i.h_shift && ~refilling || h_shift_del && first_block || ctrl_i.pad_setup ),
    .ReadAddr     ( ctrl_i.dequant ? next_wrow_i : ctrl_i.pad_setup ? '0 : pad_r_addr_d            ),
    .ReadData     ( x_pad_q[w]                                                                     ),
    .WriteEnable  ( w_index == w && ctrl_i.load                                                    ),
    .WriteAddr    ( '0                                                                             ),
    .WriteData    ( x_buffer_i                                                                     )
  );
end

assign pad_read_enable = ctrl_i.h_shift && ~refilling || h_shift_del && first_block || ctrl_i.pad_setup;

for (genvar h = 0; h < H; h++) begin : gen_x_buf
  redmule_fifo_scm #(
    .ADDR_WIDTH ( 1       ),
    .DATA_WIDTH ( W*BITW  ),
    .N_INPUTS   ( 1       ) 
  ) (
    .clk          ( clk_i                                                                           ),
    .rst_n        ( rst_ni                                                                          ),
    .ReadEnable   ( ctrl_i.h_shift && h_index_r == h                                                ),
    .ReadAddr     ( buf_r_addr                                                                      ),
    .ReadData     ( x_buffer_q[h]                                                                   ),
    .WriteEnable  ( (ctrl_i.h_shift && ~refilling || h_shift_del && first_block) && h_index_w == h  ),
    .WriteAddr    ( buf_w_addr                                                                      ),
    .WriteData    ( x_pad_q                                                                         )
  );
end

assign buf_w_addr = (first_block && pad_r_addr_q < H) ? buf_r_addr : ~buf_r_addr;
assign h_index_w  = first_block ? 2*h_index_r - h_shift_del : h_index_r;

always_ff @(posedge clk_i or negedge rst_ni) begin : x_pad_read_pointer
  if(~rst_ni) begin
    pad_r_addr_q <= '0;
  end else begin
    if (clear_i || rst_h_shift)
      pad_r_addr_q <= '0;
    else if (ctrl_i.h_shift && ~refilling || h_shift_del && first_block /*|| ctrl_i.pad_setup*/)
      pad_r_addr_q <= pad_r_addr_d;
  end
end

assign pad_r_addr_d = (pad_r_addr_q < TOT_DEPTH) ? pad_r_addr_q + 1 : '0;

always_ff @(posedge clk_i or negedge rst_ni) begin : h_read_pointer
  if(~rst_ni) begin
    buf_r_addr <= '0;
  end else begin
    if (clear_i)
      buf_r_addr <= '0;
    else if ((ctrl_i.d_shift && ~first_block) || (first_block && (pad_r_addr_q == 2*H-1)))
      buf_r_addr <= buf_r_addr + 1;
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
      else
        empty_count_q <= empty_count_q;
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
    if (empty_count_q != depth)
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
    h_index_r <= '0;
  end else begin
    if (rst_h_shift || clear_i)
      h_index_r <= '0;
    else if(ctrl_i.h_shift)
      h_index_r <= h_index_r + 1;
    else
      h_index_r <= h_index_r;
  end
end

assign next_wrow_ready_o = pad_read_enable;

// Output assignment
// verilog_lint: waive-start generate-label
generate
  for (genvar w = 0; w < W; w++) begin
    for (genvar h = 0; h < H; h++) begin
      assign x_buffer_o[w][h] = x_buffer_q[h][w];
    end
  end
endgenerate
// verilog_lint: waive-stop generate-label

endmodule : redmule_x_buffer
