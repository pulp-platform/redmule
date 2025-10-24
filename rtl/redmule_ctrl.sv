// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
// Andrea Belano <andrea.belano2@unibo.it>
//

import redmule_pkg::*;

module redmule_ctrl
  import hwpe_ctrl_package::*;
#(
  parameter int unsigned DataW = 0,
  parameter int unsigned Height = MaxDim,
  parameter int unsigned Width = MaxDim,
  parameter int unsigned PipeRegs = MaxPipeRegs-1,
  parameter int unsigned FpWidth = 16,
  parameter bit          EnableReordering = 1'b0
)(
  input  logic                    clk_i             ,
  input  logic                    rst_ni            ,
  input  logic                    test_mode_i       ,
  output logic                    busy_o            ,
  input  logic                    target_clear_i    ,
  output logic                    clear_o           ,
  output logic                    evt_o             ,
  input  redmule_config_t         config_i          ,
  output redmule_config_t         config_o          ,
  input  logic                    reg_enable_i      ,
  input  logic                    start_cfg_i       ,
  output logic                    tiler_busy_o      ,
  input  logic                    fifo_empty_i      ,
  input  logic                    fifo_ready_i      ,
  input  flgs_streamer_t          flgs_streamer_i   ,
  output logic                    cfg_complete_o    ,
  // Flags coming from the state machine
  input  logic                    w_loaded_i        ,
  // Control signals for the engine
  output logic                    flush_o           ,
  // Control signals for the state machine
  output cntrl_scheduler_t        cntrl_scheduler_o ,
  output cntrl_flags_t            cntrl_flags_o
);

  logic        latch_clear;
  logic        tiler_setback, tiler_valid;
  logic        fifo_z_empty;
  logic        set_offset_q, set_offset_d, loopback_reset;

  typedef enum logic [2:0] {
    REDMULE_LATCH_RST,
    REDMULE_IDLE,
    REDMULE_STARTING,
    REDMULE_COMPUTING,
    REDMULE_LOOPBACK,
    REDMULE_FINISHED
  } redmule_ctrl_state_e;

  redmule_ctrl_state_e current, next;

  redmule_config_t redmule_config;

  redmule_tiler #(
    .DataW    ( DataW    ),
    .Height   ( Height   ),
    .Width    ( Width    ),
    .PipeRegs ( PipeRegs ),
    .FpWidth  ( FpWidth  )
  ) i_cfg_tiler (
    .clk_i       ( clk_i          ),
    .rst_ni      ( rst_ni         ),
    .clear_i     ( target_clear_i ),
    .setback_i   ( tiler_setback  ),
    .loopback_i  ( loopback_reset ),
    .start_cfg_i ( start_cfg_i    ),
    .valid_o     ( tiler_valid    ),
    .busy_o      ( tiler_busy_o   ),
    .ready_i     ( fifo_ready_i   ),
    .config_i    ( config_i       ),
    .config_o    ( redmule_config )
  );

  assign cfg_complete_o = tiler_valid;
  /*---------------------------------------------------------------------------------------------*/
  /*                                       Register island                                       */
  /*---------------------------------------------------------------------------------------------*/

  // State register
  always_ff @(posedge clk_i or negedge rst_ni) begin : state_register
    if(~rst_ni) begin
       current <= REDMULE_LATCH_RST;
    end else if(target_clear_i) begin
       current <= REDMULE_LATCH_RST;
    end else begin
      current <= next;
    end
  end

  // Set offset flag
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
       set_offset_q <= 1'b0;
    end else begin
      if (target_clear_i || latch_clear || current == REDMULE_FINISHED || loopback_reset)
        set_offset_q <= 1'b0;
      else
        set_offset_q <= set_offset_d;
    end
  end

  logic slave_start;
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
      slave_start <= 1'b0;
    end else if(target_clear_i) begin
      slave_start <= 1'b0;
    end else begin
      if (tiler_setback)
        slave_start <= 1'b0;
      else if (start_cfg_i)
        slave_start <= 1'b1;
    end
  end

  /*---------------------------------------------------------------------------------------------*/
  /*                                   Register file assignment                                  */
  /*---------------------------------------------------------------------------------------------*/
  assign config_o = redmule_config;

  /*---------------------------------------------------------------------------------------------*/
  /*                                        Controller FSM                                       */
  /*---------------------------------------------------------------------------------------------*/

  assign cntrl_scheduler_o.first_load = current == REDMULE_STARTING;
  assign tiler_setback                = tiler_valid;
  // Keep the accelerator clocked while in FINISHED so the FSM can take the
  // final transition back to IDLE before busy deasserts.
  assign busy_o                       = slave_start | (current != REDMULE_LATCH_RST && current != REDMULE_IDLE);
  assign loopback_reset               = current == REDMULE_COMPUTING && next == REDMULE_LOOPBACK;
  assign flush_o                      = current == REDMULE_FINISHED || loopback_reset;
  assign cntrl_scheduler_o.rst        = current == REDMULE_FINISHED || loopback_reset;
  assign cntrl_scheduler_o.finished   = current == REDMULE_FINISHED;
  assign latch_clear                  = current == REDMULE_LATCH_RST;
  assign fifo_z_empty                 = EnableReordering ? flgs_streamer_i.store_fifo_empty : 1'b1;

  always_comb begin : controller_fsm
    cntrl_flags_o.idle = 1'b0;
    next = current;
    set_offset_d = set_offset_q;

    case (current)
      REDMULE_LATCH_RST: begin
        cntrl_flags_o.idle = 1'b1;
        set_offset_d = 1'b0;
        next = REDMULE_IDLE;
      end

      REDMULE_IDLE: begin
        cntrl_flags_o.idle = 1'b1;
        set_offset_d = config_i.w_cols_offset != '0;
        if ((slave_start & tiler_valid) || test_mode_i) begin
          next = REDMULE_STARTING;
        end
      end

      REDMULE_LOOPBACK: begin
        cntrl_flags_o.idle = 1'b1;
        set_offset_d = 1'b0;
        if (tiler_valid) begin
          next = REDMULE_STARTING;
        end
      end

      REDMULE_STARTING: begin
        if (w_loaded_i) begin
          next = REDMULE_COMPUTING;
        end
      end

      REDMULE_COMPUTING: begin
        // busy_o gates clk_acc, so the job must not finish while stores are
        // still queued in the streamer's store FIFO, or they freeze unsent.
        if (flgs_streamer_i.z_stream_sink_flags.ready_start && fifo_empty_i
            && flgs_streamer_i.store_fifo_empty) begin
          if (set_offset_q) begin
            next = REDMULE_LOOPBACK;
          end else begin
            next = REDMULE_FINISHED;
          end
        end
      end

      REDMULE_FINISHED: begin
        next = REDMULE_IDLE;
      end
    endcase
  end

  /*---------------------------------------------------------------------------------------------*/
  /*                            Other combinational assigmnets                                   */
  /*---------------------------------------------------------------------------------------------*/

  assign evt_o   = flgs_streamer_i.z_stream_sink_flags.done && ~set_offset_q;

  assign clear_o = target_clear_i || latch_clear || current == REDMULE_FINISHED || loopback_reset;

endmodule : redmule_ctrl
