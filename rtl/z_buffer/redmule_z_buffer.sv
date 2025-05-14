// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
// Andrea Belano <andrea.belano2@unibo.it>
//

module redmule_z_buffer
  import fpnew_pkg::*;
  import redmule_pkg::*;
#(
  parameter int unsigned           DW       = 288,
  parameter fpnew_pkg::fp_format_e FpFormat = fpnew_pkg::FP16,
  parameter int unsigned           Width    = ARRAY_WIDTH,   // Number of parallel index
  localparam int unsigned          BITW     = fpnew_pkg::fp_width(FpFormat), // Number of bits for the given format
  localparam int unsigned          W        = Width,
  localparam int unsigned          D        = DW/BITW
)(
  input  logic                             clk_i       ,
  input  logic                             rst_ni      ,
  input  logic                             clear_i     ,
  input  logic                             reg_enable_i,
  input  z_buffer_ctrl_t                   ctrl_i      ,
  input  logic           [W-1:0][BITW-1:0] z_buffer_i  ,
  input  logic                    [DW-1:0] y_buffer_i  ,
  output logic                    [DW-1:0] z_buffer_o  ,
  output logic           [W-1:0][BITW-1:0] y_buffer_o  ,
  output logic                  [DW/8-1:0] z_strb_o    ,
  output z_buffer_flgs_t                   flags_o
);

typedef enum logic [1:0] {
  EMPTY,
  LOADED,
  PUSHED
} redmule_z_state_e;

redmule_z_state_e current_state, next_state;

logic rst_fill   ,
      rst_w_load ,
      rst_d_count;

logic [$clog2(D)-1:0] fill_shift, d_index;
logic [$clog2(W)-1:0] store_shift_d, store_shift_q, w_index;

logic load_en, store_en;

logic [$clog2(TOT_DEPTH):0] z_height_tmp;
logic [$clog2(TOT_DEPTH)-1:0] z_height;

redmule_z_buffer_scm #(
  .WORD_SIZE ( BITW ),
  .ROWS      ( D    ),
  .COLS      ( W    )
) i_z_buf (
  .clk_i            ( clk_i                     ),
  .rst_ni           ( rst_ni                    ),
  .row_write_en_i   ( ctrl_i.fill               ),
  .col_write_en_i   ( load_en && ctrl_i.y_valid ),
  .row_write_addr_i ( fill_shift                ),
  .col_write_addr_i ( w_index                   ),
  .row_wdata_i      ( z_buffer_i                ),
  .col_wdata_i      ( y_buffer_i                ),
  .col_read_en_i    (  store_en && ctrl_i.ready ),
  .row_read_en_i    ( ctrl_i.y_push_enable      ),
  .col_read_addr_i  ( store_shift_d             ),
  .row_read_addr_i  ( d_index                   ),
  .col_rdata_o      ( z_buffer_o                ),
  .row_rdata_o      ( y_buffer_o                )
);

assign flags_o.y_ready = load_en && ctrl_i.y_valid;
assign flags_o.z_valid = store_en && ctrl_i.ready;
assign flags_o.z_priority = store_en;

always_ff @(posedge clk_i or negedge rst_ni) begin  : state_register
  if(~rst_ni) begin
    current_state <= EMPTY;
  end else begin
    if (clear_i) begin
      current_state <= EMPTY;
    end else begin
      current_state <= next_state;
    end
  end
end

always_comb begin : fsm
  next_state = current_state;

  case (current_state)
    EMPTY: begin
      if (w_index == ctrl_i.y_width-1 && load_en && ctrl_i.y_valid) begin
        next_state = LOADED;
      end

      // This handles the case where the height of the buffer is 1
      if (fill_shift == ctrl_i.z_height-1 && ctrl_i.fill) begin
        next_state = PUSHED;
      end
    end

    LOADED: begin
      if (d_index == ctrl_i.y_height-1 && ctrl_i.y_push_enable && ~ctrl_i.fill) begin
        next_state = EMPTY;
      end

      if (fill_shift == ctrl_i.z_height-1 && ctrl_i.fill) begin
        next_state = PUSHED;
      end
    end

    PUSHED: begin
      if (store_shift_q == ctrl_i.z_width-1 && store_en && ctrl_i.ready) begin
        next_state = EMPTY;
      end
    end
  endcase
end

// With very small leftovers on K it may happen that the z submatrix is completely stored before the current matrix of biases is fully pushed.
// Therefore, we have to check that we are not in the process of pushing biases into the array before storing
assign load_en  = current_state == EMPTY && ~ctrl_i.fill && d_index == '0;
assign store_en = current_state == PUSHED;

// Counter to track when the output buffer is full
always_ff @(posedge clk_i or negedge rst_ni) begin : buffer_fill_counter
  if(~rst_ni) begin
    fill_shift <= '0;
  end else begin
    if (rst_fill || clear_i)
      fill_shift <= '0;
    else if (ctrl_i.fill)
      fill_shift <= fill_shift + 1;
    else
      fill_shift <= fill_shift;
  end
end

// Reset for the fill value
always_comb begin : fill_shift_rst
  rst_fill      = 1'b0;
  if (fill_shift == ctrl_i.z_height-1 && ctrl_i.fill) begin
    rst_fill     = 1'b1;
  end else begin
    rst_fill     = 1'b0;
  end
end

// Counter to track the number of store rows
always_ff @(posedge clk_i or negedge rst_ni) begin : stored_rows_counter
  if(~rst_ni) begin
    store_shift_q <= '0;
  end else begin
    if (clear_i)
      store_shift_q <= '0;
    else if (store_en && ctrl_i.ready)
      store_shift_q <= store_shift_d;
    else
      store_shift_q <= store_shift_q;
  end
end

assign store_shift_d = store_shift_q == ctrl_i.z_width-1 ? '0 : store_shift_q + 1;

assign flags_o.empty = (store_shift_q == ctrl_i.z_width-1 && store_en && ctrl_i.ready) || (current_state == LOADED && d_index == ctrl_i.y_height-1 && ctrl_i.y_push_enable && ctrl_i.first_load);

// Counter to track the rows that have to be loaded
always_ff @(posedge clk_i or negedge rst_ni) begin : row_loaded_counter
  if(~rst_ni) begin
    w_index <= '0;
  end else begin
    if (rst_w_load || clear_i)
      w_index <= '0;
    else if (load_en && ctrl_i.y_valid)
      w_index <= w_index + 1;
    else
      w_index <= w_index;
  end
end

assign flags_o.loaded = current_state == EMPTY && w_index == ctrl_i.y_width-1 && ctrl_i.y_valid ||
                        current_state == LOADED;

always_comb begin : reset_y_load_counter
  rst_w_load     = 1'b0;
  if (w_index == ctrl_i.y_width-1 && load_en && ctrl_i.y_valid) begin
    rst_w_load     = 1'b1;
  end else begin
    rst_w_load     = 1'b0;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : depth_read_counter
  if(~rst_ni) begin
    d_index <= '0;
  end else begin
    if (rst_d_count || clear_i)
      d_index <= '0;
    else if (ctrl_i.y_push_enable)
      d_index <= d_index + 1;
    else
      d_index <= d_index;
  end
end

always_comb begin : reset_depth_counter
  rst_d_count    = 1'b0;
  flags_o.y_pushed = 1'b0;
  if (d_index == ctrl_i.y_height-1 && ctrl_i.y_push_enable) begin
    rst_d_count    = 1'b1;
    flags_o.y_pushed = 1'b1;
  end else begin
    rst_d_count    = 1'b0;
    flags_o.y_pushed = 1'b0;
  end
end

assign z_height_tmp = ctrl_i.z_height - 'd1;
assign z_height = z_height_tmp[$clog2(TOT_DEPTH)-1:0];

always_comb begin : z_strb_assignment
  z_strb_o = '0;
  for (int i = 0; i <= z_height; i++) begin
    z_strb_o[i*BITW/8+:BITW/8] = '1;
  end
end

endmodule : redmule_z_buffer
