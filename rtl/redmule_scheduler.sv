// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
// Andrea Belano <andrea.belano2@unibo.it>
// Arpan Suravi Prasad<prasadar@iis.ee.ethz.ch>
//

module redmule_scheduler
  import fpnew_pkg::*;
  import hci_package::*;
  import redmule_pkg::*;
  import hwpe_ctrl_package::*;
  import hwpe_stream_package::*;
#(
  parameter  int unsigned Height      = ARRAY_HEIGHT  ,
  parameter  int unsigned Width       = ARRAY_WIDTH   ,
  parameter  int unsigned NumPipeRegs = PIPE_REGS     ,
  parameter  int unsigned GID_WIDTH   = GROUP_ID_WIDTH,
  localparam int unsigned D           = TOT_DEPTH     ,
  localparam int unsigned H           = Height        ,
  localparam int unsigned W           = Width
)(
  /*********************************************************/
  /*                        Inputs                         */
  /*********************************************************/
  input  logic                            clk_i             ,
  input  logic                            rst_ni            ,
  input  logic                            test_mode_i       ,
  input  logic                            clear_i           ,

  input  logic                            x_valid_i         ,
  input  logic                            w_valid_i         ,
  input  logic                            y_valid_i         ,
  input  logic                            z_ready_i         ,

  input  logic                            wq_valid_i        ,
  input  logic                            zeros_valid_i     ,
  input  logic                            next_wrow_valid_i ,

  input  logic                            engine_flush_i    ,

  input  ctrl_regfile_t                   reg_file_i        ,

  input  flgs_streamer_t                  flgs_streamer_i   ,
  input  x_buffer_flgs_t                  flgs_x_buffer_i   ,
  input  w_buffer_flgs_t                  flgs_w_buffer_i   ,
  input  z_buffer_flgs_t                  flgs_z_buffer_i   ,

  input  flgs_engine_t                    flgs_engine_i     ,
  input  cntrl_scheduler_t                cntrl_scheduler_i ,

  /*********************************************************/
  /*                       Outputs                         */
  /*********************************************************/
  output logic                            reg_enable_o       ,
  output cntrl_engine_t                   cntrl_engine_o     ,
  output x_buffer_ctrl_t                  cntrl_x_buffer_o   ,
  output w_buffer_ctrl_t                  cntrl_w_buffer_o   ,
  output z_buffer_ctrl_t                  cntrl_z_buffer_o   ,
  output gidx_buffer_ctrl_t               cntrl_gidx_buffer_o,
  output flgs_scheduler_t                 flgs_scheduler_o
);

  typedef enum logic [1:0] {
    IDLE,
    PRELOAD,
    LOAD_W,
    WAIT
  } redmule_fsm_state_e;

  redmule_fsm_state_e current_state, next_state;

  logic start;

  logic stall_engine,
        first_load,
        start_computation,
        computing,
        x_refill,
        pushing_y;

  /************************
   * X Iteration counters *
   ************************/
  logic [15:0] x_cols_iter_d, x_cols_iter_q,
               x_w_iters_d, x_w_iters_q,
               x_rows_iter_d, x_rows_iter_q;

  logic        x_done;

  logic        x_cols_iter_en, x_w_iters_en, x_rows_iter_en,
               x_done_en;

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_columns_iteration
    if(~rst_ni) begin
      x_cols_iter_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        x_cols_iter_q <= '0;
      end else if (x_cols_iter_en && ~x_done) begin
        x_cols_iter_q <= x_cols_iter_d;
      end
    end
  end

  assign x_cols_iter_en = flgs_x_buffer_i.empty;  //We can do this as the flag is only raised for one cycle
  assign x_cols_iter_d  = x_cols_iter_en ? (x_cols_iter_q == reg_file_i.hwpe_params[X_ITERS][15:0]-1 ? '0 : x_cols_iter_q + 1) : x_cols_iter_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin : weight_iteration_counter
    if(~rst_ni) begin
      x_w_iters_q <= 0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst)
        x_w_iters_q <= '0;
      else if (x_w_iters_en && ~x_done)
        x_w_iters_q <= x_w_iters_d;
    end
  end

  assign x_w_iters_en = x_cols_iter_en && x_cols_iter_q == reg_file_i.hwpe_params[X_ITERS][15:0]-1;
  assign x_w_iters_d  = x_w_iters_en ? (x_w_iters_q == reg_file_i.hwpe_params[W_ITERS][15:0]-1 ? '0 : x_w_iters_q + 1) : x_w_iters_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_rows_iteration
    if(~rst_ni) begin
      x_rows_iter_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        x_rows_iter_q <= '0;
      end else if (x_rows_iter_en && ~x_done) begin
        x_rows_iter_q <= x_rows_iter_d;
      end
    end
  end

  assign x_rows_iter_en = x_w_iters_q == reg_file_i.hwpe_params[W_ITERS][15:0]-1 && x_w_iters_en;
  assign x_rows_iter_d  = x_rows_iter_en ? x_rows_iter_q + 1 : x_rows_iter_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_done_register
    if(~rst_ni) begin
      x_done <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        x_done <= '0;
      end else if (x_done_en) begin
        x_done <= '1;
      end
    end
  end

  assign x_done_en = flgs_streamer_i.x_stream_source_flags.ready_start && x_rows_iter_q == reg_file_i.hwpe_params[X_ITERS][31:16]-1 && x_w_iters_q == reg_file_i.hwpe_params[W_ITERS][15:0]-1 && x_cols_iter_q == reg_file_i.hwpe_params[X_ITERS][15:0]-1;

  assign cntrl_x_buffer_o.height = x_cols_iter_q == reg_file_i.hwpe_params[X_ITERS][15:0]-1 && reg_file_i.hwpe_params[LEFTOVERS][23:16] != '0 ? reg_file_i.hwpe_params[LEFTOVERS][23:16] : D;
  assign cntrl_x_buffer_o.slots  = x_cols_iter_q == reg_file_i.hwpe_params[X_ITERS][15:0]-1 && reg_file_i.hwpe_params[LEFTOVERS][23:16] != '0 ? reg_file_i.hwpe_params[X_SLOTS] : D;
  assign cntrl_x_buffer_o.width  = x_rows_iter_q == reg_file_i.hwpe_params[X_ITERS][31:16]-1 && reg_file_i.hwpe_params[LEFTOVERS][31:24] != '0 ? reg_file_i.hwpe_params[LEFTOVERS][31:24] : W;

  /******************************
   *      X Shift Control       *
   ******************************/
  logic [$clog2(H-1)-1:0] x_shift_cnt_d, x_shift_cnt_q;
  logic                   x_shift_cnt_en;
  logic [$clog2(H-1)-1:0] x_shift_offs_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_shift_counter
    if(~rst_ni) begin
      x_shift_cnt_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst || (flgs_x_buffer_i.full && flgs_x_buffer_i.empty))
        x_shift_cnt_q <= '0;
      else if (x_shift_cnt_en)
        x_shift_cnt_q <= x_shift_cnt_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_shift_offset
    if(~rst_ni) begin
      x_shift_offs_q <= '0;
    end else if (flgs_x_buffer_i.full && flgs_x_buffer_i.empty) begin
      x_shift_offs_q <= x_shift_cnt_q + x_shift_offs_q;
    end
  end

  assign x_shift_cnt_en = (current_state == LOAD_W) && ~stall_engine;
  assign x_shift_cnt_d  = x_shift_cnt_q == H-1 ? '0 : x_shift_cnt_q + 1;

  assign cntrl_x_buffer_o.h_shift = x_shift_cnt_en;

  assign cntrl_x_buffer_o.dequant   = reg_file_i.hwpe_params[DEQUANT_MODE][0];
  assign cntrl_x_buffer_o.q_int_fmt = qint_fmt_e'(reg_file_i.hwpe_params[DEQUANT_MODE][2:1]);

  /******************************
   *     X Reload Control       *
   ******************************/
  logic x_reload_q;
  logic x_reload_en, x_reload_rst;

  logic x_empty;

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_reload_register
    if(~rst_ni) begin
      x_reload_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst || x_reload_rst)
        x_reload_q <= '0;
      else if (x_reload_en)
        x_reload_q <= '1;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_empty_register
    if(~rst_ni) begin
      x_empty <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst || ~flgs_x_buffer_i.full)
        x_empty <= '0;
      else if (flgs_x_buffer_i.full && flgs_x_buffer_i.empty)
        x_empty <= '1;
    end
  end

  assign x_reload_en  = start || x_cols_iter_en || x_empty && ~flgs_x_buffer_i.full;
  assign x_reload_rst = flgs_x_buffer_i.full && ~x_reload_en;

  assign cntrl_x_buffer_o.pad_setup   = current_state == PRELOAD && next_state == LOAD_W;
  assign cntrl_x_buffer_o.load        = (x_reload_q && ~x_reload_rst) && x_valid_i;
  assign cntrl_x_buffer_o.rst_w_index = (current_state == LOAD_W && (x_shift_cnt_q == H-1 || flgs_x_buffer_i.empty)) && flgs_x_buffer_i.full && ~stall_engine;
  assign cntrl_x_buffer_o.last_x      = x_done_en;

  /************************
   * W Iteration counters *
   ************************/
  logic [15:0]        w_cols_iter_d, w_cols_iter_q,
                      w_rows_iter_d, w_rows_iter_q,
                      w_mat_iters_q;

  logic               w_done;

  logic               w_cols_iter_en, w_rows_iter_en,
                      w_mat_iters_en, w_done_en;

  logic [$clog2(H):0] w_zero_cnt_d, w_zero_cnt_q;

  logic        w_stride_cnt;

  always_ff @(posedge clk_i or negedge rst_ni) begin : w_rows_iteration
    if(~rst_ni) begin
      w_rows_iter_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        w_rows_iter_q <= '0;
      end else if (w_rows_iter_en && ~w_done) begin
        w_rows_iter_q <= w_rows_iter_d;
      end
    end
  end

  assign w_rows_iter_en = current_state == LOAD_W && (w_valid_i || reg_file_i.hwpe_params[DEQUANT_MODE][0] && flgs_w_buffer_i.gid_repeated) && ~stall_engine;
  assign w_rows_iter_d  = w_rows_iter_q == reg_file_i.hwpe_params[W_ITERS][31:16]-1 ? '0 : w_rows_iter_q + 1;

  always_ff @(posedge clk_i or negedge rst_ni) begin : w_columns_iteration
    if(~rst_ni) begin
      w_cols_iter_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        w_cols_iter_q <= '0;
      end else if (w_cols_iter_en && ~w_done) begin
        w_cols_iter_q <= w_cols_iter_d;
      end
    end
  end

  assign w_cols_iter_en = w_rows_iter_q == reg_file_i.hwpe_params[W_ITERS][31:16]-1 && w_rows_iter_en;
  assign w_cols_iter_d  = w_cols_iter_q == reg_file_i.hwpe_params[W_ITERS][15:0]-1 ? '0 : w_cols_iter_q + 1;

  always_ff @(posedge clk_i or negedge rst_ni) begin : w_matrix_iterations
    if(~rst_ni) begin
      w_mat_iters_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        w_mat_iters_q <= '0;
      end else if (w_mat_iters_en && ~w_done) begin
        w_mat_iters_q <= w_mat_iters_q + 1;
      end
    end
  end

  assign w_mat_iters_en = w_cols_iter_q == reg_file_i.hwpe_params[W_ITERS][15:0]-1 && w_cols_iter_en;

  always_ff @(posedge clk_i or negedge rst_ni) begin : w_done_register
    if(~rst_ni) begin
      w_done <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        w_done <= '0;
      end else if (w_done_en) begin
        w_done <= '1;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : w_zero_counter
    if (~rst_ni) begin
      w_zero_cnt_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        w_zero_cnt_q <= '0;
      end else begin
        w_zero_cnt_q <= w_zero_cnt_d;
      end
    end
  end

  assign w_zero_cnt_d = w_done && current_state == LOAD_W && ~stall_engine && w_zero_cnt_q != H ? w_zero_cnt_q + 1 : w_zero_cnt_q;

  assign w_done_en = w_mat_iters_en && w_mat_iters_q == reg_file_i.hwpe_params[X_ITERS][31:16]-1;

  assign cntrl_w_buffer_o.height = w_rows_iter_q >= reg_file_i.hwpe_params[W_ITERS][31:16]-(PIPE_REGS+1) && reg_file_i.hwpe_params[LEFTOVERS][15:8] != '0 ? reg_file_i.hwpe_params[LEFTOVERS][15:8] : H;
  assign cntrl_w_buffer_o.width  = w_cols_iter_q == reg_file_i.hwpe_params[W_ITERS][15:0]-1 && reg_file_i.hwpe_params[LEFTOVERS][7:0] != '0 ? reg_file_i.hwpe_params[LEFTOVERS][7:0] : D;

  assign cntrl_w_buffer_o.load  = current_state == LOAD_W && ~stall_engine && ~w_done;
  assign cntrl_w_buffer_o.shift = (current_state == LOAD_W || current_state == WAIT) && ~stall_engine;

  assign cntrl_w_buffer_o.dequant   = reg_file_i.hwpe_params[DEQUANT_MODE][0];
  assign cntrl_w_buffer_o.q_int_fmt = qint_fmt_e'(reg_file_i.hwpe_params[DEQUANT_MODE][2:1]);

  always_comb begin
    cntrl_w_buffer_o.zero_set = '0;

    for (int unsigned i = 0; i < H; i++) begin
      if (w_done && w_zero_cnt_q > i) begin
        cntrl_w_buffer_o.zero_set[i] = 1'b1;
      end
    end
  end

  /****************************
   * Y & Z Iteration counters *
   ****************************/
  logic [15:0]                    y_cols_iter_d, y_cols_iter_q,
                                  y_rows_iter_d, y_rows_iter_q;

  logic                           y_cols_iter_en, y_rows_iter_en;

  logic [$clog2(PIPE_REGS+1)-1:0] z_wait_counter_d, z_wait_counter_q;
  logic [$clog2(D)-1:0]           z_avail_counter_d, z_avail_counter_q,
                                  y_push_counter_d, y_push_counter_q;

  logic                           z_wait_en, z_wait_clr,
                                  z_avail_en, z_avail_clr,
                                  y_push_en, y_push_clr;

  logic [$clog2(W):0]             y_width, z_width;
  logic [$clog2(D):0]             y_height, z_height;

  always_ff @(posedge clk_i or negedge rst_ni) begin : y_columns_iteration
    if(~rst_ni) begin
      y_cols_iter_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        y_cols_iter_q <= '0;
      end else if (y_cols_iter_en) begin
        y_cols_iter_q <= y_cols_iter_d;
      end
    end
  end

  assign y_cols_iter_en = flgs_z_buffer_i.empty;
  assign y_cols_iter_d  = y_cols_iter_q == reg_file_i.hwpe_params[W_ITERS][15:0]-1 ? '0 : y_cols_iter_q + 1;

  always_ff @(posedge clk_i or negedge rst_ni) begin : y_rows_iteration
    if(~rst_ni) begin
      y_rows_iter_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        y_rows_iter_q <= '0;
      end else if (y_rows_iter_en) begin
        y_rows_iter_q <= y_rows_iter_d;
      end
    end
  end

  assign y_rows_iter_en = y_cols_iter_q == reg_file_i.hwpe_params[W_ITERS][15:0]-1 && y_cols_iter_en;
  assign y_rows_iter_d  =  y_rows_iter_q == reg_file_i.hwpe_params[W_ITERS][31:16]-1 ? '0 : y_rows_iter_q + 1;

  always_ff @(posedge clk_i or negedge rst_ni) begin : z_wait_enable_register
    if(~rst_ni) begin
      z_wait_en <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst || z_wait_clr) begin
        z_wait_en <= '0;
      end else if (w_cols_iter_en) begin
        z_wait_en <= '1;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : z_wait_counter
    if(~rst_ni) begin
      z_wait_counter_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        z_wait_counter_q <= '0;
      end else if (z_wait_en && ~stall_engine) begin
        z_wait_counter_q <= z_wait_counter_d;
      end
    end
  end

  assign z_wait_counter_d = z_wait_counter_q == PIPE_REGS ? '0 : z_wait_counter_q + 1;
  assign z_wait_clr       = z_wait_en && ~stall_engine && z_wait_counter_q == PIPE_REGS;

  always_ff @(posedge clk_i or negedge rst_ni) begin : z_avail_enable_register
    if(~rst_ni) begin
      z_avail_en <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst || z_avail_clr) begin
        z_avail_en <= '0;
      end else if (z_wait_clr) begin
        z_avail_en <= '1;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : z_availability_counter
    if(~rst_ni) begin
      z_avail_counter_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        z_avail_counter_q <= '0;
      end else if (z_avail_en && ~stall_engine) begin
        z_avail_counter_q <= z_avail_counter_d;
      end
    end
  end

  assign z_avail_counter_d = z_avail_counter_q == z_height-1 ? '0 : z_avail_counter_q + 1;
  assign z_avail_clr       = z_avail_en && ~stall_engine && z_avail_counter_q == z_height-1;

  always_ff @(posedge clk_i or negedge rst_ni) begin : y_push_enable_register
    if(~rst_ni) begin
      y_push_en <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst || y_push_clr) begin
        y_push_en <= '0;
      end else if (z_wait_en && ~stall_engine && z_wait_counter_q == PIPE_REGS-1 || start_computation) begin
        y_push_en <= '1;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : y_push_counter
    if(~rst_ni) begin
      y_push_counter_q <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        y_push_counter_q <= '0;
      end else if (y_push_en && ~stall_engine) begin
        y_push_counter_q <= y_push_counter_d;
      end
    end
  end

  assign y_push_counter_d = y_push_counter_q == y_height-1 ? '0 : y_push_counter_q + 1;
  assign y_push_clr       = y_push_en && ~stall_engine && y_push_counter_q == y_height-1;

  assign y_width  = y_rows_iter_q == reg_file_i.hwpe_params[W_ITERS][31:16]-1 && reg_file_i.hwpe_params[LEFTOVERS][15:8] != '0 ? reg_file_i.hwpe_params[LEFTOVERS][15:8] : W;
  assign y_height = y_cols_iter_q == reg_file_i.hwpe_params[W_ITERS][15:0]-1 && reg_file_i.hwpe_params[LEFTOVERS][7:0] != '0 ? reg_file_i.hwpe_params[LEFTOVERS][7:0] : D;

  always_ff @(posedge clk_i or negedge rst_ni) begin : z_width_register
    if(~rst_ni) begin
      z_width <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        z_width <= '0;
      end else if (flgs_z_buffer_i.empty || start_computation) begin
        z_width <= y_width;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : z_height_register
    if(~rst_ni) begin
      z_height <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        z_height <= '0;
      end else if (flgs_z_buffer_i.empty || start_computation) begin
        z_height <= y_height;
      end
    end
  end

  assign cntrl_z_buffer_o.ready         = z_ready_i;
  assign cntrl_z_buffer_o.y_valid       = y_valid_i;
  assign cntrl_z_buffer_o.y_push_enable = y_push_en && ~stall_engine;
  assign cntrl_z_buffer_o.fill          = z_avail_en && reg_enable_o;
  assign cntrl_z_buffer_o.first_load    = y_cols_iter_q == '0 && y_rows_iter_q == '0;

  assign cntrl_z_buffer_o.y_width       = y_width;
  assign cntrl_z_buffer_o.y_height      = y_height;
  assign cntrl_z_buffer_o.z_width       = z_width;
  assign cntrl_z_buffer_o.z_height      = z_height;

  assign cntrl_gidx_buffer_o.num_w_iters = reg_file_i.hwpe_params[X_ITERS][15:0];


  /**********************************
   *           Counters             *
   **********************************/

  logic [$clog2(NumPipeRegs+1)-1:0] waits_cnt;
  logic                             waits_cnt_en;

  always_ff @(posedge clk_i or negedge rst_ni) begin : waits_counter
    if(~rst_ni) begin
      waits_cnt <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst)
        waits_cnt <= '0;
      else if (waits_cnt_en)
        waits_cnt <= waits_cnt == NumPipeRegs ? '0 : waits_cnt + 1;
    end
  end

  assign waits_cnt_en = ~stall_engine && current_state != IDLE && current_state != PRELOAD;

  /*****************************
   *       ENGINE CONTROL      *
   *****************************/

  logic reg_enable_d, reg_enable_q;

  assign reg_enable_d = computing & ~stall_engine;

  always_ff @(posedge clk_i or negedge rst_ni) begin : reg_enable_register
    if (~rst_ni) begin
      reg_enable_q <= '0;
    end else begin
      if (clear_i) begin
        reg_enable_q <= '0;
      end else begin
        reg_enable_q <= reg_enable_d;
      end
    end
  end

  assign reg_enable_o = reg_enable_q;

  assign cntrl_engine_o.fma_is_boxed     = 3'b111;
  assign cntrl_engine_o.noncomp_is_boxed = 2'b11;
  assign cntrl_engine_o.stage1_rnd       = fpnew_pkg::roundmode_e'(reg_file_i.hwpe_params[OP_SELECTION][31:29]);
  assign cntrl_engine_o.stage2_rnd       = fpnew_pkg::roundmode_e'(reg_file_i.hwpe_params[OP_SELECTION][28:26]);
  assign cntrl_engine_o.op1              = fpnew_pkg::operation_e'(reg_file_i.hwpe_params[OP_SELECTION][25:21]);
  assign cntrl_engine_o.op2              = fpnew_pkg::operation_e'(reg_file_i.hwpe_params[OP_SELECTION][20:16]);
  assign cntrl_engine_o.op_mod           = 1'b0;
  assign cntrl_engine_o.in_valid         = 1'b1;
  assign cntrl_engine_o.flush            = engine_flush_i;
  assign cntrl_engine_o.out_ready        = 1'b1;
  assign cntrl_engine_o.dequant_enable   = reg_file_i.hwpe_params[DEQUANT_MODE][0];
  assign cntrl_engine_o.accumulate       = ~pushing_y;

  logic [W-1:0] row_clk_en_d, row_clk_en_q;

  always_comb begin
    row_clk_en_d = '0;

    if (computing && ~stall_engine) begin
      for (int i = 0; i < z_width; i++) begin
        row_clk_en_d[i] = 1'b1;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : row_clk_en_register
    if (~rst_ni) begin
      row_clk_en_q <= '0;
    end else begin
      if (clear_i) begin
        row_clk_en_q <= '0;
      end else begin
        row_clk_en_q <= row_clk_en_d;
      end
    end
  end

  assign cntrl_engine_o.row_clk_gate_en = row_clk_en_q;

  /*****************************
   *         CHECKS            *
   *****************************/

  // During the LOAD_W state we perform a series of checks to determine if the
  // computation can proceed or we have to stall the accelerator

  logic check_w_valid, check_w_valid_en;
  logic check_x_full, check_x_full_en;
  logic check_y_loaded, check_y_loaded_en;

  logic check_quant_valid, check_quant_valid_en;

  // Check if the next w row is valid
  assign check_w_valid     = w_valid_i || (flgs_w_buffer_i.gid_repeated && reg_file_i.hwpe_params[DEQUANT_MODE][0]);
  assign check_w_valid_en  = ~w_done;

  // Check if the x buffer is full
  // Only enable this check when a new set of x columns is to be loaded
  // This check is performed one cycle in earlier (i.e. during the WAIT state) as the X buffer takes one cycle after the full signal is asserted to actually update the outputs
  assign check_x_full      = flgs_x_buffer_i.full;
  assign check_x_full_en   = x_refill && x_shift_cnt_q == (H-1 - x_shift_offs_q) && ~x_done;

  // Check if the new Y rows are loaded and ready to be pushed
  // Only enable this check when the results of an iteration are available
  assign check_y_loaded    = flgs_z_buffer_i.loaded;
  assign check_y_loaded_en = z_wait_counter_q == PIPE_REGS && ~w_done;

  assign check_quant_valid = (zeros_valid_i || flgs_w_buffer_i.gid_repeated) && wq_valid_i && (next_wrow_valid_i || current_state != LOAD_W || x_done_en);
  assign check_quant_valid_en = ~w_done && reg_file_i.hwpe_params[DEQUANT_MODE][0];

  /******************************
   *           FLAGS            *
   ******************************/
  assign stall_engine = current_state == LOAD_W && (
                          ~check_w_valid     && check_w_valid_en     ||
                          ~check_y_loaded    && check_y_loaded_en    ||
                          ~check_quant_valid && check_quant_valid_en
                        ) || z_wait_counter_q == PIPE_REGS && flgs_z_buffer_i.z_priority
                          || current_state == WAIT && ~check_x_full && check_x_full_en;

  always_ff @(posedge clk_i or negedge rst_ni) begin : first_load_register
    if(~rst_ni) begin
      first_load <= '1;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        first_load <= '1;
      end else if (current_state == LOAD_W && ~stall_engine) begin
        first_load <= '0;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : computing_flag_register
    if(~rst_ni) begin
      computing <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        computing <= '0;
      end else if (current_state == PRELOAD && next_state == LOAD_W) begin
        computing <= '1;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : x_refill_register
    if(~rst_ni) begin
      x_refill <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        x_refill <= '0;
      end else if (flgs_x_buffer_i.empty) begin
        x_refill <= '1;
      end else if (cntrl_x_buffer_o.rst_w_index) begin
        x_refill <= '0;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : pushing_y_register
    if(~rst_ni) begin
      pushing_y <= '0;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst) begin
        pushing_y <= '0;
      end else begin
        pushing_y <= y_push_en;
      end
    end
  end

  assign start             = current_state == IDLE && cntrl_scheduler_i.first_load;

  assign flgs_scheduler_o.w_loaded = current_state == LOAD_W && ~stall_engine;
  assign start_computation = first_load && next_state == LOAD_W && ~stall_engine;

  /*********************************
   *            FSM                *
   *********************************/

  always_ff @(posedge clk_i or negedge rst_ni) begin : state_register
    if(~rst_ni) begin
      current_state <= IDLE;
    end else begin
      if (clear_i || cntrl_scheduler_i.rst)
        current_state <= IDLE;
      else
        current_state <= next_state;
    end
  end

  always_comb begin : fsm
    next_state = current_state;

    case (current_state)
      IDLE: begin
        if (cntrl_scheduler_i.first_load) begin
          next_state = PRELOAD;
        end
      end
    // Wait for the X and Y buffers to be full
    PRELOAD: begin
      if (reg_file_i.hwpe_params[OP_SELECTION][0]) begin
        if (flgs_x_buffer_i.full && flgs_z_buffer_i.loaded) begin
          next_state = LOAD_W;
        end
      end else begin // The Y matrix is not required
        if (flgs_x_buffer_i.full) begin
          next_state = LOAD_W;
        end
      end
    end

      // in this state we should check that everything is ready to be loaded and
      // if something's amiss stall the engine
      LOAD_W: begin
        if (w_done && z_avail_clr) begin
          next_state = IDLE;
        end else if (~stall_engine) begin
          next_state = WAIT;
        end
      end

      WAIT: begin
        if (waits_cnt == NumPipeRegs && ~stall_engine) begin
          next_state = LOAD_W;
        end
      end
    endcase
  end

endmodule : redmule_scheduler
