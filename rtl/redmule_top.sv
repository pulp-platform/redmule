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
  parameter int unsigned  ID_WIDTH           = 8                 ,
  parameter int unsigned  N_CORES            = 8                 ,
  parameter int unsigned  DW                 = DATA_W            , // TCDM port dimension (in bits)
  parameter int unsigned  UW                 = 1                 ,
  parameter int unsigned  X_EXT              = 0                 ,
  parameter int unsigned  SysInstWidth       = 32                ,
  parameter int unsigned  SysDataWidth       = 32                ,
  parameter int unsigned  NumContext         = N_CONTEXT         , // Number of sequential jobs for the slave device
  parameter fp_format_e   FpFormat           = FPFORMAT          , // Data format (default is FP16)
  parameter int unsigned  Height             = ARRAY_HEIGHT      , // Number of PEs within a row
  parameter int unsigned  Width              = ARRAY_WIDTH       , // Number of parallel rows
  parameter int unsigned  NumPipeRegs        = PIPE_REGS         , // Number of pipeline registers within each PE
  parameter pipe_config_t PipeConfig         = DISTRIBUTED       ,
  parameter int unsigned  BITW               = fp_width(FpFormat),  // Number of bits for the given format
  parameter hci_size_parameter_t `HCI_SIZE_PARAM(tcdm) = '0
)(
  input  logic                    clk_i      ,
  input  logic                    rst_ni     ,
  input  logic                    test_mode_i,
  output logic                    busy_o     ,
  output logic [N_CORES-1:0][1:0] evt_o      ,
`ifdef TARGET_REDMULE_COMPLEX
  cv32e40x_if_xif.coproc_issue    xif_issue_if_i,
  cv32e40x_if_xif.coproc_result   xif_result_if_o,
  cv32e40x_if_xif.coproc_compressed xif_compressed_if_i,
  cv32e40x_if_xif.coproc_mem        xif_mem_if_o,
`elsif TARGET_REDMULE_HWPE
  // Periph slave port for the controller side
  hwpe_ctrl_intf_periph.slave periph,
`endif
  // TCDM master ports for the memory side
  hci_core_intf.initiator tcdm
);

localparam int unsigned DATAW_ALIGN = DATAW;

logic                       enable, clear;
logic                       reg_enable;
logic                       start_cfg, cfg_complete;

`ifdef TARGET_REDMULE_HWPE
  /* If there is no Xif we directly plug the
     control port into the hwpe-slave device */
  assign start_cfg = ((periph.req) &&
                      (periph.add[7:0] == 'h54) &&
                      (!periph.wen) && (periph.gnt)) ? 1'b1 : 1'b0;

`elsif TARGET_REDMULE_COMPLEX
  hwpe_ctrl_intf_periph #( .ID_WIDTH  (ID_WIDTH) ) periph ( .clk(clk_i) );
  /* If there is the Xif, we pass through the
     instruction decoder and then enter into
     the hwpe slave device */
  logic [SysDataWidth-1:0] cfg_reg;
  logic [SysDataWidth-1:0] sizem, sizen, sizek;
  logic [SysDataWidth-1:0] x_addr, w_addr, y_addr, z_addr;

  redmule_inst_decoder #(
    .SysInstWidth       ( SysInstWidth       ),
    .SysDataWidth       ( SysDataWidth       ),
    .NumRfReadPrts      ( 3                  ) // FIXME: parametric
  ) i_inst_decoder      (
    .clk_i               ( clk_i               ),
    .rst_ni              ( rst_ni              ),
    .clear_i             ( clear               ),
    .xif_issue_if_i      ( xif_issue_if_i      ),
    .xif_result_if_o     ( xif_result_if_o     ),
    .xif_compressed_if_i ( xif_compressed_if_i ),
    .xif_mem_if_o        ( xif_mem_if_o        ),
    .periph              ( periph              ),
    .cfg_complete_i      ( cfg_complete        ),
    .start_cfg_o         ( start_cfg           )
  );

`endif

// Streamer control signals and flags
cntrl_streamer_t cntrl_streamer;
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

// Register file binded from controller to FSM
ctrl_regfile_t reg_file;
flags_fifo_t   w_fifo_flgs;

/*--------------------------------------------------------------*/
/* |                         Streamer                         | */
/*--------------------------------------------------------------*/

// Implementation of the incoming and outgoing streaming interfaces (one for each kind of data)

// X streaming interface + X FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) x_buffer_d         ( .clk( clk_i ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) x_buffer_fifo      ( .clk( clk_i ) );

// W streaming interface + W FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) w_buffer_d         ( .clk( clk_i ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) w_buffer_fifo      ( .clk( clk_i ) );

// Y streaming interface + Y FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) y_buffer_d         ( .clk( clk_i ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) y_buffer_fifo      ( .clk( clk_i ) );

// Z streaming interface + Z FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) z_buffer_q         ( .clk( clk_i ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) z_buffer_fifo      ( .clk( clk_i ) );

`ifdef PACE_ENABLED
// PACE streaming interface + PACE FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) pace_oup_d        ( .clk( clk_i ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) pace_oup_fifo     ( .clk( clk_i ) );
// PACE streaming interface + PACE FIFO interface
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) pace_inp_d        ( .clk( clk_i ) );
hwpe_stream_intf_stream #( .DATA_WIDTH ( DATAW_ALIGN ) ) pace_inp_fifo     ( .clk( clk_i ) );
`endif

// The streamer will present a single master TCDM port used to stream data to and from the memeory.
redmule_streamer #(
  .DW             ( DW                           ),
  .`HCI_SIZE_PARAM(tcdm) ( `HCI_SIZE_PARAM(tcdm) )
) i_streamer      (
  .clk_i           ( clk_i           ),
  .rst_ni          ( rst_ni          ),
  .test_mode_i     ( test_mode_i     ),
  // Controller generated signals
  .enable_i        ( 1'b1            ),
  .clear_i         ( clear           ),
  // Source interfaces for the incoming streams
  .x_stream_o      ( x_buffer_d      ),
  .w_stream_o      ( w_buffer_d      ),
  .y_stream_o      ( y_buffer_d      ),
  // Sink interface for the outgoing stream
  .z_stream_i      ( z_buffer_fifo   ),
`ifdef PACE_ENABLED
  // PACE interface
  .pace_stream_o   ( pace_inp_d      ),         
  .pace_stream_i   ( pace_oup_fifo   ),         
`endif
  // Master TCDM interface ports for the memory side
  .tcdm            ( tcdm            ),
  .ctrl_i          ( cntrl_streamer  ),
  .flags_o         ( flgs_streamer   )
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
`ifdef PACE_ENABLED
  hwpe_stream_fifo #(
    .DATA_WIDTH     ( DATAW_ALIGN   ),
    .FIFO_DEPTH     ( 2             )
  ) i_pace_oup_fifo (
    .clk_i          ( clk_i         ),
    .rst_ni         ( rst_ni        ),
    .clear_i        ( clear         ),
    .flags_o        (               ),
    .push_i         ( pace_oup_d    ),
    .pop_o          ( pace_oup_fifo )
  );

  hwpe_stream_fifo #(
  .DATA_WIDTH     ( DATAW_ALIGN   ),
  .FIFO_DEPTH     ( 4             )
  ) i_pace_inp_fifo (
  .clk_i          ( clk_i         ),
  .rst_ni         ( rst_ni        ),
  .clear_i        ( clear         ),
  .flags_o        (               ),
  .push_i         ( pace_inp_d    ),
  .pop_o          ( pace_inp_fifo )
);
`endif 

// Valid/Ready assignment
assign x_buffer_fifo.ready = x_buffer_ctrl.load;
assign w_buffer_fifo.ready = w_buffer_flgs.w_ready;

assign y_buffer_fifo.ready = z_buffer_flgs.y_ready;

assign z_buffer_q.valid    = z_buffer_flgs.z_valid;

/*----------------------------------------------------------------*/
/* |                          Buffers                           | */
/*----------------------------------------------------------------*/

logic [Width-1:0][Height-1:0][BITW-1:0] x_buffer_q;
redmule_x_buffer #(
  .DW         ( DATAW_ALIGN         ),
  .FpFormat   ( FpFormat            ),
  .Height     ( Height              ),
  .Width      ( Width               )
) i_x_buffer  (
  .clk_i       ( clk_i              ),
  .rst_ni      ( rst_ni             ),
  .clear_i     ( clear              ),
  .ctrl_i      ( x_buffer_ctrl      ),
  .flags_o     ( x_buffer_flgs      ),
  .x_buffer_o  ( x_buffer_q         ),
  .x_buffer_i  ( x_buffer_fifo.data )
);

logic [Height-1:0][BITW-1:0] w_buffer_q;
redmule_w_buffer #(
  .DW         ( DATAW_ALIGN         ),
  .FpFormat   ( FpFormat            ),
  .Height     ( Height              )
) i_w_buffer  (
  .clk_i       ( clk_i              ),
  .rst_ni      ( rst_ni             ),
  .clear_i     ( clear              ),
  .ctrl_i      ( w_buffer_ctrl      ),
  .flags_o     ( w_buffer_flgs      ),
  .w_buffer_o  ( w_buffer_q         ),
  .w_buffer_i  ( w_buffer_fifo.data )
);

logic [Width-1:0][BITW-1:0] z_buffer_d, y_bias_q;
redmule_z_buffer #(
  .DW            ( DATAW_ALIGN        ),
  .FpFormat      ( FpFormat           ),
  .Width         ( Width              )
) i_z_buffer     (
  .clk_i         ( clk_i              ),
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
`ifdef PACE_ENABLED

  logic [Width-1:0][BITW-1:0] pace_engine_inp;
  logic [Width-1:0][BITW-1:0] engine_inp;
  logic                       pace_inp_valid;
  logic                       pace_oup_valid;
  logic                       pace_inp_ready;
  logic                       pace_oup_ready;
  logic [Width-1:0]           pace_inp_ready_array;
  logic [Width-1:0]           pace_oup_valid_array;

  pace_pingpong_inp #(
    .InpDataWidth  ( DATAW_ALIGN ),
    .NumRows       ( Width       ),
    .OupDataWidth  ( BITW        )
  ) i_pace_pingpong_inp (
    .clk_i    ( clk_i                  ),
    .rst_ni   ( rst_ni                 ),
    .clear_i  ( clear                  ),
    .enable_i ( cntrl_engine.pace_mode ),
    .output_o ( pace_engine_inp        ),
    .valid_o  ( pace_inp_valid         ),
    .ready_i  ( pace_inp_ready         ),
    .input_i  ( pace_inp_fifo          )
  );
  assign engine_inp = cntrl_engine.pace_mode ? pace_engine_inp : y_bias_q;


  pace_pingpong_oup #(
    .NumRows        ( Width       ),
    .InpDataWidth   ( BITW        )
  ) i_pace_pingpong_oup (
    .clk_i    ( clk_i                   ),
    .rst_ni   ( rst_ni                  ),
    .clear_i  ( clear                   ),
    .enable_i ( cntrl_engine.pace_mode  ),
    .input_i  ( z_buffer_d              ),
    .valid_i  ( pace_oup_valid          ), 
    .ready_o  ( pace_oup_ready          ),
    .output_o ( pace_oup_d              )
  );
`endif
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
`ifdef PACE_ENABLED
  assign in_valid         = cntrl_engine.pace_mode ? pace_inp_valid : cntrl_engine.in_valid;
`else 
  assign in_valid         = cntrl_engine.in_valid;
`endif 
assign flush            = cntrl_engine.flush | clear;
`ifdef PACE_ENABLED
  assign out_ready        = cntrl_engine.pace_mode ?  pace_oup_ready : cntrl_engine.out_ready;
`else 
  assign out_ready        = cntrl_engine.out_ready;
`endif 
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

`ifdef PACE_ENABLED
  // Ready array assignment
  generate 
    for (genvar w = 0; w < Width; w++) begin
      assign pace_inp_ready_array[w] = in_ready[w][0];
      assign pace_oup_valid_array[w] = out_valid[w][Height-1];
    end
  endgenerate
  assign pace_inp_ready = (&pace_inp_ready_array) && cntrl_engine.pace_mode;
  assign pace_oup_valid = (&pace_oup_valid_array) && cntrl_engine.pace_mode;
`endif 
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
`ifdef PACE_ENABLED
  .y_bias_i           ( engine_inp       ),
`else 
  .y_bias_i           ( y_bias_q         ),
`endif 
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

redmule_memory_scheduler #(
  .DW (DATAW_ALIGN),
  .W  (Width),
  .H  (Height)
) i_memory_scheduler (
  .clk_i             ( clk_i               ),
  .rst_ni            ( rst_ni              ),
  .clear_i           ( clear               ),
  .reg_file_i        ( reg_file            ),
  .flgs_streamer_i   ( flgs_streamer       ),
  .cntrl_scheduler_i ( cntrl_scheduler     ),
  .cntrl_streamer_o  ( cntrl_streamer      )
);



/*---------------------------------------------------------------*/
/* |                        Controller                         | */
/*---------------------------------------------------------------*/

redmule_ctrl        #(
  .N_CORES           ( N_CORES                 ),
  .IO_REGS           ( REDMULE_REGS            ),
  .ID_WIDTH          ( ID_WIDTH                ),
  .N_CONTEXT         ( NumContext              ),
  .SysDataWidth      ( SysDataWidth            ),
  .Height            ( Height                  ),
  .Width             ( Width                   ),
  .NumPipeRegs       ( NumPipeRegs             )
) i_control          (
  .clk_i             ( clk_i                   ),
  .rst_ni            ( rst_ni                  ),
  .test_mode_i       ( test_mode_i             ),
  .flgs_streamer_i   ( flgs_streamer           ),
  .busy_o            ( busy_o                  ),
  .clear_o           ( clear                   ),
  .evt_o             ( evt_o                   ),
  .reg_file_o        ( reg_file                ),
  .reg_enable_i      ( reg_enable              ),
  .start_cfg_i       ( start_cfg               ),
  .cfg_complete_o    ( cfg_complete            ),
  .w_loaded_i        ( flgs_scheduler.w_loaded ),
  .flush_o           ( engine_flush            ),
  .cntrl_scheduler_o ( cntrl_scheduler         ),
  .periph            ( periph                  )
);


/*---------------------------------------------------------------*/
/* |                        Local FSM                          | */
/*---------------------------------------------------------------*/
redmule_scheduler #(
  .Height      ( Height         ),
  .Width       ( Width          ),
  .NumPipeRegs ( NumPipeRegs    )
) i_scheduler (
  .clk_i             ( clk_i               ),
  .rst_ni            ( rst_ni              ),
  .test_mode_i       ( test_mode_i         ),
  .clear_i           ( clear               ),
  .x_valid_i         ( x_buffer_fifo.valid ),
  .w_valid_i         ( w_buffer_fifo.valid ),
  .y_valid_i         ( y_buffer_fifo.valid ),
  .z_ready_i         ( z_buffer_q.ready    ),
  .engine_flush_i    ( engine_flush        ),
  .reg_file_i        ( reg_file            ),
  .flgs_streamer_i   ( flgs_streamer       ),
  .flgs_x_buffer_i   ( x_buffer_flgs       ),
  .flgs_w_buffer_i   ( w_buffer_flgs       ),
  .flgs_z_buffer_i   ( z_buffer_flgs       ),
  .flgs_engine_i     ( flgs_engine         ),
  .cntrl_scheduler_i ( cntrl_scheduler     ),
  .reg_enable_o      ( reg_enable          ),
  .cntrl_engine_o    ( cntrl_engine        ),
  .cntrl_x_buffer_o  ( x_buffer_ctrl       ),
  .cntrl_w_buffer_o  ( w_buffer_ctrl       ),
  .cntrl_z_buffer_o  ( z_buffer_ctrl       ),
  .flgs_scheduler_o  ( flgs_scheduler      )
);

endmodule : redmule_top
