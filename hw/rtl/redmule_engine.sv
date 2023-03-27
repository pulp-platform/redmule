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
 * RedMulE Engine
 */

module redmule_engine
  import fpnew_pkg::*;
  import redmule_pkg::*;
#(
 parameter  fp_format_e   FpFormat    = FP16                         ,
 parameter  int unsigned  Height      = 4                            ,                             // Number of PEs per row
 parameter  int unsigned  Width       = 8                            ,                             // Number of parallel index
 parameter  int unsigned  NumPipeRegs = 3                            ,
 parameter  pipe_config_t PipeConfig  = DISTRIBUTED                  ,
 parameter  type          TagType     = logic                        ,
 parameter  type          AuxType     = logic                        ,
 localparam int unsigned  BITW        = fpnew_pkg::fp_width(FpFormat), // Number of bits for the given format                          
 localparam int unsigned  H           = Height                       ,
 localparam int unsigned  W           = Width                        ,
 localparam int unsigned  DELAY       = NumPipeRegs+1
)(
  input  logic                                             clk_i              ,
  input  logic                                             rst_ni             ,
  // Input Elements                                                           
  input  logic                    [W-1:0][H-1:0][BITW-1:0] x_input_i          , // Inputs to be loaded inside the buffer
  input  logic                           [H-1:0][BITW-1:0] w_input_i          ,// Weights to be streamed inside the datapath
  input  logic                    [W-1:0]       [BITW-1:0] y_bias_i           ,
  // Output Result                                                            
  output logic                    [W-1:0]       [BITW-1:0] z_output_o         , // Outputs computations
  // input  cntrl_engine_t                                         ctrl_i  [W-1:0][H-1:0],
  // output flgs_engine_t                                          flags_o [W-1:0][H-1:0]
  // Control signal for successive accumulations
  input  logic                                             accumulate_i       ,
  // fpnew_fma Input Signals
  input  logic                    [2:0]                    fma_is_boxed_i     ,
  input  logic                    [1:0]                    noncomp_is_boxed_i ,
  input  fpnew_pkg::roundmode_e                            stage1_rnd_i       ,
  input  fpnew_pkg::roundmode_e                            stage2_rnd_i       ,
  input  fpnew_pkg::operation_e                            op1_i              ,
  input  fpnew_pkg::operation_e                            op2_i              ,
  input  logic                                             op_mod_i           ,
  input  TagType                                           tag_i              ,
  input  AuxType                                           aux_i              ,
  // fpnew_fma Input Handshake                                                
  input  logic                                             in_valid_i         ,
  output logic                    [W-1:0][H-1:0]           in_ready_o         ,
  input  logic                                             reg_enable_i       ,
  input  logic                                             flush_i            ,
  // fpnew_fma Output signals                                                 
  output fpnew_pkg::status_t      [W-1:0][H-1:0]           status_o           ,
  output logic                    [W-1:0][H-1:0]           extension_bit_o    ,
  output fpnew_pkg::classmask_e   [W-1:0][H-1:0]           class_mask_o       ,
  output logic                    [W-1:0][H-1:0]           is_class_o         ,
  output TagType                  [W-1:0][H-1:0]           tag_o              ,
  output AuxType                  [W-1:0][H-1:0]           aux_o              ,
  // fpnew_fma Output handshake                                               
  output logic                    [W-1:0][H-1:0]           out_valid_o        ,
  input  logic                                             out_ready_i        ,
  // fpnew_fma Indication of valid data in flight
  output logic                    [W-1:0][H-1:0]           busy_o
);

 /*This module contains the complete datapath of the tensorcore unit. The datapath is mainly composed by:
 1) An input buffer that loads the operands from the input
 2) An output buffer, made of HxW array that stores the partial products
 3) The real datapath, which is an array of W parallel rows, each composed by H fma modules interconnected in series*/

logic [W-1:0]       [BITW-1:0] result, feedback;

generate
  for (genvar index = 0; index < W; index++) begin
  /*--------------------------------------- Array ----------------------------------------*/
    redmule_row       #(
      .FpFormat        ( FpFormat    ),
      .Height          ( H           ),
      .NumPipeRegs     ( NumPipeRegs ),
      .PipeConfig      ( PipeConfig  )
    ) i_row            (
      .clk_i              ( clk_i                   ),
      .rst_ni             ( rst_ni                  ),
      .x_input_i          ( x_input_i       [index] ),
      .w_input_i          ( w_input_i               ),
      .y_bias_i           ( feedback        [index] ),
      .z_output_o         ( result          [index] ),
      .fma_is_boxed_i     ( fma_is_boxed_i          ),
      .noncomp_is_boxed_i ( noncomp_is_boxed_i      ),
      .stage1_rnd_i       ( stage1_rnd_i            ),
      .stage2_rnd_i       ( stage2_rnd_i            ),
      .op1_i              ( op1_i                   ),
      .op2_i              ( op2_i                   ),
      .op_mod_i           ( op_mod_i                ),
      .tag_i              ( tag_i                   ),
      .aux_i              ( aux_i                   ),
      .in_valid_i         ( in_valid_i              ),
      .in_ready_o         ( in_ready_o      [index] ),
      .reg_enable_i       ( reg_enable_i            ),
      .flush_i            ( flush_i                 ),
      .status_o           ( status_o        [index] ),
      .extension_bit_o    ( extension_bit_o [index] ),
      .class_mask_o       ( class_mask_o    [index] ),
      .is_class_o         ( is_class_o      [index] ),
      .tag_o              ( tag_o           [index] ),
      .aux_o              ( aux_o           [index] ),
      .out_valid_o        ( out_valid_o     [index] ),
      .out_ready_i        ( out_ready_i             ),
      .busy_o             ( busy_o          [index] )
    );
    
    // In case input matrix is bigger than the array, we feedback the partial results to continue the computation
    always_comb begin : partial_product_feedback
      feedback[index] = y_bias_i[index];
      if (accumulate_i)
        feedback[index] = result[index];
      else
        feedback[index] = y_bias_i[index];
    end
  end	
endgenerate

assign z_output_o = result;

endmodule : redmule_engine
