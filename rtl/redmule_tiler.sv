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
#(
  parameter int unsigned DataW = 0,
  parameter int unsigned Height = MaxDim,
  parameter int unsigned Width = MaxDim,
  parameter int unsigned PipeRegs = MaxPipeRegs-1,
  parameter int unsigned FpWidth = 16,
  parameter int unsigned AddrWidth = 32
) (
  input  logic              clk_i      ,
  input  logic              rst_ni     ,
  input  logic              clear_i    ,
  input  logic              setback_i  ,
  input  logic              loopback_i ,
  input  logic              start_cfg_i,
  output logic              valid_o    ,
  output logic              busy_o     ,
  input  logic              ready_i    ,
  input  redmule_config_t   config_i   ,
  output redmule_config_t   config_o
);

// Minimum size N handled by the internal control. Any job with n_size <= Height is run "as if"
// N = MinimumSizeN for the purpose of the W-load loop / scheduler / z_buffer timing (see
// redmule_tiler.sv), while the input operands for the padded N rows [n_size .. MinimumSizeN-1]
// are gated to zero so the result is unaffected. This is necessary to enable the controller to
// work properly in these corner cases.
// The minimum size is defined as MinimumSizeN = MinimumSizeNFactor * Height (e.g., 2*Height)
localparam int unsigned MinimumSizeN = MinimumSizeNFactor * Height;

logic clk_en;
logic clk_int;

redmule_config_t input_config_d, input_config_q;
redmule_config_t config_d, config_q;
logic loopback_active_q, loopback_active;

always_ff @(posedge clk_i, negedge rst_ni) begin: clock_gate_enabler
  if (~rst_ni) begin
    clk_en <= 1'b0;
  end else begin
    if (clear_i || setback_i) begin
      clk_en <= 1'b0;
    end else if ((start_cfg_i && ready_i) || loopback_i) begin
      clk_en <= 1'b1;
    end
  end
end

tc_clk_gating i_tiler_clockg (
  .clk_i      ( clk_i            ),
  .en_i       ( clk_en | clear_i ),
  .test_en_i  ( '0               ),
  .clk_o      ( clk_int          )
);

assign busy_o = clk_en || ~ready_i;


// Store loopback
assign loopback_active = (loopback_i || loopback_active_q);
always_ff @(posedge clk_i, negedge rst_ni) begin: loopback_ff
  if (~rst_ni) begin
    loopback_active_q <= 1'b0;
  end else begin
    loopback_active_q <= !(clear_i || setback_i) && loopback_active;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : input_config_ff
  if (~rst_ni) begin
    input_config_q <= '0;
  end else if (clear_i) begin
    input_config_q <= '0;
  end else if (start_cfg_i && ready_i) begin
    input_config_q <= config_i;
  end
end

assign input_config_d           = loopback_active ? input_config_q : config_i;
assign config_d.x_addr          = input_config_d.x_addr;
assign config_d.w_addr          = loopback_active ? input_config_d.w_addr :
                                  input_config_d.w_addr + input_config_d.w_cols_offset * (FpWidth/8);
assign config_d.z_addr          = loopback_active ? input_config_d.z_addr :
                                  input_config_d.z_addr + input_config_d.w_cols_offset * (FpWidth/8);
assign config_d.y_addr          = loopback_active ? input_config_d.z_addr + input_config_d.y_offs :
                                  input_config_d.z_addr + input_config_d.y_offs + input_config_d.w_cols_offset * (FpWidth/8);
assign config_d.m_size          = input_config_d.m_size;
assign config_d.k_size          = input_config_d.k_size;
assign config_d.n_size          = input_config_d.n_size;

// Effective N size used ONLY for the W-row loop length / streamer length: any job with
// N <= Height is promoted to MinimumSizeN so the W-load takes as long as a full N-tile, restoring
// the large-N scheduler/z_buffer pacing that fixes the small-N multi-block hang. The X-column
// tiling and the store geometry deliberately keep the real config_d.n_size here (X rows are only
// n_size wide, so over-reading X would misalign the addresses); the X buffer is instead promoted to
// a full D-deep tile in redmule_scheduler.sv (cntrl_x_buffer_o.slots) so it advances M-block rows in
// step with the promoted N, and both padded operands are zeroed (X via x_cols_lftovr,
// W via the cntrl_w_buffer_o.height gating in redmule_scheduler.sv).
logic [15:0] n_size_eff;
assign n_size_eff = (input_config_d.n_size <= Height) ? MinimumSizeN[15:0] : input_config_d.n_size;
// Sourced from input_config_d (not config_i directly) so the loopback pass keeps
// the job's original operation/format even after dec_config_q's read pointer has
// advanced past its single valid entry (config_i can no longer be trusted once
// the first pass's completion has popped it).
assign config_d.gemm_ops        = input_config_d.gemm_ops;
assign config_d.gemm_input_fmt  = input_config_d.gemm_input_fmt;
assign config_d.gemm_output_fmt = input_config_d.gemm_output_fmt;
assign config_d.receive_w       = input_config_d.receive_w;
assign config_d.send_w          = input_config_d.send_w;
assign config_d.loopback_w      = loopback_active;
assign config_d.receive_x       = input_config_d.receive_x;
assign config_d.send_x          = input_config_d.send_x;
// Convert the user-programmed column offset into whole RedMulE output tiles.
assign config_d.w_cols_offset   = loopback_active ? '0 : input_config_d.w_cols_offset;
assign config_d.y_offs          = input_config_d.y_offs;

// Calculating the number of iterations alng the two dimensions of the X matrix
logic [15:0] x_rows_iter_nolftovr;
logic [15:0] x_cols_iter_nolftovr;
assign x_rows_iter_nolftovr = config_d.m_size/Width;
assign x_cols_iter_nolftovr = config_d.n_size/(Height*(PipeRegs + 1));

// Calculating the number of iterations along the two dimensions of the W matrix
logic [15:0] w_cols_iter_nolftovr;
logic [15:0] w_rows_iter_lftovr,
             w_rows_iter_nolftovr;
assign w_cols_iter_nolftovr = loopback_active ? (input_config_d.w_cols_offset/(Height*(PipeRegs + 1))) : 
                              (config_d.k_size - input_config_d.w_cols_offset)/(Height*(PipeRegs + 1));
assign w_rows_iter_lftovr = w_rows_iter_nolftovr + Height - config_d.w_rows_lftovr;
assign w_rows_iter_nolftovr = n_size_eff; // promoted N: W-row loop runs for a full N-tile when N <= Height

// Calculating the residuals along the input dimensions
assign config_d.x_rows_lftovr = config_d.m_size - (x_rows_iter_nolftovr*Width);
assign config_d.x_cols_lftovr = config_d.n_size - (x_cols_iter_nolftovr*(Height*(PipeRegs + 1)));

// Calculating the residuals along the weight dimensions
assign config_d.w_rows_lftovr = n_size_eff - (Height*(n_size_eff/Height)); // promoted N (0 when N <= Height -> full W-row loop)
assign config_d.w_cols_lftovr = loopback_active ? input_config_d.w_cols_offset - (w_cols_iter_nolftovr*(Height*(PipeRegs + 1))) :
                                (config_d.k_size - input_config_d.w_cols_offset) - (w_cols_iter_nolftovr*(Height*(PipeRegs + 1)));

// Calculate w_cols iterations
assign config_d.w_cols_iter = config_d.w_cols_lftovr != '0 ? w_cols_iter_nolftovr + 1 : w_cols_iter_nolftovr;

// Calculate w_rows, x_cols, x_rows iterations
assign config_d.w_rows_iter = config_d.w_rows_lftovr != '0 ? w_rows_iter_lftovr       : w_rows_iter_nolftovr;
assign config_d.x_cols_iter = config_d.x_cols_lftovr != '0 ? x_cols_iter_nolftovr + 1 : x_cols_iter_nolftovr;
assign config_d.x_rows_iter = config_d.x_rows_lftovr != '0 ? x_rows_iter_nolftovr + 1 : x_rows_iter_nolftovr;

// Sequential multiplier x_rows x w_cols
logic [31:0] x_rows_by_w_cols_iter_d, x_rows_by_w_cols_iter_q;
logic        x_rows_by_w_cols_iter_valid_d, x_rows_by_w_cols_iter_valid_q;

assign x_rows_by_w_cols_iter_d = (start_cfg_i || loopback_i) ? config_d.x_rows_iter * config_d.w_cols_iter : x_rows_by_w_cols_iter_q;

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

assign x_rows_by_w_cols_iter_valid_d = (start_cfg_i || loopback_i);

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

logic [31:0] buffer_slots;

assign buffer_slots = config_d.x_cols_lftovr/Height;
assign config_d.x_buffer_slots = ((config_d.x_cols_lftovr % Height != '0) ? buffer_slots + 1 :
                                                                                                buffer_slots) * Height;

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

assign config_d.x_d1_stride = ((4*FpWidth)/AddrWidth)*(((DataW/FpWidth)*x_cols_iter_nolftovr) + config_d.x_cols_lftovr);
assign config_d.x_rows_offs = Width*config_d.x_d1_stride;
assign config_d.w_tot_len   = x_rows_by_w_cols_by_w_rows_iter_q[31:0];
assign config_d.w_d0_stride = ((4*FpWidth)/AddrWidth)*((DataW/FpWidth) * (config_d.k_size)/(Height*(PipeRegs + 1)));
assign config_d.yz_tot_len  = Width*x_rows_by_w_cols_iter_q[15:0];
assign config_d.yz_d0_stride = config_d.w_d0_stride;
assign config_d.yz_d2_stride = Width*config_d.w_d0_stride;
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

`ifndef SYNTHESIS
`ifndef VERILATOR
`ifndef VCS
initial begin
  dataw: assert (DataW == Height*(PipeRegs+1)*16);
end
`endif
`endif
`endif

endmodule: redmule_tiler
