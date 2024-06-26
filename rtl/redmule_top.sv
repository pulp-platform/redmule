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
 * RedMulE Top-Level Module
 */

`include "hci_helpers.svh"

module redmule_top
  import fpnew_pkg::*;
  import redmule_pkg::*;
  import hci_package::*;
  import hwpe_ctrl_package::*;
  import hwpe_stream_package::*;
#(
parameter  int unsigned  ID_WIDTH    = 8                 ,
parameter  int unsigned  N_CORES     = 8                 ,
parameter  int unsigned  DW          = DATA_W            , // TCDM port dimension (in bits)
localparam int unsigned  NumContext  = N_CONTEXT         , // Number of sequential jobs for the slave device
localparam fp_format_e   FpFormat    = FPFORMAT          , // Data format (default is FP16)
localparam int unsigned  Height      = ARRAY_HEIGHT      , // Number of PEs within a row
localparam int unsigned  Width       = ARRAY_WIDTH       , // Number of parallel rows
localparam int unsigned  NumPipeRegs = PIPE_REGS         , // Number of pipeline registers within each PE
localparam pipe_config_t PipeConfig  = DISTRIBUTED       ,
localparam int unsigned  BITW        = fp_width(FpFormat),  // Number of bits for the given format
parameter hci_size_parameter_t `HCI_SIZE_PARAM(tcdm) = '0
)(
  input  logic                    clk_i      ,
  input  logic                    rst_ni     ,
  input  logic                    test_mode_i,
  output logic                    busy_o     ,
  output logic [N_CORES-1:0][1:0] evt_o      ,
 
  // TCDM master ports for the memory sID_WIDTHe
  hci_core_intf.initiator         tcdm       ,
  // Periph slave port for the controller sID_WIDTHe
  hwpe_ctrl_intf_periph.slave     periph
);

localparam int unsigned DATAW_ALIGN = DATAW;

logic                       fsm_z_clk_en, ctrl_z_clk_en;
logic                       enable, clear, soft_clear;
logic                       y_buffer_depth_count,
                            y_buffer_load,
                            z_buffer_fill,
                            z_buffer_store;
logic                       w_shift;
logic                       w_load;
logic                       reg_enable,
                            gate_en;
logic [$clog2(TOT_DEPTH):0] w_cols_lftovr,
                            y_cols_lftovr;
logic [$clog2(Height):0]    w_rows_lftovr;
logic [$clog2(Width):0]     y_rows_lftovr;

// Streamer control signals, flags and ecc info
cntrl_streamer_t cntrl_streamer;
flgs_streamer_t  flgs_streamer;
errs_streamer_t ecc_errors_streamer;

cntrl_engine_t   cntrl_engine;

// Wrapper control signals and flags
// Input feature map
x_buffer_ctrl_t x_buffer_ctrl;
x_buffer_flgs_t x_buffer_flgs;

// Weights
w_buffer_ctrl_t w_buffer_ctrl;
w_buffer_flgs_t w_buffer_flgs;

// Output feature map
z_buffer_ctrl_t z_buffer_ctrl;
z_buffer_flgs_t z_buffer_flgs;

// FSM control signals and flags
cntrl_scheduler_t cntrl_scheduler;
flgs_scheduler_t  flgs_scheduler;

// Register file binded from controller to FSM
ctrl_regfile_t reg_file;
flags_fifo_t   w_fifo_flgs;

/*--------------------------------------------------------------*/
/* |                         Streamer                         | */
/*--------------------------------------------------------------*/

// Implementation of the incoming and outgoing streaming interfaces (one for each kind of data)

// X streaming interface + X FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) x_buffer_d    ( .clk( clk_i ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) x_buffer_fifo ( .clk( clk_i ) );

// W streaming interface + W FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) w_buffer_d    ( .clk( clk_i ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) w_buffer_fifo ( .clk( clk_i ) );

// Y streaming interface + Y FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) y_buffer_d    ( .clk( clk_i ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) y_buffer_fifo ( .clk( clk_i ) );

// Z streaming interface + Z FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) z_buffer_q    ( .clk( clk_i ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) z_buffer_fifo ( .clk( clk_i ) );

hwpe_ctrl_intf_periph   #( .ID_WIDTH   ( ID_WIDTH    ) ) periph_local ( .clk( clk_i ) );

// Periph port binding from local
always_comb begin
  periph_local.req  = periph.req;
  periph_local.add  = periph.add;
  periph_local.wen  = periph.wen;
  periph_local.be   = periph.be;
  periph_local.data = periph.data;
  periph_local.id   = periph.id;
  periph.gnt        = periph_local.gnt;
  periph.r_data     = periph_local.r_data;
  periph.r_valid    = periph_local.r_valid;
  periph.r_id       = periph_local.r_id;
end

// The streamer will present a single master TCDM port used to stream data to and from the memeory.
redmule_streamer #(
  .DW                    ( DW                    ),
  .`HCI_SIZE_PARAM(tcdm) ( `HCI_SIZE_PARAM(tcdm) )
) i_streamer      (
  .clk_i          ( clk_i               ),
  .rst_ni         ( rst_ni              ),
  .test_mode_i    ( test_mode_i         ),
  // Controller generated signals
  .enable_i       ( 1'b1                ),
  .clear_i        ( clear               ),
  // Source interfaces for the incoming streams
  .x_stream_o     ( x_buffer_d          ),
  .w_stream_o     ( w_buffer_d          ),
  .y_stream_o     ( y_buffer_d          ),
  // Sink interface for the outgoing stream
  .z_stream_i     ( z_buffer_fifo       ),
  // Master TCDM interface ports for the memory side
  .tcdm           ( tcdm                ),
  .ecc_errors_o   ( ecc_errors_streamer ),
  .ctrl_i         ( cntrl_streamer      ),
  .flags_o        ( flgs_streamer       )
);

hwpe_stream_fifo #(
  .DATA_WIDTH     ( DATAW_ALIGN   ),
  .FIFO_DEPTH     ( 4             )
) i_x_buffer_fifo (               
  .clk_i          ( clk_i         ),
  .rst_ni         ( rst_ni        ),
  .clear_i        ( clear         ),
  .flags_o        (               ),             
  .push_i         ( x_buffer_d    ),
  .pop_o          ( x_buffer_fifo )
);

hwpe_stream_fifo #(
  .DATA_WIDTH     ( DATAW_ALIGN   ),
  .FIFO_DEPTH     ( 4             )
) i_w_buffer_fifo (
  .clk_i          ( clk_i         ),
  .rst_ni         ( rst_ni        ),
  .clear_i        ( clear         ),
  .flags_o        ( w_fifo_flgs   ),             
  .push_i         ( w_buffer_d    ),
  .pop_o          ( w_buffer_fifo )
);

hwpe_stream_fifo #(
  .DATA_WIDTH     ( DATAW_ALIGN   ),
  .FIFO_DEPTH     ( 4             )
) i_y_buffer_fifo (
  .clk_i          ( clk_i         ),
  .rst_ni         ( rst_ni        ),
  .clear_i        ( clear         ),
  .flags_o        (               ),             
  .push_i         ( y_buffer_d    ),
  .pop_o          ( y_buffer_fifo )
);

hwpe_stream_fifo #(
  .DATA_WIDTH     ( DATAW_ALIGN   ),
  .FIFO_DEPTH     ( 2             )
) i_z_buffer_fifo (               
  .clk_i          ( clk_i         ),
  .rst_ni         ( rst_ni        ),
  .clear_i        ( clear         ),
  .flags_o        (               ),             
  .push_i         ( z_buffer_q    ),
  .pop_o          ( z_buffer_fifo )
);

// Valid/Ready assignment
assign x_buffer_fifo.ready = flgs_scheduler.x_ready;
assign w_buffer_fifo.ready = flgs_scheduler.w_ready;
assign y_buffer_fifo.ready = flgs_scheduler.y_ready;

assign z_buffer_q.valid            = flgs_scheduler.z_valid;
assign z_buffer_q.strb             = flgs_scheduler.z_strb;
assign z_buffer_ctrl.ready         = z_buffer_q.ready;
assign z_buffer_ctrl.y_valid       = y_buffer_fifo.valid;
assign z_buffer_ctrl.y_push_enable = flgs_scheduler.y_push_enable;

/*----------------------------------------------------------------*/
/* |                          Buffers                           | */
/*----------------------------------------------------------------*/

logic x_buffer_clk_en, x_buffer_clock;
tc_clk_gating i_x_buffer_clock_gating (
  .clk_i     ( clk_i           ),
  .en_i      ( x_buffer_clk_en ),
  .test_en_i ( '0              ),
  .clk_o     ( x_buffer_clock  )
);

logic [Width-1:0][Height-1:0][BITW-1:0] x_buffer_q;
redmule_x_buffer #(
  .DW         ( DATAW_ALIGN         ),
  .FpFormat   ( FpFormat            ),
  .Height     ( Height              ),
  .Width      ( Width               )
) i_x_buffer  (
  .clk_i      ( x_buffer_clock      ),
  .rst_ni     ( rst_ni              ),
  .clear_i    ( clear || soft_clear ),
  .ctrl_i     ( x_buffer_ctrl       ),
  .flags_o    ( x_buffer_flgs       ),
  .x_buffer_o ( x_buffer_q          ),
  .x_buffer_i ( x_buffer_fifo.data  )
);

logic [Height-1:0][BITW-1:0] w_buffer_q;
redmule_w_buffer #(
  .DW         ( DATAW_ALIGN         ),
  .FpFormat   ( FpFormat            ),
  .Height     ( Height              )
) i_w_buffer  (
  .clk_i      ( clk_i               ),
  .rst_ni     ( rst_ni              ),
  .clear_i    ( clear || soft_clear ),
  .ctrl_i     ( w_buffer_ctrl       ),
  .flags_o    ( w_buffer_flgs       ),
  .w_buffer_o ( w_buffer_q          ),
  .w_buffer_i ( w_buffer_fifo.data  )
);

logic [Width-1:0][BITW-1:0] z_buffer_d, y_bias_q;
redmule_z_buffer #(
  .DW            ( DATAW_ALIGN         ),
  .FpFormat      ( FpFormat            ),
  .Width         ( Width               )
) i_z_buffer     (
  .clk_i         ( clk_i               ),
  .rst_ni        ( rst_ni              ),
  .clear_i       ( clear || soft_clear ),
  .reg_enable_i  ( reg_enable          ),
  .ctrl_i        ( z_buffer_ctrl       ),
  .flags_o       ( z_buffer_flgs       ),
  .y_buffer_i    ( y_buffer_fifo.data  ),
  .z_buffer_i    ( z_buffer_d          ),
  .y_buffer_o    ( y_bias_q            ),
  .z_buffer_o    ( z_buffer_q.data     )
);

// Ready and valid assignments for wrapper registers
// Wrapper cntrl assigments
assign w_buffer_ctrl.load              = w_load;
assign w_buffer_ctrl.shift             = w_shift & flgs_scheduler.w_shift;
assign w_buffer_ctrl.cols_lftovr       = w_cols_lftovr;
assign w_buffer_ctrl.rows_lftovr       = w_rows_lftovr;
assign z_buffer_ctrl.fill              = z_buffer_fill;
assign z_buffer_ctrl.load              = y_buffer_load;
assign z_buffer_ctrl.store             = z_buffer_store;
assign z_buffer_ctrl.buffer_clk_en     = (fsm_z_clk_en | ctrl_z_clk_en);
assign z_buffer_ctrl.cols_lftovr       = y_cols_lftovr;
assign z_buffer_ctrl.rows_lftovr       = y_rows_lftovr;

/*---------------------------------------------------------------*/
/* |                          Engine                           | */
/*---------------------------------------------------------------*/
cntrl_engine_t ctrl_engine;
flgs_engine_t  flgs_engine;

// Engine signals
// Control signal for successive accumulations
logic                               accumulate, engine_flush;
// fpnew_fma Input Signals
logic                         [2:0] fma_is_boxed;
logic                         [1:0] noncomp_is_boxed;
roundmode_e                         stage1_rnd,
                                    stage2_rnd; 
operation_e                         op1, op2;
logic                               op_mod;
logic                               in_tag;
logic                               in_aux;
// fpnew_fma Input Handshake
logic                               in_valid;
logic       [Width-1:0][Height-1:0] in_ready;

logic                               flush;
// fpnew_fma Output signals
status_t    [Width-1:0][Height-1:0] status;
logic       [Width-1:0][Height-1:0] extension_bit;
classmask_e [Width-1:0][Height-1:0] class_mask;
logic       [Width-1:0][Height-1:0] is_class;
logic       [Width-1:0][Height-1:0] out_tag;
logic       [Width-1:0][Height-1:0] out_aux;
// fpnew_fma Output handshake   
logic       [Width-1:0][Height-1:0] out_valid;
logic                               out_ready;
// fpnew_fma Indication of valid data in flight
logic       [Width-1:0][Height-1:0] busy;

// Binding from engine interface types to cntrl_engine_t and
assign fma_is_boxed     = cntrl_engine.fma_is_boxed;
assign noncomp_is_boxed = cntrl_engine.noncomp_is_boxed;
assign stage1_rnd       = cntrl_engine.stage1_rnd;
assign stage2_rnd       = cntrl_engine.stage2_rnd;
assign op1              = cntrl_engine.op1;
assign op2              = cntrl_engine.op2;
assign op_mod           = cntrl_engine.op_mod;
assign in_tag           = 1'b0;
assign in_aux           = 1'b0;
assign in_valid         = cntrl_engine.in_valid;
assign flush            = cntrl_engine.flush | clear;
assign out_ready        = cntrl_engine.out_ready;
always_comb begin
  for (int w = 0; w < Width; w++) begin
    for (int h = 0; h < Height; h++) begin
      flgs_engine.in_ready      [w][h] = in_ready      [w][h];
      flgs_engine.status        [w][h] = status        [w][h];
      flgs_engine.extension_bit [w][h] = extension_bit [w][h];
      flgs_engine.out_valid     [w][h] = out_valid     [w][h];
      flgs_engine.busy          [w][h] = busy          [w][h];
    end
  end
end

// Engine instance
redmule_engine     #(
  .FpFormat        ( FpFormat      ),
  .Height          ( Height        ),
  .Width           ( Width         ),
  .NumPipeRegs     ( NumPipeRegs   ),
  .PipeConfig      ( PipeConfig    )
) i_redmule_engine (
  .clk_i              ( clk_i            ),
  .rst_ni             ( rst_ni           ),
  .x_input_i          ( x_buffer_q       ),
  .w_input_i          ( w_buffer_q       ),
  .y_bias_i           ( y_bias_q         ),
  .z_output_o         ( z_buffer_d       ),
  .accumulate_i       ( accumulate       ),
  .fma_is_boxed_i     ( fma_is_boxed     ),
  .noncomp_is_boxed_i ( noncomp_is_boxed ),
  .stage1_rnd_i       ( stage1_rnd       ),
  .stage2_rnd_i       ( stage2_rnd       ),
  .op1_i              ( op1              ),
  .op2_i              ( op2              ),
  .op_mod_i           ( op_mod           ),
  .tag_i              ( in_tag           ),
  .aux_i              ( in_aux           ),
  .in_valid_i         ( in_valid         ),
  .in_ready_o         ( in_ready         ),
  .reg_enable_i       ( reg_enable       ),
  .flush_i            ( flush            ),
  .status_o           ( status           ),
  .extension_bit_o    ( extension_bit    ),
  .class_mask_o       ( class_mask       ),
  .is_class_o         ( is_class         ),
  .tag_o              ( out_tag          ),
  .aux_o              ( out_aux          ),
  .out_valid_o        ( out_valid        ),
  .out_ready_i        ( out_ready        ),
  .busy_o             ( busy             ),
  .ctrl_engine_i      ( cntrl_engine     )
);

/*---------------------------------------------------------------*/
/* |                        Controller                         | */
/*---------------------------------------------------------------*/

redmule_ctrl        #(
  .N_CORES           ( N_CORES                 ),
  .IO_REGS           ( REDMULE_REGS            ),
  .ID_WIDTH          ( ID_WIDTH                ),
  .N_CONTEXT         ( NumContext              ),
  .Height            ( Height                  ),
  .Width             ( Width                   ),
  .NumPipeRegs       ( NumPipeRegs             )
) i_control          (                         
  .clk_i             ( clk_i                   ),
  .rst_ni            ( rst_ni                  ),
  .test_mode_i       ( test_mode_i             ),
  .busy_o            ( busy_o                  ),
  .clear_o           ( clear                   ),
  .evt_o             ( evt_o                   ),
  .z_fill_o          ( z_buffer_fill           ),
  .w_shift_o         ( w_shift                 ),
  .z_buffer_clk_en_o ( ctrl_z_clk_en           ),
  .reg_file_o        ( reg_file                ),
  .reg_enable_i      ( reg_enable              ),
  .flgs_z_buffer_i   ( z_buffer_flgs           ),
  .flgs_engine_i     ( flgs_engine             ),
  .w_loaded_i        ( flgs_scheduler.w_loaded ),
  .flush_o           ( engine_flush            ),
  .accumulate_o      ( accumulate              ),
  .cntrl_scheduler_o ( cntrl_scheduler         ),
  .errs_streamer_i   ( ecc_errors_streamer     ),
  .periph            ( periph_local            )
);
    

/*---------------------------------------------------------------*/
/* |                        Local FSM                          | */
/*---------------------------------------------------------------*/

redmule_scheduler    #(
  .Height             ( Height              ),
  .Width              ( Width               ),
  .NumPipeRegs        ( NumPipeRegs         )
) i_scheduler         (                     
  .clk_i              ( clk_i               ),
  .rst_ni             ( rst_ni              ),
  .test_mode_i        ( test_mode_i         ),
  .clear_i            ( clear               ),
  .x_valid_i          ( x_buffer_fifo.valid ),
  .x_strb_i           ( x_buffer_fifo.strb  ),
  .w_valid_i          ( w_buffer_fifo.valid ),
  .w_strb_i           ( w_buffer_fifo.strb  ),
  .y_fifo_valid_i     ( y_buffer_fifo.valid ),
  .y_fifo_strb_i      ( y_buffer_fifo.strb  ),
  .z_ready_i          ( z_buffer_q.ready    ),
  .accumulate_i       ( accumulate          ),
  .engine_flush_i     ( engine_flush        ),
  .z_strb_o           (                     ),
  .soft_clear_o       ( soft_clear          ),
  .w_load_o           ( w_load              ),
  .w_cols_lftovr_o    ( w_cols_lftovr       ),
  .w_rows_lftovr_o    ( w_rows_lftovr       ),
  .y_cols_lftovr_o    ( y_cols_lftovr       ),
  .y_rows_lftovr_o    ( y_rows_lftovr       ),
  .gate_en_o          ( gate_en             ),
  .x_buffer_clk_en_o  ( x_buffer_clk_en     ),
  .z_buffer_clk_en_o  ( fsm_z_clk_en        ),
  .reg_enable_o       ( reg_enable          ),
  .z_store_o          ( z_buffer_store      ),
  .y_buffer_load_o    ( y_buffer_load       ),
  .reg_file_i         ( reg_file            ),
  .flgs_streamer_i    ( flgs_streamer       ),
  .flgs_x_buffer_i    ( x_buffer_flgs       ),
  .flgs_w_buffer_i    ( w_buffer_flgs       ),
  .flgs_z_buffer_i    ( z_buffer_flgs       ),
  .flgs_engine_i      ( flgs_engine         ),
  .fifo_flgs_i        ( w_fifo_flgs         ),
  .cntrl_scheduler_i  ( cntrl_scheduler     ),
  .cntrl_engine_o     ( cntrl_engine        ),
  .cntrl_streamer_o   ( cntrl_streamer      ),
  .cntrl_x_buffer_o   ( x_buffer_ctrl       ),
  .flgs_scheduler_o   ( flgs_scheduler      )
);

endmodule : redmule_top
