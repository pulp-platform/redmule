// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
// Arpan Suravi Prasad<prasadar@iis.ee.ethz.ch>

`include "hci_helpers.svh"

module redmule_top
  import fpnew_pkg::*;
  import redmule_pkg::*;
  import hci_package::*;
  import hwpe_ctrl_package::*;
  import hwpe_stream_package::*;
#(
  parameter int unsigned  DataW                   = MaxDataW, // TCDM port dimension (in bits)
  parameter int unsigned  MisalignedAccessSupport = MisalignedAccessSupportDefault, // set to 1 to support misaligned accesses on TCDM
  parameter fp_format_e   FpFormat                = FP16, // Data format (default is FP16)
  parameter int unsigned  Height                  = MaxDim, // Number of PEs within a row
  parameter int unsigned  Width                   = MaxDim, // Number of parallel rows
  parameter int unsigned  NumPipeRegs             = MaxPipeRegs-1, // Number of pipeline registers within each PE
  parameter pipe_config_t PipeConfig              = DISTRIBUTED,
  parameter int unsigned  EccChunkSize            = 32,
  parameter bit           LatchBuffers            = 0,
  parameter fpnew_pkg::fmt_logic_t  FpFmtConfig   = 6'b001101,
  parameter fpnew_pkg::ifmt_logic_t IntFmtConfig  = 4'b1000,
  // Choose interface
  parameter ctrl_intf_e   CtrlIntfConfig          = XIF,
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
  // XIF ports (unused if CtrlIntfConfig = HWPE_TARGET)
  input  x_issue_req_t  x_issue_req_i,
  output x_issue_resp_t x_issue_resp_o,
  input  logic          x_issue_valid_i,
  output logic          x_issue_ready_o,
  input  x_register_t   x_register_i,
  input  logic          x_register_valid_i,
  output logic          x_register_ready_o,
  input  x_commit_t     x_commit_i,
  input  logic          x_commit_valid_i,
  output x_result_t     x_result_o,
  output logic          x_result_valid_o,
  input  logic          x_result_ready_i,
  // Synchronization ports
  output logic          sync_o,
  input  logic          sync_i,
  // TCDM master ports for the memory side
  hci_core_intf.initiator tcdm,
  // HWPE-ctrl target port (unused if CtrlIntfConfig = XIF)
  hwpe_ctrl_intf_periph.slave target
);

localparam int unsigned FpWidth = fp_width(FpFormat);
localparam int unsigned Depth   = DataW/FpWidth;

logic                       clk_acc;

logic                       fsm_z_clk_en, ctrl_z_clk_en;
logic                       enable, clear;
logic                       target_clear;
logic                       y_buffer_depth_count,
                            y_buffer_load,
                            z_buffer_fill,
                            z_buffer_store;
logic                       w_shift;
logic                       w_load;
logic                       reg_enable,
                            gate_en;
logic                       cfg_complete;
logic [31:0]                x_cols_offs,
                            x_rows_offs;
logic [$clog2(Width):0]     x_rows_lftover;
logic [$clog2(Depth):0]     w_cols_lftovr,
                            y_cols_lftovr;
logic [$clog2(Height):0]    w_rows_lftovr;
logic [$clog2(Width):0]     y_rows_lftovr;

// Streamer control signals and flags
cntrl_streamer_t cntrl_streamer_int, cntrl_streamer;
flgs_streamer_t  flgs_streamer;

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

// Configuration of the current operation
redmule_config_t redmule_config;
flags_fifo_t   w_fifo_flgs, z_fifo_flgs;
cntrl_flags_t  cntrl_flags;

redmule_config_t dec_config;
logic            dec_config_valid;

logic config_fifo_empty, config_fifo_full;

tc_clk_gating i_acc_clock_gating (
  .clk_i     ( clk_i                                          ),
  .en_i      ( dec_config_valid | ~config_fifo_empty | busy_o ),
  .test_en_i ( '0                                             ),
  .clk_o     ( clk_acc                                        )
);

/*--------------------------------------------------------------*/
/* |                         Streamer                         | */
/*--------------------------------------------------------------*/

// Implementation of the incoming and outgoing streaming interfaces (one for each kind of data)

// X streaming interface + X FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( DataW ) ) x_stream_str       ( .clk( clk_acc ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( DataW ) ) x_buffer_d         ( .clk( clk_acc ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( DataW ) ) x_buffer_fifo      ( .clk( clk_acc ) );

// W streaming interface + W FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( DataW ) ) w_stream_str       ( .clk( clk_acc ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( DataW ) ) w_buffer_d         ( .clk( clk_acc ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( DataW ) ) w_buffer_fifo      ( .clk( clk_acc ) );

// Y streaming interface + Y FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( DataW ) ) y_buffer_d         ( .clk( clk_acc ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( DataW ) ) y_buffer_fifo      ( .clk( clk_acc ) );

// Z streaming interface + Z FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( DataW ) ) z_buffer_q         ( .clk( clk_acc ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( DataW ) ) z_buffer_fifo      ( .clk( clk_acc ) );

// The streamer will present a single master TCDM port used to stream data to and from the memeory.
redmule_streamer #(
  .DataW                   ( DataW                   ),
  .MisalignedAccessSupport ( MisalignedAccessSupport ),
  .EccChunkSize            ( EccChunkSize            ),
  .FpFormat                ( FpFormat                ),
  .FpFmtConfig             ( FpFmtConfig             ),
  .IntFmtConfig            ( IntFmtConfig            ),
  .`HCI_SIZE_PARAM(tcdm) ( `HCI_SIZE_PARAM(tcdm) )
) i_streamer      (
  .clk_i           ( clk_acc         ),
  .rst_ni          ( rst_ni          ),
  .test_mode_i     ( test_mode_i     ),
  // Controller generated signals
  .enable_i        ( 1'b1            ),
  .clear_i         ( target_clear    ),
  // Source interfaces for the incoming streams
  .x_stream_o      ( x_stream_str    ),
  .w_stream_o      ( w_stream_str    ),
  .y_stream_o      ( y_buffer_d      ),
  // Sink interface for the outgoing stream
  .z_stream_i      ( z_buffer_fifo   ),
  // Master TCDM interface ports for the memory side
  .tcdm            ( tcdm            ),
  .ctrl_i          ( cntrl_streamer  ),
  .flags_o         ( flgs_streamer   )
);


redmule_config_t x_sel_config, w_sel_config;
logic x_done;

redmule_config_fifo #(
  .FALL_THROUGH (0),
  .DEPTH (2),
  .dtype (redmule_config_t)
) i_x_config_fifo (
  .clk_i      ( clk_acc                                  ),
  .rst_ni     ( rst_ni                                   ),
  .flush_i    ( clear                                    ),
  .testmode_i ( '0                                       ),
  .full_o     (                                          ),
  .empty_o    (                                          ),
  .usage_o    (                                          ),
  .data_i     ( redmule_config                           ),
  .push_i     ( cfg_complete                             ),
  .data_o     ( x_sel_config                             ),
  .pop_i      ( x_done                                   )
);

redmule_config_fifo #(
  .FALL_THROUGH (0),
  .DEPTH (2),
  .dtype (redmule_config_t)
) i_w_config_fifo (
  .clk_i      ( clk_acc                                  ),
  .rst_ni     ( rst_ni                                   ),
  .flush_i    ( clear                                    ),
  .testmode_i ( '0                                       ),
  .full_o     (                                          ),
  .empty_o    (                                          ),
  .usage_o    (                                          ),
  .data_i     ( redmule_config                           ),
  .push_i     ( cfg_complete                             ),
  .data_o     ( w_sel_config                             ),
  .pop_i      ( flgs_streamer.w_stream_source_flags.done )
);

logic w_sel;
logic w_send;

assign w_sel  = w_sel_config.receive_w;
assign w_send = w_sel_config.send_w;

assign w_buffer_d.valid   = ((w_sel) ? w_stream_i.valid : w_stream_str.valid) && ((w_send) ? w_stream_o.ready && w_buffer_d.ready : 1'b1);
assign w_buffer_d.data    = (w_sel) ? w_stream_i.data  : w_stream_str.data;
assign w_buffer_d.strb    = (w_sel) ? w_stream_i.strb  : w_stream_str.strb;
assign w_stream_str.ready = (w_sel) ? 1'b0             : w_buffer_d.ready && ((w_send) ? w_stream_o.ready : 1'b1);
assign w_stream_i.ready   = (w_sel) ? w_buffer_d.ready : 1'b0;

assign w_stream_o.valid = (w_send) ? w_buffer_d.valid : 1'b0;
assign w_stream_o.data  = (w_send) ? w_buffer_d.data : '0;
assign w_stream_o.strb  = (w_send) ? w_buffer_d.strb : '0;

logic x_sel;
logic x_send;

assign x_sel  = x_sel_config.receive_x;
assign x_send = x_sel_config.send_x;

assign x_buffer_d.valid   = ((x_sel) ? x_stream_i.valid : x_stream_str.valid) && ((x_send) ? x_stream_o.ready && x_buffer_d.ready : 1'b1);
assign x_buffer_d.data    = (x_sel) ? x_stream_i.data  : x_stream_str.data;
assign x_buffer_d.strb    = (x_sel) ? x_stream_i.strb  : x_stream_str.strb;
assign x_stream_str.ready = (x_sel) ? 1'b0             : x_buffer_d.ready && ((x_send) ? x_stream_o.ready : 1'b1);
assign x_stream_i.ready   = (x_sel) ? x_buffer_d.ready : 1'b0;

assign x_stream_o.valid = (x_send) ? x_buffer_d.valid : 1'b0;
assign x_stream_o.data  = (x_send) ? x_buffer_d.data : '0;
assign x_stream_o.strb  = (x_send) ? x_buffer_d.strb : '0;

hwpe_stream_fifo #(
  .DATA_WIDTH     ( DataW         ),
  .FIFO_DEPTH     ( 4             )
) i_x_buffer_fifo (
  .clk_i          ( clk_acc       ),
  .rst_ni         ( rst_ni        ),
  .clear_i        ( clear         ),
  .flags_o        (               ),
  .push_i         ( x_buffer_d    ),
  .pop_o          ( x_buffer_fifo )
);

hwpe_stream_fifo #(
  .DATA_WIDTH     ( DataW         ),
  .FIFO_DEPTH     ( 4             )
) i_w_buffer_fifo (
  .clk_i          ( clk_acc       ),
  .rst_ni         ( rst_ni        ),
  .clear_i        ( clear         ),
  .flags_o        ( w_fifo_flgs   ),
  .push_i         ( w_buffer_d    ),
  .pop_o          ( w_buffer_fifo )
);

hwpe_stream_fifo #(
  .DATA_WIDTH     ( DataW         ),
  .FIFO_DEPTH     ( 4             )
) i_y_buffer_fifo (
  .clk_i          ( clk_acc       ),
  .rst_ni         ( rst_ni        ),
  .clear_i        ( clear         ),
  .flags_o        (               ),
  .push_i         ( y_buffer_d    ),
  .pop_o          ( y_buffer_fifo )
);

hwpe_stream_fifo #(
  .DATA_WIDTH     ( DataW         ),
  .FIFO_DEPTH     ( 4             )
) i_z_buffer_fifo (
  .clk_i          ( clk_acc       ),
  .rst_ni         ( rst_ni        ),
  .clear_i        ( clear         ),
  .flags_o        ( z_fifo_flgs   ),
  .push_i         ( z_buffer_q    ),
  .pop_o          ( z_buffer_fifo )
);

// Valid/Ready assignment
assign x_buffer_fifo.ready     = x_buffer_ctrl.load;
assign w_buffer_fifo.ready     = w_buffer_flgs.w_ready;

assign y_buffer_fifo.ready     = z_buffer_flgs.y_ready;

assign z_buffer_q.valid        = z_buffer_flgs.z_valid;

/*----------------------------------------------------------------*/
/* |                          Buffers                           | */
/*----------------------------------------------------------------*/

logic [Width-1:0][Height-1:0][FpWidth-1:0] x_buffer_q;
redmule_x_buffer #(
  .DataW      ( DataW        ),
  .FpFormat   ( FpFormat     ),
  .Height     ( Height       ),
  .Width      ( Width        ),
  .UseLatches ( LatchBuffers )
) i_x_buffer  (
  .clk_i      ( clk_acc            ),
  .rst_ni     ( rst_ni             ),
  .clear_i    ( clear              ),
  .ctrl_i     ( x_buffer_ctrl      ),
  .flags_o    ( x_buffer_flgs      ),
  .x_buffer_o ( x_buffer_q         ),
  .x_buffer_i ( x_buffer_fifo.data )
);

logic [Height-1:0][FpWidth-1:0]   w_buffer_q;

redmule_w_buffer #(
  .DataW       ( DataW        ),
  .FpFormat    ( FpFormat     ),
  .Height      ( Height       ),
  .NumRegs     ( NumPipeRegs  ),
  .UseLatches  ( LatchBuffers )
) i_w_buffer   (
  .clk_i       ( clk_acc            ),
  .rst_ni      ( rst_ni             ),
  .clear_i     ( clear              ),
  .ctrl_i      ( w_buffer_ctrl      ),
  .flags_o     ( w_buffer_flgs      ),
  .w_buffer_o  ( w_buffer_q         ),
  .w_buffer_i  ( w_buffer_fifo.data )
);

logic [Width-1:0][FpWidth-1:0] z_buffer_d, y_bias_q;
redmule_z_buffer #(
  .DataW         ( DataW        ),
  .FpFormat      ( FpFormat     ),
  .Width         ( Width        ),
  .UseLatches    ( LatchBuffers )
) i_z_buffer     (
  .clk_i         ( clk_acc            ),
  .rst_ni        ( rst_ni             ),
  .clear_i       ( clear              ),
  .reg_enable_i  ( reg_enable         ),
  .ctrl_i        ( z_buffer_ctrl      ),
  .flags_o       ( z_buffer_flgs      ),
  .y_buffer_i    ( y_buffer_fifo.data ),
  .z_buffer_i    ( z_buffer_d         ),
  .y_buffer_o    ( y_bias_q           ),
  .z_buffer_o    ( z_buffer_q.data    ),
  .z_strb_o      ( z_buffer_q.strb    )
);

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
  .clk_i              ( clk_acc          ),
  .rst_ni             ( rst_ni           ),
  .x_input_i          ( x_buffer_q       ),
  .w_input_i          ( w_buffer_q       ),
  .y_bias_i           ( y_bias_q         ),
  .z_output_o         ( z_buffer_d       ),
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
/* |                    Memory Controller                      | */
/*---------------------------------------------------------------*/

logic z_priority;
assign z_priority = z_buffer_flgs.z_priority & !z_fifo_flgs.empty;

logic z_fifo_empty, z_fifo_full;

redmule_memory_scheduler #(
  .DW ( DataW  ),
  .W  ( Width  ),
  .H  ( Height )
) i_memory_scheduler (
  .clk_i             ( clk_acc         ),
  .rst_ni            ( rst_ni          ),
  .clear_i           ( target_clear    ),
  .z_priority_i      ( z_priority      ),
  .config_i          ( redmule_config  ),
  .config_valid_i    ( cfg_complete    ),
  .flgs_streamer_i   ( flgs_streamer   ),
  .cntrl_scheduler_i ( cntrl_scheduler ),
  .cntrl_flags_i     ( cntrl_flags     ),
  .z_fifo_empty_o    ( z_fifo_empty    ),
  .z_fifo_full_o     ( z_fifo_full     ),
  .x_done_o          ( x_done          ),
  .cntrl_streamer_o  ( cntrl_streamer  )
);

/*---------------------------------------------------------------*/
/* | Instruction Decoder (XIF) or Target Decoder (HWPE_TARGET) | */
/*---------------------------------------------------------------*/

logic tiler_busy;
redmule_config_t dec_config_q;

if(CtrlIntfConfig == XIF) begin : xif_ctrl_intf_gen
  redmule_inst_decoder #(
    .InstFifoDepth         ( 4                     ),
    .McnfigOpCode          ( McnfigOpCode          ),
    .MarithOpCode          ( MarithOpCode          ),
    .MopcntOpCode          ( MopcntOpCode          ),
    .McnfigFunct3          ( McnfigFunct3          ),
    .MarithFunct3          ( MarithFunct3          ),
    .MopcntFunct3          ( MopcntFunct3          ),
    .McnfigFunct2          ( McnfigFunct2          ),
    .MarithFunct2          ( MarithFunct2          ),
    .MopcntFunct2          ( MopcntFunct2          ),
    .XifIdWidth            ( XifIdWidth            ),
    .XifNumHarts           ( XifNumHarts           ),
    .XifIssueRegisterSplit ( XifIssueRegisterSplit ),
    .x_issue_req_t         ( x_issue_req_t         ),
    .x_issue_resp_t        ( x_issue_resp_t        ),
    .x_register_t          ( x_register_t          ),
    .x_commit_t            ( x_commit_t            ),
    .x_result_t            ( x_result_t            )
  ) i_inst_decoder (
    .clk_i              ( clk_i                                  ),
    .rst_ni             ( rst_ni                                 ),
    .clear_i            ( '0                                     ), // TODO: fixme, not having a software-based clear mechanism is a bad idea.
    .config_ready_i     ( ~config_fifo_full                      ),
    .op_done_i          ( flgs_streamer.z_stream_sink_flags.done ),
    .config_valid_o     ( dec_config_valid                       ),
    .config_o           ( dec_config                             ),
    .x_issue_req_i      ( x_issue_req_i                          ),
    .x_issue_resp_o     ( x_issue_resp_o                         ),
    .x_issue_valid_i    ( x_issue_valid_i                        ),
    .x_issue_ready_o    ( x_issue_ready_o                        ),
    .x_register_i       ( x_register_i                           ),
    .x_register_valid_i ( x_register_valid_i                     ),
    .x_register_ready_o ( x_register_ready_o                     ),
    .x_commit_i         ( x_commit_i                             ),
    .x_commit_valid_i   ( x_commit_valid_i                       ),
    .x_result_o         ( x_result_o                             ),
    .x_result_valid_o   ( x_result_valid_o                       ),
    .x_result_ready_i   ( x_result_ready_i                       )
  );
  // bind unused HWPE_TARGET signals
  assign target_clear = '0; // TODO: a software-accessible clear should be added also to the XIF interface
  assign target.gnt = '1;
  assign target.r_data = '0;
  assign target.r_valid = '0;
  assign target.r_id = '0;
end
else begin : mm_ctrl_intf_gen
  redmule_target_decoder i_target_decoder (
    .clk_i              ( clk_i                                  ),
    .rst_ni             ( rst_ni                                 ),
    .clear_i            ( '0                                     ), // ORed internally with target_clear
    .target_clear_o     ( target_clear                           ),
    .config_ready_i     ( ~config_fifo_full                      ),
    .op_done_i          ( flgs_streamer.z_stream_sink_flags.done ),
    .config_valid_o     ( dec_config_valid                       ),
    .config_o           ( dec_config                             ),
    .target             ( target                                 )
  );
  // bind unused XIF signals
  assign x_issue_resp_o     = '0;
  assign x_issue_ready_o    = '0;
  assign x_register_ready_o = '0;
  assign x_result_o         = '0;
  assign x_result_valid_o   = '0;
end

redmule_config_fifo #(
  .FALL_THROUGH ( 0                ),
  .DEPTH        ( 2                ),
  .dtype        ( redmule_config_t )
) i_config_fifo (
  .clk_i      ( clk_acc           ),
  .rst_ni     ( rst_ni            ),
  .flush_i    ( target_clear      ),
  .testmode_i ( '0                ),
  .full_o     ( config_fifo_full  ),
  .empty_o    ( config_fifo_empty ),
  .usage_o    (                   ),
  .data_i     ( dec_config        ),
  .push_i     ( dec_config_valid  ),
  .data_o     ( dec_config_q      ),
  .pop_i      ( cfg_complete      )
);

/*---------------------------------------------------------------*/
/* |                        Controller                         | */
/*---------------------------------------------------------------*/

redmule_ctrl #(
  .DataW    ( DataW       ),
  .Height   ( Height      ),
  .Width    ( Width       ),
  .PipeRegs ( NumPipeRegs ),
  .FpWidth  ( FpWidth     )
) i_control          (
  .clk_i             ( clk_acc                           ),
  .rst_ni            ( rst_ni                            ),
  .test_mode_i       ( test_mode_i                       ),
  .flgs_streamer_i   ( flgs_streamer                     ),
  .busy_o            ( busy_o                            ),
  .tiler_busy_o      ( tiler_busy                        ),
  .target_clear_i    ( target_clear                      ),
  .clear_o           ( clear                             ),
  .evt_o             ( evt_o                             ),
  .config_i          ( dec_config_q                      ),
  .config_o          ( redmule_config                    ),
  .reg_enable_i      ( reg_enable                        ),
  .fifo_empty_i      ( z_fifo_empty                      ),
  .fifo_ready_i      ( ~z_fifo_full                      ),
  .start_cfg_i       ( ~config_fifo_empty                ),
  .cfg_complete_o    ( cfg_complete                      ),
  .w_loaded_i        ( flgs_scheduler.w_loaded           ),
  .flush_o           ( engine_flush                      ),
  .cntrl_scheduler_o ( cntrl_scheduler                   ),
  .cntrl_flags_o     ( cntrl_flags                       )
);


/*---------------------------------------------------------------*/
/* |                        Local FSM                          | */
/*---------------------------------------------------------------*/
redmule_scheduler #(
  .DataW       ( DataW       ),
  .FpWidth     ( FpWidth     ),
  .Height      ( Height      ),
  .Width       ( Width       ),
  .NumPipeRegs ( NumPipeRegs )
) i_scheduler (
  .clk_i               ( clk_acc             ),
  .rst_ni              ( rst_ni              ),
  .test_mode_i         ( test_mode_i         ),
  .clear_i             ( target_clear        ),
  .x_valid_i           ( x_buffer_fifo.valid ),
  .w_valid_i           ( w_buffer_fifo.valid ),
  .y_valid_i           ( y_buffer_fifo.valid ),
  .z_ready_i           ( z_buffer_q.ready    ),
  .engine_flush_i      ( engine_flush        ),
  .config_i            ( redmule_config      ),
  .config_valid_i      ( cfg_complete        ),
  .flgs_streamer_i     ( flgs_streamer       ),
  .flgs_x_buffer_i     ( x_buffer_flgs       ),
  .flgs_w_buffer_i     ( w_buffer_flgs       ),
  .flgs_z_buffer_i     ( z_buffer_flgs       ),
  .flgs_engine_i       ( flgs_engine         ),
  .cntrl_scheduler_i   ( cntrl_scheduler     ),
  .reg_enable_o        ( reg_enable          ),
  .cntrl_engine_o      ( cntrl_engine        ),
  .cntrl_x_buffer_o    ( x_buffer_ctrl       ),
  .cntrl_w_buffer_o    ( w_buffer_ctrl       ),
  .cntrl_z_buffer_o    ( z_buffer_ctrl       ),
  .flgs_scheduler_o    ( flgs_scheduler      ),
  .sync_i,
  .sync_o
);

`ifndef SYNTHESIS 
always_ff @(posedge clk_acc) begin
  if (cfg_complete) begin
    $display("[redmule] Configuration loaded at %t", $time);
    $display("[redmule]   x_addr = 0x%h",            redmule_config.x_addr);
    $display("[redmule]   w_addr = 0x%h",            redmule_config.w_addr);
    $display("[redmule]   z_addr = 0x%h",            redmule_config.z_addr);
    $display("[redmule]   y_addr = 0x%h",            redmule_config.y_addr);
    $display("[redmule]   m_size = 0x%h",            redmule_config.m_size);
    $display("[redmule]   n_size = 0x%h",            redmule_config.n_size);
    $display("[redmule]   k_size = 0x%h",            redmule_config.k_size);
    $display("[redmule]   y_offs = 0x%h",            redmule_config.y_offs);
    $display("[redmule]   gemm_ops = %s",            redmule_config.gemm_ops.name());
    $display("[redmule]   gemm_input_fmt = %s",      redmule_config.gemm_input_fmt.name());
    $display("[redmule]   gemm_output_fmt = %s",     redmule_config.gemm_output_fmt.name());
    $display("[redmule]   x_cols_iter = 0x%h",       redmule_config.x_cols_iter);
    $display("[redmule]   x_rows_iter = 0x%h",       redmule_config.x_rows_iter);
    $display("[redmule]   w_cols_iter = 0x%h",       redmule_config.w_cols_iter);
    $display("[redmule]   w_rows_iter = 0x%h",       redmule_config.w_rows_iter);
    $display("[redmule]   x_cols_lftovr = 0x%h",     redmule_config.x_cols_lftovr);
    $display("[redmule]   x_rows_lftovr = 0x%h",     redmule_config.x_rows_lftovr);
    $display("[redmule]   w_cols_lftovr = 0x%h",     redmule_config.w_cols_lftovr);
    $display("[redmule]   w_rows_lftovr = 0x%h",     redmule_config.w_rows_lftovr);
    $display("[redmule]   tot_stores = 0x%h",        redmule_config.tot_stores);
    $display("[redmule]   x_d1_stride = 0x%h",       redmule_config.x_d1_stride);
    $display("[redmule]   w_tot_len = 0x%h",         redmule_config.w_tot_len);
    $display("[redmule]   tot_x_read = 0x%h",        redmule_config.tot_x_read);
    $display("[redmule]   w_d0_stride = 0x%h",       redmule_config.w_d0_stride);
    $display("[redmule]   yz_tot_len = 0x%h",        redmule_config.yz_tot_len);
    $display("[redmule]   yz_d0_stride = 0x%h",      redmule_config.yz_d0_stride);
    $display("[redmule]   yz_d2_stride = 0x%h",      redmule_config.yz_d2_stride);
    $display("[redmule]   x_rows_offs = 0x%h",       redmule_config.x_rows_offs);
    $display("[redmule]   x_buffer_slots = 0x%h",    redmule_config.x_buffer_slots);
    $display("[redmule]   x_tot_len = 0x%h",         redmule_config.x_tot_len);
    $display("[redmule]   stage_1_rnd_mode = %s",    redmule_config.stage_1_rnd_mode.name());
    $display("[redmule]   stage_2_rnd_mode = %s",    redmule_config.stage_2_rnd_mode.name());
    $display("[redmule]   stage_1_op = %s",          redmule_config.stage_1_op.name());
    $display("[redmule]   stage_2_op = %s",          redmule_config.stage_2_op.name());
    $display("[redmule]   input_format = %s",        redmule_config.input_format.name());
    $display("[redmule]   computing_format = %s",    redmule_config.computing_format.name());
    $display("[redmule]   gemm_selection = %b",      redmule_config.gemm_selection);
    $display("[redmule]   send_w = %b",              redmule_config.send_w);
    $display("[redmule]   receive_w = %b",           redmule_config.receive_w);
    $display("[redmule]   send_x = %b",              redmule_config.send_x);
    $display("[redmule]   receive_x = %b",           redmule_config.receive_x);
  end
end
`endif // SYNTHESIS

endmodule : redmule_top
