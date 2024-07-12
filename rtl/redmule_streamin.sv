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
 * RedMulE Streamer Input Chain
 */

`include "hci_helpers.svh"

module redmule_streamin
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
  input  fp_format_e                src_fmt_i,

  hci_core_intf.initiator           source,
  hwpe_stream_intf_stream.source    stream_o
);

  hci_core_intf #(
    .DW ( `HCI_SIZE_PARAM(source).DW ),
    .UW ( `HCI_SIZE_PARAM(source).UW )
    `ifndef SYNTHESIS
      ,
      .WAIVE_RSP3_ASSERT ( 1'b1 ),
      .WAIVE_RSP5_ASSERT ( 1'b1 )
    `endif
  ) load_fifo_d (
    .clk ( clk_i )
  );

  hci_core_intf #(
    .DW ( `HCI_SIZE_PARAM(source).DW ),
    .UW ( `HCI_SIZE_PARAM(source).UW )
  ) fifo2cast (
    .clk ( clk_i )
  );

    hci_core_intf #(
    .DW ( `HCI_SIZE_PARAM(source).DW ),
    .UW ( `HCI_SIZE_PARAM(source).UW )
  ) cast2source (
    .clk ( clk_i )
  );

  hci_core_fifo #(
    .FIFO_DEPTH  ( 4  ),
    .`HCI_SIZE_PARAM(tcdm_initiator) ( `HCI_SIZE_PARAM(source) )
  ) i_load_tcdm_fifo (
    .clk_i          ( clk_i     ),
    .rst_ni         ( rst_ni    ),
    .clear_i        ( clear_i   ),
    .flags_o        (           ),
    .tcdm_target    ( fifo2cast ),
    .tcdm_initiator ( source    )
  );

  if (BYPASS_CAST) begin
    assign cast2source.r_data = DONT_CARE;
  end else begin
    redmule_castin #(
      .FpFmtConfig  ( FpFmtConfig  ),
      .IntFmtConfig ( IntFmtConfig ),
      .dst_format   ( FPFORMAT     )
    ) i_load_cast (
      .clk_i,
      .rst_ni,
      .clear_i      ( clear_i            ),
      .cast_i       ( cast_i             ),
      .src_i        ( fifo2cast.r_data   ),
      .src_fmt_i    ( src_fmt_i          ),
      .dst_o        ( cast2source.r_data )
    );
  end

  assign fifo2cast.req        = cast2source.req;
  assign cast2source.gnt      = fifo2cast.gnt;
  assign fifo2cast.add        = cast2source.add;
  assign fifo2cast.wen        = cast2source.wen;
  assign fifo2cast.data       = cast2source.data;
  assign fifo2cast.be         = cast2source.be;
  assign fifo2cast.r_ready    = cast2source.r_ready;
  assign fifo2cast.user       = cast2source.user;
  assign fifo2cast.id         = cast2source.id;
  assign cast2source.r_valid  = fifo2cast.r_valid;
  assign cast2source.r_opc    = fifo2cast.r_opc;
  assign cast2source.r_user   = fifo2cast.r_user;
  assign cast2source.r_id     = fifo2cast.r_id;

  // Set ECC Signals constant so they can be optimised away
  assign fifo2cast.ereq       = DONT_CARE;
  assign cast2source.egnt     = DONT_CARE;
  assign cast2source.r_evalid = DONT_CARE;
  assign fifo2cast.r_eready   = DONT_CARE;
  assign fifo2cast.ecc        = DONT_CARE;
  assign cast2source.r_ecc    = DONT_CARE;

  hci_core_source #(
    .MISALIGNED_ACCESSES   ( MISALIGNED_ACCESSES     ),
    .`HCI_SIZE_PARAM(tcdm) ( `HCI_SIZE_PARAM(source) )
  ) i_stream_source (
    .clk_i               ( clk_i       ),
    .rst_ni              ( rst_ni      ),
    .test_mode_i         ( test_mode_i ),
    .clear_i             ( clear_i     ),
    .enable_i            ( enable_i    ),
    .tcdm                ( cast2source ),
    .stream              ( stream_o    ),
    .ctrl_i              ( ctrl_i      ),
    .flags_o             ( flags_o     )
  );

endmodule
