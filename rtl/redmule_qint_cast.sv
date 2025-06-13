// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Andrea Belano <andrea.belano2@unibo.it>
//

module redmule_qint_cast
  import hci_package::*;
  import redmule_pkg::*;
  import hwpe_stream_package::*;
#(
  parameter int unsigned DW = DATA_W
)(
  input  logic                   clk_i   ,
  input  logic                   rst_ni  ,
  input  logic                   clear_i ,
  input  qint_fmt_e              fmt_i   ,
  hwpe_stream_intf_stream.sink   stream_i,
  hwpe_stream_intf_stream.source stream_o
);

  logic [DW-1:0] data_cast;

  assign stream_o.valid = stream_i.valid;
  assign stream_o.strb  = stream_i.strb;
  assign stream_o.data  = data_cast;
  assign stream_i.ready = stream_o.ready;

  always_comb begin
    data_cast = stream_i.data;

    case (fmt_i)
      QINT_8: begin
        data_cast = stream_i.data;
      end

      QINT_4: begin
        for (int unsigned i = 0; i < DW/8; i++) begin
          data_cast[i*8+:8] = {4'b0, stream_i.data[i*4+:4]};
        end
      end

      QINT_2: begin
        for (int unsigned i = 0; i < DW/8; i++) begin
          data_cast[i*8+:8] = {6'b0,stream_i.data[i*2+:2]};
        end
      end

      // FIXME 3 bit weights are not supported yet
    endcase
  end

endmodule : redmule_qint_cast
