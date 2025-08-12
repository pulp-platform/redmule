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
  parameter int unsigned InpDataWidth   = 16,
  localparam int unsigned InputStreamWidth = NumRows*InpDataWidth,
  localparam int unsigned NumStreams = 4,
  localparam int unsigned OutputStreamWidth = NumStreams*InputStreamWidth
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

  hwpe_stream_intf_stream #(
    .DATA_WIDTH (InputStreamWidth)
  ) input_stream (
    .clk ( clk_i )
  );

  assign input_stream.data   = input_i;
  assign input_stream.valid  = valid_i;
  assign input_stream.strb   = '1;
  assign ready_o             = input_stream.ready; 

  hwpe_stream_intf_stream #(
    .DATA_WIDTH (InputStreamWidth)
  ) input_stream_demux[NumStreams-1:0] (
    .clk ( clk_i )
  );

  hwpe_stream_intf_stream #(
    .DATA_WIDTH (InputStreamWidth)
  ) input_stream_demux_fifo[NumStreams-1:0] (
    .clk ( clk_i )
  );

  hwpe_stream_intf_stream #(
    .DATA_WIDTH (InputStreamWidth)
  ) input_stream_fenced[NumStreams-1:0] (
    .clk ( clk_i )
  );


  hwpe_stream_intf_stream #(
    .DATA_WIDTH (OutputStreamWidth)
  ) input_stream_merged (
    .clk ( clk_i )
  );

  logic [$clog2(NumStreams)-1:0] sel, sel_d, sel_q; 

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (~rst_ni) begin
      sel_q <= 1'b0;
    end else begin
      sel_q <= sel_d;
    end
  end

  assign sel = sel_q;

  always_comb begin 
    sel_d = sel_q; 
    if(clear_i) begin
      sel_d = 1'b0; 
    end else begin 
      sel_d = input_stream.valid & input_stream.ready ? sel_q + 1 : sel_q;
    end 
  end

  hwpe_stream_demux_static #(
    .NB_OUT_STREAMS(NumStreams)
  ) i_demux (
    .clk_i   ( clk_i               ),
    .rst_ni  ( rst_ni              ),
    .clear_i ( clear_i             ),
    .sel_i   ( sel                 ),
    .push_i  ( input_stream        ),
    .pop_o   ( input_stream_demux  )
  );

  genvar ii; 
  generate 
    for(ii=0; ii<NumStreams; ii++) begin : gen_fifo
      hwpe_stream_fifo #(
        .DATA_WIDTH(InputStreamWidth),
        .FIFO_DEPTH(4)
      ) i_fifo (
        .clk_i   ( clk_i                       ),
        .rst_ni  ( rst_ni                      ),
        .clear_i ( clear_i                     ),
        .flags_o (                             ),
        .push_i  ( input_stream_demux[ii]      ),
        .pop_o   ( input_stream_demux_fifo[ii] )
      );
    end : gen_fifo
  endgenerate

  hwpe_stream_fence #(
    .NB_STREAMS(NumStreams),
    .DATA_WIDTH(InputStreamWidth)
  ) i_fence (
    .clk_i       ( clk_i                    ),
    .rst_ni      ( rst_ni                   ),
    .clear_i     ( clear_i                  ),
    .test_mode_i ( 1'b0                     ),
    .push_i      ( input_stream_demux_fifo  ),
    .pop_o       ( input_stream_fenced      )
  );

  hwpe_stream_merge #(
    .NB_IN_STREAMS(NumStreams), 
    .DATA_WIDTH_IN(InputStreamWidth)
  ) i_merge (
    .clk_i   ( clk_i               ),
    .rst_ni  ( rst_ni              ),
    .clear_i ( clear_i             ),
    .push_i  ( input_stream_fenced ),
    .pop_o   ( output_o            )
  );
endmodule
