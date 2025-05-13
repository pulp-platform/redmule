// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Andrea Belano <andrea.belano2@unibo.it>
//

module redmule_memory_scheduler
  import redmule_pkg::*;
  import hwpe_ctrl_package::*;
#(
  parameter int unsigned   DW   = DATAW,
  parameter int unsigned   W    = ARRAY_WIDTH,
  parameter int unsigned   H    = ARRAY_HEIGHT,
  parameter int unsigned   ELW  = BITW,
  localparam int unsigned  D    = TOT_DEPTH
) (
  input  logic                  clk_i            ,
  input  logic                  rst_ni           ,
  input  logic                  clear_i          ,
  input  logic                  z_priority_i     ,
  input  ctrl_regfile_t         reg_file_i       ,
  input  flgs_streamer_t        flgs_streamer_i  ,
  input  cntrl_scheduler_t      cntrl_scheduler_i,
  input  cntrl_flags_t          cntrl_flags_i    ,
  output cntrl_streamer_t       cntrl_streamer_o
);
  localparam int unsigned JMP = NumByte*(DATA_W/MemDw - 1);

  logic [31:0]        x_cols_offs_d, x_cols_offs_q;
  logic [31:0]        x_rows_offs_d, x_rows_offs_q;

  logic [15:0]        x_cols_iters_d, x_cols_iters_q,
                      x_rows_iters_d, x_rows_iters_q;

  logic [15:0]        w_iters_d, w_iters_q;

  logic [15:0]        tot_x_read_d, tot_x_read_q;

  logic [$clog2(W):0] num_x_reads;

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_cols_iters_register
    if (~rst_ni) begin
        x_cols_iters_q <= '0;
    end else begin
      if (clear_i) begin
        x_cols_iters_q <= '0;
      end else if (flgs_streamer_i.x_stream_source_flags.done) begin
        x_cols_iters_q <= x_cols_iters_d;
      end
    end
  end

  assign x_cols_iters_d = x_cols_iters_q == reg_file_i.hwpe_params[X_ITERS][15:0]-1 ? '0 : x_cols_iters_q + 1;

  always_ff @(posedge clk_i or negedge rst_ni) begin : w_iters_register
    if (~rst_ni) begin
      w_iters_q <= '0;
    end else begin
      if (clear_i) begin
        w_iters_q <= '0;
      end else if (flgs_streamer_i.x_stream_source_flags.done && x_cols_iters_q == reg_file_i.hwpe_params[X_ITERS][15:0]-1) begin
        w_iters_q <= w_iters_d;
      end
    end
  end

  assign w_iters_d = w_iters_q == reg_file_i.hwpe_params[W_ITERS][15:0]-1 ? '0 : w_iters_q + 1;

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_rows_iters_register
    if (~rst_ni) begin
      x_rows_iters_q <= '0;
    end else begin
      if (clear_i) begin
        x_rows_iters_q <= '0;
      end else if (flgs_streamer_i.x_stream_source_flags.done && x_cols_iters_q == reg_file_i.hwpe_params[X_ITERS][15:0]-1 && w_iters_q == reg_file_i.hwpe_params[W_ITERS][15:0]-1) begin
        x_rows_iters_q <= x_rows_iters_d;
      end
    end
  end

  assign x_rows_iters_d = x_rows_iters_q == reg_file_i.hwpe_params[X_ITERS][31:16]-1 ? '0 : x_rows_iters_q + 1;

  always_ff @(posedge clk_i or negedge rst_ni) begin : tot_x_read_register
    if (~rst_ni) begin
      tot_x_read_q <= '0;
    end else begin
      if (clear_i) begin
        tot_x_read_q <= '0;
      end else if (flgs_streamer_i.x_stream_source_flags.done) begin
        tot_x_read_q <= tot_x_read_q + 1;
      end
    end
  end

  assign tot_x_read_d = tot_x_read_q == reg_file_i.hwpe_params[TOT_X_READ] ? '0 : tot_x_read_q + 1;

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_cols_offs_register
    if (~rst_ni) begin
      x_cols_offs_q <= '0;
    end else begin
      if (clear_i) begin
        x_cols_offs_q <= '0;
      end else if (flgs_streamer_i.x_stream_source_flags.done) begin
        x_cols_offs_q <= x_cols_offs_d;
      end
    end
  end

  assign x_cols_offs_d = x_cols_iters_q == reg_file_i.hwpe_params[X_ITERS][15:0]-1 ? '0 : x_cols_offs_q + JMP;

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_rows_offs_register
    if (~rst_ni) begin
      x_rows_offs_q <= '0;
    end else begin
      if (clear_i) begin
        x_rows_offs_q <= '0;
      end else if (flgs_streamer_i.x_stream_source_flags.done && x_cols_iters_q == reg_file_i.hwpe_params[X_ITERS][15:0]-1 && w_iters_q == reg_file_i.hwpe_params[W_ITERS][15:0]-1) begin
        x_rows_offs_q <= x_rows_offs_d;
      end
    end
  end

  assign x_rows_offs_d = x_rows_iters_q == reg_file_i.hwpe_params[X_ITERS][31:16]-1 ? '0 : x_rows_offs_q + reg_file_i.hwpe_params[X_ROWS_OFFS];

  assign num_x_reads = x_rows_iters_q == reg_file_i.hwpe_params[X_ITERS][31:16]-1 && reg_file_i.hwpe_params[LEFTOVERS][31:24] != '0 ? reg_file_i.hwpe_params[LEFTOVERS][31:24] : W;

  // Here we initialize the streamer source signals
  // for the X stream source
  assign cntrl_streamer_o.x_stream_source_ctrl.req_start = !cntrl_flags_i.idle && flgs_streamer_i.x_stream_source_flags.ready_start &&
                                                           (cntrl_scheduler_i.first_load || tot_x_read_q < reg_file_i.hwpe_params[TOT_X_READ]);
  assign cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[X_ADDR]
                                                                    + x_rows_offs_q + x_cols_offs_q;
  assign cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.tot_len = num_x_reads;
  assign cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d0_len = 'd1;
  assign cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d0_stride = 'd0;
  assign cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d1_len = W;
  assign cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d1_stride = reg_file_i.hwpe_params[X_D1_STRIDE];
  assign cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d2_stride = '0;
  assign cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 2'b11;

  // Here we initialize the streamer source signals
  // for the W stream source
  assign cntrl_streamer_o.w_stream_source_ctrl.req_start = cntrl_scheduler_i.first_load && flgs_streamer_i.z_stream_sink_flags.ready_start;
  assign cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[W_ADDR];
  assign cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.tot_len = reg_file_i.hwpe_params[W_TOT_LEN];
  assign cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d0_len = reg_file_i.hwpe_params[W_ITERS][31:16];
  assign cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d0_stride = reg_file_i.hwpe_params[W_D0_STRIDE];
  assign cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d1_len = reg_file_i.hwpe_params[W_ITERS][15:0];
  assign cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d1_stride = JMP;
  assign cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d2_stride = 'd0;
  assign cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 2'b11;

  // Here we initialize the streamer source signals
  // for the Y stream source
  assign cntrl_streamer_o.y_stream_source_ctrl.req_start = cntrl_scheduler_i.first_load && reg_file_i.hwpe_params[OP_SELECTION][0] && flgs_streamer_i.y_stream_source_flags.ready_start;
  assign cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[Z_ADDR];
  assign cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.tot_len = reg_file_i.hwpe_params[Z_TOT_LEN];
  assign cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d0_len = W;
  assign cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d0_stride = reg_file_i.hwpe_params[Z_D0_STRIDE];
  assign cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d1_len = reg_file_i.hwpe_params[W_ITERS][15:0];
  assign cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d1_stride = JMP;
  assign cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d2_stride = reg_file_i.hwpe_params[Z_D2_STRIDE];
  assign cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 2'b11;

  // Here we initialize the streamer sink signals for
  // the Z stream sink
  assign cntrl_streamer_o.z_stream_sink_ctrl.req_start = cntrl_scheduler_i.first_load && flgs_streamer_i.z_stream_sink_flags.ready_start;
  assign cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[Z_ADDR];
  assign cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.tot_len = reg_file_i.hwpe_params[Z_TOT_LEN];
  assign cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d0_len = W;
  assign cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d0_stride = reg_file_i.hwpe_params[Z_D0_STRIDE];
  assign cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d1_len = reg_file_i.hwpe_params[W_ITERS][15:0];
  assign cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d1_stride = JMP;
  assign cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d2_stride = reg_file_i.hwpe_params[Z_D2_STRIDE];
  assign cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.dim_enable_1h = 2'b11;

  assign cntrl_streamer_o.input_cast_src_fmt  = fpnew_pkg::fp_format_e'(reg_file_i.hwpe_params[OP_SELECTION][15:13]);
  assign cntrl_streamer_o.input_cast_dst_fmt  = fpnew_pkg::fp_format_e'(reg_file_i.hwpe_params[OP_SELECTION][12:10]);
  assign cntrl_streamer_o.output_cast_src_fmt = fpnew_pkg::fp_format_e'(reg_file_i.hwpe_params[OP_SELECTION][12:10]);
  assign cntrl_streamer_o.output_cast_dst_fmt = fpnew_pkg::fp_format_e'(reg_file_i.hwpe_params[OP_SELECTION][15:13]);

  assign cntrl_streamer_o.z_priority = z_priority_i;
endmodule : redmule_memory_scheduler
