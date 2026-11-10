// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// RedMulE-specific Z store sink.
//
// This is a local variant of hci_core_sink whose address generator is
// per-M-block linear rather than a single fixed addressgen_v4 geometry:
//  * every complete Width-row M block stores Width rows per K tile;
//  * the final M block stores only x_rows_lftovr rows per K tile.
// The generator therefore never visits padding rows and cannot hit the
// stale-counter transition of hwpe_stream_addressgen_v4, while the whole job
// still has a single sink run (one done pulse, preserving XIF pipelining).

`include "hci_helpers.svh"

module redmule_z_stream_sink
  import hwpe_stream_package::*;
  import hci_package::*;
  import redmule_pkg::*;
#(
  parameter int unsigned TCDM_FIFO_DEPTH      = 0,
  parameter int unsigned TRANS_CNT            = 16,
  parameter int unsigned MISALIGNED_ACCESSES  = 1,
  parameter int unsigned ELEMENT_WIDTH        = 8,
  parameter int unsigned ELEMENTS_PER_BANK    = 4,
  parameter int unsigned WIDTH                = MaxDim,
  parameter int unsigned JMP                  = MaxDataW/8,
  localparam int unsigned BANK_DATA_WIDTH     = ELEMENT_WIDTH * ELEMENTS_PER_BANK,
  localparam int unsigned ELEMENT_INDEX_WIDTH = $clog2(ELEMENTS_PER_BANK),
  parameter hci_size_parameter_t `HCI_SIZE_PARAM(tcdm) = '0
)
(
  input logic clk_i,
  input logic rst_ni,
  input logic test_mode_i,
  input logic clear_i,
  input logic enable_i,

  hci_core_intf.initiator      tcdm,
  hwpe_stream_intf_stream.sink stream,

  // Active store-side configuration for the current job.
  input redmule_config_t        config_i,
  // When a successor job is already queued, keep the padded final-block
  // geometry to preserve overlapped/pipelined stream behavior. The store
  // suppression removes the padding writes.
  input logic                   pad_final_i,

  // Control plane
  input  hci_streamer_ctrl_t    ctrl_i,
  output hci_streamer_flags_t   flags_o
);

  localparam int unsigned DATA_WIDTH = `HCI_SIZE_GET_DW(tcdm);
  localparam int unsigned EHW        = `HCI_SIZE_GET_EHW(tcdm);

  hci_streamer_state_t cs, ns;

  logic address_gen_en;
  logic address_gen_clr;
  logic done;

  logic tcdm_inflight;

  assign flags_o.no_valid_transfers = (~tcdm_inflight);

  hwpe_stream_intf_stream #(
    .DATA_WIDTH ( 36 )
  ) addr_push (
    .clk ( clk_i )
  );

  hwpe_stream_intf_stream #(
    .DATA_WIDTH ( 36 )
  ) addr_pop (
    .clk ( clk_i )
  );

  `HCI_INTF_EXPLICIT_PARAM(tcdm_target, clk_i, `HCI_SIZE_PARAM(tcdm));

  // ----------------------------------------------------------------
  // Per-M-block linear address generator
  // ----------------------------------------------------------------
  logic [31:0] total_len;
  logic [15:0] rows_current;
  logic [31:0] overall_counter_q;
  logic [15:0] block_q, k_tile_q, row_q;
  logic [15:0] next_block, next_k_tile, next_row;
  logic [31:0] current_addr, next_addr, addr_q;
  logic        addr_valid_q;

  assign total_len = pad_final_i
                   ? WIDTH * config_i.x_rows_iter * config_i.w_cols_iter
                   : config_i.m_size * config_i.w_cols_iter;
  assign rows_current = (block_q == config_i.x_rows_iter - 1
                         && config_i.x_rows_lftovr != '0
                         && !pad_final_i)
                      ? config_i.x_rows_lftovr : WIDTH;

  assign current_addr = config_i.z_addr
                      + block_q * WIDTH * config_i.yz_d0_stride
                      + k_tile_q * JMP
                      + row_q * config_i.yz_d0_stride;

  always_comb begin
    next_block  = block_q;
    next_k_tile = k_tile_q;
    next_row    = row_q;

    if (row_q + 1 < rows_current) begin
      next_row = row_q + 1;
    end else begin
      next_row = '0;
      if (k_tile_q + 1 < config_i.w_cols_iter) begin
        next_k_tile = k_tile_q + 1;
      end else begin
        next_k_tile = '0;
        next_block  = block_q + 1;
      end
    end
  end

  assign next_addr = config_i.z_addr
                   + next_block * WIDTH * config_i.yz_d0_stride
                   + next_k_tile * JMP
                   + next_row * config_i.yz_d0_stride;

  assign addr_push.data  = (ctrl_i.req_start && total_len != 0) ? config_i.z_addr : addr_q;
  assign addr_push.strb  = '1;
  assign addr_push.valid = addr_valid_q || (ctrl_i.req_start && total_len != 0);
  assign flags_o.addressgen_flags.done = (overall_counter_q >= total_len);

  always_ff @(posedge clk_i or negedge rst_ni) begin : addrgen_counters
    if (~rst_ni) begin
      overall_counter_q <= '0;
      block_q           <= '0;
      k_tile_q          <= '0;
      row_q             <= '0;
      addr_q            <= '0;
      addr_valid_q      <= '0;
    end else if (clear_i || address_gen_clr) begin
      overall_counter_q <= '0;
      block_q           <= '0;
      k_tile_q          <= '0;
      row_q             <= '0;
      addr_q            <= '0;
      addr_valid_q      <= '0;
    end else if (ctrl_i.req_start) begin
      // Emit the first address in the start cycle, then preload the second one.
      if (total_len == 0) begin
        overall_counter_q <= '0;
        block_q           <= '0;
        k_tile_q          <= '0;
        row_q             <= '0;
        addr_q            <= config_i.z_addr;
        addr_valid_q      <= '0;
      end else begin
        overall_counter_q <= 1;
        block_q           <= next_block;
        k_tile_q          <= next_k_tile;
        row_q             <= next_row;
        addr_q            <= next_addr;
        addr_valid_q      <= (1 < total_len);
      end
    end else if (address_gen_en && overall_counter_q < total_len) begin
      if (~addr_valid_q) begin
        addr_q       <= current_addr;
        addr_valid_q <= 1'b1;
      end else if (addr_push.ready) begin
        overall_counter_q <= overall_counter_q + 1;
        block_q           <= next_block;
        k_tile_q          <= next_k_tile;
        row_q             <= next_row;
        addr_q            <= next_addr;
        addr_valid_q      <= (overall_counter_q + 1 < total_len);
      end
    end
  end

  hwpe_stream_fifo #(
    .DATA_WIDTH ( 36 ),
    .FIFO_DEPTH ( 2  )
  ) i_fifo_addr (
    .clk_i   ( clk_i           ),
    .rst_ni  ( rst_ni          ),
    .clear_i ( clear_i         ),
    .flags_o (                   ),
    .push_i  ( addr_push       ),
    .pop_o   ( addr_pop        )
  );

  logic address_cnt_en, address_cnt_clr;
  logic [TRANS_CNT-1:0] address_cnt_d, address_cnt_q;

  logic [DATA_WIDTH-1:0]   stream_data_misaligned;
  logic [DATA_WIDTH/ELEMENT_WIDTH-1:0] stream_strb_misaligned;
  logic [ELEMENTS_PER_BANK-1:0][DATA_WIDTH-1:0]   stream_data_aligned_array;
  logic [ELEMENTS_PER_BANK-1:0][DATA_WIDTH/ELEMENT_WIDTH-1:0] stream_strb_aligned_array;
  logic [DATA_WIDTH-1:0]   stream_data_aligned;
  logic [DATA_WIDTH/ELEMENT_WIDTH-1:0] stream_strb_aligned;

  logic [ELEMENT_INDEX_WIDTH-1:0] bank_offset;

  assign bank_offset = addr_pop.data[ELEMENT_INDEX_WIDTH-1:0];

  generate
    if (MISALIGNED_ACCESSES == 1) begin: misaligned_access_gen
      for (genvar offs = 0; offs < ELEMENTS_PER_BANK; offs++) begin : aligned_stream_gen
        if (offs > 0) begin
          assign stream_data_aligned_array[offs][offs*ELEMENT_WIDTH-1:0] = '0;
          assign stream_strb_aligned_array[offs][offs-1:0] = '0;
        end

        localparam int unsigned DATA_OFFSET_MSB = DATA_WIDTH - BANK_DATA_WIDTH + offs * ELEMENT_WIDTH;
        localparam int unsigned DATA_OFFSET_LSB = DATA_OFFSET_MSB - (DATA_WIDTH - BANK_DATA_WIDTH);
        localparam int unsigned STRB_OFFSET_MSB = DATA_OFFSET_MSB / ELEMENT_WIDTH;
        localparam int unsigned STRB_OFFSET_LSB = DATA_OFFSET_LSB / ELEMENT_WIDTH;

        assign stream_data_aligned_array[offs][DATA_WIDTH-1:DATA_OFFSET_MSB] = '0;
        assign stream_data_aligned_array[offs][DATA_OFFSET_MSB-1:DATA_OFFSET_LSB] = stream_data_misaligned[DATA_WIDTH-BANK_DATA_WIDTH-1:0];

        assign stream_strb_aligned_array[offs][DATA_WIDTH/ELEMENT_WIDTH-1:STRB_OFFSET_MSB] = '0;
        assign stream_strb_aligned_array[offs][STRB_OFFSET_MSB-1:STRB_OFFSET_LSB] = stream_strb_misaligned[(DATA_WIDTH-BANK_DATA_WIDTH)/ELEMENT_WIDTH-1:0];
      end
      assign stream_data_aligned = stream_data_aligned_array[bank_offset];
      assign stream_strb_aligned = stream_strb_aligned_array[bank_offset];
    end else begin
      assign stream_data_aligned[DATA_WIDTH-1:0]   = stream_data_misaligned[DATA_WIDTH-1:0];
      assign stream_strb_aligned[DATA_WIDTH/ELEMENT_WIDTH-1:0] = stream_strb_misaligned[DATA_WIDTH/ELEMENT_WIDTH-1:0];
    end
  endgenerate

  assign stream_data_misaligned = stream.data;
  assign stream_strb_misaligned = stream.strb;

  assign tcdm_target.req     = (cs != STREAMER_IDLE) ? stream.valid & addr_pop.valid : '0;
  assign tcdm_target.add     = (cs != STREAMER_IDLE) ? {addr_pop.data[31:ELEMENT_INDEX_WIDTH],{ELEMENT_INDEX_WIDTH{1'b0}}} : '0;
  assign tcdm_target.wen     = '0;
  assign tcdm_target.be      = (cs != STREAMER_IDLE) ? stream_strb_aligned : '0;
  assign tcdm_target.data    = (cs != STREAMER_IDLE) ? stream_data_aligned : '0;
  assign tcdm_target.r_ready = '1;
  assign stream.ready        = ~stream.valid | (tcdm_target.gnt & addr_pop.valid);
  assign addr_pop.ready      = stream.valid & stream.ready;

  assign tcdm_target.user = '0;
  assign tcdm_target.id   = '0;
  assign tcdm_target.ecc  = '0;

  generate
    if (TCDM_FIFO_DEPTH != 0) begin: tcdm_fifos_gen
      hci_core_fifo #(
        .FIFO_DEPTH                      ( TCDM_FIFO_DEPTH       ),
        .`HCI_SIZE_PARAM(tcdm_initiator) ( `HCI_SIZE_PARAM(tcdm) )
      ) i_tcdm_fifo (
        .clk_i          ( clk_i       ),
        .rst_ni         ( rst_ni      ),
        .clear_i        ( clear_i     ),
        .tcdm_target    ( tcdm_target ),
        .tcdm_initiator ( tcdm        ),
        .flags_o        (             )
      );
    end else begin: no_tcdm_fifos_gen
      hci_core_assign i_tcdm_assign (
        .tcdm_target    ( tcdm_target ),
        .tcdm_initiator ( tcdm        )
      );
    end
  endgenerate

  assign tcdm_inflight = tcdm.req;

  always_ff @(posedge clk_i or negedge rst_ni) begin : done_sink_ff
    if(~rst_ni)
      flags_o.done <= 1'b0;
    else if(clear_i)
      flags_o.done <= 1'b0;
    else if(enable_i)
      flags_o.done <= done;
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin : fsm_seq
    if(rst_ni == 1'b0)
      cs <= STREAMER_IDLE;
    else if(clear_i == 1'b1)
      cs <= STREAMER_IDLE;
    else if(enable_i)
      cs <= ns;
  end

  always_comb begin : fsm_comb
    ns                  = cs;
    done                = 1'b0;
    flags_o.ready_start = 1'b0;
    address_gen_en      = 1'b0;
    address_gen_clr     = clear_i;
    address_cnt_clr     = 1'b0;
    case(cs)
      STREAMER_IDLE : begin
        flags_o.ready_start = 1'b1;
        if(ctrl_i.req_start) begin
          ns = STREAMER_WORKING;
          address_gen_en = 1'b1;
        end
      end
      STREAMER_WORKING : begin
        address_gen_en = 1'b1;
        if(flags_o.addressgen_flags.done) begin
          ns = STREAMER_DONE;
        end
      end
      STREAMER_DONE : begin
        address_gen_en = 1'b1;
        if((address_cnt_q == total_len) | (address_cnt_q == total_len-1 && address_cnt_en)) begin
          ns = STREAMER_IDLE;
          done = 1'b1;
          address_gen_en  = 1'b0;
          address_gen_clr = 1'b1;
          address_cnt_clr = 1'b1;
        end
      end
    endcase
  end

  assign address_cnt_en = addr_pop.valid & addr_pop.ready;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni)
      address_cnt_q <= '0;
    else if(clear_i | address_cnt_clr)
      address_cnt_q <= '0;
    else if(enable_i & address_cnt_en)
      address_cnt_q <= address_cnt_d;
  end
  assign address_cnt_d = address_cnt_q + 1;

  if(EHW > 0) begin : ecc_handshake_gen
    assign tcdm_target.ereq     = '{default:{tcdm_target.req}};
    assign tcdm_target.r_eready = '{default:{tcdm_target.r_ready}};
  end
  else begin : no_ecc_handshake_gen
    assign tcdm_target.ereq     = '0;
    assign tcdm_target.r_eready = '1;
  end

`ifndef SYNTHESIS
`ifndef VERILATOR
`ifndef VCS
  if(MISALIGNED_ACCESSES == 0) begin
    initial
      dw : assert(stream.DATA_WIDTH == tcdm.DW);
  end
  else begin
    initial
      dw : assert(stream.DATA_WIDTH+BANK_DATA_WIDTH == tcdm.DW);
  end

  `HCI_SIZE_CHECK_ASSERTS(tcdm);
`endif
`endif
`endif

endmodule : redmule_z_stream_sink
