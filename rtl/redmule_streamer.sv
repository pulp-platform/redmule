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
  hci_variablelatency_intf.initiator   tcdm,

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

// hci-core interface within the streamer
hci_core_intf #(
  .WAIVE_RQ3_ASSERT  ( 1'b1 ),
  .DW  ( DW  ),
  .AW  ( DEFAULT_AW  ),
  .BW  ( DEFAULT_BW  ),
  .UW  ( UW  ),
  .IW  ( IW  ),
  .EW  ( EW  ),
  .EHW ( EHW )
) tcdm_core ( .clk ( clk_i ) );

// Convert variablelatency req to hci-core
hci_variablelatency_tocore #(
) i_convert2core (
  .in (tcdm_core),
  .out     (tcdm)
);

// Virtual internal TCDM interface splitting the upstream TCDM
// X   -> virt_tcdm[0]
// W   -> virt_tcdm[1]
// Y   -> virt_tcdm[2]
// Z   -> virt_tcdm[3]
hci_core_intf #(
  .WAIVE_RQ3_ASSERT  ( 1'b1 ),
  .WAIVE_RQ4_ASSERT  ( 1'b1 ),
  .WAIVE_RSP3_ASSERT ( 1'b1 ),
  .DW ( DW ),
  .AW ( DEFAULT_AW ),
  .BW ( DEFAULT_BW ),
  .UW ( UW ),
  .IW ( IW ),
  .EW ( EW ),
  .EHW ( EHW ) ) virt_tcdm [0:NumStreamSources] ( .clk ( clk_i ) );
hci_core_intf #(
  .WAIVE_RQ3_ASSERT  ( 1'b1 ),
  .WAIVE_RQ4_ASSERT  ( 1'b1 ),
  .WAIVE_RSP3_ASSERT ( 1'b1 ),
  .DW ( DW ),
  .AW ( DEFAULT_AW ),
  .BW ( DEFAULT_BW ),
  .UW ( UW ),
  .IW ( IW ),
  .EW ( EW ),
  .EHW ( EHW ) ) virt_tcdm_rob [0:NumStreamSources] ( .clk ( clk_i ) );

localparam int unsigned ROB_NW = 1 << UW;

hci_core_rob #(
	.ROB_NW ( ROB_NW ),
	.`HCI_SIZE_PARAM(out) ( `HCI_SIZE_PARAM(ldst_tcdm) )
) i_streamer_rob_x (
	.clk_i 	( clk_i 	),
	.rst_ni ( rst_ni 	),
	.in 	( virt_tcdm[0] ),
	.out 	( virt_tcdm_rob[0] )
);
hci_core_rob #(
	.ROB_NW ( ROB_NW ),
	.`HCI_SIZE_PARAM(out) ( `HCI_SIZE_PARAM(ldst_tcdm) )
) i_streamer_rob_w (
	.clk_i 	( clk_i 	),
	.rst_ni ( rst_ni 	),
	.in 	( virt_tcdm[1] ),
	.out 	( virt_tcdm_rob[1] )
);
hci_core_rob #(
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
assign priority_encoding[0] = 0;
assign priority_encoding[1] = 1;
assign priority_encoding[2] = 2;
assign priority_encoding[3] = 3;

hci_core_fifo #(
  .FIFO_DEPTH ( ARRAY_WIDTH ),
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
hci_core_mux_ooo #(
  .NB_CHAN              ( NumStreamSources+1         ),
  .`HCI_SIZE_PARAM(out) ( `HCI_SIZE_PARAM(ldst_tcdm) )
) i_ldst_mux          (
  .clk_i              ( clk_i                ),
  .rst_ni             ( rst_ni               ),
  .clear_i            ( clear_i              ),
  .priority_force_i   ( 1'b1                 ),
  .priority_i         ( priority_encoding    ),
  .in                 ( virt_tcdm_rob        ),
  .out                ( tcdm_core            )
);

/************************************ Store Channel *************************************/
/* The store channel of the streamer connects the incoming stream interface (Z stream)  *
 * to an HCI core sink module that translates the stream into a TCDM protocol. This     *
 * sink module then connects to a cast unit to cast data from one FP format to another. *
 * The result of the cast unit enters a TCDM FIFO that eventually connects to the store *
 * side (virt_tcdm[NumStreamSources]) of the LD/ST multiplexer.                         */

hci_core_intf #(
  .WAIVE_RQ4_ASSERT  ( 1'b1 ),
  .WAIVE_RSP3_ASSERT ( 1'b1 ),
  .DW  ( DW ),
  .AW  ( DEFAULT_AW ),
  .BW  ( DEFAULT_BW ),
  .UW  ( UW ),
  .IW  ( IW ),
  .EW  ( EW ),
  .EHW ( EHW )
) zstream2cast ( .clk ( clk_i ) );

// Sink module that turns the incoming Z stream into TCDM.
hci_core_sink #(
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
hci_core_intf #(
  .WAIVE_RQ4_ASSERT  ( 1'b1 ),
  .WAIVE_RSP3_ASSERT ( 1'b1 ),
  .DW  ( DW ),
  .AW  ( DEFAULT_AW ),
  .BW  ( DEFAULT_BW ),
  .UW  ( UW ),
  .IW  ( IW ),
  .EW  ( EW ),
  .EHW ( EHW )
) z_store ( .clk ( clk_i ) );

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
  .src_i        (zstream2cast.data          ),
  .dst_fmt_i    (ctrl_i.output_cast_dst_fmt ),
  .dst_o        (z_store.data               )
);

// Left TCDM buses assignment.
assign z_store.add          = zstream2cast.add;
assign z_store.wen          = zstream2cast.wen;
// Do not assign z_store.req_data <-> zstream2cast.req_data
assign z_store.be           = zstream2cast.be;
assign z_store.user         = zstream2cast.user;
assign z_store.id           = zstream2cast.id;
assign z_store.ecc          = zstream2cast.ecc;
assign z_store.req          = zstream2cast.req;
assign z_store.ereq         = zstream2cast.ereq;
assign zstream2cast.gnt     = z_store.gnt;
assign zstream2cast.egnt    = z_store.egnt;
// Right TCDM buses assignment.
assign zstream2cast.r_data   = '0;
assign zstream2cast.r_user   = '0;
assign zstream2cast.r_id     = '0;
assign zstream2cast.r_ecc    = '0;
assign zstream2cast.r_valid  = 1'b1;
assign zstream2cast.r_evalid = '0;
assign z_store.r_ready       = 1'b1;
assign z_store.r_eready      = '1;

// Assigning the store output to the store side of the y/z multiplexer.
hci_core_assign i_store_assign ( .tcdm_target (z_store), .tcdm_initiator (virt_tcdm[3]) );

/**************************************** Load Channel ****************************************/
/* The load channel of the streamer connects the incoming TCDM interface to three different   *
 * stream interfaces: X stream (ID: 0), W stream (ID: 1), and Y stream (ID: 2). The load side *
 * (virt_tcdm[0]) of the LD/ST multiplexer connects to another multiplexer that splits the    *
 * icoming TCDM bus into three TCDM interfaces (X, W, and Y). Each interface connects to its  *
 * own FIFO, and then to a cas unit that casts the data from one FP format to another. Then,  *
 * the output of the cast connects to a dedicated HCI core source unit used to translate the  *
 * incoming TCDM protocls into stream.                                                        */

hci_core_intf #(
  .WAIVE_RQ4_ASSERT  ( 1'b1 ),
  .WAIVE_RSP3_ASSERT ( 1'b1 ),
  .DW ( DW ),
  .AW ( DEFAULT_AW ),
  .BW ( DEFAULT_BW ),
  .UW ( UW ),
  .IW ( IW ),
  .EW ( EW ),
  .EHW ( EHW ) ) tcdm_cast [0:NumStreamSources-1] ( .clk ( clk_i ) );
hci_core_intf #(
  .WAIVE_RQ4_ASSERT  ( 1'b1 ),
  .WAIVE_RSP3_ASSERT ( 1'b1 ),
  .DW ( DW ),
  .AW ( DEFAULT_AW ),
  .BW ( DEFAULT_BW ),
  .UW ( UW ),
  .IW ( IW ),
  .EW ( EW ),
  .EHW ( EHW ) ) tcdm_load [0:NumStreamSources-1] ( .clk ( clk_i ) );

hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW ) ) out_stream [NumStreamSources-1:0] ( .clk( clk_i ) );
hci_package::hci_streamer_ctrl_t  [NumStreamSources-1:0] source_ctrl;
hci_package::hci_streamer_flags_t [NumStreamSources-1:0] source_flags;

// Assign input control buses to the relative ID in the vector.
assign source_ctrl[XsourceStreamId]      = ctrl_i.x_stream_source_ctrl;
assign source_ctrl[WsourceStreamId]      = ctrl_i.w_stream_source_ctrl;
assign source_ctrl[YsourceStreamId]      = ctrl_i.y_stream_source_ctrl;

for (genvar i = 0; i < NumStreamSources; i++) begin: gen_tcdm2stream

  hci_core_assign i_load_assign ( .tcdm_target (tcdm_load[i]), .tcdm_initiator (virt_tcdm[i]) );

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
    .src_i        ( tcdm_load[i].r_data       ),
    .src_fmt_i    ( ctrl_i.input_cast_src_fmt ),
    .dst_o        ( tcdm_cast[i].r_data       )
  );

  // Left TCDM buses assignment.
  assign tcdm_load[i].add      = tcdm_cast[i].add;
  assign tcdm_load[i].wen      = tcdm_cast[i].wen;
  assign tcdm_load[i].data     = tcdm_cast[i].data;
  assign tcdm_load[i].be       = tcdm_cast[i].be;
  assign tcdm_load[i].user     = tcdm_cast[i].user;
  assign tcdm_load[i].id       = tcdm_cast[i].id;
  assign tcdm_load[i].ecc      = tcdm_cast[i].ecc;
  assign tcdm_load[i].req      = tcdm_cast[i].req;
  assign tcdm_load[i].ereq     = tcdm_cast[i].ereq;
  assign tcdm_cast[i].gnt      = tcdm_load[i].gnt;
  assign tcdm_cast[i].egnt     = tcdm_load[i].egnt;
  // Right TCDM buses assignment.
  // Do not assign tcdm_cast[i].resp_data <-> tcdm_load[i].resp_data
  assign tcdm_cast[i].r_opc    = tcdm_load[i].r_opc;
  assign tcdm_cast[i].r_user   = tcdm_load[i].r_user;
  assign tcdm_cast[i].r_id     = tcdm_load[i].r_id;
  assign tcdm_cast[i].r_ecc    = tcdm_load[i].r_ecc;
  assign tcdm_cast[i].r_valid  = tcdm_load[i].r_valid;
  assign tcdm_cast[i].r_evalid = tcdm_load[i].r_evalid;
  assign tcdm_load[i].r_ready  = tcdm_cast[i].r_ready;
  assign tcdm_load[i].r_eready = tcdm_cast[i].r_eready;

  hci_core_source #(
    .ADDR_MIS_DEPTH        ( ROB_NW                     ),
    .MISALIGNED_ACCESSES   ( REALIGN                    ),
    .RESP_FIFO_DEPTH       ( ARRAY_HEIGHT*(PIPE_REGS+1) ),
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
