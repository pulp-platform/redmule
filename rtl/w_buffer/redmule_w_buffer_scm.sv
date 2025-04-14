// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Andrea Belano <andrea.belano2@unibo.it>
//

module redmule_w_buffer_scm #(
  parameter int unsigned WORD_SIZE   = 32,
  parameter int unsigned ROWS        = 1 ,
  parameter int unsigned COLS        = 1 ,
  parameter int unsigned ELMS        = 1 ,
  parameter int unsigned USE_LATCHES = LATCH_BUFFERS
) (
  input  logic                                                        clk_i            ,
  input  logic                                                        rst_ni           ,
  input  logic                                                        clear_i          ,
  input  logic                                                        write_en_i       ,
  input  logic [$clog2(ROWS)-1:0]                                     write_addr_i     ,
  input  logic [COLS-1:0][ELMS-1:0][WORD_SIZE-1:0]                    wdata_i          ,
  input  logic                                                        read_en_i        ,
  input  logic [$clog2(ELMS)-1:0]                                     elms_read_addr_i ,  // The element read address is the same for all entries
  input  logic [$clog2(COLS)-1:0]                                     cols_read_offs_i ,  // We only need the column read address of the first row as the others can be generated
  input  logic [ROWS-1:0][$clog2(ROWS)-1:0]                           rows_read_addr_i ,
  output logic [ROWS-1:0][WORD_SIZE-1:0]                              rdata_o
);
  logic [ROWS-1:0][COLS-1:0][ELMS-1:0][WORD_SIZE-1:0] buffer_q;
  logic [COLS-1:0][ELMS-1:0][WORD_SIZE-1:0]           wdata_q;

  logic [$clog2(ELMS)-1:0]                            elms_read_addr_q;
  logic [$clog2(COLS)-1:0]                            cols_read_offs_q;
  logic [ROWS-1:0][$clog2(ROWS)-1:0]                  rows_read_addr_q;

  logic [ROWS-1:0][$clog2(COLS)-1:0]                  cols_read_addr;

  logic [ROWS-1:0]                                    clk_w;

  always_ff @(posedge clk_i or negedge rst_ni) begin : sample_raddrs
    if(~rst_ni) begin
      elms_read_addr_q <= '0;
      cols_read_offs_q <= '0;
      rows_read_addr_q <= '0;
    end else begin
      if (clear_i) begin
        elms_read_addr_q <= '0;
        cols_read_offs_q <= '0;
        rows_read_addr_q <= '0;
      end else if (read_en_i) begin
        elms_read_addr_q <= elms_read_addr_i;
        cols_read_offs_q <= cols_read_offs_i;
        rows_read_addr_q <= rows_read_addr_i;
      end
    end
  end

  for (genvar r = 0; r < ROWS; r++) begin : gen_cols_read_addrs
    assign cols_read_addr[r] = cols_read_offs_q >= r ? cols_read_offs_q - r : ROWS - (r - cols_read_offs_q);
  end

  for (genvar r = 0; r < ROWS; r++) begin : gen_output_assignment
    assign rdata_o[r] = buffer_q[rows_read_addr_q[r]][cols_read_addr[r]][elms_read_addr_q];
  end

  if (USE_LATCHES) begin : gen_latches
    always_ff @(posedge clk_i or negedge rst_ni) begin : sample_wdata
      if(~rst_ni) begin
        wdata_q <= '0;
      end else begin
        if (clear_i) begin
          wdata_q <= '0;
        end else if (write_en_i) begin
          wdata_q <= wdata_i;
        end
      end
    end

    for (genvar r = 0; r < ROWS; r++) begin : gen_write_clock_gates
      tc_clk_gating i_rows_cg (
        .clk_i     ( clk_i                                      ),
        .en_i      ( write_addr_i == r && write_en_i || clear_i ),
        .test_en_i ( '0                                         ),
        .clk_o     ( clk_w[r]                                   )
      );
    end

    for (genvar r = 0; r < ROWS; r++) begin : gen_rows
      for (genvar c = 0; c < COLS; c++) begin : gen_cols
        always_latch begin : wdata
          if (clk_w[r]) begin
            buffer_q[r][c] = wdata_q[c];
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
            end else if (write_addr_i == r && write_en_i) begin
              buffer_q[r][c] <= wdata_i[c];
            end
          end
        end
      end
    end
  end

endmodule : redmule_w_buffer_scm
