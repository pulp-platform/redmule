// Copyright 2023 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Yvan Tortorella <yvan.tortorella@unibo.it>
//

`include "obi/typedef.svh"
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
  parameter int unsigned NumIrqs = 32,
  parameter int unsigned AddrWidth = 32,
  parameter int unsigned CoreDataWidth = 32,
  parameter int unsigned XPulp = 0,
  parameter int unsigned FpuPresent = 0,
  parameter int unsigned Zfinx = 0,
  parameter int unsigned RedMulERegionStartAddr = 'h00100000,
  parameter int unsigned RedMulERegionSize = 'h400,
  // Data format (default is FP16)
  parameter fp_format_e  FpFormat = FPFORMAT,
  // Number of PEs within a row
  parameter int unsigned Height = ARRAY_HEIGHT,
  // Number of parallel rows
  parameter int unsigned Width = ARRAY_WIDTH,
  parameter type core_data_req_t = struct packed {
    logic req;
    logic we;
    logic [(CoreDataWidth/8)-1:0] be;
    logic [AddrWidth-1:0] addr;
    logic [CoreDataWidth-1:0] data;
  },
  parameter type core_data_rsp_t = struct packed {
    logic gnt;
    logic valid;
    logic [CoreDataWidth-1:0] data;
  },
  parameter type core_inst_req_t = struct packed {
    logic        req;
    logic [AddrWidth-1:0] addr;
  },
  parameter type core_inst_rsp_t = struct packed {
    logic        gnt;
    logic        valid;
    logic [CoreDataWidth-1:0] data;
  },
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
  input  logic                         redmule_clk_en_i  ,
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

localparam int unsigned XExt = (CoreType == CV32X) ? 1 : 0;
localparam int unsigned SysDataWidth = (CoreType == CVA6) ? 64 : 32;
localparam int unsigned SysInstWidth = (CoreType == CVA6) ? 64 : 32;
localparam int unsigned NumDemuxIdx = 2;
localparam int unsigned NumDemuxRules = 3;

logic busy;
logic s_clk, s_clk_en;
logic [N_CORES-1:0][1:0] evt;

`OBI_TYPEDEF_A_CHAN_T(redmule_complex_a_chan_t, AddrWidth, SysDataWidth, ID_WIDTH, logic)
`OBI_TYPEDEF_R_CHAN_T(redmule_complex_r_chan_t, SysDataWidth, ID_WIDTH, logic)
`OBI_TYPEDEF_REQ_T(redmule_complex_req_t, redmule_complex_a_chan_t)
`OBI_TYPEDEF_RSP_T(redmule_complex_rsp_t, redmule_complex_r_chan_t)

redmule_complex_req_t core_data_req, core_data_req_cut;
redmule_complex_rsp_t core_data_rsp, core_data_rsp_cut;
redmule_complex_req_t core_inst_req, core_inst_req_cut;
redmule_complex_rsp_t core_inst_rsp, core_inst_rsp_cut;

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

localparam obi_pkg::obi_cfg_t LocalObiCfg = '{
  UseRReady: 1'b0,
  CombGnt:   1'b0,
  AddrWidth: AddrWidth,
  DataWidth: SysDataWidth,
  IdWidth:   ID_WIDTH,
  Integrity: 1'b0,
  BeFull:    1'b1,
  OptionalCfg: '{default: '0}
};

obi_cut #(
  .ObiCfg       ( LocalObiCfg              ),
  .obi_a_chan_t ( redmule_complex_a_chan_t ),
  .obi_r_chan_t ( redmule_complex_r_chan_t ),
  .obi_req_t    ( redmule_complex_req_t    ),
  .obi_rsp_t    ( redmule_complex_rsp_t    ),
  .Bypass       ( 1'b0                     ),
  .BypassReq    ( 1'b0                     ),
  .BypassRsp    ( 1'b0                     )
) i_obi_data_cut (
  .clk_i,
  .rst_ni,
  .sbr_port_req_i ( core_data_req     ),
  .sbr_port_rsp_o ( core_data_rsp     ),
  .mgr_port_req_o ( core_data_req_cut ),
  .mgr_port_rsp_i ( core_data_rsp_cut )
);
assign core_data_req_o.req  = core_data_req_cut.req;
assign core_data_req_o.addr = core_data_req_cut.a.addr;
assign core_data_req_o.we   = core_data_req_cut.a.we;
assign core_data_req_o.be   = core_data_req_cut.a.be;
assign core_data_req_o.data = core_data_req_cut.a.wdata;
assign core_data_rsp_cut.gnt     = core_data_rsp_i.gnt;
assign core_data_rsp_cut.r.rdata = core_data_rsp_i.data;
assign core_data_rsp_cut.rvalid  = core_data_rsp_i.valid;

obi_cut #(
  .ObiCfg       ( LocalObiCfg              ),
  .obi_a_chan_t ( redmule_complex_a_chan_t ),
  .obi_r_chan_t ( redmule_complex_r_chan_t ),
  .obi_req_t    ( redmule_complex_req_t    ),
  .obi_rsp_t    ( redmule_complex_rsp_t    ),
  .Bypass       ( 1'b0                     ),
  .BypassReq    ( 1'b0                     ),
  .BypassRsp    ( 1'b0                     )
) i_obi_instr_cut (
  .clk_i,
  .rst_ni,
  .sbr_port_req_i ( core_inst_req     ),
  .sbr_port_rsp_o ( core_inst_rsp     ),
  .mgr_port_req_o ( core_inst_req_cut ),
  .mgr_port_rsp_i ( core_inst_rsp_cut )
);
assign core_inst_req_o.req  = core_inst_req_cut.req;
assign core_inst_req_o.addr = core_inst_req_cut.a.addr;
assign core_inst_rsp_cut.gnt     = core_inst_rsp_i.gnt;
assign core_inst_rsp_cut.r.rdata = core_inst_rsp_i.data;
assign core_inst_rsp_cut.rvalid  = core_inst_rsp_i.valid;

  if (CoreType == CV32P) begin: gen_cv32e40p

    typedef enum logic [NumDemuxIdx-1:0] {
      ExternalId = 'h0,
      RedMulEId  = 'h1
    } local_demux_ids_e;

    typedef struct packed {
      logic [NumDemuxIdx-1:0] idx;
      logic [  AddrWidth-1:0] start_addr;
      logic [  AddrWidth-1:0] end_addr;
    } addr_map_rule_t;

    localparam addr_map_rule_t [NumDemuxRules-1:0] LocalAddrMap = '{
       // Before Accelerator
      '{idx: ExternalId, start_addr: 'h00000000,
                         end_addr: RedMulERegionStartAddr},
      // Accelerator configuration port
      '{idx: RedMulEId, start_addr: RedMulERegionStartAddr,
                        end_addr: RedMulERegionStartAddr + RedMulERegionSize},
      // After Accelerator
      '{idx: ExternalId, start_addr: RedMulERegionStartAddr + RedMulERegionSize,
                         end_addr: 'hFFFFFFFF}
    };

    redmule_complex_req_t core_local_data_req;
    redmule_complex_rsp_t core_local_data_rsp;
    redmule_complex_req_t [NumDemuxIdx-1:0] target_data_req;
    redmule_complex_rsp_t [NumDemuxIdx-1:0] target_data_rsp;

  `ifdef CV32E40P_TRACE_EXECUTION
    cv32e40p_wrapper #(
  `else
    cv32e40p_core #(
  `endif
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
      .instr_req_o         ( core_inst_req.req     ),
      .instr_addr_o        ( core_inst_req.a.addr  ),
      .instr_gnt_i         ( core_inst_rsp.gnt     ),
      .instr_rvalid_i      ( core_inst_rsp.rvalid  ),
      .instr_rdata_i       ( core_inst_rsp.r.rdata ),
      // Data memory interface
      .data_req_o          ( core_local_data_req.req     ),
      .data_we_o           ( core_local_data_req.a.we    ),
      .data_be_o           ( core_local_data_req.a.be    ),
      .data_addr_o         ( core_local_data_req.a.addr  ),
      .data_wdata_o        ( core_local_data_req.a.wdata ),
      .data_gnt_i          ( core_local_data_rsp.gnt     ),
      .data_rvalid_i       ( core_local_data_rsp.rvalid  ),
      .data_rdata_i        ( core_local_data_rsp.r.rdata ),
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
      .irq_i               ({27'd0, evt, 3'd0} ),  // CLINT interrupts + CLINT extension interrupts
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
    // Tie to 0 unused buses
    assign core_local_data_req.rready = '0;
    assign core_local_data_req.a.aid = '0;
    assign core_local_data_req.a.a_optional = '0;
    assign core_inst_req.a.we = '0;
    assign core_inst_req.a.be = '0;
    assign core_inst_req.a.wdata = '0;

    logic [$clog2(NumDemuxIdx)-1:0] target_sel, default_idx;
    assign default_idx = '0;
    addr_decode #(
      .NoIndices ( NumDemuxIdx           ),
      .NoRules   ( NumDemuxRules         ),
      .addr_t    ( logic [AddrWidth-1:0] ),
      .rule_t    ( addr_map_rule_t       )
    ) i_addr_decode (
      .addr_i          ( core_local_data_req.a.addr ),
      .addr_map_i      ( LocalAddrMap               ),
      .idx_o           ( target_sel                 ),
      .dec_valid_o     ( ),
      .dec_error_o     ( ),
      .en_default_idx_i( 1'b1                       ),
      .default_idx_i   ( default_idx                )
    );

    obi_demux #(
      .ObiCfg      ( LocalObiCfg           ),
      .obi_req_t   ( redmule_complex_req_t ),
      .obi_rsp_t   ( redmule_complex_rsp_t ),
      .NumMgrPorts ( NumDemuxIdx           ),
      .NumMaxTrans ( 1                     )
    ) i_demux (
      .clk_i,
      .rst_ni,
      .sbr_port_select_i ( target_sel          ),
      .sbr_port_req_i    ( core_local_data_req ),
      .sbr_port_rsp_o    ( core_local_data_rsp ),
      .mgr_ports_req_o   ( target_data_req     ),
      .mgr_ports_rsp_i   ( target_data_rsp     )
    );

    // Bind redmule config bus to HWPE Control interface
    assign periph.req            = target_data_req[1].req;
    assign periph.add            = target_data_req[1].a.addr;
    assign periph.wen            = ~target_data_req[1].a.we;
    assign periph.be             = target_data_req[1].a.be;
    assign periph.data           = target_data_req[1].a.wdata;
    assign periph.id             = target_data_req[1].a.aid;
    assign target_data_rsp[1].gnt     = periph.gnt;
    assign target_data_rsp[1].r.rdata = periph.r_data;
    assign target_data_rsp[1].rvalid  = periph.r_valid;

    assign core_data_req = target_data_req[0];
    assign target_data_rsp[0] = core_data_rsp;

    // Kill Xif on the coprocessor side
    // We do not tie to 0 the Xif bus here because Design Compiler
    // complains when interfaces hierarchy is driven by hand. Also
    // Questasim complains but raises just a warning (not an error).
  end else if (CoreType == CV32X) begin: gen_cv32e40x
  `ifdef CV32E40X_TRACE_EXECUTION
    cv32e40x_wrapper #(
  `else
    cv32e40x_core #(
  `endif
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
      .clk_i               ( s_clk                   ),
      .rst_ni              ( rst_ni                  ),
      .scan_cg_en_i        ( 1'b0                    ),  // Enable all clock gates for testing
      // Core ID, Cluster ID, debug mode halt address and boot address are considered more or less static
      .boot_addr_i         ( boot_addr_i             ),
      .dm_exception_addr_i ( '0                      ),
      .dm_halt_addr_i      ( '0                      ),
      .mhartid_i           ( '0                      ),
      .mimpid_patch_i      ( '0                      ),
      .mtvec_addr_i        ( '0                      ),
      // Instruction memory interface
      .instr_req_o         ( core_inst_req.req      ),
      .instr_gnt_i         ( core_inst_rsp.gnt      ),
      .instr_rvalid_i      ( core_inst_rsp.rvalid   ),
      .instr_addr_o        ( core_inst_req.a.addr   ),
      .instr_memtype_o     (                         ),
      .instr_prot_o        (                         ),
      .instr_dbg_o         (                         ),
      .instr_rdata_i       ( core_inst_rsp.r.rdata  ),
      .instr_err_i         ( '0                      ),
      // Data memory interface
      .data_req_o          ( core_data_req.req       ),
      .data_gnt_i          ( core_data_rsp.gnt       ),
      .data_rvalid_i       ( core_data_rsp.rvalid    ),
      .data_addr_o         ( core_data_req.a.addr    ),
      .data_be_o           ( core_data_req.a.be      ),
      .data_we_o           ( core_data_req.a.we      ),
      .data_wdata_o        ( core_data_req.a.wdata   ),
      .data_memtype_o      (                         ),
      .data_prot_o         (                         ),
      .data_dbg_o          (                         ),
      .data_atop_o         (                         ),
      .data_rdata_i        ( core_data_rsp.r.rdata   ),
      .data_err_i          ( '0                      ),
      .data_exokay_i       ( '1                      ),
      // Cycle, Time
      .mcycle_o            (                         ),
      .time_i              ( '0                      ),
      // eXtension interface
      .xif_compressed_if   ( core_xif.cpu_compressed ),
      .xif_issue_if        ( core_xif.cpu_issue      ),
      .xif_commit_if       ( core_xif.cpu_commit     ),
      .xif_mem_if          ( core_xif.cpu_mem        ),
      .xif_mem_result_if   ( core_xif.cpu_mem_result ),
      .xif_result_if       ( core_xif.cpu_result     ),
      // Basic interrupt architecture
      .irq_i               ( {27'd0, evt, 3'd0}      ),
      // Event wakeup signals
      .wu_wfe_i            ( '0                      ), // Wait-for-event wakeup
      // CLIC interrupt architecture
      .clic_irq_i          ( '0                      ),
      .clic_irq_id_i       ( '0                      ),
      .clic_irq_level_i    ( '0                      ),
      .clic_irq_priv_i     ( '0                      ),
      .clic_irq_shv_i      ( '0                      ),
      // Fence.i flush handshake
      .fencei_flush_req_o  (                         ),
      .fencei_flush_ack_i  ( '0                      ),
      // Debug Interface
      .debug_req_i         ( '0                      ),
      .debug_havereset_o   (                         ),
      .debug_running_o     (                         ),
      .debug_halted_o      (                         ),
      .debug_pc_valid_o    (                         ),
      .debug_pc_o          (                         ),
      // CPU Control Signals
      .fetch_enable_i      ( fetch_enable_i          ),
      .core_sleep_o        ( core_sleep_o            )
    );
    assign core_data_req.rready = '0;
    assign core_data_req.a.aid = '0;
    assign core_data_req.a.a_optional = '0;
    assign core_inst_req.a.we = '0;
    assign core_inst_req.a.be = '0;
    assign core_inst_req.a.wdata = '0;

    // Kill coprocessor periph interface
    assign periph.req  = '0;
    assign periph.add  = '0;
    assign periph.wen  = '0;
    assign periph.be   = '0;
    assign periph.data = '0;
    assign periph.id   = '0;
  end else if (CoreType == Ibex) begin: gen_ibex
    $error("Ibex connection not yet implemented");
  end else begin: gen_cva6
    $error("CVA6 connection not yet implemented");
  end

logic redmule_clk;
tc_clk_gating redmule_clock_gating (
  .clk_i     ( clk_i            ),
  .en_i      ( redmule_clk_en_i ),
  .test_en_i ( test_mode_i      ),
  .clk_o     ( redmule_clk      )
);

redmule_top #(
  .ID_WIDTH           ( ID_WIDTH              ),
  .N_CORES            ( N_CORES               ),
  .DW                 ( DW                    ),
  .X_EXT              ( XExt                  ),
  .SysInstWidth       ( SysInstWidth          ),
  .SysDataWidth       ( SysDataWidth          )
) i_redmule_top       (
  .clk_i              ( redmule_clk                ),
  .rst_ni             ( rst_ni                     ),
  .test_mode_i        ( test_mode_i                ),
  .evt_o              ( evt                        ),
  .busy_o             ( busy                       ),
  .tcdm               ( tcdm                       ),
  .xif_issue_if_i     ( core_xif.coproc_issue      ),
  .xif_result_if_o    ( core_xif.coproc_result     ),
  .xif_compressed_if_i( core_xif.coproc_compressed ),
  .xif_mem_if_o       ( core_xif.coproc_mem        ),
  .periph             ( periph                     )
);

endmodule: redmule_complex
