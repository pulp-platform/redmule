// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
//

module redmule_complex
  import cv32e40x_pkg::*;
  import fpnew_pkg::*;
  import hci_package::*;
  import redmule_pkg::*;
  import hwpe_ctrl_package::*;
  import hwpe_stream_package::*;
#(
  // CV32E40P, IBEX, SNITCH, CVA6
  parameter core_type_e CoreType = CV32X,
  parameter int unsigned ID_WIDTH = 8,
  parameter int unsigned N_CORES = 8,
  // TCDM port dimension (in bits)
  parameter int unsigned DW = DATA_W,
  parameter int unsigned MP = DW/redmule_pkg::MemDw,
  parameter int unsigned NumIrqs = 32,
  parameter int unsigned AddrWidth = 32,
  parameter int unsigned XPulp = 0,
  parameter int unsigned FpuPresent = 0,
  parameter int unsigned Zfinx = 0,
  parameter type core_data_req_t = logic,
  parameter type core_data_rsp_t = logic,
  parameter type core_inst_req_t = logic,
  parameter type core_inst_rsp_t = logic,
  // Data format (default is FP16)
  localparam fp_format_e  FpFormat = FPFORMAT,
  // Number of PEs within a row
  localparam int unsigned Height = ARRAY_HEIGHT,
  // Number of parallel rows
  localparam int unsigned Width = ARRAY_WIDTH,
  // Number of pipeline registers within each PE
  localparam int unsigned NumPipeRegs = PIPE_REGS,
  localparam pipe_config_t PipeConfig  = DISTRIBUTED,
  // Number of bits for the given format
  localparam int unsigned BITW = fp_width(FpFormat)
)(
  input  logic                         clk_i             ,
  input  logic                         rst_ni            ,
  input  logic                         test_mode_i       ,
  input  logic                         fetch_enable_i    ,
  input  logic   [      AddrWidth-1:0] boot_addr_i       ,
  input  logic   [        NumIrqs-1:0] irq_i             ,
  output logic   [$clog2(NumIrqs)-1:0] irq_id_o          ,
  output logic                         irq_ack_o         ,
  output logic                         core_sleep_o      ,
  input  core_inst_rsp_t               core_inst_rsp_i   ,
  output core_inst_req_t               core_inst_req_o   ,
  input  core_data_rsp_t               core_data_rsp_i   ,
  output core_data_req_t               core_data_req_o   ,
  hci_core_intf.initiator              tcdm
);

localparam int unsigned SysDataWidth = (CoreType == CVA6) ? 64 : 32;
localparam int unsigned SysInstWidth = (CoreType == CVA6) ? 64 : 32;

logic busy;
logic s_clk, s_clk_en;
logic [N_CORES-1:0][1:0] evt;

core_inst_req_t core_inst_req;
core_inst_rsp_t core_inst_rsp;

core_data_req_t core_data_req;
core_data_rsp_t core_data_rsp;

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

localparam int unsigned NumRs = 3;
localparam int unsigned XifMemWidth = 32;
localparam int unsigned XifRFReadWidth = 32;
localparam int unsigned XifRFWriteWidth = 32;
localparam logic [31:0] XifMisa = '0;
localparam logic [ 1:0] XifEcsXs = '0;

cv32e40x_if_xif#(
  .X_NUM_RS    ( NumRs           ),
  .X_ID_WIDTH  ( ID_WIDTH        ),
  .X_MEM_WIDTH ( XifMemWidth     ),
  .X_RFR_WIDTH ( XifRFReadWidth  ),
  .X_RFW_WIDTH ( XifRFWriteWidth ),
  .X_MISA      ( XifMisa         ),
  .X_ECS_XS    ( XifEcsXs        )
) core_xif ();

cv32e40x_if_xif#(
  .X_NUM_RS    ( NumRs           ),
  .X_ID_WIDTH  ( ID_WIDTH        ),
  .X_MEM_WIDTH ( XifMemWidth     ),
  .X_RFR_WIDTH ( XifRFReadWidth  ),
  .X_RFW_WIDTH ( XifRFWriteWidth ),
  .X_MISA      ( XifMisa         ),
  .X_ECS_XS    ( XifEcsXs        )
) redmule_xif ();

generate
  if (CoreType == CV32P) begin: gen_cv32e40p
    cv32e40p_core #(
      .PULP_XPULP     ( XPulp      ),
      .FPU            ( FpuPresent ),
      .PULP_ZFINX     ( Zfinx      )
    ) i_core          (
      // Clock and Reset
      .clk_i               ( s_clk                 ),
      .rst_ni              ( rst_ni                ),
      .pulp_clock_en_i     ( s_clk_en              ),  // PULP clock enable (only used if PULP_CLUSTER = 1)
      .scan_cg_en_i        ( 1'b0                  ),  // Enable all clock gates for testing
      // Core ID, Cluster ID, debug mode halt address and boot address are considered more or less static
      .boot_addr_i         ( boot_addr_i           ),
      .mtvec_addr_i        ( '0                    ),
      .dm_halt_addr_i      ( '0                    ),
      .hart_id_i           ( '0                    ),
      .dm_exception_addr_i ( '0                    ),
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
  end else if (CoreType == CV32X) begin: gen_cv32e40x
    cv32e40x_core #(
      .M_EXT       ( cv32e40x_pkg::M ),
      .X_EXT       ( 1               ),
      .X_NUM_RS    ( NumRs           ),
      .X_ID_WIDTH  ( ID_WIDTH        ),
      .X_MEM_WIDTH ( XifMemWidth     ),
      .X_RFR_WIDTH ( XifRFReadWidth  ),
      .X_RFW_WIDTH ( XifRFWriteWidth ),
      .X_MISA      ( XifMisa         ),
      .X_ECS_XS    ( XifEcsXs        )
    ) i_core       (
      // Clock and Reset
      .clk_i               ( s_clk                      ),
      .rst_ni              ( rst_ni                     ),
      .scan_cg_en_i        ( 1'b0                       ),  // Enable all clock gates for testing
      // Core ID, Cluster ID, debug mode halt address and boot address are considered more or less static
      .boot_addr_i         ( boot_addr_i                ),
      .dm_exception_addr_i ( '0                         ),
      .dm_halt_addr_i      ( '0                         ),
      .mhartid_i           ( '0                         ),
      .mimpid_patch_i      ( '0                         ),
      .mtvec_addr_i        ( '0                         ),
      // Instruction memory interface
      .instr_req_o         ( core_inst_req_o.req        ),
      .instr_gnt_i         ( core_inst_rsp_i.gnt        ),
      .instr_rvalid_i      ( core_inst_rsp_i.valid      ),
      .instr_addr_o        ( core_inst_req_o.addr       ),
      .instr_memtype_o     (                            ),
      .instr_prot_o        (                            ),
      .instr_dbg_o         (                            ),
      .instr_rdata_i       ( core_inst_rsp_i.data       ),
      .instr_err_i         ( '0                         ),
      // Data memory interface
      .data_req_o          ( core_data_req_o.req        ),
      .data_gnt_i          ( core_data_rsp_i.gnt        ),
      .data_rvalid_i       ( core_data_rsp_i.valid      ),
      .data_addr_o         ( core_data_req_o.addr       ),
      .data_be_o           ( core_data_req_o.be         ),
      .data_we_o           ( core_data_req_o.we         ),
      .data_wdata_o        ( core_data_req_o.data       ),
      .data_memtype_o      (                            ),
      .data_prot_o         (                            ),
      .data_dbg_o          (                            ),
      .data_atop_o         (                            ),
      .data_rdata_i        ( core_data_rsp_i.data       ),
      .data_err_i          ( '0                         ),
      .data_exokay_i       ( '1                         ),
      // Cycle, Time
      .mcycle_o            (                            ),
      .time_i              ( '0                         ),
      // eXtension interface
      .xif_compressed_if   ( core_xif.cpu_compressed    ),
      .xif_issue_if        ( core_xif.cpu_issue         ),
      .xif_commit_if       ( core_xif.cpu_commit        ),
      .xif_mem_if          ( core_xif.cpu_mem           ),
      .xif_mem_result_if   ( core_xif.cpu_mem_result    ),
      .xif_result_if       ( core_xif.cpu_result        ),
      // Basic interrupt architecture
      .irq_i               ( {27'd0 ,evt, 3'd0}         ),
      // Event wakeup signals
      .wu_wfe_i            ( '0                         ), // Wait-for-event wakeup
      // CLIC interrupt architecture
      .clic_irq_i          ( '0                         ),
      .clic_irq_id_i       ( '0                         ),
      .clic_irq_level_i    ( '0                         ),
      .clic_irq_priv_i     ( '0                         ),
      .clic_irq_shv_i      ( '0                         ),
      // Fence.i flush handshake
      .fencei_flush_req_o  (                            ),
      .fencei_flush_ack_i  ( '0                         ),
      // Debug Interface
      .debug_req_i         ( '0                         ),
      .debug_havereset_o   (                            ),
      .debug_running_o     (                            ),
      .debug_halted_o      (                            ),
      .debug_pc_valid_o    (                            ),
      .debug_pc_o          (                            ),
      // CPU Control Signals
      .fetch_enable_i      ( fetch_enable_i             ),
      .core_sleep_o        ( core_sleep_o               )
    );
  end else if (CoreType == Ibex) begin: gen_ibex
    $error("Ibex connection not yet implemented");
  end else begin: gen_cva6
    $error("CVA6 connection not yet implemented");
  end
endgenerate

localparam int unsigned XExt = (CoreType == CV32X) ? 1 : 0;

redmule_top #(
  .ID_WIDTH           ( ID_WIDTH              ),
  .N_CORES            ( 1                     ),
  .DW                 ( DW                    ),
  .X_EXT              ( XExt                  ),
  .SysInstWidth       ( SysInstWidth          ),
  .SysDataWidth       ( SysDataWidth          )
) i_redmule_top       (
  .clk_i              ( s_clk                      ),
  .rst_ni             ( rst_ni                     ),
  .test_mode_i        ( test_mode_i                ),
  .evt_o              ( evt                        ),
  .busy_o             ( busy                       ),
  .tcdm               ( tcdm                       ),
  .xif_issue_if_i     ( core_xif.coproc_issue      ),
  .xif_result_if_o    ( core_xif.coproc_result     ),
  .xif_compressed_if_i( core_xif.coproc_compressed ),
  .xif_mem_if_o       ( core_xif.coproc_mem        )
);

endmodule: redmule_complex
