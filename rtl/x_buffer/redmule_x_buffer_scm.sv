// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Andrea Belano <andrea.belano2@unibo.it>
//

module redmule_x_buffer_scm #(
  parameter int unsigned WORD_SIZE = 32,
  parameter int unsigned WIDTH     = 1 ,
  parameter int unsigned HEIGHT    = 2 ,
  parameter int unsigned N_OUTPUTS = 1
) (
  input  logic                                           clk_i        ,
  input  logic                                           rst_ni       ,
  input  logic                                           clear_i      ,
  input  logic                                           write_en_i   ,
  input  logic [$clog2(N_OUTPUTS)+$clog2(HEIGHT)-1:0]    write_addr_i ,
  input  logic [WIDTH-1:0][WORD_SIZE-1:0]                wdata_i      ,
  input  logic                                           read_en_i    ,
  input  logic [$clog2(N_OUTPUTS)+$clog2(HEIGHT)-1:0]    read_addr_i  ,
  output logic [N_OUTPUTS-1:0][WIDTH-1:0][WORD_SIZE-1:0] rdata_o
);
  logic [HEIGHT-1:0][N_OUTPUTS-1:0][WIDTH-1:0][WORD_SIZE-1:0] buffer_q;
  logic [WIDTH-1:0][WORD_SIZE-1:0]                            wdata_q;
  logic [N_OUTPUTS-1:0][$clog2(HEIGHT)-1:0]                   read_addr_q;

  logic [$clog2(N_OUTPUTS)-1:0]                               row_w_addr;
  logic [$clog2(HEIGHT)-1:0]                                  slot_w_addr;

  logic [HEIGHT-1:0][N_OUTPUTS-1:0]                           clk_w;

  for (genvar o = 0; o < N_OUTPUTS; o++) begin : gen_read_addr_registers
    always_ff @(posedge clk_i or negedge rst_ni) begin : sample_raddr
      if(~rst_ni) begin
        read_addr_q[o] <= '0;
      end else begin
        if (clear_i) begin
          read_addr_q[o] <= '0;
        end if (read_en_i && read_addr_i[$clog2(N_OUTPUTS)-1:0] == o) begin
          read_addr_q[o] <= read_addr_i[$clog2(N_OUTPUTS)+:$clog2(HEIGHT)];
        end
      end
    end
  end

  for (genvar o = 0; o < N_OUTPUTS; o++) begin : gen_output_assignment
    assign rdata_o[o] = buffer_q[read_addr_q[o]][o];
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : sample_wdata
    if(~rst_ni) begin
      wdata_q <= '0;
    end else begin
      if (clear_i) begin
        wdata_q <= '0;
      end if (write_en_i) begin
        wdata_q <= wdata_i;
      end
    end
  end

  assign row_w_addr  = write_addr_i[$clog2(N_OUTPUTS)-1:0];
  assign slot_w_addr = write_addr_i[$clog2(N_OUTPUTS)+:$clog2(HEIGHT)];

  for (genvar h = 0; h < HEIGHT; h++) begin : gen_slots_cg
    for (genvar o = 0; o < N_OUTPUTS; o++) begin : gen_rows_cg
      tc_clk_gating i_row_cg (
        .clk_i     ( clk_i                                                        ),
        .en_i      ( row_w_addr == o && slot_w_addr == h && write_en_i || clear_i ),
        .test_en_i ( '0                                                           ),
        .clk_o     ( clk_w[h][o]                                                  )
      );
    end
  end

  for (genvar h = 0; h < HEIGHT; h++) begin : gen_slots
    for (genvar o = 0; o < N_OUTPUTS; o++) begin : gen_rows
      always_latch begin : latch_wdata
        if (clk_w[h][o]) begin
          buffer_q[h][o] = wdata_q;
        end
      end
    end
  end

endmodule : redmule_x_buffer_scm
