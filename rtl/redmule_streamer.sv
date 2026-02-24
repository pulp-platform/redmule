// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
// Andrea Belano <andrea.belano2@unibo.it>
// Arpan Suravi Prasad<prasadar@iis.ee.ethz.ch>
//

`include "hci_helpers.svh"

module redmule_streamer
  import fpnew_pkg::*;
  import redmule_pkg::*;
  import hci_package::*;
  import hwpe_stream_package::*;
#(
  parameter  int unsigned           DataW        = MaxDataW,
  parameter  int unsigned           MisalignedAccessSupport = MisalignedAccessSupportDefault,
  parameter  int unsigned           FpFormat     = FP16    ,
  parameter  int unsigned           EccChunkSize = 32      ,
  parameter fpnew_pkg::fmt_logic_t  FpFmtConfig  = 6'b001101,
  parameter fpnew_pkg::ifmt_logic_t IntFmtConfig = 4'b1000,
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
  hci_core_intf.initiator        tcdm      ,

  // Control signals
  input  cntrl_streamer_t        ctrl_i,
  output flgs_streamer_t         flags_o
);

localparam int unsigned EW  = `HCI_SIZE_GET_EW(tcdm);

// Non-ECC variant of tcdm size params, used for all internal (non-ECC) interfaces
localparam hci_size_parameter_t `HCI_SIZE_PARAM(ldst_tcdm) = '{
  DW:  `HCI_SIZE_GET_DW(tcdm),
  AW:  `HCI_SIZE_GET_AW(tcdm),
  BW:  `HCI_SIZE_GET_BW(tcdm),
  UW:  `HCI_SIZE_GET_UW(tcdm),
  IW:  `HCI_SIZE_GET_IW(tcdm),
  EW:  DEFAULT_EW,
  EHW: `HCI_SIZE_GET_EHW(tcdm)
};

// Here the dynamic mux for virtual_tcdm interfaces
// coming/going from/to the accelerator to/from the memory
hci_core_intf #(
`ifndef SYNTHESIS
  .WAIVE_RSP3_ASSERT ( 1'b1 ), // waive RSP-3 on memory-side of HCI FIFO
  .WAIVE_RSP5_ASSERT ( 1'b1 ), // waive RSP-5 on memory-side of HCI FIFO
`endif
  .DW  ( `HCI_SIZE_GET_DW(ldst_tcdm)  ),
  .AW  ( `HCI_SIZE_GET_AW(ldst_tcdm)  ),
  .BW  ( `HCI_SIZE_GET_BW(ldst_tcdm)  ),
  .UW  ( `HCI_SIZE_GET_UW(ldst_tcdm)  ),
  .IW  ( `HCI_SIZE_GET_IW(ldst_tcdm)  ),
  .EW  ( `HCI_SIZE_GET_EW(ldst_tcdm)  ),
  .EHW ( `HCI_SIZE_GET_EHW(ldst_tcdm) )
) ldst_tcdm ( .clk ( clk_i ) );

hci_core_intf #(
`ifndef SYNTHESIS
  .WAIVE_RSP3_ASSERT ( 1'b1 ), // waive RSP-3 on memory-side of HCI FIFO
  .WAIVE_RSP5_ASSERT ( 1'b1 ), // waive RSP-5 on memory-side of HCI FIFO
`endif
  .DW  ( `HCI_SIZE_GET_DW(ldst_tcdm)  ),
  .AW  ( `HCI_SIZE_GET_AW(ldst_tcdm)  ),
  .BW  ( `HCI_SIZE_GET_BW(ldst_tcdm)  ),
  .UW  ( `HCI_SIZE_GET_UW(ldst_tcdm)  ),
  .IW  ( `HCI_SIZE_GET_IW(ldst_tcdm)  ),
  .EW  ( `HCI_SIZE_GET_EW(ldst_tcdm)  ),
  .EHW ( `HCI_SIZE_GET_EHW(ldst_tcdm) )
) ldst_tcdm_pre_r_id ( .clk ( clk_i ) );

hci_core_intf #(
`ifndef SYNTHESIS
  .WAIVE_RSP3_ASSERT ( 1'b1 ), // waive RSP-3 on memory-side of HCI FIFO
  .WAIVE_RSP5_ASSERT ( 1'b1 ), // waive RSP-5 on memory-side of HCI FIFO
`endif
  .DW  ( `HCI_SIZE_GET_DW(ldst_tcdm)  ),
  .AW  ( `HCI_SIZE_GET_AW(ldst_tcdm)  ),
  .BW  ( `HCI_SIZE_GET_BW(ldst_tcdm)  ),
  .UW  ( `HCI_SIZE_GET_UW(ldst_tcdm)  ),
  .IW  ( `HCI_SIZE_GET_IW(ldst_tcdm)  ),
  .EW  ( `HCI_SIZE_GET_EW(ldst_tcdm)  ),
  .EHW ( `HCI_SIZE_GET_EHW(ldst_tcdm) )
) ldst_tcdm_pre_r_valid ( .clk ( clk_i ) );

if (EW > 1) begin : gen_ecc_encoder
  logic [`HCI_SIZE_GET_DW(tcdm)/EccChunkSize-1:0] data_single_err, data_multi_err;
  logic                          meta_single_err, meta_multi_err;

  hci_ecc_enc #(
    .DW ( `HCI_SIZE_GET_DW(tcdm) ),
    .`HCI_SIZE_PARAM(tcdm_target)    ( `HCI_SIZE_PARAM(ldst_tcdm) ),
    .`HCI_SIZE_PARAM(tcdm_initiator) ( `HCI_SIZE_PARAM(tcdm)      )
  ) i_ecc_enc (
    .r_data_single_err_o ( data_single_err ),
    .r_data_multi_err_o  ( data_multi_err  ),
    .r_meta_single_err_o ( meta_single_err ),
    .r_meta_multi_err_o  ( meta_multi_err  ),
    .tcdm_target         ( ldst_tcdm       ),
    .tcdm_initiator      ( tcdm            )
  );
end else begin : gen_ldst_assign
  hci_core_assign i_ldst_assign ( .tcdm_target (ldst_tcdm), .tcdm_initiator (tcdm) );
end

// Virtual internal TCDM interface splitting the upstream TCDM
hci_core_intf #(
`ifndef SYNTHESIS
  .WAIVE_RSP3_ASSERT ( 1'b1 ), // waive RSP-3 on memory-side of HCI FIFO
  .WAIVE_RSP5_ASSERT ( 1'b1 ), // waive RSP-5 on memory-side of HCI FIFO
  .WAIVE_RQ3_ASSERT  ( 1'b1 ),
  .WAIVE_RQ4_ASSERT  ( 1'b1 ),
`endif
  .DW  ( `HCI_SIZE_GET_DW(ldst_tcdm)  ),
  .AW  ( `HCI_SIZE_GET_AW(ldst_tcdm)  ),
  .BW  ( `HCI_SIZE_GET_BW(ldst_tcdm)  ),
  .UW  ( `HCI_SIZE_GET_UW(ldst_tcdm)  ),
  .IW  ( `HCI_SIZE_GET_IW(ldst_tcdm)  ),
  .EW  ( `HCI_SIZE_GET_EW(ldst_tcdm)  ),
  .EHW ( `HCI_SIZE_GET_EHW(ldst_tcdm) )
) virt_tcdm [0:NumStreamSources+1] ( .clk ( clk_i ) );

redmule_mux #(
  .NB_CHAN   (NumStreamSources+2),
  .`HCI_SIZE_PARAM(out) ( `HCI_SIZE_PARAM(ldst_tcdm) )
) i_mux (
  .clk_i      ( clk_i                 ),
  .rst_ni     ( rst_ni                ),
  .clear_i    ( clear_i               ),
  .in         ( virt_tcdm             ),
  .out        ( ldst_tcdm_pre_r_valid )
);

hci_core_r_valid_filter #(
  .`HCI_SIZE_PARAM(tcdm_target)   ( `HCI_SIZE_PARAM(ldst_tcdm) )
) i_tcdm_r_valid_filter (
    .clk_i          (  clk_i                 ),
    .rst_ni         (  rst_ni                ),
    .clear_i        (  clear_i               ),
    .enable_i       (  1'b1                  ),
    .tcdm_target    (  ldst_tcdm_pre_r_valid ),
    .tcdm_initiator (  ldst_tcdm             )
);

/************************************ Store Channel *************************************/
/* The store channel of the streamer connects the incoming stream interface (Z stream)  *
 * to an HCI core sink module that translates the stream into a TCDM protocol. This     *
 * sink module then connects to a cast unit to cast data from one FP format to another. *
 * The result of the cast unit enters a TCDM FIFO that eventually connects to the store *
 * side (virt_tcdm[NumStreamSources]) of the LD/ST multiplexer.                         */

// Sink module that turns the incoming Z stream into TCDM.
`HCI_INTF_EXPLICIT_PARAM(zstream2cast, clk_i, `HCI_SIZE_PARAM(ldst_tcdm));
hci_core_sink         #(
  .MISALIGNED_ACCESSES ( MisalignedAccessSupport ),
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

// Store interface FIFO buses.
hci_core_intf #(
`ifndef SYNTHESIS
  .WAIVE_RSP3_ASSERT ( 1'b1 ), // waive RSP-3 on memory-side of HCI FIFO
  .WAIVE_RSP5_ASSERT ( 1'b1 ),  // waive RSP-5 on memory-side of HCI FIFO
`endif
  .DW  ( `HCI_SIZE_GET_DW(ldst_tcdm)  ),
  .AW  ( `HCI_SIZE_GET_AW(ldst_tcdm)  ),
  .BW  ( `HCI_SIZE_GET_BW(ldst_tcdm)  ),
  .UW  ( `HCI_SIZE_GET_UW(ldst_tcdm)  ),
  .IW  ( `HCI_SIZE_GET_IW(ldst_tcdm)  ),
  .EW  ( `HCI_SIZE_GET_EW(ldst_tcdm)  ),
  .EHW ( `HCI_SIZE_GET_EHW(ldst_tcdm) )
) z_fifo_d ( .clk ( clk_i ) );
`HCI_INTF_EXPLICIT_PARAM(z_fifo_q, clk_i, `HCI_SIZE_PARAM(ldst_tcdm));

logic cast;
assign cast = (ctrl_i.input_cast_src_fmt == fpnew_pkg::FP16) ? 1'b0: 1'b1;

// Store cast unit
// This unit uses only the data bus of the TCDM interface. The other buses
// are assigned manually.
redmule_castout #(
  .DataW         ( DataW        ),
  .FpFmtConfig   ( FpFmtConfig  ),
  .IntFmtConfig  ( IntFmtConfig ),
  .SrcFormat     ( FpFormat     )
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
assign z_fifo_d.req          = zstream2cast.req;
assign zstream2cast.gnt      = z_fifo_d.gnt;
assign z_fifo_d.add          = zstream2cast.add;
assign z_fifo_d.wen          = zstream2cast.wen;
// do not assign z_fifo_d.data <-> zstream2cast.data
assign z_fifo_d.be           = zstream2cast.be;
assign z_fifo_d.r_ready      = zstream2cast.r_ready;
assign z_fifo_d.user         = zstream2cast.user;
assign z_fifo_d.id           = zstream2cast.id;
assign zstream2cast.r_data   = z_fifo_d.r_data;
assign zstream2cast.r_valid  = z_fifo_d.r_valid;
assign zstream2cast.r_user   = z_fifo_d.r_user;
assign zstream2cast.r_id     = z_fifo_d.r_id;
assign z_fifo_d.ereq         = zstream2cast.ereq;
assign zstream2cast.egnt     = z_fifo_d.egnt;
assign zstream2cast.r_evalid = z_fifo_d.r_evalid;
assign z_fifo_d.r_eready     = zstream2cast.r_eready;
assign z_fifo_d.ecc          = zstream2cast.ecc;
assign zstream2cast.r_ecc    = z_fifo_d.r_ecc;

flags_fifo_t store_fifo_flags;

// HCI store fifo.
hci_core_fifo #(
  .FIFO_DEPTH                      ( 2                     ),
  .`HCI_SIZE_PARAM(tcdm_initiator) ( `HCI_SIZE_PARAM(ldst_tcdm) )
) i_store_fifo (
  .clk_i          ( clk_i            ),
  .rst_ni         ( rst_ni           ),
  .clear_i        ( clear_i          ),
  .flags_o        ( store_fifo_flags ),
  .tcdm_target    ( z_fifo_d         ),
  .tcdm_initiator ( z_fifo_q         )
);

assign flags_o.store_fifo_empty = store_fifo_flags.empty;

// Assigning the store FIFO output to the store side of the y/z multiplexer.
hci_core_assign i_store_assign ( .tcdm_target (z_fifo_q), .tcdm_initiator (virt_tcdm[NumStreamSources]) );

/**************************************** Load Channel ****************************************/
/* The load channel of the streamer connects the incoming TCDM interface to three different   *
 * stream interfaces: X stream (ID: 0), W stream (ID: 1), and Y stream (ID: 2). The load side *
 * (virt_tcdm[0]) of the LD/ST multiplexer connects to another multiplexer that splits the    *
 * icoming TCDM bus into three TCDM interfaces (X, W, and Y). Each interface connects to its  *
 * own FIFO, and then to a cas unit that casts the data from one FP format to another. Then,  *
 * the output of the cast connects to a dedicated HCI core source unit used to translate the  *
 * incoming TCDM protocls into stream.                                                        */

// Virtual TCDM interfaces
// X   -> virt_tcdm[0]
// W   -> virt_tcdm[1]
// Y/Z -> virt_tcdm[2]
// R   -> virt_tcdm[3]
// R SINK  -> virt_tcdm[5]

// One TCDM FIFO and one HCI core source unit per stream channel.
hci_core_intf #(
`ifndef SYNTHESIS
  .WAIVE_RSP3_ASSERT ( 1'b1 ), // waive RSP-3 on memory-side of HCI FIFO
  .WAIVE_RSP5_ASSERT ( 1'b1 ),  // waive RSP-5 on memory-side of HCI FIFO
  .WAIVE_RQ4_ASSERT  ( 1'b1 ),
`endif
  .DW  ( `HCI_SIZE_GET_DW(ldst_tcdm)  ),
  .AW  ( `HCI_SIZE_GET_AW(ldst_tcdm)  ),
  .BW  ( `HCI_SIZE_GET_BW(ldst_tcdm)  ),
  .UW  ( `HCI_SIZE_GET_UW(ldst_tcdm)  ),
  .IW  ( `HCI_SIZE_GET_IW(ldst_tcdm)  ),
  .EW  ( `HCI_SIZE_GET_EW(ldst_tcdm)  ),
  .EHW ( `HCI_SIZE_GET_EHW(ldst_tcdm) )
) load_fifo_d [0:NumStreamSources-1] ( .clk ( clk_i ) );

hci_core_intf #(
`ifndef SYNTHESIS
  .WAIVE_RSP3_ASSERT ( 1'b1 ),
  .WAIVE_RSP5_ASSERT ( 1'b1 ),
  .WAIVE_RQ4_ASSERT  ( 1'b1 ),
`endif
  .DW  ( `HCI_SIZE_GET_DW(ldst_tcdm)  ),
  .AW  ( `HCI_SIZE_GET_AW(ldst_tcdm)  ),
  .BW  ( `HCI_SIZE_GET_BW(ldst_tcdm)  ),
  .UW  ( `HCI_SIZE_GET_UW(ldst_tcdm)  ),
  .IW  ( `HCI_SIZE_GET_IW(ldst_tcdm)  ),
  .EW  ( `HCI_SIZE_GET_EW(ldst_tcdm)  ),
  .EHW ( `HCI_SIZE_GET_EHW(ldst_tcdm) )
) load_fifo_q [0:NumStreamSources-1] ( .clk ( clk_i ) );

hci_core_intf #(
`ifndef SYNTHESIS
  .WAIVE_RSP3_ASSERT ( 1'b1 ),
  .WAIVE_RSP5_ASSERT ( 1'b1 ),
  .WAIVE_RQ4_ASSERT  ( 1'b1 ),
`endif
  .DW  ( `HCI_SIZE_GET_DW(ldst_tcdm)  ),
  .AW  ( `HCI_SIZE_GET_AW(ldst_tcdm)  ),
  .BW  ( `HCI_SIZE_GET_BW(ldst_tcdm)  ),
  .UW  ( `HCI_SIZE_GET_UW(ldst_tcdm)  ),
  .IW  ( `HCI_SIZE_GET_IW(ldst_tcdm)  ),
  .EW  ( `HCI_SIZE_GET_EW(ldst_tcdm)  ),
  .EHW ( `HCI_SIZE_GET_EHW(ldst_tcdm) )
) tcdm_cast [0:NumStreamSources-1] ( .clk ( clk_i ) );

hwpe_stream_intf_stream #( .DATA_WIDTH ( DataW ) ) out_stream [0:NumStreamSources-1] ( .clk( clk_i ) );

hci_package::hci_streamer_ctrl_t        [NumStreamSources-1:0] source_ctrl;
hci_package::hci_streamer_flags_t       [NumStreamSources-1:0] source_flags;

// Assign input control buses to the relative ID in the vector.
assign source_ctrl[XsourceStreamId]      = ctrl_i.x_stream_source_ctrl;
assign source_ctrl[WsourceStreamId]      = ctrl_i.w_stream_source_ctrl;
assign source_ctrl[YsourceStreamId]      = ctrl_i.y_stream_source_ctrl;

for (genvar i = 0; i < NumStreamSources; i++) begin: gen_tcdm2stream

  logic source_enable;

  hci_core_assign i_load_assign ( .tcdm_target (load_fifo_d[i]), .tcdm_initiator (virt_tcdm[i]) );

  hci_core_fifo #(
    .FIFO_DEPTH  ( 4  ), // to avoid protocol violations, as the consumer has a throughput
                         // of 1 packet over 4 cycles, we need a depth of 4 elements.
    .`HCI_SIZE_PARAM(tcdm_initiator) ( `HCI_SIZE_PARAM(ldst_tcdm) )
  ) i_load_tcdm_fifo (
    .clk_i          ( clk_i          ),
    .rst_ni         ( rst_ni         ),
    .clear_i        ( clear_i        ),
    .flags_o        (                ),
    .tcdm_target    ( load_fifo_q[i] ),
    .tcdm_initiator ( load_fifo_d[i] )
  );

  // Load cast unit
  // This unit uses only the data bus of the TCDM interface. The other buses
  // are assigned manually.
  redmule_castin #(
    .DataW        ( DataW        ),
    .FpFmtConfig  ( FpFmtConfig  ),
    .IntFmtConfig ( IntFmtConfig ),
    .DstFormat    ( FpFormat     )
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
  assign load_fifo_q[i].req      = tcdm_cast[i].req;
  assign tcdm_cast[i].gnt        = load_fifo_q[i].gnt;
  assign load_fifo_q[i].add      = tcdm_cast[i].add;
  assign load_fifo_q[i].wen      = tcdm_cast[i].wen;
  assign load_fifo_q[i].data     = tcdm_cast[i].data;
  assign load_fifo_q[i].be       = tcdm_cast[i].be;
  assign load_fifo_q[i].r_ready  = tcdm_cast[i].r_ready;
  assign load_fifo_q[i].user     = tcdm_cast[i].user;
  assign load_fifo_q[i].id       = tcdm_cast[i].id;
  assign tcdm_cast[i].r_valid    = load_fifo_q[i].r_valid;
  // do not assign tcdm_cast[i].r_data = load_fifo_q[i].r_data
  assign tcdm_cast[i].r_opc      = load_fifo_q[i].r_opc;
  assign tcdm_cast[i].r_user     = load_fifo_q[i].r_user;
  assign tcdm_cast[i].r_id       = load_fifo_q[i].r_id;
  assign load_fifo_q[i].ereq     = tcdm_cast[i].ereq;
  assign tcdm_cast[i].egnt       = load_fifo_q[i].egnt;
  assign tcdm_cast[i].r_evalid   = load_fifo_q[i].r_evalid;
  assign load_fifo_q[i].r_eready = tcdm_cast[i].r_eready;
  assign load_fifo_q[i].ecc      = tcdm_cast[i].ecc;
  assign tcdm_cast[i].r_ecc      = load_fifo_q[i].r_ecc;

  if (i == WsourceStreamId) begin
    assign source_enable = enable_i & ~ctrl_i.receive_w_stream;
  end else if (i == XsourceStreamId) begin
    assign source_enable = enable_i & ~ctrl_i.receive_x_stream;
  end else begin
    assign source_enable = enable_i;
  end

  hci_core_source       #(
    .MISALIGNED_ACCESSES   ( MisalignedAccessSupport ),
    .`HCI_SIZE_PARAM(tcdm) ( `HCI_SIZE_PARAM(ldst_tcdm) )
  ) i_stream_source      (
    .clk_i               ( clk_i           ),
    .rst_ni              ( rst_ni          ),
    .test_mode_i         ( test_mode_i     ),
    .clear_i             ( clear_i         ),
    .enable_i            ( source_enable   ),
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

`ifndef SYNTHESIS
`ifndef VERILATOR
`ifndef VCS
initial begin
  tcdm_size_check_dw : assert(`HCI_SIZE_PARAM(tcdm).DW == ((MisalignedAccessSupport == 1) ? (DataW + 32) : DataW));
end
`endif
`endif
`endif

endmodule : redmule_streamer
