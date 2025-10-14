// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
// Andrea Belano <andrea.belano2@unibo.it>
//

`include "hci_helpers.svh"

module redmule_streamer
  import fpnew_pkg::*;
  import redmule_pkg::*;
  import hci_package::*;
  import hwpe_stream_package::*;
#(
  localparam int unsigned REALIGN = 0     ,
  parameter hci_size_parameter_t `HCI_SIZE_PARAM(tcdm) = '0
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
  hci_outstanding_intf.initiator        tcdm,

  // ECC error signals
  output errs_streamer_t         ecc_errors_o,
  // Control signals
  input  cntrl_streamer_t        ctrl_i,
  output flgs_streamer_t         flags_o
);

localparam int unsigned DW  = `HCI_SIZE_GET_DW(tcdm);
localparam int unsigned UW  = `HCI_SIZE_GET_UW(tcdm);
localparam int unsigned IW  = `HCI_SIZE_GET_IW(tcdm);
localparam int unsigned EW  = `HCI_SIZE_GET_EW(tcdm);
localparam int unsigned EHW  = `HCI_SIZE_GET_EHW(tcdm);

// this localparam is reused for all internal, non-ecc HCI interfaces
localparam hci_size_parameter_t `HCI_SIZE_PARAM(ldst_tcdm) = '{
  DW:  DW,
  AW:  DEFAULT_AW,
  BW:  DEFAULT_BW,
  UW:  UW,
  IW:  IW,
  EW:  EW,
  EHW: EHW
};

// Virtual internal TCDM interface splitting the upstream TCDM
// X   -> virt_tcdm[0]
// W   -> virt_tcdm[1]
// Y   -> virt_tcdm[2]
// Z   -> virt_tcdm[3]
hci_outstanding_intf #(
  .DW ( DW ),
  .UW ( UW ),
  .IW ( IW ) ) virt_tcdm [0:NumStreamSources] ( .clk ( clk_i ) );
hci_outstanding_intf #(
  .DW ( DW ),
  .UW ( UW ),
  .IW ( IW ) ) virt_tcdm_rob [0:NumStreamSources] ( .clk ( clk_i ) );

localparam int unsigned ROB_NW = 1 << UW;

hci_outstanding_rob #(
	.ROB_NW ( ROB_NW ),
	.`HCI_SIZE_PARAM(out) ( `HCI_SIZE_PARAM(ldst_tcdm) )
) i_streamer_rob_x (
	.clk_i 	( clk_i 	),
	.rst_ni ( rst_ni 	),
	.in 	( virt_tcdm[0] ),
	.out 	( virt_tcdm_rob[0] )
);
hci_outstanding_rob #(
	.ROB_NW ( ROB_NW ),
	.`HCI_SIZE_PARAM(out) ( `HCI_SIZE_PARAM(ldst_tcdm) )
) i_streamer_rob_w (
	.clk_i 	( clk_i 	),
	.rst_ni ( rst_ni 	),
	.in 	( virt_tcdm[1] ),
	.out 	( virt_tcdm_rob[1] )
);
hci_outstanding_rob #(
	.ROB_NW ( ROB_NW ),
	.`HCI_SIZE_PARAM(out) ( `HCI_SIZE_PARAM(ldst_tcdm) )
) i_streamer_rob_y (
	.clk_i 	( clk_i 	),
	.rst_ni ( rst_ni 	),
	.in 	( virt_tcdm[2] ),
	.out 	( virt_tcdm_rob[2] )
);

flags_fifo_t z_fifo_flags;
logic [NumStreamSources:0][$clog2(NumStreamSources+1)-1:0] priority_encoding;
assign priority_encoding[1] = 0;
assign priority_encoding[2] = z_fifo_flags.full & ctrl_i.z_priority ? 3 : 1;
assign priority_encoding[0] = 2;
assign priority_encoding[3] = z_fifo_flags.full & ctrl_i.z_priority ? 1 : 3;
hci_outstanding_fifo #(
  .FIFO_DEPTH ( ARRAY_WIDTH / 4 ),
  .`HCI_SIZE_PARAM(tcdm_initiator) ( `HCI_SIZE_PARAM(ldst_tcdm) )
) i_z_fifo (
  .clk_i  ( clk_i   ),
  .rst_ni ( rst_ni  ),
  .clear_i         ( clear_i          ),
  .flags_o         ( z_fifo_flags     ),
  .tcdm_target     ( virt_tcdm[3]     ),
  .tcdm_initiator  ( virt_tcdm_rob[3] )
);

// XWYZ-MUX A single TCDM port is used to load XW and to store Z / load Y
hci_outstanding_mux #(
  .NB_CHAN              ( NumStreamSources+1         ),
  .`HCI_SIZE_PARAM(out) ( `HCI_SIZE_PARAM(ldst_tcdm) )
) i_ldst_mux          (
  .clk_i              ( clk_i                ),
  .rst_ni             ( rst_ni               ),
  .clear_i            ( clear_i              ),
  .priority_force_i   ( 1'b1                 ),
  .priority_i         ( priority_encoding    ),
  .in                 ( virt_tcdm_rob        ),
  .out                ( tcdm                 )
);

/************************************ Store Channel *************************************/
/* The store channel of the streamer connects the incoming stream interface (Z stream)  *
 * to an HCI core sink module that translates the stream into a TCDM protocol. This     *
 * sink module then connects to a cast unit to cast data from one FP format to another. *
 * The result of the cast unit enters a TCDM FIFO that eventually connects to the store *
 * side (virt_tcdm[NumStreamSources]) of the LD/ST multiplexer.                         */

hci_outstanding_intf #( 
	.DW ( DW ),
  .UW ( UW ),
  .IW ( IW ) ) zstream2cast ( .clk ( clk_i ) );

// Sink module that turns the incoming Z stream into TCDM.
hci_outstanding_sink #(
  .MISALIGNED_ACCESSES ( REALIGN                      ),
  .`HCI_SIZE_PARAM(tcdm) ( `HCI_SIZE_PARAM(ldst_tcdm) )
) i_stream_sink        (
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

// Store interface.
hci_outstanding_intf #(
  .DW ( DW ),
  .UW ( UW ),
  .IW ( IW ) ) z_store ( .clk ( clk_i ) );

logic cast;
assign cast = (ctrl_i.input_cast_src_fmt == fpnew_pkg::FP16) ? 1'b0: 1'b1;
// Store cast unit
// This unit uses only the data bus of the TCDM interface. The other buses
// are assigned manually.
redmule_castout #(
  .FpFmtConfig   ( FpFmtConfig  ),
  .IntFmtConfig  ( IntFmtConfig ),
  .SrcFormat     ( FPFORMAT     )
) i_store_cast   (
  .clk_i                                     ,
  .rst_ni                                    ,
  .clear_i                                   ,
  .cast_i       ( cast                      ),
  .src_i        (zstream2cast.req_data      ),
  .dst_fmt_i    (ctrl_i.output_cast_dst_fmt ),
  .dst_o        (z_store.req_data           )
);

// Left TCDM buses assignment.
assign z_store.req_add          = zstream2cast.req_add;
assign z_store.req_wen          = zstream2cast.req_wen;
// Do not assign z_store.req_data <-> zstream2cast.req_data
assign z_store.req_be           = zstream2cast.req_be;
assign z_store.req_user         = zstream2cast.req_user;
assign z_store.req_id           = zstream2cast.req_id;
assign z_store.req_valid        = zstream2cast.req_valid;
assign zstream2cast.req_ready   = z_store.req_ready;
// Right TCDM buses assignment.
assign zstream2cast.resp_data   = '0;
assign zstream2cast.resp_user   = '0;
assign zstream2cast.resp_id     = '0;
assign zstream2cast.resp_valid  = 1'b1;
assign z_store.resp_ready       = 1'b1;

// Assigning the store output to the store side of the y/z multiplexer.
hci_outstanding_assign i_store_assign ( .tcdm_target (z_store), .tcdm_initiator (virt_tcdm[3]) );

/**************************************** Load Channel ****************************************/
/* The load channel of the streamer connects the incoming TCDM interface to three different   *
 * stream interfaces: X stream (ID: 0), W stream (ID: 1), and Y stream (ID: 2). The load side *
 * (virt_tcdm[0]) of the LD/ST multiplexer connects to another multiplexer that splits the    *
 * icoming TCDM bus into three TCDM interfaces (X, W, and Y). Each interface connects to its  *
 * own FIFO, and then to a cas unit that casts the data from one FP format to another. Then,  *
 * the output of the cast connects to a dedicated HCI core source unit used to translate the  *
 * incoming TCDM protocls into stream.                                                        */

hci_outstanding_intf #(
  .DW ( DW ),
  .UW ( UW ),
  .IW ( IW ) ) tcdm_cast [0:NumStreamSources-1] ( .clk ( clk_i ) );
hci_outstanding_intf #(
  .DW ( DW ),
  .UW ( UW ),
  .IW ( IW ) ) tcdm_load [0:NumStreamSources-1] ( .clk ( clk_i ) );

hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW ) ) out_stream [NumStreamSources-1:0] ( .clk( clk_i ) );
hci_package::hci_streamer_ctrl_t  [NumStreamSources-1:0] source_ctrl;
hci_package::hci_streamer_flags_t [NumStreamSources-1:0] source_flags;

// Assign input control buses to the relative ID in the vector.
assign source_ctrl[XsourceStreamId]      = ctrl_i.x_stream_source_ctrl;
assign source_ctrl[WsourceStreamId]      = ctrl_i.w_stream_source_ctrl;
assign source_ctrl[YsourceStreamId]      = ctrl_i.y_stream_source_ctrl;

for (genvar i = 0; i < NumStreamSources; i++) begin: gen_tcdm2stream

  hci_outstanding_assign i_load_assign ( .tcdm_target (tcdm_load[i]), .tcdm_initiator (virt_tcdm[i]) );

  // Load cast unit
  // This unit uses only the data bus of the TCDM interface. The other buses
  // are assigned manually.
  redmule_castin #(
    .FpFmtConfig  ( FpFmtConfig  ),
    .IntFmtConfig ( IntFmtConfig ),
    .DstFormat    ( FPFORMAT     )
  ) i_load_cast   (
    .clk_i                                     ,
    .rst_ni                                    ,
    .clear_i                                   ,
    .cast_i       ( cast                      ),
    .src_i        ( tcdm_load[i].resp_data    ),
    .src_fmt_i    ( ctrl_i.input_cast_src_fmt ),
    .dst_o        ( tcdm_cast[i].resp_data    )
  );

  // Left TCDM buses assignment.
  assign tcdm_load[i].req_add    = tcdm_cast[i].req_add;
  assign tcdm_load[i].req_wen    = tcdm_cast[i].req_wen;
  assign tcdm_load[i].req_data   = tcdm_cast[i].req_data;
  assign tcdm_load[i].req_be     = tcdm_cast[i].req_be;
  assign tcdm_load[i].req_user   = tcdm_cast[i].req_user;
  assign tcdm_load[i].req_id     = tcdm_cast[i].req_id;
  assign tcdm_load[i].req_valid  = tcdm_cast[i].req_valid;
  assign tcdm_cast[i].req_ready  = tcdm_load[i].req_ready;
  // Right TCDM buses assignment.
  // Do not assign tcdm_cast[i].resp_data <-> tcdm_load[i].resp_data
  assign tcdm_cast[i].resp_opc   = tcdm_load[i].resp_opc;
  assign tcdm_cast[i].resp_user  = tcdm_load[i].resp_user;
  assign tcdm_cast[i].resp_id    = tcdm_load[i].resp_id;
  assign tcdm_cast[i].resp_valid = tcdm_load[i].resp_valid;
  assign tcdm_load[i].resp_ready = tcdm_cast[i].resp_ready;

  hci_outstanding_source #(
    .ADDR_MIS_DEPTH        ( ROB_NW                     ),
    .MISALIGNED_ACCESSES   ( REALIGN                    ),
    .`HCI_SIZE_PARAM(tcdm) ( `HCI_SIZE_PARAM(ldst_tcdm) )
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
