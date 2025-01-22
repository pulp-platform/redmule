// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
// Andrea Belano <andrea.belano2@unibo.it>
//

module redmule_w_buffer
  import fpnew_pkg::*;
  import redmule_pkg::*;
#(
  parameter int unsigned  DW        = 288               ,
  parameter fp_format_e   FpFormat  = FP16              ,
  parameter int unsigned  Height    = ARRAY_HEIGHT      , // Number of PEs per row
  parameter int unsigned  N_REGS    = PIPE_REGS         , // Number of registers per PE
  parameter int unsigned  GID_WIDTH = GROUP_ID_WIDTH    ,
  localparam int unsigned BITW      = fp_width(FpFormat), // Number of bits for the given format
  localparam int unsigned H         = Height            ,
  localparam int unsigned D         = DW/BITW           
)(
  input  logic                             clk_i     ,
  input  logic                             rst_ni    ,
  input  logic                             clear_i   ,
  input  w_buffer_ctrl_t                   ctrl_i    ,
  output w_buffer_flgs_t                   flags_o   ,
  output logic           [H-1:0][BITW-1:0] w_buffer_o,
  input  logic                    [DW-1:0] w_buffer_i,  //Normally the rows of the W matrix; in quantization mode, the vectors of scales

  input  logic             /*PLACEHOLDER*/ qw_i      ,
  input  logic             /*PLACEHOLDER*/ zeros_i   ,

  input  logic     [$clog2(GID_WIDTH)-1:0] next_gidx_i   //Tentative name
);

localparam int unsigned S       = (D + N_REGS)/(N_REGS + 1);
localparam int unsigned S_ADDR_W = $clog2(N_REGS + 1);
localparam int unsigned S_DATA_W = (N_REGS + 1) * BITW;

logic [$clog2(H):0]            w_row;
logic [$clog2(H):0]            count_limit;
logic [$clog2(D):0]            depth;
logic [H-1:0][H-1:0][BITW-1:0] w_buffer_q;

logic [S_ADDR_W-1:0]           el_addr_d, el_addr_q;
logic [H-1:0][$clog2(S)-1:0]   sec_addr_d, sec_addr_q;

logic [D-1:0][BITW-1:0]        w_data;

logic [H-1:0][$clog2(GID_WIDTH)-1:0]   cache_r_id_d, cache_r_id_q, cache_w_id_d, cache_w_id_q;
logic [H-1:0]                  cache_r_id_valid_d, cache_r_id_valid_q, cache_w_id_valid_d, cache_w_id_valid_q;

logic [H-1:0][$clog2(H)-1:0]   buffer_r_addr_d, buffer_r_addr_q;
logic [H-1:0]                  buffer_r_addr_valid_d, buffer_r_addr_valid_q;

logic [H-1:0][$clog2(D/(PIPE_REGS+1))-1:0]   usage_counter_q;
logic [$clog2(H)-1:0]                        evict_pointer;

logic gidx_present;

for (genvar d = 0; d < D; d++) begin : zero_padding
  assign w_data[d] = (d < depth && w_row < count_limit) ? w_buffer_i[(d+1)*BITW-1:d*BITW] : '0;
end

//FIXME THIS IS SUBOPTIMAL!
for (genvar r = 0; r < H; r++) begin : gen_rows
  for (genvar s = 0; s < S; s++) begin : gen_sections
    redmule_fifo_scm #(
      .ADDR_WIDTH ( S_ADDR_W    ),
      .DATA_WIDTH ( BITW        ),
      .N_INPUTS   ( N_REGS + 1  ) 
    ) i_section (
      .clk          ( clk_i                                                                                                                ),
      .rst_n        ( rst_ni                                                                                                               ),
      .ReadEnable   ( (ctrl_i.dequant ? buffer_r_addr_d[sec_addr_d[s]] == r && buffer_r_addr_valid_d[sec_addr_d[s]] : sec_addr_d[r] == s) && ctrl_i.shift ),
      .ReadAddr     ( el_addr_d                                                                                                            ),
      .ReadData     ( w_buffer_q[r][s]                                                                                                     ),
      .WriteEnable  ( (ctrl_i.dequant ? evict_pointer == r && ~gidx_present : w_row == r) && ctrl_i.load                                   ),
      .WriteAddr    ( '0                                                                                                                   ),
      .WriteData    ( w_data[(s+1)*(N_REGS+1)-1:s*(N_REGS+1)]                                                                              )
    );
  end

  assign w_buffer_o[r] = ctrl_i.dequant ? w_buffer_q[buffer_r_addr_q[r]][sec_addr_q[r]] : w_buffer_q[r][sec_addr_q[r]];
end 

// Read side
for (genvar h = 0; h < H; h++) begin : gen_r_id_registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      cache_r_id_q[h] <= '0;
    end else begin
      if (clear_i) begin
        cache_r_id_q[h]       <= '0;
        cache_r_id_valid_q[h] <= '0;
      end else if (w_row == h && ctrl_i.load && ctrl_i.dequant) begin   // This is loaded at the same time as the W row
        cache_r_id_q[h]       <= next_gidx_i;
        cache_r_id_valid_q[h] <= '1;
      end
    end
  end

  assign cache_r_id_d[h]       = (w_row == h && ctrl_i.load && ctrl_i.dequant) ? next_gidx_i : cache_r_id_q[h];
  assign cache_r_id_valid_d[h] = (w_row == h && ctrl_i.load && ctrl_i.dequant) ? '1 : cache_r_id_valid_q[h];
end

always_comb begin : buffer_r_addr_assignment
  buffer_r_addr_q       = '0;
  buffer_r_addr_d       = '0;
  buffer_r_addr_valid_q = '0;
  buffer_r_addr_valid_d = '0;

  for (int h = 0; h < H; h++) begin
    for (int hh = 0; hh < H; hh++) begin
      if (cache_r_id_q[h] == cache_w_id_q[hh]) begin
        buffer_r_addr_q[h]       = hh;
        buffer_r_addr_valid_q[h] = cache_w_id_valid_q[hh] && cache_r_id_valid_q[h];
        break;
      end
    end
  end

  for (int h = 0; h < H; h++) begin
    for (int hh = 0; hh < H; hh++) begin
      if (cache_r_id_d[h] == cache_w_id_d[hh]) begin
        buffer_r_addr_d[h]       = hh;
        buffer_r_addr_valid_d[h] = cache_w_id_valid_d[hh] && cache_r_id_valid_d[h];
        break;
      end
    end
  end
end

// Write side
for (genvar h = 0; h < H; h++) begin : gen_w_id_registers
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      cache_w_id_q[h]       <= '0;
      cache_w_id_valid_q[h] <= '0;
    end else begin
      if (clear_i) begin
        cache_w_id_q[h]       <= '0;
        cache_w_id_valid_q[h] <= '0;
      end else if (evict_pointer == h && ctrl_i.load && ctrl_i.dequant && ~gidx_present) begin   // This is loaded at the same time as the W row //FIXME (fixed?)
        cache_w_id_q[h]       <= next_gidx_i;
        cache_w_id_valid_q[h] <= '1;
      end
    end
  end

  assign cache_w_id_d[h]       = (evict_pointer == h && ctrl_i.load && ctrl_i.dequant && ~gidx_present) ? next_gidx_i : cache_w_id_q[h];
  assign cache_w_id_valid_d[h] = (evict_pointer == h && ctrl_i.load && ctrl_i.dequant && ~gidx_present) ? '1 : cache_w_id_valid_q[h];
end

// Each row of the buffer has a counter that 
// It resets to D/(PIPE_REGS+1) each time the vector is requested
// FIXME leftovers ----
for (genvar h = 0; h < H; h++) begin : gen_usage_counters
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if(~rst_ni) begin
      usage_counter_q[h] <= '0;
    end else begin
      if (clear_i)
        usage_counter_q[h] <= '0;
      else if (ctrl_i.dequant && evict_pointer == h && ctrl_i.load)
        usage_counter_q[h] <= D/(PIPE_REGS+1)-1;
      else if (ctrl_i.dequant && el_addr_q == N_REGS && usage_counter_q[h] != 0 && ctrl_i.shift)
        usage_counter_q[h] <= usage_counter_q[h] - 1;
    end
  end
end

always_comb begin : evict_pointer_assignment
  evict_pointer = '0;

  for (int h = 0; h < H; h++) begin
    if (usage_counter_q[h] == '0) begin
      evict_pointer = h;
      break;
    end
  end
end

always_comb begin : gidx_present_assignment
  gidx_present = '0;

  for (int h = 0; h < H; h++) begin
    if (cache_w_id_q[h] == next_gidx_i && cache_w_id_valid_q[h]) begin
      gidx_present = '1;
      break;
    end
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : element_counter
  if(~rst_ni) begin
    el_addr_q <= N_REGS;
  end else begin
    if (clear_i)
      el_addr_q <= N_REGS;
    else if (ctrl_i.shift)
      el_addr_q <= el_addr_d;
  end
end

always_ff @(posedge clk_i or negedge rst_ni) begin : section_counter
  if(~rst_ni) begin
    sec_addr_q[0] <= S-1;
  end else begin
    if (clear_i)
      sec_addr_q[0] <= S-1;
    else if (ctrl_i.shift)
      sec_addr_q[0] <= sec_addr_d[0];
  end
end

assign el_addr_d = (el_addr_q == N_REGS) ? '0 : el_addr_q + 1;
assign sec_addr_d[0] = (el_addr_q == N_REGS) ? (sec_addr_q[0] == (S-1) ? '0 : sec_addr_q[0] + 1) : sec_addr_q[0];

for (genvar r = 1; r < H; r++) begin : assign_sec_addr
  assign sec_addr_d[r] = sec_addr_d[0] >= r ? sec_addr_d[0] - r : H - (r - sec_addr_d[0]);
  assign sec_addr_q[r] = sec_addr_q[0] >= r ? sec_addr_q[0] - r : H - (r - sec_addr_q[0]);
end

// Counter to track the number of shifts per row
always_ff @(posedge clk_i or negedge rst_ni) begin : row_load_counter
  if(~rst_ni) begin
    w_row <= '0;
  end else begin
    if (clear_i || w_row == H )
      w_row <= '0;
    else if (ctrl_i.load)
      w_row <= w_row + 1;
    else
      w_row <= w_row;
  end
end

assign depth       = (ctrl_i.cols_lftovr == '0) ? D : ctrl_i.cols_lftovr;
assign count_limit = (ctrl_i.rows_lftovr != '0) ? ctrl_i.rows_lftovr : Height;

endmodule : redmule_w_buffer
