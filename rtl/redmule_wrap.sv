// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
//

`include "hci/typedef.svh"
`include "hci/assign.svh"
`include "hwpe-ctrl/typedef.svh"

module redmule_wrap
  import fpnew_pkg::*;
  import hci_package::*;
  import redmule_pkg::*;
  import hwpe_ctrl_package::*;
  import hwpe_stream_package::*;
#(
  parameter  int unsigned  ID_WIDTH           = 8                    ,
  parameter  int unsigned  N_CORES            = 8                    ,
  parameter  int unsigned  DW                 = DATA_W               , // TCDM port dimension (in bits)
  parameter  int unsigned  MP                 = DW/redmule_pkg::MemDw,
  localparam fp_format_e   FpFormat           = FPFORMAT             , // Data format (default is FP16)
  localparam int unsigned  Height             = ARRAY_HEIGHT         , // Number of PEs within a row
  localparam int unsigned  Width              = ARRAY_WIDTH          , // Number of parallel rows
  localparam int unsigned  NumPipeRegs        = PIPE_REGS            , // Number of pipeline registers within each PE
  localparam pipe_config_t PipeConfig         = DISTRIBUTED          ,
  localparam int unsigned  BITW               = fp_width(FpFormat)  // Number of bits for the given format
)(
  // global signals
  input  logic                      clk_i         ,
  input  logic                      rst_ni        ,
  input  logic                      test_mode_i   ,
  // evnets
  output logic [N_CORES-1:0][1:0]   evt_o         ,
  output logic                      busy_o        ,
  // tcdm master ports
  output logic [      MP-1:0]       tcdm_req_o      ,
  input  logic [      MP-1:0]       tcdm_gnt_i      ,
  output logic [      MP-1:0][31:0] tcdm_add_o      ,
  output logic [      MP-1:0]       tcdm_wen_o      ,
  output logic [      MP-1:0][ 3:0] tcdm_be_o       ,
  output logic [      MP-1:0][31:0] tcdm_data_o     ,
  input  logic [      MP-1:0][31:0] tcdm_r_data_i   ,
  input  logic [      MP-1:0]       tcdm_r_valid_i  ,
  input  logic                      tcdm_r_opc_i    ,
  input  logic                      tcdm_r_user_i   ,
  // periph slave port
  input  logic                      periph_req_i    ,
  output logic                      periph_gnt_o    ,
  input  logic [        31:0]       periph_add_i    ,
  input  logic                      periph_wen_i    ,
  input  logic [         3:0]       periph_be_i     ,
  input  logic [        31:0]       periph_data_i   ,
  input  logic [ID_WIDTH-1:0]       periph_id_i     ,
  output logic [        31:0]       periph_r_data_o ,
  output logic                      periph_r_valid_o,
  output logic [ID_WIDTH-1:0]       periph_r_id_o
);

`HCI_TYPEDEF_REQ_T(redmule_data_req_t, logic [31:0], logic [DW-1:0], logic [DW/8-1:0], logic signed [DW/32-1:0][31:0], logic)
`HCI_TYPEDEF_RSP_T(redmule_data_rsp_t, logic [DW-1:0], logic)
`HWPE_CTRL_TYPEDEF_REQ_T(redmule_ctrl_req_t, logic [31:0], logic [31:0], logic [3:0], logic [ID-1:0])
`HWPE_CTRL_TYPEDEF_RSP_T(redmule_ctrl_rsp_t, logic [31:0], logic [ID-1:0])

redmule_data_req_t data_req;
redmule_data_rsp_t data_rsp;
redmule_ctrl_req_t ctrl_req;
redmule_ctrl_rsp_t ctrl_rsp;
logic busy;
logic [N_CORES-1:0][1:0] evt;

`ifdef REDMULE_HWPE_SYNTH
  always_ff @(posedge clk_i, negedge rst_ni) begin
    if (~rst_ni) begin
      // TCDM port
      for (int ii = 0; ii < MP; ii++) begin
        tcdm_req_o  [ii] <= '0;
        tcdm_add_o  [ii] <= '0;
        tcdm_wen_o  [ii] <= '0;
        tcdm_be_o   [ii] <= '0;
        tcdm_data_o [ii] <= '0;
      end
      data_rsp.gnt     <= '0;
      data_rsp.r_valid <= '0;
      data_rsp.r_data  <= '0;
      data_rsp.r_opc   <= '0;
      data_rsp.r_user  <= '0;
      // Control port
      ctrl_req.req     <= '0;
      ctrl_req.add     <= '0;
      ctrl_req.wen     <= '0;
      ctrl_req.be      <= '0;
      ctrl_req.data    <= '0;
      ctrl_req.id      <= '0;
      periph_gnt_o     <= '0;
      periph_r_data_o  <= '0;
      periph_r_valid_o <= '0;
      periph_r_id_o    <= '0;
      // Other
      busy_o           <= '0;
      evt_o            <= '0;
    end else begin
      // TCDM port
      for (int ii = 0; ii < MP; ii++) begin
        tcdm_req_o  [ii] <= data_req.req;
        tcdm_add_o  [ii] <= data_req.add + ii*4;
        tcdm_wen_o  [ii] <= data_req.wen;
        tcdm_be_o   [ii] <= data_req.be[ii*4+:4];
        tcdm_data_o [ii] <= data_req.data[ii*32+:32];
      end
      data_rsp.gnt     <= &(tcdm_gnt_i);
      data_rsp.r_valid <= &(tcdm_r_valid_i);
      data_rsp.r_data  <= { >> {tcdm_r_data_i} };
      data_rsp.r_opc   <= tcdm_r_opc_i;
      data_rsp.r_user  <= tcdm_r_user_i;
      // Control port
      ctrl_req.req     <= periph_req_i;
      ctrl_req.add     <= periph_add_i;
      ctrl_req.wen     <= periph_wen_i;
      ctrl_req.be      <= periph_be_i;
      ctrl_req.data    <= periph_data_i;
      ctrl_req.id      <= periph_id_i;
      periph_gnt_o     <= ctrl_rsp.gnt;
      periph_r_data_o  <= ctrl_rsp.r_data;
      periph_r_valid_o <= ctrl_rsp.r_valid;
      periph_r_id_o    <= ctrl_rsp.r_id;
      // Other
      busy_o           <= busy;
      evt_o            <= evt;
    end
  end
`else
  generate
    for(genvar ii=0; ii<MP; ii++) begin: gen_tcdm_binding
      assign tcdm_req_o  [ii] = data_req.req;
      assign tcdm_add_o  [ii] = data_req.add + ii*4;
      assign tcdm_wen_o  [ii] = data_req.wen;
      assign tcdm_be_o   [ii] = data_req.be[(ii+1)*4-1:ii*4];
      assign tcdm_data_o [ii] = data_req.data[(ii+1)*32-1:ii*32];
    end
    assign data_rsp.gnt     = &(tcdm_gnt_i);
    assign data_rsp.r_valid = &(tcdm_r_valid_i);
    assign data_rsp.r_data  = { >> {tcdm_r_data_i} };
    assign data_rsp.r_opc   = tcdm_r_opc_i;
    assign data_rsp.r_user  = tcdm_r_user_i;
  endgenerate

  assign ctrl_req.req     = periph_req_i;
  assign ctrl_req.add     = periph_add_i;
  assign ctrl_req.wen     = periph_wen_i;
  assign ctrl_req.be      = periph_be_i;
  assign ctrl_req.data    = periph_data_i;
  assign ctrl_req.id      = periph_id_i;
  assign periph_gnt_o     = ctrl_rsp.gnt;
  assign periph_r_data_o  = ctrl_rsp.r_data;
  assign periph_r_valid_o = ctrl_rsp.r_valid;
  assign periph_r_id_o    = ctrl_rsp.r_id;
`endif
redmule_top #(
  .ID_WIDTH           ( ID_WIDTH           ),
  .N_CORES            ( N_CORES            ),
  .DW                 ( DW                 ),
  .redmule_data_req_t ( redmule_data_req_t ),
  .redmule_data_rsp_t ( redmule_data_rsp_t ),
  .redmule_ctrl_req_t ( redmule_ctrl_req_t ),
  .redmule_ctrl_rsp_t ( redmule_ctrl_rsp_t )
) i_redmule_top       (
  .clk_i              ( clk_i              ),
  .rst_ni             ( rst_ni             ),
  .test_mode_i        ( test_mode_i        ),
  .evt_o              ( evt_o              ),
  .busy_o             ( busy_o             ),
  .data_req_o         ( data_req           ),
  .data_rsp_i         ( data_rsp           ),
  .ctrl_req_i         ( ctrl_req           ),
  .ctrl_rsp_o         ( ctrl_rsp           )
);

endmodule: redmule_wrap
