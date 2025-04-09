// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Andrea Belano <andrea.belano2@unibo.it>
//

module redmule_gidx_buffer
  import fpnew_pkg::*;
  import redmule_pkg::*;
#(
parameter int unsigned           DW          = 256,
parameter int unsigned           GID_WIDTH   = GROUP_ID_WIDTH,
parameter fpnew_pkg::fp_format_e FpFormat    = fpnew_pkg::FP16,
parameter int unsigned           Height      = ARRAY_HEIGHT,  // Number of PEs per row
localparam int unsigned          BITW        = fpnew_pkg::fp_width(FpFormat), // Number of bits for the given format
localparam int unsigned          H           = Height,
localparam int unsigned          G           = GID_WIDTH,
localparam int unsigned          D           = DW/(H*BITW)
)(
  input  logic                                               clk_i          ,
  input  logic                                               rst_ni         ,
  input  logic                                               clear_i        ,
  input  gidx_buffer_ctrl_t                                  ctrl_i         ,
  output gidx_buffer_flgs_t                                  flags_o        ,
  input  logic                            [DW/G-1:0][G-1:0]  gidx_buffer_i  ,
  input  logic                                               gidx_valid_i   ,
  output logic                                               out_valid_o    ,
  output logic                               [GID_WIDTH:0]   next_gidx_o    ,
  output logic                             [$clog2(D*H)-1:0] next_wrow_o    , //Tentative name
  output logic                                               gidx_ready_o   ,
  input  logic                                               out_ready_i
);

  // FIXME I DON'T WORK WITH LEFTOVERS!!!

  logic [H+D*H-1:0][G-1:0] target;
  logic [H-1:0][G-1:0] last_gidx_d, last_gidx_q;

  logic [H-1:0] last_gidx_valid_q;
  logic [$clog2(H)-1:0] evict_pointer;
  logic [H-1:0][$clog2(D*H/(PIPE_REGS+1)):0] usage_counter_q;
  logic gidx_present_d, gidx_present_q;


  logic lookahead_offset_en, lookahead_offset_rst;
  logic [$clog2(H+D*H)-1:0] lookahead_offset_d, lookahead_offset_q;
  logic [D*H-1:0] lookahead_matches_d, lookahead_matches_q;

  logic [G-1:0] current_gidx_d, current_gidx_q;

  logic lookahead_fifo_full, lookahead_fifo_push;
  logic lookahead_fifo_empty, lookahead_fifo_pop;

  logic [$clog2(H)-1:0] last_gidx_wptr_d, last_gidx_wptr_q;

  logic [H*D-1:0] match_msk_d, match_msk_q;

  /*  STEP 1  */

  // Write side
  for (genvar h = 0; h < H; h++) begin : gen_w_id_registers
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if(~rst_ni) begin
        last_gidx_q[h]       <= '0;
        last_gidx_valid_q[h] <= '0;
      end else begin
        if (clear_i) begin
          last_gidx_q[h]       <= '0;
          last_gidx_valid_q[h] <= '0;
        end else if (evict_pointer == h && lookahead_fifo_push/*ctrl_i.load*/ /*&& ctrl_i.dequant*/ && ~gidx_present_d) begin   // This is loaded at the same time as the W row
          last_gidx_q[h]       <= target[lookahead_offset_q];//next_gidx_i;
          last_gidx_valid_q[h] <= '1;
        end
      end
    end

    // assign cache_w_id_d[h]       = (evict_pointer == h && lookahead_fifo_push /*&& ctrl_i.dequant*/ && ~gidx_present_d) ? next_gidx_i : last_gidx_q[h];
    // assign cache_w_id_valid_d[h] = (evict_pointer == h && lookahead_fifo_push /*&& ctrl_i.dequant*/ && ~gidx_present_d) ? '1 : last_gidx_valid_q[h];
  end

  always_comb begin : evict_pointer_assignment
    evict_pointer = '0;

    for (int h = 0; h < H; h++) begin
      if (last_gidx_valid_q[h] == '0) begin
        evict_pointer = h;
        break;
      end
    end

    if (&last_gidx_valid_q) begin
      for (int h = 0; h < H; h++) begin
        if (usage_counter_q[h] == '0) begin
          evict_pointer = h;
          break;
        end
      end
    end
  end

  // Each row of the buffer has a counter that
  // resets to D/(PIPE_REGS+1) each time the vector is requested
  for (genvar h = 0; h < H; h++) begin : gen_usage_counters
    always_ff @(posedge clk_i or negedge rst_ni) begin
      if(~rst_ni) begin
        usage_counter_q[h] <= '0;
      end else begin
        if (clear_i)
          usage_counter_q[h] <= '0;
        else if (/*ctrl_i.dequant &&*/ (evict_pointer == h && ~gidx_present_d || gidx_present_d && last_gidx_q[h]/*cache_w_id_q[h]*/ == target[lookahead_offset_q]/*next_gidx_i*/) && lookahead_fifo_push/*ctrl_i.load*/)
          usage_counter_q[h] <= D*H/(PIPE_REGS+1);
        else if (/*ctrl_i.dequant &&*/ /*el_addr_q == PIPE_REGS &&*/ usage_counter_q[h] != 0 && lookahead_fifo_push/*ctrl_i.shift*/)
          usage_counter_q[h] <= usage_counter_q[h] - (PIPE_REGS+1);
      end
    end
  end

  always_comb begin : gidx_present_assignment
    gidx_present_d = '0;

    for (int h = 0; h < H; h++) begin
      if (last_gidx_q[h]/*cache_w_id_q[h]*/ == target[lookahead_offset_q]/*next_gidx_i*/ && last_gidx_valid_q[h]/*cache_w_id_valid_q[h]*/) begin
        gidx_present_d = '1;
        break;
      end
    end
  end




  always_comb begin
    match_msk_d = match_msk_q;

    if (lookahead_offset_en) begin
      /*if (lookahead_offset_rst) begin
        match_msk_d = '1;
      end else begin */
        match_msk_d = match_msk_q ^ lookahead_matches_d;
      //end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      match_msk_q <= '1;
    end else begin
      if (clear_i || lookahead_offset_rst) begin
        match_msk_q <= '1;
      end else begin
        match_msk_q <= match_msk_d;
      end
    end
  end

  assign target = {gidx_buffer_i, last_gidx_q};

  assign lookahead_offset_en  = gidx_valid_i && ~lookahead_fifo_full;
  assign lookahead_fifo_push  = gidx_valid_i && ~lookahead_fifo_full && |lookahead_matches_d;

  assign lookahead_offset_rst = lookahead_offset_q == H+D*H-1 || ~|match_msk_d;

  assign lookahead_offset_d   = lookahead_offset_en ? (lookahead_offset_rst ? '0 : lookahead_offset_q + 1) : lookahead_offset_q;

  assign gidx_ready_o         = lookahead_offset_en && lookahead_offset_rst;

  always_comb begin
    lookahead_matches_d = '0;

    for (int unsigned i = 0; i < D*H; i++) begin
      lookahead_matches_d[i] = target[lookahead_offset_q] == gidx_buffer_i[i] & match_msk_q[i];
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      lookahead_offset_q <= H;
    end else begin
      if (clear_i) begin
        lookahead_offset_q <= H;
      end else begin
        lookahead_offset_q <= lookahead_offset_d;
      end
    end
  end

  assign current_gidx_d = target[lookahead_offset_q];

  fifo_v3 #(
    .DATA_WIDTH ( G+D*H+1 ),
    .DEPTH      ( 4       )
  ) i_lookahead_fifo (
    .clk_i      ( clk_i                                                 ),
    .rst_ni     ( rst_ni                                                ),
    .flush_i    ( clear_i                                               ),
    .testmode_i ( '0                                                    ),
    .full_o     ( lookahead_fifo_full                                   ),
    .empty_o    ( lookahead_fifo_empty                                  ),
    .data_i     ( {gidx_present_d, current_gidx_d, lookahead_matches_d} ),
    .push_i     ( lookahead_fifo_push                                   ),
    .data_o     ( {gidx_present_q, current_gidx_q, lookahead_matches_q} ),
    .pop_i      ( lookahead_fifo_pop                                    )
  );

  logic [H*D-1:0] order_msk_d, order_msk_q;
  logic order_msk_rst;
  logic [$clog2(H*D)-1:0] match_ptr;
  logic new_match;

  /*  STEP 2  */

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      order_msk_q <= '1;
    end else begin
      if (clear_i || order_msk_rst) begin
        order_msk_q <= '1;
      end else if (out_ready_i && ~lookahead_fifo_empty) begin
        order_msk_q <= order_msk_d;
      end
    end
  end

  always_comb begin
    match_ptr     = '1;
    order_msk_d   = order_msk_q;
    order_msk_rst = '0;

    for (int unsigned i = 0; i < H*D; i++) begin
      if (lookahead_matches_q[i] & order_msk_q[i] == 1'b1) begin
        match_ptr      = i;
        order_msk_d[i] = 1'b0;
        break;
      end
    end

    if (((lookahead_matches_q & order_msk_d) == '0) && out_ready_i) begin
      order_msk_rst = '1;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      new_match <= '1;
    end else begin
      if (clear_i || lookahead_fifo_pop) begin
        new_match <= '1;
      end else if (~lookahead_fifo_empty && out_ready_i) begin
        new_match <= '0;
      end
    end
  end

  assign lookahead_fifo_pop = out_ready_i && ~lookahead_fifo_empty && order_msk_rst;

  assign next_wrow_o    = match_ptr;
  assign next_gidx_o    = {/*gidx_present_q || ~new_match*/ 1'b0, current_gidx_q};
  assign out_valid_o    = ~lookahead_fifo_empty && out_ready_i;

endmodule