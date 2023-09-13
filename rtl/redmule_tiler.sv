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
 * Authors:  Yvan Tortorella <yvan.tortorella@unibo.it>
 *           Francesco Conti <f.conti@unibo.it>
 * 
 * RedMulE Tiler
 */

module redmule_tiler
  import redmule_pkg::*;
  import hwpe_ctrl_package::*;
(
  input  logic              clk_i      ,
  input  logic              rst_ni     ,
  input  logic              clear_i    ,
  input  logic              setback_i  ,
  input  logic              start_cfg_i,
  input  ctrl_regfile_t     reg_file_i ,
  output logic              valid_o    ,
  output ctrl_regfile_t     reg_file_o
);

logic clk_en;
logic clk_int;

redmule_config_t config_d, config_q;

always_ff @(posedge clk_i, negedge rst_ni) begin: clock_gate_enabler
  if (~rst_ni) begin
    clk_en <= 1'b0;
  end else begin
    if (clear_i || setback_i) begin
      clk_en <= 1'b0;
    end else if (start_cfg_i) begin
      clk_en <= 1'b1;
    end
  end
end

tc_clk_gating i_tiler_clockg (
  .clk_i      ( clk_i   ),
  .en_i       ( clk_en  ),
  .test_en_i  ( '0      ),
  .clk_o      ( clk_int )
);

assign config_d.x_addr          = reg_file_i.hwpe_params[X_ADDR];
assign config_d.w_addr          = reg_file_i.hwpe_params[W_ADDR];
assign config_d.z_addr          = reg_file_i.hwpe_params[Z_ADDR];
assign config_d.m_size          = reg_file_i.hwpe_params[MCFIG0][15: 0];
assign config_d.k_size          = reg_file_i.hwpe_params[MCFIG0][31:16];
assign config_d.n_size          = reg_file_i.hwpe_params[MCFIG1][15: 0];
assign config_d.gemm_ops        = gemm_op_e' (reg_file_i.hwpe_params[MACFG][12:10]);
assign config_d.gemm_input_fmt  = gemm_fmt_e'(reg_file_i.hwpe_params[MACFG][ 9: 7]);
assign config_d.gemm_output_fmt = gemm_fmt_e'(reg_file_i.hwpe_params[MACFG][ 9: 7]);

// Calculating the number of iterations alng the two dimensions of the X matrix
logic [15:0] x_rows_iter_nolftovr;
logic [15:0] x_cols_iter_nolftovr;
assign x_rows_iter_nolftovr = config_d.m_size/ARRAY_WIDTH;
assign x_cols_iter_nolftovr = config_d.n_size/(ARRAY_HEIGHT*(PIPE_REGS + 1));

// Calculating the number of iterations along the two dimensions of the W matrix
logic [15:0] w_cols_iter_nolftovr;
logic [15:0] w_rows_iter_lftovr,
             w_rows_iter_nolftovr;
assign w_cols_iter_nolftovr = config_d.k_size/(ARRAY_HEIGHT*(PIPE_REGS + 1));
assign w_rows_iter_lftovr = w_rows_iter_nolftovr + ARRAY_HEIGHT - config_d.w_rows_lftovr;
assign w_rows_iter_nolftovr = config_d.n_size;

// Calculating the residuals along the input dimensions
assign config_d.x_rows_lftovr = config_d.m_size - (x_rows_iter_nolftovr*ARRAY_WIDTH);
assign config_d.x_cols_lftovr = config_d.n_size - (x_cols_iter_nolftovr*(ARRAY_HEIGHT*(PIPE_REGS + 1)));

// Calculating the residuals along the weight dimensions
assign config_d.w_rows_lftovr = config_d.n_size - (ARRAY_HEIGHT*(config_d.n_size/ARRAY_HEIGHT));
assign config_d.w_cols_lftovr = config_d.k_size - (w_cols_iter_nolftovr*(ARRAY_HEIGHT*(PIPE_REGS + 1)));

// Calculate w_cols, x_cols, x_rows iterations
assign config_d.w_cols_iter = config_d.w_cols_lftovr != '0 ? w_cols_iter_nolftovr + 1 : w_cols_iter_nolftovr;
assign config_d.w_rows_iter = config_d.w_rows_lftovr != '0 ? w_rows_iter_lftovr       : w_rows_iter_nolftovr;
assign config_d.x_cols_iter = config_d.x_cols_lftovr != '0 ? x_cols_iter_nolftovr + 1 : x_cols_iter_nolftovr;
assign config_d.x_rows_iter = config_d.x_rows_lftovr != '0 ? x_rows_iter_nolftovr + 1 : x_rows_iter_nolftovr;

// Sequential multiplier x_rows x w_cols
logic [31:0] x_rows_by_w_cols_iter;
logic        x_rows_by_w_cols_iter_valid, x_rows_by_w_cols_iter_valid_d, x_rows_by_w_cols_iter_valid_q;
logic        x_rows_by_w_cols_iter_ready;
hwpe_ctrl_seq_mult #(
  .AW ( 16 ),
  .BW ( 16 )
) i_x_rows_by_w_cols_seqmult (
  .clk_i    ( clk_i                         ),
  .rst_ni   ( rst_ni                        ),
  .clear_i  ( clear_i | setback_i           ),
  .start_i  ( start_cfg_i                   ),
  .a_i      ( config_d.x_rows_iter          ),
  .b_i      ( config_d.w_cols_iter          ),
  .invert_i ( 1'b0                          ),
  .valid_o  ( x_rows_by_w_cols_iter_valid_d ),
  .ready_o  ( x_rows_by_w_cols_iter_ready   ),
  .prod_o   ( x_rows_by_w_cols_iter         )
);
always_ff @(posedge clk_int or negedge rst_ni) begin
  if(~rst_ni)
    x_rows_by_w_cols_iter_valid_q <= '0;
  else if(clear_i | setback_i)
    x_rows_by_w_cols_iter_valid_q <= '0;
  else
    x_rows_by_w_cols_iter_valid_q <= x_rows_by_w_cols_iter_valid_d;
end
assign x_rows_by_w_cols_iter_valid = ~x_rows_by_w_cols_iter_valid_q & x_rows_by_w_cols_iter_valid_d;

// Sequential multiplier x_rows x w_cols x x_cols
logic [47:0] x_rows_by_w_cols_by_x_cols_iter;
logic        x_rows_by_w_cols_by_x_cols_iter_valid;
logic        x_rows_by_w_cols_by_x_cols_iter_ready;
hwpe_ctrl_seq_mult #(
  .AW ( 16 ),
  .BW ( 32 )
) i_x_rows_by_w_cols_by_x_cols_seqmult (
  .clk_i    ( clk_int                               ),
  .rst_ni   ( rst_ni                                ),
  .clear_i  ( clear_i | setback_i                   ),
  .start_i  ( x_rows_by_w_cols_iter_valid           ),
  .a_i      ( config_d.x_cols_iter                  ),
  .b_i      ( x_rows_by_w_cols_iter                 ),
  .invert_i ( 1'b0                                  ),
  .valid_o  ( x_rows_by_w_cols_by_x_cols_iter_valid ),
  .ready_o  ( x_rows_by_w_cols_by_x_cols_iter_ready ),
  .prod_o   ( x_rows_by_w_cols_by_x_cols_iter       )
);

// Sequential multiplier x_rows x w_cols x w_rows
logic [47:0] x_rows_by_w_cols_by_w_rows_iter;
logic        x_rows_by_w_cols_by_w_rows_iter_valid;
logic        x_rows_by_w_cols_by_w_rows_iter_ready;
hwpe_ctrl_seq_mult #(
  .AW ( 16 ),
  .BW ( 32 )
) i_x_rows_by_w_cols_by_w_rows_seqmult (
  .clk_i    ( clk_int                               ),
  .rst_ni   ( rst_ni                                ),
  .clear_i  ( clear_i | setback_i                   ),
  .start_i  ( x_rows_by_w_cols_iter_valid           ),
  .a_i      ( config_d.w_rows_iter                  ),
  .b_i      ( x_rows_by_w_cols_iter                 ),
  .invert_i ( 1'b0                                  ),
  .valid_o  ( x_rows_by_w_cols_by_w_rows_iter_valid ),
  .ready_o  ( x_rows_by_w_cols_by_w_rows_iter_ready ),
  .prod_o   ( x_rows_by_w_cols_by_w_rows_iter       )
);

// Calculate x_buffer_slots
logic [31:0] buffer_slots;
assign buffer_slots = config_d.x_cols_lftovr/(DATAW/(ARRAY_HEIGHT*BITW));
assign config_d.x_buffer_slots = (config_d.x_cols_lftovr % (DATAW/(ARRAY_HEIGHT*BITW)) != '0) ? buffer_slots + 1 :
                                                                                                buffer_slots;

// Calculating the number of total stores
assign config_d.tot_stores = x_rows_by_w_cols_iter[15:0];

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
assign config_d.stage_1_op       = config_d.gemm_ops == MATMUL ? FPU_FMADD :
                                   config_d.gemm_ops == GEMM   ? FPU_FMADD :
                                   config_d.gemm_ops == ADDMAX ? FPU_ADD :
                                   config_d.gemm_ops == ADDMIN ? FPU_ADD :
                                   config_d.gemm_ops == MULMAX ? FPU_MUL :
                                   config_d.gemm_ops == MULMIN ? FPU_MUL :
                                   config_d.gemm_ops == MAXMIN ? FPU_MINMAX :
                                                                 FPU_MINMAX;
assign config_d.stage_2_op       = FPU_MINMAX;
assign config_d.input_format     = config_d.gemm_input_fmt == Float16    ? FPU_FP16 :
                                   config_d.gemm_input_fmt == Float8     ? FPU_FP8 :
                                   config_d.gemm_input_fmt == Float16Alt ? FPU_FP16ALT :
                                                                        FPU_FP8ALT;
assign config_d.computing_format = config_d.gemm_output_fmt == Float16    ? FPU_FP16 :
                                   config_d.gemm_output_fmt == Float8     ? FPU_FP8 :
                                   config_d.gemm_output_fmt == Float16Alt ? FPU_FP16ALT :
                                                                         FPU_FP8ALT;
assign config_d.gemm_selection   = config_d.gemm_ops == MATMUL ? 1'b0 : 1'b1;

assign config_d.x_d1_stride = ((NumByte*BITW)/ADDR_W)*(((DATAW/BITW)*x_cols_iter_nolftovr) + config_d.x_cols_lftovr);
assign config_d.x_rows_offs = ARRAY_WIDTH*config_d.x_d1_stride;
assign config_d.w_tot_len   = x_rows_by_w_cols_by_w_rows_iter[31:0];
assign config_d.w_d0_stride = ((NumByte*BITW)/ADDR_W)*(((DATAW/BITW)*w_cols_iter_nolftovr) + config_d.w_cols_lftovr);
assign config_d.yz_tot_len  = ARRAY_WIDTH*x_rows_by_w_cols_iter[15:0];
assign config_d.yz_d0_stride = config_d.w_d0_stride;
assign config_d.yz_d2_stride = ARRAY_WIDTH*config_d.w_d0_stride;
assign config_d.tot_x_read   = x_rows_by_w_cols_by_x_cols_iter[31:0];
assign config_d.x_tot_len    = '0; // not used

// register configuration to avoid critical paths (maybe removable!)
always_ff @(posedge clk_int or negedge rst_ni) begin
  if(~rst_ni)
    config_q <= '0;
  else if (clear_i)
    config_q <= '0;
  else if(x_rows_by_w_cols_by_w_rows_iter_valid & x_rows_by_w_cols_by_w_rows_iter_ready)
    config_q <= config_d;
end

// generate output valid
always_ff @(posedge clk_int or negedge rst_ni) begin
  if(~rst_ni)
    valid_o <= '0;
  else if (clear_i | setback_i)
    valid_o <= '0;
  else if(x_rows_by_w_cols_by_w_rows_iter_ready)
    valid_o <= x_rows_by_w_cols_by_w_rows_iter_valid;
end

// re-encode in older RedMulE regfile map
assign reg_file_o.generic_params = '0;
assign reg_file_o.ext_data = '0;
assign reg_file_o.hwpe_params[REGFILE_N_MAX_IO_REGS-1:REDMULE_REGS] = '0;
assign reg_file_o.hwpe_params[      X_ADDR]        = config_d.x_addr; // do not register (these are straight from regfile)
assign reg_file_o.hwpe_params[      W_ADDR]        = config_d.w_addr; // do not register (these are straight from regfile)
assign reg_file_o.hwpe_params[      Z_ADDR]        = config_d.z_addr; // do not register (these are straight from regfile)
assign reg_file_o.hwpe_params[     X_ITERS][31:16] = config_q.x_rows_iter;
assign reg_file_o.hwpe_params[     X_ITERS][15: 0] = config_q.x_cols_iter;
assign reg_file_o.hwpe_params[     W_ITERS][31:16] = config_q.w_rows_iter;
assign reg_file_o.hwpe_params[     W_ITERS][15: 0] = config_q.w_cols_iter;
assign reg_file_o.hwpe_params[   LEFTOVERS][31:24] = config_q.x_rows_lftovr;
assign reg_file_o.hwpe_params[   LEFTOVERS][23:16] = config_q.x_cols_lftovr;
assign reg_file_o.hwpe_params[   LEFTOVERS][15: 8] = config_q.w_rows_lftovr;
assign reg_file_o.hwpe_params[   LEFTOVERS][ 7: 0] = config_q.w_cols_lftovr;
assign reg_file_o.hwpe_params[ LEFT_PARAMS][31:16] = config_q.tot_stores;
assign reg_file_o.hwpe_params[ LEFT_PARAMS][15: 0] = '0;
assign reg_file_o.hwpe_params[ X_D1_STRIDE]        = config_q.x_d1_stride;
assign reg_file_o.hwpe_params[   W_TOT_LEN]        = config_q.w_tot_len;
assign reg_file_o.hwpe_params[  TOT_X_READ]        = config_q.tot_x_read;
assign reg_file_o.hwpe_params[ W_D0_STRIDE]        = config_q.w_d0_stride;
assign reg_file_o.hwpe_params[   Z_TOT_LEN]        = config_q.yz_tot_len;
assign reg_file_o.hwpe_params[ Z_D0_STRIDE]        = config_q.yz_d0_stride;
assign reg_file_o.hwpe_params[ Z_D2_STRIDE]        = config_q.yz_d2_stride;
assign reg_file_o.hwpe_params[ X_ROWS_OFFS]        = config_q.x_rows_offs;
assign reg_file_o.hwpe_params[     X_SLOTS]        = config_q.x_buffer_slots;
assign reg_file_o.hwpe_params[  IN_TOT_LEN]        = config_q.x_tot_len;
assign reg_file_o.hwpe_params[OP_SELECTION][31:29] = config_q.stage_1_rnd_mode;
assign reg_file_o.hwpe_params[OP_SELECTION][28:26] = config_q.stage_2_rnd_mode;
assign reg_file_o.hwpe_params[OP_SELECTION][25:21] = config_q.stage_1_op;
assign reg_file_o.hwpe_params[OP_SELECTION][20:16] = config_q.stage_2_op;
assign reg_file_o.hwpe_params[OP_SELECTION][15:13] = config_q.input_format;
assign reg_file_o.hwpe_params[OP_SELECTION][12:10] = config_q.computing_format;
assign reg_file_o.hwpe_params[OP_SELECTION][ 9: 1] = '0;
assign reg_file_o.hwpe_params[OP_SELECTION][0]     = config_q.gemm_selection;

endmodule: redmule_tiler
