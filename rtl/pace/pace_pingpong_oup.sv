// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Arpan Suravi Prasad <prasadar@iis.ee.ethz.ch>
//
// This module takes a InpDataWidth*NumRows data from the engine and combines it over 2 cycles
// to generate a datawidth of 2*InpDataWidth*NumRows bits thus utilizing whole bandwidth once in 2 cycles.
// The average bandwidth requirement is half the provided external bandwidth

module pace_pingpong_oup #(
  parameter int unsigned NumRows        = 8,
  parameter int unsigned InpDataWidth   = 16
) (
  input  logic                                 clk_i,
  input  logic                                 rst_ni,
  input  logic                                 clear_i,
  input  logic [NumRows-1:0][InpDataWidth-1:0] input_i,
  input  logic                                 enable_i,
  input  logic                                 valid_i,
  output logic                                 ready_o,
  hwpe_stream_intf_stream.source               output_o
);

  // Internal signals
  logic [NumRows*InpDataWidth-1:0]    input_buffer_d, input_buffer_q;
  logic [2*NumRows*InpDataWidth-1:0]  flattened_oup_buffer;
  logic                               ping_pong_status_d, ping_pong_status_q;
  logic                               input_handshake;

  // Handshake
  assign input_handshake = valid_i & ready_o;

  // Input buffering logic
  assign input_buffer_d = clear_i ? '0 :
                          (input_handshake && ~ping_pong_status_q) ? input_i : input_buffer_q;

  // Flatten the buffered output
  generate
    for (genvar r = 0; r < 2*NumRows; r++) begin : gen_flattened_output
      if (r < NumRows) begin : gen_even_entry
        assign flattened_oup_buffer[(r+1)*InpDataWidth-1 -: InpDataWidth] = input_buffer_q[(r+1)*InpDataWidth-1 -: InpDataWidth];
      end else begin : gen_odd_entry
        assign flattened_oup_buffer[(r+1)*InpDataWidth-1 -: InpDataWidth] = input_i[r-NumRows];
      end
    end
  endgenerate

  // Output assignments
  assign output_o.data  = flattened_oup_buffer;
  assign output_o.valid = valid_i & ping_pong_status_q;
  assign output_o.strb  = '1;
  assign ready_o        = enable_i && (((output_o.ready & output_o.valid) && ping_pong_status_q) || ~ping_pong_status_q);
  // When the input data is not latched that is ping_pong_status_q == 0
  // Else when one input data is latched(ping_pong_status_q == 1) and there is a handhake then one data could be taken

  // Ping-pong status control
  assign ping_pong_status_d = clear_i         ? 1'b0 :
                              input_handshake ? ~ping_pong_status_q :
                                                ping_pong_status_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin : ping_pong_status_ff
    if (~rst_ni) begin
      ping_pong_status_q <= 1'b0;
      input_buffer_q     <= '0;
    end else begin
      ping_pong_status_q <= ping_pong_status_d;
      input_buffer_q     <= input_buffer_d;
    end
  end

endmodule
