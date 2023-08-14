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
 * RedMulE Package
 */

import fpnew_pkg::*;
import hci_package::*;
import hwpe_stream_package::*;

package redmule_pkg;

  parameter int unsigned            DATA_W       = 288; // TCDM port dimension (in bits)
  parameter int unsigned            MemDw        = 32;
  parameter int unsigned            ADDR_W       = hci_package::DEFAULT_AW;
  parameter int unsigned            DATAW        = DATA_W - MemDw;
  parameter int unsigned            REDMULE_REGS = 19;
  parameter int unsigned            RegfileScm   = 0;
  parameter int unsigned            N_CONTEXT    = 2;
  parameter fpnew_pkg::fp_format_e  FPFORMAT     = fpnew_pkg::FP16;
  parameter int unsigned            BITW         = fpnew_pkg::fp_width(FPFORMAT);
  parameter int unsigned            ARRAY_HEIGHT = 4;
  parameter int unsigned            PIPE_REGS    = 3;
  parameter int unsigned            ARRAY_WIDTH  = 12; /* Superior limit is ARRAY_HEIGHT*PIPE_REGS */
  parameter int unsigned            TOT_DEPTH    = DATAW/BITW;
  parameter int unsigned            DEPTH        = TOT_DEPTH/ARRAY_HEIGHT;
  parameter int unsigned            STRB         = DATA_W/8;
  parameter fpnew_pkg::fmt_logic_t  FpFmtConfig  = 6'b001101;
  parameter fpnew_pkg::ifmt_logic_t IntFmtConfig = 4'b1000;
  parameter fpnew_pkg::operation_e  CAST_OP      = fpnew_pkg::F2F;
  parameter int unsigned MIN_FMT  = fpnew_pkg::min_fp_width(FpFmtConfig);
  parameter int unsigned DW_CUT   = DATA_W - ARRAY_HEIGHT*(PIPE_REGS + 1)*MIN_FMT;

  // Register file index
  // Matrix addresses
  parameter int unsigned X_ADDR    = 0; // 0x00
  parameter int unsigned W_ADDR    = 1; // 0x04
  parameter int unsigned Y_ADDR    = 2; // 0x08
  parameter int unsigned Z_ADDR    = 3; // 0x0C
  // Number of iterations on X and W matrices
  // (15 bits for number of rows iterations, 15 bits for number of columns iterations)
  parameter int unsigned X_ITERS   = 4; // 0x10 --> [31:16] -> ROWS ITERATIONS, [15:0] -> COLUMNS ITERATIONS
  parameter int unsigned W_ITERS   = 5; // 0x14 --> [31:16] -> ROWS ITERATIONS, [15:0] -> COLUMNS ITERATIONS
  // Number of rows and columns leftovers (8 bits for each)
  // [31:24] -> X/Y ROWS LEFTOVERS 
  // [23:16] -> X COLUMNS LEFTOVERS
  // [15:8]  -> W ROWS LEFTOVERS 
  // [7:0]   -> W/Y COLUMNS LEFTOVERS
  parameter int unsigned LEFTOVERS = 6; // 0x18
  // We keep a register for the remaining params
  // [31:16] -> TOT_NUMBER_OF_STORES
  // [14]    -> 1'b0: X cols/W rows >= ARRAY_HEIGHT; 1'b1: X cols/W rows < ARRAY_HEIGHT
  // [13]    -> 1'b0: W cols >= TILE ( TILE = (PIPE_REGS + 1)*ARRAY_HEIGHT ); 1'b1: W cols < TILE ( TILE = (PIPE_REGS + 1)*ARRAY_HEIGHT )
  parameter int unsigned LEFT_PARAMS = 7;  // 0x1C
  parameter int unsigned X_D1_STRIDE = 8;  // 0x20
  parameter int unsigned W_TOT_LEN   = 9;  // 0x24
  parameter int unsigned TOT_X_READ  = 10; // 0x28
  parameter int unsigned W_D0_STRIDE = 11; // 0x2C
  parameter int unsigned Z_TOT_LEN   = 12; // 0x30
  parameter int unsigned Z_D0_STRIDE = 13; // 0x34
  parameter int unsigned Z_D2_STRIDE = 14; // 0x38
  parameter int unsigned X_ROWS_OFFS = 15; // 0x3C
  parameter int unsigned X_SLOTS     = 16; // 0x40
  parameter int unsigned IN_TOT_LEN  = 17; // 0x44
  // One resgister is used for the round modes and operations of the Computing Elements.
  // [31:29] -> roundmode of the stage 1
  // [28:26] -> roundmode of the stage 2
  // [25:22] -> operation of the stage 1
  // [21:18] -> operation of the stage 2
  // [17:15] -> input/output format
  // [14:12] -> computing format
  // [0:0]   -> GEMM selection
  parameter int unsigned OP_SELECTION = 18; // 0x48
  

  typedef enum logic { LD_IN_FMP, LD_WEIGHT } source_sel_e;
  typedef enum logic { LOAD, STORE }          ld_st_sel_e;

  typedef struct packed {
    hci_package::hci_streamer_ctrl_t x_stream_source_ctrl;
    hci_package::hci_streamer_ctrl_t w_stream_source_ctrl;
    hci_package::hci_streamer_ctrl_t y_stream_source_ctrl;
    hci_package::hci_streamer_ctrl_t z_stream_sink_ctrl;
    fpnew_pkg::fp_format_e           input_cast_src_fmt;
    fpnew_pkg::fp_format_e           input_cast_dst_fmt;
    fpnew_pkg::fp_format_e           output_cast_src_fmt;
    fpnew_pkg::fp_format_e           output_cast_dst_fmt;
  } cntrl_streamer_t;

  typedef struct packed {
    hci_package::hci_streamer_flags_t x_stream_source_flags;
    hci_package::hci_streamer_flags_t w_stream_source_flags;
    hci_package::hci_streamer_flags_t y_stream_source_flags;
    hci_package::hci_streamer_flags_t z_stream_sink_flags;
  } flgs_streamer_t;

  typedef struct packed {
    logic d_shift;
    logic h_shift;
    logic blck_shift;
    logic load;
    logic [$clog2(TOT_DEPTH):0]   cols_lftovr;
    logic [$clog2(ARRAY_WIDTH):0] rows_lftovr;
    logic [$clog2(DEPTH)-1:0]     slots;
  } x_buffer_ctrl_t;

  typedef struct packed {
    logic empty;
    logic full;
  } x_buffer_flgs_t;

  typedef struct packed {
    logic                          shift;
    logic                          load;
    logic [$clog2(TOT_DEPTH):0]    cols_lftovr;
    logic [$clog2(ARRAY_HEIGHT):0] rows_lftovr;
  } w_buffer_ctrl_t;

  typedef struct packed {
    logic [ARRAY_HEIGHT-1:0] empty;
  } w_buffer_flgs_t;

  typedef struct packed {
    logic                         buffer_clk_en;
    logic                         y_push_enable;
    logic                         fill;
    logic                         load;
    logic                         ready;
    logic                         store;
    logic                         y_valid;
    logic [$clog2(TOT_DEPTH):0]   cols_lftovr;
    logic [$clog2(ARRAY_WIDTH):0] rows_lftovr;
  } z_buffer_ctrl_t;

  typedef struct packed {
    logic y_pushed;
    logic empty;
    logic full;
    logic loaded;
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
    logic       [ARRAY_WIDTH-1:0] row_clk_gate_en;
  } cntrl_engine_t;

  typedef struct packed {
    logic                  [ARRAY_WIDTH-1:0][ARRAY_HEIGHT-1:0] in_ready;
    fpnew_pkg::status_t    [ARRAY_WIDTH-1:0][ARRAY_HEIGHT-1:0] status;
    logic                  [ARRAY_WIDTH-1:0][ARRAY_HEIGHT-1:0] extension_bit;
    fpnew_pkg::classmask_e [ARRAY_WIDTH-1:0][ARRAY_HEIGHT-1:0] class_mask;
    logic [ARRAY_WIDTH-1:0][ARRAY_HEIGHT-1:0]                  is_mask;
    logic                  [ARRAY_WIDTH-1:0][ARRAY_HEIGHT-1:0] out_valid;
    logic                  [ARRAY_WIDTH-1:0][ARRAY_HEIGHT-1:0] busy;
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
    logic            y_push_enable;
    logic            x_ready;
    logic            w_ready;
    logic            y_ready;
    logic            z_valid;
    logic            x_full;
    logic            w_loaded;
    logic            w_shift;
    logic            stored;
    logic [STRB-1:0] z_strb;
  } flgs_scheduler_t;

endpackage
