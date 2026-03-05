// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Francesco Conti <f.conti@unibo.it>

// Wrapper for redmule_top that exposes only the HWPE-ctrl memory-mapped target
// interface. XIF ports are hidden (inputs tied to '0) and external streaming
// ports (w_stream_i/o, x_stream_i/o) are hidden (source-side valid/data/strb
// tied to '0, sink-side ready tied to '0).

`include "hci_helpers.svh"

module redmule_mm_wrap
  import fpnew_pkg::*;
  import redmule_pkg::*;
  import hci_package::*;
  import hwpe_ctrl_package::*;
  import hwpe_stream_package::*;
#(
  parameter int unsigned  DataW                   = MaxDataW,
  parameter int unsigned  MisalignedAccessSupport = MisalignedAccessSupportDefault,
  parameter fp_format_e   FpFormat                = FP16,
  parameter int unsigned  Height                  = MaxDim,
  parameter int unsigned  Width                   = MaxDim,
  parameter int unsigned  NumPipeRegs             = MaxPipeRegs-1,
  parameter pipe_config_t PipeConfig              = DISTRIBUTED,
  parameter int unsigned  EccChunkSize            = 32,
  parameter bit           LatchBuffers            = 0,
  parameter fpnew_pkg::fmt_logic_t  FpFmtConfig   = 6'b001101,
  parameter fpnew_pkg::ifmt_logic_t IntFmtConfig  = 4'b1000,
  parameter hci_size_parameter_t `HCI_SIZE_PARAM(tcdm) = '0
  // NOTE: XIF parameters are not exposed; CtrlIntfConfig is fixed to HWPE_TARGET.
  //       External stream ports are also hidden.
)(
  input  logic                    clk_i      ,
  input  logic                    rst_ni     ,
  input  logic                    test_mode_i,
  output logic                    busy_o     ,
  output logic                    evt_o      ,
  // Synchronization ports
  output logic                    sync_o     ,
  input  logic                    sync_i     ,
  // TCDM master ports for the memory side
  hci_core_intf.initiator         tcdm       ,
  // HWPE-ctrl target port
  hwpe_ctrl_intf_periph.slave     target
  // NOTE: XIF ports are hidden; all XIF inputs are tied to '0 internally.
  // NOTE: external stream ports (w_stream_i/o, x_stream_i/o) are hidden;
  //       source-side handshake signals are tied to '0 internally.
);

  // Local dummy stream interfaces for the hidden external stream ports.
  // w_stream_i / x_stream_i are sink ports in redmule_top (redmule consumes);
  // the external source drives valid, data, strb — tie to '0.
  hwpe_stream_intf_stream #(.DATA_WIDTH(DataW)) w_stream_i (.clk(clk_i));
  hwpe_stream_intf_stream #(.DATA_WIDTH(DataW)) x_stream_i (.clk(clk_i));
  assign w_stream_i.valid = '0;
  assign w_stream_i.data  = '0;
  assign w_stream_i.strb  = '0;
  assign x_stream_i.valid = '0;
  assign x_stream_i.data  = '0;
  assign x_stream_i.strb  = '0;

  // w_stream_o / x_stream_o are source ports in redmule_top (redmule produces);
  // the external sink drives ready — tie to '0.
  hwpe_stream_intf_stream #(.DATA_WIDTH(DataW)) w_stream_o (.clk(clk_i));
  hwpe_stream_intf_stream #(.DATA_WIDTH(DataW)) x_stream_o (.clk(clk_i));
  assign w_stream_o.ready = '0;
  assign x_stream_o.ready = '0;

  redmule_top #(
    .DataW                   ( DataW                   ),
    .MisalignedAccessSupport ( MisalignedAccessSupport ),
    .FpFormat                ( FpFormat                ),
    .Height                  ( Height                  ),
    .Width                   ( Width                   ),
    .NumPipeRegs             ( NumPipeRegs             ),
    .PipeConfig              ( PipeConfig              ),
    .EccChunkSize            ( EccChunkSize            ),
    .LatchBuffers            ( LatchBuffers            ),
    .FpFmtConfig             ( FpFmtConfig             ),
    .IntFmtConfig            ( IntFmtConfig            ),
    .CtrlIntfConfig          ( HWPE_TARGET             ),
    .`HCI_SIZE_PARAM(tcdm)   ( `HCI_SIZE_PARAM(tcdm)   )
    // XIF parameters left at their defaults (logic); unused in HWPE_TARGET mode.
  ) i_redmule_top (
    .clk_i               ( clk_i       ),
    .rst_ni              ( rst_ni      ),
    .test_mode_i         ( test_mode_i ),
    .busy_o              ( busy_o      ),
    .evt_o               ( evt_o       ),
    .w_stream_i          ( w_stream_i  ),
    .x_stream_i          ( x_stream_i  ),
    .w_stream_o          ( w_stream_o  ),
    .x_stream_o          ( x_stream_o  ),
    // XIF inputs tied to '0; outputs left unconnected (driven to '0 by redmule_top)
    .x_issue_req_i       ( '0          ),
    .x_issue_resp_o      (             ),
    .x_issue_valid_i     ( '0          ),
    .x_issue_ready_o     (             ),
    .x_register_i        ( '0          ),
    .x_register_valid_i  ( '0          ),
    .x_register_ready_o  (             ),
    .x_commit_i          ( '0          ),
    .x_commit_valid_i    ( '0          ),
    .x_result_o          (             ),
    .x_result_valid_o    (             ),
    .x_result_ready_i    ( '0          ),
    .sync_o              ( sync_o      ),
    .sync_i              ( sync_i      ),
    .tcdm                ( tcdm        ),
    .target              ( target      )
  );

endmodule : redmule_mm_wrap
