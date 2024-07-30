/*
 * Copyright (C) 2024-2024 ETH Zurich and University of Bologna
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
 * Authors:  Maurus Item     <itemm@student.ethz.ch>
 * 
 * RedMulE Streamer Output Chain
 */

`include "hci_helpers.svh"

module redmule_streamout
  import fpnew_pkg::*;
  import redmule_pkg::*;
  import hci_package::*;
  import hwpe_stream_package::*;
#(
  parameter         int unsigned     MISALIGNED_ACCESSES = 1,
  parameter hci_size_parameter_t `HCI_SIZE_PARAM(source) = '0,
  parameter                  bit             BYPASS_CAST = 0
) (
  input logic                       clk_i,
  input logic                       rst_ni,
  input logic                       clear_i,

  // HCI Control Signals
  input logic                       test_mode_i,
  input logic                       enable_i,
  input  hci_streamer_ctrl_t        ctrl_i,
  output hci_streamer_flags_t       flags_o,

  // Cast control Signals
  input logic                       cast_i,
  input  fp_format_e                dst_fmt_i,

  hwpe_stream_intf_stream.sink      stream_i,
  hci_core_intf.initiator           source
);

  hci_core_intf #(
    .DW ( `HCI_SIZE_PARAM(source).DW ),
    .UW ( `HCI_SIZE_PARAM(source).UW )
  ) zstream2cast (
    .clk ( clk_i )
  );

  hci_core_sink #(
    .MISALIGNED_ACCESSES   ( MISALIGNED_ACCESSES     ),
    .`HCI_SIZE_PARAM(tcdm) ( `HCI_SIZE_PARAM(source) ),
    .DIM_ENABLE_1H         ( 3'b111                  )
  ) i_stream_sink (                             
    .clk_i               ( clk_i        ),
    .rst_ni              ( rst_ni       ),
    .test_mode_i         ( test_mode_i  ),
    .clear_i             ( clear_i      ),
    .enable_i            ( enable_i     ),
    .tcdm                ( zstream2cast ),
    .stream              ( stream_i     ),
    .ctrl_i              ( ctrl_i       ),
    .flags_o             ( flags_o      )
  );

  hci_core_intf #(
    .DW ( `HCI_SIZE_PARAM(source).DW ),
    .UW ( `HCI_SIZE_PARAM(source).UW )
    `ifndef SYNTHESIS
      ,
      .WAIVE_RSP3_ASSERT ( 1'b1 ),
      .WAIVE_RSP5_ASSERT ( 1'b1 )
    `endif
  ) cast2fifo (
    .clk ( clk_i )
  );

  // Store cast unit
  // This unit uses only the data bus of the TCDM interface. The other buses
  // are assigned manually.

  if (BYPASS_CAST) begin
    assign cast2fifo.data = DONT_CARE;
  end else begin
    redmule_castout #(
      .FpFmtConfig   ( FpFmtConfig  ),
      .IntFmtConfig  ( IntFmtConfig ),
      .src_format    ( FPFORMAT     )
    ) i_store_cast (
      .clk_i,
      .rst_ni,
      .clear_i      ( clear_i           ),
      .cast_i       ( cast_i            ),
      .src_i        ( zstream2cast.data ),
      .dst_fmt_i    ( dst_fmt_i         ),
      .dst_o        ( cast2fifo.data    )
    );
  end

  // Left TCDM buses assignment.
  assign cast2fifo.req         = zstream2cast.req;
  assign zstream2cast.gnt      = cast2fifo.gnt;
  assign cast2fifo.add         = zstream2cast.add;
  assign cast2fifo.wen         = zstream2cast.wen;
  assign cast2fifo.be          = zstream2cast.be;
  assign cast2fifo.r_ready     = zstream2cast.r_ready;
  assign cast2fifo.user        = zstream2cast.user;
  assign cast2fifo.id          = zstream2cast.id;
  assign zstream2cast.r_data   = cast2fifo.r_data;
  assign zstream2cast.r_valid  = cast2fifo.r_valid;
  assign zstream2cast.r_user   = cast2fifo.r_user;
  assign zstream2cast.r_id     = cast2fifo.r_id;

  // Set ECC Signals constant so they can be optimised away
  assign cast2fifo.ereq        = DONT_CARE;
  assign zstream2cast.egnt     = DONT_CARE;
  assign zstream2cast.r_evalid = DONT_CARE;
  assign cast2fifo.r_eready    = DONT_CARE;
  assign cast2fifo.ecc         = DONT_CARE;
  assign zstream2cast.r_ecc    = DONT_CARE;

  // HCI store fifo.
  hci_core_fifo #(
    .FIFO_DEPTH                      ( 2                       ),
    .`HCI_SIZE_PARAM(tcdm_initiator) ( `HCI_SIZE_PARAM(source) )
  ) i_store_fifo (
    .clk_i          ( clk_i     ),
    .rst_ni         ( rst_ni    ),
    .clear_i        ( clear_i   ),
    .flags_o        (           ),
    .tcdm_target    ( cast2fifo ),
    .tcdm_initiator ( source    )
  );

endmodule
