// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Andrea Belano <andrea.belano2@unibo.it>
//

module redmule_z_buffer_scm
  import redmule_pkg::*;
#(
  parameter int unsigned WORD_SIZE   = 32,
  parameter int unsigned ROWS        = 1 ,
  parameter int unsigned COLS        = 1 ,
  parameter int unsigned USE_LATCHES = LATCH_BUFFERS
) (
  input  logic                           clk_i            ,
  input  logic                           rst_ni           ,
  input  logic                           clear_i          ,
  input  logic                           row_write_en_i   ,
  input  logic                           col_write_en_i   ,
  input  logic [$clog2(ROWS)-1:0]        row_write_addr_i ,
  input  logic [$clog2(COLS)-1:0]        col_write_addr_i ,
  input  logic [COLS-1:0][WORD_SIZE-1:0] row_wdata_i      ,
  input  logic [ROWS-1:0][WORD_SIZE-1:0] col_wdata_i      ,
  input  logic                           col_read_en_i    ,
  input  logic                           row_read_en_i    ,
  input  logic [$clog2(COLS)-1:0]        col_read_addr_i  ,
  input  logic [$clog2(ROWS)-1:0]        row_read_addr_i  ,
  output logic [ROWS-1:0][WORD_SIZE-1:0] col_rdata_o      ,
  output logic [COLS-1:0][WORD_SIZE-1:0] row_rdata_o
);
  logic [ROWS-1:0][COLS-1:0][WORD_SIZE-1:0] buffer_q;
  logic [COLS-1:0][WORD_SIZE-1:0]           row_wdata_q;
  logic [ROWS-1:0][WORD_SIZE-1:0]           col_wdata_q;
  logic                                     row_write_en_q;
  logic [$clog2(COLS)-1:0]                  col_read_addr_q;
  logic [$clog2(ROWS)-1:0]                  row_read_addr_q;

  logic [ROWS-1:0][COLS-1:0]                clk_w;

  always_ff @(posedge clk_i or negedge rst_ni) begin : sample_col_raddr
    if(~rst_ni) begin
      col_read_addr_q <= '0;
    end else begin
      if (clear_i) begin
        col_read_addr_q <= '0;
      end else if (col_read_en_i) begin
        col_read_addr_q <= col_read_addr_i;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : sample_row_raddr
    if(~rst_ni) begin
      row_read_addr_q <= '0;
    end else begin
      if (clear_i) begin
        row_read_addr_q <= '0;
      end else if (row_read_en_i) begin
        row_read_addr_q <= row_read_addr_i;
      end
    end
  end

  for (genvar r = 0; r < ROWS; r++) begin : gen_output_columns_assignment
    assign col_rdata_o[r] = buffer_q[r][col_read_addr_q];
  end

  for (genvar c = 0; c < COLS; c++) begin : gen_output_rows_assignment
    assign row_rdata_o[c] = buffer_q[row_read_addr_q][c];
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : sample_row_wdata
    if(~rst_ni) begin
      row_wdata_q <= '0;
    end else begin
      if (clear_i) begin
        row_wdata_q <= '0;
      end else if (row_write_en_i) begin
        row_wdata_q <= row_wdata_i;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : sample_col_wdata
    if(~rst_ni) begin
      col_wdata_q <= '0;
    end else begin
      if (clear_i) begin
        col_wdata_q <= '0;
      end if (col_write_en_i) begin
        col_wdata_q <= col_wdata_i;
      end
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : sample_row_write_enable
    if(~rst_ni) begin
      row_write_en_q <= '0;
    end else begin
      if (clear_i) begin
        row_write_en_q <= '0;
      end else if (col_write_en_i || row_write_en_i) begin
        row_write_en_q <= row_write_en_i;
      end
    end
  end

  if (USE_LATCHES) begin : gen_latches
    for (genvar r = 0; r < ROWS; r++) begin : gen_write_clock_gates
      for (genvar c = 0; c < COLS; c++) begin : gen_col_write_clock_gates
        tc_clk_gating i_rows_cg (
          .clk_i     ( clk_i                                                                                         ),
          .en_i      ( row_write_addr_i == r && row_write_en_i || col_write_addr_i == c && col_write_en_i || clear_i ),
          .test_en_i ( '0                                                                                            ),
          .clk_o     ( clk_w[r][c]                                                                                   )
        );
      end
    end

    for (genvar r = 0; r < ROWS; r++) begin : gen_rows
      for (genvar c = 0; c < COLS; c++) begin : gen_cols
        always_latch begin : wdata
          if (clk_w[r][c]) begin
            buffer_q[r][c] = row_write_en_q ? row_wdata_q[c] : col_wdata_q[r];
          end
        end
      end
    end
  end else begin : gen_flip_flops
    for (genvar r = 0; r < ROWS; r++) begin : gen_rows
      for (genvar c = 0; c < COLS; c++) begin : gen_cols
        always_ff @(posedge clk_i or negedge rst_ni) begin : wdata
          if (~rst_ni) begin
            buffer_q[r][c] <= '0;
          end else begin
            if (clear_i) begin
              buffer_q[r][c] <= '0;
            end else if (row_write_addr_i == r && row_write_en_i || col_write_addr_i == c && col_write_en_i) begin
              buffer_q[r][c] <= row_write_en_i ? row_wdata_i[c] : col_wdata_i[r];
            end
          end
        end
      end
    end
  end

endmodule : redmule_z_buffer_scm
