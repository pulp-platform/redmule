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
 * Authors: Yvan Tortorella <yvan.tortorella@unibo.it>
 * 
 * RedMulE Wrapper
 */

`include "hci_helpers.svh"

module redmule_wrap
  import fpnew_pkg::*;
  import hci_package::*;
  import redmule_pkg::*;
  import hwpe_ctrl_package::*;
  import hwpe_stream_package::*;
#(
parameter  int unsigned  ID_WIDTH          = 8                    ,
parameter  int unsigned  N_CORES           = 8                    ,
parameter  int unsigned  DW                = DATA_W               , // TCDM port dimension (in bits)
parameter  int unsigned  MP                = DW/redmule_pkg::MemDw,
parameter  int unsigned  EW                = 0                    , // ECC signals width
parameter           bit  USE_REDUNDANCY    = 1                    , // Number of Replicas of Internal State Machine
localparam fp_format_e   FpFormat          = FPFORMAT             , // Data format (default is FP16)
localparam int unsigned  Height            = ARRAY_HEIGHT         , // Number of PEs within a row
localparam int unsigned  Width             = ARRAY_WIDTH          , // Number of parallel rows
localparam int unsigned  NumPipeRegs       = PIPE_REGS            , // Number of pipeline registers within each PE 
localparam pipe_config_t PipeConfig        = DISTRIBUTED          ,
localparam int unsigned  BITW              = fp_width(FpFormat)  // Number of bits for the given format
) (
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
  output logic [      EW-1:0]       tcdm_ecc_o      ,
  input  logic [      MP-1:0][31:0] tcdm_r_data_i   ,
  input  logic [      MP-1:0]       tcdm_r_valid_i  ,
  input  logic                      tcdm_r_opc_i    ,
  input  logic                      tcdm_r_user_i   ,
  input  logic [      EW-1:0]       tcdm_r_ecc_i    ,
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

localparam hci_size_parameter_t `HCI_SIZE_PARAM(tcdm) = '{
  DW:  DW,
  AW:  DEFAULT_AW,
  BW:  DEFAULT_BW,
  UW:  DEFAULT_UW,
  IW:  DEFAULT_IW,
  EW:  EW,
  EHW: DEFAULT_EHW
};
hci_core_intf #(
`ifndef SYNTHESIS
  .WAIVE_RSP3_ASSERT ( 1'b1 ), // waive RSP-3 on memory-side of HCI FIFO
  .WAIVE_RSP5_ASSERT ( 1'b1 ),  // waive RSP-5 on memory-side of HCI FIFO
`endif
  .DW ( DW ),
  .EW ( EW ) ) tcdm ( .clk ( clk_i ) );
hwpe_ctrl_intf_periph #(.ID_WIDTH(ID_WIDTH)) periph (.clk(clk_i));

// bindings
generate
  for(genvar ii=0; ii<MP; ii++) begin: tcdm_binding
    assign tcdm_req_o  [ii] = tcdm.req;
    assign tcdm_add_o  [ii] = tcdm.add + ii*4;
    assign tcdm_wen_o  [ii] = tcdm.wen;
    assign tcdm_be_o   [ii] = tcdm.be[(ii+1)*4-1:ii*4];
    assign tcdm_data_o [ii] = tcdm.data[(ii+1)*32-1:ii*32];
  end
  assign tcdm_ecc_o   = tcdm.ecc;
  assign tcdm.gnt     = &(tcdm_gnt_i);
  assign tcdm.r_valid = &(tcdm_r_valid_i);
  assign tcdm.r_data  = { >> {tcdm_r_data_i} };
  assign tcdm.r_opc   = tcdm_r_opc_i;
  assign tcdm.r_user  = tcdm_r_user_i;
  assign tcdm.r_ecc   = tcdm_r_ecc_i;
  assign tcdm.r_id    = '0;
  assign tcdm.egnt    = '1;
  assign tcdm.r_evalid = '0;
endgenerate

always_comb begin
  periph.req       = periph_req_i;
  periph.add       = periph_add_i;
  periph.wen       = periph_wen_i;
  periph.be        = periph_be_i;
  periph.data      = periph_data_i;
  periph.id        = periph_id_i;
  periph_gnt_o     = periph.gnt;
  periph_r_data_o  = periph.r_data;
  periph_r_valid_o = periph.r_valid;
  periph_r_id_o    = periph.r_id;
end

redmule_top #(
  .ID_WIDTH              ( ID_WIDTH              ),
  .N_CORES               ( N_CORES               ),
  .DW                    ( DW                    ),
  .`HCI_SIZE_PARAM(tcdm) ( `HCI_SIZE_PARAM(tcdm) ),
  .USE_REDUNDANCY        ( USE_REDUNDANCY        )
) i_redmule_top (
  .clk_i            ( clk_i        ),
  .rst_ni           ( rst_ni       ),
  .test_mode_i      ( test_mode_i  ),
  .evt_o            ( evt_o        ),
  .busy_o           ( busy_o       ),
  .tcdm             ( tcdm         ),
  .periph           ( periph       )
);

endmodule: redmule_wrap
