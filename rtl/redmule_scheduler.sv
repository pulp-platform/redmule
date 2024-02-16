// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
//

module redmule_scheduler
  import fpnew_pkg::*;
  import hci_package::*;
  import redmule_pkg::*;
  import hwpe_ctrl_package::*;
  import hwpe_stream_package::*;
#(
  parameter  int unsigned Height      = ARRAY_HEIGHT,
  parameter  int unsigned Width       = ARRAY_WIDTH ,
  parameter  int unsigned NumPipeRegs = PIPE_REGS   ,
  localparam int unsigned D           = TOT_DEPTH   ,
  localparam int unsigned H           = Height      ,
  localparam int unsigned W           = Width
)(
  /********************************************************/
  /*                        Inputs                        */
  /********************************************************/
  input  logic                            clk_i            ,
  input  logic                            rst_ni           ,
  input  logic                            test_mode_i      ,
  input  logic                            clear_i          ,
  input  logic                            x_valid_i        ,
  input  logic            [(DATAW/8)-1:0] x_strb_i         ,
  input  logic                            w_valid_i        ,
  input  logic            [(DATAW/8)-1:0] w_strb_i         ,
  input  logic                            y_fifo_valid_i   ,
  input  logic            [(DATAW/8)-1:0] y_fifo_strb_i    ,
  input  logic                            z_ready_i        ,
  input  logic                            accumulate_i     ,
  input  logic                            engine_flush_i   ,
  input  ctrl_regfile_t                   reg_file_i       ,
  input  flgs_streamer_t                  flgs_streamer_i  ,
  input  x_buffer_flgs_t                  flgs_x_buffer_i  ,
  input  w_buffer_flgs_t                  flgs_w_buffer_i  ,
  input  z_buffer_flgs_t                  flgs_z_buffer_i  ,
  input  flgs_engine_t                    flgs_engine_i    ,
  input  flags_fifo_t                     fifo_flgs_i      ,
  input  cntrl_scheduler_t                cntrl_scheduler_i,
  /********************************************************/
  /*                       Outputs                        */
  /********************************************************/
  output logic            [(DATAW/8)-1:0] z_strb_o         ,
  output logic                            soft_clear_o     ,
  output logic                            w_load_o         ,
  output logic            [$clog2(D):0]   w_cols_lftovr_o  ,
  output logic            [$clog2(H):0]   w_rows_lftovr_o  ,
  output logic            [$clog2(D):0]   y_cols_lftovr_o  ,
  output logic            [$clog2(W):0]   y_rows_lftovr_o  ,
  output logic                            gate_en_o        ,
  output logic                            x_buffer_clk_en_o,
  output logic                            z_buffer_clk_en_o,
  output logic                            reg_enable_o     ,
  output logic                            z_store_o        ,
  output logic                            y_buffer_load_o  ,
  output cntrl_engine_t                   cntrl_engine_o   ,
  output cntrl_streamer_t                 cntrl_streamer_o ,
  output x_buffer_ctrl_t                  cntrl_x_buffer_o ,
  output flgs_scheduler_t                 flgs_scheduler_o
);

logic clear_regs;
logic loading_x_q,
      loading_y_q,
      load_x_en,
      load_y_en,
      hold_q,
      hold_en,
      y_push_en;
logic y_loaded_q;
logic h_shift_rst,
      wait_rst,
      load_x_rst,
      load_y_rst,
      transfer_rst,
      hold_rst,
      x_rows_rst,
      x_cols_rst,
      y_push_rst;
logic consume_y_q,
      consume_y_en,
      consume_y_rst;
logic x_preloaded_q,
      x_preloaded_en,
      x_preloaded_rst;
logic count_w_cycles_q,
      count_w_cycles_en,
      count_w_cycles_rst;
logic y_preloaded_q,
      y_preloaded_en,
      y_preloaded_rst;
logic last_store,
      last_store_en,
      last_store_rst;
logic store_cols_lftovr_q,
      store_cols_lftovr_en,
      store_cols_lftovr_rst;
logic store_rows_lftovr_en,
      store_rows_lftovr_rst;
logic gate, gate_en, gate_rst, gate_comb;
logic shift_lock_q,
      shift_lock_en,
      shift_lock_rst;
logic reg_enable,
      shift_count_en;
logic w_loaded;
logic x_rows_lftovr_en, x_rows_lftovr_rst, x_rows_clk_gate_en,
      y_cols_lftovr_en, y_cols_lftovr_rst,
      y_rows_lftovr_en, y_rows_lftovr_rst;
logic y_push_q;
logic skip_w_q, skip_w_en,
      skip_w_rst;
logic reg_disable, shift_disable;
logic [$clog2(NumPipeRegs):0] skipped_w_q;
logic [$clog2(W)-1:0] x_rows_lftovr_q,
                      y_rows_lftovr_q,
                      store_rows_lftovr_q;
logic [255:0]         n_waits_d, n_waits_q;
logic [$clog2(W):0] tot_x_loaded_d,
                    tot_x_loaded_q,
                    tot_y_loaded_d,
                    tot_y_loaded_q,
                    tot_z_stored_d,
                    tot_z_stored_q;
logic [1:0] transfer_count_d,
            transfer_count_q;
// Signals for the address generator
logic [31:0] x_rows_offs_d,
             x_rows_offs_q,
             x_cols_offs_d,
             x_cols_offs_q;
logic [15:0] w_loaded_d, w_loaded_q,
             w_iters_d, w_iters_q,
             tot_w_loaded_d, tot_w_loaded_q,
             new_w_d, new_w_q,
             x_rows_iter_d, x_rows_iter_q,
             x_cols_iter_d, x_cols_iter_q,
             y_rows_iter_d, y_rows_iter_q,
             y_cols_iter_d, y_cols_iter_q,
             w_cols_d, w_cols_q,
             tot_x_read_d, tot_x_read_q;
logic [$clog2(H):0] h_shift_d,
                    h_shift_q,
                    d_shift_d,
                    d_shift_q;
logic w_cols_lftovr_en,
      w_cols_lftovr_rst,
      x_cols_lftovr_en,
      x_cols_lftovr_rst;
logic [$clog2(D):0] w_cycles_q,
                    w_cols_lftovr,
                    y_cols_lftovr_q,
                    x_cols_lftovr_q;
logic [$clog2(H):0] w_rows_lftovr;
logic [STRB-1:0] strb;
logic [$clog2(D)-1:0] x_slots_q;
fpnew_pkg::fp_format_e input_cast_src_fmt ,
                       input_cast_dst_fmt ,
                       output_cast_src_fmt,
                       output_cast_dst_fmt;

// JMP = 32 if streamer ports are 256 bit wide and parallelism is 32 bit
localparam int unsigned JMP    = NumByte*(DATA_W/MemDw - 1);
localparam int unsigned NBYTES = BITW/8;

typedef enum logic [3:0] {
  ENGINE_IDLE,
  PRELOAD_Y,
  LOAD_Y,
  X_REQ,
  W_REQ,
  STORE_REQ,
  FIRST_LOAD,
  WAIT,
  WAIT_ONE,
  WAIT_TWO,
  LOAD_X,
  LOAD_W,
  STORE,
  SKIP_W
} redmule_fsm_state_e;

redmule_fsm_state_e current, next;

always_comb begin : address_gen_signals
  // Here we initialize the streamer source signals
  // for the X stream source
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[X_ADDR]
                                                                      + x_rows_offs_q + x_cols_offs_q;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.tot_len = (x_rows_lftovr_q == 0) ?
                                                                    W : x_rows_lftovr_q;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d0_len = 'd1;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d0_stride = 'd0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d1_len = W;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d1_stride = reg_file_i.hwpe_params[X_D1_STRIDE];
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.d2_stride = '0;
    cntrl_streamer_o.x_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 2'b11;
    // Here we initialize the streamer source signals
    // for the W stream source
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[W_ADDR];
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.tot_len = reg_file_i.hwpe_params[W_TOT_LEN];
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d0_len = reg_file_i.hwpe_params[W_ITERS][31:16];
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d0_stride = reg_file_i.hwpe_params[W_D0_STRIDE];
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d1_len = reg_file_i.hwpe_params[W_ITERS][15:0];
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d1_stride = JMP;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.d2_stride = 'd0;
    cntrl_streamer_o.w_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 2'b11;
    // Here we initialize the streamer source signals
    // for the Y stream source
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[Z_ADDR];
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.tot_len = reg_file_i.hwpe_params[Z_TOT_LEN];
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d0_len = W;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d0_stride = reg_file_i.hwpe_params[Z_D0_STRIDE];
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d1_len = reg_file_i.hwpe_params[W_ITERS][15:0];
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d1_stride = JMP;
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.d2_stride = reg_file_i.hwpe_params[Z_D2_STRIDE];
    cntrl_streamer_o.y_stream_source_ctrl.addressgen_ctrl.dim_enable_1h = 2'b11;
    // Here we initialize the streamer sink signals for
    // the Z stream sink
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.base_addr = reg_file_i.hwpe_params[Z_ADDR];
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.tot_len = reg_file_i.hwpe_params[Z_TOT_LEN];
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d0_len = W;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d0_stride = reg_file_i.hwpe_params[Z_D0_STRIDE];
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d1_len = reg_file_i.hwpe_params[W_ITERS][15:0];
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d1_stride = JMP;
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.d2_stride = reg_file_i.hwpe_params[Z_D2_STRIDE];
    cntrl_streamer_o.z_stream_sink_ctrl.addressgen_ctrl.dim_enable_1h = 2'b11;
end

/*---------------------------------------------------------------------------------------------*/
/*                                       Register island                                       */
/*---------------------------------------------------------------------------------------------*/

always_ff @(posedge clk_i or negedge rst_ni) begin : state_register
  if(~rst_ni) begin
    current <= ENGINE_IDLE;
  end else begin
    if (clear_i || clear_regs || cntrl_scheduler_i.rst)
      current <= ENGINE_IDLE;
    else
      current <= next;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : tot_weights_loaded
  if(~rst_ni) begin
    tot_w_loaded_q <= '0;
  end else begin
    if (clear_i || clear_regs)
      tot_w_loaded_q <= '0;
    else
      tot_w_loaded_q <= tot_w_loaded_d;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : tot_x_loaded
  if(~rst_ni) begin
    tot_x_loaded_q <= '0;
  end else begin
    if (clear_i || clear_regs)
      tot_x_loaded_q <= '0;
    else
      tot_x_loaded_q <= tot_x_loaded_d;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : tot_y_loaded
  if(~rst_ni) begin
    tot_y_loaded_q <= '0;
  end else begin
    if (clear_i || clear_regs)
      tot_y_loaded_q <= '0;
    else
      tot_y_loaded_q <= tot_y_loaded_d;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : tot_z_stored
  if(~rst_ni) begin
    tot_z_stored_q <= '0;
  end else begin
    if (clear_i || clear_regs)
      tot_z_stored_q <= '0;
    else
      tot_z_stored_q <= tot_z_stored_d;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : w_load_counter
  if(~rst_ni) begin
    w_loaded_q <= '0;
  end else begin
    if (clear_i || clear_regs)
      w_loaded_q <= '0;
    else
      w_loaded_q <= w_loaded_d;
  end
end

// hold_q signal is used to trigger the shifting of the X Buffer only once
// the first four W rows have been brought inside the accelerator
always_ff @(posedge clk_i or negedge rst_ni) begin : hold_reg
  if(~rst_ni) begin
    hold_q <= 1'b0;
  end else begin
    if (clear_i || clear_regs || hold_rst)
      hold_q <= 1'b0;
    else if (hold_en)
      hold_q <= 1'b1;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : transfer_counter
  if(~rst_ni) begin
    transfer_count_q <= '0;
  end else begin
    if (clear_i || clear_regs || transfer_rst)
      transfer_count_q <= '0;
    else
      transfer_count_q <= transfer_count_d;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : weight_iteration_counter
  if(~rst_ni) begin
    w_iters_q <= 0;
  end else begin
    if (clear_i || clear_regs)
      w_iters_q <= '0;
    else
      w_iters_q <= w_iters_d;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin
  if(~rst_ni) begin
    w_cols_q <= 0;
  end else begin
    if (clear_i || clear_regs)
      w_cols_q <= '0;
    else
      w_cols_q <= w_cols_d;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : x_loaded_rows_counter
  if(~rst_ni) begin
    loading_x_q <= '0;
  end else begin
    if (clear_i || clear_regs || load_x_rst) begin
      loading_x_q <= '0;
    end else if (load_x_en)
      loading_x_q <= 1'b1;
    else begin
      loading_x_q <= loading_x_q;
    end
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : y_loaded_rows_counter
  if(~rst_ni) begin
    loading_y_q <= '0;
  end else begin
    if (clear_i || clear_regs || load_y_rst) begin
      loading_y_q <= '0;
    end else if (load_y_en)
      loading_y_q <= 1'b1;
    else begin
      loading_y_q <= loading_y_q;
    end
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : consume_y
  if(~rst_ni) begin
    consume_y_q <= '0;
  end else begin
    if (clear_i || clear_regs || consume_y_rst) begin
      consume_y_q <= '0;
    end else if (consume_y_en)
      consume_y_q <= 1'b1;
    else begin
      consume_y_q <= consume_y_q;
    end
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : y_preloaded
  if(~rst_ni) begin
    y_preloaded_q <= '0;
  end else begin
    if (clear_i || clear_regs || y_preloaded_rst) begin
      y_preloaded_q <= '0;
    end else if (y_preloaded_en)
      y_preloaded_q <= 1'b1;
    else begin
      y_preloaded_q <= y_preloaded_q;
    end
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : x_preloaded
  if(~rst_ni) begin
    x_preloaded_q <= '0;
  end else begin
    if (clear_i || clear_regs || x_preloaded_rst) begin
      x_preloaded_q <= '0;
    end else if (x_preloaded_en)
      x_preloaded_q <= 1'b1;
    else begin
      x_preloaded_q <= x_preloaded_q;
    end
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : w_cycles_counter_en
  if(~rst_ni) begin
    count_w_cycles_q <= '0;
  end else begin
    if (clear_i || clear_regs || count_w_cycles_rst) begin
      count_w_cycles_q <= '0;
    end else if (count_w_cycles_en)
      count_w_cycles_q <= 1'b1;
    else begin
      count_w_cycles_q <= count_w_cycles_q;
    end
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : w_cycles_counter
  if(~rst_ni) begin
    w_cycles_q <= '0;
  end else begin
    if (clear_i | clear_regs | count_w_cycles_rst)
      w_cycles_q <= '0;
    else if (count_w_cycles_q & reg_enable)
      w_cycles_q <= w_cycles_q + 1;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : y_columns_leftover_flag
  if(~rst_ni) begin
    y_cols_lftovr_q <= '0;
  end else begin
    if (clear_i || clear_regs || y_cols_lftovr_rst)
      y_cols_lftovr_q <= '0;
    else if (y_cols_lftovr_en)
      y_cols_lftovr_q <= reg_file_i.hwpe_params[LEFTOVERS][7:0];
  end
end
assign y_cols_lftovr_o = y_cols_lftovr_q;

always_ff @(posedge clk_i or negedge rst_ni) begin : y_rows_leftover_flag
  if(~rst_ni) begin
    y_rows_lftovr_q <= '0;
  end else begin
    if (clear_i || clear_regs || y_rows_lftovr_rst)
      y_rows_lftovr_q <= '0;
    else if (y_rows_lftovr_en)
      y_rows_lftovr_q <= reg_file_i.hwpe_params[LEFTOVERS][31:24];
  end
end
assign y_rows_lftovr_o = y_rows_lftovr_q;

always_ff @(posedge clk_i or negedge rst_ni) begin
  if(~rst_ni) begin
    tot_x_read_q <= '0;
  end else begin
    if (clear_i || clear_regs)
      tot_x_read_q <= '0;
    else
      tot_x_read_q <= tot_x_read_d;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : wait_states_counter
  if(~rst_ni) begin
    n_waits_q <= '0;
  end else begin
    if (clear_i || clear_regs)
      n_waits_q <= '0;
    else
      n_waits_q <= n_waits_d;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : h_shift_counter
  if(~rst_ni) begin
    h_shift_q <= '0;
    d_shift_q <= '0;
  end else begin
    if (clear_i || clear_regs) begin
      h_shift_q <= '0;
      d_shift_q <= '0;
    end else begin
      h_shift_q <= h_shift_d;
      d_shift_q <= d_shift_d;
    end
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : new_weight_reg
  if(~rst_ni) begin
    new_w_q <= '0;
  end else begin
    if (clear_i || clear_regs)
      new_w_q <= '0;
    else
      new_w_q <= new_w_d;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : store_signal
  if(~rst_ni) begin
    last_store <= '0;
  end else begin
    if (clear_i || clear_regs || last_store_rst)
      last_store  <= '0;
    else if (last_store_en)
      last_store <= 1;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : store_cols_leftovers
  if(~rst_ni) begin
    store_cols_lftovr_q <= '0;
  end else begin
    if (clear_i || clear_regs || store_cols_lftovr_rst)
      store_cols_lftovr_q <= '0;
    else if (store_cols_lftovr_en)
      store_cols_lftovr_q <= '1;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : store_rows_leftovers
  if(~rst_ni) begin
    store_rows_lftovr_q <= '0;
  end else begin
    if (clear_i || clear_regs || store_rows_lftovr_rst)
      store_rows_lftovr_q <= '0;
    else if (store_rows_lftovr_en)
      store_rows_lftovr_q <= reg_file_i.hwpe_params[LEFTOVERS][31:24];
  end
end

always_ff @ (posedge clk_i or negedge rst_ni) begin : skip_w_reg
  if(~rst_ni) begin
    skip_w_q <= '0;
  end else begin
    if (clear_i || clear_regs || skip_w_rst)
      skip_w_q <= '0;
    else if (skip_w_en)
      skip_w_q <= 1;
  end
end

always_ff @ (posedge clk_i or negedge rst_ni) begin : skipped_w_counter
  if(~rst_ni) begin
    skipped_w_q <= '0;
  end else begin
    if (clear_i || clear_regs || skip_w_rst)
      skipped_w_q <= '0;
    else if (skip_w_q && skipped_w_q != NumPipeRegs)
      skipped_w_q <= skipped_w_q + 1;
  end
end
assign reg_disable    = skipped_w_q == NumPipeRegs;
assign shift_disable  = skipped_w_q >= NumPipeRegs - 1;

always_ff @(posedge clk_i or negedge rst_ni) begin : x_rows_and_columns_iteration
  if(~rst_ni) begin
    x_rows_iter_q <= '0;
    x_cols_iter_q <= '0;
  end else begin
    if (clear_i || clear_regs) begin
      x_rows_iter_q <= '0;
      x_cols_iter_q <= '0;
    end else begin
      x_rows_iter_q <= x_rows_iter_d;
      x_cols_iter_q <= x_cols_iter_d;
    end
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : y_rows_and_columns_iteration
  if(~rst_ni) begin
    y_cols_iter_q <= '0;
    y_rows_iter_q <= '0;
  end else begin
    if (clear_i || clear_regs) begin
      y_cols_iter_q <= '0;
      y_rows_iter_q <= '0;
    end else begin
      y_cols_iter_q <= y_cols_iter_d;
      y_rows_iter_q <= y_rows_iter_d;
    end
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : x_cols_leftovers
  if(~rst_ni) begin
    x_cols_lftovr_q <= '0;
    x_slots_q       <= '0;
  end else begin
    if (clear_i || clear_regs || x_cols_lftovr_rst) begin
      x_cols_lftovr_q <= '0;
      x_slots_q       <= '0;
    end else if (x_cols_lftovr_en) begin
      x_cols_lftovr_q <= reg_file_i.hwpe_params[LEFTOVERS][23:16];
      x_slots_q       <= reg_file_i.hwpe_params[X_SLOTS];
    end
  end
end
assign w_rows_lftovr_o = tot_w_loaded_q > reg_file_i.hwpe_params[W_ITERS][31:16] - reg_file_i.hwpe_params[LEFTOVERS][15:8] ? reg_file_i.hwpe_params[LEFTOVERS][15:8] : '0;

always_ff @(posedge clk_i or negedge rst_ni) begin : weight_cols_leftovers
  if(~rst_ni) begin
    w_cols_lftovr <= '0;
  end else begin
    if (clear_i || clear_regs || w_cols_lftovr_rst)
      w_cols_lftovr <= '0;
    else if (w_cols_lftovr_en)
      w_cols_lftovr <= reg_file_i.hwpe_params[LEFTOVERS][7:0];
  end
end
assign w_cols_lftovr_o = w_cols_lftovr;

always_ff @(posedge clk_i or negedge rst_ni) begin : x_rows_leftovers
  if(~rst_ni) begin
    x_rows_lftovr_q <= '0;
  end else begin
    if (clear_i || clear_regs || x_rows_lftovr_rst) begin
      x_rows_lftovr_q <= '0;
    end else if (x_rows_lftovr_en) begin
      x_rows_lftovr_q <= reg_file_i.hwpe_params[LEFTOVERS][31:24];
    end
  end
end


always_ff @(posedge clk_i or negedge rst_ni) begin : gate_register
  if(~rst_ni) begin
    gate <= '0;
  end else begin
    if (clear_i || clear_regs || gate_rst)
      gate <= '0;
    else if (gate_en)
      gate <= '1;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : weight_shift_register
  if(~rst_ni) begin
    shift_lock_q <= '0;
  end else begin
    if (clear_i || clear_regs || shift_lock_rst)
      shift_lock_q <= '0;
    else if (shift_lock_en)
      shift_lock_q <= '1;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : addr_offs_counter
  if(~rst_ni) begin
    x_rows_offs_q  <= '0;
    x_cols_offs_q  <= '0;
  end else begin
    if (clear_i || clear_regs) begin
      x_rows_offs_q  <= '0;
      x_cols_offs_q  <= '0;
    end else if(x_rows_rst)
      x_rows_offs_q  <= '0;
    else if (x_cols_rst)
      x_cols_offs_q  <= '0;
    else begin
      x_rows_offs_q  <= x_rows_offs_d;
      x_cols_offs_q  <= x_cols_offs_d;
    end
  end
end

logic [7:0] gate_count_d, gate_count_q;
always_ff @(posedge clk_i or negedge rst_ni) begin : gate_enable_counter
  if(~rst_ni) begin
    gate_count_q <= '0;
  end else begin
    if (clear_i || clear_regs)
      gate_count_q <= '0;
    else
      gate_count_q <= gate_count_d;
  end
end

logic [7:0] store_count_d, store_count_q;
always_ff @(posedge clk_i or negedge rst_ni) begin : store_handshake_counter
  if(~rst_ni) begin
    store_count_q <= '0;
  end else begin
    if (clear_i || clear_regs)
      store_count_q <= '0;
    else
      store_count_q <= store_count_d;
  end
end

logic [15:0] tot_store_d, tot_store_q;
always_ff @(posedge clk_i or negedge rst_ni) begin : tot_stores_counter
  if(~rst_ni) begin
    tot_store_q <= '0;
  end else begin
    if (clear_i || clear_regs)
      tot_store_q <= '0;
    else
      tot_store_q <= tot_store_d;
  end
end

logic [15:0] consumed_y_d, consumed_y_q;
always_ff @(posedge clk_i or negedge rst_ni) begin : y_consumed_counter
  if(~rst_ni) begin
    consumed_y_q <= '0;
  end else begin
    if (clear_i || clear_regs)
      consumed_y_q <= '0;
    else
      consumed_y_q <= consumed_y_d;
  end
end

always_comb begin
  if (store_rows_lftovr_q == '0 || tot_z_stored_q < store_rows_lftovr_q) begin
    if (store_cols_lftovr_q) begin
      for (int i = 0; i < STRB; i++) begin
        strb [i] = ( i < NBYTES*reg_file_i.hwpe_params[LEFTOVERS][7:0] ) ? 1'b1 : 1'b0;
      end
    end else if (input_cast_src_fmt != FPFORMAT) begin
      for (int i = 0; i < STRB; i++) begin
        strb[i] =  ( i < (DATAW-DW_CUT)/8 ) ? 1'b1 : 1'b0;
      end
    end else
      strb = '1;
  end else
    strb = '0;
end

logic [H-1:0][$clog2(D)-1:0] count_w_q;
logic [H-1:0][$clog2(D)-1:0] shift_count_q;
logic [$clog2(H)-1:0] counter_index;
logic [H-1:0] en_w, w_rst;

always_ff @(posedge clk_i or negedge rst_ni) begin
  if(~rst_ni) begin
    en_w <= '0;
  end else begin
    if (clear_i || clear_regs)
      en_w <= '0;
    else begin
      for (int i = 0; i < H; i++) begin
        if (w_loaded && !en_w [counter_index])
          en_w [counter_index] <= 1;
      end
    end
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin
  if(~rst_ni) begin
    counter_index <= '0;
  end else begin
    if (clear_i || clear_regs)
      counter_index <= '0;
    else if (w_loaded && !en_w[H-1])
      counter_index <= counter_index + 1;
  end
end

logic shift_comb;
logic wlq;
logic shift_comb_n;
logic shift_comb_en;
logic end_computation;
always_ff @(posedge clk_i or negedge rst_ni) begin
  if(~rst_ni) begin
    shift_count_q <= '0;
  end else begin
    if (clear_i || clear_regs)
      shift_count_q <= '0;
    else if (w_rst [h_shift_d])
      shift_count_q [h_shift_d] <= '0;
    else begin
      for (int i= 0; i < D; i++) begin
        if(shift_count_q[i][1:0] == '1) begin // "elastic" cycle
          if(en_w [i] & w_loaded)
            shift_count_q [i] <= shift_count_q [i] + 1;
        end else if(en_w [i]) begin // "rigid" cycle
          shift_count_q [i] <= shift_count_q [i] + 1;
        end
      end
    end
  end
end
assign shift_count_en = ((shift_count_q[0][1:0] == '1 && !end_computation && !skip_w_q) ? w_loaded : 1'b1);

assign reg_enable   = (shift_count_en | (flgs_streamer_i.w_stream_source_flags.ready_start & fifo_flgs_i.empty)) & !reg_disable;
assign reg_enable_o = reg_enable;
assign count_w_q    = shift_count_q;


logic pre_ready_en, pre_ready_rst, pre_ready_x_q, x_buffer_clk_en, z_buffer_clk_en;
always_ff @(posedge clk_i or negedge rst_ni) begin : pre_ready_x_sampler
  if(~rst_ni) begin
    pre_ready_x_q <= '0;
  end else begin
    if (clear_i || clear_regs || pre_ready_rst)
      pre_ready_x_q <= '0;
    else if (pre_ready_en)
      pre_ready_x_q <= '1;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin: y_push_register
  if(~rst_ni) begin
    y_push_q <= 1'b0;
  end else begin
    if (clear_i || clear_regs || y_push_rst)
      y_push_q <= 1'b0;
    else if (y_push_en)
      y_push_q <= 1'b1;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : y_loaded
  if (~rst_ni) begin
    y_loaded_q <= 1'b0;
  end else begin
    if (clear_i || clear_regs || flgs_z_buffer_i.y_pushed)
      y_loaded_q <= 1'b0;
    else if (flgs_z_buffer_i.loaded)
      y_loaded_q <= 1'b1;
  end
end

/* Engine control singals binding */
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
assign input_cast_src_fmt              = fpnew_pkg::fp_format_e'(reg_file_i.hwpe_params[OP_SELECTION][15:13]);
assign input_cast_dst_fmt              = fpnew_pkg::fp_format_e'(reg_file_i.hwpe_params[OP_SELECTION][12:10]);
assign output_cast_src_fmt             = fpnew_pkg::fp_format_e'(reg_file_i.hwpe_params[OP_SELECTION][12:10]);
assign output_cast_dst_fmt             = fpnew_pkg::fp_format_e'(reg_file_i.hwpe_params[OP_SELECTION][15:13]);

assign gate_en_o    = gate_comb;
assign w_load_o     = w_loaded;
assign soft_clear_o = clear_regs;
assign x_buffer_clk_en_o  = x_buffer_clk_en;
assign z_buffer_clk_en_o = z_buffer_clk_en;

assign x_rows_clk_gate_en = (reg_file_i.hwpe_params[X_ITERS][31:16] > 'd1) ?       // If M > L we count all iterations before leftovers before clock gating
                                                                           (w_loaded_q == 'd1 +                                                // One cycle due to delay
                                                                                              ( (reg_file_i.hwpe_params[X_ITERS][31:16] - 1)   // We need to count all iterations before we
                                                                                              * (reg_file_i.hwpe_params[W_ITERS][31:16]    )   // get to the leftover. The number of iterations
                                                                                              * (reg_file_i.hwpe_params[W_ITERS][ 15:0]    ) ) // are ceil(M/L)*N*ceil(K/[H*(P+1)])
                                                                                              + PIPE_REGS + 1                              )   // PIPE_REGS + 1 are needed to drain the pipeline
                                                                           : 1'b1; // If M < L we need to clock gate the whole computation

assign x_rows_lftovr_en = ((x_rows_iter_d == reg_file_i.hwpe_params[X_ITERS][31:16] - 1 && w_cols_d == '0)
                           || (reg_file_i.hwpe_params[X_ITERS][31:16] == 'd1 && current == X_REQ))
                          && reg_file_i.hwpe_params[LEFTOVERS][31:24] != '0
                          && x_rows_lftovr_q == '0;

always_ff @(posedge clk_i, negedge rst_ni) begin: rows_clock_gating
  if (~rst_ni)
    cntrl_engine_o.row_clk_gate_en <= '1;
  else begin
    if (clear_i || clear_regs)
      cntrl_engine_o.row_clk_gate_en <= '1;
    else if (x_rows_lftovr_q != '0  && x_rows_clk_gate_en) begin
      for (int i = 0; i < W; i++) begin
        if (i > x_rows_lftovr_q - 1)
          cntrl_engine_o.row_clk_gate_en[i] <= 1'b0;
      end
    end
  end
end

always_comb begin : finite_state_machine
// Default assignments
next                           = current;
z_strb_o                       = '1;
flgs_scheduler_o.y_push_enable = '0;
flgs_scheduler_o.x_ready       = '0;
flgs_scheduler_o.w_ready       = '0;
flgs_scheduler_o.y_ready       = '0;
flgs_scheduler_o.z_valid       = '0;
flgs_scheduler_o.x_full        = '0;
flgs_scheduler_o.w_loaded      = '0;
flgs_scheduler_o.w_shift       = shift_count_en && !shift_disable;
flgs_scheduler_o.stored        = '0;
flgs_scheduler_o.z_strb        = strb;
// Input buffer control default assignments
cntrl_x_buffer_o.d_shift     = '0;
cntrl_x_buffer_o.h_shift     = '0;
cntrl_x_buffer_o.blck_shift  = '0;
cntrl_x_buffer_o.load        = '0;
cntrl_x_buffer_o.cols_lftovr = x_cols_lftovr_q;
cntrl_x_buffer_o.rows_lftovr = x_rows_lftovr_q;
cntrl_x_buffer_o.slots       = x_slots_q;
cntrl_streamer_o.x_stream_source_ctrl.req_start = 1'b0;
cntrl_streamer_o.w_stream_source_ctrl.req_start = 1'b0;
cntrl_streamer_o.y_stream_source_ctrl.req_start = 1'b0;
cntrl_streamer_o.z_stream_sink_ctrl.req_start   = 1'b0;
cntrl_streamer_o.input_cast_src_fmt             = input_cast_src_fmt;
cntrl_streamer_o.input_cast_dst_fmt             = input_cast_dst_fmt;
cntrl_streamer_o.output_cast_src_fmt            = output_cast_src_fmt;
cntrl_streamer_o.output_cast_dst_fmt            = output_cast_dst_fmt;

// Default reset signals for the addresses
x_rows_rst      = 1'b0;
x_cols_rst      = 1'b0;

// Other default signals
load_x_en          = 1'b0;
load_x_rst         = 1'b0;
load_y_en          = 1'b0;
load_y_rst         = 1'b0;
consume_y_en       = 1'b0;
consume_y_rst      = 1'b0;
x_preloaded_en     = 1'b0;
x_preloaded_rst    = 1'b0;
y_preloaded_en     = 1'b0;
y_preloaded_rst    = 1'b0;
count_w_cycles_en  = 1'b0;
count_w_cycles_rst = 1'b0;
hold_en            = 1'b0;
transfer_rst       = 1'b0;
hold_rst           = 1'b0;
w_loaded           = 1'b0;
z_store_o          = 1'b0;
y_buffer_load_o    = 1'b0;
gate_en            = 1'b0;
gate_rst           = 1'b0;
gate_comb          = 1'b1;
shift_comb         = 1'b1;
shift_lock_en      = 1'b0;
shift_lock_rst     = 1'b0;
last_store_en      = 1'b0;
last_store_rst     = 1'b0;
end_computation    = '0;
x_buffer_clk_en    = '0;
z_buffer_clk_en    = '0;
skip_w_en          = 1'b0;
skip_w_rst         = 1'b0;

// Leftover enable and reset signals
x_cols_lftovr_en   = 1'b0;
x_cols_lftovr_rst  = 1'b0;
//x_rows_lftovr_en   = 1'b0;  //Moved out of FSM
x_rows_lftovr_rst  = 1'b0;
y_cols_lftovr_en   = 1'b0;
y_cols_lftovr_rst  = 1'b0;
y_rows_lftovr_en   = 1'b0;
y_rows_lftovr_rst  = 1'b0;
w_cols_lftovr_en   = 1'b0;
w_cols_lftovr_rst  = 1'b0;
store_cols_lftovr_en  = 1'b0;
store_cols_lftovr_rst = 1'b0;
store_rows_lftovr_en  = 1'b0;
store_rows_lftovr_rst = 1'b0;
pre_ready_en       = '0;
pre_ready_rst      = '0;
y_push_en          = 1'b0;
y_push_rst         = 1'b0;

// Default values for counters
w_loaded_d       = w_loaded_q;
w_iters_d        = w_iters_q;
w_cols_d         = w_cols_q;
new_w_d          = new_w_q;
h_shift_d        = h_shift_q;
d_shift_d        = d_shift_q;
x_rows_offs_d    = x_rows_offs_q;
x_cols_offs_d    = x_cols_offs_q;
x_rows_iter_d    = x_rows_iter_q;
x_cols_iter_d    = x_cols_iter_q;
tot_w_loaded_d   = tot_w_loaded_q;
tot_x_read_d     = tot_x_read_q;
tot_x_loaded_d   = tot_x_loaded_q;
tot_y_loaded_d   = tot_y_loaded_q;
tot_z_stored_d   = tot_z_stored_q;
n_waits_d        = n_waits_q;
transfer_count_d = transfer_count_q;
gate_count_d     = gate_count_q;
store_count_d    = store_count_q;
tot_store_d      = tot_store_q;
consumed_y_d     = consumed_y_q;
y_rows_iter_d    = y_rows_iter_q;
y_cols_iter_d    = y_cols_iter_q;

clear_regs       = 1'b0;

  case (current)
    ENGINE_IDLE: begin
      if (clear_i) begin
        x_buffer_clk_en  = 1'b1;
        z_buffer_clk_en = 1'b1;
      end

      if (cntrl_scheduler_i.first_load) begin
        if (reg_file_i.hwpe_params[OP_SELECTION][0]) begin
          next = PRELOAD_Y;
          z_buffer_clk_en = 1'b1;
          if (reg_file_i.hwpe_params[X_ITERS][31:16] == 'd1 && reg_file_i.hwpe_params[LEFTOVERS][31:24] != '0)
            y_rows_lftovr_en = 1'b1;
        end else
          next = X_REQ;

        cntrl_streamer_o.y_stream_source_ctrl.req_start = 1'b1;
        cntrl_streamer_o.z_stream_sink_ctrl.req_start   = 1'b1;
      end else
        next = ENGINE_IDLE;
    end

    PRELOAD_Y: begin
      if (y_fifo_valid_i && y_fifo_strb_i == '1 && !flgs_z_buffer_i.loaded) begin
        y_buffer_load_o = 1'b1;
        z_buffer_clk_en = 1'b1;
      end
      if (flgs_z_buffer_i.loaded) begin
        next = X_REQ;
        y_preloaded_en = 1'b1;
        flgs_scheduler_o.y_ready = 1'b0;
        y_cols_iter_d = y_cols_iter_q + 1;


        if (y_cols_iter_q == reg_file_i.hwpe_params[W_ITERS][15:0] - 1)
          y_rows_iter_d = y_rows_iter_q + 1;

      end else begin
        next = PRELOAD_Y;
        flgs_scheduler_o.y_ready = 1'b1;
      end
    end

    X_REQ: begin
      z_buffer_clk_en = (flgs_z_buffer_i.loaded) ? 1'b1 : 1'b0;
      cntrl_streamer_o.x_stream_source_ctrl.req_start = 1'b1;
      n_waits_d = n_waits_q + 1;
      if (cntrl_scheduler_i.first_load) begin
        next = FIRST_LOAD;
      end else if (n_waits_q == 2'd1) begin
        tot_x_read_d = tot_x_read_q + 1;
        next = LOAD_W;
        n_waits_d = '0;
        load_x_en = 1'b1;
        x_cols_iter_d = x_cols_iter_q + 1;
      end
    end

    FIRST_LOAD: begin
      hold_en = 1'b1;
      flgs_scheduler_o.x_ready = 1'b1;
      if (x_valid_i && x_strb_i == '1) begin
        cntrl_x_buffer_o.load = 1'b1;
        x_buffer_clk_en = 1'b1;
      end
      if (flgs_x_buffer_i.full) begin
        x_cols_iter_d = x_cols_iter_q + 1;
        x_preloaded_en = 1'b1;
        next = W_REQ;
        n_waits_d = '0;
      end else
        next = FIRST_LOAD;
    end

    W_REQ: begin
      cntrl_streamer_o.w_stream_source_ctrl.req_start = 1'b1;
      n_waits_d = n_waits_q + 1;
      w_cols_d  =  w_cols_q + 1;
      case (new_w_q)
        1: begin
           if (n_waits_q == NumPipeRegs) begin // This should be just to allow the W hci_source module to start
             next = LOAD_W;
           end
           else
             next = W_REQ;
        end
        0: begin
           next = LOAD_W;
        end
      endcase
      if (!cntrl_scheduler_i.first_load) begin
        x_cols_offs_d = '0;
        x_rows_offs_d = x_rows_offs_q + reg_file_i.hwpe_params[X_ROWS_OFFS];
      end
    end

    SKIP_W: begin
      transfer_count_d = '0;
      if (loading_x_q) begin
        next = LOAD_X;
      end else begin
        next = WAIT;
      end

      x_buffer_clk_en = 1'b1;
      h_shift_d = h_shift_q + 1;

      if (h_shift_q == H - 1) begin
        cntrl_x_buffer_o.d_shift = 1'b1;
        x_buffer_clk_en = 1'b1;
        d_shift_d = d_shift_q + 1;
        h_shift_d = '0;
      end

    end

    LOAD_W: begin
      transfer_count_d = '0;
      gate_count_d = gate_count_q + 1;
      if (reg_file_i.hwpe_params[OP_SELECTION][0]) begin
        y_push_rst = (flgs_z_buffer_i.y_pushed) ?  1'b1 : 1'b0;
        consume_y_rst = (flgs_z_buffer_i.y_pushed && consume_y_q) ? 1'b1 : 1'b0;
        consumed_y_d = consume_y_rst ? consumed_y_q + 'd1 : consumed_y_q;
        if (!accumulate_i && consume_y_q && !skip_w_q) begin
          flgs_scheduler_o.y_push_enable = 1'b1;
          z_buffer_clk_en          = 1'b1;
        end

        /*If we have stalls, we can fall into LOAD_W state to check wether Y loads are completed or not*/
        if (flgs_z_buffer_i.loaded || tot_y_loaded_q == '1) begin
          z_buffer_clk_en = 1'b1;
          x_buffer_clk_en = 1'b1;
          load_y_rst = (loading_y_q) ? 1'b1 : 1'b0;
          y_preloaded_rst = (y_preloaded_q) ? 1'b1 : 1'b0;
          y_cols_lftovr_rst = (y_cols_lftovr_q != '0) ? 1'b1 : 1'b0;
        end
      end

      if (y_rows_iter_q == reg_file_i.hwpe_params[X_ITERS][31:16] - 1 && reg_file_i.hwpe_params[LEFTOVERS][31:24] != 0 && y_rows_lftovr_q == '0)
        y_rows_lftovr_en = 1'b1;

      /*Here it is mandatory to check if the x_buffer is full because we want
        to schedule Y loads only once X has been reloaded*/
      if (reg_file_i.hwpe_params[OP_SELECTION][0] && flgs_x_buffer_i.full &&
          !flgs_streamer_i.y_stream_source_flags.ready_start &&
          !y_loaded_q) begin
        z_buffer_clk_en = 1'b1;
        load_y_en = (loading_y_q) ? 1'b0 : 1'b1;
        last_store_rst = 1'b1;
        if (store_cols_lftovr_q)
          store_cols_lftovr_rst = 1'b1;
      end

      if (shift_lock_q) begin
        if (w_valid_i) begin
          shift_lock_rst = 1'b1;
          flgs_scheduler_o.w_ready = 1'b1;
        end else if (gate_count_q >= 0) begin
          shift_comb = 1'b1;
          shift_lock_rst = 1'b1;
          flgs_scheduler_o.w_ready = 1'b1;
        end else begin
          flgs_scheduler_o.w_ready = 1'b0;
        end
      end else begin
        flgs_scheduler_o.w_ready = 1'b1;
        if (count_w_q [h_shift_q] == D - 1) begin
            shift_comb = 1'b0;
        end
      end

      if (hold_q == 1'b0 && w_valid_i) begin
        cntrl_x_buffer_o.h_shift = 1'b1;
        x_buffer_clk_en = 1'b1;
        h_shift_d = h_shift_q + 1;
      end

      if (h_shift_q == H - 1 && w_valid_i) begin
        cntrl_x_buffer_o.d_shift = 1'b1;
        x_buffer_clk_en = 1'b1;
        d_shift_d = d_shift_q + 1;
        h_shift_d = '0;
      end

      if (skip_w_q)
        skip_w_rst = 1'b1;

      if (w_valid_i == 1'b1 && w_strb_i == '1) begin
        w_loaded = 1'b1;
        count_w_cycles_en = (!count_w_cycles_q & x_preloaded_q) ? 1'b1 : 1'b0;
        if (reg_file_i.hwpe_params[OP_SELECTION][0] &&
            consumed_y_q < reg_file_i.hwpe_params[LEFT_PARAMS][31:16]) begin
          y_push_en = (!y_push_q) ? 1'b1 : 1'b0;
          consume_y_en = (!consume_y_q) ? 1'b1 : 1'b0;
        end

        w_loaded_d = w_loaded_q + 1;

        if (tot_w_loaded_d == reg_file_i.hwpe_params[W_ITERS][31:16]) begin
          tot_w_loaded_d = '0;
          w_iters_d = w_iters_q + 1;
        end else
          tot_w_loaded_d = tot_w_loaded_q + 1;

        flgs_scheduler_o.w_loaded = skip_w_q ? 1'b0 : 1'b1;

        if (loading_x_q)
          next = LOAD_X;
        else if ( ((loading_y_q && !flgs_z_buffer_i.loaded) ||
                  (y_preloaded_q && flgs_z_buffer_i.y_pushed &&
                  !(reg_file_i.hwpe_params[W_ITERS][15:0] == 'd1 &&
                    // if only one iteration is needed to completely load Y, we skip the LOAD_Y state
                    reg_file_i.hwpe_params[X_ITERS][31:16] == 'd1)) ||
                   (flgs_x_buffer_i.full && !y_loaded_q && y_fifo_valid_i)) &&
                   reg_file_i.hwpe_params[OP_SELECTION][0]
                ) begin
          next = LOAD_Y;
          if (y_cols_iter_q == reg_file_i.hwpe_params[W_ITERS][15:0] - 1) begin
            if ((reg_file_i.hwpe_params[LEFTOVERS][7:0] != '0) && (y_cols_lftovr_q == '0))
              y_cols_lftovr_en = 1'b1;
          end
        end else if ((d_shift_d == NumPipeRegs + 'd1) && !flgs_streamer_i.x_stream_source_flags.ready_start) begin
          load_x_en = 1'b1;
          d_shift_d = '0;
          next = LOAD_X;
          if (x_cols_iter_q == reg_file_i.hwpe_params[X_ITERS][15:0]) begin
            if ( (reg_file_i.hwpe_params[LEFTOVERS][23:16] != '0) && (x_cols_lftovr_q == '0) )
              x_cols_lftovr_en = 1'b1;
          end

        end else if (cntrl_scheduler_i.storing) begin
          next = STORE;
          n_waits_d = '0;
          store_count_d = '0;
          if (reg_file_i.hwpe_params[X_ITERS][31:16] == 'd1 &&
              reg_file_i.hwpe_params[LEFTOVERS][31:24] != '0 &&
              store_rows_lftovr_q == '0)
            store_rows_lftovr_en = 1'b1;
        end else begin
          next = WAIT;

          if (cntrl_scheduler_i.first_load) begin
            x_buffer_clk_en = 1'b1;
            cntrl_x_buffer_o.blck_shift = 1'b1;
            d_shift_d = d_shift_q + 2;
            n_waits_d = '0;
          end
        end
      end
    end

    LOAD_X: begin
      gate_count_d = '0;
      n_waits_d = n_waits_q + 1;
      flgs_scheduler_o.x_ready = 1'b1;
      x_buffer_clk_en = 1'b1;
      if (reg_file_i.hwpe_params[OP_SELECTION][0]) begin
        if (!accumulate_i & !skip_w_q) begin
          flgs_scheduler_o.y_push_enable = consume_y_q ? 1'b1 : 1'b0;
          z_buffer_clk_en          = 1'b1;
        end
        consume_y_rst = (flgs_z_buffer_i.y_pushed && consume_y_q) ? 1'b1 : 1'b0;
      end

      if (!shift_lock_q)
        shift_lock_en = 1'b1;

      if (flgs_x_buffer_i.full || tot_x_loaded_q == W) begin
        load_x_rst = 1'b1;
      end

      if (x_valid_i == 1'b1 && x_strb_i == '1) begin
        cntrl_x_buffer_o.load = 1'b1;
        transfer_count_d = transfer_count_q + 1;
        tot_x_loaded_d = tot_x_loaded_q + 1;
      end

      if (tot_x_loaded_d == ((x_rows_lftovr_q == '0) ? W : x_rows_lftovr_q)) begin
        tot_x_loaded_d = '0;
        load_x_rst = 1'b1;
        if (n_waits_q > 1) begin
          next = skip_w_q ? SKIP_W : LOAD_W;
          n_waits_d = '0;
          load_x_rst = (loading_x_q) ? 1'b1 : 1'b0;
        end else
          next = WAIT;
      end else if (transfer_count_d == NumPipeRegs) begin
        if (n_waits_q == 1) begin
          next = WAIT;
          shift_lock_rst = 1'b1;
        end else if (n_waits_q > 1 ) begin
          next = skip_w_q ? SKIP_W : LOAD_W;
          n_waits_d = '0;
        end
      end

      if (flgs_streamer_i.w_stream_source_flags.ready_start) begin
          if (x_rows_iter_q == reg_file_i.hwpe_params[X_ITERS][31:16])
              cntrl_streamer_o.w_stream_source_ctrl.req_start = 1'b0;
      end
    end

    LOAD_Y: begin
      gate_count_d = '0;
      z_buffer_clk_en = 1'b1;
      n_waits_d = n_waits_q + 1;
      flgs_scheduler_o.y_ready = 1'b1;
      load_y_en = (loading_y_q) ? 1'b0 : 1'b1;

      if (!shift_lock_q)
        shift_lock_en = 1'b1;

      if (flgs_z_buffer_i.loaded || tot_y_loaded_q == W - 1) begin
        load_y_rst = (loading_y_q) ? 1'b1 : 1'b0;
        y_preloaded_rst = (y_preloaded_q) ? 1'b1 : 1'b0;
        y_cols_iter_d = y_cols_iter_q + 1;
        y_cols_lftovr_rst = (y_cols_lftovr_q != '0) ? 1'b1 : 1'b0;

        if (y_cols_iter_q == reg_file_i.hwpe_params[W_ITERS][15:0] - 1)
          y_rows_iter_d = y_rows_iter_q + 1;
      end

      if (y_fifo_valid_i == 1'b1 && y_fifo_strb_i == '1) begin
        y_buffer_load_o = 1'b1;
        transfer_count_d = transfer_count_q + 1;
        tot_y_loaded_d = tot_y_loaded_q + 1;
      end

      if (tot_y_loaded_d == W) begin
      tot_y_loaded_d = '0;
        if (n_waits_q > 1) begin
          next = LOAD_W;
          n_waits_d = '0;
          load_y_rst = (loading_y_q) ? 1'b1 : 1'b0;
        end else
          next = WAIT;
      end else if (transfer_count_d == NumPipeRegs) begin
        if (n_waits_q == 1) begin
          next = WAIT;
          shift_lock_rst = 1'b1;
        end else if (n_waits_q > 1 || flgs_z_buffer_i.loaded) begin
          next = LOAD_W;
          n_waits_d = '0;
        end
      end
    end

    WAIT: begin
      transfer_count_d = '0;
      gate_count_d = '0;

      if (!accumulate_i && reg_file_i.hwpe_params[OP_SELECTION][0] && !skip_w_q) begin
        flgs_scheduler_o.y_push_enable = consume_y_q ? 1'b1 : 1'b0;
        z_buffer_clk_en          = 1'b1;
      end

      /*Here it is mandatory to check if the x_buffer is full because we want to schedule Y loads only once X has been reloaded*/
      if (reg_file_i.hwpe_params[OP_SELECTION][0] && flgs_x_buffer_i.full
          && !flgs_streamer_i.y_stream_source_flags.ready_start
          && !y_loaded_q) begin
        z_buffer_clk_en = 1'b1;
        x_buffer_clk_en = 1'b1;
        last_store_rst = 1'b1;
        load_y_en = (loading_y_q) ? 1'b0 : 1'b1;
        if (store_cols_lftovr_q)
          store_cols_lftovr_rst = 1'b1;
      end

      n_waits_d = n_waits_q + 1;

      if (w_cols_q == reg_file_i.hwpe_params[W_ITERS][15:0]) begin
        if ( (reg_file_i.hwpe_params[LEFTOVERS][7:0] != '0) && (w_cols_lftovr == '0) )
          w_cols_lftovr_en = 1'b1;
      end
      if (tot_w_loaded_d == reg_file_i.hwpe_params[W_ITERS][31:16]) begin
        if (w_cols_lftovr != '0) begin
          w_cols_lftovr_rst = 1'b1;
          store_cols_lftovr_en = 1'b1;
          w_cols_d = 16'd1;
        end else
          w_cols_d = w_cols_q + 1;
      end

        if ( (w_cycles_q == D - PIPE_REGS + 1) & reg_enable & x_preloaded_q) begin
          hold_rst = (hold_q) ? 1'b1 : 1'b0;
          count_w_cycles_rst = 1'b1;
          x_preloaded_rst = 1'b1;
        end

      if (x_cols_lftovr_q != '0 && (flgs_x_buffer_i.full) )
        x_cols_lftovr_rst = 1'b1;

      if (reg_file_i.hwpe_params[X_ITERS][15:0] > 'd1) begin // X Matrix N dimension is larger than the number of elements we read through the streamer port

        if (flgs_streamer_i.x_stream_source_flags.ready_start) begin

          if (flgs_streamer_i.w_stream_source_flags.ready_start)
            cntrl_streamer_o.x_stream_source_ctrl.req_start = 1'b0;
          else begin

            if (!pre_ready_x_q) begin
              pre_ready_en = 1'b1;
              flgs_scheduler_o.x_ready = 1'b1;
            end

            if (tot_store_q < reg_file_i.hwpe_params[LEFT_PARAMS][31:16] - 1) begin
              cntrl_streamer_o.x_stream_source_ctrl.req_start = 1'b1;
              tot_x_read_d = tot_x_read_q + 1;
              if (x_cols_lftovr_q != '0 && !loading_x_q)
                x_cols_lftovr_rst = 1'b1;
            end else if (tot_store_q == reg_file_i.hwpe_params[LEFT_PARAMS][31:16] - 1) begin
              if (x_cols_iter_q < reg_file_i.hwpe_params[X_ITERS][15:0] && tot_x_read_q < reg_file_i.hwpe_params[TOT_X_READ] - 1 || reg_file_i.hwpe_params[X_ITERS][31:16] == 'd1) begin
                cntrl_streamer_o.x_stream_source_ctrl.req_start = 1'b1;
                tot_x_read_d = tot_x_read_q + 1;
              end
            end else if (reg_file_i.hwpe_params[X_ITERS][31:16] == 'd1) begin
              cntrl_streamer_o.x_stream_source_ctrl.req_start = 1'b1;
              tot_x_read_d = tot_x_read_q + 1;
            end

            if (x_cols_iter_q == reg_file_i.hwpe_params[X_ITERS][15:0]) begin
              x_cols_iter_d = 16'd1;
              x_cols_offs_d = '0;
              if (w_cols_q == reg_file_i.hwpe_params[W_ITERS][15:0]) begin
                if (reg_file_i.hwpe_params[X_ITERS][31:16] == 1) begin
                  x_rows_offs_d = x_rows_offs_q;
                  x_rows_iter_d = x_rows_iter_q;
                  w_cols_d = 16'd0;

                end else begin
                  if (x_rows_iter_d < reg_file_i.hwpe_params[X_ITERS][31:16] - 1) begin
                    x_rows_offs_d = x_rows_offs_q + reg_file_i.hwpe_params[X_ROWS_OFFS];
                    x_rows_iter_d = x_rows_iter_q + 1;
                    w_cols_d = 16'd0;
                  end else begin
                    x_rows_offs_d = x_rows_offs_q;
                    x_rows_iter_d = x_rows_iter_q;
                  end
                end
              end
            end else begin
              x_cols_iter_d = x_cols_iter_q + 1;
              x_cols_offs_d = x_cols_offs_q + JMP;
            end

            if (w_iters_q == reg_file_i.hwpe_params[W_ITERS][15:0])
              w_iters_d = '0;
          end
        end
      end else begin
        // X Matrix N channel is equal or smaller than the number
        // of elements we read from the streamer port
        if (flgs_streamer_i.w_stream_source_flags.ready_start)
          cntrl_streamer_o.x_stream_source_ctrl.req_start = 1'b0;
        else begin

          if (!pre_ready_x_q) begin
            pre_ready_en = 1'b1;
            flgs_scheduler_o.x_ready = 1'b1;
          end

          if (tot_store_q == reg_file_i.hwpe_params[LEFT_PARAMS][31:16] - 1) begin
            if (x_cols_iter_q < reg_file_i.hwpe_params[X_ITERS][15:0] && tot_x_read_q < reg_file_i.hwpe_params[TOT_X_READ] - 1) begin
              cntrl_streamer_o.x_stream_source_ctrl.req_start = 1'b1;
              tot_x_read_d = tot_x_read_q + 1;
            end
          end

          if (x_cols_iter_q == reg_file_i.hwpe_params[X_ITERS][15:0]) begin
            x_cols_iter_d = 16'd1;
            x_cols_offs_d = '0;
            if (w_cols_q == reg_file_i.hwpe_params[W_ITERS][15:0]) begin
              if (x_rows_iter_d < reg_file_i.hwpe_params[X_ITERS][31:16] - 1) begin
                cntrl_streamer_o.x_stream_source_ctrl.req_start = 1'b1;
                x_rows_offs_d = x_rows_offs_q + reg_file_i.hwpe_params[X_ROWS_OFFS];
                x_rows_iter_d = x_rows_iter_q + 1;
                w_cols_d = 16'd0;
              end else begin
                x_rows_offs_d = x_rows_offs_q;
                x_rows_iter_d = x_rows_iter_q;
              end
            end
          end else begin
            x_cols_iter_d = x_cols_iter_q + 1;
            x_cols_offs_d = x_cols_offs_q + JMP;
          end

          if (w_iters_q == reg_file_i.hwpe_params[W_ITERS][15:0])
            w_iters_d = '0;
        end
      end

      if (reg_file_i.hwpe_params[OP_SELECTION][0]) begin
        if (y_cols_iter_q == reg_file_i.hwpe_params[W_ITERS][15:0])
          y_cols_iter_d = 16'd0;
      end

      if (tot_w_loaded_q == reg_file_i.hwpe_params[W_ITERS][31:16] && !loading_x_q) begin
        tot_w_loaded_d = '0;
        w_iters_d = w_iters_q + 1;
      end
      if (n_waits_q == (NumPipeRegs - 1) && !(flgs_streamer_i.w_stream_source_flags.ready_start & fifo_flgs_i.empty)) begin
        n_waits_d = '0;
        next = LOAD_W;
        if (last_store) begin
          flgs_scheduler_o.w_ready = 1'b1;
          last_store_rst = 1'b1;
        end
      end else if (flgs_streamer_i.w_stream_source_flags.ready_start && fifo_flgs_i.empty) begin
        end_computation = 1'b1;
        if (cntrl_scheduler_i.storing) begin
          next = STORE;
          if (reg_file_i.hwpe_params[X_ITERS][31:16] == 'd1 && reg_file_i.hwpe_params[LEFTOVERS][31:24] != '0 && store_rows_lftovr_q == '0)
            store_rows_lftovr_en = 1'b1;
        end else
          next = WAIT;
      end else if (flgs_x_buffer_i.empty && tot_store_q < reg_file_i.hwpe_params[LEFT_PARAMS][31:16] - 1) begin
        next = LOAD_X;
        load_x_en = 1'b1;
        d_shift_d = '0;

        //This handles the case where the number of iterations on X rows is 2 but we have a leftover <= H
        if (x_cols_iter_d == reg_file_i.hwpe_params[X_ITERS][15:0] - 1 &&
            !(x_rows_iter_d == '0 && w_iters_d == '0) &&
            reg_file_i.hwpe_params[X_ITERS][15:0] == 'd2 &&
            reg_file_i.hwpe_params[LEFTOVERS][23:16] <= H &&
            reg_file_i.hwpe_params[LEFTOVERS][23:16] != '0 &&
            tot_x_read_d != reg_file_i.hwpe_params[TOT_X_READ])
          skip_w_en = 1'b1;
      end
    end

    STORE: begin
      gate_count_d = '0;
      n_waits_d   = n_waits_q + 1;

      if (cntrl_scheduler_i.finished) begin
        flgs_scheduler_o.z_valid = 1'b0;
        tot_store_d = tot_store_q + 1;
        next = ENGINE_IDLE;
        // Registers cleanup before starting a new operation
        clear_regs = 1'b1;
        z_buffer_clk_en = 1'b1;
        x_buffer_clk_en  = 1'b1;
      end else begin
        flgs_scheduler_o.z_valid = 1'b1;

        if (z_ready_i == 1'b1) begin
          z_store_o = 1'b1;
          z_buffer_clk_en = 1'b1;
          store_count_d = store_count_q + 1;
          tot_z_stored_d = tot_z_stored_q + 1;
        end

        if (!flgs_streamer_i.w_stream_source_flags.ready_start) begin
          if (flgs_z_buffer_i.empty) begin
            transfer_rst = 1'b1;
            if (store_cols_lftovr_q)
              store_cols_lftovr_rst = 1'b1;
          end

          if (tot_z_stored_d == W) begin
            next = WAIT;
            tot_store_d = tot_store_q + 1;
            n_waits_d = (W == H*NumPipeRegs) ? (NumPipeRegs - 1) : n_waits_q;
            store_count_d = '0;
            tot_z_stored_d = '0;

            if (x_rows_lftovr_q != '0 && store_rows_lftovr_q == '0)
              store_rows_lftovr_en = 1'b1;

          end else if ( (n_waits_d == NumPipeRegs) && (store_count_d == NumPipeRegs) ) begin
            next = LOAD_W;
            n_waits_d = NumPipeRegs - 1;
            store_count_d = '0;
          end else if (n_waits_d > NumPipeRegs) begin
            shift_comb = 1'b0;
            if (store_count_d == NumPipeRegs) begin
              next = LOAD_W;
              n_waits_d = NumPipeRegs - 1;
              store_count_d = '0;
            end
          end
        end else
          next = STORE;
      end
    end
  endcase
end

endmodule : redmule_scheduler
