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
  input  ctrl_regfile_t          reg_file_i       ,
  input  flgs_streamer_t         flgs_streamer_i  ,
  input  cntrl_scheduler_t       cntrl_scheduler_i,
  output cntrl_streamer_t        cntrl_streamer_o ,
  hwpe_stream_intf_stream.sink   next_row_i       ,
  hwpe_stream_intf_stream.sink   next_gidx_i      ,
  hwpe_stream_intf_stream.source scales_bias_o    ,
  hwpe_stream_intf_stream.source scales_skip_o    ,
  hwpe_stream_intf_stream.source zeros_bias_o     ,
  hwpe_stream_intf_stream.source zeros_skip_o     ,
  hwpe_stream_intf_stream.source wq_bias_o        ,
  hwpe_stream_intf_stream.source wq_skip_o
);
  localparam int unsigned JMP = NumByte*(DATA_W/MemDw);

  logic [31:0]        x_cols_offs_d, x_cols_offs_q;
  logic [31:0]        x_rows_offs_d, x_rows_offs_q;

  logic [15:0]        x_cols_iters_d, x_cols_iters_q,
                      x_rows_iters_d, x_rows_iters_q;

  logic [15:0]        w_iters_d, w_iters_q;

  logic [15:0]        tot_x_read_d, tot_x_read_q;

  logic [$clog2(W):0] num_x_reads;

  logic [1:0]         q_shift;

  logic               gidx_present;

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

  assign q_shift = reg_file_i.hwpe_params[DEQUANT_MODE][2:1] == QINT_2 ? 2'b11 :
                   reg_file_i.hwpe_params[DEQUANT_MODE][2:1] == QINT_4 ? 2'b10 :
                                                                         2'b01 ;

  always_comb begin : address_gen_signals
    // Here we initialize the streamer source signals
    // for the X stream source
  `ifdef PACE_ENABLED
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[X_ADDR]
                                                                      + x_rows_offs_q + x_cols_offs_q;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.tot_len = cntrl_streamer_o.pace_mode ? PACE_PART_BST_STAGES+PACE_NPOLY+1 : num_x_reads;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d0_len = cntrl_streamer_o.pace_mode ? PACE_PART_BST_STAGES+PACE_NPOLY+1 : 'd1;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d0_stride = cntrl_streamer_o.pace_mode ? (PACE_PART_BST_STAGES+PACE_NPOLY+1)*2 : 'd0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d1_len = W;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d1_stride = reg_file_i.hwpe_params[X_D1_STRIDE];
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d2_stride = '0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d3_stride = '0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;
`else
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[X_ADDR]
                                                                      + x_rows_offs_q + x_cols_offs_q;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.tot_len = num_x_reads;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d0_len = 'd1;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d0_stride = 'd0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d1_len = W;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d1_stride = reg_file_i.hwpe_params[X_D1_STRIDE];
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d2_stride = '0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d2_len = '0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d3_stride = '0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;
`endif
    // Here we initialize the streamer source signals
    // for the W stream source
    // In quantization mode this is used to load the scales instead
    if (reg_file_i.hwpe_params[DEQUANT_MODE][0] == 1'b0) begin
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[W_ADDR];
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.tot_len = reg_file_i.hwpe_params[W_TOT_LEN];
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d0_len = reg_file_i.hwpe_params[W_ITERS][31:16];
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d0_stride = reg_file_i.hwpe_params[W_D0_STRIDE];
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d1_len = reg_file_i.hwpe_params[W_ITERS][15:0];
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d1_stride = JMP;
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d2_stride = 'd0;
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d2_len = '0;
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d3_stride = '0;
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;
    end else begin
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[SCALES_ADDR];
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.tot_len = reg_file_i.hwpe_params[W_TOT_LEN];
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d0_stride = '0;
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d0_len = reg_file_i.hwpe_params[W_ITERS][31:16];
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d1_stride = JMP;
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d1_len = reg_file_i.hwpe_params[W_ITERS][15:0];
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d2_stride = 'd0;
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d2_len = '0;
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d3_stride = '0;
      cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;
    end

    // Here we initialize the streamer source signals
    // for the Y stream source
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[Z_ADDR];
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.tot_len = reg_file_i.hwpe_params[Z_TOT_LEN];
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d0_len = W;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d0_stride = reg_file_i.hwpe_params[Z_D0_STRIDE];
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d1_len = reg_file_i.hwpe_params[W_ITERS][15:0];
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d1_stride = JMP;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d2_stride = reg_file_i.hwpe_params[Z_D2_STRIDE];
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d2_len = '0;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d3_stride = '0;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;

    // Here we initialize the streamer sink signals for
    // the Z stream sink
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[Z_ADDR];
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.tot_len = reg_file_i.hwpe_params[Z_TOT_LEN];
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d0_len = W;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d0_stride = reg_file_i.hwpe_params[Z_D0_STRIDE];
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d1_len = reg_file_i.hwpe_params[W_ITERS][15:0];
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d1_stride = JMP;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d2_stride = reg_file_i.hwpe_params[Z_D2_STRIDE];
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d2_len = '0;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d3_stride = '0;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;

    // Here we initialize the streamer source signals
    // for the GIDX stream source
    cntrl_streamer_o.gid_stream_source_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[GIDX_ADDR];
    cntrl_streamer_o.gid_stream_source_ctrl.addressgen_ctrl.tot_len = reg_file_i.hwpe_params[W_TOT_LEN]/(DATAW/GW);
    cntrl_streamer_o.gid_stream_source_ctrl.addressgen_ctrl.d0_len = reg_file_i.hwpe_params[W_ITERS][31:16]/(DATAW/GW);
    cntrl_streamer_o.gid_stream_source_ctrl.addressgen_ctrl.d0_stride = JMP;
    cntrl_streamer_o.gid_stream_source_ctrl.addressgen_ctrl.d1_len = reg_file_i.hwpe_params[W_ITERS][15:0];
    cntrl_streamer_o.gid_stream_source_ctrl.addressgen_ctrl.d1_stride = '0;
    cntrl_streamer_o.gid_stream_source_ctrl.addressgen_ctrl.d2_stride = '0;
    cntrl_streamer_o.gid_stream_source_ctrl.addressgen_ctrl.d2_len = '0;
    cntrl_streamer_o.gid_stream_source_ctrl.addressgen_ctrl.d3_stride = '0;
    cntrl_streamer_o.gid_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 3'b001;

    // Here we initialize the streamer source signals
    // for the Wq stream source
    cntrl_streamer_o.wq_stream_source_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[W_ADDR];
    cntrl_streamer_o.wq_stream_source_ctrl.addressgen_ctrl.tot_len = reg_file_i.hwpe_params[W_TOT_LEN];
    cntrl_streamer_o.wq_stream_source_ctrl.addressgen_ctrl.d0_stride = '0;
    cntrl_streamer_o.wq_stream_source_ctrl.addressgen_ctrl.d0_len = D;          //FIXME LEFTOVERS
    cntrl_streamer_o.wq_stream_source_ctrl.addressgen_ctrl.d1_stride = (reg_file_i.hwpe_params[W_D0_STRIDE] * D) >> q_shift;
    cntrl_streamer_o.wq_stream_source_ctrl.addressgen_ctrl.d1_len = reg_file_i.hwpe_params[W_ITERS][31:16] / D;
    cntrl_streamer_o.wq_stream_source_ctrl.addressgen_ctrl.d2_stride = JMP >> q_shift;
    cntrl_streamer_o.wq_stream_source_ctrl.addressgen_ctrl.d2_len = reg_file_i.hwpe_params[W_ITERS][15:0];
    cntrl_streamer_o.wq_stream_source_ctrl.addressgen_ctrl.d3_stride = '0;
    cntrl_streamer_o.wq_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 3'b111;

    // Here we initialize the streamer source signals
    // for the Zeros stream source
    cntrl_streamer_o.zeros_stream_source_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[ZEROS_ADDR];
    cntrl_streamer_o.zeros_stream_source_ctrl.addressgen_ctrl.tot_len = reg_file_i.hwpe_params[W_TOT_LEN];
    cntrl_streamer_o.zeros_stream_source_ctrl.addressgen_ctrl.d0_stride = '0;
    cntrl_streamer_o.zeros_stream_source_ctrl.addressgen_ctrl.d0_len = reg_file_i.hwpe_params[W_ITERS][31:16];
    cntrl_streamer_o.zeros_stream_source_ctrl.addressgen_ctrl.d1_stride = JMP >> q_shift;
    cntrl_streamer_o.zeros_stream_source_ctrl.addressgen_ctrl.d1_len = reg_file_i.hwpe_params[W_ITERS][15:0];
    cntrl_streamer_o.zeros_stream_source_ctrl.addressgen_ctrl.d2_stride = 'd0;
    cntrl_streamer_o.zeros_stream_source_ctrl.addressgen_ctrl.d2_len = 'd0;
    cntrl_streamer_o.zeros_stream_source_ctrl.addressgen_ctrl.d3_stride = 'd0;
    cntrl_streamer_o.zeros_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;

`ifdef PACE_ENABLED
   // for the PACE stream source
    cntrl_streamer_o.pace_stream_source_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[W_ADDR];
    cntrl_streamer_o.pace_stream_source_ctrl.addressgen_ctrl.tot_len = reg_file_i.hwpe_params[PACE_D0_LENGTH];
    cntrl_streamer_o.pace_stream_source_ctrl.addressgen_ctrl.d0_len = reg_file_i.hwpe_params[PACE_D0_LENGTH];
    cntrl_streamer_o.pace_stream_source_ctrl.addressgen_ctrl.d0_stride = reg_file_i.hwpe_params[PACE_D0_STRIDE];
    cntrl_streamer_o.pace_stream_source_ctrl.addressgen_ctrl.d1_len = reg_file_i.hwpe_params[W_ITERS][15:0];
    cntrl_streamer_o.pace_stream_source_ctrl.addressgen_ctrl.d1_stride = JMP;
    cntrl_streamer_o.pace_stream_source_ctrl.addressgen_ctrl.d2_stride = 'd0;
    cntrl_streamer_o.pace_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;

    // for the PACE stream sink
    cntrl_streamer_o.pace_stream_sink_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[Z_ADDR];
    cntrl_streamer_o.pace_stream_sink_ctrl.addressgen_ctrl.tot_len = reg_file_i.hwpe_params[PACE_D0_LENGTH];
    cntrl_streamer_o.pace_stream_sink_ctrl.addressgen_ctrl.d0_len = reg_file_i.hwpe_params[PACE_D0_LENGTH];
    cntrl_streamer_o.pace_stream_sink_ctrl.addressgen_ctrl.d0_stride = reg_file_i.hwpe_params[PACE_D0_STRIDE];
    cntrl_streamer_o.pace_stream_sink_ctrl.addressgen_ctrl.d1_len = reg_file_i.hwpe_params[W_ITERS][15:0];
    cntrl_streamer_o.pace_stream_sink_ctrl.addressgen_ctrl.d1_stride = JMP;
    cntrl_streamer_o.pace_stream_sink_ctrl.addressgen_ctrl.d2_stride = reg_file_i.hwpe_params[Z_D2_STRIDE];
    cntrl_streamer_o.pace_stream_sink_ctrl.addressgen_ctrl.dim_enable_1h = 3'b011;
`endif
  end
`ifdef PACE_ENABLED
    logic x_first_load_d, x_first_load_q;
    assign x_first_load_d = clear_i ? 1'b0 : (x_first_load_q ? x_first_load_q : cntrl_streamer_o.pace_stream_source_ctrl.req_start);
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (~rst_ni) begin
        x_first_load_q <= '0;
      end else begin
        x_first_load_q <= x_first_load_d;
      end
  end

`endif
  always_comb begin : req_start_assignment
`ifdef PACE_ENABLED
    cntrl_streamer_o.pace_mode = reg_file_i.hwpe_params[OP_SELECTION][1];
    cntrl_streamer_o.pace_stream_source_ctrl.req_start  = ~cntrl_streamer_o.pace_mode ? 1'b0 : flgs_streamer_i.x_stream_source_flags.done;
    cntrl_streamer_o.pace_stream_sink_ctrl.req_start    = ~cntrl_streamer_o.pace_mode ? 1'b0 : flgs_streamer_i.x_stream_source_flags.done;
    cntrl_streamer_o.x_stream_source_ctrl.req_start     = cntrl_streamer_o.pace_mode ? cntrl_scheduler_i.first_load && flgs_streamer_i.x_stream_source_flags.ready_start  && !x_first_load_q : (cntrl_scheduler_i.first_load || tot_x_read_q != '0 && tot_x_read_q != reg_file_i.hwpe_params[TOT_X_READ]) && flgs_streamer_i.x_stream_source_flags.ready_start;
    cntrl_streamer_o.w_stream_source_ctrl.req_start     = cntrl_streamer_o.pace_mode ? 1'b0 : cntrl_scheduler_i.first_load && flgs_streamer_i.z_stream_sink_flags.ready_start;
    cntrl_streamer_o.y_stream_source_ctrl.req_start     = cntrl_streamer_o.pace_mode ? 1'b0 : cntrl_scheduler_i.first_load && reg_file_i.hwpe_params[OP_SELECTION][0] && flgs_streamer_i.y_stream_source_flags.ready_start;
    cntrl_streamer_o.z_stream_sink_ctrl.req_start       = cntrl_streamer_o.pace_mode ? 1'b0 : cntrl_scheduler_i.first_load && flgs_streamer_i.z_stream_sink_flags.ready_start;
`else
    cntrl_streamer_o.x_stream_source_ctrl.req_start     = (cntrl_scheduler_i.first_load || tot_x_read_q != '0 && tot_x_read_q != reg_file_i.hwpe_params[TOT_X_READ]) && flgs_streamer_i.x_stream_source_flags.ready_start;
    cntrl_streamer_o.w_stream_source_ctrl.req_start     = cntrl_scheduler_i.first_load && flgs_streamer_i.w_stream_source_flags.ready_start;
    cntrl_streamer_o.y_stream_source_ctrl.req_start     = cntrl_scheduler_i.first_load && reg_file_i.hwpe_params[OP_SELECTION][0] && flgs_streamer_i.y_stream_source_flags.ready_start;
    cntrl_streamer_o.z_stream_sink_ctrl.req_start       = cntrl_scheduler_i.first_load && flgs_streamer_i.z_stream_sink_flags.ready_start;
`endif
    cntrl_streamer_o.gid_stream_source_ctrl.req_start   = reg_file_i.hwpe_params[DEQUANT_MODE][0] && cntrl_scheduler_i.first_load && flgs_streamer_i.gid_stream_source_flags.ready_start;
    cntrl_streamer_o.wq_stream_source_ctrl.req_start    = reg_file_i.hwpe_params[DEQUANT_MODE][0] && cntrl_scheduler_i.first_load && flgs_streamer_i.wq_stream_source_flags.ready_start;
    cntrl_streamer_o.zeros_stream_source_ctrl.req_start = reg_file_i.hwpe_params[DEQUANT_MODE][0] && cntrl_scheduler_i.first_load && flgs_streamer_i.zeros_stream_source_flags.ready_start;
  end

  assign cntrl_streamer_o.input_cast_src_fmt  = fpnew_pkg::fp_format_e'(reg_file_i.hwpe_params[OP_SELECTION][15:13]);
  assign cntrl_streamer_o.input_cast_dst_fmt  = fpnew_pkg::fp_format_e'(reg_file_i.hwpe_params[OP_SELECTION][12:10]);
  assign cntrl_streamer_o.output_cast_src_fmt = fpnew_pkg::fp_format_e'(reg_file_i.hwpe_params[OP_SELECTION][12:10]);
  assign cntrl_streamer_o.output_cast_dst_fmt = fpnew_pkg::fp_format_e'(reg_file_i.hwpe_params[OP_SELECTION][15:13]);

  assign cntrl_streamer_o.z_priority = z_priority_i;
  assign cntrl_streamer_o.q_int_fmt           = qint_fmt_e'(reg_file_i.hwpe_params[DEQUANT_MODE][2:1]);

  /* BIAS ASSIGNMENT */

  assign cntrl_streamer_o.w_stream_source_ctrl.ignore_bias      = reg_file_i.hwpe_params[DEQUANT_MODE][0] ? 1'b0 : 1'b1;
  assign cntrl_streamer_o.wq_stream_source_ctrl.ignore_bias     = reg_file_i.hwpe_params[DEQUANT_MODE][0] ? 1'b0 : 1'b1;
  assign cntrl_streamer_o.zeros_stream_source_ctrl.ignore_bias  = reg_file_i.hwpe_params[DEQUANT_MODE][0] ? 1'b0 : 1'b1;

  assign cntrl_streamer_o.w_stream_source_ctrl.ignore_skip      = reg_file_i.hwpe_params[DEQUANT_MODE][0] ? 1'b0 : 1'b1;
  assign cntrl_streamer_o.wq_stream_source_ctrl.ignore_skip     = 1'b1;
  assign cntrl_streamer_o.zeros_stream_source_ctrl.ignore_skip  = reg_file_i.hwpe_params[DEQUANT_MODE][0] ? 1'b0 : 1'b1;

  assign next_row_i.ready       = wq_bias_o.ready;
  assign next_gidx_i.ready      = scales_bias_o.ready && zeros_bias_o.ready;

  assign scales_bias_o.valid    = next_gidx_i.valid && scales_bias_o.ready && zeros_bias_o.ready && scales_skip_o.ready && zeros_skip_o.ready;
  assign scales_bias_o.data     = next_gidx_i.data[GW-1:0] * reg_file_i.hwpe_params[W_D0_STRIDE][15:0];
  assign scales_bias_o.strb     = '1;

  assign scales_skip_o.valid    = next_gidx_i.valid && scales_bias_o.ready && zeros_bias_o.ready && scales_skip_o.ready && zeros_skip_o.ready;
  assign scales_skip_o.data     = next_gidx_i.data[GW];
  assign scales_skip_o.strb     = '1;

  assign zeros_bias_o.valid     = next_gidx_i.valid && scales_bias_o.ready && zeros_bias_o.ready && scales_skip_o.ready && zeros_skip_o.ready;
  assign zeros_bias_o.data      = next_gidx_i.data[GW-1:0] * (reg_file_i.hwpe_params[W_D0_STRIDE][15:0] >> q_shift);
  assign zeros_bias_o.strb      = '1;

  assign zeros_skip_o.valid     = next_gidx_i.valid && scales_bias_o.ready && zeros_bias_o.ready && scales_skip_o.ready && zeros_skip_o.ready;
  assign zeros_skip_o.data      = next_gidx_i.data[GW];
  assign zeros_skip_o.strb      = '1;

  assign wq_bias_o.valid        = next_row_i.valid && wq_bias_o.ready;
  assign wq_bias_o.data         = next_row_i.data * (reg_file_i.hwpe_params[W_D0_STRIDE][15:0] >> q_shift);
  assign wq_bias_o.strb         = '1;

  assign wq_skip_o.valid        = '1;
  assign wq_skip_o.data         = '0;
  assign wq_skip_o.strb         = '1;


endmodule : redmule_memory_scheduler
