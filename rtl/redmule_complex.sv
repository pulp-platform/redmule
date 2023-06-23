module redmule_complex 
  import fpnew_pkg::*;
  import hci_package::*;
  import redmule_pkg::*;
  import hwpe_ctrl_package::*;
  import hwpe_stream_package::*;
#(
  parameter  core_type_e   CoreType        = CV32                 , // CV32E40P, IBEX, SNITCH, CVA6
  parameter  int unsigned  ID_WIDTH        = 8                    ,
  parameter  int unsigned  N_CORES         = 8                    ,
  parameter  int unsigned  DW              = DATA_W               , // TCDM port dimension (in bits)
  parameter  int unsigned  MP              = DW/redmule_pkg::MemDw,
  parameter  int unsigned  NumIrqs         = 32                   ,
  parameter  int unsigned  AddrWidth       = 32                   ,
  parameter      type      core_data_req_t = logic                ,
  parameter      type      core_data_rsp_t = logic                ,
  parameter      type      core_inst_req_t = logic                ,
  parameter      type      core_inst_rsp_t = logic                ,
  parameter      type      redmule_req_t   = logic                ,
  parameter      type      redmule_rsp_t   = logic                ,
  localparam fp_format_e   FpFormat    = FPFORMAT                 , // Data format (default is FP16)
  localparam int unsigned  Height      = ARRAY_HEIGHT             , // Number of PEs within a row
  localparam int unsigned  Width       = ARRAY_WIDTH              , // Number of parallel rows
  localparam int unsigned  NumPipeRegs = PIPE_REGS                , // Number of pipeline registers within each PE 
  localparam pipe_config_t PipeConfig  = DISTRIBUTED              ,
  localparam int unsigned  BITW        = fp_width(FpFormat)         // Number of bits for the given format
)(
  input  logic                         clk_i        ,
  input  logic                         rst_ni       ,
  input  logic                         test_mode_i  ,
  input  logic                         fetch_en_i   ,
  input  logic    [     AddrWidth-1:0] boot_addr_i  ,
  input  logic    [        NumIrq-1:0] irq_i        ,
  output logic    [$clog2(NumIrq)-1:0] irq_id_o     ,
  output logic                         irq_ack_o    ,
  input  core_inst_rsp_t               inst_rsp_i   ,
  output core_inst_req_t               inst_req_o   ,
  input  core_data_rsp_t               data_rsp_i   ,
  output core_data_req_t               data_req_o   ,
  input  redmule_rsp_t                 redmule_rsp_i,
  output redmule_req_t                 redmule_req_o
);

logic evt;
logic busy;
logic s_clk, s_clk_en;
hci_core_intf #(.DW(DW)) tcdm (.clk(clk_i));
hwpe_ctrl_intf_periph #(.ID_WIDTH(ID_WIDTH)) periph (.clk(clk_i));

always_ff @(posedge clk_i or negedge rst_ni) begin: clock_enable
  if (~rst_ni)
    s_clk_en <= 1'b0;
  else
    s_clk_en <= fetch_en_i;
end

tc_clk_gating sys_clock_gating (
  .clk_i     ( clk_i       ),
  .en_i      ( s_clk_en    ),
  .test_en_i ( test_mode_i ),
  .clk_o     ( s_clk       )
);

redmule_top #(
  .ID_WIDTH     ( ID_WIDTH     ),
  .N_CORES      ( N_CORES      ),
  .DW           ( DW           )
) i_redmule_top (
  .clk_i        ( s_clck       ),
  .rst_ni       ( rst_ni       ),
  .test_mode_i  ( test_mode_i  ),
  .evt_o        ( evt          ),
  .busy_o       ( busy         ),
  .tcdm         ( tcdm         ),
  .periph       ( periph       )
);

generate
  if (CoreType == CV32) begin: gen_cv32e40p
    cv32e40p_core #(
      .PULP_XPULP     ( PULP_XPULP ),
      .FPU            ( FPU        ),
      .PULP_ZFINX     ( PULP_ZFINX )
    ) i_cv32e40p_core (
      // Clock and Reset
      .clk_i               ( s_clk             ),
      .rst_ni              ( rst_ni            ),
      .pulp_clock_en_i     ( s_clk_en          ),  // PULP clock enable (only used if PULP_CLUSTER = 1)
      .scan_cg_en_i        ( 1'b0              ),  // Enable all clock gates for testing
      // Core ID, Cluster ID, debug mode halt address and boot address are considered more or less static
      .boot_addr_i         ( boot_addr_i       ),
      .mtvec_addr_i        ( '0                ),
      .dm_halt_addr_i      ( '0                ),
      .hart_id_i           ( '0                ),
      .dm_exception_addr_i ( '0                ),
      // Instruction memory interface
      .instr_req_o         ( instr_req         ),
      .instr_gnt_i         ( instr_gnt         ),
      .instr_rvalid_i      ( instr_rvalid      ),
      .instr_addr_o        ( instr_addr        ),
      .instr_rdata_i       ( instr_rdata       ),
      // Data memory interface
      .data_req_o          ( data_req          ),
      .data_gnt_i          ( data_gnt          ),
      .data_rvalid_i       ( data_rvalid       ),
      .data_we_o           ( data_we           ),
      .data_be_o           ( data_be           ),
      .data_addr_o         ( data_addr         ),
      .data_wdata_o        ( data_wdata        ),
      .data_rdata_i        ( data_rdata        ),
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
      .irq_i               ({28'd0 ,evt, 3'd0} ),  // CLINT interrupts + CLINT extension interrupts
      .irq_ack_o           (                   ),
      .irq_id_o            (                   ),
      // Debug Interface
      .debug_req_i         ( '0                ),
      .debug_havereset_o   (                   ),
      .debug_running_o     (                   ),
      .debug_halted_o      (                   ),
      // CPU Control Signals
      .fetch_enable_i      ( fetch_enable_i    ),
      .core_sleep_o        (                   )
    );
  end else if (CoreType == Ibex) begin: gen_ibex
  
  end else if (CoreType == Snitch) begin: gen_snitch
    snitch #(
      .AddrWidth              (),
      .DataWidth              (),
      .RVE                    (),
      .Xdma                   (),
      .Xssr                   (),
      .FP_EN                  (),
      .RVF                    (),
      .RVD                    (),
      .XF16                   (),
      .XF16ALT                (),
      .XF8                    (),
      .XF8ALT                 (),
      .XDivSqrt               (),
      .XFVEC                  (),
      .XFDOTP                 (),
      .XFAUX                  (),
      .FLEN                   (),
      .VMSupport              (),
      .Xipu                   (),
      .dreq_t                 (),
      .drsp_t                 (),
      .acc_req_t              (),
      .acc_resp_t             (),
      .pa_t                   (),
      .l0_pte_t               (),
      .NumIntOutstandingLoads (),
      .NumIntOutstandingMem   (),
      .NumDTLBEntries         (),
      .NumITLBEntries         (),
      .SnitchPMACfg           (),
      .addr_t                 (),
      .data_t                 ()
    ) snitch (
      .clk_i           (),
      .rst_i           (),
      .hart_id_i       (),
      .boot_addr_i     (),
      .irq_i           (),
      .flush_i_valid_o (),
      .flush_i_ready_i (),
      .inst_addr_o     (),
      .inst_cacheable_o(),
      .inst_data_i     (),
      .inst_valid_o    (),
      .inst_ready_i    (),
      .acc_qreq_o      (),
      .acc_qvalid_o    (),
      .acc_qready_i    (),
      .acc_prsp_i      (),
      .acc_pvalid_i    (),
      .acc_pready_o    (),
      .data_req_o      (),
      .data_rsp_i      (),
      .ptw_valid_o     (),
      .ptw_ready_i     (),
      .ptw_va_o        (),
      .ptw_ppn_o       (),
      .ptw_pte_i       (),
      .ptw_is_4mega_i  (),
      .fpu_rnd_mode_o  (),
      .fpu_fmt_mode_o  (),
      .fpu_status_i    (),
      .core_events_o   ()
    );
  end else begin: gen_cva6

  end
endgenerate

endmodule: redmule_complex
