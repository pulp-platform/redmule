// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
//

module redmule_complex_wrap
 import redmule_pkg::*;
#(
 localparam int unsigned AddrWidth = 32,
 localparam int unsigned NumIrqs   = 0
)(
  input  logic                         clk_i             ,
  input  logic                         rst_ni            ,
  input  logic                         test_mode_i       ,
  input  logic                         fetch_enable_i    ,
  input  logic    [     AddrWidth-1:0] boot_addr_i       ,
  input  logic    [       NumIrqs-1:0] irq_i             ,
  output logic   [$clog2(NumIrqs)-1:0] irq_id_o          ,
  output logic                         irq_ack_o         ,
  output logic                         core_sleep_o      ,
  input  core_default_inst_rsp_t       core_inst_rsp_i   ,
  output core_default_inst_req_t       core_inst_req_o   ,
  input  core_default_data_rsp_t       core_data_rsp_i   ,
  output core_default_data_req_t       core_data_req_o   ,
  input  redmule_default_data_rsp_t    redmule_data_rsp_i,
  output redmule_default_data_req_t    redmule_data_req_o
);
localparam int unsigned DW = redmule_pkg::DATA_W;
localparam int unsigned NC = 1;

logic                         test_mode   ;
logic                         fetch_enable;
logic    [     AddrWidth-1:0] boot_addr   ;
logic    [       NumIrqs-1:0] irq         ;
logic   [$clog2(NumIrqs)-1:0] irq_id      ;
logic                         irq_ack     ;
logic                         core_sleep  ;

core_default_inst_rsp_t       core_inst_rsp;
core_default_inst_req_t       core_inst_req;
core_default_data_rsp_t       core_data_rsp;
core_default_data_req_t       core_data_req;
redmule_default_data_rsp_t    redmule_data_rsp;
redmule_default_data_req_t    redmule_data_req;

always_ff @(posedge clk_i, negedge rst_ni) begin
  if (~rst_ni) begin
    // Inputs
    test_mode        <= '0;
    fetch_enable     <= '0;
    boot_addr        <= '0;
    irq              <= '0;
    core_inst_rsp    <= '0;
    core_data_rsp    <= '0;
    redmule_data_rsp <= '0;
    // Outputs
    irq_id_o           <= '0;
    irq_ack_o          <= '0;
    core_sleep_o       <= '0;
    core_inst_req_o    <= '0;
    core_data_req_o    <= '0;
    redmule_data_req_o <= '0;
  end else begin
    // Inputs
    test_mode        <= test_mode_i       ;
    fetch_enable     <= fetch_enable_i    ;
    boot_addr        <= boot_addr_i       ;
    irq              <= irq_i             ;
    core_inst_rsp    <= core_inst_rsp_i   ;
    core_data_rsp    <= core_data_rsp_i   ;
    redmule_data_rsp <= redmule_data_rsp_i;
    // Outputs
    irq_id_o           <= irq_id          ;
    irq_ack_o          <= irq_ack         ;
    core_sleep_o       <= core_sleep      ;
    core_inst_req_o    <= core_inst_req   ;
    core_data_req_o    <= core_data_req   ;
    redmule_data_req_o <= redmule_data_req;
  end
end

redmule_complex #(
  .CoreType           ( redmule_pkg::CV32X          ), // CV32E40P, CV32E40X, IBEX, SNITCH, CVA6
  .ID_WIDTH           ( redmule_pkg::ID             ),
  .N_CORES            ( NC                          ),
  .DW                 ( DW                          ), // TCDM port dimension (in bits)
  .MP                 ( DW/32                       ),
  .NumIrqs            ( NumIrqs                     ),
  .AddrWidth          ( AddrWidth                   ),
  .core_data_req_t    ( core_default_data_req_t     ),
  .core_data_rsp_t    ( core_default_data_rsp_t     ),
  .core_inst_req_t    ( core_default_inst_req_t     ),
  .core_inst_rsp_t    ( core_default_inst_rsp_t     ),
  .redmule_data_req_t ( redmule_default_data_req_t  ),
  .redmule_data_rsp_t ( redmule_default_data_rsp_t  )
) i_redmule_complex   (
  .clk_i              ( clk_i            ),
  .rst_ni             ( rst_ni           ),
  .test_mode_i        ( test_mode        ),
  .fetch_enable_i     ( fetch_enable     ),
  .boot_addr_i        ( boot_addr        ),
  .irq_i              ( irq              ),
  .irq_id_o           ( irq_id           ),
  .irq_ack_o          ( irq_ack          ),
  .core_sleep_o       ( core_sleep       ),
  .core_inst_rsp_i    ( core_inst_rsp    ),
  .core_inst_req_o    ( core_inst_req    ),
  .core_data_rsp_i    ( core_data_rsp    ),
  .core_data_req_o    ( core_data_req    ),
  .redmule_data_rsp_i ( redmule_data_rsp ),
  .redmule_data_req_o ( redmule_data_req )
);

endmodule : redmule_complex_wrap
