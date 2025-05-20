// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
// Andrea Belano <andrea.belano2@unibo.it>
//

module redmule_w_buffer
  import fpnew_pkg::*;
  import redmule_pkg::*;
#(
  parameter int unsigned  DW        = 288               ,
  parameter fp_format_e   FpFormat  = FP16              ,
  parameter int unsigned  Height    = ARRAY_HEIGHT      , // Number of PEs per row
  parameter int unsigned  N_REGS    = PIPE_REGS         , // Number of registers per PE
  localparam int unsigned BITW      = fp_width(FpFormat), // Number of bits for the given format
  localparam int unsigned H         = Height            ,
  localparam int unsigned D         = DW/BITW           ,
  localparam int unsigned DWQ       = DW/(BITW/8)
)(
  input  logic                             clk_i      ,
  input  logic                             rst_ni     ,
  input  logic                             clear_i    ,
  input  w_buffer_ctrl_t                   ctrl_i     ,
  output w_buffer_flgs_t                   flags_o    ,
  output logic           [H-1:0][BITW-1:0] w_buffer_o ,
  input  logic                    [DW-1:0] w_buffer_i ,  //Normally the rows of the W matrix; in quantization mode, the vectors of scales

  input  logic                   [DWQ-1:0] qw_i       ,
  input  logic                   [DWQ-1:0] zeros_i    ,

  output logic                [H-1:0][7:0] qw_o       ,
  output logic                [H-1:0][7:0] zeros_o    ,

  input  logic             [$clog2(H)-1:0] next_gidx_i,
  input  logic                             new_gidx_i
);

localparam int unsigned C         = (D+N_REGS)/(N_REGS+1);
localparam int unsigned EL_ADDR_W = $clog2(N_REGS+1);
localparam int unsigned EL_DATA_W = (N_REGS+1)*BITW;

logic [$clog2(H):0]            w_row;

logic [H-1:0][BITW-1:0]        w_buffer_q;
logic [H-1:0][7:0]             qw_q;
logic [H-1:0][7:0]             zeros_q;

logic [EL_ADDR_W-1:0]          el_addr_d, el_addr_q;
logic [$clog2(C)-1:0]          col_addr_d, col_addr_q;

logic [D-1:0][BITW-1:0]        w_data;

logic [H-1:0][$clog2(H)-1:0]   buffer_r_addr_d, buffer_r_addr_q, wq_buffer_raddr;
logic [H-1:0]                  buffer_r_addr_valid_d, buffer_r_addr_valid_q;

logic [$clog2(H)-1:0]         evict_pointer;

logic gidx_present;

logic                 buf_write_en;
logic [$clog2(H)-1:0] buf_write_addr;

for (genvar d = 0; d < D; d++) begin : gen_zero_padding
  assign w_data[d] = (d < ctrl_i.width && w_row < ctrl_i.height) ? w_buffer_i[(d+1)*BITW-1:d*BITW] : '0;
end

assign buf_write_en   = ctrl_i.load && (~ctrl_i.dequant || ~new_gidx_i);
assign buf_write_addr = ctrl_i.dequant ? next_gidx_i : w_row;

redmule_w_buffer_scm #(
  .WORD_SIZE ( BITW     ),
  .ROWS      ( H        ),
  .COLS      ( C        ),
  .ELMS      ( N_REGS+1 )
) i_w_buf (
  .clk_i            ( clk_i           ),
  .rst_ni           ( rst_ni          ),
  .clear_i          ( clear_i         ),
  .write_en_i       ( buf_write_en    ),
  .write_addr_i     ( buf_write_addr  ),
  .wdata_i          ( w_data          ),
  .read_en_i        ( ctrl_i.shift    ),
  .elms_read_addr_i ( el_addr_q       ),
  .cols_read_offs_i ( col_addr_q      ),
  .rows_read_addr_i ( buffer_r_addr_d ),
  .rdata_o          ( w_buffer_q      )
);

redmule_w_buffer_scm #(
  .WORD_SIZE ( BITW/2   ),
  .ROWS      ( H        ),
  .COLS      ( C        ),
  .ELMS      ( N_REGS+1 )
) i_zeros_buf (
  .clk_i            ( clk_i           ),
  .rst_ni           ( rst_ni          ),
  .clear_i          ( clear_i         ),
  .write_en_i       ( buf_write_en    ),
  .write_addr_i     ( buf_write_addr  ),
  .wdata_i          ( zeros_i         ),
  .read_en_i        ( ctrl_i.shift    ),
  .elms_read_addr_i ( el_addr_q       ),
  .cols_read_offs_i ( col_addr_q      ),
  .rows_read_addr_i ( buffer_r_addr_d ),
  .rdata_o          ( zeros_q         )
);

redmule_w_buffer_scm #(
  .WORD_SIZE ( BITW/2   ),
  .ROWS      ( H        ),
  .COLS      ( C        ),
  .ELMS      ( N_REGS+1 )
) i_wq_buf (
  .clk_i            ( clk_i                ),
  .rst_ni           ( rst_ni               ),
  .clear_i          ( clear_i              ),
  .write_en_i       ( ctrl_i.load          ),
  .write_addr_i     ( w_row[$clog2(H)-1:0] ),
  .wdata_i          ( qw_i                 ),
  .read_en_i        ( ctrl_i.shift         ),
  .elms_read_addr_i ( el_addr_q            ),
  .cols_read_offs_i ( col_addr_q           ),
  .rows_read_addr_i ( wq_buffer_raddr      ),
  .rdata_o          ( qw_q                 )
);

assign flags_o.w_ready = buf_write_en;

for (genvar h = 0; h < H; h++) begin : gen_r_addr_registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      buffer_r_addr_q[h] <= h;
    end else begin
      if (clear_i) begin
        buffer_r_addr_q[h] <= h;
      end else begin   // This is loaded at the same time as the W row
        buffer_r_addr_q[h] <= buffer_r_addr_d[h];
      end
    end
  end

  always_comb begin
    buffer_r_addr_d[h] = buffer_r_addr_q[h];

    if (w_row == h && ctrl_i.load && ctrl_i.dequant) begin
      buffer_r_addr_d[h] = next_gidx_i;
    end
  end
end

for (genvar h = 0; h < H; h++) begin
  assign wq_buffer_raddr[h] = h;
end

always_ff @(posedge clk_i or negedge rst_ni) begin : element_counter
  if(~rst_ni) begin
    el_addr_q <= '0;
  end else begin
    if (clear_i)
      el_addr_q <= '0;
    else if (ctrl_i.shift)
      el_addr_q <= el_addr_d;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : section_counter
  if(~rst_ni) begin
    col_addr_q <= '0;
  end else begin
    if (clear_i)
      col_addr_q <= '0;
    else if (ctrl_i.shift)
      col_addr_q <= col_addr_d;
  end
end

assign el_addr_d  = (el_addr_q == N_REGS) ? '0 : el_addr_q + 1;
assign col_addr_d = (el_addr_q == N_REGS) ? (col_addr_q == (C-1) ? '0 : col_addr_q + 1) : col_addr_q;

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

always_comb begin : output_assignment
  w_buffer_o = w_buffer_q;
  qw_o       = qw_q;
  zeros_o    = zeros_q;

  for (int unsigned i = 0; i < H; i++) begin
    if (ctrl_i.zero_set[i]) begin
      w_buffer_o[i] = '0;
      qw_o[i]       = '0;
      zeros_o[i]    = '0;
    end
  end
end

assign flags_o.gid_repeated = new_gidx_i;

endmodule : redmule_w_buffer
