// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// RedMulE-specific Y bias source.
//
// Local variant of hci_core_source with a per-M-block linear address
// generator. Complete M blocks load Width rows per K tile; the final block
// loads only x_rows_lftovr rows per K tile. When a successor job is queued,
// pad_final_i keeps the old padded geometry so overlapped jobs stay in
// lockstep.

`include "hci_helpers.svh"

module redmule_y_stream_source
  import hwpe_stream_package::*;
  import hci_package::*;
  import redmule_pkg::*;
#(
  parameter int unsigned LATCH_FIFO           = 0,
  parameter int unsigned TRANS_CNT            = 16,
  parameter int unsigned ADDR_MIS_DEPTH       = 8,
  parameter int unsigned MISALIGNED_ACCESSES  = 1,
  parameter int unsigned PASSTHROUGH_FIFO     = 0,
  parameter int unsigned RESP_FIFO_DEPTH      = 0,
  parameter int unsigned ELEMENT_WIDTH        = 8,
  parameter int unsigned ELEMENTS_PER_BANK    = 4,
  parameter int unsigned WIDTH                = MaxDim,
  parameter int unsigned JMP                  = MaxDataW/8,
  localparam int unsigned BANK_DATA_WIDTH     = ELEMENT_WIDTH * ELEMENTS_PER_BANK,
  localparam int unsigned ADDR_OFFSET         = ELEMENTS_PER_BANK == 1 ? 1 : $clog2(ELEMENTS_PER_BANK),
  parameter hci_size_parameter_t `HCI_SIZE_PARAM(tcdm) = '0
)
(
  input logic clk_i,
  input logic rst_ni,
  input logic test_mode_i,
  input logic clear_i,
  input logic enable_i,

  hci_core_intf.initiator        tcdm,
  hwpe_stream_intf_stream.source stream,

  // Active bias-side configuration for the current job.
  input redmule_config_t         config_i,
  // Keep padded final-block geometry when a successor job is already queued.
  input logic                    pad_final_i,

  input  hci_streamer_ctrl_t     ctrl_i,
  output hci_streamer_flags_t    flags_o
);

  localparam int unsigned DATA_WIDTH = `HCI_SIZE_GET_DW(tcdm);
  localparam int unsigned EHW        = `HCI_SIZE_GET_EHW(tcdm);
  localparam int unsigned STREAM_MISALIGNED_DW = DATA_WIDTH - BANK_DATA_WIDTH;

  hci_streamer_state_t cs, ns;
  flags_fifo_t addr_fifo_flags;

  logic done;
  logic address_gen_en;
  logic address_gen_clr;

  hwpe_stream_intf_stream #(
    .DATA_WIDTH ( 32 )
  ) addr_push (
    .clk ( clk_i )
  );

  hwpe_stream_intf_stream #(
    .DATA_WIDTH ( 32 )
  ) addr_pop (
    .clk ( clk_i )
  );

  // ----------------------------------------------------------------
  // Per-M-block linear address generator (Y base)
  // ----------------------------------------------------------------
  logic [31:0] total_len;
  logic [15:0] rows_current;
  logic [15:0] block_q, k_tile_q, row_q;
  logic [15:0] next_block, next_k_tile, next_row;
  logic [31:0] overall_counter_q;
  logic [31:0] current_addr, next_addr, addr_q;
  logic        addr_valid_q;

  assign total_len = pad_final_i
                   ? WIDTH * config_i.x_rows_iter * config_i.w_cols_iter
                   : config_i.m_size * config_i.w_cols_iter;
  assign rows_current = (block_q == config_i.x_rows_iter - 1
                         && config_i.x_rows_lftovr != '0
                         && !pad_final_i)
                      ? config_i.x_rows_lftovr : WIDTH;

  assign current_addr = config_i.y_addr
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

  assign next_addr = config_i.y_addr
                   + next_block * WIDTH * config_i.yz_d0_stride
                   + next_k_tile * JMP
                   + next_row * config_i.yz_d0_stride;

  assign addr_push.data  = addr_q;
  assign addr_push.strb  = '1;
  assign addr_push.valid = addr_valid_q;
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
      overall_counter_q <= '0;
      block_q           <= '0;
      k_tile_q          <= '0;
      row_q             <= '0;
      addr_q            <= config_i.y_addr;
      addr_valid_q      <= '0;
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

  if (PASSTHROUGH_FIFO) begin : passthrough_gen
    hwpe_stream_fifo_passthrough #(
      .DATA_WIDTH ( 36 ),
      .FIFO_DEPTH ( 2  )
    ) i_fifo_addr (
      .clk_i   ( clk_i           ),
      .rst_ni  ( rst_ni          ),
      .clear_i ( clear_i         ),
      .flags_o ( addr_fifo_flags ),
      .push_i  ( addr_push       ),
      .pop_o   ( addr_pop        )
    );
  end
  else begin : nopassthrough_gen
    hwpe_stream_fifo #(
      .DATA_WIDTH ( 36 ),
      .FIFO_DEPTH ( 2  )
    ) i_fifo_addr (
      .clk_i   ( clk_i           ),
      .rst_ni  ( rst_ni          ),
      .clear_i ( clear_i         ),
      .flags_o ( addr_fifo_flags ),
      .push_i  ( addr_push       ),
      .pop_o   ( addr_pop        )
    );
  end

  logic                  stream_valid_q;
  logic [DATA_WIDTH-1:0] stream_data_q;
  logic [ADDR_OFFSET-1:0] addr_misaligned_q;
  logic [DATA_WIDTH-1:0] stream_data_misaligned;
  logic [DATA_WIDTH-1:0] stream_data_aligned;

  logic stream_cnt_en, stream_cnt_clr;
  logic [TRANS_CNT-1:0] stream_cnt_d, stream_cnt_q;

  assign stream_data_misaligned = tcdm.r_valid ? tcdm.r_data : stream_data_q;

  localparam int unsigned ADDR_OFFSET_BYTE = 8*((ADDR_OFFSET + 8 - 1) / 8);

  if (MISALIGNED_ACCESSES==1) begin : misaligned_access_gen
    always_comb begin
      stream_data_aligned = '0;
      if (addr_misaligned_q == 0) begin
        stream_data_aligned[DATA_WIDTH-1:0] = stream_data_misaligned[DATA_WIDTH-1:0];
      end else begin
        stream_data_aligned[STREAM_MISALIGNED_DW-1:0] = stream_data_misaligned[addr_misaligned_q*ELEMENT_WIDTH +: STREAM_MISALIGNED_DW];
      end
    end

    hwpe_stream_intf_stream #(
      .DATA_WIDTH ( ADDR_OFFSET_BYTE )
    ) addr_misaligned_push (
      .clk ( clk_i )
    );
    hwpe_stream_intf_stream #(
      .DATA_WIDTH ( ADDR_OFFSET_BYTE )
    ) addr_misaligned_pop (
      .clk ( clk_i )
    );
    if (ADDR_OFFSET_BYTE == ADDR_OFFSET)
      assign addr_misaligned_push.data = addr_pop.data[ADDR_OFFSET-1:0];
    else
      assign addr_misaligned_push.data = {{(ADDR_OFFSET_BYTE-ADDR_OFFSET){1'b0}}, addr_pop.data[ADDR_OFFSET-1:0]};
    assign addr_misaligned_push.strb  = '1;
    assign addr_misaligned_push.valid = enable_i & tcdm.req & tcdm.gnt;
    assign addr_misaligned_pop.ready  = (tcdm.r_valid | stream_valid_q) & resp_push.ready;
    assign addr_misaligned_q = addr_misaligned_pop.data[ADDR_OFFSET-1:0];

    hwpe_stream_fifo #(
      .DATA_WIDTH ( ADDR_OFFSET_BYTE),
      .FIFO_DEPTH ( ADDR_MIS_DEPTH )
    ) i_addr_misaligned_fifo (
      .clk_i   ( clk_i                ),
      .rst_ni  ( rst_ni               ),
      .clear_i ( clear_i              ),
      .flags_o (                      ),
      .push_i  ( addr_misaligned_push ),
      .pop_o   ( addr_misaligned_pop  )
    );
  end
  else begin
    assign stream_data_aligned[DATA_WIDTH-1:0] = stream_data_misaligned[DATA_WIDTH-1:0];
  end

  hwpe_stream_intf_stream #(
    .DATA_WIDTH ( DATA_WIDTH )
  ) resp_push (
    .clk ( clk_i )
  );
  hwpe_stream_intf_stream #(
    .DATA_WIDTH ( DATA_WIDTH )
  ) resp_pop (
    .clk ( clk_i )
  );

  assign tcdm.req        = (cs != STREAMER_IDLE) ? addr_pop.valid : '0;
  if(ADDR_OFFSET == 1)
    assign tcdm.add        = (cs != STREAMER_IDLE) ? addr_pop.data[31:0] : '0;
  else
    assign tcdm.add        = (cs != STREAMER_IDLE) ? {addr_pop.data[31:ADDR_OFFSET],{ADDR_OFFSET{1'b0}}} : '0;
  assign tcdm.wen        = 1'b1;
  assign tcdm.be         = {ELEMENTS_PER_BANK{1'b0}};
  assign tcdm.data       = '0;
  assign tcdm.user       = '0;
  assign tcdm.id         = '0;
  assign tcdm.ecc        = '0;
  assign addr_pop.ready  = (cs != STREAMER_IDLE) ? tcdm.gnt : 1'b0;
  assign resp_push.data  = stream_data_aligned;
  assign resp_push.strb  = '1;
  assign resp_push.valid = enable_i & (tcdm.r_valid | stream_valid_q);
  assign tcdm.r_ready    = resp_push.ready;

  generate
    if (RESP_FIFO_DEPTH > 0) begin : gen_resp_fifo
      hwpe_stream_fifo #(
        .DATA_WIDTH ( DATA_WIDTH     ),
        .FIFO_DEPTH ( RESP_FIFO_DEPTH )
      ) i_resp_fifo (
        .clk_i   ( clk_i     ),
        .rst_ni  ( rst_ni    ),
        .clear_i ( clear_i   ),
        .flags_o (           ),
        .push_i  ( resp_push ),
        .pop_o   ( resp_pop  )
      );
    end else begin : gen_no_resp_fifo
      hwpe_stream_assign i_resp_assign (
        .push_i ( resp_push ),
        .pop_o  ( resp_pop  )
      );
    end
  endgenerate

  assign stream.data    = resp_pop.data;
  assign stream.valid   = resp_pop.valid;
  assign stream.strb    = resp_pop.strb;
  assign resp_pop.ready = stream.ready;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni)
      stream_valid_q <= 1'b0;
    else if(clear_i)
      stream_valid_q <= 1'b0;
    else if(enable_i) begin
      if(tcdm.r_valid & resp_push.ready)
        stream_valid_q <= 1'b0;
      else if(tcdm.r_valid)
        stream_valid_q <= 1'b1;
      else if(stream_valid_q & resp_push.ready)
        stream_valid_q <= 1'b0;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni)
      stream_data_q <= '0;
    else if(clear_i)
      stream_data_q <= '0;
    else if(enable_i & tcdm.r_valid)
      stream_data_q <= tcdm.r_data;
  end

  always_ff @(posedge clk_i, negedge rst_ni) begin : fsm_seq
    if(rst_ni == 1'b0) begin
      cs <= STREAMER_IDLE;
    end else if(clear_i == 1'b1) begin
      cs <= STREAMER_IDLE;
    end else if(enable_i) begin
      cs <= ns;
    end
  end

  always_comb begin : fsm_comb
    ns                  = cs;
    done                = 1'b0;
    flags_o.ready_start = 1'b0;
    flags_o.done        = 1'b0;
    address_gen_en      = 1'b0;
    address_gen_clr     = clear_i;
    stream_cnt_clr      = 1'b0;
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
        if((addr_fifo_flags.empty==1'b1) && (stream_cnt_q==total_len)) begin
          ns = STREAMER_IDLE;
          flags_o.done = 1'b1;
          done = 1'b1;
          address_gen_en  = 1'b0;
          address_gen_clr = 1'b1;
          stream_cnt_clr = 1'b1;
        end
      end
    endcase
  end

  assign stream_cnt_en = stream.valid & stream.ready;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni)
      stream_cnt_q <= '0;
    else if(clear_i | stream_cnt_clr)
      stream_cnt_q <= '0;
    else if(enable_i & stream_cnt_en)
      stream_cnt_q <= stream_cnt_d;
  end
  assign stream_cnt_d = stream_cnt_q + 1;

  if(EHW > 0) begin : ecc_handshake_gen
    assign tcdm.ereq     = '{default: {tcdm.req}};
    assign tcdm.r_eready = '{default: {tcdm.r_ready}};
  end
  else begin : no_ecc_handshake_gen
    assign tcdm.ereq     = '0;
    assign tcdm.r_eready = '1;
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
      dw : assert(stream.DATA_WIDTH <= tcdm.DW);
  end

  `HCI_SIZE_CHECK_ASSERTS(tcdm);
`endif
`endif
`endif

endmodule : redmule_y_stream_source
