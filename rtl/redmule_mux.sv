// Copyright 2025 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Andrea Belano <andrea.belano2@unibo.it>
//

`include "hci_helpers.svh"

module redmule_mux
  import redmule_pkg::*;
  import hwpe_stream_package::*;
  import hci_package::*;
#(
  parameter int unsigned NB_CHAN    = 2,
  parameter hci_size_parameter_t `HCI_SIZE_PARAM(out) = '0
) (
  input  logic            clk_i,
  input  logic            rst_ni,
  input  logic            clear_i,
  hci_core_intf.target    in [0:NB_CHAN-1],
  hci_core_intf.initiator out
);

  localparam int unsigned DW  = `HCI_SIZE_GET_DW(out);
  localparam int unsigned BW  = `HCI_SIZE_GET_BW(out);
  localparam int unsigned AW  = `HCI_SIZE_GET_AW(out);
  localparam int unsigned UW  = `HCI_SIZE_GET_UW(out);
  localparam int unsigned IW  = `HCI_SIZE_GET_IW(out);
  localparam int unsigned EW  = `HCI_SIZE_GET_EW(out);
  localparam int unsigned EHW = `HCI_SIZE_GET_EHW(out);

  // tcdm ports binding
  logic [NB_CHAN-1:0]                            in_req;
  logic [NB_CHAN-1:0]                            in_gnt;
  logic [NB_CHAN-1:0]                            in_r_valid;
  logic [NB_CHAN-1:0]                            in_lrdy;
  logic [NB_CHAN-1:0][AW-1:0]                    in_add;
  logic [NB_CHAN-1:0]                            in_wen;
  logic [NB_CHAN-1:0][DW-1:0]                    in_data;
  logic [NB_CHAN-1:0][DW/BW-1:0]                 in_be;
  logic [NB_CHAN-1:0][hci_package::iomsb(UW):0]  in_user;
  logic [NB_CHAN-1:0][hci_package::iomsb(IW):0]  in_id;
  logic [NB_CHAN-1:0][hci_package::iomsb(EW):0]  in_ecc;
  logic [NB_CHAN-1:0][hci_package::iomsb(EHW):0] in_egnt;
  logic [NB_CHAN-1:0][hci_package::iomsb(EHW):0] in_r_evalid;

  logic [$clog2(NB_CHAN)-1:0] winner_d, winner_q;

  always_comb begin : winner_assignment
    winner_d = '0;

    if (in_req[WsourceStreamId]) begin             // W
      winner_d = WsourceStreamId;
    end else if (in_req[XsourceStreamId]) begin    // X
      winner_d = XsourceStreamId;
    end else if (in_req[YsourceStreamId]) begin    // Y
      winner_d = YsourceStreamId;
    end else if (in_req[PACEsourceStreamId]) begin // PACE IN
      winner_d = PACEsourceStreamId;
    end else if (in_req[NumStreamSources]) begin   // Z
      winner_d = NumStreamSources;
    end else if (in_req[RsourceStreamId]) begin    // R Source
      winner_d = RsourceStreamId;
    end else if (in_req[NumStreamSources+1]) begin // R Sink
      winner_d = NumStreamSources+1;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin : winner_register
    if (~rst_ni) begin
      winner_q <= '0;
    end else begin
      if (clear_i) begin
        winner_q <= '0;
      end else begin
        winner_q <= winner_d;
      end
    end
  end

  for(genvar ii=0; ii<NB_CHAN; ii++) begin: in_port_binding
    assign in_req     [ii] = in[ii].req;
    assign in_lrdy    [ii] = in[ii].r_ready;
    assign in_add     [ii] = in[ii].add;
    assign in_wen     [ii] = in[ii].wen;
    assign in_data    [ii] = in[ii].data;
    assign in_be      [ii] = in[ii].be;
    assign in_user    [ii] = in[ii].user;
    assign in_id      [ii] = ii;
    assign in_ecc     [ii] = in[ii].ecc;

    // We do not have outstanding transactions AND r_valid has to be asserted 1 cycle after the grant (why tho?)
    // so we can route the r_valid signal using the id of the previous winner
    assign in_gnt[ii]      = (winner_d == ii) ? in[ii].req & out.gnt : 1'b0;
    assign in[ii].gnt      = in_gnt[ii];
    assign in_r_valid[ii]  = (winner_q == ii) ? out.r_valid : 1'b0;
    assign in[ii].r_valid  = in_r_valid[ii];
    assign in[ii].r_data   = out.r_data;
    assign in[ii].r_opc    = out.r_opc;
    assign in[ii].r_user   = out.r_user;
    assign in[ii].r_ecc    = out.r_ecc;
    assign in[ii].r_id     = out.r_id;
    assign in[ii].egnt     = in_egnt;
    assign in[ii].r_evalid = in_r_evalid;
  end

  assign out.req     = in_req   [winner_d];
  assign out.add     = in_add   [winner_d];
  assign out.wen     = in_wen   [winner_d];
  assign out.be      = in_be    [winner_d];
  assign out.data    = in_data  [winner_d];
  assign out.r_ready = in_lrdy  [out.r_id];
  assign out.user    = in_user  [winner_d];
  assign out.id      = in_id    [winner_d];
  assign out.ecc     = in_ecc   [winner_d];

  /*
 * ECC Handshake signals
 */
  if(EHW > 0) begin : ecc_handshake_gen
    for(genvar ii=0; ii<NB_CHAN; ii++) begin : in_chan_gen
      assign in_egnt[ii]     = '{default: {in_gnt[ii]}};
      assign in_r_evalid[ii] = '{default: {in_r_valid[ii]}};
    end
    assign out.ereq     = '{default: {out.req}};
    assign out.r_eready = '{default: {out.r_ready}};
  end
  else begin : no_ecc_handshake_gen
    for(genvar ii=0; ii<NB_CHAN; ii++) begin : in_chan_gen
      assign in_egnt[ii]     = '1;
      assign in_r_evalid[ii] = '0;
    end
    assign out.ereq     = '0;
    assign out.r_eready = '1;
  end

/*
 * Interface size asserts
 */
`ifndef SYNTHESIS
`ifndef VERILATOR
`ifndef VCS
  for(genvar i=0; i<NB_CHAN; i++) begin
    initial
      dw :  assert(in[i].DW  == out.DW);
    initial
      bw :  assert(in[i].BW  == out.BW);
    initial
      aw :  assert(in[i].AW  == out.AW);
    initial
      uw :  assert(in[i].UW  == out.UW);
    // initial
    //   iw_in :  assert(in[i].IW  == 0);
    initial
      iw_out :  assert(out.IW  >= $clog2(NB_CHAN));
    initial
      ew :  assert(in[i].EW  == out.EW);
    initial
      ehw : assert(in[i].EHW == out.EHW);
  end

  `HCI_SIZE_CHECK_ASSERTS(out);

`endif
`endif
`endif;

endmodule
