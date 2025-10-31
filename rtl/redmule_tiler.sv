// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
// Francesco Conti <f.conti@unibo.it>
// Arpan Suravi Prasad<prasadar@iis.ee.ethz.ch>


module redmule_tiler
  import redmule_pkg::*;
  import hwpe_ctrl_package::*;
(
  input  logic              clk_i      ,
  input  logic              rst_ni     ,
  input  logic              clear_i    ,
  input  logic              setback_i  ,
  input  logic              start_cfg_i,
  output logic              valid_o    ,
  input  redmule_config_t   config_i   ,
  output redmule_config_t   config_o
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

assign config_d.x_addr          = config_i.x_addr;
assign config_d.w_addr          = config_i.w_addr;
assign config_d.z_addr          = config_i.z_addr;
assign config_d.m_size          = config_i.m_size;
assign config_d.k_size          = config_i.k_size;
assign config_d.n_size          = config_i.n_size;
assign config_d.gemm_ops        = config_i.gemm_ops;
assign config_d.gemm_input_fmt  = config_i.gemm_input_fmt;
assign config_d.gemm_output_fmt = config_i.gemm_output_fmt;
assign config_d.r_addr          = config_i.r_addr;
assign config_d.red_init        = config_i.red_init;
assign config_d.red_op          = config_i.red_op;
assign config_d.receive_w       = config_i.receive_w;
assign config_d.send_w          = config_i.send_w;
assign config_d.receive_x       = config_i.receive_x;
assign config_d.send_x          = config_i.send_x;

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
logic [31:0] x_rows_by_w_cols_iter_d, x_rows_by_w_cols_iter_q;
logic        x_rows_by_w_cols_iter_valid_d, x_rows_by_w_cols_iter_valid_q;

assign x_rows_by_w_cols_iter_d = start_cfg_i ? config_d.x_rows_iter * config_d.w_cols_iter : x_rows_by_w_cols_iter_q;

always_ff @(posedge clk_i or negedge rst_ni) begin
  if (~rst_ni) begin
    x_rows_by_w_cols_iter_q <= '0;
  end else begin
    if (clear_i | setback_i) begin
      x_rows_by_w_cols_iter_q <= '0;
    end else begin
      x_rows_by_w_cols_iter_q <= x_rows_by_w_cols_iter_d;
    end
  end
end

assign x_rows_by_w_cols_iter_valid_d = start_cfg_i;

always_ff @(posedge clk_i or negedge rst_ni) begin
  if (~rst_ni) begin
    x_rows_by_w_cols_iter_valid_q <= '0;
  end else begin
    if (clear_i | setback_i) begin
      x_rows_by_w_cols_iter_valid_q <= '0;
    end else begin
      x_rows_by_w_cols_iter_valid_q <= x_rows_by_w_cols_iter_valid_d;
    end
  end
end

// Sequential multiplier x_rows x w_cols x x_cols
logic [47:0] x_rows_by_w_cols_by_x_cols_iter_d, x_rows_by_w_cols_by_x_cols_iter_q;
logic        x_rows_by_w_cols_by_x_cols_iter_valid_d, x_rows_by_w_cols_by_x_cols_iter_valid_q;

assign x_rows_by_w_cols_by_x_cols_iter_d = x_rows_by_w_cols_iter_valid_q ? config_d.x_cols_iter * x_rows_by_w_cols_iter_q : x_rows_by_w_cols_by_x_cols_iter_q;

always_ff @(posedge clk_i or negedge rst_ni) begin
  if (~rst_ni) begin
    x_rows_by_w_cols_by_x_cols_iter_q <= '0;
  end else begin
    if (clear_i | setback_i) begin
      x_rows_by_w_cols_by_x_cols_iter_q <= '0;
    end else begin
      x_rows_by_w_cols_by_x_cols_iter_q <= x_rows_by_w_cols_by_x_cols_iter_d;
    end
  end
end

assign x_rows_by_w_cols_by_x_cols_iter_valid_d = x_rows_by_w_cols_iter_valid_q;

always_ff @(posedge clk_i or negedge rst_ni) begin
  if (~rst_ni) begin
    x_rows_by_w_cols_by_x_cols_iter_valid_q <= '0;
  end else begin
    if (clear_i | setback_i) begin
      x_rows_by_w_cols_by_x_cols_iter_valid_q <= '0;
    end else begin
      x_rows_by_w_cols_by_x_cols_iter_valid_q <= x_rows_by_w_cols_by_x_cols_iter_valid_d;
    end
  end
end

// Sequential multiplier x_rows x w_cols x w_rows
logic [47:0] x_rows_by_w_cols_by_w_rows_iter_d, x_rows_by_w_cols_by_w_rows_iter_q;
logic        x_rows_by_w_cols_by_w_rows_iter_valid_d, x_rows_by_w_cols_by_w_rows_iter_valid_q;

assign x_rows_by_w_cols_by_w_rows_iter_d = x_rows_by_w_cols_iter_valid_q ? config_d.w_rows_iter * x_rows_by_w_cols_iter_q : x_rows_by_w_cols_by_w_rows_iter_q;

always_ff @(posedge clk_i or negedge rst_ni) begin
  if (~rst_ni) begin
    x_rows_by_w_cols_by_w_rows_iter_q <= '0;
  end else begin
    if (clear_i | setback_i) begin
      x_rows_by_w_cols_by_w_rows_iter_q <= '0;
    end else begin
      x_rows_by_w_cols_by_w_rows_iter_q <= x_rows_by_w_cols_by_w_rows_iter_d;
    end
  end
end

assign x_rows_by_w_cols_by_w_rows_iter_valid_d = x_rows_by_w_cols_iter_valid_q;

always_ff @(posedge clk_i or negedge rst_ni) begin
  if (~rst_ni) begin
    x_rows_by_w_cols_by_w_rows_iter_valid_q <= '0;
  end else begin
    if (clear_i | setback_i) begin
      x_rows_by_w_cols_by_w_rows_iter_valid_q <= '0;
    end else begin
      x_rows_by_w_cols_by_w_rows_iter_valid_q <= x_rows_by_w_cols_by_w_rows_iter_valid_d;
    end
  end
end

// Calculate x_buffer_slots
logic [31:0] buffer_slots;
//assign buffer_slots = config_d.x_cols_lftovr/(DATAW/(ARRAY_HEIGHT*BITW));
//assign config_d.x_buffer_slots = ((config_d.x_cols_lftovr % (DATAW/(ARRAY_HEIGHT*BITW)) != '0) ? buffer_slots + 1 :
//                                                                                                buffer_slots) * (DATAW/(ARRAY_HEIGHT*BITW));

assign buffer_slots = config_d.x_cols_lftovr/ARRAY_HEIGHT;
assign config_d.x_buffer_slots = ((config_d.x_cols_lftovr % ARRAY_HEIGHT != '0) ? buffer_slots + 1 :
                                                                                                buffer_slots) * ARRAY_HEIGHT;

// Calculating the number of total stores
assign config_d.tot_stores = x_rows_by_w_cols_iter_q[15:0];

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
assign config_d.w_tot_len   = x_rows_by_w_cols_by_w_rows_iter_q[31:0];
assign config_d.w_d0_stride = ((NumByte*BITW)/ADDR_W)*(((DATAW/BITW)*w_cols_iter_nolftovr) + config_d.w_cols_lftovr);
assign config_d.yz_tot_len  = ARRAY_WIDTH*x_rows_by_w_cols_iter_q[15:0];
assign config_d.yz_d0_stride = config_d.w_d0_stride;
assign config_d.yz_d2_stride = ARRAY_WIDTH*config_d.w_d0_stride;
assign config_d.tot_x_read   = x_rows_by_w_cols_by_x_cols_iter_q[31:0];
assign config_d.x_tot_len    = '0; // not used

// register configuration to avoid critical paths (maybe removable!)
always_ff @(posedge clk_int or negedge rst_ni) begin
  if(~rst_ni)
    config_q <= '0;
  else if (clear_i)
    config_q <= '0;
  else if(x_rows_by_w_cols_by_w_rows_iter_valid_q && x_rows_by_w_cols_by_x_cols_iter_valid_q)
    config_q <= config_d;
end

// generate output valid
always_ff @(posedge clk_int or negedge rst_ni) begin
  if(~rst_ni)
    valid_o <= '0;
  else if (clear_i | setback_i)
    valid_o <= '0;
  else if(x_rows_by_w_cols_by_w_rows_iter_valid_q && x_rows_by_w_cols_by_x_cols_iter_valid_q)
    valid_o <= x_rows_by_w_cols_by_w_rows_iter_valid_q;
end

assign config_o = config_q;

endmodule: redmule_tiler
