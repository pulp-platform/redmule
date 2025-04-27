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
  parameter  int unsigned N_CORES       = 8                      ,
  parameter  int unsigned IO_REGS       = REDMULE_REGS           ,
  parameter  int unsigned ID_WIDTH      = 8                      ,
  parameter  int unsigned SysDataWidth  = 32                     ,
  parameter  int unsigned N_CONTEXT     = 2                      ,
  parameter  int unsigned Height        = 4                      ,
  parameter  int unsigned Width         = 8                      ,
  parameter  int unsigned NumPipeRegs   = 3                      ,
  localparam int unsigned TILE          = (NumPipeRegs +1)*Height
)(
  input  logic                    clk_i             ,
  input  logic                    rst_ni            ,
  input  logic                    test_mode_i       ,
  output logic                    busy_o            ,
  output logic                    clear_o           ,
  output logic [N_CORES-1:0][1:0] evt_o             ,
  output ctrl_regfile_t           reg_file_o        ,
  input  logic                    reg_enable_i      ,
  input  logic                    start_cfg_i       ,
  input  flgs_streamer_t          flgs_streamer_i   ,
  output logic                    cfg_complete_o    ,
  // Flags coming from the state machine
  input  logic                    w_loaded_i        ,
  // Control signals for the engine
  output logic                    flush_o           ,
  // Control signals for the state machine
  output cntrl_scheduler_t        cntrl_scheduler_o ,
  output cntrl_flags_t            cntrl_flags_o,
  // Peripheral slave port
  hwpe_ctrl_intf_periph.slave     periph
);

  logic        clear, latch_clear;
  logic        tiler_setback, tiler_valid;

  typedef enum logic [2:0] {
    REDMULE_LATCH_RST,
    REDMULE_IDLE,
    REDMULE_STARTING,
    REDMULE_COMPUTING,
    REDMULE_FINISHED
  } redmule_ctrl_state_e;

  redmule_ctrl_state_e current, next;

  hwpe_ctrl_package::ctrl_regfile_t reg_file_d, reg_file_q;
  hwpe_ctrl_package::ctrl_slave_t   cntrl_slave;
  hwpe_ctrl_package::flags_slave_t  flgs_slave;

  // Control slave interface
  hwpe_ctrl_slave  #(
    .REGFILE_SCM    ( 0            ),
    .N_CORES        ( N_CORES      ),
    .N_CONTEXT      ( N_CONTEXT    ),
    .N_IO_REGS      ( REDMULE_REGS ),
    .N_GENERIC_REGS ( 6            ),
    .ID_WIDTH       ( ID_WIDTH     )
  ) i_slave         (
    .clk_i          ( clk_i        ),
    .rst_ni         ( rst_ni       ),
    .clear_o        ( clear        ),
    .cfg            ( periph       ),
    .ctrl_i         ( cntrl_slave  ),
    .flags_o        ( flgs_slave   ),
    .reg_file       ( reg_file_d   )
  );

  redmule_tiler  i_cfg_tiler (
    .clk_i       ( clk_i         ),
    .rst_ni      ( rst_ni        ),
    .clear_i     ( clear         ),
    .setback_i   ( tiler_setback ),
    .start_cfg_i ( start_cfg_i   ),
    .reg_file_i  ( reg_file_d    ),
    .valid_o     ( tiler_valid   ),
    .reg_file_o  ( reg_file_q    )
  );

  assign cfg_complete_o = tiler_valid;
  /*---------------------------------------------------------------------------------------------*/
  /*                                       Register island                                       */
  /*---------------------------------------------------------------------------------------------*/

  // State register
  always_ff @(posedge clk_i or negedge rst_ni) begin : state_register
    if(~rst_ni) begin
       current <= REDMULE_LATCH_RST;
    end else begin
      if (clear)
        current <= REDMULE_IDLE;
      else
        current <= next;
    end
  end

  logic slave_start;
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
      slave_start <= 1'b0;
    end else begin
      if (clear || tiler_setback)
        slave_start <= 1'b0;
      else if (flgs_slave.start)
        slave_start <= 1'b1;
    end
  end

  /*---------------------------------------------------------------------------------------------*/
  /*                                   Register file assignment                                  */
  /*---------------------------------------------------------------------------------------------*/
  assign reg_file_o = reg_file_q;

  /*---------------------------------------------------------------------------------------------*/
  /*                                        Controller FSM                                       */
  /*---------------------------------------------------------------------------------------------*/

  assign cntrl_scheduler_o.first_load = current == REDMULE_STARTING;
  assign tiler_setback                = current == REDMULE_IDLE && next == REDMULE_STARTING;
  assign busy_o                       = current != REDMULE_LATCH_RST && current != REDMULE_IDLE && current != REDMULE_FINISHED;
  assign flush_o                      = current == REDMULE_FINISHED;
  assign cntrl_scheduler_o.rst        = current == REDMULE_FINISHED;
  assign cntrl_scheduler_o.finished   = current == REDMULE_FINISHED;
  assign latch_clear                  = current == REDMULE_LATCH_RST;

  always_comb begin : controller_fsm
    cntrl_flags_o.idle = 1'b0;
    cntrl_slave = '0;
    next = current;

    case (current)
      REDMULE_LATCH_RST: begin
        cntrl_flags_o.idle = 1'b1;
        next = REDMULE_IDLE;
      end

      REDMULE_IDLE: begin
        cntrl_flags_o.idle = 1'b1;
        if ((slave_start & tiler_valid) || test_mode_i) begin
          next = REDMULE_STARTING;
        end
      end

      REDMULE_STARTING: begin
        if (w_loaded_i) begin
          next = REDMULE_COMPUTING;
        end
      end

      REDMULE_COMPUTING: begin
        if (flgs_streamer_i.z_stream_sink_flags.done) begin
          next = REDMULE_FINISHED;
        end
      end

      REDMULE_FINISHED: begin
        next = REDMULE_IDLE;
        cntrl_slave.done = 1'b1;
      end
    endcase
  end

  /*---------------------------------------------------------------------------------------------*/
  /*                            Other combinational assigmnets                                   */
  /*---------------------------------------------------------------------------------------------*/
  assign evt_o   = flgs_slave.evt[7:0];
  assign clear_o = clear || latch_clear;

endmodule : redmule_ctrl
