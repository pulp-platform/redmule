// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
// Arpan Suravi Prasad<prasadar@iis.ee.ethz.ch>
//

import fpnew_pkg::*;
import hci_package::*;
import hwpe_stream_package::*;

package redmule_pkg;
  parameter int unsigned MaxDim               = 32;
  parameter int unsigned MaxPipeRegs          = 4;
  parameter int unsigned MaxDepth             = MaxDim * MaxPipeRegs;
  parameter int unsigned MaxDataW             = MaxDepth * 16;
  parameter int unsigned MisalignedAccessSupportDefault = 0; // default to 0 for compatibility with Snitch

  parameter int unsigned NumStreamSources     = 3; // X, W, Y

  parameter int unsigned XsourceStreamId      = 0;
  parameter int unsigned WsourceStreamId      = 1;
  parameter int unsigned YsourceStreamId      = 2;

  typedef enum logic { HWPE_TARGET, XIF } ctrl_intf_e;
  
  typedef enum logic { LD_IN_FMP, LD_WEIGHT } source_sel_e;
  typedef enum logic { LOAD, STORE }          ld_st_sel_e;

  typedef struct packed {
    hci_package::hci_streamer_ctrl_t        x_stream_source_ctrl;
    hci_package::hci_streamer_ctrl_t        w_stream_source_ctrl;
    hci_package::hci_streamer_ctrl_t        y_stream_source_ctrl;
    hci_package::hci_streamer_ctrl_t        r_stream_source_ctrl;
    hci_package::hci_streamer_ctrl_t        z_stream_sink_ctrl;
    hci_package::hci_streamer_ctrl_t        r_stream_sink_ctrl;
    fpnew_pkg::fp_format_e                  input_cast_src_fmt;
    fpnew_pkg::fp_format_e                  input_cast_dst_fmt;
    fpnew_pkg::fp_format_e                  output_cast_src_fmt;
    fpnew_pkg::fp_format_e                  output_cast_dst_fmt;
    logic                                   z_priority;
    logic                                   receive_w_stream;
    logic                                   receive_x_stream;
  } cntrl_streamer_t;

  typedef struct packed {
    logic                             store_fifo_empty;
    hci_package::hci_streamer_flags_t x_stream_source_flags;
    hci_package::hci_streamer_flags_t w_stream_source_flags;
    hci_package::hci_streamer_flags_t y_stream_source_flags;
    hci_package::hci_streamer_flags_t z_stream_sink_flags;
  } flgs_streamer_t;

  typedef struct packed {
    logic                        h_shift;
    logic                        load;
    logic                        pad_setup;
    logic [$clog2(MaxDim)-1:0]   width;
    logic [$clog2(MaxDepth)-1:0] height;
    logic [$clog2(MaxDepth)-1:0] slots;
    logic                        rst_w_index;
    logic                        last_x;
  } x_buffer_ctrl_t;

  typedef struct packed {
    logic empty;
    logic full;
  } x_buffer_flgs_t;

  typedef struct packed {
    logic                        shift;
    logic                        load;
    logic [$clog2(MaxDepth)-1:0] width;
    logic [$clog2(MaxDim)-1:0]   height;
    logic [MaxDim-1:0]           zero_set;
  } w_buffer_ctrl_t;

  typedef struct packed {
    logic [MaxDim-1:0] empty;
    logic              w_ready;
  } w_buffer_flgs_t;

  typedef struct packed {
    logic        y_push_enable;
    logic        fill;
    logic        ready;
    logic        y_valid;
    logic        first_load;
    logic        is_biased;
    logic        mask_y;
    logic [$clog2(MaxDim)-1:0]   y_width;
    logic [$clog2(MaxDepth)-1:0] y_height;
    logic [$clog2(MaxDim)-1:0]   z_width;
    logic [$clog2(MaxDepth)-1:0] z_height;
  } z_buffer_ctrl_t;

  typedef struct packed {
    logic y_pushed;
    logic empty;
    logic full;
    logic loaded;
    logic y_ready;
    logic z_valid;
    logic z_priority;
  } z_buffer_flgs_t;

  typedef struct packed {
    logic                   [2:0] fma_is_boxed;
    logic                   [1:0] noncomp_is_boxed;
    fpnew_pkg::roundmode_e        stage1_rnd;
    fpnew_pkg::roundmode_e        stage2_rnd;
    fpnew_pkg::operation_e        op1;
    fpnew_pkg::operation_e        op2;
    logic                         op_mod;
    logic                         in_valid;
    logic                         flush;
    logic                         out_ready;
    logic                         accumulate;
    logic [MaxDim-1:0]            row_clk_gate_en;
  } cntrl_engine_t;

  typedef struct packed {
    logic                  [MaxDim-1:0][MaxDim-1:0] in_ready;
    fpnew_pkg::status_t    [MaxDim-1:0][MaxDim-1:0] status;
    logic                  [MaxDim-1:0][MaxDim-1:0] extension_bit;
    fpnew_pkg::classmask_e [MaxDim-1:0][MaxDim-1:0] class_mask;
    logic                  [MaxDim-1:0][MaxDim-1:0] is_mask;
    logic                  [MaxDim-1:0][MaxDim-1:0] out_valid;
    logic                  [MaxDim-1:0][MaxDim-1:0] busy;
  } flgs_engine_t;

  typedef struct packed {
    logic start_fsm;
    logic first_load;
    logic engine_working;
    logic storing;
    logic rst;
    logic finished;
    logic done;
  } cntrl_scheduler_t;

  typedef struct packed {
    logic                  y_push_enable;
    logic                  x_ready;
    logic                  w_ready;
    logic                  y_ready;
    logic                  z_valid;
    logic                  x_full;
    logic                  w_loaded;
    logic                  w_shift;
    logic                  stored;
    logic [MaxDataW/8-1:0] z_strb;
  } flgs_scheduler_t;

  typedef struct packed {
    logic idle;
  } cntrl_flags_t;

  typedef enum logic [2:0] { MATMUL=3'h0, GEMM=3'h1, ADDMAX=3'h2, ADDMIN=3'h3, MULMAX=3'h4, MULMIN=3'h5, MAXMIN=3'h6, MINMAX=3'h7 } gemm_op_e;
  typedef enum logic [1:0] { Float8=2'h0, Float16=2'h1, Float8Alt=2'h2, Float16Alt=2'h3 } gemm_fmt_e;
  typedef enum logic       { RNE=1'h0, RTZ=1'h1 } rnd_mode_e;
  typedef enum logic [2:0] { FPU_FMADD=3'h0, FPU_ADD=3'h2, FPU_MUL=3'h3, FPU_MINMAX=3'h7 }    fpu_op_e;
  typedef enum logic [2:0] { FPU_FP16=3'h2, FPU_FP8=3'h3, FPU_FP16ALT=3'h4, FPU_FP8ALT=3'h5 } fpu_fmt_e;

  typedef struct packed {
    logic [31:0] x_addr;
    logic [31:0] w_addr;
    logic [31:0] z_addr;
    logic [31:0] y_addr;
    logic [15:0] m_size;
    logic [15:0] n_size;
    logic [15:0] k_size;
    logic [31:0] y_offs;
    gemm_op_e gemm_ops;
    gemm_fmt_e gemm_input_fmt;
    gemm_fmt_e gemm_output_fmt;

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
    logic [31:0] tot_x_read;
    logic [31:0] w_d0_stride;
    logic [31:0] yz_tot_len;
    logic [31:0] yz_d0_stride;
    logic [31:0] yz_d2_stride;
    logic [31:0] x_rows_offs;
    logic [31:0] x_buffer_slots;
    logic [31:0] x_tot_len;
    rnd_mode_e stage_1_rnd_mode;
    rnd_mode_e stage_2_rnd_mode;
    fpu_op_e stage_1_op;
    fpu_op_e stage_2_op;
    fpu_fmt_e input_format;
    fpu_fmt_e computing_format;
    logic        gemm_selection;
    logic        send_w;
    logic        receive_w;
    logic        send_x;
    logic        receive_x;
  } redmule_config_t;

endpackage
