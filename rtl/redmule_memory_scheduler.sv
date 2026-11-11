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
  parameter int unsigned   DW   = MaxDataW,
  parameter int unsigned   W    = MaxDim
) (
  input  logic                   clk_i            ,
  input  logic                   rst_ni           ,
  input  logic                   clear_i          ,
  input  logic                   z_priority_i     ,
  input  redmule_config_t        config_i         ,
  input  logic                   config_valid_i   ,
  input  flgs_streamer_t         flgs_streamer_i  ,
  input  cntrl_scheduler_t       cntrl_scheduler_i,
  input  cntrl_flags_t           cntrl_flags_i    ,
  output logic                   z_fifo_empty_o   ,
  output logic                   z_fifo_full_o    ,
  output logic                   x_done_o         ,
  output logic [31:0]            z_store_end_addr_o,
  output redmule_config_t        z_config_o       ,
  output redmule_config_t        y_config_o       ,
  output logic                   z_pad_final_o    ,
  output logic                   y_pad_final_o    ,
  output cntrl_streamer_t        cntrl_streamer_o
);
  localparam int unsigned JMP = DW/8;

  logic [31:0]        x_cols_offs_d, x_cols_offs_q;
  logic [31:0]        x_rows_offs_d, x_rows_offs_q;

  logic [15:0]        x_cols_iters_d, x_cols_iters_q,
                      x_rows_iters_d, x_rows_iters_q;

  logic [15:0]        w_iters_d, w_iters_q;

  logic [15:0]        tot_x_read_d, tot_x_read_q;

  logic [$clog2(W):0] num_x_reads;

  redmule_config_t x_config, w_config, y_config, z_config;
  logic            x_config_empty, w_config_empty, y_config_empty, z_config_empty;
  logic            x_config_full, z_config_full;

  // Once a successor job is queued, the streams overlap and all jobs in this
  // busy period must keep the padded final-block geometry. The flag persists
  // until the controller clears the accelerator.
  logic            z_pipelined_q, z_pipelined_d;

  logic            start_x_streamer;

  logic            store_empty_rise;
  logic            store_empty_rise_cnt;

  logic            y_fifo_pop, y_fifo_pop_matmul;

  assign x_done_o = tot_x_read_q == x_config.tot_x_read-1 && flgs_streamer_i.x_stream_source_flags.done;

  redmule_config_fifo #(
    .FALL_THROUGH (0),
    .DEPTH (2),
    .dtype (redmule_config_t)
  ) i_x_config_fifo (
    .clk_i      ( clk_i                           ),
    .rst_ni     ( rst_ni                          ),
    .flush_i    ( clear_i | cntrl_scheduler_i.rst ),
    .testmode_i ( '0                              ),
    .full_o     ( x_config_full                   ),
    .empty_o    ( x_config_empty                  ),
    .usage_o    (                                 ),
    .data_i     ( config_i                        ),
    .push_i     ( config_valid_i                  ),
    .data_o     ( x_config                        ),
    .pop_i      ( x_done_o                        )
  );

  redmule_config_fifo #(
    .FALL_THROUGH (0),
    .DEPTH (2),
    .dtype (redmule_config_t)
  ) i_w_config_fifo (
    .clk_i      ( clk_i                                      ),
    .rst_ni     ( rst_ni                                     ),
    .flush_i    ( clear_i | cntrl_scheduler_i.rst            ),
    .testmode_i ( '0                                         ),
    .full_o     (                                            ),
    .empty_o    ( w_config_empty                             ),
    .usage_o    (                                            ),
    .data_i     ( config_i                                   ),
    .push_i     ( config_valid_i                             ),
    .data_o     ( w_config                                   ),
    .pop_i      ( flgs_streamer_i.w_stream_source_flags.done )
  );

  redmule_config_fifo #(
    .FALL_THROUGH (0),
    .DEPTH (2),
    .dtype (redmule_config_t)
  ) i_y_config_fifo (
    .clk_i      ( clk_i                                                                                                           ),
    .rst_ni     ( rst_ni                                                                                                          ),
    .flush_i    ( clear_i | cntrl_scheduler_i.rst                                                                                 ),
    .testmode_i ( '0                                                                                                              ),
    .full_o     (                                                                                                                 ),
    .empty_o    ( y_config_empty                                                                                                  ),
    .usage_o    (                                                                                                                 ),
    .data_i     ( config_i                                                                                                        ),
    .push_i     ( config_valid_i                                                                                                  ),
    .data_o     ( y_config                                                                                                        ),
    .pop_i      ( y_fifo_pop                                                                                                      )
  );

  redmule_config_fifo #(
    .FALL_THROUGH (0),
    .DEPTH (2),
    .dtype (redmule_config_t)
  ) i_z_config_fifo (
    .clk_i      ( clk_i                                    ),
    .rst_ni     ( rst_ni                                   ),
    .flush_i    ( clear_i | cntrl_scheduler_i.rst          ),
    .testmode_i ( '0                                       ),
    .full_o     ( z_config_full                            ),
    .empty_o    ( z_config_empty                           ),
    .usage_o    (                                          ),
    .data_i     ( config_i                                 ),
    .push_i     ( config_valid_i                           ),
    .data_o     ( z_config                                 ),
    .pop_i      ( flgs_streamer_i.z_stream_sink_flags.done )
  );

  always_comb begin : z_pipelined_next
    z_pipelined_d = z_pipelined_q;
    if (z_config_full) begin
      z_pipelined_d = 1'b1;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : z_pipelined_register
    if (~rst_ni) begin
      z_pipelined_q <= 1'b0;
    end else if (clear_i || cntrl_scheduler_i.rst) begin
      z_pipelined_q <= 1'b0;
    end else begin
      z_pipelined_q <= z_pipelined_d;
    end
  end

  edge_detect i_store_fifo_empty_edge_detector (
    .clk_i  ( clk_i                            ),
    .rst_ni ( rst_ni                           ),
    .d_i    ( flgs_streamer_i.store_fifo_empty ),
    .re_o   ( store_empty_rise                 ),
    .fe_o   (                                  )
  );

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      store_empty_rise_cnt <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst || flgs_streamer_i.y_stream_source_flags.done || y_fifo_pop_matmul) begin
        store_empty_rise_cnt <= '0;
      end else if (store_empty_rise && ~y_config_empty) begin
        store_empty_rise_cnt <= 1'b1;
      end
    end
  end

  // Y config FIFO pop: one per job, as every job (MATMUL included) pushes one config.
  // - GEMM: when the Y load is done.
  // - MATMUL (no Y load): on the second store-FIFO empty rise of the job, so that, in case of a
  //   MATMUL followed by a GEMM, Y is loaded only after the first 2 Z chunks have been completely
  //   stored. The counter is cleared by this pop, so the next MATMUL counts its own two rises
  //   again. Gated by ~y_config_empty: once the MATMUL config has been popped, data_o still shows
  //   it, and the later store-FIFO empty rises of the job must not pop again.
  assign y_fifo_pop_matmul = ~y_config_empty && ~y_config.gemm_selection && store_empty_rise_cnt && store_empty_rise;
  assign y_fifo_pop        = ~y_config_empty && (y_config.gemm_selection ? flgs_streamer_i.y_stream_source_flags.done : y_fifo_pop_matmul);

  assign z_config_o = z_config;
  assign y_config_o = y_config;
  assign z_pad_final_o = z_pipelined_q
                       || (z_config.w_cols_iter > 16'd1
                           && z_config.w_cols_lftovr != '0
                           && z_config.x_rows_lftovr > 1);
  assign y_pad_final_o = z_pipelined_q
                       || (y_config.w_cols_iter > 16'd1
                           && y_config.w_cols_lftovr != '0
                           && y_config.x_rows_lftovr > 1);

  assign z_fifo_empty_o = z_config_empty;
  assign z_fifo_full_o = z_config_full;

  // End of the real M*K output region for the currently active store config.
  assign z_store_end_addr_o = z_config.z_addr
                            + z_config.m_size * z_config.yz_d0_stride;

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

  assign x_cols_iters_d = x_cols_iters_q == x_config.x_cols_iter-1 ? '0 : x_cols_iters_q + 1;

  always_ff @(posedge clk_i or negedge rst_ni) begin : w_iters_register
    if (~rst_ni) begin
      w_iters_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        w_iters_q <= '0;
      end else if (flgs_streamer_i.x_stream_source_flags.done && x_cols_iters_q == x_config.x_cols_iter-1) begin
        w_iters_q <= w_iters_d;
      end
    end
  end

  assign w_iters_d = w_iters_q == x_config.w_cols_iter-1 ? '0 : w_iters_q + 1;

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_rows_iters_register
    if (~rst_ni) begin
      x_rows_iters_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        x_rows_iters_q <= '0;
      end else if (flgs_streamer_i.x_stream_source_flags.done && x_cols_iters_q == x_config.x_cols_iter-1 && w_iters_q == x_config.w_cols_iter-1) begin
        x_rows_iters_q <= x_rows_iters_d;
      end
    end
  end

  assign x_rows_iters_d = x_rows_iters_q == x_config.x_rows_iter-1 ? '0 : x_rows_iters_q + 1;

  always_ff @(posedge clk_i or negedge rst_ni) begin : tot_x_read_register
    if (~rst_ni) begin
      tot_x_read_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        tot_x_read_q <= '0;
      end else if (flgs_streamer_i.x_stream_source_flags.done) begin
        tot_x_read_q <= tot_x_read_d;
      end
    end
  end

  assign tot_x_read_d = tot_x_read_q == x_config.tot_x_read-1 ? '0 : tot_x_read_q + 1;

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

  assign x_cols_offs_d = x_cols_iters_q == x_config.x_cols_iter-1 ? '0 : x_cols_offs_q + JMP;

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_rows_offs_register
    if (~rst_ni) begin
      x_rows_offs_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        x_rows_offs_q <= '0;
      end else if (flgs_streamer_i.x_stream_source_flags.done && x_cols_iters_q == x_config.x_cols_iter-1 && w_iters_q == x_config.w_cols_iter-1) begin
        x_rows_offs_q <= x_rows_offs_d;
      end
    end
  end

  assign x_rows_offs_d = x_rows_iters_q == x_config.x_rows_iter-1 ? '0 : x_rows_offs_q + x_config.x_rows_offs;

  assign num_x_reads = x_rows_iters_q == x_config.x_rows_iter-1 && x_config.x_rows_lftovr != '0 ? x_config.x_rows_lftovr : W;

  always_comb begin : address_gen_signals
    // Here we initialize the streamer source signals
    // for the X stream source
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.base_addr = x_config.x_addr
                                                                      + x_rows_offs_q + x_cols_offs_q;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.tot_len = num_x_reads;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d0_len = 'd1;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d0_stride = 'd0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d1_len = W;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d1_stride = x_config.x_d1_stride;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d2_stride = '0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d2_len = '0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d3_stride = '0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;
    // Here we initialize the streamer source signals
    // for the W stream source
    // In quantization mode this is used to load the scales instead
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.base_addr = w_config.w_addr;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.tot_len = w_config.w_tot_len;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d0_len = w_config.w_rows_iter;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d0_stride = w_config.w_d0_stride;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d1_len = w_config.w_cols_iter;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d1_stride = JMP;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d2_stride = 'd0;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d2_len = '0;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d3_stride = '0;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;

    // Here we initialize the streamer source signals
    // for the Y stream source. The custom redmule_y_stream_source uses
    // config_i for its per-M-block linear generator; these legacy addressgen
    // fields remain defined for compatibility with the shared control bus.
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.base_addr = y_config.y_addr;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.tot_len = y_config.yz_tot_len;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d0_len = W;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d0_stride = y_config.yz_d0_stride;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d1_len = y_config.w_cols_iter;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d1_stride = JMP;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d2_stride = y_config.yz_d2_stride;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d2_len = '0;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d3_stride = '0;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;

    // Here we initialize the streamer sink signals for
    // the Z stream sink. The custom redmule_z_stream_sink uses config_i for its
    // per-M-block linear generator; these legacy addressgen fields remain
    // defined for compatibility with the shared control bus.
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.base_addr = z_config.z_addr;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.tot_len = z_config.yz_tot_len;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d0_len = W;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d0_stride = z_config.yz_d0_stride;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d1_len = z_config.w_cols_iter;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d1_stride = JMP;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d2_stride = z_config.yz_d2_stride;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d2_len = '0;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d3_stride = '0;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;
  end

  assign start_x_streamer = (~x_config_empty && ~x_config_full && ~x_done_o) || x_config_full;

  always_comb begin : req_start_assignment
    cntrl_streamer_o.x_stream_source_ctrl.req_start     = (start_x_streamer || tot_x_read_q != '0 && tot_x_read_q != x_config.tot_x_read) && flgs_streamer_i.x_stream_source_flags.ready_start;
    cntrl_streamer_o.w_stream_source_ctrl.req_start     = ~w_config_empty && flgs_streamer_i.w_stream_source_flags.ready_start;
    cntrl_streamer_o.y_stream_source_ctrl.req_start     = ~y_config_empty && y_config.gemm_selection && flgs_streamer_i.y_stream_source_flags.ready_start;
    cntrl_streamer_o.z_stream_sink_ctrl.req_start       = ~z_config_empty && flgs_streamer_i.z_stream_sink_flags.ready_start && ~flgs_streamer_i.z_stream_sink_flags.done; // we need the ~done here as this is asserted at the same time as the ready_start signal in sink modules
  end

  // FIXME
  assign cntrl_streamer_o.input_cast_src_fmt  = fpnew_pkg::fp_format_e'(config_i.input_format);
  assign cntrl_streamer_o.input_cast_dst_fmt  = fpnew_pkg::fp_format_e'(config_i.computing_format);
  assign cntrl_streamer_o.output_cast_src_fmt = fpnew_pkg::fp_format_e'(config_i.computing_format);
  assign cntrl_streamer_o.output_cast_dst_fmt = fpnew_pkg::fp_format_e'(config_i.input_format);

  assign cntrl_streamer_o.z_priority = z_priority_i;

  assign cntrl_streamer_o.receive_w_stream = w_config.receive_w;
  assign cntrl_streamer_o.receive_x_stream = x_config.receive_x;
endmodule : redmule_memory_scheduler
