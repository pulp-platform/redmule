// Copyright 2026 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Francesco Conti <f.conti@unibo.it>

// Wrapper for redmule_top that exposes the XIF control interface and hides the
// HWPE-ctrl memory-mapped target port. The target port's master-driven inputs
// (req, add, wen, be, data, id) are tied to '0; gnt is driven to '1 internally
// by redmule_top when CtrlIntfConfig == XIF.

`include "hci_helpers.svh"

module redmule_xif_wrap
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
  // Custom instructions
  parameter logic [6:0]   McnfigOpCode            = 7'b0001011,
  parameter logic [6:0]   MarithOpCode            = 7'b0001011,
  parameter logic [6:0]   MopcntOpCode            = 7'b0001011,
  parameter logic [2:0]   McnfigFunct3            = 3'b000,
  parameter logic [2:0]   MarithFunct3            = 3'b001,
  parameter logic [2:0]   MopcntFunct3            = 3'b010,
  parameter logic [1:0]   McnfigFunct2            = 2'b00,
  parameter logic [1:0]   MarithFunct2            = 2'b00,
  parameter logic [1:0]   MopcntFunct2            = 2'b00,
  // XIF parameters
  parameter int unsigned  XifNumHarts             = 1,
  parameter int unsigned  XifIdWidth              = 1,
  parameter int unsigned  XifIssueRegisterSplit   = 0,
  // XIF types
  parameter type          x_issue_req_t  = logic,
  parameter type          x_issue_resp_t = logic,
  parameter type          x_register_t   = logic,
  parameter type          x_commit_t     = logic,
  parameter type          x_result_t     = logic,
  parameter hci_size_parameter_t `HCI_SIZE_PARAM(tcdm) = '0
)(
  input  logic                    clk_i      ,
  input  logic                    rst_ni     ,
  input  logic                    test_mode_i,
  output logic                    busy_o     ,
  output logic                    evt_o      ,
  // External W stream
  hwpe_stream_intf_stream.sink    w_stream_i ,
  // External X stream
  hwpe_stream_intf_stream.sink    x_stream_i ,
  // Broadcasted W stream
  hwpe_stream_intf_stream.source  w_stream_o ,
  // Broadcasted X stream
  hwpe_stream_intf_stream.source  x_stream_o ,
  // XIF ports
  input  x_issue_req_t  x_issue_req_i      ,
  output x_issue_resp_t x_issue_resp_o     ,
  input  logic          x_issue_valid_i    ,
  output logic          x_issue_ready_o    ,
  input  x_register_t   x_register_i       ,
  input  logic          x_register_valid_i ,
  output logic          x_register_ready_o ,
  input  x_commit_t     x_commit_i         ,
  input  logic          x_commit_valid_i   ,
  output x_result_t     x_result_o         ,
  output logic          x_result_valid_o   ,
  input  logic          x_result_ready_i   ,
  // Synchronization ports
  output logic          sync_o             ,
  input  logic          sync_i             ,
  // TCDM master ports for the memory side
  hci_core_intf.initiator tcdm
  // NOTE: hwpe_ctrl_intf_periph target is hidden; master inputs are tied to '0
  //       and gnt is driven to '1 internally (CtrlIntfConfig == XIF).
);

  // Local dummy HWPE-ctrl target interface — master-side inputs tied to '0.
  hwpe_ctrl_intf_periph #(.ID_WIDTH(0)) target (.clk(clk_i));
  assign target.req  = '0;
  assign target.add  = '0;
  assign target.wen  = '0;
  assign target.be   = '0;
  assign target.data = '0;
  assign target.id   = '0;

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
    .CtrlIntfConfig          ( XIF                     ),
    .McnfigOpCode            ( McnfigOpCode            ),
    .MarithOpCode            ( MarithOpCode            ),
    .MopcntOpCode            ( MopcntOpCode            ),
    .McnfigFunct3            ( McnfigFunct3            ),
    .MarithFunct3            ( MarithFunct3            ),
    .MopcntFunct3            ( MopcntFunct3            ),
    .McnfigFunct2            ( McnfigFunct2            ),
    .MarithFunct2            ( MarithFunct2            ),
    .MopcntFunct2            ( MopcntFunct2            ),
    .XifNumHarts             ( XifNumHarts             ),
    .XifIdWidth              ( XifIdWidth              ),
    .XifIssueRegisterSplit   ( XifIssueRegisterSplit   ),
    .x_issue_req_t           ( x_issue_req_t           ),
    .x_issue_resp_t          ( x_issue_resp_t          ),
    .x_register_t            ( x_register_t            ),
    .x_commit_t              ( x_commit_t              ),
    .x_result_t              ( x_result_t              ),
    .`HCI_SIZE_PARAM(tcdm)   ( `HCI_SIZE_PARAM(tcdm)   )
  ) i_redmule_top (
    .clk_i               ( clk_i               ),
    .rst_ni              ( rst_ni              ),
    .test_mode_i         ( test_mode_i         ),
    .busy_o              ( busy_o              ),
    .evt_o               ( evt_o               ),
    .w_stream_i          ( w_stream_i          ),
    .x_stream_i          ( x_stream_i          ),
    .w_stream_o          ( w_stream_o          ),
    .x_stream_o          ( x_stream_o          ),
    .x_issue_req_i       ( x_issue_req_i       ),
    .x_issue_resp_o      ( x_issue_resp_o      ),
    .x_issue_valid_i     ( x_issue_valid_i     ),
    .x_issue_ready_o     ( x_issue_ready_o     ),
    .x_register_i        ( x_register_i        ),
    .x_register_valid_i  ( x_register_valid_i  ),
    .x_register_ready_o  ( x_register_ready_o  ),
    .x_commit_i          ( x_commit_i          ),
    .x_commit_valid_i    ( x_commit_valid_i    ),
    .x_result_o          ( x_result_o          ),
    .x_result_valid_o    ( x_result_valid_o    ),
    .x_result_ready_i    ( x_result_ready_i    ),
    .sync_o              ( sync_o              ),
    .sync_i              ( sync_i              ),
    .tcdm                ( tcdm                ),
    .target              ( target              )
  );

endmodule : redmule_xif_wrap
