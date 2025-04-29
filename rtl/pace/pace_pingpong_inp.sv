// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Arpan Suravi Prasad <prasadar@iis.ee.ethz.ch>
//
// This module takes a 256b data and splits it to 128b to feed it to the engine for 2 cycles.
module pace_pingpong_inp #(
  parameter int unsigned InpDataWidth  = 256,
  parameter int unsigned NumRows       = 8,
  parameter int unsigned OupDataWidth  = 16
) (
  input  logic                                    clk_i,
  input  logic                                    rst_ni,
  input  logic                                    clear_i,
  input  logic                                    enable_i,
  output logic [NumRows-1:0][OupDataWidth-1:0]    output_o,
  output logic                                    valid_o,
  input  logic                                    ready_i,
  hwpe_stream_intf_stream.sink                    input_i
);

  // Local signals
  hwpe_stream_intf_stream #(
    .DATA_WIDTH ( InpDataWidth*NumRows )
  ) ping_pong_buffer [1:0] (
    .clk ( clk_i )
  );
  logic                            output_handshake;
  logic [NumRows*OupDataWidth-1:0] output_buffer;
  logic                            ping_pong_status_d, ping_pong_status_q;

  // Stream splitter
  hwpe_stream_split #(
    .NB_OUT_STREAMS ( 2            ),
    .DATA_WIDTH_IN  ( InpDataWidth )
  ) i_hwpe_stream_split (
    .clk_i   ( clk_i            ),
    .rst_ni  ( rst_ni           ),
    .clear_i ( clear_i          ),
    .push_i  ( input_i          ),
    .pop_o   ( ping_pong_buffer )
  );

  // Ready/valid handshake
  assign ping_pong_buffer[0].ready = output_handshake & ping_pong_status_q & enable_i;
  assign ping_pong_buffer[1].ready = output_handshake & ping_pong_status_q & enable_i;

  assign output_buffer = ping_pong_status_q ? ping_pong_buffer[1].data  : ping_pong_buffer[0].data;
  assign valid_o       = ping_pong_status_q ? ping_pong_buffer[1].valid : ping_pong_buffer[0].valid;

  // Output slicing
  generate
    for (genvar r = 0; r < NumRows; r++) begin : gen_output_unpack
      assign output_o[r] = output_buffer[(OupDataWidth*(r+1))-1 -: OupDataWidth];
    end
  endgenerate

  // Handshake logic
  assign output_handshake = valid_o & ready_i;

  // Ping-pong control
  assign ping_pong_status_d = clear_i             ? 1'b0 :
                              output_handshake    ? ~ping_pong_status_q :
                                                    ping_pong_status_q;
  always_ff @(posedge clk_i or negedge rst_ni) begin : gen_ping_pong_status_ff
    if (~rst_ni) begin
      ping_pong_status_q <= 1'b0;
    end else begin
      ping_pong_status_q <= ping_pong_status_d;
    end
  end

endmodule
