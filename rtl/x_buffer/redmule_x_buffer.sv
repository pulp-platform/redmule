// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
// Andrea Belano <andrea.belano2@unibo.it>
//

module redmule_x_buffer
  import fpnew_pkg::*;
  import redmule_pkg::*;
#(
parameter int unsigned           DW        = 288,
parameter fpnew_pkg::fp_format_e FpFormat  = fpnew_pkg::FP16,
parameter int unsigned           Height    = ARRAY_HEIGHT,  // Number of PEs per row
parameter int unsigned           Width     = ARRAY_WIDTH,   // Number of parallel index
localparam int unsigned          BITW      = fpnew_pkg::fp_width(FpFormat), // Number of bits for the given format
localparam int unsigned          H         = Height,
localparam int unsigned          W         = Width,
localparam int unsigned          D         = DW/(H*BITW),
localparam int unsigned          HALF_D    = D/2,
localparam int unsigned          TOT_DEPTH = H*D
)(
  input  logic                                               clk_i      ,
  input  logic                                               rst_ni     ,
  input  logic                                               clear_i    ,
  input  x_buffer_ctrl_t                                     ctrl_i     ,
  output x_buffer_flgs_t                                     flags_o    ,
  output logic                      [W-1:0][H-1:0][BITW-1:0] x_buffer_o ,
  input  logic                                      [DW-1:0] x_buffer_i
);

typedef enum logic [2:0] {
  PRELOAD,
  FAST_FILL,
  WAIT_FIRST_READ,
  WAIT_SHIFT,
  FILL,
  PAD_EMPTY
} redmule_x_state_e;

logic [$clog2(W):0]             w_index_d, w_index_q;
logic [$clog2(H)-1:0]           h_index_r, h_index_w;
logic [W-1:0][BITW-1:0]         x_pad_q;
logic [H-1:0][W-1:0][BITW-1:0]  x_buffer_q;

logic [$clog2(TOT_DEPTH)-1:0]   pad_r_addr_d, pad_r_addr_q;
logic                           buf_r_addr, buf_w_addr;

logic [$clog2(TOT_DEPTH):0]     pad_read_cnt;
logic                           pad_read_cnt_rst;

logic [$clog2(2*H):0]           buf_write_cnt;

logic                           pad_read_en,
                                buf_write_en;

logic [$clog2(TOT_DEPTH)-1:0]   pad_read_addr;

redmule_x_state_e               current_state, next_state;

logic                           first_block,
                                refilling;

always_ff @(posedge clk_i or negedge rst_ni) begin : first_block_register
  if(~rst_ni) begin
    first_block <= '0;
  end else begin
    if (clear_i || pad_r_addr_q == 2*H-1)
      first_block <= '0;
    else if (ctrl_i.pad_setup)
      first_block <= '1;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : refill_flag_register
  if(~rst_ni) begin
    refilling <= '1;
  end else begin
    if (clear_i)
      refilling <= '1;
    else if (flags_o.full)
      refilling <= '0;
    else if (flags_o.empty)
      refilling <= '1;
  end
end

assign pad_read_en   = buf_write_en || ctrl_i.pad_setup;
assign pad_read_addr = ctrl_i.pad_setup ? '0 : pad_r_addr_d;

redmule_x_pad_scm #(
  .WORD_SIZE ( BITW      ),
  .ROWS      ( W         ),
  .COLS      ( TOT_DEPTH )
) i_x_pad (
  .clk_i        ( clk_i                     ),
  .rst_ni       ( rst_ni                    ),
  .clear_i      ( clear_i                   ),
  .write_en_i   ( ctrl_i.load               ),
  .write_addr_i ( w_index_q [$clog2(W)-1:0] ),
  .wdata_i      ( x_buffer_i                ),
  .read_en_i    ( pad_read_en               ),
  .read_addr_i  ( pad_read_addr             ),
  .rdata_o      ( x_pad_q                   )
);

// Normally, we only write a row in the buffer when another one is read
// In the FAST_FILL state we write a new row in the buffer every cycle until it is full
assign buf_write_en = ( current_state == FAST_FILL ||
                        current_state == FILL && ctrl_i.h_shift)
                      && ~refilling;

redmule_x_buffer_scm #(
  .WORD_SIZE ( BITW ),
  .WIDTH     ( W    ),
  .HEIGHT    ( 2    ),
  .N_OUTPUTS ( H    )
) i_x_buf (
  .clk_i        ( clk_i                                        ),
  .rst_ni       ( rst_ni                                       ),
  .clear_i      ( clear_i                                      ),
  .write_en_i   ( buf_write_en                                 ),
  .write_addr_i ( {buf_w_addr, h_index_w}                      ),
`ifdef PACE_ENABLED
  .wdata_i      ( ctrl_i.pace_mode ? x_pad_q: (pad_read_cnt <= ctrl_i.height ? x_pad_q : '0) ),
`else
  .wdata_i      ( pad_read_cnt <= ctrl_i.height ? x_pad_q : '0 ),
`endif 
  .read_en_i    ( ctrl_i.h_shift                               ),
  .read_addr_i  ( {buf_r_addr, h_index_r}                      ),
  .rdata_o      ( x_buffer_q                                   )
);

always_ff @(posedge clk_i or negedge rst_ni) begin  : state_register
  if(~rst_ni) begin
    current_state <= PRELOAD;
  end else begin
    if (clear_i) begin
      current_state <= PRELOAD;
    end else begin
      current_state <= next_state;
    end
  end
end

always_comb begin : fsm
  next_state = current_state;

  case (current_state)
    PRELOAD: begin
      if (ctrl_i.pad_setup) begin
        next_state = FAST_FILL;
      end
    end

    FAST_FILL: begin
      // As buf_write_cnt increments one cycle late, we have to check if its value is set to increase in the next cycle
      if (pad_r_addr_q == buf_write_cnt-1 && (~ctrl_i.h_shift || first_block || (pad_read_cnt == ctrl_i.slots))) begin
        if (pad_read_cnt == ctrl_i.slots) begin
          if (~flags_o.full) begin
            next_state = PAD_EMPTY;
          end else begin
            next_state = WAIT_FIRST_READ;
          end
        end else if (first_block) begin
          next_state = WAIT_FIRST_READ;
        end else begin
          if (pad_read_cnt == ctrl_i.slots) begin // There is nothing more to read inside the pad, we just have to assert the empty flag once we are read
            next_state = WAIT_SHIFT;
          end else begin
            next_state = FILL;
          end
        end
      end
    end

    WAIT_FIRST_READ: begin
      if (h_index_r == H-1 && ctrl_i.h_shift) begin
        if (ctrl_i.rst_w_index) begin
          next_state = PAD_EMPTY;
        end  else begin
          next_state = FILL;
        end
      end
    end

    WAIT_SHIFT: begin // The pad is empty but we are waiting for the first h_shift to assert the empty flag
      if (ctrl_i.h_shift) begin
        next_state = PAD_EMPTY;
      end
    end

    FILL: begin
      if (flags_o.empty) begin
        // If the width of the buffer is 1, the full flag is asserted at the same time as the empty flag so we skip the PAD_EMPTY state
        if (flags_o.full) begin
          next_state = FILL;
        end else begin
          next_state = PAD_EMPTY;
        end
      end
    end

    PAD_EMPTY: begin
      if (flags_o.full) begin
        if (buf_write_cnt != '0 || ctrl_i.h_shift) begin
          next_state = FAST_FILL;
        end else begin
          next_state = FILL;
        end
      end
    end
  endcase
end

always_ff @(posedge clk_i or negedge rst_ni) begin : x_pad_read_pointer
  if(~rst_ni) begin
    pad_r_addr_q <= '0;
  end else begin
    if (clear_i)
      pad_r_addr_q <= '0;
    else if (buf_write_en)
      pad_r_addr_q <= pad_r_addr_d;
  end
end

assign pad_r_addr_d = (pad_r_addr_q < ctrl_i.slots-1) ? pad_r_addr_q + 1 : '0;

// Counter to track the rows that have to be loaded
always_ff @(posedge clk_i or negedge rst_ni) begin : row_loaded_counter
  if(~rst_ni) begin
    w_index_q <= '0;
  end else begin
    // The rst signal is externally supplied, as the full flag has to stay asserted until the scheduler acknowledges it
    if (ctrl_i.rst_w_index || clear_i)
      w_index_q <= '0;
    else if (ctrl_i.load)
      w_index_q <= w_index_d;
    else
      w_index_q <= w_index_q;
  end
end

assign w_index_d = ctrl_i.load ? w_index_q + 1 : w_index_q;

assign flags_o.full = w_index_q == ctrl_i.width;


always_ff @(posedge clk_i or negedge rst_ni) begin : pad_read_counter
  if(~rst_ni) begin
    pad_read_cnt <= '0;
  end else begin
    if (clear_i)
      pad_read_cnt <= '0;
    else begin
      if (pad_read_cnt_rst)
        pad_read_cnt <= 1;
      else if (pad_read_en)
        pad_read_cnt <= pad_read_cnt + 1;
    end
  end
end

assign pad_read_cnt_rst = (pad_read_cnt >= ctrl_i.slots) && ctrl_i.h_shift;
assign flags_o.empty    = pad_read_cnt_rst;

// This counts the number of times we have to write the buffer to fill it during the FAST_FILL state
always_ff @(posedge clk_i or negedge rst_ni) begin : buf_write_counter
  if(~rst_ni) begin
    buf_write_cnt <= '0;
  end else begin
    if (clear_i || pad_read_cnt_rst)
      buf_write_cnt <= '0;
    else begin
      if ((current_state == PAD_EMPTY || current_state == FAST_FILL && ~first_block) && ctrl_i.h_shift)
        buf_write_cnt <= buf_write_cnt + 1;
      else if (ctrl_i.pad_setup)
        buf_write_cnt <= 2*H;
    end
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : h_index_r_register
  if(~rst_ni) begin
    h_index_r <= '0;
  end else begin
    if (clear_i)
      h_index_r <= '0;
    else if(ctrl_i.h_shift)
      h_index_r <= h_index_r == H-1 ? '0 : h_index_r + 1;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : buffer_read_address
  if(~rst_ni) begin
    buf_r_addr <= '0;
  end else begin
    if (clear_i)
      buf_r_addr <= '0;
    else if (h_index_r == H-1 && ctrl_i.h_shift)
      buf_r_addr <= buf_r_addr + 1;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : h_index_w_register
  if(~rst_ni) begin
    h_index_w <= '0;
  end else begin
    if (clear_i)
      h_index_w <= '0;
    else if(buf_write_en)
      h_index_w <= h_index_w == H-1 ? '0 : h_index_w + 1;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : buffer_write_address
  if(~rst_ni) begin
    buf_w_addr <= '0;
  end else begin
    if (clear_i)
      buf_w_addr <= '0;
    else if (h_index_w == H-1 && buf_write_en)
      buf_w_addr <= buf_w_addr + 1;
  end
end

assign next_wrow_ready_o = pad_read_en;

// Output assignment
// verilog_lint: waive-start generate-label
generate
  for (genvar w = 0; w < W; w++) begin
    for (genvar h = 0; h < H; h++) begin
      assign x_buffer_o[w][h] = x_buffer_q[h][w];
    end
  end
endgenerate
// verilog_lint: waive-stop generate-label

endmodule : redmule_x_buffer
