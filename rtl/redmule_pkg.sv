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

  parameter int unsigned            DATA_W       = 256; // TCDM port dimension (in bits)
  parameter int unsigned            MemDw        = 32;
  parameter int unsigned            NumByte      = MemDw/8;
  parameter int unsigned            ADDR_W       = hci_package::DEFAULT_AW;
  parameter int unsigned            DATAW        = DATA_W;
  parameter int unsigned            REDMULE_REGS = 27;
  parameter int unsigned            N_CONTEXT    = 2;
  parameter fpnew_pkg::fp_format_e  FPFORMAT     = fpnew_pkg::FP16;
  parameter int unsigned            BITW         = fpnew_pkg::fp_width(FPFORMAT);
  parameter int unsigned            ARRAY_HEIGHT = 8;
  parameter int unsigned            PIPE_REGS    = 1;
  parameter int unsigned            ARRAY_WIDTH  = ARRAY_HEIGHT*PIPE_REGS; // Superior limit, smaller values are allowed.
  parameter int unsigned            TOT_DEPTH    = DATAW/BITW;
  parameter int unsigned            DEPTH        = TOT_DEPTH/ARRAY_HEIGHT;
  parameter int unsigned            STRB         = DATA_W/8;
  parameter fpnew_pkg::fmt_logic_t  FpFmtConfig  = 6'b001101;
  parameter fpnew_pkg::ifmt_logic_t IntFmtConfig = 4'b1000;
  parameter fpnew_pkg::operation_e  CAST_OP      = fpnew_pkg::F2F;
  parameter int unsigned MIN_FMT                 = fpnew_pkg::min_fp_width(FpFmtConfig);
  parameter int unsigned DW_CUT                  = DATA_W - ARRAY_HEIGHT*(PIPE_REGS + 1)*MIN_FMT;
  parameter int unsigned ECC_CHUNK_SIZE          = 32;
  parameter int unsigned ECC_N_CHUNK             = DATA_W / ECC_CHUNK_SIZE;
  parameter int unsigned LATCH_BUFFERS           = 0;

  // Register File mapping
  /**********************
  ** Slave RF indexing **
  **********************/
  parameter int unsigned X_ADDR = 0; // 0x00 /* These do not change between slave and final */
  parameter int unsigned W_ADDR = 1; // 0x04 /* These do not change between slave and final */
  parameter int unsigned Z_ADDR = 2; // 0x08 /* These do not change between slave and final */
  parameter int unsigned MCFIG0 = 3; // 0x0C --> [31:16] -> K size, [15: 0] -> M size
  parameter int unsigned MCFIG1 = 4; // 0x10 --> [31: 0] -> N Size
  // Matrix arithmetic config register
  // [20:20] -> Send X stream
  // [19:19] -> Receive X stream
  // [18:18] -> Send W stream
  // [17:17] -> Receive W stream
  // [16:16] -> Reduction initialization
  // [15:14] -> Reduction operation
  // [13:13] -> PACE mode selection
  // [12:10] -> Operation selection
  // [ 9: 7] -> Input/Output format
  parameter int unsigned MACFG = 5; // 0x14
  // Reduction initialization values addr
  parameter int unsigned R_ADDR_R = 6; // 0x18
  /**********************
  ** Final RF indexing **
  **********************/
  // Number of iterations on X and W matrices
  // (15 bits for number of rows iterations, 15 bits for number of columns iterations)
  parameter int unsigned X_ITERS   = 3; // 0x0C --> [31:16] -> ROWS ITERATIONS, [15:0] -> COLUMNS ITERATIONS
  parameter int unsigned W_ITERS   = 4; // 0x10 --> [31:16] -> ROWS ITERATIONS, [15:0] -> COLUMNS ITERATIONS
  // Number of rows and columns leftovers (8 bits for each)
  // [31:24] -> X/Y ROWS LEFTOVERS
  // [23:16] -> X COLUMNS LEFTOVERS
  // [15:8]  -> W ROWS LEFTOVERS
  // [7:0]   -> W/Y COLUMNS LEFTOVERS
  parameter int unsigned LEFTOVERS = 5; // 0x14
  // We keep a register for the remaining params
  // [31:16] -> TOT_NUMBER_OF_STORES
  // [14]    -> 1'b0: X cols/W rows >= ARRAY_HEIGHT; 1'b1: X cols/W rows < ARRAY_HEIGHT
  // [13]    -> 1'b0: W cols >= TILE ( TILE = (PIPE_REGS + 1)*ARRAY_HEIGHT ); 1'b1: W cols < TILE ( TILE = (PIPE_REGS + 1)*ARRAY_HEIGHT )
  parameter int unsigned LEFT_PARAMS = 6;  // 0x18
  parameter int unsigned X_D1_STRIDE = 7;  // 0x1C
  parameter int unsigned W_TOT_LEN   = 8;  // 0x20
  parameter int unsigned TOT_X_READ  = 9;  // 0x24
  parameter int unsigned W_D0_STRIDE = 10; // 0x28
  parameter int unsigned Z_TOT_LEN   = 11; // 0x2C
  parameter int unsigned Z_D0_STRIDE = 12; // 0x30
  parameter int unsigned Z_D2_STRIDE = 13; // 0x34
  parameter int unsigned X_ROWS_OFFS = 14; // 0x38
  parameter int unsigned X_SLOTS     = 15; // 0x3C
  parameter int unsigned IN_TOT_LEN  = 16; // 0x40

  // One register is used for the round modes and operations of the Computing Elements.
  // [31:29] -> roundmode of the stage 1
  // [28:26] -> roundmode of the stage 2
  // [25:21] -> operation of the stage 1
  // [20:16] -> operation of the stage 2
  // [15:13] -> input/output format
  // [12:10] -> computing format
  // [1:1]   -> pace mode
  // [0:0]   -> GEMM selection
  parameter int unsigned OP_SELECTION = 17; // 0x44

  parameter int unsigned M_SIZE      = 18; // 0x48
  parameter int unsigned N_SIZE      = 19; // 0x4C
  parameter int unsigned K_SIZE      = 20; // 0x50
  parameter int unsigned R_ADDR      = 21; // 0x54

  // [2:1]   -> reduction operation
  // [0:0]   -> init enable
  parameter int unsigned R_CONF      = 22; // 0x58

  // X/W Streams configuration
  // [3:3]   -> Send X
  // [2:2]   -> Receive X
  // [1:1]   -> Send W
  // [0:0]   -> Receive W
  parameter int unsigned STREAM_CONF = 23; // 0x5C

  `ifdef PACE_ENABLED
    parameter int unsigned PACE_IN_ADDR   = 24; // 0x60
    parameter int unsigned PACE_OUT_ADDR  = 25; // 0x68
    parameter int unsigned PACE_D0_LENGTH = 26; // 0x6C
  `endif

  parameter bit[6:0] MCNFIG = 7'b0001011; // 0x0B
  parameter bit[6:0] MARITH = 7'b0101011; // 0x2B
  parameter bit[6:0] RVCSR  = 7'b1110011; // 0x73 -> RISC-V CSR instruction opcode

  /* The CSRs below are not really present in the current RedMulE version. The following
     enum is here to allow future development where it might be useful to write the
     configuration registers through standard `csrw` instructions coming from the core.
     The CSRs values are chosen following the custom read/write already available in the
     RISC-V specifications. */
  typedef enum logic[11:0] {
    CSR_REDMULE_X_ADDR = 12'h800,
    CSR_REDMULE_W_ADDR = 12'h801,
    CSR_REDMULE_Z_ADDR = 12'h802,
    CSR_REDMULE_MCFIG0 = 12'h803,
    CSR_REDMULE_MCFIG1 = 12'h804,
`ifdef PACE_ENABLED
    CSR_REDMULE_MACFG  = 12'h805,
    CSR_PACE_INP_ADDR  = 12'h806,
    CSR_PACE_OUP_ADDR  = 12'h807
`else
    CSR_REDMULE_MACFG  = 12'h805
`endif
  } redmule_csr_num_e;

`ifdef PACE_ENABLED
  parameter int unsigned NumStreamSources     = 5; // X, W, Y, R, PACE_IN
  parameter int unsigned PACEsourceStreamId   = 4;
`else
  parameter int unsigned NumStreamSources     = 4; // X, W, Y, R
`endif

  parameter int unsigned XsourceStreamId      = 0;
  parameter int unsigned WsourceStreamId      = 1;
  parameter int unsigned YsourceStreamId      = 2;
  parameter int unsigned RsourceStreamId      = 3;

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
    logic                                   pace_mode;
    logic                                   receive_w_stream;
    logic                                   receive_x_stream;
`ifdef PACE_ENABLED
    hci_package::hci_streamer_ctrl_t        pace_stream_source_ctrl;
    hci_package::hci_streamer_ctrl_t        pace_stream_sink_ctrl;
`endif
  } cntrl_streamer_t;

  typedef struct packed {
    hci_package::hci_streamer_flags_t x_stream_source_flags;
    hci_package::hci_streamer_flags_t w_stream_source_flags;
    hci_package::hci_streamer_flags_t y_stream_source_flags;
    hci_package::hci_streamer_flags_t r_stream_source_flags;
    hci_package::hci_streamer_flags_t z_stream_sink_flags;
    hci_package::hci_streamer_flags_t r_stream_sink_flags;
`ifdef PACE_ENABLED
    hci_package::hci_streamer_flags_t pace_stream_source_flags;
    hci_package::hci_streamer_flags_t pace_stream_sink_flags;
`endif
  } flgs_streamer_t;

  typedef struct packed {
    logic                         h_shift;
    logic                         load;
    logic                         pad_setup;
    logic [$clog2(ARRAY_WIDTH):0] width;
    logic [$clog2(TOT_DEPTH):0]   height;
    logic [$clog2(TOT_DEPTH):0]   slots;
`ifdef PACE_ENABLED
    logic                         pace_mode;
`endif

    logic                         rst_w_index;
    logic                         last_x;
  } x_buffer_ctrl_t;

  typedef struct packed {
    logic empty;
    logic full;
  } x_buffer_flgs_t;

  typedef struct packed {
    logic                          shift;
    logic                          load;
    logic [$clog2(TOT_DEPTH):0]    width;
    logic [$clog2(ARRAY_HEIGHT):0] height;
    logic [ARRAY_HEIGHT-1:0]       zero_set;
  } w_buffer_ctrl_t;

  typedef struct packed {
    logic [ARRAY_HEIGHT-1:0] empty;
    logic                    w_ready;
  } w_buffer_flgs_t;

  typedef struct packed {
    logic                         y_push_enable;
    logic                         fill;
    logic                         ready;
    logic                         y_valid;
    logic                         first_load;
    logic [$clog2(ARRAY_WIDTH):0] y_width;
    logic [$clog2(TOT_DEPTH):0]   y_height;
    logic [$clog2(ARRAY_WIDTH):0] z_width;
    logic [$clog2(TOT_DEPTH):0]   z_height;
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
`ifdef PACE_ENABLED
    logic                         pace_mode;
`endif
    logic                         op_mod;
    logic                         in_valid;
    logic                         flush;
    logic                         out_ready;
    logic                         accumulate;
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

  typedef struct packed {
    logic idle;
  } cntrl_flags_t;

  typedef enum logic [1:0] { RED_NONE, MAX, SUM } red_op_t;

  typedef struct packed {
    logic [15:0]  row_len;
    red_op_t      op;
    logic         load;
    logic         enable;
    logic         ready;
  } cntrl_red_t;


  typedef struct packed {
    logic is_initialized;
  } flgs_red_t;

  typedef enum logic [2:0] { MATMUL=3'h0, GEMM=3'h1, ADDMAX=3'h2, ADDMIN=3'h3, MULMAX=3'h4, MULMIN=3'h5, MAXMIN=3'h6, MINMAX=3'h7 } gemm_op_e;
  typedef enum logic [1:0] { Float8=2'h0, Float16=2'h1, Float8Alt=2'h2, Float16Alt=2'h3 } gemm_fmt_e;
  typedef enum logic       { RNE=1'h0, RTZ=1'h1 } rnd_mode_e;
  typedef enum logic [2:0] { FPU_FMADD=3'h0, FPU_ADD=3'h2, FPU_MUL=3'h3, FPU_MINMAX=3'h7 }    fpu_op_e;
  typedef enum logic [2:0] { FPU_FP16=3'h2, FPU_FP8=3'h3, FPU_FP16ALT=3'h4, FPU_FP8ALT=3'h5 } fpu_fmt_e;

  typedef struct packed {
    logic [31:0] x_addr;
    logic [31:0] w_addr;
    logic [31:0] z_addr;
`ifdef PACE_ENABLED
    logic [31:0] pace_in_addr;
    logic [31:0] pace_out_addr;
`endif
    logic [15:0] m_size;
    logic [15:0] n_size;
    logic [15:0] k_size;
    gemm_op_e gemm_ops;
`ifdef PACE_ENABLED
    logic     pace_mode;
`endif
    gemm_fmt_e gemm_input_fmt;
    gemm_fmt_e gemm_output_fmt;

    logic [15:0] x_cols_iter;
    logic [15:0] x_rows_iter;
    logic [15:0] w_cols_iter;
    logic [15:0] w_rows_iter;
`ifdef PACE_ENABLED
    logic [15:0] pace_iter;
`endif
    logic [ 7:0] x_cols_lftovr;
    logic [ 7:0] x_rows_lftovr;
    logic [ 7:0] w_cols_lftovr;
    logic [ 7:0] w_rows_lftovr;
`ifdef PACE_ENABLED
    logic [15:0] pace_lftovr;
`endif
    logic [15:0] tot_stores;
    logic [31:0] x_d1_stride;
    logic [31:0] w_tot_len;
    logic [31:0] tot_x_read;
    logic [31:0] w_d0_stride;
    logic [31:0] yz_tot_len;
    logic [31:0] yz_d0_stride;
    logic [31:0] yz_d2_stride;
`ifdef PACE_ENABLED
    logic [15:0] pace_tot_len;
`endif
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
    logic [31:0] r_addr;
    logic        red_init;
    red_op_t     red_op;
    logic        send_w;
    logic        receive_w;
    logic        send_x;
    logic        receive_x;
  } redmule_config_t;

  typedef enum {
    CV32P ,
    CV32X ,
    Ibex  ,
    CVA6
  } core_type_e;

  // Default buses
  localparam int unsigned ID = 10;
  typedef struct packed {
    logic        req;
    logic [31:0] addr;
  } core_default_inst_req_t;

  typedef struct packed {
    logic        gnt;
    logic        valid;
    logic [31:0] data;
  } core_default_inst_rsp_t;

  typedef struct packed {
    logic req;
    logic we;
    logic [3:0] be;
    logic [31:0] addr;
    logic [31:0] data;
  } core_default_data_req_t;

  typedef struct packed {
    logic gnt;
    logic valid;
    logic [31:0] data;
  } core_default_data_rsp_t;

  typedef struct packed {
    logic req;
    logic wen;
    logic [DATA_W/8-1:0] be;
    logic signed [DATA_W/32-1:0][31:0]boffs;
    logic [31:0] add;
    logic [DATA_W-1:0] data;
    logic lrdy;
    logic user;
  } redmule_default_data_req_t;

  typedef struct packed {
    logic gnt;
    logic r_valid;
    logic [DATA_W-1:0] r_data;
    logic r_opc;
    logic r_user;
  } redmule_default_data_rsp_t;

`ifdef PACE_ENABLED
  localparam int unsigned PACE_NPARTS = 8; // same as the height of the Redmule array or the number of rows in RedMule. It must be power of 2
  localparam int unsigned PACE_PART_BST_STAGES = $clog2(PACE_NPARTS);
  localparam int unsigned PIDW = PACE_PART_BST_STAGES;// Part ID width
  localparam int unsigned PACE_NPOLY = 4; // Redmule Width - PACE_PART_BST_STAGES
`endif

endpackage
