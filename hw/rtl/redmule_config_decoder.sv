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
 * Authors: Francesco Conti <f.conti@unibo.it>
 *          Yvan Tortorella <yvan.tortorella@unibo.it>
 * 
 * RedMulE Configuration Decoder
 */

import redmule_pkg::*;
import hwpe_ctrl_package::*;

module redmule_config_decoder #(
  parameter int unsigned ARRAY_WIDTH,
  parameter int unsigned ARRAY_HEIGHT,
  parameter int unsigned PIPE_REGS,
  parameter int unsigned FPFORMAT,
  parameter int unsigned DATA_WIDTH
) (
  input  logic          clk_i       ,
  input  logic          rst_ni      ,
  input  logic          clear_i     ,
  input  logic          start_i     ,
  output logic          valid_o     ,
  input  ctrl_regfile_t reg_file_i  ,
  output ctrl_regfile_t reg_file_o
);

  typedef enum logic [2:0] { MATMUL=3'h0, GEMM=3'h1, ADDMAX=3'h2, ADDMIN=3'h3, MULMAX=3'h4, MULMIN=3'h5, MAXMIN=3'h6, MINMAX=3'h7 } gemm_op_t;
  typedef enum logic [1:0] { FP16=2'h0, FP8=2'h1, FP16ALT=2'h2, FP8ALT=2'h3 }                                                       gemm_fmt_t;

  typedef enum logic       { RNE=1'h0, RTZ=1'h1 }                                                                                   rnd_mode_t;
  typedef enum logic [2:0] { FMADD=3'h0, ADD=3'h2, MUL=3'h3, MINMAX=3'h7 }                                                          fpu_op_t;
  typedef enum logic [2:0] { FP16=3'h2, FP8=3'h3, FP16ALT=3'h4, FP8ALT=3'h5 }                                                       fpu_fmt_t;

  typedef struct packed {
    logic [31:0] x_addr;
    logic [31:0] w_addr;
    logic [31:0] y_addr;
    logic [31:0] z_addr;
    logic [15:0] m_size;
    logic [15:0] n_size;
    logic [15:0] k_size;
    gemm_op_t gemm_ops;
    gemm_fmt_t gemm_input_fmt;
    gemm_fmt_t gemm_output_fmt;

    logic [15:0] x_cols_iter;
    logic [15:0] x_rows_iter;
    logic [15:0] w_cols_iter;
    logic [15:0] w_rows_iter;
    logic [ 7:0] x_cols_lftovr;
    logic [ 7:0] x_rows_lftovr;
    logic [ 7:0] w_cols_lftovr;
    logic [ 7:0] w_rows_lftovr;
    logic [15:0] tot_stores;
    logic [31:0] x_d1_stride;
    logic [31:0] w_tot_len;
    logic [31:0] w_tot_len;
    logic [31:0] tot_x_read;
    logic [31:0] w_d0_stride;
    logic [31:0] yz_tot_len;
    logic [31:0] yz_d0_stride;
    logic [31:0] yz_d2_stride;
    logic [31:0] x_rows_offs;
    logic [31:0] x_buffer_slots;
    logic [31:0] x_tot_len;
    rnd_mode_t stage_1_rnd_mode;
    rnd_mode_t stage_2_rnd_mode;
    fpu_op_t stage_1_op;
    fpu_op_t stage_2_op;
    fpu_fmt_t input_format;
    fpu_fmt_t computing_format;
    logic        gemm_selection;
  } redmule_config_t;

  redmule_config_t config_d, config_q;

  assign config_d.x_addr          = reg_file_i.hwpe_params[0];
  assign config_d.w_addr          = reg_file_i.hwpe_params[1];
  assign config_d.y_addr          = reg_file_i.hwpe_params[2];
  assign config_d.z_addr          = reg_file_i.hwpe_params[3];
  assign config_d.m_size          = reg_file_i.hwpe_params[4][15:0];
  assign config_d.n_size          = reg_file_i.hwpe_params[4][31:16];
  assign config_d.k_size          = reg_file_i.hwpe_params[5][15:0];
  assign config_d.gemm_ops        = reg_file_i.hwpe_params[5][18:16];
  assign config_d.gemm_input_fmt  = reg_file_i.hwpe_params[5][20:19];
  assign config_d.gemm_output_fmt = reg_file_i.hwpe_params[5][22:21];

  // Calculating the number of iterations alng the two dimensions of the X matrix
  logic [15:0] x_rows_iter_nolftovr;
  logic [15:0] x_cols_iter_nolftovr;
  assign x_rows_iter_nolftovr = m_size/ARRAY_WIDTH;
  assign x_cols_iter_nolftovr = n_size/(ARRAY_HEIGHT*(PIPE_REGS + 1));

  // Calculating the number of iterations along the two dimensions of the W matrix
  logic [15:0] w_cols_iter_nolftovr;
  assign config_d.w_rows_iter = config_d.n_size;
  assign w_cols_iter_nolftovr = config_d.k_size/(ARRAY_HEIGHT*(PIPE_REGS + 1));

  // Calculating the residuals along the input dimensions
  assign config_d.x_rows_lftovr = config_d.m_size - (x_rows_iter_nolftovr*ARRAY_WIDTH);
  assign config_d.x_cols_lftovr = config_d.n_size - (x_cols_iter_nolftovr*(ARRAY_HEIGHT*(PIPE_REGS + 1)));

  // Calculating the residuals along the weight dimensions
  assign config_d.w_rows_lftovr = config_d.n_size - (ARRAY_HEIGHT*(config_d.k_size/ARRAY_HEIGHT));
  assign config_d.w_cols_lftovr = config_d.k_size - (w_cols_iter_nolftovr*(ARRAY_HEIGHT*(PIPE_REGS + 1)));

  // Calculate w_cols, x_cols, x_rows iterations
  assign config_d.w_cols_iter = w_cols_lftovr != '0 ? w_cols_iter_nolftovr + 1 : w_cols_iter_nolftovr;
  assign config_d.x_cols_iter = x_cols_lftovr != '0 ? x_cols_iter_nolftovr + 1 : x_cols_iter_nolftovr;
  assign config_d.x_rows_iter = x_rows_lftovr != '0 ? x_rows_iter_nolftovr + 1 : x_rows_iter_nolftovr;

  // Sequential multiplier x_rows x w_cols
  logic [31:0] x_rows_by_w_cols_iter;
  logic        x_rows_by_w_cols_iter_valid;
  logic        x_rows_by_w_cols_iter_ready;
  hwpe_ctrl_seq_mult #(
    .AW ( 16 ),
    .BW ( 16 )
  ) i_x_rows_by_w_cols_seqmult
  (
    .clk_i    ( clk_i                       ),
    .rst_ni   ( rst_ni                      ),
    .clear_i  ( clear_i                     ),
    .start_i  ( start_i                     ),
    .a_i      ( config_d.x_rows_iter        ),
    .b_i      ( config_d.w_cols_iter        ),
    .invert_i ( 1'b0                        ),
    .valid_o  ( x_rows_by_w_cols_iter_valid ),
    .ready_o  ( x_rows_by_w_cols_iter_ready ),
    .prod_o   ( x_rows_by_w_cols_iter       )
  );

  // Sequential multiplier x_rows x w_cols x x_cols
  logic [31:0] x_rows_by_w_cols_by_x_cols_iter;
  logic        x_rows_by_w_cols_by_x_cols_iter_valid;
  logic        x_rows_by_w_cols_by_x_cols_iter_ready;
  hwpe_ctrl_seq_mult #(
    .AW ( 16 ),
    .BW ( 32 )
  ) i_x_rows_by_w_cols_by_x_cols_seqmult
  (
    .clk_i    ( clk_i                                 ),
    .rst_ni   ( rst_ni                                ),
    .clear_i  ( clear_i                               ),
    .start_i  ( x_rows_by_w_cols_iter_valid           ),
    .a_i      ( config_d.x_cols_iter                   ),
    .b_i      ( x_rows_by_w_cols_iter                 ),
    .invert_i ( 1'b0                                  ),
    .valid_o  ( x_rows_by_w_cols_by_x_cols_iter_valid ),
    .ready_o  ( x_rows_by_w_cols_by_x_cols_iter_ready ),
    .prod_o   ( x_rows_by_w_cols_by_x_cols_iter       )
  );

  // Sequential multiplier x_rows x w_cols x w_rows
  logic [31:0] x_rows_by_w_cols_by_w_rows_iter;
  logic        x_rows_by_w_cols_by_w_rows_iter_valid;
  logic        x_rows_by_w_cols_by_w_rows_iter_ready;
  hwpe_ctrl_seq_mult #(
    .AW ( 16 ),
    .BW ( 32 )
  ) i_x_rows_by_w_cols_by_w_rows_seqmult
  (
    .clk_i    ( clk_i                                 ),
    .rst_ni   ( rst_ni                                ),
    .clear_i  ( clear_i                               ),
    .start_i  ( x_rows_by_w_cols_iter_valid           ),
    .a_i      ( config_d.w_rows_iter                   ),
    .b_i      ( x_rows_by_w_cols_iter                 ),
    .invert_i ( 1'b0                                  ),
    .valid_o  ( x_rows_by_w_cols_by_w_rows_iter_valid ),
    .ready_o  ( x_rows_by_w_cols_by_w_rows_iter_ready ),
    .prod_o   ( x_rows_by_w_cols_by_w_rows_iter       )
  );

  // Calculate x_buffer_slots
  assign config_d.x_buffer_slots = x_cols_lftovr % (DATA_WIDTH/(ARRAY_HEIGHT*FPFORMAT)) != '0 ? x_cols_lftovr/(DATA_WIDTH/(ARRAY_HEIGHT*FPFORMAT)) + 1 : x_cols_lftovr/(DATA_WIDTH/(ARRAY_HEIGHT*FPFORMAT)); // fixme DIV

  // Calculating the number of total stores
  assign config_d.tot_stores = x_rows_by_w_cols_iter[15:0];

  // Determining if input matrixes are sub-matrixes
  assign config_d.x_rows_sub = (config_d.m_size < ARRAY_WIDTH)  ? 1'b1 : 1'b0;
  assign config_d.x_cols_sub = (config_d.n_size < ARRAY_HEIGHT) ? 1'b1 : 1'b0;
  assign config_d.w_cols_sub = (config_d.k_size < ARRAY_HEIGHT*(PIPE_REGS + 1)) ? 1'b1 : 1'b0;

  assign config_d.stage_1_rnd_mode = config_d.gemm_ops == MATMUL ? RNE :
                                    config_d.gemm_ops == GEMM   ? RNE : 
                                    config_d.gemm_ops == ADDMAX ? RNE :
                                    config_d.gemm_ops == ADDMIN ? RNE :
                                    config_d.gemm_ops == MULMAX ? RNE :
                                    config_d.gemm_ops == MULMIN ? RNE :
                                    config_d.gemm_ops == MAXMIN ? RTZ :
                                                                 RNE ;
  assign config_d.stage_2_rnd_mode = config_d.gemm_ops == MATMUL ? RNE :
                                    config_d.gemm_ops == GEMM   ? RNE : 
                                    config_d.gemm_ops == ADDMAX ? RTZ :
                                    config_d.gemm_ops == ADDMIN ? RNE :
                                    config_d.gemm_ops == MULMAX ? RTZ :
                                    config_d.gemm_ops == MULMIN ? RNE :
                                    config_d.gemm_ops == MAXMIN ? RNE :
                                                                 RTZ;
  assign config_d.stage_1_op       = config_d.gemm_ops == MATMUL ? FMADD :
                                    config_d.gemm_ops == GEMM   ? FMADD : 
                                    config_d.gemm_ops == ADDMAX ? ADD :
                                    config_d.gemm_ops == ADDMIN ? ADD :
                                    config_d.gemm_ops == MULMAX ? MUL :
                                    config_d.gemm_ops == MULMIN ? MUL :
                                    config_d.gemm_ops == MAXMIN ? MINMAX :
                                                                 MINMAX;
  assign config_d.stage_2_op       = MINMAX;
  assign config_d.input_format     = config_d.gemm_input_fmt == FP16    ? FP16 :
                                    config_d.gemm_input_fmt == FP8     ? FP8 : 
                                    config_d.gemm_input_fmt == FP16ALT ? FP16ALT :
                                                                        FP8ALT;
  assign config_d.computing_format = config_d.gemm_output_fmt == FP16    ? FP16 :
                                    config_d.gemm_output_fmt == FP8     ? FP8 : 
                                    config_d.gemm_output_fmt == FP16ALT ? FP16ALT :
                                                                         FP8ALT;
  assign config_d.gemm_selection   = config_d.gemm_ops == MATMUL ? 1'b0 : 1'b1;

  assign config_d.x_d1_stride = ((4*FPFORMAT)/ADDR_WIDTH)*(((DATA_WIDTH/FPFORMAT)*x_cols_iter_nolftovr) + config_d.x_cols_lftovr);
  assign config_d.x_rows_offs = ARRAY_WIDTH*config_d.x_d1_stride;
  assign config_d.w_tot_len   = x_rows_by_w_cols_by_w_rows_iter[15:0];
  assign config_d.w_d0_stride = ((4*FPFORMAT)/ADDR_WIDTH)*(((DATA_WIDTH/FPFORMAT)*w_cols_iter_nolftovr) + config_d.w_cols_lftovr);
  assign config_d.yz_tot_len  = ARRAY_WIDTH*x_rows_by_w_cols_iter[15:0];
  assign config_d.yz_d0_stride = config_d.w_d0_stride;
  assign config_d.yz_d2_stride = ARRAY_WIDTH*config_d.w_d0_stride;
  assign config_d.tot_x_read   = x_rows_by_w_cols_by_x_cols_iter[15:0];

  // register configuration to avoid critical paths (maybe removable!)
  always_ff @(posedge clk_i or negedge rst_ni)
  begin
    if(~rst_ni)
      config_q <= '0;
    else if (clear_i)
      config_q <= '0;
    else if(x_rows_by_w_cols_by_w_rows_iter_valid & x_rows_by_w_cols_by_w_rows_iter_ready)
      config_q <= config_d;
  end

  // generate output valid
  always_ff @(posedge clk_i or negedge rst_ni)
  begin
    if(~rst_ni)
      valid_o <= '0;
    else if (clear_i)
      valid_o <= '0;
    else if(x_rows_by_w_cols_by_w_rows_iter_ready)
      valid_o <= x_rows_by_w_cols_by_w_rows_iter_valid;
  end

  // re-encode in older RedMulE "memory map"
  assign reg_file_o.hwpe_params[0]         = config_q.x_addr;
  assign reg_file_o.hwpe_params[1]         = config_q.w_addr;
  assign reg_file_o.hwpe_params[2]         = config_q.y_addr;
  assign reg_file_o.hwpe_params[3]         = config_q.z_addr;
  assign reg_file_o.hwpe_params[4][31:16]  = config_q.x_rows_iter;
  assign reg_file_o.hwpe_params[4][15: 0]  = config_q.x_cols_iter;
  assign reg_file_o.hwpe_params[5][31:16]  = config_q.w_rows_iter;
  assign reg_file_o.hwpe_params[5][15: 0]  = config_q.w_cols_iter;
  assign reg_file_o.hwpe_params[6][31:24]  = config_q.x_rows_lftovr;
  assign reg_file_o.hwpe_params[6][23:16]  = config_q.x_cols_lftovr;
  assign reg_file_o.hwpe_params[6][15: 8]  = config_q.w_rows_lftovr;
  assign reg_file_o.hwpe_params[6][ 7: 0]  = config_q.w_cols_lftovr;
  assign reg_file_o.hwpe_params[7][31:16]  = config_q.tot_stores;
  assign reg_file_o.hwpe_params[8]         = config_q.x_d1_stride;
  assign reg_file_o.hwpe_params[9]         = config_q.w_tot_len;
  assign reg_file_o.hwpe_params[10]        = config_q.tot_x_read;
  assign reg_file_o.hwpe_params[11]        = config_q.w_d0_stride;
  assign reg_file_o.hwpe_params[12]        = config_q.yz_tot_len;
  assign reg_file_o.hwpe_params[13]        = config_q.yz_d0_stride;
  assign reg_file_o.hwpe_params[14]        = config_q.yz_d2_stride;
  assign reg_file_o.hwpe_params[15]        = config_q.x_rows_offs;
  assign reg_file_o.hwpe_params[16]        = config_q.x_buffer_slots;
  assign reg_file_o.hwpe_params[17]        = config_q.x_tot_len;
  assign reg_file_o.hwpe_params[18][31:29] = config_q.stage_1_rnd_mode;
  assign reg_file_o.hwpe_params[18][28:26] = config_q.stage_2_rnd_mode;
  assign reg_file_o.hwpe_params[18][24:22] = config_q.stage_1_op;
  assign reg_file_o.hwpe_params[18][20:18] = config_q.stage_2_op;
  assign reg_file_o.hwpe_params[18][17:15] = config_q.input_format;
  assign reg_file_o.hwpe_params[18][14:12] = config_q.computing_format;
  assign reg_file_o.hwpe_params[18][0]     = config_q.gemm_selection;

endmodule : redmule_config_decoder
