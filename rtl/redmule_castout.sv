// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
//


module redmule_castout
  import fpnew_pkg::*;
  import hci_package::*;
  import redmule_pkg::*;
#(
  parameter fpnew_pkg::fmt_logic_t   FpFmtConfig  = 6'b001101,
  parameter fpnew_pkg::ifmt_logic_t  IntFmtConfig = 4'b1000,
  parameter fpnew_pkg::fp_format_e   SrcFormat    = FP16,
  parameter fpnew_pkg::operation_e   Operation    = F2F,
  parameter logic Pipe                            = 1'b0    ,
  parameter int unsigned             DataW        = 0,
  localparam int unsigned BW = hci_package::DEFAULT_BW      ,
  localparam int unsigned UW = hci_package::DEFAULT_UW      ,
  localparam int unsigned WIDTH = fpnew_pkg::maximum(fpnew_pkg::max_fp_width(FpFmtConfig),
                                                     fpnew_pkg::max_int_width(IntFmtConfig))
)(
  input  logic                   clk_i    ,
  input  logic                   rst_ni   ,
  input  logic                   clear_i  ,
  input  logic                   cast_i   ,
  input  logic [DataW-1:0]       src_i    ,
  input  fpnew_pkg::fp_format_e  dst_fmt_i,
  output logic [DataW-1:0]       dst_o
);

localparam int unsigned NUM_CAST = DataW/fp_width(SrcFormat);
localparam int unsigned NARRBITW = fpnew_pkg::fp_width(fpnew_pkg::FP8);
// localparam int unsigned ZEROBITS = WIDTH - NARRBITW;
localparam int unsigned ZEROBITS = fpnew_pkg::min_fp_width(FpFmtConfig);
localparam int unsigned MIN_FMT  = fpnew_pkg::min_fp_width(FpFmtConfig);
localparam fpnew_pkg::int_format_e INT_SRC = fpnew_pkg::INT8;
localparam int unsigned DW_RATIO = fp_width(SrcFormat)/min_fp_width(FpFmtConfig);

logic [DataW-1:0]  dst_int,
                   res;
logic [NUM_CAST-1:0][WIDTH-1:0] result ,
                                operand;

generate
  for (genvar i = 0; i < NUM_CAST; i++) begin : gen_cast_units

    assign operand [i] = src_i[i*WIDTH+:WIDTH];

    fpnew_cast_multi  #(
      .FpFmtConfig     ( FpFmtConfig  ),
      .IntFmtConfig    ( IntFmtConfig )
    ) redmule_cast_i   (
      .clk_i           ( clk_i          ),
      .rst_ni          ( rst_ni         ),
      .operands_i      ( operand [i]    ),
      .is_boxed_i      ( '1             ),
      .rnd_mode_i      ( fpnew_pkg::RNE ),
      .op_i            ( Operation      ),
      .op_mod_i        ( '0             ),
      .src_fmt_i       ( SrcFormat      ),
      .dst_fmt_i       ( dst_fmt_i      ),
      .int_fmt_i       ( INT_SRC        ),
      .tag_i           ( '0             ),
      .mask_i          ( '0             ),
      .aux_i           ( '0             ),
      .in_valid_i      ( '1             ),
      .in_ready_o      (                ),
      .flush_i         ( '0             ),
      .result_o        ( result [i]     ),
      .status_o        (                ),
      .extension_bit_o (                ),
      .tag_o           (                ),
      .mask_o          (                ),
      .aux_o           (                ),
      .out_valid_o     (                ),
      .out_ready_i     ( '1             ),
      .busy_o          (                )
    );

    assign  res [i*MIN_FMT+:MIN_FMT] = result[i][WIDTH-MIN_FMT-1:0];

  end

endgenerate

assign dst_int = {{DataW/DW_RATIO{1'b0}}, res[DataW/DW_RATIO-1:0]};

assign dst_o = cast_i ? dst_int : src_i;

endmodule : redmule_castout
