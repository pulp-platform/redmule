// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Andrea Belano <andrea.belano2@unibo.it>
//

module redmule_dequantizer
  import fpnew_pkg::*;
  import redmule_pkg::*;
#(
  parameter int unsigned           DW          = DATAW,
  parameter fpnew_pkg::fp_format_e FpFormat    = fpnew_pkg::FP16,
  parameter int unsigned           Height      = ARRAY_HEIGHT,  // Number of PEs per row
  localparam int unsigned          BITW        = fpnew_pkg::fp_width(FpFormat), // Number of bits for the given format
  localparam int unsigned          H           = Height
) (
  input  logic                             clk_i    ,
  input  logic                             rst_ni   ,
  input  logic                             clear_i  ,
  input  logic           [H-1:0][BITW-1:0] scales_i ,
  input  logic           [H-1:0][7:0]      zeros_i  ,
  input  logic           [H-1:0][7:0]      qw_i     ,
  output logic           [H-1:0][BITW-1:0] weights_o
);

  localparam int unsigned EXP_BITS = fpnew_pkg::exp_bits(FpFormat);
  localparam int unsigned MAN_BITS = fpnew_pkg::man_bits(FpFormat);

  typedef struct packed {
    logic                sign;
    logic [EXP_BITS-1:0] exponent;
    logic [MAN_BITS-1:0] mantissa;
  } fp_t;

  logic [H-1:0][9:0] int_zeros;
  logic [H-1:0][9:0] int_weighs;

  logic [H-1:0]      w_sign;
  logic [H-1:0][9:0] w_unsigned;

  fp_t  [H-1:0] scales_fp, res_pre_round;

  logic [H-1:0][MAN_BITS+10:0] mant_prod, mant_shift;

  logic [H-1:0][$clog2(11)-1:0] prod_lz;
  logic [H-1:0]                 prod_empty;

  // We use 2 sticky bits like in the FMA
  logic [H-1:0][MAN_BITS+1:0] mant_pre_round;

  logic [H-1:0] round;

  for (genvar i = 0; i < H; i++) begin: gen_rounding
    assign int_zeros[i]  = zeros_i[i] + 1;
    assign int_weighs[i] = qw_i[i] - int_zeros[i];

    assign w_sign[i]     = int_weighs[i][9];
    assign w_unsigned[i] = w_sign[i] ? {1'b0, ~int_weighs[i][8:0]} + 1 : {1'b0, int_weighs[i][8:0]};

    assign scales_fp[i]  = scales_i[i];

    assign mant_prod[i]  = {1'b1, scales_fp[i].mantissa} * w_unsigned[i];

    lzc #(
      .WIDTH ( 11 ),
      .MODE  ( 1  ) // MODE = 1 counts leading zeroes
    ) i_lzc (
      .in_i    ( mant_prod[i][MAN_BITS+10-:11] ),
      .cnt_o   ( prod_lz[i]                    ),
      .empty_o ( prod_empty[i]                 )
    );

    assign mant_shift[i]     = mant_prod[i] << (prod_lz[i] + 1);
    assign mant_pre_round[i] = mant_shift[i][MAN_BITS+10-:MAN_BITS+2]; // (9 - prod_lz);

    always_comb begin
     unique case (mant_pre_round[i][1:0])
       2'b00,
       2'b01: round[i] = 1'b0;                 // < ulp/2 away, round down
       2'b10: round[i] = mant_pre_round[i][2]; // = ulp/2 away, round towards even result
       2'b11: round[i] = 1'b1;                 // > ulp/2 away, round up
     endcase
    end

    assign res_pre_round[i].sign     = w_sign[i] ^ scales_fp[i].sign;
    assign res_pre_round[i].exponent = scales_fp[i].exponent + (10 - prod_lz[i]);
    assign res_pre_round[i].mantissa = mant_pre_round[i][MAN_BITS+1:2];

    assign weights_o[i] = prod_empty[i] ? '0 : res_pre_round[i] + round[i];
  end

endmodule
