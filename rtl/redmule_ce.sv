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
 * RedMulE Computing Element (CE)
 */

module redmule_ce
  import fpnew_pkg::*;
#(
  parameter fpnew_pkg::fp_format_e   FpFormat    = fpnew_pkg::FP16              ,
  parameter int unsigned             NumPipeRegs = 2                            ,
  parameter fpnew_pkg::pipe_config_t PipeConfig  = fpnew_pkg::DISTRIBUTED       ,
  parameter type                     TagType     = logic                        ,
  parameter type                     AuxType     = logic                        ,
  parameter logic                    Stallable   = 1'b0                         ,
  localparam int unsigned            BITW        = fpnew_pkg::fp_width(FpFormat)
)(
  input  logic                               clk_i             ,
  input  logic                               rst_ni            ,
  input  logic                    [BITW-1:0] x_input_i         ,
  input  logic                    [BITW-1:0] w_input_i         ,
  input  logic                    [BITW-1:0] y_bias_i          ,
  input  logic                    [2:0]      fma_is_boxed_i    ,
  input  logic                    [1:0]      noncomp_is_boxed_i,
  input  fpnew_pkg::roundmode_e              stage1_rnd_i      ,
  input  fpnew_pkg::roundmode_e              stage2_rnd_i      ,
  input  fpnew_pkg::operation_e              op1_i             ,
  input  fpnew_pkg::operation_e              op2_i             ,
  input  logic                               op_mod_i          ,
  input  TagType                             tag_i             ,
  input  AuxType                             aux_i             ,
  input  logic                               in_valid_i        ,
  output logic                               in_ready_o        ,
  input  logic                               reg_enable_i      ,
  input  logic                               flush_i           ,
  output logic                    [BITW-1:0] z_output_o        ,
  output fpnew_pkg::status_t                 status_o          ,
  output logic                               extension_bit_o   ,
  output fpnew_pkg::classmask_e              class_mask_o      ,
  output logic                               is_class_o        ,
  output TagType                             tag_o             ,
  output AuxType                             aux_o             ,
  output logic                               out_valid_o       ,
  input  logic                               out_ready_i       ,
  output logic                               busy_o
);

// Internal logic binding
logic [BITW-1:0] fma_y    ,
                 noncomp_y,
                 noncomp_y_d;

fpnew_pkg::operation_e op1_int;
logic stage2_noncomp_clk_en        ,
      stage2_noncomp_input_pipe_clk;

assign op1_int = op1_i;

/* Assigning input bias to both FMA and second-stage FNCOMP input  */
assign fma_y       = (op1_int == fpnew_pkg::MUL) ? '0 : y_bias_i;
assign noncomp_y_d = y_bias_i;

/* Second stage clock gating enable signal and clock gating cell */
assign stage2_noncomp_clk_en = (op1_int == fpnew_pkg::FMADD) ? 1'b0 : 1'b1;

cluster_clock_gating stage2_noncomp_clk_gating (
  .clk_i      ( clk_i                          ),
  .en_i       ( stage2_noncomp_clk_en          ),
  .test_en_i  ( '0                             ),
  .clk_o      ( stage2_noncomp_input_pipe_clk  )
);

logic [NumPipeRegs-1:0][BITW-1:0] noncomp_y_q;
generate
  for (genvar i = 0; i < NumPipeRegs; i++) begin : noncomp_input_pipe
    always_ff @(posedge stage2_noncomp_input_pipe_clk, negedge rst_ni) begin
      if (~rst_ni) begin
        noncomp_y_q[i] <= '0;
      end else begin
        if (reg_enable_i)
          noncomp_y_q[i] <= (i == 0) ? noncomp_y_d : noncomp_y_q[i-1];
        else
          noncomp_y_q[i] <= noncomp_y_q[i];
      end
    end
  end
endgenerate

assign noncomp_y = noncomp_y_q[NumPipeRegs-1];

/*******************************************************************************/
/*                                   STAGE 1                                   */
/*******************************************************************************/
/* Stage 1 contains all the modules that enable operation 1: it can be either  *
 * FMUL, FADD, FMA, FMIN, or FMAX                                              */
/*******************************************************************************/
/* In Stage 1, X and W inputs are propagated into both FMA and NONCOMP modules *
 * In case of FMA operations, op1_i signal is enough to define the operation   *
 * to chose. In particular:                                                    *
 * - FMIN: op1_i = fpnew_pkg::MINMAX, stage1_rnd_i = fpnew_pkg::RNE            *
 * - FMAX: op1_i = fpnew_pkg::MINMAX, stage1_rnd_i = fpnew_pkg::RTZ            */

// Generating internal singnals to maniuplate them in the next stages
logic                  [2:0] fma_is_boxed_int            ;
logic                  [1:0] noncomp_is_boxed_int        ;
fpnew_pkg::roundmode_e       stage1_rnd_int              ;
fpnew_pkg::roundmode_e       stage2_rnd_int              ;
fpnew_pkg::operation_e       op2_int                     ;

logic                        stage1_fma_op_mod           ,
                             stage1_noncomp_op_mod       ;

TagType                      stage1_fma_input_tag        ,
                             stage1_noncomp_input_tag    ;

AuxType                      stage1_fma_input_aux        ,
                             stage1_noncomp_input_aux    ;

logic                        stage1_fma_in_valid         ,
                             stage1_noncomp_in_valid     ;

logic                        stage1_in_ready             ,
                             stage1_fma_in_ready         ,
                             stage1_noncomp_in_ready     ;

logic                        stage1_fma_reg_enable       ,
                             stage1_noncomp_reg_enable   ;

logic                        stage1_fma_flush            ,
                             stage1_noncomp_flush        ;

fpnew_pkg::status_t          stage1_status               ,
                             stage1_fma_status           ,
                             stage1_noncomp_status       ;

logic                        stage1_extension_bit        ,
                             stage1_fma_extension_bit    ,
                             stage1_noncomp_extension_bit;

fpnew_pkg::classmask_e       stage1_class_mask           ;
logic                        stage1_is_class             ;

TagType                      stage1_output_tag           ,
                             stage1_fma_output_tag       ,
                             stage1_noncomp_output_tag   ;

AuxType                      stage1_output_aux           ,
                             stage1_fma_output_aux       ,
                             stage1_noncomp_output_aux   ;

logic                        stage1_out_valid            ,
                             stage1_fma_out_valid        ,
                             stage1_noncomp_out_valid    ;

logic                        stage1_fma_out_ready        ,
                             stage1_noncomp_out_ready    ;

logic                        stage1_busy                 ,
                             stage1_fma_busy             ,
                             stage1_noncomp_busy         ;

assign fma_is_boxed_int     = fma_is_boxed_i    ;
assign noncomp_is_boxed_int = noncomp_is_boxed_i;
assign stage1_rnd_int       = stage1_rnd_i      ;
assign stage2_rnd_int       = stage2_rnd_i      ;
assign op2_int              = op2_i             ;

// X/W input opernads copies to use within selections
logic      [BITW-1:0] x_input           ,
                      w_input           ,
                      stage1_res        ,
                      stage1_fma_res    ,
                      stage1_noncomp_res;

logic stage1_fma_clk,
      stage1_fma_clk_en,
      stage1_noncomp_clk,
      stage1_noncomp_clk_en;
logic [2:0][BITW-1:0] stage1_fma_operands;           // FMA exists only in stage 1
logic [1:0][BITW-1:0] stage1_noncomp_operands;

assign x_input = x_input_i;
assign w_input = w_input_i;

/*******************************************************************************/
/* Assigning input signals to the stage1 FMA and to the stage1 NONCOMP module  */
/*******************************************************************************/

assign stage1_noncomp_operands[0] = x_input;
assign stage1_noncomp_operands[1] = w_input;

assign stage1_noncomp_op_mod     = op_mod_i    ;
assign stage1_noncomp_input_tag  = tag_i       ;
assign stage1_noncomp_input_aux  = aux_i       ;
assign stage1_noncomp_in_valid   = in_valid_i  ;
assign stage1_noncomp_reg_enable = reg_enable_i;
assign stage1_noncomp_flush      = flush_i     ;
assign stage1_noncomp_out_ready  = out_ready_i ;

always_comb begin : FMA_input_multiplexer
  if ( op1_int == fpnew_pkg::ADD ) begin
    stage1_fma_operands[0] = '0     ;
    stage1_fma_operands[1] = x_input;
    stage1_fma_operands[2] = w_input;
  end else begin
    stage1_fma_operands[0] = x_input;
    stage1_fma_operands[1] = w_input;
    stage1_fma_operands[2] = fma_y  ;
  end
end : FMA_input_multiplexer

assign stage1_fma_op_mod     = op_mod_i    ;
assign stage1_fma_input_tag  = tag_i       ;
assign stage1_fma_input_aux  = aux_i       ;
assign stage1_fma_in_valid   = in_valid_i  ;
assign stage1_fma_reg_enable = reg_enable_i;
assign stage1_fma_flush      = flush_i     ;
assign stage1_fma_out_ready  = out_ready_i ;

/*******************************************************************************/
/* Depending on op1, we clock gate either FMA or NONCOMP module.               */
/*******************************************************************************/
always_comb begin : stage_one_clock_gating_selector
stage1_fma_clk_en     = 1'b0;
stage1_noncomp_clk_en = 1'b0;
  if ( op1_int == fpnew_pkg::MINMAX )
    stage1_noncomp_clk_en = 1'b1;
  else
    stage1_fma_clk_en     = 1'b1;
end : stage_one_clock_gating_selector


/*******************************************************************************/
/* Instantiation of stage1 FMA and stage1 NONCOMP                              */
/*******************************************************************************/
tc_clk_gating stage1_noncomp_clk_gating (
  .clk_i      ( clk_i                 ),
  .en_i       ( stage1_noncomp_clk_en ),
  .test_en_i  ( '0                    ),
  .clk_o      ( stage1_noncomp_clk    )
);

redmule_noncomp #(
  .FpFormat      ( FpFormat    ),
  .NumPipeRegs   ( NumPipeRegs ),
  .PipeConfig    ( PipeConfig  ),
  .Stallable     ( Stallable   )
) op1_minmax_i   (
  .clk_i           ( stage1_noncomp_clk           ),
  .rst_ni          ( rst_ni                       ),
  .operands_i      ( stage1_noncomp_operands      ),
  .is_boxed_i      ( noncomp_is_boxed_int         ),
  .rnd_mode_i      ( stage1_rnd_int               ),
  .op_i            ( op1_int                      ),
  .op_mod_i        ( stage1_noncomp_op_mod        ),
  .tag_i           ( stage1_noncomp_input_tag     ),
  .aux_i           ( stage1_noncomp_input_aux     ),
  .in_valid_i      ( stage1_noncomp_in_valid      ),
  .in_ready_o      ( stage1_noncomp_in_ready      ),
  .reg_enable_i    ( stage1_noncomp_reg_enable    ),
  .flush_i         ( stage1_noncomp_flush         ),
  .result_o        ( stage1_noncomp_res           ),
  .status_o        ( stage1_noncomp_status        ),
  .extension_bit_o ( stage1_noncomp_extension_bit ),
  .class_mask_o    ( stage1_class_mask            ),
  .is_class_o      ( stage1_is_class              ),
  .tag_o           ( stage1_noncomp_output_tag    ),
  .aux_o           ( stage1_noncomp_output_aux    ),
  .out_valid_o     ( stage1_noncomp_out_valid     ),
  .out_ready_i     ( stage1_noncomp_out_ready     ),
  .busy_o          ( stage1_noncomp_busy          )
);


tc_clk_gating stage1_fma_clk_gating (
  .clk_i      ( clk_i             ),
  .en_i       ( stage1_fma_clk_en ),
  .test_en_i  ( '0                ),
  .clk_o      ( stage1_fma_clk    )
);

redmule_fma   #(
  .FpFormat    ( FpFormat    ),
  .NumPipeRegs ( NumPipeRegs ),
  .PipeConfig  ( PipeConfig  ),
  .Stallable   ( Stallable   )
) op1_fma_i    (
  .clk_i           ( stage1_fma_clk           ),
  .rst_ni          ( rst_ni                   ),
  .operands_i      ( stage1_fma_operands      ),
  .is_boxed_i      ( fma_is_boxed_int         ),
  .rnd_mode_i      ( stage1_rnd_int           ),
  .op_i            ( op1_int                  ),
  .op_mod_i        ( stage1_fma_op_mod        ),
  .tag_i           ( stage1_fma_input_tag     ),
  .aux_i           ( stage1_fma_input_aux     ),
  .in_valid_i      ( stage1_fma_in_valid      ),
  .in_ready_o      ( stage1_fma_in_ready      ),
  .reg_enable_i    ( stage1_fma_reg_enable    ),
  .flush_i         ( stage1_fma_flush         ),
  .result_o        ( stage1_fma_res           ),
  .status_o        ( stage1_fma_status        ),
  .extension_bit_o ( stage1_fma_extension_bit ),
  .tag_o           ( stage1_fma_output_tag    ),
  .aux_o           ( stage1_fma_output_aux    ),
  .out_valid_o     ( stage1_fma_out_valid     ),
  .out_ready_i     ( stage1_fma_out_ready     ),
  .busy_o          ( stage1_fma_busy          )
);

/*******************************************************************************/
/* Stage 1 mux: selects output signals from the stage1 FMA or the stage1       *
 * NONCOMP depending on op1 value                                              */
/*******************************************************************************/
always_comb begin : stage1_output_selector
stage1_in_ready      = '0;
stage1_res           = '0;
stage1_status        = '0;
stage1_extension_bit = '0;
stage1_output_tag    = '0;
stage1_output_aux    = '0;
stage1_out_valid     = '0;
stage1_busy          = '0;

  if (op1_int == fpnew_pkg::MINMAX) begin : minmax_output_selected
    stage1_in_ready      = stage1_noncomp_in_ready     ;
    stage1_res           = stage1_noncomp_res          ;
    stage1_status        = stage1_noncomp_status       ;
    stage1_extension_bit = stage1_noncomp_extension_bit;
    stage1_output_tag    = stage1_noncomp_output_tag   ;
    stage1_output_aux    = stage1_noncomp_output_aux   ;
    stage1_out_valid     = stage1_noncomp_out_valid    ;
    stage1_busy          = stage1_noncomp_busy         ;

  end else begin : fma_output_selected
    stage1_in_ready      = stage1_fma_in_ready     ;
    stage1_res           = stage1_fma_res          ;
    stage1_status        = stage1_fma_status       ;
    stage1_extension_bit = stage1_fma_extension_bit;
    stage1_output_tag    = stage1_fma_output_tag   ;
    stage1_output_aux    = stage1_fma_output_aux   ;
    stage1_out_valid     = stage1_fma_out_valid    ;
    stage1_busy          = stage1_fma_busy         ;

  end
end : stage1_output_selector

/*******************************************************************************/
/*                                   STAGE 2                                   */
/*******************************************************************************/
/* Stage 2 contains all the modules that enable operation 2: it can be either  *
 * FMIN, or FMAX, or nothing. In the latter case, we propagate the result of   *
 * stage 1 to output.                                                          *
********************************************************************************/
/* Depending on op1_i:                                                         *
 * - op1_i = fpnew_pkg::FMADD -> propagate stage 1 result to output (Z)        *
 * - In all the other cases, propagate stage 1 result to stage 2 NONCOMP input */

// Internal signals for logic binding
logic                        stage2_noncomp_op_mod       ;
TagType                      stage2_noncomp_input_tag    ;
AuxType                      stage2_noncomp_input_aux    ;
logic                        stage2_noncomp_in_valid     ;
logic                        stage2_in_ready             ,
                             stage2_noncomp_in_ready     ;
logic                        stage2_noncomp_reg_enable   ;
logic                        stage2_noncomp_flush        ;
fpnew_pkg::status_t          stage2_status               ,
                             stage2_noncomp_status       ;
logic                        stage2_extension_bit        ,
                             stage2_noncomp_extension_bit;
fpnew_pkg::classmask_e       stage2_class_mask           ,
                             stage2_noncomp_class_mask   ;
logic                        stage2_is_class             ,
                             stage2_noncomp_is_class     ;
TagType                      stage2_output_tag           ,
                             stage2_noncomp_output_tag   ;
AuxType                      stage2_output_aux           ,
                             stage2_noncomp_output_aux   ;
logic                        stage2_out_valid            ,
                             stage2_noncomp_out_valid    ;
logic                        stage2_noncomp_out_ready    ;
logic                        stage2_busy                 ,
                             stage2_noncomp_busy         ;

assign stage2_noncomp_op_mod     = stage1_noncomp_op_mod    ;
assign stage2_noncomp_input_tag  = stage1_noncomp_input_tag ;
assign stage2_noncomp_input_aux  = stage1_noncomp_input_aux ;
assign stage2_noncomp_in_valid   = stage1_noncomp_in_valid  ;
assign stage2_noncomp_reg_enable = stage1_noncomp_reg_enable;
assign stage2_noncomp_flush      = stage1_noncomp_flush     ;
assign stage2_noncomp_out_ready  = stage1_noncomp_out_ready ;

logic [1:0][BITW-1:0]  stage2_noncomp_operands;
logic      [BITW-1:0]  stage2_res             ,
                       stage2_noncomp_res     ;

assign stage2_noncomp_operands[0] = stage1_res;
assign stage2_noncomp_operands[1] = noncomp_y ;

/*******************************************************************************/
/* Instantiation of stage2 NONCOMP                                             */
/*******************************************************************************/
redmule_noncomp #(
  .FpFormat      ( FpFormat    ),
  .NumPipeRegs   ( 0           ),
  .PipeConfig    ( PipeConfig  ),
  .Stallable     ( Stallable   )
) op2_minmax_i   (
  .clk_i                                           ,
  .rst_ni                                          ,
  .operands_i      ( stage2_noncomp_operands      ),
  .is_boxed_i      ( noncomp_is_boxed_int         ),
  .rnd_mode_i      ( stage2_rnd_int               ),
  .op_i            ( op2_int                      ),
  .op_mod_i        ( stage2_noncomp_op_mod        ),
  .tag_i           ( stage2_noncomp_input_tag     ),
  .aux_i           ( stage2_noncomp_input_aux     ),
  .in_valid_i      ( stage2_noncomp_in_valid      ),
  .in_ready_o      ( stage2_noncomp_in_ready      ),
  .reg_enable_i    ( stage2_noncomp_reg_enable    ),
  .flush_i         ( stage2_noncomp_flush         ),
  .result_o        ( stage2_noncomp_res           ),
  .status_o        ( stage2_noncomp_status        ),
  .extension_bit_o ( stage2_noncomp_extension_bit ),
  .class_mask_o    ( stage2_noncomp_class_mask    ),
  .is_class_o      ( stage2_noncomp_is_class      ),
  .tag_o           ( stage2_noncomp_output_tag    ),
  .aux_o           ( stage2_noncomp_output_aux    ),
  .out_valid_o     ( stage2_noncomp_out_valid     ),
  .out_ready_i     ( stage2_noncomp_out_ready     ),
  .busy_o          ( stage2_noncomp_busy          )
);

/*******************************************************************************/
/* Stage 2 mux: selects output signals from the stage1 FMA or the stage2       *
 * NONCOMP depending on op1 value                                              */
/*******************************************************************************/
always_comb begin: stage2_output_selector
stage2_res = '0;

stage2_in_ready      = '0;
stage2_res           = '0;
stage2_status        = fpnew_pkg::DONT_CARE;
stage2_extension_bit = '0;
stage2_class_mask    = fpnew_pkg::QNAN;
stage2_is_class      = '0;
stage2_output_tag    = '0;
stage2_output_aux    = '0;
stage2_out_valid     = '0;
stage2_busy          = '0;

  if (op1_int == fpnew_pkg::FMADD) begin : stage2_noncomp_disabled
    stage2_in_ready      = stage1_in_ready     ;
    stage2_res           = stage1_res          ;
    stage2_status        = stage1_status       ;
    stage2_extension_bit = stage1_extension_bit;
    stage2_output_tag    = stage1_output_tag   ;
    stage2_output_aux    = stage1_output_aux   ;
    stage2_out_valid     = stage1_out_valid    ;
    stage2_busy          = stage1_busy         ;

  end else begin : stage2_noncomp_enabled
    stage2_in_ready      = stage2_noncomp_in_ready     ;
    stage2_res           = stage2_noncomp_res          ;
    stage2_status        = stage2_noncomp_status       ;
    stage2_extension_bit = stage2_noncomp_extension_bit;
    stage2_class_mask    = stage2_noncomp_class_mask   ;
    stage2_is_class      = stage2_noncomp_is_class     ;
    stage2_output_tag    = stage2_noncomp_output_tag   ;
    stage2_output_aux    = stage2_noncomp_output_aux   ;
    stage2_out_valid     = stage2_noncomp_out_valid    ;
    stage2_busy          = stage2_noncomp_busy         ;

  end
end : stage2_output_selector

/*******************************************************************************/
/*                               OUTPUT BINDING                                */
/*******************************************************************************/
assign in_ready_o      = stage2_in_ready     ;
assign z_output_o      = stage2_res          ;
assign status_o        = stage2_status       ;
assign extension_bit_o = stage2_extension_bit;
assign class_mask_o    = stage2_class_mask   ;
assign is_class_o      = stage2_is_class     ;
assign tag_o           = stage2_output_tag   ;
assign aux_o           = stage2_output_aux   ;
assign out_valid_o     = stage2_out_valid    ;
assign busy_o          = stage2_busy         ;

endmodule: redmule_ce
