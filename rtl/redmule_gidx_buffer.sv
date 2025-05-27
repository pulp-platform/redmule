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
  input  logic                                               clk_i         ,
  input  logic                                               rst_ni        ,
  input  logic                                               clear_i       ,
  input  gidx_buffer_ctrl_t                                  ctrl_i        ,
  output gidx_buffer_flgs_t                                  flags_o       ,
  input  logic                             [DW/G-1:0][G-1:0] gidx_buffer_i ,
  input  logic                                               gidx_valid_i  ,
  output logic                                               out_valid_o   ,
  output logic                               [G+$clog2(H):0] next_gidx_o   ,
  output logic                             [$clog2(D*H)-1:0] next_wrow_o   ,
  output logic                                               gidx_ready_o  ,
  input  logic                                               out_ready_i
);

  // FIXME I DON'T WORK WITH LEFTOVERS!!!

  logic [1:0][H-1:0][G-1:0] last_gidx_d, last_gidx_q;

  logic gidx_present_d, gidx_present_q;

  logic lookahead_offset_en, lookahead_offset_rst;
  logic [$clog2(H+D*H)-1:0] lookahead_offset_d, lookahead_offset_q;
  logic [D*H-1:0] lookahead_matches_d, lookahead_matches_q;

  logic [G-1:0] current_gidx_d, current_gidx_q;

  logic lookahead_fifo_full, lookahead_fifo_push;
  logic lookahead_fifo_empty, lookahead_fifo_pop;

  logic [H*D-1:0] match_msk_d, match_msk_q;

  logic [15:0] iter_counter_q;
  logic        iter_counter_en, iter_counter_rst;

  typedef enum logic[1:0] { CHECK_LAST, FILL, FULL } gidx_buffer_state_t;

  logic last_gidx_ptr;

  logic match_flg_d;

  logic [$clog2(H):0] last_matches_d, last_matches_q,
                      fill_counter_d, fill_counter_q,
                      num_gidx_valid_d, num_gidx_valid_q;

  logic [H-1:0]       last_matched_d, last_matched_q;

  logic [1:0][$clog2(H)-1:0] last_gidx_wptr_d, last_gidx_wptr_q;
  logic [$clog2(H)-1:0]      last_gidx_wptr_pre_fill_q,
                             last_gidx_wptr_pre_full_q;

  logic [$clog2(H)-1:0]      evict_ptr_d, evict_ptr_q;
  logic [1:0][H-1:0][$clog2(H)-1:0] evict_ptr_trnsl_d, evict_ptr_trnsl_q;

  gidx_buffer_state_t current_state, next_state;


  always_ff @(posedge clk_i or negedge rst_ni) begin : num_gidx_valid_register
    if (~rst_ni) begin
      num_gidx_valid_q <= '0;
    end else begin
      if (clear_i || iter_counter_rst) begin
        num_gidx_valid_q <= '0;
      end else if (gidx_valid_i && ~lookahead_fifo_full) begin
        num_gidx_valid_q <= num_gidx_valid_d;
      end
    end
  end

  assign num_gidx_valid_d = current_state == FULL && match_msk_q[lookahead_offset_q-H] && num_gidx_valid_q != H ? num_gidx_valid_q + 1 : num_gidx_valid_q;


  always_ff @(posedge clk_i or negedge rst_ni) begin : last_matches_register
    if (~rst_ni) begin
      last_matches_q <= '0;
    end else begin
      if (clear_i || lookahead_offset_rst || iter_counter_rst) begin
        last_matches_q <= '0;
      end else if (gidx_valid_i && ~lookahead_fifo_full) begin
        last_matches_q <= last_matches_d;
      end
    end
  end

  assign last_matches_d = current_state == CHECK_LAST && |lookahead_matches_d && last_matches_q != num_gidx_valid_d ? last_matches_q + 1 : last_matches_q;


  always_ff @(posedge clk_i or negedge rst_ni) begin : last_gidx_ptr_register
    if (~rst_ni) begin
      last_gidx_ptr <= '0;
    end else begin
      if (clear_i) begin
        last_gidx_ptr <= '0;
      end else if (lookahead_offset_rst && ~iter_counter_rst) begin
        last_gidx_ptr <= ~last_gidx_ptr;
      end
    end
  end


  /* LAST MATCHED ASSIGNMENT*/

  always_ff @(posedge clk_i or negedge rst_ni) begin : last_matched_register
    if (~rst_ni) begin
      last_matched_q <= '0;
    end else begin
      if (clear_i || lookahead_offset_rst || iter_counter_rst) begin
        last_matched_q <= '0;
      end else if (gidx_valid_i && ~lookahead_fifo_full) begin
        last_matched_q <= last_matched_d;
      end
    end
  end

  always_comb begin
    last_matched_d = last_matched_q;

    if (current_state == CHECK_LAST && |lookahead_matches_d) begin
      last_matched_d[last_gidx_wptr_q[last_gidx_ptr]] = 1'b1;
    end
  end

  /* LAST GIDX WRITE POINTERS ASSIGNMENT  */

  always_ff @(posedge clk_i or negedge rst_ni) begin : last_gidx_wptr_pre_fill_register
    if (~rst_ni) begin
      last_gidx_wptr_pre_fill_q <= '0;
    end else begin
      if (clear_i || iter_counter_rst) begin
        last_gidx_wptr_pre_fill_q <= '0;
      end else if (gidx_valid_i && ~lookahead_fifo_full && current_state == CHECK_LAST && next_state == FILL) begin
        last_gidx_wptr_pre_fill_q <= last_gidx_wptr_d[~last_gidx_ptr];
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : last_gidx_wptr_pre_full_register
    if (~rst_ni) begin
      last_gidx_wptr_pre_full_q <= '0;
    end else begin
      if (clear_i) begin
        last_gidx_wptr_pre_full_q <= '0;
      end else if (gidx_valid_i && ~lookahead_fifo_full && iter_counter_rst) begin
        last_gidx_wptr_pre_full_q <= last_gidx_wptr_d[~last_gidx_ptr];
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : last_gidx_wprt_register
    if (~rst_ni) begin
      last_gidx_wptr_q <= '0;
    end else begin
      if (clear_i) begin
        last_gidx_wptr_q <= '0;
      end else if (gidx_valid_i && ~lookahead_fifo_full) begin
        last_gidx_wptr_q <= last_gidx_wptr_d;
      end
    end
  end

  always_comb begin
    last_gidx_wptr_d = last_gidx_wptr_q;

    if (current_state == CHECK_LAST) begin
      last_gidx_wptr_d[last_gidx_ptr] = last_gidx_wptr_q[last_gidx_ptr] + 1;

      if (|lookahead_matches_d) begin
        last_gidx_wptr_d[~last_gidx_ptr] = last_gidx_wptr_q[~last_gidx_ptr] + 1;
      end
    end else if (current_state == FILL) begin
      last_gidx_wptr_d[last_gidx_ptr] = last_gidx_wptr_q[last_gidx_ptr] + 1;

      if (~last_matched_q[last_gidx_wptr_q[last_gidx_ptr]] /*The gix has not matched before*/) begin
        last_gidx_wptr_d[~last_gidx_ptr] = last_gidx_wptr_q[~last_gidx_ptr] + 1;
      end

      if (next_state == FULL) begin
        last_gidx_wptr_d[~last_gidx_ptr] = last_gidx_wptr_pre_fill_q;
      end
    end else if (current_state == FULL) begin
      last_gidx_wptr_d[last_gidx_ptr] = '0;

      if (next_state == CHECK_LAST && num_gidx_valid_d != H)
        last_gidx_wptr_d[~last_gidx_ptr] = last_gidx_wptr_pre_full_q; // was '0
      else if (|lookahead_matches_d) begin
        last_gidx_wptr_d[~last_gidx_ptr] = last_gidx_wptr_q[~last_gidx_ptr] + 1;
      end
    end
  end

  /* EVICT POINTER TRANSLATOR */

  always_ff @(posedge clk_i or negedge rst_ni) begin : evict_ptr_trnsl_register
    if (~rst_ni) begin
      for (int unsigned i = 0; i < H; i++) begin
        evict_ptr_trnsl_q[0][i] <= i;
        evict_ptr_trnsl_q[1][i] <= i;
      end
    end else begin
      if (clear_i) begin
        for (int unsigned i = 0; i < H; i++) begin
          evict_ptr_trnsl_q[0][i] <= i;
          evict_ptr_trnsl_q[1][i] <= i;
        end
      end else if (gidx_valid_i && ~lookahead_fifo_full) begin
        evict_ptr_trnsl_q <= evict_ptr_trnsl_d;
      end
    end
  end

  always_comb begin
    evict_ptr_trnsl_d = evict_ptr_trnsl_q;

    if (current_state == CHECK_LAST && |lookahead_matches_d) begin
      evict_ptr_trnsl_d[last_gidx_ptr][last_gidx_wptr_q[~last_gidx_ptr]] = evict_ptr_trnsl_q[~last_gidx_ptr][last_gidx_wptr_q[last_gidx_ptr]];
    end else if (current_state == FILL && ~last_matched_q[last_gidx_wptr_q[last_gidx_ptr]]) begin
      evict_ptr_trnsl_d[last_gidx_ptr][last_gidx_wptr_q[~last_gidx_ptr]] = evict_ptr_trnsl_q[~last_gidx_ptr][last_gidx_wptr_q[last_gidx_ptr]];
    end else if (current_state == FULL && lookahead_offset_rst) begin
      evict_ptr_trnsl_d[~last_gidx_ptr] = evict_ptr_trnsl_q[last_gidx_ptr];
    end
  end

  /* LAST GIDX ASSIGNMENT */

  always_ff @(posedge clk_i or negedge rst_ni) begin : last_gidx_register
    if (~rst_ni) begin
      last_gidx_q <= '0;
    end else begin
      if (clear_i) begin
        last_gidx_q <= '0;
      end else if (gidx_valid_i && ~lookahead_fifo_full) begin
        last_gidx_q <= last_gidx_d;
      end
    end
  end

  always_comb begin
    last_gidx_d = last_gidx_q;

    if (current_state == CHECK_LAST) begin
      if (|lookahead_matches_d) begin
        last_gidx_d[~last_gidx_ptr][last_gidx_wptr_q[~last_gidx_ptr]] = current_gidx_d;
      end
    end else if (current_state == FILL) begin
      if (~last_matched_q[last_gidx_wptr_q[last_gidx_ptr]]) begin
        last_gidx_d[~last_gidx_ptr][last_gidx_wptr_q[~last_gidx_ptr]] = last_gidx_d[last_gidx_ptr][last_gidx_wptr_q[last_gidx_ptr]];
      end
    end else if (current_state == FULL) begin
      if (|lookahead_matches_d) begin
        last_gidx_d[~last_gidx_ptr][last_gidx_wptr_q[~last_gidx_ptr]] = current_gidx_d;
      end
    end
  end

  /* FILL COUNTER */

  always_ff @(posedge clk_i or negedge rst_ni) begin : fill_counter_register
    if (~rst_ni) begin
      fill_counter_q <= '0;
    end else begin
      if (clear_i || lookahead_offset_rst || iter_counter_rst) begin
        fill_counter_q <= '0;
      end else if (gidx_valid_i && ~lookahead_fifo_full) begin
        fill_counter_q <= fill_counter_d;
      end
    end
  end

  always_comb begin : fill_counter_assignment
    fill_counter_d = fill_counter_q;

    if (current_state == CHECK_LAST && |lookahead_matches_d) begin
      fill_counter_d = fill_counter_q + 1;
    end else if (current_state == FILL && ~last_matched_q[last_gidx_wptr_q[last_gidx_ptr]]) begin
      fill_counter_d = fill_counter_q + 1;
    end
  end

  /* ITERATION COUNTER */

  always_ff @(posedge clk_i or negedge rst_ni) begin : iteration_counter
    if (~rst_ni) begin
      iter_counter_q <= '0;
    end else begin
      if (clear_i || iter_counter_rst) begin
        iter_counter_q <= '0;
      end else if (lookahead_offset_rst) begin
        iter_counter_q <= iter_counter_q + 1;
      end
    end
  end

  assign iter_counter_rst = lookahead_offset_rst && iter_counter_q == ctrl_i.num_w_iters - 1;

  always_comb begin : gidx_present_assignment
    gidx_present_d = 1'b0;

    if (current_state == FULL || current_state == CHECK_LAST) begin
      for (int h = 0; h < H; h++) begin
        if (current_gidx_d == last_gidx_q[last_gidx_ptr][h] && num_gidx_valid_q > (h + (H - last_gidx_wptr_pre_full_q)) && iter_counter_q != 0) begin
          gidx_present_d = 1'b1;
          break;
        end
      end
    end
  end

  always_comb begin
    lookahead_matches_d = '0;

    for (int unsigned i = 0; i < D*H; i++) begin
      lookahead_matches_d[i] = current_gidx_d == gidx_buffer_i[i] & match_msk_q[i] && (current_state != CHECK_LAST || (lookahead_offset_q) < num_gidx_valid_q);
    end
  end

  always_comb begin
    match_msk_d = match_msk_q;

    if (lookahead_offset_en) begin
        match_msk_d = match_msk_q ^ lookahead_matches_d;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      match_msk_q <= '1;
    end else begin
      if (clear_i || lookahead_offset_rst || iter_counter_rst) begin
        match_msk_q <= '1;
      end else begin
        match_msk_q <= match_msk_d;
      end
    end
  end

  assign lookahead_offset_en  = gidx_valid_i && ~lookahead_fifo_full && current_state != FILL;
  assign lookahead_fifo_push  = gidx_valid_i && ~lookahead_fifo_full && |lookahead_matches_d && current_state != FILL;

  assign lookahead_offset_rst = lookahead_offset_q == H+D*H-1 || ~|match_msk_d;

  assign lookahead_offset_d   = lookahead_offset_en ? (lookahead_offset_rst ? '0 : lookahead_offset_q + 1) : lookahead_offset_q;

  assign gidx_ready_o         = lookahead_offset_en && lookahead_offset_rst;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      lookahead_offset_q <= H;
    end else begin
      if (clear_i || iter_counter_rst) begin
        lookahead_offset_q <= H;
      end else begin
        lookahead_offset_q <= lookahead_offset_d;
      end
    end
  end

  assign current_gidx_d = current_state == CHECK_LAST ? last_gidx_q[last_gidx_ptr][last_gidx_wptr_q[last_gidx_ptr]] : gidx_buffer_i[lookahead_offset_q-H];

  assign evict_ptr_d = current_state == FULL       ? evict_ptr_trnsl_q[last_gidx_ptr][last_gidx_wptr_q[~last_gidx_ptr]] :
                       current_state == CHECK_LAST ? evict_ptr_trnsl_q[~last_gidx_ptr][last_gidx_wptr_q[last_gidx_ptr]] : '0;

  always_ff @(posedge clk_i or negedge rst_ni) begin : state_register
    if (~rst_ni) begin
      current_state <= FULL;
    end else begin
      if (clear_i || iter_counter_rst) begin
        current_state <= FULL;
      end else if (gidx_valid_i && ~lookahead_fifo_full) begin
        current_state <= next_state;
      end
    end
  end

  always_comb begin : fsm
    next_state = current_state;

    case (current_state)
      CHECK_LAST: begin
        if (lookahead_offset_d == H) begin
          if (last_matches_d == num_gidx_valid_q) begin
            next_state = FULL;
          end else begin
            next_state = FILL;
          end
        end
      end

      FILL: begin
        if (fill_counter_d == H) begin
          next_state = FULL;
        end
      end

      FULL: begin
        if (lookahead_offset_rst) begin
          next_state = CHECK_LAST;
        end
      end
    endcase
  end

  fifo_v3 #(
    .DATA_WIDTH ( G+D*H+1+$clog2(H) ),
    .DEPTH      ( 4                 )
  ) i_lookahead_fifo (
    .clk_i      ( clk_i                                                              ),
    .rst_ni     ( rst_ni                                                             ),
    .flush_i    ( clear_i                                                            ),
    .testmode_i ( '0                                                                 ),
    .full_o     ( lookahead_fifo_full                                                ),
    .empty_o    ( lookahead_fifo_empty                                               ),
    .data_i     ( {evict_ptr_d, gidx_present_d, current_gidx_d, lookahead_matches_d} ),
    .push_i     ( lookahead_fifo_push                                                ),
    .data_o     ( {evict_ptr_q, gidx_present_q, current_gidx_q, lookahead_matches_q} ),
    .pop_i      ( lookahead_fifo_pop                                                 )
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

  assign next_wrow_o = match_ptr;
  assign next_gidx_o = {evict_ptr_q, gidx_present_q || ~new_match, current_gidx_q};
  assign out_valid_o = ~lookahead_fifo_empty && out_ready_i;

endmodule