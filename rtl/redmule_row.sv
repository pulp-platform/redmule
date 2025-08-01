// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
// Arpan Suravi Prasad <prasadar@iis.ee.ethz.ch>

module redmule_row
  import fpnew_pkg::*;
`ifdef PACE_ENABLED
  import redmule_pkg::*;
`endif
#(
  parameter fpnew_pkg::fp_format_e    FpFormat    = fpnew_pkg::FP16,
  parameter int unsigned              Height      = 4,                             // Number of PEs per row
  parameter int unsigned              NumPipeRegs = 2,
  parameter fpnew_pkg::pipe_config_t  PipeConfig  = fpnew_pkg::DISTRIBUTED,
  parameter type                      TagType     = logic,
  parameter type                      AuxType     = logic,
  localparam int unsigned             BITW        = fpnew_pkg::fp_width(FpFormat), // Number of bits for the given format
  localparam int unsigned             H           = Height
)(
  input  logic                                      clk_i             ,
  input  logic                                      rst_ni            ,
  // Input Elements
  input  logic                    [H-1:0][BITW-1:0] x_input_i         ,
  input  logic                    [H-1:0][BITW-1:0] w_input_i         ,
  input  logic                           [BITW-1:0] y_bias_i          ,
  // Output Result
  output logic                           [BITW-1:0] z_output_o        ,
`ifdef PACE_ENABLED
  input   logic                                     pace_mode_i       ,
  output  logic                   [H-1:0][PIDW-1:0] pace_part_id_o    , // Partition Index for selecting right x from x_buffer
`endif
  // fpnew_fma Input Signals
  input  logic                    [2:0]             fma_is_boxed_i    ,
  input  logic                    [1:0]             noncomp_is_boxed_i,
  input  fpnew_pkg::roundmode_e                     stage1_rnd_i      ,
  input  fpnew_pkg::roundmode_e                     stage2_rnd_i      ,
  input  fpnew_pkg::operation_e                     op1_i             ,
  input  fpnew_pkg::operation_e                     op2_i             ,
  input  logic                                      op_mod_i          ,
  input  TagType                                    tag_i             ,
  input  AuxType                                    aux_i             ,
  // fpnew_fma Input Handshake
  input  logic                                      in_valid_i     ,
  output logic                    [H-1:0]           in_ready_o     ,
  input  logic                                      reg_enable_i   ,
  input  logic                                      flush_i        ,
  // fpnew_fma Output signals
  output fpnew_pkg::status_t      [H-1:0]           status_o       ,
  output logic                    [H-1:0]           extension_bit_o,
  output fpnew_pkg::classmask_e   [H-1:0]           class_mask_o   ,
  output logic                    [H-1:0]           is_class_o     ,
  output TagType                  [H-1:0]           tag_o          ,
  output AuxType                  [H-1:0]           aux_o          ,
  // fpnew_fma Output handshake
  output logic                    [H-1:0]           out_valid_o    ,
  input  logic                                      out_ready_i    ,
  // fpnew_fma Indication of valid data in flight
  output logic                    [H-1:0]           busy_o
);

// Local signals for operands assign: elemnts 0 and 1 are addressed to multiplication,
// element 2 is destined to accumulation.
logic [H-1:0] [2:0][BITW-1:0]       input_operands;
logic [H-1:0]      [BITW-1:0]       y_bias_int    ,
                                    partial_result;
logic              [BITW-1:0]       result;

// Signals for intermediate registers
logic [H-1:0]      [BITW-1:0]       output_q;

`ifdef PACE_ENABLED
  logic [H-1:0] [2:0][BITW-1:0]       pace_input_operands;
  fpnew_pkg::operation_e [H-1:0] op1_row, op2_row;

generate
  for(genvar h=0; h<H; h++) begin
    if(h <= PACE_PART_BST_STAGES) begin
      assign op1_row[h] = pace_mode_i ? fpnew_pkg::SGNJ : op1_i;
      assign op2_row[h] = pace_mode_i ? fpnew_pkg::SGNJ : op2_i;
    end else begin
      assign op1_row[h] = pace_mode_i ? fpnew_pkg::FMADD : op1_i;
      assign op2_row[h] = pace_mode_i ? fpnew_pkg::MINMAX : op2_i;
    end
  end
endgenerate

`endif
`ifdef PACE_ENABLED

  logic [H-1:0][2*BITW+PIDW:0]      tag_in, tag_out, tag_out_reg;
  fpnew_pkg::roundmode_e   [H-1:0]  stage1_rnd_mode, stage2_rnd_mode;
  logic [H-1:0]                     is_greater, is_greater_reg;
  logic [H-1:0]                     pace_inp_valid, pace_oup_valid,
                                    pace_inp_valid_reg, pace_oup_valid_reg;
  logic [H-1:0]                     pace_inp_ready, pace_oup_ready,
                                    pace_inp_ready_reg, pace_oup_ready_reg;

`endif

// Generate PEs
generate
  for (genvar index = 0; index < H; index++) begin : gen_computing_element
    assign input_operands [index][0] = x_input_i [index];
    assign input_operands [index][1] = w_input_i [index];
    if (index > 0)
      assign input_operands [index][2] = output_q [index-1];
    else
      assign input_operands [index][2] = y_bias_i;
`ifdef PACE_ENABLED

  if (index == 0) begin
    assign pace_inp_valid[index] = in_valid_i;
    assign out_valid_o[index]    = pace_oup_valid_reg[index];
  end else begin
    assign pace_inp_valid[index] = pace_mode_i ? pace_oup_valid_reg[index-1] : in_valid_i;
    assign out_valid_o[index]    = pace_oup_valid_reg[index];
  end

  assign  in_ready_o[index] = pace_inp_ready[index];

  if(index == (H-1)) begin
    assign pace_oup_ready[index] = pace_mode_i ? pace_inp_ready_reg[index] : out_ready_i;
  end else begin
    assign pace_oup_ready[index] = pace_mode_i ? pace_inp_ready_reg[index] : out_ready_i;
  end

  localparam int unsigned TBITW = (index == 0) ? 0 :
                                  (index < PACE_PART_BST_STAGES) ? index - 1 :
                                  (index == PACE_PART_BST_STAGES) ? PIDW + 2*BITW :
                                  PIDW + BITW;
  if(index <= PACE_PART_BST_STAGES) begin : gen_rnd_mode
      assign stage1_rnd_mode[index] = pace_mode_i ? fpnew_pkg::RUP : stage1_rnd_i;
      assign stage2_rnd_mode[index] = pace_mode_i ? fpnew_pkg::RUP : stage2_rnd_i;
    end : gen_rnd_mode else begin
      assign stage1_rnd_mode[index] = stage1_rnd_i;
      assign stage2_rnd_mode[index] = stage2_rnd_i;
    end
    if(index == 0) begin
      assign pace_input_operands[index][0] =  pace_mode_i ? input_operands[index][2] : input_operands[index][0];
      assign pace_input_operands[index][1] =  pace_mode_i ? input_operands[index][0] : input_operands[index][1];
      assign pace_input_operands[index][2] =  input_operands[index][2];
    end else if (index < PACE_PART_BST_STAGES) begin
      assign pace_input_operands[index][0] =  pace_mode_i ? output_q[index-1] : input_operands[index][0];
      assign pace_input_operands[index][1] =  pace_mode_i ? input_operands[index][0] : input_operands[index][1];
      assign pace_input_operands[index][2] =  input_operands[index][2];
    end else if (index == PACE_PART_BST_STAGES) begin
      assign pace_input_operands[index][0] =  pace_mode_i ? output_q[index-1] : input_operands[index][0];
      assign pace_input_operands[index][2] =  input_operands[index][2];
      assign pace_input_operands[index][1] =  input_operands[index][1];
    end else if (index == PACE_PART_BST_STAGES + 1) begin
      // ax + b
      assign pace_input_operands[index][0] =  pace_mode_i ? tag_out_reg[index-1][PIDW+BITW-1:PIDW] : input_operands[index][0]; //a
      assign pace_input_operands[index][2] =  pace_mode_i ? input_operands[index][0]   : input_operands[index][2]; //b
      assign pace_input_operands[index][1] =  pace_mode_i ? output_q[index-1] : input_operands[index][1]; // x
    end else if (index <= PACE_PART_BST_STAGES + PACE_NPOLY) begin
      // pres * x + b
      assign pace_input_operands[index][0] =  pace_mode_i ? output_q[index-1] : input_operands[index][0]; //pres
      assign pace_input_operands[index][1] =  pace_mode_i ? tag_out_reg[index-1][BITW+PIDW-1:PIDW] : input_operands[index][1]; //x
      assign pace_input_operands[index][2] =  pace_mode_i ? input_operands[index][0] : input_operands[index][2]; // b
    end else begin
      assign pace_input_operands[index][0] =  pace_mode_i ? output_q[index-1] : input_operands[index][0]; //pres
      assign pace_input_operands[index][1] =  pace_mode_i ? 16'h3c00 : input_operands[index][1]; //x
      assign pace_input_operands[index][2] =  pace_mode_i ? input_operands[index][0] : input_operands[index][2]; // b
    end


  if (index == 0) begin
    assign tag_in[index]      = 1'b0;
    assign pace_part_id_o[index] = {PIDW{1'b0}};

  end else if (index > 0 && index < PACE_PART_BST_STAGES) begin
    if (index == 1) begin
      assign tag_in[index][0] = ~pace_mode_i ? '0 : is_greater_reg[index-1];
    end else begin
      assign tag_in[index]    = ~pace_mode_i ? '0 : {tag_out_reg[index-1][TBITW-1:0], is_greater_reg[index-1]};
    end

    assign pace_part_id_o[index] = ~pace_mode_i ? '0 : {
                                        {(PIDW - index){1'b0}},  // zero padding
                                        tag_in[index][index-1:0] // tag bits
                                      };

  end else begin
    if (index == PACE_PART_BST_STAGES) begin
      assign tag_in[index]         = ~pace_mode_i ? '0 : {input_operands [index][0], {tag_out_reg[index-1][PIDW-2:0], is_greater_reg[index-1]}};
      assign pace_part_id_o[index] = ~pace_mode_i ? '0 : {tag_out_reg[index-1][PIDW-2:0], is_greater_reg[index-1]};
    end else begin
      if(index == PACE_PART_BST_STAGES + 1) begin
          assign tag_in[index]     = ~pace_mode_i ? '0 : {output_q[index-1], tag_out_reg[index-1][PIDW-1:0]};
      end else begin
        assign tag_in[index]       = ~pace_mode_i ? '0 : tag_out_reg[index-1][TBITW-1:0];
      end
      assign pace_part_id_o[index] = ~pace_mode_i ? '0 : {tag_out_reg[index-1][PIDW-1:0]};

    end

  end

  typedef logic [TBITW:0] PACETagType;

`endif


    redmule_ce         #(
    .FpFormat           ( FpFormat    ),
    .NumPipeRegs        ( NumPipeRegs ),
`ifdef PACE_ENABLED
    .TagType            ( PACETagType ),
`endif
    .PipeConfig         ( PipeConfig  ),
    .Stallable          ( 1'b1        )
    ) i_computing_element (
      .clk_i              ( clk_i                     ),
      .rst_ni             ( rst_ni                    ),
`ifdef PACE_ENABLED
      .x_input_i          ( pace_input_operands [index][0] ),
      .w_input_i          ( pace_input_operands [index][1] ),
      .y_bias_i           ( pace_input_operands [index][2] ),
      .is_greater_o       ( is_greater     [index]    ),
      .pace_mode_i        ( pace_mode_i               ),
`else
      .x_input_i          ( input_operands [index][0] ),
      .w_input_i          ( input_operands [index][1] ),
      .y_bias_i           ( input_operands [index][2] ),
`endif
      .fma_is_boxed_i     ( fma_is_boxed_i            ),
      .noncomp_is_boxed_i ( noncomp_is_boxed_i        ),
`ifdef PACE_ENABLED
      .stage1_rnd_i       ( stage1_rnd_mode[index]    ),
      .stage2_rnd_i       ( stage2_rnd_mode[index]    ),
      .op1_i              ( op1_row     [index]       ),
      .op2_i              ( op2_row     [index]       ),
      .tag_i              ( tag_in  [index][TBITW:0]  ),
      .in_valid_i         ( pace_inp_valid[index]     ),
      .in_ready_o         ( pace_inp_ready[index]     ),
`else
      .stage1_rnd_i       ( stage1_rnd_i              ),
      .stage2_rnd_i       ( stage2_rnd_i              ),
      .op1_i              ( op1_i                     ),
      .op2_i              ( op2_i                     ),
      .tag_i              ( tag_i                     ),
      .in_valid_i         ( in_valid_i                ),
      .in_ready_o         ( in_ready_o      [index]   ),
`endif
      .op_mod_i           ( op_mod_i                  ),
      .aux_i              ( aux_i                     ),
      .reg_enable_i       ( reg_enable_i              ),
      .flush_i            ( flush_i                   ),
      .z_output_o         ( partial_result  [index]   ),
      .status_o           ( status_o        [index]   ),
      .extension_bit_o    ( extension_bit_o [index]   ),
      .class_mask_o       ( class_mask_o    [index]   ),
      .is_class_o         ( is_class_o      [index]   ),
`ifdef PACE_ENABLED
      .tag_o              ( tag_out  [index][TBITW:0] ),
      .out_valid_o        ( pace_oup_valid  [index]   ),
      .out_ready_i        ( pace_oup_ready  [index]   ),
`else
      .tag_o              ( tag_o           [index]   ),
      .out_valid_o        ( out_valid_o     [index]   ),
      .out_ready_i        ( out_ready_i               ),
`endif
      .aux_o              ( aux_o           [index]   ),
      .busy_o             ( busy_o          [index]   )
    );

  `ifdef PACE_ENABLED
    spill_register_flushable #(
      .T      ( logic [TBITW+BITW+1:0] ),
      .Bypass ( 1'b0                   )
    ) i_spill_reg (
      .clk_i,
      .rst_ni,
      .valid_i ( pace_mode_i ? pace_oup_valid[index] : reg_enable_i                        ),
      .flush_i ( flush_i                                                                   ),
      .ready_o ( pace_inp_ready_reg[index]                                                 ),
      .data_i  ( {is_greater[index], tag_out[index][TBITW:0], partial_result[index]}       ),
      .valid_o ( pace_oup_valid_reg[index]                                                 ),
      .ready_i ( pace_mode_i ? (index == H-1 ? out_ready_i : pace_inp_ready[index+1]) : '1 ),
      .data_o  ( {is_greater_reg[index], tag_out_reg[index][TBITW:0], output_q[index]}     )
    );
  `else
    always_ff @(posedge clk_i or negedge rst_ni) begin : intermediate_output_register
      if(~rst_ni) begin
        output_q[index] <= '0;
      end else begin
        if (flush_i)
          output_q [index] <= '0;
        else if (reg_enable_i)
          output_q [index] <= partial_result [index];
      end
    end
  `endif
  end
endgenerate

assign z_output_o = output_q [H-1];

endmodule : redmule_row
