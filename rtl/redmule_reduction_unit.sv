// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Andrea Belano <andrea.belano2@unibo.it>
//

/* This module performs a *row wise* reduction on the output matrix */

module redmule_reduction_unit
  import redmule_pkg::*;
#(
  parameter int unsigned           Width    = ARRAY_WIDTH,
  parameter int unsigned           Height   = ARRAY_HEIGHT,
  parameter int unsigned           PipeRegs = PIPE_REGS,
  parameter fpnew_pkg::fp_format_e FpFormat = fpnew_pkg::FP16,
  parameter int unsigned           MaxLat   = 0,
  parameter int unsigned           SumLat   = 1,

  localparam int unsigned          BITW     = fpnew_pkg::fp_width(FpFormat)
) (
  input  logic                             clk_i,
  input  logic                             rst_ni,
  input  logic                             clear_i,
  input  logic                             valid_i,
  input  cntrl_red_t                       ctrl_i,
  input  logic       [Width-1:0][BITW-1:0] data_i,
  input  logic       [Width-1:0][BITW-1:0] init_i,
  input  logic                             init_valid_i,
  output logic       [Width-1:0][BITW-1:0] red_o,
  output logic                             red_valid_o,
  output flgs_red_t                        flags_o
);

  localparam int unsigned RedLat = SumLat > MaxLat ? SumLat : MaxLat;

  logic [Width-1:0][BITW-1:0] red_q, red_d, neutral_d;

  logic [Width-1:0] red_valid;

  logic new_iter;
  logic red_valid_q;
  logic [15:0] row_elem_counter_d, row_elem_counter_q;
  logic [$clog2(RedLat+1)-1:0] op_counter_d, op_counter_q, sel_lat;
  logic op_counter_en;

  logic is_init_q;

  assign sel_lat = ctrl_i.op == MAX ? MaxLat : SumLat;

  always_ff @(posedge clk_i or negedge rst_ni) begin : is_init_register
    if (~rst_ni) begin
      is_init_q <= '0;
    end else begin
      if (clear_i) begin
        is_init_q <= '0;
      end else if ((~ctrl_i.load || (ctrl_i.load && init_valid_i)) && ~is_init_q && ctrl_i.enable) begin
        is_init_q <= '1;
      end else if (red_valid_q && ctrl_i.ready) begin
        is_init_q <= '0;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : op_counter
    if (~rst_ni) begin
      op_counter_q <= '0;
    end else begin
      if (clear_i) begin
        op_counter_q <= '0;
      end else begin
        op_counter_q <= op_counter_d;
      end
    end
  end

  assign op_counter_d = op_counter_en ? (op_counter_q == sel_lat ? '0 : op_counter_q+1) : op_counter_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin : row_elem_counter
    if (~rst_ni) begin
      row_elem_counter_q <= '0;
    end else begin
      if (clear_i) begin
        row_elem_counter_q <= '0;
      end else begin
        row_elem_counter_q <= row_elem_counter_d;
      end
    end
  end

  assign row_elem_counter_d = (op_counter_q == sel_lat) && op_counter_en ? (row_elem_counter_q == ctrl_i.row_len-1 ? '0 : row_elem_counter_q+1) : row_elem_counter_q;
  assign new_iter = (op_counter_q == sel_lat) && op_counter_en && (row_elem_counter_q == ctrl_i.row_len-1);

  always_ff @(posedge clk_i or negedge rst_ni) begin : res_valid_register
    if (~rst_ni) begin
      red_valid_q <= '0;
    end else begin
      if (clear_i | ctrl_i.ready && red_valid_q) begin
        red_valid_q <= '0;
      end else if (new_iter) begin
        red_valid_q <= '1;
      end
    end
  end

  assign red_valid_o = red_valid_q;

  // MAX //
  logic [Width-1:0][BITW-1:0] max_d;
  logic [Width-1:0]           max_out_valid;

  always_comb begin : max_assignment
    max_d = '0;
    max_out_valid = '0;

    for (int unsigned i = 0; i < Width; i++) begin
      if ((ctrl_i.op == MAX) && valid_i) begin
        if (data_i[i][BITW-1] < red_q[i][BITW-1]) begin
          max_d[i] = data_i[i];
          max_out_valid[i] = 1'b1;
        end else if (data_i[i][BITW-1] == red_q[i][BITW-1]) begin
          if (red_q[i][BITW-1] == 1'b0) begin
            if (data_i[i][BITW-2:0] > red_q[i][BITW-2:0]) begin
              max_d[i] = data_i[i];
              max_out_valid[i] = 1'b1;
            end
          end else begin
            if (data_i[i][BITW-2:0] < red_q[i][BITW-2:0]) begin
              max_d[i] = data_i[i];
              max_out_valid[i] = 1'b1;
            end
          end
        end
      end
    end
  end

  // SUM //
  logic [$clog2(SumLat+1)-1:0] sum_in_rr_counter_d, sum_in_rr_counter_q,
                               sum_out_rr_counter_d, sum_out_rr_counter_q;

  // Possibly FIXME
  logic [Width-1:0]           sum_out_valid, fifos_empty;
  logic [Width-1:0][BITW-1:0] sum_d;

  always_ff @(posedge clk_i or negedge rst_ni) begin : sum_in_counter
    if (~rst_ni) begin
      sum_in_rr_counter_q <= '0;
    end else begin
      if (clear_i | new_iter) begin
        sum_in_rr_counter_q <= '0;
      end else begin
        sum_in_rr_counter_q <= sum_in_rr_counter_d;
      end
    end
  end

  assign sum_in_rr_counter_d = ~&fifos_empty && (ctrl_i.op == SUM) ? (sum_in_rr_counter_q == SumLat ? '0 : sum_in_rr_counter_q + 1) : sum_in_rr_counter_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin : sum_out_counter
    if (~rst_ni) begin
      sum_out_rr_counter_q <= '0;
    end else begin
      if (clear_i | new_iter) begin
        sum_out_rr_counter_q <= '0;
      end else begin
        sum_out_rr_counter_q <= sum_out_rr_counter_d;
      end
    end
  end

  assign sum_out_rr_counter_d = |sum_out_valid && (ctrl_i.op == SUM) ? (sum_out_rr_counter_q == SumLat ? '0 : sum_out_rr_counter_q + 1) : sum_out_rr_counter_q;

  for (genvar i = 0; i < Width; i += SumLat+1) begin : gen_sum
    logic [SumLat:0][BITW-1:0] sum_fifo_d, sum_fifo_q;
    logic [2:0][BITW-1:0]      operands;
    logic [SumLat:0]           fifo_empty;

    logic [BITW-1]             sum_tmp;
    logic                      sum_valid_tmp;

    assign operands [0] = '0;
    assign operands [1] = red_q[i+sum_in_rr_counter_q];
    assign operands [2] = sum_fifo_q[sum_in_rr_counter_q];

    for (genvar j = 0; j < SumLat+1; j++) begin : gen_inp_fifos
      assign sum_fifo_d[j] = data_i[i+j];

      fifo_v3 #(
        .FALL_THROUGH ( 1                                                             ),
        .DATA_WIDTH   ( BITW                                                          ),
        .DEPTH        ( (PipeRegs+1)*Height-((PipeRegs+1)*Height+SumLat)/(SumLat+1)+1 )
      ) sum_fifo (
        .clk_i      ( clk_i                                        ),
        .rst_ni     ( rst_ni                                       ),
        .flush_i    ( clear_i                                      ),
        .testmode_i ( '0                                           ),
        .full_o     (                                              ),
        .empty_o    ( fifo_empty[j]                                ),
        .usage_o    (                                              ),
        .data_i     ( sum_fifo_d[j]                                ),
        .push_i     ( valid_i && (ctrl_i.op == SUM)                ),
        .data_o     ( sum_fifo_q[j]                                ),
        .pop_i      ( ~fifo_empty[j] && (sum_in_rr_counter_q == j) )
      );

      assign fifos_empty[i+j] = fifo_empty[j];
    end

    redmule_fma   #(
      .FpFormat    ( FpFormat               ),
      .NumPipeRegs ( SumLat                 ),
      .PipeConfig  ( fpnew_pkg::DISTRIBUTED ),
      .Stallable   ( 0                      )
    ) i_sum (
      .clk_i           ( clk_i                    ),
      .rst_ni          ( rst_ni                   ),
      .operands_i      ( operands                 ),
      .is_boxed_i      ( '1                       ),
      .rnd_mode_i      ( fpnew_pkg::RNE           ),
      .op_i            ( fpnew_pkg::ADD           ),
      .op_mod_i        ( '0                       ),
      .tag_i           ( '0                       ),
      .aux_i           ( '0                       ),
      .in_valid_i      ( ~&fifo_empty             ),
      .in_ready_o      (                          ),
      .reg_enable_i    ( '1                       ),
      .flush_i         ( clear_i                  ),
      .result_o        ( sum_tmp                  ),
      .out_valid_o     ( sum_valid_tmp            ),
      .out_ready_i     ( '1                       ),
      .busy_o          (                          )
    );

    // Set the reamining sum_d and sum_out_valid elements to 0
    for (genvar j = 0; j < SumLat+1; j++) begin : assign_sum
      assign sum_d[i+j]         = sum_out_rr_counter_q == j ? sum_tmp       : '0;
      assign sum_out_valid[i+j] = sum_out_rr_counter_q == j ? sum_valid_tmp : '0;
    end
  end

  always_comb begin : red_assignment
    red_d = '0;
    red_valid = '0;

    unique case (ctrl_i.op)
      SUM: begin
        red_d         = sum_d;
        red_valid     = sum_out_valid;
        op_counter_en = |red_valid;
      end
      MAX: begin
        red_d         = max_d;
        red_valid     = max_out_valid;
        op_counter_en = valid_i;
      end
      default: begin
        red_d         = '0;
        red_valid     = '0;
        op_counter_en = '0;
      end
    endcase
  end

  always_comb begin : neutral_element_assignment
    unique case (ctrl_i.op)
      SUM     : neutral_d = '0;
      MAX     : neutral_d = '1; // To keep things simple we do not treat NaNs differently
      default : neutral_d = '0;
    endcase
  end

  for (genvar i = 0; i < Width; i++) begin : gen_red_registers
    always_ff @(posedge clk_i or negedge rst_ni) begin : red_register
      if (~rst_ni) begin
        red_q[i] <= '0;
      end else begin
        if (clear_i) begin
          red_q[i] <= '0;
        end else if (~ctrl_i.load && ~is_init_q) begin
          red_q[i] <= neutral_d;
        end else if (ctrl_i.load && init_valid_i && ~is_init_q) begin
          red_q[i] <= init_i[i];
        end else if (red_valid[i]) begin
          red_q[i] <= red_d[i];
        end
      end
    end
  end

  assign red_o = red_q;

  assign flags_o.is_initialized = is_init_q;

endmodule