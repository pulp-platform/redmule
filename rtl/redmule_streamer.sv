/*
 * Copyright (C) 2022-2023 ETH Zurich and University of Bologna
 *
 * Licensed under the Solderpad Hardware License, Version 0.51 
 * (the "License"); you may not use this file except in compliance 
 * with the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: SHL-0.51
 *
 * Authors:  Yvan Tortorella <yvan.tortorella@unibo.it>
 * 
 * RedMulE Streamer
 */

module redmule_streamer
  import fpnew_pkg::*;
  import redmule_pkg::*;
  import hci_package::*;
  import hwpe_stream_package::*;
#(
parameter  int unsigned DW      = 288   ,
parameter  int unsigned UW      = 1     ,
parameter  int unsigned AW      = ADDR_W,
localparam int unsigned REALIGN = 1
)(
  input logic                    clk_i,
  input logic                    rst_ni,
  input logic                    test_mode_i,
  input logic                    enable_i,
  input logic                    clear_i,
  // Engine X input + HS signals (output for the streamer)
  hwpe_stream_intf_stream.source x_stream_o,
  // Engine W input + HS signals (output for the streamer)
  hwpe_stream_intf_stream.source w_stream_o,
  // Engine Y input + HS signals (output for the streamer)
  hwpe_stream_intf_stream.source y_stream_o,
  // Engine Z output + HS signals (intput for the streamer)
  hwpe_stream_intf_stream.sink   z_stream_i,
  // TCDM interface between the streamer and the memory
  hci_core_intf.master           tcdm      ,
  
  // Control signals
  input  cntrl_streamer_t        ctrl_i,
  output flgs_streamer_t         flags_o
);

// Here the dynamic mux for virtual_tcdm interfaces
// coming/going from/to the accelerator to/from the memory
hci_core_intf #( .DW ( DW ),
                 .UW ( UW ) ) ldst_tcdm [0:0] ( .clk ( clk_i ) );

hci_core_assign i_ldst_assign ( .tcdm_slave (ldst_tcdm [0]), .tcdm_master (tcdm) );

// Virtual internal TCDM interface splitting the upstream TCDM into two channels:
// * Channel 0 - load channel (from TCDM to stream).
// * Channel 1 - store channel (from stream to TCDM).
hci_core_intf #( .DW ( DW ),
                 .UW ( UW ) ) virt_tcdm [1:0] ( .clk ( clk_i ) );

hci_core_mux_dynamic #(
  .NB_IN_CHAN         ( 2         ),
  .UW                 ( UW        ),
  .DW                 ( DW        )
) i_ldst_mux          (
  .clk_i              ( clk_i     ),
  .rst_ni             ( rst_ni    ),
  .clear_i            ( clear_i   ),
  .in                 ( virt_tcdm ),
  .out                ( ldst_tcdm )
);

/************************************ Store Channel *************************************/
/* The store channel of the streamer connects the incoming stream interface (Z stream)  *
 * to an HCI core sink module that translates the stream into a TCDM protocol. This     *
 * sink module then connects to a cast unit to cast data from one FP format to another. *
 * The result of the cast unit enters a TCDM FIFO that eventually connects to the store *
 * side (virt_tcdm[1]) of the LD/ST multiplexer.                                        */

// Sink module that turns the incoming Z stream into TCDM.
hci_core_intf #( .DW ( DW ),
                 .UW ( UW ) ) zstream2cast ( .clk ( clk_i ) );
hci_core_sink         #(
  .DATA_WIDTH          ( DW                          ),
  .MISALIGNED_ACCESSES ( REALIGN                     )
) i_stream_sink      (                             
  .clk_i               ( clk_i                       ),
  .rst_ni              ( rst_ni                      ),
  .test_mode_i         ( test_mode_i                 ),
  .clear_i             ( clear_i                     ),
  .enable_i            ( enable_i                    ),
  .tcdm                ( zstream2cast                ),
  .stream              ( z_stream_i                  ),
  .ctrl_i              ( ctrl_i.z_stream_sink_ctrl   ),
  .flags_o             ( flags_o.z_stream_sink_flags )
);

// Store interface FIFO buses.
hci_core_intf #( .DW ( DW ),
                 .UW ( UW ) ) z_fifo_d ( .clk ( clk_i ) );
hci_core_intf #( .DW ( DW ),
                 .UW ( UW ) ) z_fifo_q ( .clk ( clk_i ) );

logic cast;
assign cast = (ctrl_i.input_cast_src_fmt == fpnew_pkg::FP16) ? 1'b0: 1'b1;

// Store cast unit
// This unit uses only the data bus of the TCDM interface. The other buses
// are assigned manually.
redmule_castout #(
  .FpFmtConfig   ( FpFmtConfig  ),
  .IntFmtConfig  ( IntFmtConfig ),
  .src_format    ( FPFORMAT     )
) i_store_cast   (
  .clk_i                                     ,
  .rst_ni                                    ,
  .clear_i                                   ,
  .cast_i       ( cast                      ),
  .src_i        (zstream2cast.data          ),
  .dst_fmt_i    (ctrl_i.output_cast_dst_fmt ),
  .dst_o        (z_fifo_d.data              )
);

// Left TCDM buses assignment.
assign z_fifo_d.req         = zstream2cast.req;
assign zstream2cast.gnt     = z_fifo_d.gnt;
assign z_fifo_d.add         = zstream2cast.add;
assign z_fifo_d.wen         = zstream2cast.wen;
assign z_fifo_d.be          = zstream2cast.be;
assign z_fifo_d.boffs       = zstream2cast.boffs;
assign z_fifo_d.lrdy        = zstream2cast.lrdy;
assign z_fifo_d.user        = zstream2cast.user;
assign zstream2cast.r_data  = z_fifo_d.r_data;
assign zstream2cast.r_valid = z_fifo_d.r_valid;
assign zstream2cast.r_opc   = z_fifo_d.r_opc;
assign zstream2cast.r_user  = z_fifo_d.r_user;

// HCI store fifo.
hci_core_fifo #(
  .FIFO_DEPTH  ( 2  ),
  .DW          ( DW )
) i_store_fifo (
  .clk_i       ( clk_i    ),
  .rst_ni      ( rst_ni   ),
  .clear_i     ( clear_i  ),
  .flags_o     (          ),
  .tcdm_slave  ( z_fifo_d ),
  .tcdm_master ( z_fifo_q )
);

// Assigning the store FIFO output to the store side of the LD/ST multiplexer.
hci_core_assign i_store_assign ( .tcdm_slave (z_fifo_q), .tcdm_master (virt_tcdm[1]) );

/**************************************** Load Channel ****************************************/
/* The load channel of the streamer connects the incoming TCDM interface to three different   *
 * stream interfaces: X stream (ID: 0), W stream (ID: 1), and Y stream (ID: 2). The load side *
 * (virt_tcdm[0]) of the LD/ST multiplexer connects to another multiplexer that splits the    *
 * icoming TCDM bus into three TCDM interfaces (X, W, and Y). Each interface connects to its  *
 * own FIFO, and then to a cas unit that casts the data from one FP format to another. Then,  *
 * the output of the cast connects to a dedicated HCI core source unit used to translate the  *
 * incoming TCDM protocls into stream.                                                        */

// Virtual TCDM interfaces (source type) for input matrices
// X -> source[0]
// W -> source[1]
// Y -> source[2]
hci_core_intf #( .DW ( DW ),
                 .UW ( UW ) ) source [NumStreamSources-1:0] ( .clk ( clk_i ) );
hci_core_intf #( .DW ( DW ),
                 .UW ( UW ) ) mux_tcdm [0:0] ( .clk ( clk_i ) );

// Dynamic multiplexer splitting the TCDM-side interface into
// X, W, and Y interfaces
hci_core_mux_dynamic #(
  .NB_IN_CHAN         ( NumStreamSources ),
  .UW                 ( UW               ),
  .DW                 ( DW               )
) i_source_mux        (
  .clk_i              ( clk_i            ),
  .rst_ni             ( rst_ni           ),
  .clear_i            ( clear_i          ),
  .in                 ( source           ),
  .out                ( virt_tcdm[0:0]   )
);

// One TCDM FIFO and one HCI core source unit per stream channel.
hci_core_intf #( .DW ( DW ),
                 .UW ( UW ) ) load_fifo_d [NumStreamSources-1:0] ( .clk ( clk_i ) );

hci_core_intf #( .DW ( DW ),
                 .UW ( UW ) ) load_fifo_q [NumStreamSources-1:0] ( .clk ( clk_i ) );

hci_core_intf #( .DW ( DW ),
                 .UW ( UW ) ) tcdm_cast [NumStreamSources-1:0] ( .clk ( clk_i ) );

hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW ) ) out_stream [NumStreamSources-1:0] ( .clk( clk_i ) );

hci_package::hci_streamer_ctrl_t  [NumStreamSources-1:0] source_ctrl;
hci_package::hci_streamer_flags_t [NumStreamSources-1:0] source_flags;

// Assign input control buses to the relative ID in the vector.
assign source_ctrl[XsourceStreamId] = ctrl_i.x_stream_source_ctrl;
assign source_ctrl[WsourceStreamId] = ctrl_i.w_stream_source_ctrl;
assign source_ctrl[YsourceStreamId] = ctrl_i.y_stream_source_ctrl;

for (genvar i = 0; i < NumStreamSources; i++) begin: gen_tcdm2stream

  hci_core_assign i_load_assign ( .tcdm_slave (load_fifo_d[i]), .tcdm_master (source[i]) );

  hci_core_fifo #(
    .FIFO_DEPTH  ( 2  ),
    .DW          ( DW )
  ) i_load_tcdm_fifo (
    .clk_i       ( clk_i          ),
    .rst_ni      ( rst_ni         ),
    .clear_i     ( clear_i        ),
    .flags_o     (                ),
    .tcdm_slave  ( load_fifo_q[i] ),
    .tcdm_master ( load_fifo_d[i] )
  );

  // Load cast unit
  // This unit uses only the data bus of the TCDM interface. The other buses
  // are assigned manually.
  redmule_castin #(
    .FpFmtConfig  ( FpFmtConfig  ),
    .IntFmtConfig ( IntFmtConfig ),
    .dst_format   ( FPFORMAT     )
  ) i_load_cast   (
    .clk_i                                     ,
    .rst_ni                                    ,
    .clear_i                                   ,
    .cast_i       ( cast                      ),
    .src_i        ( load_fifo_q[i].r_data     ),
    .src_fmt_i    ( ctrl_i.input_cast_src_fmt ),
    .dst_o        ( tcdm_cast[i].r_data       )
  );

  // Left TCDM buses assignment.
  assign load_fifo_q[i].req   = tcdm_cast[i].req;
  assign tcdm_cast[i].gnt     = load_fifo_q[i].gnt;
  assign load_fifo_q[i].add   = tcdm_cast[i].add;
  assign load_fifo_q[i].wen   = tcdm_cast[i].wen;
  assign load_fifo_q[i].data  = tcdm_cast[i].data;
  assign load_fifo_q[i].be    = tcdm_cast[i].be;
  assign load_fifo_q[i].boffs = tcdm_cast[i].boffs;
  assign load_fifo_q[i].lrdy  = tcdm_cast[i].lrdy;
  assign load_fifo_q[i].user  = tcdm_cast[i].user;
  assign tcdm_cast[i].r_valid = load_fifo_q[i].r_valid;
  assign tcdm_cast[i].r_opc   = load_fifo_q[i].r_opc;
  assign tcdm_cast[i].r_user  = load_fifo_q[i].r_user;

  hci_core_source       #(
    .DATA_WIDTH          ( DW              ),
    .MISALIGNED_ACCESSES ( REALIGN         )
  ) i_stream_source      (
    .clk_i               ( clk_i           ),
    .rst_ni              ( rst_ni          ),
    .test_mode_i         ( test_mode_i     ),
    .clear_i             ( clear_i         ),
    .enable_i            ( enable_i        ),
    .tcdm                ( tcdm_cast[i]    ),
    .stream              ( out_stream[i]   ),
    .ctrl_i              ( source_ctrl[i]  ),
    .flags_o             ( source_flags[i] )
  );
  
end

// Assign flags in the vector to the relative output buses.
assign flags_o.x_stream_source_flags = source_flags[XsourceStreamId];
assign flags_o.w_stream_source_flags = source_flags[WsourceStreamId];
assign flags_o.y_stream_source_flags = source_flags[YsourceStreamId];

// Assign resulting streams.
hwpe_stream_assign i_xstream_assign ( .push_i( out_stream[XsourceStreamId] ) ,
                                      .pop_o ( x_stream_o                  ) );

hwpe_stream_assign i_wstream_assign ( .push_i( out_stream[WsourceStreamId] ) ,
                                      .pop_o ( w_stream_o                  ) );

hwpe_stream_assign i_ystream_assign ( .push_i( out_stream[YsourceStreamId] ) ,
                                      .pop_o ( y_stream_o                  ) );

endmodule : redmule_streamer
