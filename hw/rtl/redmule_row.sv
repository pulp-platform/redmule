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
 * RedMulE Row of Computing Elements
 */

module redmule_row
  import fpnew_pkg::*;
#(
  parameter fpnew_pkg::fp_format_e    FpFormat    = fpnew_pkg::FP16,
  parameter int unsigned              Height      = 4,                             // Number of PEs per row
  parameter int unsigned              NumPipeRegs = 2,
  parameter fpnew_pkg::pipe_config_t  PipeConfig  = fpnew_pkg::DISTRIBUTED,
  parameter type                      TagType     = logic,
  parameter type                      AuxType     = logic,
  localparam int unsigned             BITW        = fpnew_pkg::fp_width(FpFormat), // Number of bits for the given format
  localparam int unsigned             H           = Height
)(
  input  logic                                      clk_i             ,
  input  logic                                      rst_ni            ,
  // Input Elements                                                   
  input  logic                    [H-1:0][BITW-1:0] x_input_i         ,
  input  logic                    [H-1:0][BITW-1:0] w_input_i         ,
  input  logic                           [BITW-1:0] y_bias_i          ,
  // Output Result                                                    
  output logic                           [BITW-1:0] z_output_o        ,
  // fpnew_fma Input Signals                                          
  input  logic                    [2:0]             fma_is_boxed_i    ,
  input  logic                    [1:0]             noncomp_is_boxed_i,
  input  fpnew_pkg::roundmode_e                     stage1_rnd_i      ,
  input  fpnew_pkg::roundmode_e                     stage2_rnd_i      ,
  input  fpnew_pkg::operation_e                     op1_i             ,
  input  fpnew_pkg::operation_e                     op2_i             ,
  input  logic                                      op_mod_i          ,
  input  TagType                                    tag_i             ,
  input  AuxType                                    aux_i             ,
  // fpnew_fma Input Handshake
  input  logic                                      in_valid_i     ,
  output logic                    [H-1:0]           in_ready_o     ,
  input  logic                                      reg_enable_i   ,
  input  logic                                      flush_i        ,
  // fpnew_fma Output signals
  output fpnew_pkg::status_t      [H-1:0]           status_o       ,
  output logic                    [H-1:0]           extension_bit_o,
  output fpnew_pkg::classmask_e   [H-1:0]           class_mask_o   ,
  output logic                    [H-1:0]           is_class_o     ,
  output TagType                  [H-1:0]           tag_o          ,
  output AuxType                  [H-1:0]           aux_o          ,
  // fpnew_fma Output handshake   
  output logic                    [H-1:0]           out_valid_o    ,
  input  logic                                      out_ready_i    ,
  // fpnew_fma Indication of valid data in flight   
  output logic                    [H-1:0]           busy_o
);

// Local signals for operands assign: elemnts 0 and 1 are addressed to multiplication,
// element 2 is destined to accumulation.
logic [H-1:0] [2:0][BITW-1:0]       input_operands;
logic [H-1:0]      [BITW-1:0]       y_bias_int    ,
                                    partial_result;
logic              [BITW-1:0]       result;

// Signals for intermediate registers
logic [H-1:0]      [BITW-1:0]       output_q;

// Generate PEs
generate
  for (genvar index = 0; index < H; index++) begin : computing_element
    assign input_operands [index][0] = x_input_i [index];
    assign input_operands [index][1] = w_input_i [index];
    if (index > 0) 
      assign input_operands [index][2] = output_q [index-1];
    else
      assign input_operands [index][2] = y_bias_i;
    
    redmule_ce         #(
    .FpFormat           ( FpFormat    ),
    .NumPipeRegs        ( NumPipeRegs ),
    .PipeConfig         ( PipeConfig  ),
    .Stallable          ( 1'b1        )
    ) i_computing_element (
      .clk_i              ( clk_i                     ),
      .rst_ni             ( rst_ni                    ),
      .x_input_i          ( input_operands [index][0] ),
      .w_input_i          ( input_operands [index][1] ),
      .y_bias_i           ( input_operands [index][2] ),
      .fma_is_boxed_i     ( fma_is_boxed_i            ),
      .noncomp_is_boxed_i ( noncomp_is_boxed_i        ),
      .stage1_rnd_i       ( stage1_rnd_i              ),
      .stage2_rnd_i       ( stage2_rnd_i              ),
      .op1_i              ( op1_i                     ),
      .op2_i              ( op2_i                     ),
      .op_mod_i           ( op_mod_i                  ),
      .tag_i              ( tag_i                     ),
      .aux_i              ( aux_i                     ),
      .in_valid_i         ( in_valid_i                ),
      .in_ready_o         ( in_ready_o      [index]   ),
      .reg_enable_i       ( reg_enable_i              ),
      .flush_i            ( flush_i                   ),
      .z_output_o         ( partial_result  [index]   ),
      .status_o           ( status_o        [index]   ),
      .extension_bit_o    ( extension_bit_o [index]   ),
      .class_mask_o       ( class_mask_o    [index]   ),
      .is_class_o         ( is_class_o      [index]   ),
      .tag_o              ( tag_o           [index]   ),
      .aux_o              ( aux_o           [index]   ),
      .out_valid_o        ( out_valid_o     [index]   ),
      .out_ready_i        ( out_ready_i               ),
      .busy_o             ( busy_o          [index]   )
    );
  end : computing_element
endgenerate

always_ff @(posedge clk_i or negedge rst_ni) begin : intermediate_output_register
  if(~rst_ni) begin
    output_q         <= '0;
  end else begin
    for (int i = 0; i < H; i++) begin
      if (flush_i)
        output_q [i] <= '0;
      else if (reg_enable_i)
        output_q [i] <= partial_result [i];
      else 
        output_q [i] <= output_q [i];
    end
  end
end

assign z_output_o = output_q [H-1];

endmodule : redmule_row
