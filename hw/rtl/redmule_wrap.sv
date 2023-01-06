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
 *
 * Authors: Yvan Tortorella <yvan.tortorella@unibo.it>
 * 
 * RedMulE Wrapper
 */

import fpnew_pkg::*;
import hci_package::*;
import redmule_pkg::*;
import hwpe_ctrl_package::*;
import hwpe_stream_package::*;

module redmule_wrap #(
parameter  int unsigned  ID_WIDTH    = 8                 ,
parameter  int unsigned  N_CORES     = 8                 ,
parameter  int unsigned  DW          = DATA_W            , // TCDM port dimension (in bits)
parameter  int unsigned  MP          = DW/ADDR_W         ,
localparam fp_format_e   FpFormat    = FPFORMAT          , // Data format (default is FP16)
localparam int unsigned  Height      = ARRAY_HEIGHT      , // Number of PEs within a row
localparam int unsigned  Width       = ARRAY_WIDTH       , // Number of parallel rows
localparam int unsigned  NumPipeRegs = PIPE_REGS         , // Number of pipeline registers within each PE 
localparam pipe_config_t PipeConfig  = DISTRIBUTED       ,
localparam int unsigned  BITW        = fp_width(FpFormat)  // Number of bits for the given format
) (
  // global signals
  input  logic                      clk_i         ,
  input  logic                      rst_ni        ,
  input  logic                      test_mode_i   ,
  // evnets
  output logic [N_CORES-1:0][1:0]   evt_o         ,
  output logic                      busy_o        ,
  // tcdm master ports
  output logic [      MP-1:0]       tcdm_req      ,
  input  logic [      MP-1:0]       tcdm_gnt      ,
  output logic [      MP-1:0][31:0] tcdm_add      ,
  output logic [      MP-1:0]       tcdm_wen      ,
  output logic [      MP-1:0][ 3:0] tcdm_be       ,
  output logic [      MP-1:0][31:0] tcdm_data     ,
  input  logic [      MP-1:0][31:0] tcdm_r_data   ,
  input  logic [      MP-1:0]       tcdm_r_valid  ,
  input  logic                      tcdm_r_opc    ,
  input  logic                      tcdm_r_user   ,
  // periph slave port
  input  logic                      periph_req    ,
  output logic                      periph_gnt    ,
  input  logic [        31:0]       periph_add    ,
  input  logic                      periph_wen    ,
  input  logic [         3:0]       periph_be     ,
  input  logic [        31:0]       periph_data   ,
  input  logic [ID_WIDTH-1:0]       periph_id     ,
  output logic [        31:0]       periph_r_data ,
  output logic                      periph_r_valid,
  output logic [ID_WIDTH-1:0]       periph_r_id
);

hci_core_intf #(.DW(DW)) tcdm (.clk(clk_i));
hwpe_ctrl_intf_periph #(.ID_WIDTH(ID_WIDTH)) periph (.clk(clk_i));

// bindings
generate
  for(genvar ii=0; ii<MP; ii++) begin: tcdm_binding
    assign tcdm_req  [ii] = tcdm.req;
    assign tcdm_add  [ii] = tcdm.add + ii*4;
    assign tcdm_wen  [ii] = tcdm.wen;
    assign tcdm_be   [ii] = tcdm.be[(ii+1)*4-1:ii*4];
    assign tcdm_data [ii] = tcdm.data[(ii+1)*32-1:ii*32];
  end
  assign tcdm.gnt     = &(tcdm_gnt);
  assign tcdm.r_valid = &(tcdm_r_valid);
  assign tcdm.r_data  = { >> {tcdm_r_data} };
  assign tcdm.r_opc   = tcdm_r_opc;
  assign tcdm.r_user  = tcdm_r_user; 
endgenerate

always_comb begin
  periph.req     = periph_req;
  periph.add     = periph_add;
  periph.wen     = periph_wen;
  periph.be      = periph_be;
  periph.data    = periph_data;
  periph.id      = periph_id;
  periph_gnt     = periph.gnt;
  periph_r_data  = periph.r_data;
  periph_r_valid = periph.r_valid;
  periph_r_id    = periph.r_id;
end

redmule_top #(
  .ID_WIDTH     ( ID_WIDTH     ),
  .N_CORES      ( N_CORES      ),
  .DW           ( DW           )
) i_redmule_top (
  .clk_i        ( clk_i        ),
  .rst_ni       ( rst_ni       ),
  .test_mode_i  ( test_mode_i  ),
  .evt_o        ( evt_o        ),
  .busy_o       ( busy_o       ),
  .tcdm         ( tcdm         ),
  .periph       ( periph       )
);

endmodule: redmule_wrap
