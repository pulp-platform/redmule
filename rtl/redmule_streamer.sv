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

`include "hci_helpers.svh"

module redmule_streamer
  import fpnew_pkg::*;
  import redmule_pkg::*;
  import hci_package::*;
  import hwpe_stream_package::*;
#(
parameter  int unsigned DW             = 288   ,
parameter  int unsigned AW             = ADDR_W,
parameter  int unsigned ECC_CHUNK_SIZE = 32    ,
localparam int unsigned REALIGN        = 1     ,
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

localparam int unsigned UW  = `HCI_SIZE_GET_UW(tcdm);
localparam int unsigned EW  = `HCI_SIZE_GET_EW(tcdm);
localparam int unsigned EW_DW     = $clog2(ECC_CHUNK_SIZE)+2;
localparam int unsigned EW_RQMETA = $clog2(AW+DW/8+UW+1)+2;
localparam int unsigned EW_RSMETA = $clog2(UW+1)+2;

// this localparam is reused for all internal HCI interfaces
localparam hci_size_parameter_t `HCI_SIZE_PARAM(ldst_tcdm) = '{
  DW:  DW,
  AW:  DEFAULT_AW,
  BW:  DEFAULT_BW,
  UW:  UW,
  IW:  DEFAULT_IW,
  EW:  EW,
  EHW: DEFAULT_EHW
};

// Here the dynamic mux for virtual_tcdm interfaces
// coming/going from/to the accelerator to/from the memory
hci_core_intf #(
`ifndef SYNTHESIS
  .WAIVE_RSP3_ASSERT ( 1'b1 ), // waive RSP-3 on memory-side of HCI FIFO
  .WAIVE_RSP5_ASSERT ( 1'b1 ),  // waive RSP-5 on memory-side of HCI FIFO
`endif
  .DW ( DW ),
  .UW ( UW ),
  .EW ( EW )
) ldst_tcdm [0:0] ( .clk ( clk_i ) );

hci_core_assign i_ldst_assign ( .tcdm_target (ldst_tcdm [0]), .tcdm_initiator (tcdm) );

// Virtual internal TCDM interface splitting the upstream TCDM into two channels:
// * Channel 0 - load channel (from TCDM to stream).
// * Channel 1 - store channel (from stream to TCDM).
hci_core_intf #(
`ifndef SYNTHESIS
  .WAIVE_RSP3_ASSERT ( 1'b1 ), // waive RSP-3 on memory-side of HCI FIFO
  .WAIVE_RSP5_ASSERT ( 1'b1 ),  // waive RSP-5 on memory-side of HCI FIFO
`endif
  .DW ( DW ),
  .UW ( UW ),
  .EW ( EW )
) virt_tcdm [0:1] ( .clk ( clk_i ) );

hci_core_mux_dynamic #(
  .NB_IN_CHAN          ( 2                          ),
  .`HCI_SIZE_PARAM(in) ( `HCI_SIZE_PARAM(ldst_tcdm) )
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
                 .UW ( UW ),
                 .EW ( EW ) ) zstream2cast ( .clk ( clk_i ) );

if (EW > 1) begin: gen_ecc_sink
  hci_ecc_sink            #(
    .MISALIGNED_ACCESSES   ( REALIGN                     ),
    .`HCI_SIZE_PARAM(tcdm) ( `HCI_SIZE_PARAM(ldst_tcdm)  )
  ) i_stream_ecc_sink      (
    .clk_i                 ( clk_i                       ),
    .rst_ni                ( rst_ni                      ),
    .test_mode_i           ( test_mode_i                 ),
    .clear_i               ( clear_i                     ),
    .enable_i              ( enable_i                    ),
    .tcdm                  ( zstream2cast                ),
    .stream                ( z_stream_i                  ),
    .ctrl_i                ( ctrl_i.z_stream_sink_ctrl   ),
    .flags_o               ( flags_o.z_stream_sink_flags )
  );
end else begin: gen_sink
  hci_core_sink           #(
    .MISALIGNED_ACCESSES   ( REALIGN                     ),
    .`HCI_SIZE_PARAM(tcdm) ( `HCI_SIZE_PARAM(ldst_tcdm)  )
  ) i_stream_sink          (
    .clk_i                 ( clk_i                       ),
    .rst_ni                ( rst_ni                      ),
    .test_mode_i           ( test_mode_i                 ),
    .clear_i               ( clear_i                     ),
    .enable_i              ( enable_i                    ),
    .tcdm                  ( zstream2cast                ),
    .stream                ( z_stream_i                  ),
    .ctrl_i                ( ctrl_i.z_stream_sink_ctrl   ),
    .flags_o               ( flags_o.z_stream_sink_flags )
  );
end

// Store interface FIFO buses.
hci_core_intf #(
`ifndef SYNTHESIS
  .WAIVE_RSP3_ASSERT ( 1'b1 ), // waive RSP-3 on memory-side of HCI FIFO
  .WAIVE_RSP5_ASSERT ( 1'b1 ),  // waive RSP-5 on memory-side of HCI FIFO
`endif
  .DW ( DW ),
  .UW ( UW ),
  .EW ( EW )
) z_fifo_d ( .clk ( clk_i ) );
hci_core_intf #( .DW ( DW ),
                 .UW ( UW ),
                 .EW ( EW ) ) z_fifo_q ( .clk ( clk_i ) );

logic cast;
logic [NumStreamSources-1:0][DW-1:0] pre_castin_r_data;
logic [NumStreamSources-1:0][DW-1:0] post_castin_r_data;
logic [DW-1:0] pre_castout_data;
logic [DW-1:0] post_castout_data;
assign cast = (ctrl_i.input_cast_src_fmt == fpnew_pkg::FP16) ? 1'b0: 1'b1;

if (EW > 1) begin: gen_pre_castout_decoder
    logic [DW/ECC_CHUNK_SIZE-1:0][1:0]  pre_castout_err;
    for(genvar ii=0; ii<DW/ECC_CHUNK_SIZE; ii++) begin : data_decoding
      hsiao_ecc_dec #(
        .DataWidth ( ECC_CHUNK_SIZE ),
        .ProtWidth ( EW_DW          )
      ) i_castout_data_dec (
        .in         ( { zstream2cast.ecc[EW_RQMETA+(ii*EW_DW)+:EW_DW], zstream2cast.data[ii*ECC_CHUNK_SIZE+:ECC_CHUNK_SIZE] } ),
        .out        ( pre_castout_data[ii*ECC_CHUNK_SIZE+:ECC_CHUNK_SIZE] ),
        .syndrome_o (  ),
        .err_o      ( pre_castout_err[ii] )
      );
    end
  end else begin
    assign pre_castout_data = zstream2cast.data;
  end

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
  .src_i        (pre_castout_data           ),
  .dst_fmt_i    (ctrl_i.output_cast_dst_fmt ),
  .dst_o        (post_castout_data             )
);

if (EW > 1) begin: gen_post_castout_encoder
    logic [DW/ECC_CHUNK_SIZE*EW_DW-1:0] post_castout_ecc;
    for(genvar ii=0; ii<DW/ECC_CHUNK_SIZE; ii++) begin : data_encoding
      hsiao_ecc_enc #(
        .DataWidth ( ECC_CHUNK_SIZE ),
        .ProtWidth ( EW_DW          )
      ) i_castout_data_enc (
        .in         ( post_castout_data[ii*ECC_CHUNK_SIZE+:ECC_CHUNK_SIZE] ),
        .out        ( { post_castout_ecc[ii*EW_DW+:EW_DW], z_fifo_d.data[ii*ECC_CHUNK_SIZE+:ECC_CHUNK_SIZE]} )
      );
    end
    assign z_fifo_d.ecc = { zstream2cast.ecc[EW-1:DW/ECC_CHUNK_SIZE*EW_DW], post_castout_ecc, zstream2cast.ecc[EW_RQMETA-1:0]};
  end else begin
    assign z_fifo_d.data = post_castout_data;
    assign z_fifo_d.ecc  = zstream2cast.ecc;
  end

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
// do not assign z_fifo_d.ecc = zstream2cast.ecc;
assign zstream2cast.r_ecc    = z_fifo_d.r_ecc;

// HCI store fifo.
hci_core_fifo #(
  .FIFO_DEPTH                      ( 2                          ),
  .`HCI_SIZE_PARAM(tcdm_initiator) ( `HCI_SIZE_PARAM(ldst_tcdm) )
) i_store_fifo (
  .clk_i          ( clk_i    ),
  .rst_ni         ( rst_ni   ),
  .clear_i        ( clear_i  ),
  .flags_o        (          ),
  .tcdm_target    ( z_fifo_d ),
  .tcdm_initiator ( z_fifo_q )
);

// Assigning the store FIFO output to the store side of the LD/ST multiplexer.
hci_core_assign i_store_assign ( .tcdm_target (z_fifo_q), .tcdm_initiator (virt_tcdm[1]) );

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
hci_core_intf #(
`ifndef SYNTHESIS
    .WAIVE_RSP3_ASSERT ( 1'b1 ), // waive RSP-3 on memory-side of HCI FIFO
    .WAIVE_RSP5_ASSERT ( 1'b1 ),  // waive RSP-5 on memory-side of HCI FIFO
`endif
  .DW ( DW ),
  .UW ( UW ),
  .EW ( EW )
) source [0:NumStreamSources-1] ( .clk ( clk_i ) );
hci_core_intf #( .DW ( DW ),
                 .UW ( UW ),
                 .EW ( EW ) ) mux_tcdm [0:0] ( .clk ( clk_i ) );

// Dynamic multiplexer splitting the TCDM-side interface into
// X, W, and Y interfaces
hci_core_mux_dynamic #(
  .NB_IN_CHAN          ( NumStreamSources           ),
  .`HCI_SIZE_PARAM(in) ( `HCI_SIZE_PARAM(ldst_tcdm) )
) i_source_mux        (
  .clk_i              ( clk_i            ),
  .rst_ni             ( rst_ni           ),
  .clear_i            ( clear_i          ),
  .in                 ( source           ),
  .out                ( virt_tcdm[0:0]   )
);

// One TCDM FIFO and one HCI core source unit per stream channel.
hci_core_intf #(
`ifndef SYNTHESIS
  .WAIVE_RSP3_ASSERT ( 1'b1 ), // waive RSP-3 on memory-side of HCI FIFO
  .WAIVE_RSP5_ASSERT ( 1'b1 ),  // waive RSP-5 on memory-side of HCI FIFO
`endif
  .DW ( DW ),
  .UW ( UW ),
  .EW ( EW )
) load_fifo_d [0:NumStreamSources-1] ( .clk ( clk_i ) );

hci_core_intf #( .DW ( DW ),
                 .UW ( UW ),
                 .EW ( EW ) ) load_fifo_q [0:NumStreamSources-1] ( .clk ( clk_i ) );

hci_core_intf #( .DW ( DW ),
                 .UW ( UW ),
                 .EW ( EW ) ) tcdm_cast [0:NumStreamSources-1] ( .clk ( clk_i ) );

hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW ) ) out_stream [NumStreamSources-1:0] ( .clk( clk_i ) );

hci_package::hci_streamer_ctrl_t  [NumStreamSources-1:0] source_ctrl;
hci_package::hci_streamer_flags_t [NumStreamSources-1:0] source_flags;

// Assign input control buses to the relative ID in the vector.
assign source_ctrl[XsourceStreamId] = ctrl_i.x_stream_source_ctrl;
assign source_ctrl[WsourceStreamId] = ctrl_i.w_stream_source_ctrl;
assign source_ctrl[YsourceStreamId] = ctrl_i.y_stream_source_ctrl;

for (genvar i = 0; i < NumStreamSources; i++) begin: gen_tcdm2stream

  hci_core_assign i_load_assign ( .tcdm_target (load_fifo_d[i]), .tcdm_initiator (source[i]) );

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

  if (EW > 1) begin: gen_pre_castin_decoder
    logic [DW/ECC_CHUNK_SIZE-1:0][1:0]  pre_castin_err;
    for(genvar ii=0; ii<DW/ECC_CHUNK_SIZE; ii++) begin : r_data_decoding
      hsiao_ecc_dec #(
        .DataWidth ( ECC_CHUNK_SIZE ),
        .ProtWidth ( EW_DW          )
      ) i_castin_r_data_dec (
        .in         ( { load_fifo_q[i].r_ecc[EW_RSMETA+(ii*EW_DW)+:EW_DW], load_fifo_q[i].r_data[ii*ECC_CHUNK_SIZE+:ECC_CHUNK_SIZE] } ),
        .out        ( pre_castin_r_data[i][ii*ECC_CHUNK_SIZE+:ECC_CHUNK_SIZE] ),
        .syndrome_o (  ),
        .err_o      ( pre_castin_err[ii] )
      );
    end
  end else begin
    assign pre_castin_r_data[i] = load_fifo_q[i].r_data;
  end

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
    .src_i        ( pre_castin_r_data[i]      ),
    .src_fmt_i    ( ctrl_i.input_cast_src_fmt ),
    .dst_o        ( post_castin_r_data[i]     )
  );

  if (EW > 1) begin: gen_post_castin_encoder
    logic [DW/ECC_CHUNK_SIZE*EW_DW-1:0] post_castin_r_ecc;
    for(genvar ii=0; ii<DW/ECC_CHUNK_SIZE; ii++) begin : r_data_encoding
      hsiao_ecc_enc #(
        .DataWidth ( ECC_CHUNK_SIZE ),
        .ProtWidth ( EW_DW          )
      ) i_castin_r_data_enc (
        .in         ( post_castin_r_data[i][ii*ECC_CHUNK_SIZE+:ECC_CHUNK_SIZE] ),
        .out        ( { post_castin_r_ecc[ii*EW_DW+:EW_DW], tcdm_cast[i].r_data[ii*ECC_CHUNK_SIZE+:ECC_CHUNK_SIZE]} )
      );
    end
    assign tcdm_cast[i].r_ecc= { load_fifo_q[i].r_ecc[EW-1:DW/ECC_CHUNK_SIZE*EW_DW], post_castin_r_ecc, load_fifo_q[i].r_ecc[EW_RSMETA-1:0]};
  end else begin
    assign tcdm_cast[i].r_data = post_castin_r_data[i];
    assign tcdm_cast[i].r_ecc  = load_fifo_q[i].r_ecc;
  end

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
  // do not assign tcdm_cast[i].r_ecc = load_fifo_q[i].r_ecc;

  if (EW > 1) begin: gen_ecc_source
    hci_ecc_source          #(
      .MISALIGNED_ACCESSES   ( REALIGN                    ),
      .`HCI_SIZE_PARAM(tcdm) ( `HCI_SIZE_PARAM(ldst_tcdm) )
    ) i_stream_ecc_source    (
      .clk_i                 ( clk_i                      ),
      .rst_ni                ( rst_ni                     ),
      .test_mode_i           ( test_mode_i                ),
      .clear_i               ( clear_i                    ),
      .enable_i              ( enable_i                   ),
      .tcdm                  ( tcdm_cast[i]               ),
      .stream                ( out_stream[i]              ),
      .ctrl_i                ( source_ctrl[i]             ),
      .flags_o               ( source_flags[i]            )
    );
  end else begin: gen_source
    hci_core_source           #(
        .MISALIGNED_ACCESSES   ( REALIGN                    ),
        .`HCI_SIZE_PARAM(tcdm) ( `HCI_SIZE_PARAM(ldst_tcdm) )
      ) i_stream_source        (
        .clk_i                 ( clk_i                      ),
        .rst_ni                ( rst_ni                     ),
        .test_mode_i           ( test_mode_i                ),
        .clear_i               ( clear_i                    ),
        .enable_i              ( enable_i                   ),
        .tcdm                  ( tcdm_cast[i]               ),
        .stream                ( out_stream[i]              ),
        .ctrl_i                ( source_ctrl[i]             ),
        .flags_o               ( source_flags[i]            )
      );
  end

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
