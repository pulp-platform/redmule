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
`include "common_cells/registers.svh"

module redmule_streamer
  import fpnew_pkg::*;
  import redmule_pkg::*;
  import hci_package::*;
  import hwpe_stream_package::*;
#(
parameter  int unsigned DW        = 288   ,
parameter  int unsigned AW        = ADDR_W,
localparam int unsigned REALIGN   = 1     ,
parameter  bit SERIAL_REPLICATION = 0     , // Serial error detection on the Output
parameter  bit REDUCED_DATAPATH   = 0     , // Only do W datapath and all control signals
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

  // ECC error signals
  output errs_streamer_t         ecc_errors_o,
  // Control signals
  input  cntrl_streamer_t        ctrl_i,
  output flgs_streamer_t         flags_o,
  output logic                   serial_fault_o
);

localparam int unsigned UW  = `HCI_SIZE_GET_UW(tcdm);
localparam int unsigned EW  = `HCI_SIZE_GET_EW(tcdm);

/*************************** Store Channel: Serial Detection ****************************/
/* In redundant modes, every element is fetched and stored twice, after the whole       *
 * it arrives here and we check that the two elements still are the same.               *
 * this overlapps with the full replication of the data in fully redundant modes, which *
 * then overlapps with ECC encode / decode                                              */

if (SERIAL_REPLICATION) begin: gen_serial_fault_detection
  logic [DW-1:0] data_out_d, data_out_q;
  logic same_d, same_q;
  logic data_transmitted;

  assign data_transmitted = tcdm.req && tcdm.gnt && !tcdm.wen;
  assign data_out_d[DW-1:0] = tcdm.data;

  `FFL(data_out_q, data_out_d, data_transmitted, '0);

  assign same_d = data_out_d == data_out_q;

  `FFL(same_q, same_d, data_transmitted, '1);

  assign serial_fault_o = ~same_d && ~same_q && data_transmitted;
end else begin: gen_no_serial_fault_detection
  assign serial_fault_o = 1'b0; 
  // Since we want to be able to have a configuration where only serial detection is done
  // We default to 0 here (Otherwise disabled redundancy -> assert fault for safety).
end

// TODO: Add Load / Store deduplication here

/************************************** ECC Stage **************************************/
/* If the interface from the cores has data ECC, we decode it here. All further error  *
 * protection is in time or with parity bits  
                                           */
// this localparam is reused for all internal, non-ecc HCI interfaces
localparam hci_size_parameter_t `HCI_SIZE_PARAM(ldst_tcdm) = '{
  DW:  DW,
  AW:  DEFAULT_AW,
  BW:  DEFAULT_BW,
  UW:  UW,
  IW:  DEFAULT_IW,
  EW:  DEFAULT_EW,
  EHW: DEFAULT_EHW
};

// this localparam is reused for the  internal ecc HCI interface
localparam hci_size_parameter_t `HCI_SIZE_PARAM(ecc_ldst_tcdm) = '{
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
  .UW ( UW )
) ldst_tcdm [0:0] ( .clk ( clk_i ) );

if (EW > 1 && !REDUCED_DATAPATH) begin : gen_ecc_encoder
  logic [ECC_N_CHUNK-1:0] data_single_err, data_multi_err;
  logic                   meta_single_err, meta_multi_err;

  hci_ecc_enc #(
    .DW ( DW ),
    .`HCI_SIZE_PARAM(tcdm_target)    ( `HCI_SIZE_PARAM(ldst_tcdm)     ),
    .`HCI_SIZE_PARAM(tcdm_initiator) ( `HCI_SIZE_PARAM(ecc_ldst_tcdm) )
  ) i_ecc_enc (
    .r_data_single_err_o ( data_single_err ),
    .r_data_multi_err_o  ( data_multi_err  ),
    .r_meta_single_err_o ( meta_single_err ),
    .r_meta_multi_err_o  ( meta_multi_err  ),
    .tcdm_target         ( ldst_tcdm[0]                 ),
    .tcdm_initiator      ( tcdm                         )
  );

  assign ecc_errors_o.data_single_err = data_single_err & {ECC_N_CHUNK{tcdm.r_valid}};
  assign ecc_errors_o.data_multi_err  = data_multi_err  & {ECC_N_CHUNK{tcdm.r_valid}};
  assign ecc_errors_o.meta_single_err = meta_single_err & (tcdm.req & tcdm.gnt);
  assign ecc_errors_o.meta_multi_err  = meta_multi_err  & (tcdm.req & tcdm.gnt);
end else begin : gen_ldst_assign
  hci_core_assign i_ldst_assign ( .tcdm_target (ldst_tcdm [0]), .tcdm_initiator (tcdm) );
  assign ecc_errors_o = '0;
end

/********************************* Load / Store MUX *************************************/
/* Virtual internal TCDM interface splitting the upstream TCDM into two channels:       *
 * Channel 0 - load channel (from TCDM to stream).                                      *
 * Channel 1 - store channel (from stream to TCDM).                                     */

hci_core_intf #(
`ifndef SYNTHESIS
  .WAIVE_RSP3_ASSERT ( 1'b1 ), // waive RSP-3 on memory-side of HCI FIFO
  .WAIVE_RSP5_ASSERT ( 1'b1 ),  // waive RSP-5 on memory-side of HCI FIFO
`endif
  .DW ( DW ),
  .UW ( UW )
) virt_tcdm [0:1] ( .clk ( clk_i ) );

hci_core_mux_dynamic #(
  .NB_IN_CHAN          ( 2                          ),
  .`HCI_SIZE_PARAM(in) ( `HCI_SIZE_PARAM(ldst_tcdm) )
) i_ldst_mux (
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

// Convert Control Signals
logic cast;
assign cast = (ctrl_i.input_cast_src_fmt == fpnew_pkg::FP16) ? 1'b0: 1'b1;

hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW ) ) z_stream ( .clk( clk_i ) );

// Upcast Z stream
assign z_stream_i.ready = z_stream.ready;
assign z_stream.valid   = z_stream_i.valid;
assign z_stream.strb    = z_stream_i.strb;
if (REDUCED_DATAPATH) begin
  assign z_stream.data = DONT_CARE; // No data input
end else begin
  assign z_stream.data = z_stream_i.data;  
end

redmule_streamout #(
  .MISALIGNED_ACCESSES     ( REALIGN                    ),
  .`HCI_SIZE_PARAM(source) ( `HCI_SIZE_PARAM(ldst_tcdm) ),
  .BYPASS_CAST             ( REDUCED_DATAPATH           )
) i_z_stream_out (
  .clk_i,
  .rst_ni,
  .clear_i      ( clear_i                     ),
  .test_mode_i  ( test_mode_i                 ),
  .enable_i     ( enable_i                    ),
  .ctrl_i       ( ctrl_i.z_stream_sink_ctrl   ),
  .cast_i       ( cast                        ),
  .dst_fmt_i    ( ctrl_i.output_cast_dst_fmt  ),
  .stream_i     ( z_stream                    ),
  .source       ( virt_tcdm[1]                ),
  .flags_o      ( flags_o.z_stream_sink_flags )
);

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
  .UW ( UW )
) source [0:NumStreamSources-1] ( .clk ( clk_i ) );

// Dynamic multiplexer splitting the TCDM-side interface into
// X, W, and Y interfaces
hci_core_mux_dynamic #(
  .NB_IN_CHAN          ( NumStreamSources           ),
  .`HCI_SIZE_PARAM(in) ( `HCI_SIZE_PARAM(ldst_tcdm) )
) i_source_mux        (
  .clk_i              ( clk_i          ),
  .rst_ni             ( rst_ni         ),
  .clear_i            ( clear_i        ),
  .in                 ( source         ),
  .out                ( virt_tcdm[0:0] )
);

hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW ) ) x_stream ( .clk( clk_i ) );

redmule_streamin #(
  .MISALIGNED_ACCESSES     ( REALIGN                    ),
  .`HCI_SIZE_PARAM(source) ( `HCI_SIZE_PARAM(ldst_tcdm) ),
  .BYPASS_CAST             ( REDUCED_DATAPATH           )
) i_x_stream_in (
  .clk_i,
  .rst_ni,
  .test_mode_i  ( test_mode_i                   ),
  .clear_i      ( clear_i                       ),
  .enable_i     ( enable_i                      ),
  .cast_i       ( cast                          ),
  .stream_o     ( x_stream                      ),
  .source       ( source[0]                     ),
  .src_fmt_i    ( ctrl_i.input_cast_src_fmt     ),
  .ctrl_i       ( ctrl_i.x_stream_source_ctrl   ),
  .flags_o      ( flags_o.x_stream_source_flags )
);

// Downcast X stream
assign x_stream.ready   = x_stream_o.ready;
assign x_stream_o.valid = x_stream.valid;
assign x_stream_o.strb  = x_stream.strb;
if (REDUCED_DATAPATH) begin
  assign x_stream_o.data = DONT_CARE; // No data output
end else begin
  assign x_stream_o.data = x_stream.data;  
end

hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW ) ) w_stream ( .clk( clk_i ) );

redmule_streamin #(
  .MISALIGNED_ACCESSES     ( REALIGN                    ),
  .`HCI_SIZE_PARAM(source) ( `HCI_SIZE_PARAM(ldst_tcdm) ),
  .BYPASS_CAST             ( 0                          )
) i_w_stream_in (
  .clk_i,
  .rst_ni,
  .test_mode_i  ( test_mode_i                   ),
  .clear_i      ( clear_i                       ),
  .enable_i     ( enable_i                      ),
  .cast_i       ( cast                          ),
  .stream_o     ( w_stream                      ),
  .source       ( source[1]                     ),
  .src_fmt_i    ( ctrl_i.input_cast_src_fmt     ),
  .ctrl_i       ( ctrl_i.w_stream_source_ctrl   ),
  .flags_o      ( flags_o.w_stream_source_flags )
);

// Downcast W stream
assign w_stream.ready = w_stream_o.ready;
assign w_stream_o.valid = w_stream.valid;
assign w_stream_o.strb = w_stream.strb;
if (REDUCED_DATAPATH) begin
    for (genvar i = 0; i < DATAW / 8 ; i++) begin
      assign w_stream_o.data[i]  = ^w_stream.data[i * 8 +: 8]; // Bytewise parity
    end
end else begin
  assign w_stream_o.data = w_stream.data;  
end

hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW ) ) y_stream ( .clk( clk_i ) );

redmule_streamin #(
  .MISALIGNED_ACCESSES     ( REALIGN                    ),
  .`HCI_SIZE_PARAM(source) ( `HCI_SIZE_PARAM(ldst_tcdm) ),
  .BYPASS_CAST             ( REDUCED_DATAPATH           )
) i_y_stream_in (
  .clk_i,
  .rst_ni,
  .test_mode_i  ( test_mode_i                   ),
  .clear_i      ( clear_i                       ),
  .enable_i     ( enable_i                      ),
  .cast_i       ( cast                          ),
  .stream_o     ( y_stream                      ),
  .source       ( source[2]                     ),
  .src_fmt_i    ( ctrl_i.input_cast_src_fmt     ),
  .ctrl_i       ( ctrl_i.y_stream_source_ctrl   ),
  .flags_o      ( flags_o.y_stream_source_flags )
);

// Downcast Y stream
assign y_stream.ready   = y_stream_o.ready;
assign y_stream_o.valid = y_stream.valid;
assign y_stream_o.strb  = y_stream.strb;
if (REDUCED_DATAPATH) begin
  assign y_stream_o.data = DONT_CARE; // No output
end else begin
  assign y_stream_o.data = y_stream.data;  
end

endmodule : redmule_streamer
