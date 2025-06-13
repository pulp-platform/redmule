// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
//

timeunit 1ps; timeprecision 1ps;

module redmule_tb_wrap;
import redmule_pkg::*;

  localparam TCP = 1.0ns; // clock period, 1 GHz clock
  localparam TA  = 0.2ns; // application time
  localparam TT  = 0.8ns; // test time
  parameter  real  PROB_STALL = 0; // Dummy memories stall probability (passed through the Makefile)

  logic clk, rst_n, fetch_enable;

  redmule_tb #(
    .TCP ( TCP ),
    .TA  ( TA  ),
    .TT  ( TT  )
  ) i_redmule_tb (
    .clk_i          ( clk          ),
    .rst_ni         ( rst_n        ),
    .fetch_enable_i ( fetch_enable )
  );

  // Performs one entire clock cycle.
  task cycle;
    clk <= #(TCP/2) 0;
    clk <= #TCP 1;
    #TCP;
  endtask

  initial begin
    clk <= 1'b0;
    rst_n <= 1'b0;
    fetch_enable <= 1'b0;

    for (int i = 0; i < 20; i++) cycle();

    rst_n <= #TA 1'b1;

    for (int i = 0; i < 10; i++) cycle();

    rst_n <= #TA 1'b0;

    for (int i = 0; i < 10; i++) cycle();

    rst_n <= #TA 1'b1;

    #(100*TCP);
    fetch_enable = 1'b1;

    while(1) cycle();

  end

endmodule // redmule_tb_wrap
