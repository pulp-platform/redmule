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
parameter  int unsigned  ID_WIDTH       = 8                     ,
parameter  int unsigned  N_CORES        = 8                     ,
parameter  int unsigned  DW             = DATA_W                , // TCDM port dimension (in bits)
parameter  bit           USE_REDUNDANCY = 1                     , // Number of Replicas of Internal State Machine
localparam int unsigned  NumContext     = N_CONTEXT             , // Number of sequential jobs for the slave device
localparam fp_format_e   FpFormat       = FPFORMAT              , // Data format (default is FP16)
localparam int unsigned  Height         = ARRAY_HEIGHT          , // Number of PEs within a row
localparam int unsigned  Width          = ARRAY_WIDTH           , // Number of parallel rows
localparam int unsigned  NumPipeRegs    = PIPE_REGS             , // Number of pipeline registers within each PE
localparam pipe_config_t PipeConfig     = DISTRIBUTED           ,
localparam int unsigned  BITW           = fp_width(FpFormat)    , // Number of bits for the given format
localparam int unsigned  REP            = USE_REDUNDANCY ? 2 : 1, // Replication of elements
localparam bit           W_PARITY       = (REP > 1)             , // W parity can only be enabled if REP > 1 (but disabling it would work)
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

if (REP != 1 && REP != 2) begin: guard_unsupported_rep
  $fatal(1, "Selected replicas (REP) in redmule top not supported! (This module specifically can't recover with REP = 3)\n");
end

localparam int unsigned DATAW_ALIGN = DATAW;
localparam int unsigned STRBW = DATAW / 8;

logic [REP-1:0] fsm_z_clk_en, ctrl_z_clk_en;
logic [REP-1:0] clear, soft_clear;
logic [REP-1:0] accumulate;
logic [REP-1:0] w_shift;
logic [REP-1:0] reg_enable;
logic [REP-1:0] gate_en;

// Streamer control signals, flags and ecc info
cntrl_streamer_t [REP-1:0] cntrl_streamer;
flgs_streamer_t  [REP-1:0] flgs_streamer;

cntrl_engine_t   [REP-1:0] cntrl_engine;
logic            [REP-1:0] engine_flush;
flgs_engine_t    flgs_engine; // As this signal is an output per CE it can not be replicated, use with caution!

// Wrapper control signals and flags
// Input feature map
x_buffer_ctrl_t [REP-1:0] x_buffer_ctrl;
x_buffer_flgs_t [REP-1:0] x_buffer_flgs;

// Weights
w_buffer_ctrl_t [REP-1:0] w_buffer_ctrl;
w_buffer_flgs_t [REP-1:0] w_buffer_flgs;

// Output feature map
z_buffer_ctrl_t [REP-1:0] z_buffer_ctrl;
z_buffer_flgs_t [REP-1:0] z_buffer_flgs;

// FSM control signals and flags
cntrl_scheduler_t [REP-1:0] cntrl_scheduler;
flgs_scheduler_t  [REP-1:0] flgs_scheduler;

// Register file binded from controller to FSM
ctrl_regfile_t [REP-1:0] reg_file;
flags_fifo_t   [REP-1:0] w_fifo_flgs;

// Fault Detection Signals
// These signals are not replicated since a fault on it would be detected by definition

errs_streamer_t ecc_errors_streamer;

logic parallel_fault, serial_fault;

logic x_fault, w_fault, z_fault;
logic engine_fault, ctrl_fault, scheduler_fault, streamer_parallel_fault;

// Combine all fault outputs from parallel modules
assign parallel_fault = x_fault | w_fault | z_fault |
     engine_fault | ctrl_fault | scheduler_fault |
     streamer_parallel_fault;

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

// Additional Interfaces for Parity bits
// These have two uses
// 1. They replicate the handshake, thus enabling handshake fault detection
// 2. They transmit one parity bit per data byte, this allowing data fault detection
// (For some cases, data fault detection is not used parallely as by the "double loading" it is
// already covered by the serial output detection mechanism. These signals are simply never assigned
// And thus can be optimized).
// X streaming interface + X FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( 1 ), .STRB_WIDTH (STRBW) ) x_copy_buffer_d    ( .clk( clk_i ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( 1 ), .STRB_WIDTH (STRBW) ) x_copy_buffer_fifo ( .clk( clk_i ) );

// W streaming interface + W FIFO interface, special case since it hold parity information!
hwpe_stream_intf_stream #( .DATA_WIDTH ( STRBW ), .STRB_WIDTH (STRBW) ) w_copy_buffer_d    ( .clk( clk_i ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( STRBW ), .STRB_WIDTH (STRBW) ) w_copy_buffer_fifo ( .clk( clk_i ) );

// Y streaming interface + Y FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( 1 ), .STRB_WIDTH (STRBW) ) y_copy_buffer_d    ( .clk( clk_i ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( 1 ), .STRB_WIDTH (STRBW) ) y_copy_buffer_fifo ( .clk( clk_i ) );

// Z streaming interface + Z FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( 1 ), .STRB_WIDTH (STRBW) ) z_copy_buffer_q    ( .clk( clk_i ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( 1 ), .STRB_WIDTH (STRBW) ) z_copy_buffer_fifo ( .clk( clk_i ) );

logic [REP-1:0] test_mode;
logic [REP-1:0] enable;

for (genvar r = 0; r < REP; r++) begin: gen_streamer_in_array
  assign test_mode[r] = test_mode_i;
  assign enable[r] = 1'b1;
end

// The streamer will present a single master TCDM port used to stream data to and from the memeory.
redmule_streamer #(
  .DW                    ( DW                    ),
  .`HCI_SIZE_PARAM(tcdm) ( `HCI_SIZE_PARAM(tcdm) ),
  .SERIAL_REPLICATION    ( 1                     ), // Always allow serial fault detection since it is cheap
  .REDUCED_DATAPATH      ( 0                     )
) i_streamer (
  .clk_i          ( clk_i               ),
  .rst_ni         ( rst_ni              ),
  .test_mode_i    ( test_mode[0]        ),
  // Controller generated signals
  .enable_i       ( enable[0]           ),
  .clear_i        ( clear[0]            ),
  // Source interfaces for the incoming streams
  .x_stream_o     ( x_buffer_d          ),
  .w_stream_o     ( w_buffer_d          ),
  .y_stream_o     ( y_buffer_d          ),
  // Sink interface for the outgoing stream
  .z_stream_i     ( z_buffer_fifo       ),
  // Master TCDM interface ports for the memory side
  .tcdm           ( tcdm                ),
  .ecc_errors_o   ( ecc_errors_streamer ),
  .ctrl_i         ( cntrl_streamer[0]   ),
  .flags_o        ( flgs_streamer[0]    ),
  .serial_fault_o ( serial_fault        )
);


if (REP > 1) begin : gen_streamer_replica
  logic interface_hci_fault, streamer_flags_fault;

  hci_core_intf #(
    `ifndef SYNTHESIS
      .WAIVE_RSP3_ASSERT ( 1'b1 ), // waive RSP-3 on memory-side of HCI FIFO
      .WAIVE_RSP5_ASSERT ( 1'b1 ),  // waive RSP-5 on memory-side of HCI FIFO
    `endif
    .DW  ( `HCI_SIZE_GET_DW(tcdm) ),
    .UW  ( `HCI_SIZE_GET_UW(tcdm) )
  ) tcdm_replica (
    .clk ( clk_i )
  );

  hci_copy_sink # (
    .COPY_TYPE    ( hci_package::NO_ECC    ),
    .COMPARE_TYPE ( hci_package::CTRL_ONLY )
  ) i_hci_copy_sink (
    .clk_i,
    .rst_ni,
    .tcdm_main ( tcdm                ),
    .tcdm_copy ( tcdm_replica        ),
    .fault_o   ( interface_hci_fault )
  );

  redmule_streamer #(
    .DW                    ( DW                    ),
    .`HCI_SIZE_PARAM(tcdm) ( `HCI_SIZE_PARAM(tcdm) ),
    .SERIAL_REPLICATION    ( 0                     ),
    .REDUCED_DATAPATH      ( 1                     )
  ) i_streamer (
    .clk_i          ( clk_i              ),
    .rst_ni         ( rst_ni             ),
    .test_mode_i    ( test_mode[1]       ),
    // Controller generated signals
    .enable_i       ( enable[1]          ),
    .clear_i        ( clear[1]           ),
    // Source interfaces for the incoming streams
    .x_stream_o     ( x_copy_buffer_d    ),
    .w_stream_o     ( w_copy_buffer_d    ),
    .y_stream_o     ( y_copy_buffer_d    ),
    // Sink interface for the outgoing stream
    .z_stream_i     ( z_copy_buffer_fifo ),
    // Master TCDM interface ports for the memory side
    .tcdm           ( tcdm_replica       ),
    .ecc_errors_o   ( /* Unused */       ),
    .ctrl_i         ( cntrl_streamer[1]  ),
    .flags_o        ( flgs_streamer[1]   ),
    .serial_fault_o ( /* Unused */       )
  );

  assign streamer_flags_fault = flgs_streamer[0] != flgs_streamer[1];
  assign streamer_parallel_fault = streamer_flags_fault | interface_hci_fault;
end else begin: gen_no_streamer_replica
  assign streamer_parallel_fault = 1'b0;
end

/*---------------------------------------------------------------*/
/* |                            FIFOS                          | */
/*---------------------------------------------------------------*/

hwpe_stream_fifo #(
  .DATA_WIDTH     ( DATAW_ALIGN   ),
  .FIFO_DEPTH     ( 4             )
) i_x_buffer_fifo (
  .clk_i          ( clk_i         ),
  .rst_ni         ( rst_ni        ),
  .clear_i        ( clear[0]      ),
  .flags_o        (               ),
  .push_i         ( x_buffer_d    ),
  .pop_o          ( x_buffer_fifo )
);

hwpe_stream_fifo #(
  .DATA_WIDTH     ( DATAW_ALIGN    ),
  .FIFO_DEPTH     ( 4              )
) i_w_buffer_fifo (
  .clk_i          ( clk_i          ),
  .rst_ni         ( rst_ni         ),
  .clear_i        ( clear[0]       ),
  .flags_o        ( w_fifo_flgs[0] ),
  .push_i         ( w_buffer_d     ),
  .pop_o          ( w_buffer_fifo  )
);

hwpe_stream_fifo #(
  .DATA_WIDTH     ( DATAW_ALIGN   ),
  .FIFO_DEPTH     ( 4             )
) i_y_buffer_fifo (
  .clk_i          ( clk_i         ),
  .rst_ni         ( rst_ni        ),
  .clear_i        ( clear[0]      ),
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
  .clear_i        ( clear[0]      ),
  .flags_o        (               ),
  .push_i         ( z_buffer_q    ),
  .pop_o          ( z_buffer_fifo )
);

// Valid/Ready assignment
assign x_buffer_fifo.ready = flgs_scheduler[0].x_ready;
assign w_buffer_fifo.ready = flgs_scheduler[0].w_ready;
assign y_buffer_fifo.ready = flgs_scheduler[0].y_ready;

assign z_buffer_q.valid               = flgs_scheduler[0].z_valid;
assign z_buffer_q.strb                = flgs_scheduler[0].z_strb;
assign z_buffer_ctrl[0].ready         = z_buffer_q.ready;
assign z_buffer_ctrl[0].y_valid       = y_buffer_fifo.valid;
assign z_buffer_ctrl[0].y_push_enable = flgs_scheduler[0].y_push_enable;

if (REP > 1) begin : gen_parity_fifos
  hwpe_stream_fifo #(
    .DATA_WIDTH     ( 1     ),
    .STRB_WIDTH     ( STRBW ),
    .FIFO_DEPTH     ( 4     )
  ) i_x_strb_fifo (
    .clk_i          ( clk_i              ),
    .rst_ni         ( rst_ni             ),
    .clear_i        ( clear[1]           ),
    .flags_o        (                    ),
    .push_i         ( x_copy_buffer_d    ),
    .pop_o          ( x_copy_buffer_fifo )
  );

  hwpe_stream_fifo #(
    .DATA_WIDTH     ( STRBW ),
    .STRB_WIDTH     ( STRBW ),
    .FIFO_DEPTH     ( 4     )
  ) i_w_parity_fifo (
    .clk_i          ( clk_i              ),
    .rst_ni         ( rst_ni             ),
    .clear_i        ( clear[1]           ),
    .flags_o        ( w_fifo_flgs[1]     ),
    .push_i         ( w_copy_buffer_d    ),
    .pop_o          ( w_copy_buffer_fifo )
  );

  hwpe_stream_fifo #(
    .DATA_WIDTH     ( 1     ),
    .STRB_WIDTH     ( STRBW ),
    .FIFO_DEPTH     ( 4     )
  ) i_y_strb_fifo (
    .clk_i          ( clk_i              ),
    .rst_ni         ( rst_ni             ),
    .clear_i        ( clear[1]           ),
    .flags_o        (                    ),
    .push_i         ( y_copy_buffer_d    ),
    .pop_o          ( y_copy_buffer_fifo )
  );

  hwpe_stream_fifo #(
    .DATA_WIDTH     ( 1     ),
    .STRB_WIDTH     ( STRBW ),
    .FIFO_DEPTH     ( 2     )
  ) i_z_strb_fifo (
    .clk_i          ( clk_i              ),
    .rst_ni         ( rst_ni             ),
    .clear_i        ( clear[1]           ),
    .flags_o        (                    ),
    .push_i         ( z_copy_buffer_q    ),
    .pop_o          ( z_copy_buffer_fifo )
  );

  // Valid/Ready assignment
  assign x_copy_buffer_fifo.ready       = flgs_scheduler[1].x_ready;
  assign w_copy_buffer_fifo.ready       = flgs_scheduler[1].w_ready;
  assign y_copy_buffer_fifo.ready       = flgs_scheduler[1].y_ready;

  assign z_copy_buffer_q.valid          = flgs_scheduler[1].z_valid;
  assign z_copy_buffer_q.strb           = flgs_scheduler[1].z_strb;
  assign z_copy_buffer_q.data           = DONT_CARE;
  assign z_buffer_ctrl[1].ready         = z_copy_buffer_q.ready;
  assign z_buffer_ctrl[1].y_valid       = y_copy_buffer_fifo.valid;
  assign z_buffer_ctrl[1].y_push_enable = flgs_scheduler[1].y_push_enable;
end

/*----------------------------------------------------------------*/
/* |                          Buffers                           | */
/*----------------------------------------------------------------*/

logic [REP-1:0] x_buffer_clk_en;

logic [Width-1:0][Height-1:0][BITW-1:0] x_buffer_q;
redmule_x_buffer #(
  .DW       ( DATAW_ALIGN ),
  .FpFormat ( FpFormat    ),
  .Height   ( Height      ),
  .Width    ( Width       ),
  .REP      ( REP         )
) i_x_buffer (
  .clk_i           ( clk_i              ),
  .rst_ni          ( rst_ni             ),
  .buffer_clk_en_i ( x_buffer_clk_en    ),
  .clear_i         ( clear | soft_clear ),
  .ctrl_i          ( x_buffer_ctrl      ),
  .flags_o         ( x_buffer_flgs      ),
  .x_buffer_o      ( x_buffer_q         ),
  .x_buffer_i      ( x_buffer_fifo.data ),
  .fault_o         ( x_fault            )
);


logic [Height-1:0][BITW-1:0] w_buffer_q;
logic [Height-1:0][BITW/8-1:0] w_buffer_parity_q;
redmule_w_buffer #(
  .DW       ( DATAW_ALIGN     ),
  .PW       ( DATAW_ALIGN / 8 ),
  .FpFormat ( FpFormat        ),
  .Height   ( Height          ),
  .REP      ( REP             ),
  .W_PARITY ( W_PARITY        )
) i_w_buffer (
  .clk_i      ( clk_i                   ),
  .rst_ni     ( rst_ni                  ),
  .clear_i    ( clear | soft_clear      ),
  .ctrl_i     ( w_buffer_ctrl           ),
  .flags_o    ( w_buffer_flgs           ),
  .w_buffer_o ( w_buffer_q              ),
  .w_parity_o ( w_buffer_parity_q       ),
  .w_buffer_i ( w_buffer_fifo.data      ),
  .w_parity_i ( w_copy_buffer_fifo.data ),
  .fault_o    ( w_fault                 )
);

logic [Width-1:0][BITW-1:0] z_buffer_d, y_bias_q;
redmule_z_buffer #(
  .DW       ( DATAW_ALIGN ),
  .FpFormat ( FpFormat    ),
  .Width    ( Width       ),
  .REP      ( REP         )
) i_z_buffer (
  .clk_i        ( clk_i              ),
  .rst_ni       ( rst_ni             ),
  .clear_i      ( clear | soft_clear ),
  .reg_enable_i ( reg_enable         ),
  .ctrl_i       ( z_buffer_ctrl      ),
  .flags_o      ( z_buffer_flgs      ),
  .y_buffer_i   ( y_buffer_fifo.data ),
  .z_buffer_i   ( z_buffer_d         ),
  .y_buffer_o   ( y_bias_q           ),
  .z_buffer_o   ( z_buffer_q.data    ),
  .fault_o      ( z_fault            )
);

/*---------------------------------------------------------------*/
/* |                          Engine                           | */
/*---------------------------------------------------------------*/

// Engine instance
redmule_engine #(
  .FpFormat    ( FpFormat    ),
  .Height      ( Height      ),
  .Width       ( Width       ),
  .NumPipeRegs ( NumPipeRegs ),
  .PipeConfig  ( PipeConfig  ),
  .W_PARITY    ( W_PARITY    ),
  .REP         ( REP         ),
  .PARW        ( BITW/8      )
) i_redmule_engine (
  .clk_i         ( clk_i             ),
  .rst_ni        ( rst_ni            ),
  .x_input_i     ( x_buffer_q        ),
  .w_input_i     ( w_buffer_q        ),
  .w_parity_i    ( w_buffer_parity_q ),
  .y_bias_i      ( y_bias_q          ),
  .z_output_o    ( z_buffer_d        ),
  .accumulate_i  ( accumulate        ),
  .reg_enable_i  ( reg_enable        ),
  .flush_i       ( engine_flush      ),
  .ctrl_engine_i ( cntrl_engine      ),
  .flgs_engine_o ( flgs_engine       ),
  .fault_o       ( engine_fault      )
);

/*---------------------------------------------------------------*/
/* |                        Controller                         | */
/*---------------------------------------------------------------*/

logic [REP-1:0] local_busy;
logic [REP-1:0][N_CORES-1:0][1:0] local_evt;
logic [REP-1:0] local_ctrl_fault;

assign busy_o = local_busy[0];
assign evt_o = local_evt[0];
assign ctrl_fault = |local_ctrl_fault;

for (genvar r = 0; r < REP; r++) begin: gen_controllers
  hwpe_ctrl_intf_periph #( .ID_WIDTH( ID_WIDTH ) ) periph_local ( .clk( clk_i ) );

  // TODO: Make copy source / sink for hwpe_ctrl and instantiate instead
  // Periph port binding from local
  always_comb begin
    periph_local.req  = periph.req;
    periph_local.add  = periph.add;
    periph_local.wen  = periph.wen;
    periph_local.be   = periph.be;
    periph_local.data = periph.data;
    periph_local.id   = periph.id;
  end

  // Feedback only on first instance
  if (r == 0) begin
    always_comb begin
      periph.gnt        = periph_local.gnt;
      periph.r_data     = periph_local.r_data;
      periph.r_valid    = periph_local.r_valid;
      periph.r_id       = periph_local.r_id;
    end
  end

  redmule_ctrl #(
    .N_CORES     ( N_CORES      ),
    .IO_REGS     ( REDMULE_REGS ),
    .ID_WIDTH    ( ID_WIDTH     ),
    .N_CONTEXT   ( NumContext   ),
    .Height      ( Height       ),
    .Width       ( Width        ),
    .NumPipeRegs ( NumPipeRegs  )
  ) i_control (
    .clk_i             ( clk_i                      ),
    .rst_ni            ( rst_ni                     ),
    .test_mode_i       ( test_mode_i                ),
    .busy_o            ( local_busy[r]              ),
    .clear_o           ( clear[r]                   ),
    .evt_o             ( local_evt[r]               ),
    .z_fill_o          ( z_buffer_ctrl[r].fill      ),
    .w_shift_o         ( w_shift[r]                 ),
    .z_buffer_clk_en_o ( ctrl_z_clk_en[r]           ),
    .reg_file_o        ( reg_file[r]                ),
    .reg_enable_i      ( reg_enable[r]              ),
    .flgs_z_buffer_i   ( z_buffer_flgs[r]           ),
    .flgs_engine_i     ( flgs_engine                ),
    .w_loaded_i        ( flgs_scheduler[r].w_loaded ),
    .flush_o           ( engine_flush[r]            ),
    .accumulate_o      ( accumulate[r]              ),
    .cntrl_scheduler_o ( cntrl_scheduler[r]         ),
    .errs_streamer_i   ( ecc_errors_streamer        ),
    .periph            ( periph_local               ),
    .parallel_fault_i  ( parallel_fault             ),
    .serial_fault_i    ( serial_fault               )
  );

  // Output Voters
  if (r > 0) begin: gen_ctrl_voters
    logic same_busy;
    logic same_clear;
    logic same_evt;
    logic same_fill;
    logic same_w_shift;
    logic same_ctrl_z_clk_en;
    logic same_reg_file;
    logic same_engine_flush;
    logic same_accumulate;
    logic same_cntrl_scheduler;
    logic same_periph_gnt;
    logic same_periph_r_data;
    logic same_periph_r_valid;
    logic same_periph_r_id;

    assign same_busy            =      local_busy[r-1]      ==      local_busy[r];
    assign same_clear           =           clear[r-1]      ==           clear[r];
    assign same_evt             =       local_evt[r-1]      ==       local_evt[r];
    assign same_fill            =   z_buffer_ctrl[r-1].fill ==   z_buffer_ctrl[r].fill;
    assign same_w_shift         =         w_shift[r-1]      ==         w_shift[r];
    assign same_ctrl_z_clk_en   =   ctrl_z_clk_en[r-1]      ==   ctrl_z_clk_en[r];
    assign same_reg_file        =        reg_file[r-1]      ==        reg_file[r];
    assign same_engine_flush    =    engine_flush[r-1]      ==    engine_flush[r];
    assign same_accumulate      =      accumulate[r-1]      ==      accumulate[r];
    assign same_cntrl_scheduler = cntrl_scheduler[r-1]      == cntrl_scheduler[r];
    assign same_periph_gnt      = periph.gnt     == periph_local.gnt;
    assign same_periph_r_data   = periph.r_data  == periph_local.r_data;
    assign same_periph_r_valid  = periph.r_valid == periph_local.r_valid;
    assign same_periph_r_id     = periph.r_id    == periph_local.r_id;

    assign local_ctrl_fault[r] =
      ~same_busy | ~same_clear | ~same_evt | ~same_fill | ~same_w_shift | ~same_ctrl_z_clk_en |
      ~same_reg_file | ~same_engine_flush | ~same_accumulate | ~same_cntrl_scheduler |
      ~same_periph_gnt | ~same_periph_r_data | ~same_periph_r_valid | ~same_periph_r_id;

  end else begin: gen_no_control_voters
    assign local_ctrl_fault[r] = 1'b0;
  end

end

/*---------------------------------------------------------------*/
/* |                        Local FSM                          | */
/*---------------------------------------------------------------*/
logic [REP-1:0] local_scheduler_fault;

assign scheduler_fault = |local_scheduler_fault;

for (genvar r = 0; r < REP; r++) begin: gen_scheduler

  // Assign parity and normal flags to each FSM
  logic x_valid, w_valid, y_fifo_valid, z_ready;
  logic [STRBW-1:0] x_strb, w_strb, y_fifo_strb;
  if (r > 0) begin
    assign x_valid      = x_copy_buffer_fifo.valid;
    assign x_strb       = x_copy_buffer_fifo.strb;
    assign w_valid      = w_copy_buffer_fifo.valid;
    assign w_strb       = w_copy_buffer_fifo.strb;
    assign y_fifo_valid = y_copy_buffer_fifo.valid;
    assign y_fifo_strb  = y_copy_buffer_fifo.strb;
    assign z_ready      = z_copy_buffer_q.ready;
  end else begin
    assign x_valid      = x_buffer_fifo.valid;
    assign x_strb       = x_buffer_fifo.strb;
    assign w_valid      = w_buffer_fifo.valid;
    assign w_strb       = w_buffer_fifo.strb;
    assign y_fifo_valid = y_buffer_fifo.valid;
    assign y_fifo_strb  = y_buffer_fifo.strb;
    assign z_ready      = z_buffer_q.ready;
  end

  redmule_scheduler    #(
    .Height      ( Height      ),
    .Width       ( Width       ),
    .NumPipeRegs ( NumPipeRegs )
  ) i_scheduler (
    .clk_i              ( clk_i                        ),
    .rst_ni             ( rst_ni                       ),
    .test_mode_i        ( test_mode_i                  ),
    .clear_i            ( clear[r]                     ),
    .x_valid_i          ( x_valid                      ),
    .x_strb_i           ( x_strb                       ),
    .w_valid_i          ( w_valid                      ),
    .w_strb_i           ( w_strb                       ),
    .y_fifo_valid_i     ( y_fifo_valid                 ),
    .y_fifo_strb_i      ( y_fifo_strb                  ),
    .z_ready_i          ( z_ready                      ),
    .accumulate_i       ( accumulate[r]                ),
    .engine_flush_i     ( engine_flush[r]              ),
    .z_strb_o           (                              ),
    .soft_clear_o       ( soft_clear[r]                ),
    .w_load_o           ( w_buffer_ctrl[r].load        ),
    .w_cols_lftovr_o    ( w_buffer_ctrl[r].cols_lftovr ),
    .w_rows_lftovr_o    ( w_buffer_ctrl[r].rows_lftovr ),
    .y_cols_lftovr_o    ( z_buffer_ctrl[r].cols_lftovr ),
    .y_rows_lftovr_o    ( z_buffer_ctrl[r].rows_lftovr ),
    .gate_en_o          ( gate_en[r]                   ),
    .x_buffer_clk_en_o  ( x_buffer_clk_en[r]           ),
    .z_buffer_clk_en_o  ( fsm_z_clk_en[r]              ),
    .reg_enable_o       ( reg_enable[r]                ),
    .z_store_o          ( z_buffer_ctrl[r].store       ),
    .y_buffer_load_o    ( z_buffer_ctrl[r].load        ),
    .reg_file_i         ( reg_file[r]                  ),
    .flgs_streamer_i    ( flgs_streamer[r]             ),
    .flgs_x_buffer_i    ( x_buffer_flgs[r]             ),
    .flgs_w_buffer_i    ( w_buffer_flgs[r]             ),
    .flgs_z_buffer_i    ( z_buffer_flgs[r]             ),
    .flgs_engine_i      ( flgs_engine                  ),
    .fifo_flgs_i        ( w_fifo_flgs[r]               ),
    .cntrl_scheduler_i  ( cntrl_scheduler[r]           ),
    .cntrl_engine_o     ( cntrl_engine[r]              ),
    .cntrl_streamer_o   ( cntrl_streamer[r]            ),
    .cntrl_x_buffer_o   ( x_buffer_ctrl[r]             ),
    .flgs_scheduler_o   ( flgs_scheduler[r]            )
  );

  // Output Voters
  if (r > 0) begin: gen_scheduler_voters
    logic same_soft_clear;
    logic same_w_load, same_w_cols_lftovr, same_w_rows_lftovr;
    logic same_y_cols_lftovr, same_y_rows_lftovr;
    logic same_gate_en;
    logic same_x_buffer_clk_en, same_z_buffer_clk_en;
    logic same_reg_enable;
    logic same_z_store;
    logic same_y_buffer_load;
    logic same_cntrl_engine;
    logic same_cntrl_streamer;
    logic same_x_buffer_ctrl;
    logic same_flgs_scheduler;

    assign same_soft_clear       =      soft_clear[r-1]             == soft_clear[0];
    assign same_w_load           =   w_buffer_ctrl[r-1].load        == w_buffer_ctrl[0].load;
    assign same_w_cols_lftovr    =   w_buffer_ctrl[r-1].cols_lftovr == w_buffer_ctrl[0].cols_lftovr;
    assign same_w_rows_lftovr    =   w_buffer_ctrl[r-1].rows_lftovr == w_buffer_ctrl[0].rows_lftovr;
    assign same_y_cols_lftovr    =   z_buffer_ctrl[r-1].cols_lftovr == z_buffer_ctrl[0].cols_lftovr;
    assign same_y_rows_lftovr    =   z_buffer_ctrl[r-1].rows_lftovr == z_buffer_ctrl[0].rows_lftovr;
    assign same_gate_en          =         gate_en[r-1]             == gate_en[0];
    assign same_x_buffer_clk_en  = x_buffer_clk_en[r-1]             == x_buffer_clk_en[0];
    assign same_z_buffer_clk_en  =    fsm_z_clk_en[r-1]             == fsm_z_clk_en[0];
    assign same_reg_enable       =      reg_enable[r-1]             == reg_enable[0];
    assign same_z_store          =   z_buffer_ctrl[r-1].store       == z_buffer_ctrl[0].store;
    assign same_y_buffer_load    =   z_buffer_ctrl[r-1].load        == z_buffer_ctrl[0].load;
    assign same_cntrl_engine     =    cntrl_engine[r-1]             == cntrl_engine[0];
    assign same_cntrl_streamer   =  cntrl_streamer[r-1]             == cntrl_streamer[0];
    assign same_x_buffer_ctrl    =   x_buffer_ctrl[r-1]             == x_buffer_ctrl[0];
    assign same_flgs_scheduler   =  flgs_scheduler[r-1]             == flgs_scheduler[0];

    assign local_scheduler_fault[r] =
        ~same_soft_clear | ~same_w_load | ~same_w_cols_lftovr | ~same_w_rows_lftovr |
        ~same_y_cols_lftovr | ~same_y_rows_lftovr | ~same_gate_en | ~same_x_buffer_clk_en |
        ~same_z_buffer_clk_en | ~same_reg_enable | ~same_z_store | ~same_y_buffer_load |
        ~same_cntrl_engine | ~same_cntrl_streamer | ~same_x_buffer_ctrl | ~same_flgs_scheduler;

  end else begin: gen_no_scheduler_voters;
    assign local_scheduler_fault[r] = 1'b0;
  end
end

// Combine Control Signals From FSM and CTRL
for (genvar r = 0; r < REP; r++) begin: gen_w_buffer_ctrl
  assign w_buffer_ctrl[r].shift         = w_shift[r] & flgs_scheduler[r].w_shift;
  assign z_buffer_ctrl[r].buffer_clk_en = (fsm_z_clk_en[r] | ctrl_z_clk_en[r]);
end

endmodule : redmule_top
