/*
 * Copyright (C) 2022-2023 ETH Zurich and University of Bologna
 *
 * Licensed under the Solderpad Hardware License, Version 0.51
 * (the "License"); you may not use this file except in compliance
 * with the License. You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * SPDX-License-Identifier: SHL-0.51
 *
 * Authors: Yvan Tortorella <yvan.tortorella@unibo.it>
 *
 * RedMulE Complex Core
 */

module redmule_complex
  import snitch_pkg::*;
  import fpnew_pkg::*;
  import hci_package::*;
  import redmule_pkg::*;
  import hwpe_ctrl_package::*;
  import hwpe_stream_package::*;
#(
  parameter  core_type_e   CoreType           = CV32                 , // CV32E40P, IBEX, SNITCH, CVA6
  parameter  int unsigned  ID_WIDTH           = 8                    ,
  parameter  int unsigned  N_CORES            = 8                    ,
  parameter  int unsigned  DW                 = DATA_W               , // TCDM port dimension (in bits)
  parameter  int unsigned  MP                 = DW/redmule_pkg::MemDw,
  parameter  int unsigned  NumIrqs            = 32                   ,
  parameter  int unsigned  AddrWidth          = 32                   ,
  parameter  int unsigned  XPulp              = 0                    ,
  parameter  int unsigned  FpuPresent         = 0                    ,
  parameter  int unsigned  Zfinx              = 0                    ,
  parameter      type      core_data_req_t    = logic                ,
  parameter      type      core_data_rsp_t    = logic                ,
  parameter      type      core_inst_req_t    = logic                ,
  parameter      type      core_inst_rsp_t    = logic                ,
  parameter      type      redmule_data_req_t = logic                ,
  parameter      type      redmule_data_rsp_t = logic                ,
  parameter      type      redmule_ctrl_req_t = logic                ,
  parameter      type      redmule_ctrl_rsp_t = logic                ,
  localparam fp_format_e   FpFormat    = FPFORMAT                    , // Data format (default is FP16)
  localparam int unsigned  Height      = ARRAY_HEIGHT                , // Number of PEs within a row
  localparam int unsigned  Width       = ARRAY_WIDTH                 , // Number of parallel rows
  localparam int unsigned  NumPipeRegs = PIPE_REGS                   , // Number of pipeline registers within each PE
  localparam pipe_config_t PipeConfig  = DISTRIBUTED                 ,
  localparam int unsigned  BITW        = fp_width(FpFormat)            // Number of bits for the given format
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
  input  core_inst_rsp_t               core_inst_rsp_i   ,
  output core_inst_req_t               core_inst_req_o   ,
  input  core_data_rsp_t               core_data_rsp_i   ,
  output core_data_req_t               core_data_req_o   ,
  input  redmule_data_rsp_t            redmule_data_rsp_i,
  output redmule_data_req_t            redmule_data_req_o
);

logic busy;
logic s_clk, s_clk_en;
logic [N_CORES-1:0][1:0] evt;

core_inst_req_t core_inst_req;
core_inst_rsp_t core_inst_rsp;

core_data_req_t core_data_req;
core_data_rsp_t core_data_rsp;

redmule_ctrl_req_t redmule_ctrl_req;
redmule_ctrl_rsp_t redmule_ctrl_rsp;

hci_core_intf #(.DW(DW)) tcdm (.clk(clk_i));
hwpe_ctrl_intf_periph #(.ID_WIDTH(ID_WIDTH)) periph (.clk(clk_i));

always_ff @(posedge clk_i or negedge rst_ni) begin: clock_enable
  if (~rst_ni)
    s_clk_en <= 1'b0;
  else
    s_clk_en <= fetch_enable_i;
end

tc_clk_gating sys_clock_gating (
  .clk_i     ( clk_i       ),
  .en_i      ( s_clk_en    ),
  .test_en_i ( test_mode_i ),
  .clk_o     ( s_clk       )
);

redmule_top #(
  .ID_WIDTH           ( ID_WIDTH           ),
  .N_CORES            ( 1                  ),
  .DW                 ( DW                 ),
  .redmule_data_req_t ( redmule_data_req_t ),
  .redmule_data_rsp_t ( redmule_data_rsp_t )
) i_redmule_top       (
  .clk_i              ( s_clk              ),
  .rst_ni             ( rst_ni             ),
  .test_mode_i        ( test_mode_i        ),
  .evt_o              ( evt                ),
  .busy_o             ( busy               ),
  .data_rsp_i         ( redmule_data_rsp_i ),
  .data_req_o         ( redmule_data_req_o ),
  .periph             ( periph             )
);

generate
  if (CoreType == CV32) begin: gen_cv32e40p
    cv32e40p_core #(
      .PULP_XPULP     ( XPulp      ),
      .FPU            ( FpuPresent ),
      .PULP_ZFINX     ( Zfinx      )
    ) i_core          (
      // Clock and Reset
      .clk_i               ( s_clk               ),
      .rst_ni              ( rst_ni              ),
      .pulp_clock_en_i     ( s_clk_en            ),  // PULP clock enable (only used if PULP_CLUSTER = 1)
      .scan_cg_en_i        ( 1'b0                ),  // Enable all clock gates for testing
      // Core ID, Cluster ID, debug mode halt address and boot address are considered more or less static
      .boot_addr_i         ( boot_addr_i         ),
      .mtvec_addr_i        ( '0                  ),
      .dm_halt_addr_i      ( '0                  ),
      .hart_id_i           ( '0                  ),
      .dm_exception_addr_i ( '0                  ),
      // Instruction memory interface
      .instr_req_o         ( core_inst_req_o.req   ),
      .instr_addr_o        ( core_inst_req_o.addr  ),
      .instr_gnt_i         ( core_inst_rsp_i.gnt   ),
      .instr_rvalid_i      ( core_inst_rsp_i.valid ),
      .instr_rdata_i       ( core_inst_rsp_i.data  ),
      // Data memory interface
      .data_req_o          ( core_data_req_o.req   ),
      .data_we_o           ( core_data_req_o.we    ),
      .data_be_o           ( core_data_req_o.be    ),
      .data_addr_o         ( core_data_req_o.addr  ),
      .data_wdata_o        ( core_data_req_o.data  ),
      .data_gnt_i          ( core_data_rsp_i.gnt   ),
      .data_rvalid_i       ( core_data_rsp_i.valid ),
      .data_rdata_i        ( core_data_rsp_i.data  ),
      // apu-interconnect
      // handshake signals
      .apu_req_o           (                   ),
      .apu_gnt_i           ( '0                ),
      // request channel
      .apu_operands_o      (                   ),
      .apu_op_o            (                   ),
      .apu_flags_o         (                   ),
      // response channel
      .apu_rvalid_i        ( '0                ),
      .apu_result_i        ( '0                ),
      .apu_flags_i         ( '0                ),
      // Interrupt inputs
      .irq_i               ({27'd0 ,evt, 3'd0} ),  // CLINT interrupts + CLINT extension interrupts
      .irq_ack_o           (                   ),
      .irq_id_o            (                   ),
      // Debug Interface
      .debug_req_i         ( '0                ),
      .debug_havereset_o   (                   ),
      .debug_running_o     (                   ),
      .debug_halted_o      (                   ),
      // CPU Control Signals
      .fetch_enable_i      ( fetch_enable_i    ),
      .core_sleep_o        ( core_sleep_o      )
    );
  end else if (CoreType == Ibex) begin: gen_ibex

  end else if (CoreType == Snitch) begin: gen_snitch
    snitch_pkg::interrupts_t irqs;
    always_comb begin
      irqs.debug = '0;
      irqs.meip  = '0;
      irqs.mtip  = '0;
      irqs.msip  = '0;
      irqs.mcip  = evt;
    end

    snitch #(
      .BootAddr               ( 32'h1C000084       ),
      .AddrWidth              ( 32                 ),
      .DataWidth              ( 32                 ),
      .RVE                    ( 0                  ),
      .Xdma                   ( 0                  ),
      .Xssr                   ( 0                  ),
      .FP_EN                  ( 0                  ),
      .RVF                    ( 0                  ),
      .RVD                    ( 0                  ),
      .XF16                   ( 0                  ),
      .XF16ALT                ( 0                  ),
      .XF8                    ( 0                  ),
      .XF8ALT                 ( 0                  ),
      .XDivSqrt               ( 0                  ),
      .XFVEC                  ( 0                  ),
      .XFDOTP                 ( 0                  ),
      .XFAUX                  ( 0                  ),
      .FLEN                   ( 0                  ),
      .VMSupport              ( 0                  ),
      .Xipu                   ( 0                  ),
      .dreq_t                 ( core_data_req_t    ),
      .drsp_t                 ( core_data_rsp_t    ),
      .acc_req_t              ( redmule_ctrl_req_t ),
      .acc_resp_t             ( redmule_ctrl_rsp_t ),
      .pa_t                   (  '{0}              ),
      .l0_pte_t               (  '{0}              ),
      .NumIntOutstandingLoads (   0                ),
      .NumIntOutstandingMem   (   0                ),
      .NumDTLBEntries         (   0                ),
      .NumITLBEntries         (   0                ),
      .SnitchPMACfg           (  '{0}              )
    ) i_core                  (
      .clk_i                  ( s_clk               ),
      .rst_i                  ( rst_ni              ),
      .hart_id_i              ( 0                   ),
      .irq_i                  ( irqs                ),
      .flush_i_valid_o        (                     ),
      .flush_i_ready_i        ( 0                   ),
      .inst_valid_o           ( core_inst_req.req   ),
      .inst_addr_o            ( core_inst_req.addr  ),
      .inst_cacheable_o       (                     ),
      .inst_ready_i           ( core_inst_rsp.valid ),
      .inst_data_i            ( core_inst_rsp.data  ),
      .acc_qreq_o             ( redmule_ctrl_req    ),
      .acc_qvalid_o           (                     ),
      .acc_qready_i           ( '1                  ),
      .acc_prsp_i             ( redmule_ctrl_rsp    ),
      .acc_pvalid_i           ( '1                  ),
      .acc_pready_o           (                     ),
      .data_req_o             ( core_data_req       ),
      .data_rsp_i             ( core_data_rsp       ),
      .ptw_valid_o            (                     ),
      .ptw_ready_i            ( '0                  ),
      .ptw_va_o               (                     ),
      .ptw_ppn_o              (                     ),
      .ptw_pte_i              ( '0                  ),
      .ptw_is_4mega_i         ( '0                  ),
      .fpu_rnd_mode_o         (                     ),
      .fpu_fmt_mode_o         (                     ),
      .fpu_status_i           ( '0                  ),
      .core_events_o          (                     )
    );
  end else begin: gen_cva6

  end
endgenerate

endmodule: redmule_complex
