// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Andrea Belano <andrea.belano2@unibo.it>
// Arpan Suravi Prasad<prasadar@iis.ee.ethz.ch>
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
  input  logic                   clk_i            ,
  input  logic                   rst_ni           ,
  input  logic                   clear_i          ,
  input  logic                   z_priority_i     ,
  input  redmule_config_t          config_i       ,
  input  flgs_streamer_t         flgs_streamer_i  ,
  input  cntrl_scheduler_t       cntrl_scheduler_i,
  input  cntrl_flags_t           cntrl_flags_i    ,
  output cntrl_streamer_t        cntrl_streamer_o
);
  localparam int unsigned JMP = NumByte*(DATA_W/MemDw);

  logic [31:0]        x_cols_offs_d, x_cols_offs_q;
  logic [31:0]        x_rows_offs_d, x_rows_offs_q;

  logic [15:0]        x_cols_iters_d, x_cols_iters_q,
                      x_rows_iters_d, x_rows_iters_q;

  logic [15:0]        w_iters_d, w_iters_q;

  logic [15:0]        tot_x_read_d, tot_x_read_q;

  logic [$clog2(W):0] x_rows_lftover_d, x_rows_lftover_q;

  logic [$clog2(W):0] num_x_reads;

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_cols_iters_register
    if (~rst_ni) begin
        x_cols_iters_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        x_cols_iters_q <= '0;
      end else if (flgs_streamer_i.x_stream_source_flags.done) begin
        x_cols_iters_q <= x_cols_iters_d;
      end
    end
  end

  assign x_cols_iters_d = x_cols_iters_q == config_i.x_cols_iter-1 ? '0 : x_cols_iters_q + 1;

  always_ff @(posedge clk_i or negedge rst_ni) begin : w_iters_register
    if (~rst_ni) begin
      w_iters_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        w_iters_q <= '0;
      end else if (flgs_streamer_i.x_stream_source_flags.done && x_cols_iters_q == config_i.x_cols_iter-1) begin
        w_iters_q <= w_iters_d;
      end
    end
  end

  assign w_iters_d = w_iters_q == config_i.w_cols_iter-1 ? '0 : w_iters_q + 1;

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_rows_iters_register
    if (~rst_ni) begin
      x_rows_iters_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        x_rows_iters_q <= '0;
      end else if (flgs_streamer_i.x_stream_source_flags.done && x_cols_iters_q == config_i.x_cols_iter-1 && w_iters_q == config_i.w_cols_iter-1) begin
        x_rows_iters_q <= x_rows_iters_d;
      end
    end
  end

  assign x_rows_iters_d = x_rows_iters_q == config_i.x_rows_iter-1 ? '0 : x_rows_iters_q + 1;

  always_ff @(posedge clk_i or negedge rst_ni) begin : tot_x_read_register
    if (~rst_ni) begin
      tot_x_read_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        tot_x_read_q <= '0;
      end else if (flgs_streamer_i.x_stream_source_flags.done) begin
        tot_x_read_q <= tot_x_read_q + 1;
      end
    end
  end

  assign tot_x_read_d = tot_x_read_q == config_i.tot_x_read ? '0 : tot_x_read_q + 1;

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_cols_offs_register
    if (~rst_ni) begin
      x_cols_offs_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        x_cols_offs_q <= '0;
      end else if (flgs_streamer_i.x_stream_source_flags.done) begin
        x_cols_offs_q <= x_cols_offs_d;
      end
    end
  end

  assign x_cols_offs_d = x_cols_iters_q == config_i.x_cols_iter-1 ? '0 : x_cols_offs_q + JMP;

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_rows_offs_register
    if (~rst_ni) begin
      x_rows_offs_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        x_rows_offs_q <= '0;
      end else if (flgs_streamer_i.x_stream_source_flags.done && x_cols_iters_q == config_i.x_cols_iter-1 && w_iters_q == config_i.w_cols_iter-1) begin
        x_rows_offs_q <= x_rows_offs_d;
      end
    end
  end

  assign x_rows_offs_d = x_rows_iters_q == config_i.x_rows_iter-1 ? '0 : x_rows_offs_q + config_i.x_rows_offs;

  assign num_x_reads = x_rows_iters_q == config_i.x_rows_iter-1 && config_i.x_rows_lftovr != '0 ? config_i.x_rows_lftovr : W;

  always_comb begin : address_gen_signals
    // Here we initialize the streamer source signals
    // for the X stream source
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.base_addr = config_i.x_addr
                                                                      + x_rows_offs_q + x_cols_offs_q;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.tot_len = num_x_reads;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d0_len = 'd1;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d0_stride = 'd0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d1_len = W;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d1_stride = config_i.x_d1_stride;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d2_stride = '0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d2_len = '0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d3_stride = '0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;
    // Here we initialize the streamer source signals
    // for the W stream source
    // In quantization mode this is used to load the scales instead
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.base_addr = config_i.w_addr;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.tot_len = config_i.w_tot_len;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d0_len = config_i.w_rows_iter;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d0_stride = config_i.w_d0_stride;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d1_len = config_i.w_cols_iter;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d1_stride = JMP;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d2_stride = 'd0;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d2_len = '0;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d3_stride = '0;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;

    // Here we initialize the streamer source signals
    // for the Y stream source
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.base_addr = config_i.z_addr;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.tot_len = config_i.yz_tot_len;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d0_len = W;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d0_stride = config_i.yz_d0_stride;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d1_len = config_i.w_cols_iter;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d1_stride = JMP;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d2_stride = config_i.yz_d2_stride;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d2_len = '0;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d3_stride = '0;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;

    // Here we initialize the streamer sink signals for
    // the Z stream sink
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.base_addr = config_i.z_addr;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.tot_len = config_i.yz_tot_len;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d0_len = W;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d0_stride = config_i.yz_d0_stride;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d1_len = config_i.w_cols_iter;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d1_stride = JMP;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d2_stride = config_i.yz_d2_stride;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d2_len = '0;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d3_stride = '0;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;

    // Here we initialize the streamer source signals
    // for the R stream source
    cntrl_streamer_o.r_stream_source_ctrl.addressgen_ctrl.base_addr = config_i.r_addr;
    cntrl_streamer_o.r_stream_source_ctrl.addressgen_ctrl.tot_len = config_i.n_size/W;
    cntrl_streamer_o.r_stream_source_ctrl.addressgen_ctrl.d0_len = '0;
    cntrl_streamer_o.r_stream_source_ctrl.addressgen_ctrl.d0_stride = W*ELW/8;
    cntrl_streamer_o.r_stream_source_ctrl.addressgen_ctrl.d1_len = '0;
    cntrl_streamer_o.r_stream_source_ctrl.addressgen_ctrl.d1_stride = '0;
    cntrl_streamer_o.r_stream_source_ctrl.addressgen_ctrl.d2_stride = '0;
    cntrl_streamer_o.r_stream_source_ctrl.addressgen_ctrl.d2_len = '0;
    cntrl_streamer_o.r_stream_source_ctrl.addressgen_ctrl.d3_stride = '0;
    cntrl_streamer_o.r_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 3'b000;

    // Here we initialize the streamer source signals
    // for the R stream sink
    cntrl_streamer_o.r_stream_sink_ctrl.addressgen_ctrl.base_addr = config_i.r_addr;
    cntrl_streamer_o.r_stream_sink_ctrl.addressgen_ctrl.tot_len = config_i.n_size/W;
    cntrl_streamer_o.r_stream_sink_ctrl.addressgen_ctrl.d0_len = '0;
    cntrl_streamer_o.r_stream_sink_ctrl.addressgen_ctrl.d0_stride = W*ELW/8;
    cntrl_streamer_o.r_stream_sink_ctrl.addressgen_ctrl.d1_len = '0;
    cntrl_streamer_o.r_stream_sink_ctrl.addressgen_ctrl.d1_stride = '0;
    cntrl_streamer_o.r_stream_sink_ctrl.addressgen_ctrl.d2_stride = '0;
    cntrl_streamer_o.r_stream_sink_ctrl.addressgen_ctrl.d2_len = '0;
    cntrl_streamer_o.r_stream_sink_ctrl.addressgen_ctrl.d3_stride = '0;
    cntrl_streamer_o.r_stream_sink_ctrl.addressgen_ctrl.dim_enable_1h = 3'b000;
  end

  always_comb begin : req_start_assignment
    cntrl_streamer_o.x_stream_source_ctrl.req_start     = !cntrl_flags_i.idle && (cntrl_scheduler_i.first_load || tot_x_read_q != '0 && tot_x_read_q != config_i.tot_x_read) && flgs_streamer_i.x_stream_source_flags.ready_start;
    cntrl_streamer_o.w_stream_source_ctrl.req_start     = cntrl_scheduler_i.first_load && flgs_streamer_i.w_stream_source_flags.ready_start;
    cntrl_streamer_o.y_stream_source_ctrl.req_start     = cntrl_scheduler_i.first_load && config_i.gemm_selection && flgs_streamer_i.y_stream_source_flags.ready_start;
    cntrl_streamer_o.r_stream_source_ctrl.req_start     = cntrl_scheduler_i.first_load && config_i.red_init && flgs_streamer_i.r_stream_source_flags.ready_start;
    cntrl_streamer_o.z_stream_sink_ctrl.req_start       = cntrl_scheduler_i.first_load && flgs_streamer_i.z_stream_sink_flags.ready_start;
    cntrl_streamer_o.r_stream_sink_ctrl.req_start       = cntrl_scheduler_i.first_load && (config_i.red_op != RED_NONE) && flgs_streamer_i.r_stream_sink_flags.ready_start;
  end

  assign cntrl_streamer_o.input_cast_src_fmt  = fpnew_pkg::fp_format_e'(config_i.input_format);
  assign cntrl_streamer_o.input_cast_dst_fmt  = fpnew_pkg::fp_format_e'(config_i.computing_format);
  assign cntrl_streamer_o.output_cast_src_fmt = fpnew_pkg::fp_format_e'(config_i.computing_format);
  assign cntrl_streamer_o.output_cast_dst_fmt = fpnew_pkg::fp_format_e'(config_i.input_format);

  assign cntrl_streamer_o.z_priority = z_priority_i;

  assign cntrl_streamer_o.receive_w_stream = config_i.receive_w;
  assign cntrl_streamer_o.receive_x_stream = config_i.receive_x;
endmodule : redmule_memory_scheduler
