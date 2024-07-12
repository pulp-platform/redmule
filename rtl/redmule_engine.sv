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
 parameter  int unsigned  REP         = 1                            , // Number of Replicas on the control Inputs
 parameter  bit           W_PARITY    = 0                            , // If an extra parity bit is used on W Inputs
 localparam int unsigned  BITW        = fpnew_pkg::fp_width(FpFormat), // Number of bits for the given format  
 parameter  int unsigned  PARW        = BITW / 8                     , // Number of parity bits for the given format
 localparam int unsigned  H           = Height                       ,
 localparam int unsigned  W           = Width                        ,
 localparam int unsigned  DELAY       = NumPipeRegs+1
)(
  input  logic                                             clk_i              ,
  input  logic                                             rst_ni             ,
  // Input Elements                                                           
  input  logic                    [W-1:0][H-1:0][BITW-1:0] x_input_i          , // Inputs to be loaded inside the buffer
  input  logic                           [H-1:0][BITW-1:0] w_input_i          , // Weights to be streamed inside the datapath
  input  logic                           [H-1:0][PARW-1:0] w_parity_i         , // Parity on Weights
  input  logic                    [W-1:0]       [BITW-1:0] y_bias_i           ,
  // Output Result                                                            
  output logic                    [W-1:0]       [BITW-1:0] z_output_o         , // Outputs computations
  // input  cntrl_engine_t                                         ctrl_i  [W-1:0][H-1:0],
  // Control signal for successive accumulations
  input  logic                                   [REP-1:0] accumulate_i       ,
  input  logic                                   [REP-1:0] reg_enable_i       ,
  input  logic                                   [REP-1:0] flush_i            ,
  // control bus from FSM
  input  cntrl_engine_t                          [REP-1:0] ctrl_engine_i      ,
  output flgs_engine_t                                     flgs_engine_o      ,
  output logic                                             fault_o                            
);

 /*This module contains the complete RedMulE datapath. The datapath is mainly composed by:
 1) An input buffer that loads the operands from the input
 2) An output buffer, made of HxW array that stores the partial products
 3) The real datapath, which is an array of W parallel rows, each composed by H fma modules interconnected in series*/

if (REP != 1 && REP != 2) begin: guard_unsupported_rep
  $fatal(1, "Selected replicas (REP) in redmule engine not supported! (This module specifically can't recover with REP = 3)\n");
end

// Clock gating and intermediate signals
logic [W-1:0]           row_clk;
logic [W-1:0][BITW-1:0] result, feedback;

// Collect Fault Detected
logic [W-1:0] fault;
assign fault_o = |fault;

generate
  for (genvar index = 0; index < W; index++) begin: gen_row_array
  /*--------------------------------------- Array ----------------------------------------*/
    localparam replica_index = index % REP;

    tc_clk_gating i_row_clk_gating (
      .clk_i     ( clk_i                                               ),
      .en_i      ( ctrl_engine_i[replica_index].row_clk_gate_en[index] ),
      .test_en_i ( '0                                                  ),
      .clk_o     ( row_clk[index]                                      )
    );

    redmule_row       #(
      .FpFormat        ( FpFormat    ),
      .Height          ( H           ),
      .NumPipeRegs     ( NumPipeRegs ),
      .PipeConfig      ( PipeConfig  ),
      .W_PARITY        ( W_PARITY    ),
      .PARW            ( PARW        )
    ) i_row            (
      .clk_i              ( row_clk[index]                                ),
      .rst_ni             ( rst_ni                                        ),
      .x_input_i          ( x_input_i[index]                              ),
      .w_input_i          ( w_input_i                                     ),
      .w_parity_i         ( w_parity_i                                    ),
      .y_bias_i           ( feedback[index]                               ),
      .z_output_o         ( result[index]                                 ),
      .fma_is_boxed_i     ( ctrl_engine_i[replica_index].fma_is_boxed     ),
      .noncomp_is_boxed_i ( ctrl_engine_i[replica_index].noncomp_is_boxed ),
      .stage1_rnd_i       ( ctrl_engine_i[replica_index].stage1_rnd       ),
      .stage2_rnd_i       ( ctrl_engine_i[replica_index].stage2_rnd       ),
      .op1_i              ( ctrl_engine_i[replica_index].op1              ),
      .op2_i              ( ctrl_engine_i[replica_index].op2              ),
      .op_mod_i           ( ctrl_engine_i[replica_index].op_mod           ),
      .tag_i              ( 1'b0                                          ), // There because FPNew would support it
      .aux_i              ( 1'b0                                          ), // There because FPNew would support it
      .in_valid_i         ( ctrl_engine_i[replica_index].in_valid         ),
      .in_ready_o         ( flgs_engine_o.in_ready[index]                 ),
      .reg_enable_i       ( reg_enable_i[replica_index]                   ),
      .flush_i            ( flush_i[replica_index]                        ),
      .status_o           ( flgs_engine_o.status[index]                   ),
      .extension_bit_o    ( flgs_engine_o.extension_bit[index]            ),
      .class_mask_o       ( /* Unused */                                  ), // There because FPNew would support it
      .is_class_o         ( /* Unused */                                  ), // There because FPNew would support it
      .tag_o              ( /* Unused */                                  ), // There because FPNew would support it
      .aux_o              ( /* Unused */                                  ), // There because FPNew would support it
      .out_valid_o        ( flgs_engine_o.out_valid[index]                ),
      .out_ready_i        ( ctrl_engine_i[replica_index].out_ready        ),
      .busy_o             ( flgs_engine_o.busy[index]                     ),
      .fault_o            ( fault[index]                                  )
    );
    
    // In case input matrix is bigger than the array, we feedback the partial results to continue the computation
    always_comb begin : partial_product_feedback
      feedback[index] = y_bias_i[index];
      if (accumulate_i[replica_index])
        feedback[index] = result[index];
      else
        feedback[index] = y_bias_i[index];
    end
  end	
endgenerate

assign z_output_o = result;

endmodule : redmule_engine
