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

module redmule_streamer
  import fpnew_pkg::*;
  import redmule_pkg::*;
  import hci_package::*;
  import hwpe_stream_package::*;
#(
parameter  int unsigned DW      = 288,
parameter  int unsigned UW      = 1,
parameter  int unsigned AW      = ADDR_W,
localparam int unsigned REALIGN = 1
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
  hci_core_intf.master           tcdm,
  
  // Control signals
  input  cntrl_streamer_t        ctrl_i,
  output flgs_streamer_t         flags_o
);

// Here the dynamic mux for virtual_tcdm interfaces
// coming/going from/to the accelerator to/from the memory
hci_core_intf #( .DW ( DW ), 
                 .UW ( UW ) ) load_st_tcdm [0:0] ( .clk ( clk_i ) );

hci_core_assign i_ld_st_assign ( .tcdm_slave (load_st_tcdm [0]), .tcdm_master (tcdm) );

hci_core_intf #( .DW ( DW ),
                 .UW ( UW ) ) virt_tcdm    [1:0] ( .clk ( clk_i ) );

hci_core_mux_dynamic #(
  .NB_IN_CHAN         ( 2            ),
  .UW                 ( UW           ),
  .DW                 ( DW           )
) i_ld_store_mux      (
  .clk_i              ( clk_i        ),
  .rst_ni             ( rst_ni       ),
  .clear_i            ( clear_i      ),
  .in                 ( virt_tcdm    ),
  .out                ( load_st_tcdm )
);

hci_core_intf #( .DW ( DW ),
                 .UW ( UW ) ) z_to_cast [0:0] ( .clk ( clk_i ) );
hci_core_intf #( .DW ( DW ),
                 .UW ( UW ) ) z_to_tcdm [0:0] ( .clk ( clk_i ) );
// Sink module that turns the incoming Z matrix stream into virtual TCDM interface
hci_core_sink         #(
  .DATA_WIDTH          ( DW                          ),
  .MISALIGNED_ACCESSES ( REALIGN                     )
) i_z_stream_sink      (                             
  .clk_i               ( clk_i                       ),
  .rst_ni              ( rst_ni                      ),
  .test_mode_i         ( test_mode_i                 ),
  .clear_i             ( clear_i                     ),
  .enable_i            ( enable_i                    ),
  .tcdm                ( z_to_cast [0]               ),
  .stream              ( z_stream_i                  ),
  .ctrl_i              ( ctrl_i.z_stream_sink_ctrl   ),
  .flags_o             ( flags_o.z_stream_sink_flags )
);

logic cast;
assign cast = (ctrl_i.input_cast_src_fmt == fpnew_pkg::FP16) ? 1'b0: 1'b1;

redmule_castout #(
  .FpFmtConfig   ( FpFmtConfig  ),
  .IntFmtConfig  ( IntFmtConfig ),
  .src_format    ( FPFORMAT     )
) i_output_cast  (
  .clk_i                                     ,
  .rst_ni                                    ,
  .clear_i                                   ,
  .cast_i       ( cast                      ),
  .src_i        (z_to_cast[0].data          ),
  .dst_fmt_i    (ctrl_i.output_cast_dst_fmt ),
  .dst_o        (virt_tcdm[1].data          )
);

assign virt_tcdm[1].req     = z_to_cast[0].req;
assign z_to_cast[0].gnt     = virt_tcdm[1].gnt;
assign virt_tcdm[1].add     = z_to_cast[0].add;
assign virt_tcdm[1].wen     = z_to_cast[0].wen;
assign virt_tcdm[1].be      = z_to_cast[0].be;
assign virt_tcdm[1].boffs   = z_to_cast[0].boffs;
assign virt_tcdm[1].lrdy    = z_to_cast[0].lrdy;
assign virt_tcdm[1].user    = z_to_cast[0].user;
assign z_to_cast[0].r_data  = virt_tcdm[1].r_data;
assign z_to_cast[0].r_valid = virt_tcdm[1].r_valid;
assign z_to_cast[0].r_opc   = virt_tcdm[1].r_opc;
assign z_to_cast[0].r_user  = virt_tcdm[1].r_user;

// hci_core_assign i_z_assign ( .tcdm_slave (virt_tcdm [1]), .tcdm_master (z_to_tcdm [0]) );

// Virtual TCDM interfaces (source type) for input matrices
// X matrix -> source[0]
// W matrix -> source[1]
// Y matrix -> source[2]
// source[3] is fake because the hci_core_mux_dynamic does not work with three sources
hci_core_intf #( .DW ( DW ),
                 .UW ( UW ) ) source       [3:0] ( .clk ( clk_i ) );
hci_core_intf #( .DW ( DW ),
                 .UW ( UW ) ) mux_tcdm     [0:0] ( .clk ( clk_i ) );
hci_core_intf #( .DW ( DW ),
                 .UW ( UW ) ) tcdm_cast    [0:0] ( .clk ( clk_i ) );

redmule_castin #(
  .FpFmtConfig  ( FpFmtConfig  ),
  .IntFmtConfig ( IntFmtConfig ),
  .dst_format   ( FPFORMAT     )
) i_input_cast  (
  .clk_i                                    ,
  .rst_ni                                   ,
  .clear_i                                  ,
  .cast_i       ( cast                     ),
  .src_i        (virt_tcdm[0].r_data       ),
  .src_fmt_i    (ctrl_i.input_cast_src_fmt ),
  .dst_o        (mux_tcdm[0].r_data        )
);

assign virt_tcdm[0].req    = mux_tcdm[0].req;
assign mux_tcdm[0].gnt     = virt_tcdm[0].gnt;
assign virt_tcdm[0].add    = mux_tcdm[0].add;
assign virt_tcdm[0].wen    = mux_tcdm[0].wen;
assign virt_tcdm[0].data   = mux_tcdm[0].data;
assign virt_tcdm[0].be     = mux_tcdm[0].be;
assign virt_tcdm[0].boffs  = mux_tcdm[0].boffs;
assign virt_tcdm[0].lrdy   = mux_tcdm[0].lrdy;
assign virt_tcdm[0].user   = mux_tcdm[0].user;
assign mux_tcdm[0].r_valid = virt_tcdm[0].r_valid;
assign mux_tcdm[0].r_opc   = virt_tcdm[0].r_opc;
assign mux_tcdm[0].r_user  = virt_tcdm[0].r_user;

// hci_core_assign i_input_assign ( .tcdm_slave (mux_tcdm [0]), .tcdm_master (tcdm_cast [0]) );

// Here we instantiate the dynamic mux that turns the tcdm stream into
// source [0], source[1] or source[2] depending on the scheduling
hci_core_mux_dynamic #(
  .NB_IN_CHAN         ( 4              ),
  .UW                 ( UW             ),
  .DW                 ( DW             )
) i_source_mux        (
  .clk_i              ( clk_i          ),
  .rst_ni             ( rst_ni         ),
  .clear_i            ( clear_i        ),
  .in                 ( source         ),
  .out                ( mux_tcdm [0:0] )
);

// Here we implement the source module to convert virt_tcdm [0] interface to
// all source streams.
// Source module for X input matrix
hci_core_source       #(
  .DATA_WIDTH          ( DW                            ),
  .MISALIGNED_ACCESSES ( REALIGN                       )
) i_x_stream_source    (                               
  .clk_i               ( clk_i                         ),
  .rst_ni              ( rst_ni                        ),
  .test_mode_i         ( test_mode_i                   ),
  .clear_i             ( clear_i                       ),
  .enable_i            ( enable_i                      ),
  .tcdm                ( source [0]                    ),
  .stream              ( x_stream_o                    ),
  .ctrl_i              ( ctrl_i.x_stream_source_ctrl   ),
  .flags_o             ( flags_o.x_stream_source_flags )
);

// Source module for W input matrix
hci_core_source       #(
  .DATA_WIDTH          ( DW                            ),
  .MISALIGNED_ACCESSES ( REALIGN                       )
) i_w_stream_source    (
  .clk_i               ( clk_i                         ),
  .rst_ni              ( rst_ni                        ),
  .test_mode_i         ( test_mode_i                   ),
  .clear_i             ( clear_i                       ),
  .enable_i            ( enable_i                      ),
  .tcdm                ( source [1]                    ),
  .stream              ( w_stream_o                    ),
  .ctrl_i              ( ctrl_i.w_stream_source_ctrl   ),
  .flags_o             ( flags_o.w_stream_source_flags )
);

// Source module for Y input matrix
hci_core_source       #(
  .DATA_WIDTH          ( DW                            ),
  .MISALIGNED_ACCESSES ( REALIGN                       )
) i_y_stream_source    (
  .clk_i               ( clk_i                         ),
  .rst_ni              ( rst_ni                        ),
  .test_mode_i         ( test_mode_i                   ),
  .clear_i             ( clear_i                       ),
  .enable_i            ( enable_i                      ),
  .tcdm                ( source[2]                     ),
  .stream              ( y_stream_o                    ),
  .ctrl_i              ( ctrl_i.y_stream_source_ctrl   ),
  .flags_o             ( flags_o.y_stream_source_flags )
);

// Binding source[3] to '0 to solve hci_core_mux_dynamic issues
assign source[3].req   =  0;
assign source[3].add   = '0;
assign source[3].wen   =  0;
assign source[3].data  =  0;
assign source[3].be    =  0;
assign source[3].boffs =  0;
assign source[3].lrdy  =  0;
assign source[3].user  = '0;

endmodule : redmule_streamer
