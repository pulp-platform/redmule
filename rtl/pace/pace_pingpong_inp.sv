// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Arpan Suravi Prasad <prasadar@iis.ee.ethz.ch>
//
// This module takes a 256b data and splits it to 128b to feed it to the engine for 2 cycles.
module pace_pingpong_inp #(
  parameter int unsigned InpDataWidth    = 256,
  parameter int unsigned NumRows         = 8,
  parameter int unsigned CEOupDataWidth  = 16,
  localparam int NumStreams = InpDataWidth/(CEOupDataWidth*NumRows),
  localparam int unsigned OupDataWidth   = NumRows * CEOupDataWidth
) (
  input  logic                                    clk_i,
  input  logic                                    rst_ni,
  input  logic                                    clear_i,
  input  logic                                    enable_i,
  output logic [NumRows-1:0][CEOupDataWidth-1:0]  output_o,
  output logic                                    valid_o,
  input  logic                                    ready_i,
  hwpe_stream_intf_stream.sink                    input_i
);

  // Local signals
  hwpe_stream_intf_stream #(
    .DATA_WIDTH (InpDataWidth/NumStreams )
  ) ping_pong_buffer [NumStreams-1:0] (
    .clk ( clk_i )
  );

  hwpe_stream_intf_stream #(
    .DATA_WIDTH (InpDataWidth/NumStreams )
  ) output_buffer (
    .clk ( clk_i )
  );

  hwpe_stream_intf_stream #(
    .DATA_WIDTH (InpDataWidth/NumStreams )
  ) output_buffer_fifo (
    .clk ( clk_i )
  );


  // Stream splitter
  hwpe_stream_split #(
    .NB_OUT_STREAMS ( NumStreams   ),
    .DATA_WIDTH_IN  ( InpDataWidth )
  ) i_hwpe_stream_split (
    .clk_i   ( clk_i            ),
    .rst_ni  ( rst_ni           ),
    .clear_i ( clear_i          ),
    .push_i  ( input_i          ),
    .pop_o   ( ping_pong_buffer )
  );

  hwpe_stream_package::ctrl_serdes_t ctrl_serdes;

  assign ctrl_serdes.clear_serdes_state = clear_i;
  assign ctrl_serdes.nb_contig_m1       = 0;
  assign ctrl_serdes.first_stream       = 1'b0;

  hwpe_stream_serialize #(
    .NB_IN_STREAMS ( NumStreams   ),
    .CONTIG_LIMIT  ( 1024         ),
    .DATA_WIDTH    ( OupDataWidth ),
    .SYNC_READY    ( 1'b1         )
  ) i_hwpe_stream_serialize (
    .clk_i   ( clk_i            ),
    .rst_ni  ( rst_ni           ),
    .clear_i ( clear_i          ),
    .ctrl_i  ( ctrl_serdes      ),
    .push_i  ( ping_pong_buffer ),
    .pop_o   ( output_buffer    )
  );

  hwpe_stream_fifo #(
    .DATA_WIDTH ( OupDataWidth ),
    .FIFO_DEPTH ( 2            ),
    .LATCH_FIFO ( 0            ),
    .LATCH_FIFO_TEST_WRAP ( 0  )
  ) i_hwpe_stream_fifo (
    .clk_i   ( clk_i              ),
    .rst_ni  ( rst_ni             ),
    .clear_i ( clear_i            ),
    .flags_o (                    ),
    .push_i  ( output_buffer      ),
    .pop_o   ( output_buffer_fifo )
  );

  // Output slicing
  generate
    for (genvar r = 0; r < NumRows; r++) begin : gen_output_unpack
      assign output_o[r] = output_buffer_fifo.data[(CEOupDataWidth*(r+1))-1 -: CEOupDataWidth];
    end
  endgenerate
  assign valid_o = output_buffer_fifo.valid;
  assign output_buffer_fifo.ready = ready_i & enable_i;



endmodule
