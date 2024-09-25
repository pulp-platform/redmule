// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
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
  localparam int unsigned TILE          = (NumPipeRegs +1)*Height,
  localparam int unsigned W_ITERS       = redmule_pkg::W_ITERS                ,
  localparam int unsigned LEFT_PARAMS   = redmule_pkg::LEFT_PARAMS
)(
  input  logic                    clk_i             ,
  input  logic                    rst_ni            ,
  input  logic                    test_mode_i       ,
  output logic                    busy_o            ,
  output logic                    clear_o           ,
  output logic [N_CORES-1:0][1:0] evt_o             ,
  output logic                    z_fill_o          ,
  output logic                    w_shift_o         ,
  output logic                    z_buffer_clk_en_o ,
  output ctrl_regfile_t           reg_file_o        ,
  input  logic                    reg_enable_i      ,
  input  logic                    start_cfg_i       ,
  output logic                    cfg_complete_o    ,
  // Flags coming from the wrap registers
  input  z_buffer_flgs_t          flgs_z_buffer_i   ,
  // Flags coming from the engine
  input  flgs_engine_t            flgs_engine_i     ,
  // Flags coming from the state machine
  input  logic                    w_loaded_i        ,
  // Control signals for the engine
  output logic                    flush_o           ,
  output logic                    accumulate_o      ,
  // Control signals for the state machine
  output cntrl_scheduler_t        cntrl_scheduler_o ,
  // Peripheral slave port
  hwpe_ctrl_intf_periph.slave     periph
);

  logic        clear;
  logic        accumulate_q;
  logic        w_computed_en, w_computed_rst, count_w_q, accumulate_en, accumulate_rst, storing_rst;
  logic        last_w_row, last_w_row_en, last_w_row_rst;
  logic        z_buffer_clk_en;
  logic        enable_depth_count, reset_depth_count;
  logic        tiler_setback, tiler_valid;
  logic [4:0]  w_computed;
  logic [15:0] w_rows;
  logic [15:0] w_rows_iter, w_row_count_d, w_row_count_q;
  logic [15:0] z_storings_d, z_storings_q, tot_stores, issued_store_d, issued_store_q;

  typedef enum logic [2:0] {
    REDMULE_IDLE,
    REDMULE_STARTING,
    REDMULE_COMPUTING,
    REDMULE_BUFFERING,
    REDMULE_STORING,
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
       current <= REDMULE_IDLE;
    end else begin
      if (clear)
        current <= REDMULE_IDLE;
      else
        current <= next;
    end
  end

  // This register counts the number of weight rows loaded
  always_ff @(posedge clk_i or negedge rst_ni) begin : weight_rows_counter
    if(~rst_ni) begin
      w_row_count_q <= '0;
    end else begin
      if (clear)
        w_row_count_q <= '0;
      else
        w_row_count_q <= w_row_count_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      count_w_q <= 1'b0;
    end else begin
      if (clear || w_computed_rst)
          count_w_q <= 1'b0;
      else if (w_computed_en)
          count_w_q <= 1'b1;
    end
  end

  // This one counts how many weights have been computed by the last
  // PE in each row of the array
  always_ff @(posedge clk_i or negedge rst_ni) begin : w_computed_counter
    if(~rst_ni) begin
      w_computed <= '0;
    end else begin
      if (w_computed_rst || clear)
        w_computed <= '0;
      else if (count_w_q && reg_enable_i)
        w_computed <= w_computed + 1;
    end
  end

  logic accumulate_ctrl_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      accumulate_ctrl_q <= 1'b0;
    end else begin
      if (clear || reg_enable_i)
        accumulate_ctrl_q <= 1'b0;
      else if (!reg_enable_i && !accumulate_q)
        accumulate_ctrl_q <= 1'b1;
    end
  end

  // This register generates the accumulation signal for the engine
  always_ff @(posedge clk_i or negedge rst_ni) begin : accumale_sampler
    if(~rst_ni) begin
      accumulate_q <= 1'b0;
    end else begin
      if (accumulate_rst || clear)
        accumulate_q <= 1'b0;
      else if (accumulate_en)
        accumulate_q <= 1'b1;
    end
  end
  assign accumulate_o =  accumulate_q & !accumulate_ctrl_q;

  logic finish_d, finish_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin : finish_sampler
    if(~rst_ni) begin
      finish_q <= 1'b0;
    end else begin
      if (clear)
        finish_q <= 1'b0;
      else
        finish_q <= finish_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : last_w_row_reg
    if(~rst_ni) begin
      last_w_row <= 1'b0;
    end else begin
      if (last_w_row_rst || clear)
        last_w_row <= 1'b0;
      else if (last_w_row_en)
        last_w_row <= 1'b1;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : issued_store
    if(~rst_ni) begin
      issued_store_q <= '0;
    end else begin
      if (clear)
        issued_store_q <= '0;
      else
        issued_store_q <= issued_store_d;
    end
  end

  // This register counts the number of times we exit from the REDMULE_STORING
  // state and go to the REDMULE_COMPUTING one. Every time this happens, it
  // means that a piece of computation fas done, and we can track the number
  // the number of storage operations to see when the last one occurs
  always_ff @(posedge clk_i or negedge rst_ni) begin : out_storings_counter
    if(~rst_ni) begin
      z_storings_q <= '0;
    end else begin
      if (clear || storing_rst)
        z_storings_q <= '0;
      else
        z_storings_q <= z_storings_d;
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
  assign w_rows_iter = reg_file_q.hwpe_params [W_ITERS    ][31:16];
  assign tot_stores  = reg_file_q.hwpe_params [LEFT_PARAMS][31:16];
  assign reg_file_o = reg_file_q;
  assign z_buffer_clk_en_o = z_buffer_clk_en;

  /*---------------------------------------------------------------------------------------------*/
  /*                                        Controller FSM                                       */
  /*---------------------------------------------------------------------------------------------*/
  // This is a local FSM who's only work is to make the first
  // input load operation and to start the redmule_scheduler
  always_comb begin : controller_fsm
    tiler_setback      = 1'b0;
    cntrl_scheduler_o  = '0;
    cntrl_slave        = '0;
    // Engine default control signals assignment
    flush_o            = 1'b0;
    // Other local default signals
    w_shift_o          = 1'b1;
    z_fill_o           = 1'b0;
    busy_o             = 1'b1;
    w_computed_en      = 1'b0;
    w_computed_rst     = 1'b0;
    last_w_row_en      = 1'b0;
    last_w_row_rst     = 1'b0;
    w_row_count_d      = w_row_count_q;
    z_storings_d       = z_storings_q;
    issued_store_d     = issued_store_q;
    finish_d           = finish_q;
    accumulate_en      = 1'b0;
    accumulate_rst     = 1'b0;
    storing_rst        = 1'b0;
    z_buffer_clk_en    = '0;
    enable_depth_count = '0;
    reset_depth_count  = '0;
    next               = current;

    case (current)
      REDMULE_IDLE: begin
        w_shift_o = 1'b0;
        busy_o    = 1'b0;
        z_storings_d = '0;
        w_row_count_d  = '0;
        if (clear)
          z_buffer_clk_en = 1'b1;
        if ( (slave_start & tiler_valid) || test_mode_i) begin
          tiler_setback = 1'b1;
          finish_d = 1'b0;
          next = REDMULE_STARTING;
        end
        else
          next = REDMULE_IDLE;
      end

      REDMULE_STARTING: begin
        w_shift_o              = 1'b0;
        cntrl_scheduler_o.first_load = 1'b1;
        if (w_loaded_i) begin
          next = REDMULE_COMPUTING;
          w_row_count_d = w_row_count_q + 1;
        end else
          next = REDMULE_STARTING;
      end

      REDMULE_COMPUTING: begin
        if (w_loaded_i)
          w_row_count_d = w_row_count_q + 1;

        if (w_row_count_d == Height && !count_w_q)
          w_computed_en = 1'b1;
        else if (w_row_count_q == w_rows_iter) begin
          if (!count_w_q)
            w_computed_en = 1'b1;
          if (!last_w_row)
            last_w_row_en = 1'b1;
        end

        case (last_w_row)
          1'b0: begin
            if (w_computed == NumPipeRegs) begin
              if (!accumulate_q && !finish_q)
                  accumulate_en = 1'b1;
              if (count_w_q)
                  w_computed_rst = 1'b1;
            end
          end

          1'b1: begin
            if (w_computed == NumPipeRegs - 1 && reg_enable_i) begin
              w_row_count_d = 16'd1;
              issued_store_d = issued_store_q + 'd1;
              next = REDMULE_BUFFERING;
              if (accumulate_q) begin
                accumulate_rst = 1'b1;
                finish_d = (issued_store_q == tot_stores - 1) ? 1'b1 : 1'b0;
              end
              if (count_w_q)
                w_computed_rst = 1'b1;
            end else
              next = REDMULE_COMPUTING;
          end
        endcase
      end

      REDMULE_BUFFERING: begin
        z_buffer_clk_en = 1'b1;
        if (last_w_row)
          last_w_row_rst = 1'b1;
        if (w_loaded_i)
          w_row_count_d = w_row_count_q + 1;
          z_fill_o = reg_enable_i;
        if (flgs_z_buffer_i.full) begin
          accumulate_en = finish_q ? 1'b0 : 1'b1;
          next = REDMULE_STORING;
        end
        else
          next = REDMULE_BUFFERING;
      end

      REDMULE_STORING: begin
        cntrl_scheduler_o.storing = 1'b1;

        if (w_loaded_i)
          w_row_count_d = w_row_count_q + 1;

        if (flgs_z_buffer_i.empty) begin
          z_storings_d = z_storings_q + 1;
          if (z_storings_q == tot_stores - 1) begin
            next = REDMULE_FINISHED;
            storing_rst = 1'b1;
            cntrl_scheduler_o.finished = 1'b1;
          end else
          if (z_storings_q < tot_stores) begin
            next = REDMULE_COMPUTING;
          end
        end
      end

      REDMULE_FINISHED: begin
        cntrl_slave.done = 1'b1;
        busy_o           = 1'b0;
        flush_o          = 1'b1;
        cntrl_scheduler_o.rst  = 1'b1;
        cntrl_scheduler_o.finished = 1'b1;
        next = REDMULE_IDLE;
        // Reset for all the registers
        w_row_count_d  = '0;
        w_computed_rst = 1'b1;
        accumulate_rst = 1'b1;
        last_w_row_rst = 1'b1;
        storing_rst    = 1'b1;
      end
    endcase
  end

  /*---------------------------------------------------------------------------------------------*/
  /*                            Other combinational assigmnets                                   */
  /*---------------------------------------------------------------------------------------------*/
  assign evt_o   = flgs_slave.evt[7:0];
  assign clear_o = clear;

endmodule : redmule_ctrl
