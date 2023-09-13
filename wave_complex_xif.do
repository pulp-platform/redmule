onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/clk_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/rst_ni
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/scan_cg_en_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/boot_addr_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/dm_exception_addr_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/dm_halt_addr_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mhartid_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mimpid_patch_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mtvec_addr_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/instr_req_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/instr_gnt_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/instr_rvalid_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/instr_addr_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/instr_memtype_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/instr_prot_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/instr_dbg_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/instr_rdata_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/instr_err_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/data_req_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/data_gnt_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/data_rvalid_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/data_addr_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/data_be_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/data_we_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/data_wdata_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/data_memtype_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/data_prot_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/data_dbg_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/data_atop_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/data_rdata_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/data_err_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/data_exokay_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mcycle_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/time_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/irq_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wu_wfe_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/clic_irq_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/clic_irq_id_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/clic_irq_level_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/clic_irq_priv_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/clic_irq_shv_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/fencei_flush_req_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/fencei_flush_ack_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/debug_req_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/debug_havereset_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/debug_running_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/debug_halted_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/debug_pc_valid_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/debug_pc_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/fetch_enable_i
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/core_sleep_o
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/clk
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/fetch_enable
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/pc_if
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ptr_in_if
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/priv_lvl_if
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/jump_target_id
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/branch_target_ex
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/branch_decision_ex
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_busy
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_busy
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_bus_busy
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_interruptible
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_ex_pipe
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_wb_pipe
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_id_pipe
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ctrl_byp
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ctrl_fsm
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/debug_req_gated
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/rf_we_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/rf_waddr_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/rf_wdata_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/rf_wdata_ex
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/last_op_if
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/last_op_id
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/last_op_ex
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/last_op_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/abort_op_if
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/abort_op_id
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/abort_op_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/first_op_id
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/rf_re_id
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mtvec_addr
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mtvec_mode
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/jvt_addr
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/jvt_mode
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mtvt_addr
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mintthresh_th
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mintstatus
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mcause
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/csr_rdata
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/csr_counter_read
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/csr_wr_in_wb_flush
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/csr_irq_enable_write
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/priv_lvl
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/csr_mnxti_read
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/csr_clic_pa_valid
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/csr_clic_pa
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_split_ex
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_first_op_ex
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_last_op_ex
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_atomic_ex
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_mpu_status_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_wpt_match_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_align_status_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_rdata_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_err_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_atomic_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_valid_0
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_ready_ex
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_valid_ex
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_ready_0
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_valid_1
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_ready_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_valid_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_ready_1
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_addr_ex
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_we_ex
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/lsu_be_ex
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/data_stall_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wpt_match_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mpu_status_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/align_status_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_ready
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_ready
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_ready
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_valid
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_valid
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_valid
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_valid
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mstatus
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mepc
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/dpc
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mie
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mip
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/csr_mtvec_init_if
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/dcsr
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/trigger_match_if
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/trigger_match_ex
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/etrigger_wb
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/alu_jmp_id
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/alu_jmpr_id
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/alu_en_id
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sys_en_id
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sys_mret_insn_id
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/csr_en_raw_id
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/csr_illegal
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/xif_csr_error_ex
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/irq_req_ctrl
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/irq_id_ctrl
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/irq_wu_ctrl
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/irq_clic_shv
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/irq_clic_level
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/irq_clic_priv
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mnxti_irq_pending
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mnxti_irq_id
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/mnxti_irq_level
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/irq_ack
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/irq_id
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/irq_level
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/irq_priv
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/irq_shv
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/dbg_ack
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/xif_offloading_id
add wave -noupdate -group core -group top /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/unused_signals
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/compressed_valid
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/compressed_ready
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/compressed_req
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/compressed_resp
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/issue_valid
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/issue_ready
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/issue_req
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/issue_resp
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/commit_valid
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/commit
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/mem_valid
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/mem_ready
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/mem_req
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/mem_resp
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/mem_result_valid
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/mem_result
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/result_valid
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/result_ready
add wave -noupdate -group core -group x_if /redmule_complex_tb/i_dut/core_xif/result
add wave -noupdate -group core -group sleep_unit /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sleep_unit_i/clk_ungated_i
add wave -noupdate -group core -group sleep_unit /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sleep_unit_i/rst_n
add wave -noupdate -group core -group sleep_unit /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sleep_unit_i/clk_gated_o
add wave -noupdate -group core -group sleep_unit /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sleep_unit_i/scan_cg_en_i
add wave -noupdate -group core -group sleep_unit /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sleep_unit_i/core_sleep_o
add wave -noupdate -group core -group sleep_unit /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sleep_unit_i/fetch_enable_i
add wave -noupdate -group core -group sleep_unit /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sleep_unit_i/fetch_enable_o
add wave -noupdate -group core -group sleep_unit /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sleep_unit_i/if_busy_i
add wave -noupdate -group core -group sleep_unit /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sleep_unit_i/lsu_busy_i
add wave -noupdate -group core -group sleep_unit /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sleep_unit_i/ctrl_fsm_i
add wave -noupdate -group core -group sleep_unit /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sleep_unit_i/fetch_enable_q
add wave -noupdate -group core -group sleep_unit /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sleep_unit_i/fetch_enable_d
add wave -noupdate -group core -group sleep_unit /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sleep_unit_i/core_busy_q
add wave -noupdate -group core -group sleep_unit /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sleep_unit_i/core_busy_d
add wave -noupdate -group core -group sleep_unit /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/sleep_unit_i/clock_en
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/clk
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/rst_n
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/boot_addr_i
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/branch_target_ex_i
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/dm_exception_addr_i
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/dm_halt_addr_i
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/dpc_i
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/jump_target_id_i
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/mepc_i
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/mtvec_addr_i
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/jvt_mode_i
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/mtvt_addr_i
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/ctrl_fsm_i
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/trigger_match_i
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/if_id_pipe_o
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/pc_if_o
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/csr_mtvec_init_o
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/if_busy_o
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/ptr_in_if_o
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/priv_lvl_if_o
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/last_op_o
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/abort_op_o
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/if_valid_o
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/id_ready_i
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/xif_offloading_id_i
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/if_ready
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/prefetch_busy
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/branch_addr_n
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/prefetch_valid
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/prefetch_ready
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/prefetch_instr
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/prefetch_priv_lvl
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/prefetch_is_clic_ptr
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/prefetch_is_mret_ptr
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/prefetch_is_tbljmp_ptr
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/illegal_c_insn
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/instr_decompressed
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/instr_compressed
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/prefetch_resp_valid
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/prefetch_trans_valid
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/prefetch_trans_ready
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/prefetch_trans_addr
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/prefetch_inst_resp
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/prefetch_one_txn_pend_n
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/prefetch_outstnd_cnt_q
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/bus_resp_valid
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/bus_resp
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/bus_trans_valid
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/bus_trans_ready
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/bus_trans
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/core_trans
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/instr_valid
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/xif_id
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/predec_ready
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/seq_valid
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/seq_ready
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/seq_instr_valid
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/seq_first
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/seq_last
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/seq_instr
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/seq_tbljmp
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/seq_pushpop
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/first_op
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/unused_signals
add wave -noupdate -group core -group if_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/if_stage_i/instr_meta_n
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/clk
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/rst_n
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/jmp_target_o
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/if_id_pipe_i
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/id_ex_pipe_o
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/ex_wb_pipe_i
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/ctrl_byp_i
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/ctrl_fsm_i
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/mcause_i
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/jvt_addr_i
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/rf_wdata_wb_i
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/rf_wdata_ex_i
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/alu_jmp_o
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/alu_jmpr_o
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/sys_mret_insn_o
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/csr_en_raw_o
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/alu_en_o
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/sys_en_o
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/first_op_o
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/last_op_o
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/abort_op_o
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/rf_re_o
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/id_ready_o
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/id_valid_o
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/ex_ready_i
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/xif_offloading_o
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/instr
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/rf_re
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/rf_we
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/rf_we_dec
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/rf_waddr
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/rf_illegal_raddr
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/alu_en
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/alu_bch
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/alu_jmp
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/alu_jmpr
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/alu_operator
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/mul_en
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/mul_operator
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/mul_signed_mode
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/div_en
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/div_operator
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/lsu_en
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/lsu_we
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/lsu_size
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/lsu_sext
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/lsu_atop
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/csr_en
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/csr_en_raw
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/csr_op
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/sys_en
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/sys_fence_insn
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/sys_fencei_insn
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/sys_ecall_insn
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/sys_ebrk_insn
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/sys_mret_insn
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/sys_dret_insn
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/sys_wfi_insn
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/sys_wfe_insn
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/operand_a
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/operand_b
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/operand_c
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/operand_a_fw
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/operand_b_fw
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/jalr_fw
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/alu_op_a_mux_sel
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/alu_op_b_mux_sel
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/op_c_mux_sel
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/imm_a_mux_sel
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/imm_b_mux_sel
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/bch_jmp_mux_sel
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/imm_a
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/imm_b
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/imm_i_type
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/imm_s_type
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/imm_sb_type
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/imm_u_type
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/imm_uj_type
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/imm_z_type
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/bch_target
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/illegal_insn
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/instr_valid
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/xif_en
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/xif_waiting
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/xif_insn_accept
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/xif_insn_reject
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/xif_we
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/xif_exception
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/xif_dualwrite
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/xif_loadstore
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/tbljmp_first
add wave -noupdate -group core -group id_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/id_stage_i/jvt_index
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/clk
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/rst_n
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/id_ex_pipe_i
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/csr_rdata_i
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/csr_illegal_i
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/csr_mnxti_read_i
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/ex_wb_pipe_o
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/ctrl_fsm_i
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/rf_wdata_o
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/branch_decision_o
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/branch_target_o
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/xif_csr_error_o
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/lsu_valid_i
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/lsu_ready_o
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/lsu_valid_o
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/lsu_ready_i
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/lsu_split_i
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/lsu_last_op_i
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/lsu_first_op_i
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/ex_ready_o
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/ex_valid_o
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/wb_ready_i
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/last_op_o
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/instr_valid
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/alu_ready
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/alu_valid
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/csr_ready
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/csr_valid
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/sys_ready
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/sys_valid
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/mul_ready
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/mul_valid
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/div_ready
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/div_valid
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/xif_ready
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/xif_valid
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/alu_result
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/alu_cmp_result
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/mul_result
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/div_result
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/lsu_en_gated
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/div_en
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/div_clz_en
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/div_clz_data_rev
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/div_clz_result
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/div_shift_en
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/div_shift_amt
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/div_op_b_shifted
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/first_op
add wave -noupdate -group core -group exe_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/ex_stage_i/csr_is_illegal
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/clk
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/rst_n
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/ctrl_fsm_i
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/id_ex_pipe_i
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/busy_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/bus_busy_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/interruptible_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/trigger_match_0_i
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/lsu_split_0_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/lsu_first_op_0_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/lsu_last_op_0_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/lsu_atomic_0_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/lsu_addr_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/lsu_we_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/lsu_be_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/lsu_err_1_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/lsu_rdata_1_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/lsu_mpu_status_1_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/lsu_wpt_match_1_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/lsu_align_status_1_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/lsu_atomic_1_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/valid_0_i
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/ready_0_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/valid_0_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/ready_0_i
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/valid_1_i
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/ready_1_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/valid_1_o
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/ready_1_i
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/trans
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/trans_valid
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/trans_ready
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/wpt_trans_valid
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/wpt_trans_ready
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/wpt_trans_pushpop
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/wpt_trans
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/alcheck_trans_valid
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/alcheck_trans_ready
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/alcheck_trans
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/mpu_trans_valid
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/mpu_trans_ready
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/mpu_trans_pushpop
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/mpu_trans_atomic
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/mpu_trans
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/resp_valid
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/resp_rdata
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/resp
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/wpt_resp_valid
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/wpt_resp_rdata
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/wpt_resp
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/alcheck_resp_valid
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/alcheck_resp
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/mpu_resp_valid
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/mpu_resp
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/buffer_trans_valid
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/buffer_trans_ready
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/buffer_trans
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/filter_trans_valid
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/filter_trans_ready
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/filter_trans
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/filter_resp_valid
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/filter_resp
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/bus_trans_valid
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/bus_trans_ready
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/bus_trans
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/bus_resp_valid
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/bus_resp
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/cnt_q
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/next_cnt
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/count_up
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/count_down
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/cnt_is_one_next
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/ctrl_update
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/lsu_size_q
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/lsu_sext_q
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/lsu_we_q
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/rdata_offset_q
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/last_q
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/be
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/wdata
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/split_q
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/misaligned_access
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/filter_resp_busy
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/rdata_q
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/done_0
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/trans_valid_q
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/xif_req
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/xif_mpu_err
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/xif_wpt_match
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/xif_ready_1
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/xif_res_q
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/xif_id_q
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/align_check_en
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/consumer_resp_wait
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/rdata_ext
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/rdata_full
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/rdata_aligned
add wave -noupdate -group core -group LSU /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/load_store_unit_i/rdata_is_split
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/clk
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/rst_n
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/ex_wb_pipe_i
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/ctrl_fsm_i
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_rdata_i
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_mpu_status_i
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_wpt_match_i
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_align_status_i
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/rf_we_wb_o
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/rf_waddr_wb_o
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/rf_wdata_wb_o
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_valid_i
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_ready_o
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_valid_o
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_ready_i
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/data_stall_o
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/wb_ready_o
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/wb_valid_o
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/wpt_match_wb_o
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/mpu_status_wb_o
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/align_status_wb_o
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/clic_pa_i
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/clic_pa_valid_i
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/last_op_o
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/abort_op_o
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/instr_valid
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/wb_valid
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_exception
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/xif_waiting
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/xif_exception
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_mpu_status_q
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_wpt_match_q
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_align_status_q
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_valid_q
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_mpu_status
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_wpt_match
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_align_status
add wave -noupdate -group core -group wb_stage /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/wb_stage_i/lsu_valid
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/clk
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/rst_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mhartid_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mimpid_patch_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mtvec_addr_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/csr_mtvec_init_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dcsr_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dpc_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/jvt_addr_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/jvt_mode_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mcause_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mcycle_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mepc_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mie_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mintstatus_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mintthresh_th_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mstatus_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mtvec_addr_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mtvec_mode_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mtvt_addr_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/priv_lvl_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/id_ex_pipe_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/csr_illegal_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/ex_wb_pipe_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/ctrl_fsm_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/csr_counter_read_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/csr_mnxti_read_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/csr_rdata_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mip_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mnxti_irq_pending_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mnxti_irq_id_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mnxti_irq_level_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/clic_pa_valid_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/clic_pa_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/csr_irq_enable_write_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/time_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/csr_wr_in_wb_flush_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/pc_if_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/ptr_in_if_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/priv_lvl_if_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/trigger_match_if_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/trigger_match_ex_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/etrigger_wb_o
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/lsu_valid_ex_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/lsu_addr_ex_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/lsu_we_ex_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/lsu_be_ex_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/lsu_atomic_ex_i
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/csr_wdata_int
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/csr_rdata_int
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/csr_we_int
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/csr_op
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/csr_waddr
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/csr_raddr
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/csr_wdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/csr_en_gated
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/illegal_csr_read
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/illegal_csr_write
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/instr_valid
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/unused_signals
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mepc_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mepc_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mepc_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mepc_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/tselect_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/tselect_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/tdata1_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/tdata1_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/tdata2_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/tdata2_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/tinfo_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/tinfo_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dcsr_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dcsr_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dcsr_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dcsr_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dpc_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dpc_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dpc_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dpc_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dscratch0_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dscratch0_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dscratch0_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dscratch0_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dscratch1_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dscratch1_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dscratch1_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/dscratch1_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mscratch_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mscratch_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mscratch_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mscratch_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/jvt_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/jvt_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/jvt_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/jvt_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mstatus_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mstatus_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mstatus_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mstatus_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mstatush_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mstatush_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mstatush_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/misa_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/misa_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/misa_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mcause_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mcause_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mcause_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mcause_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mtvec_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mtvec_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mtvec_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mtvec_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mtvt_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mtvt_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mtvt_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mtvt_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mnxti_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mnxti_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mnxti_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mintstatus_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mintstatus_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mintstatus_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mintstatus_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mintthresh_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mintthresh_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mintthresh_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mintthresh_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mscratchcswl_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mscratchcswl_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mscratchcswl_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mip_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mip_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mip_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mie_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mie_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mie_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mie_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mvendorid_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mvendorid_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mvendorid_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/marchid_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/marchid_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/marchid_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mimpid_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mimpid_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mimpid_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mhartid_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mhartid_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mhartid_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mconfigptr_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mconfigptr_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mconfigptr_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mtval_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mtval_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mtval_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/priv_lvl_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/priv_lvl_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/priv_lvl_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/priv_lvl_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/csr_wr_in_wb
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/jvt_wr_in_wb
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mcause_alias_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mstatus_alias_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mhpmcounter_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mhpmcounter_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mhpmcounter_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mhpmcounter_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mhpmevent_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mhpmevent_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mhpmevent_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mcountinhibit_q
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mcountinhibit_n
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mcountinhibit_rdata
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/hpm_events
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mhpmcounter_increment
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mhpmcounter_write_lower
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mhpmcounter_write_upper
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mhpmcounter_write_increment
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mscratchcswl_in_wb
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mnxti_in_wb
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/hpm_events_raw
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/all_counters_disabled
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/debug_stopcount
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mcountinhibit_we
add wave -noupdate -group core -group cs_registers /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/cs_registers_i/mhpmevent_we
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/clk
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/rst_n
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/fetch_enable_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/if_valid_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/pc_if_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/last_op_if_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/abort_op_if_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/if_id_pipe_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/alu_jmp_id_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/alu_jmpr_id_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/alu_en_id_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/sys_en_id_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/sys_mret_id_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/csr_en_raw_id_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/first_op_id_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/last_op_id_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/abort_op_id_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/id_ex_pipe_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/ex_wb_pipe_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/mpu_status_wb_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/wpt_match_wb_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/align_status_wb_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/last_op_ex_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/last_op_wb_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/abort_op_wb_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/data_stall_wb_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/lsu_err_wb_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/lsu_busy_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/lsu_bus_busy_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/lsu_interruptible_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/lsu_valid_wb_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/lsu_atomic_ex_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/lsu_atomic_wb_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/branch_decision_ex_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/irq_req_ctrl_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/irq_id_ctrl_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/irq_wu_ctrl_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/irq_clic_shv_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/irq_clic_level_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/irq_clic_priv_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/wu_wfe_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/mtvec_mode_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/mcause_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/mintstatus_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/etrigger_wb_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/csr_wr_in_wb_flush_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/debug_req_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/dcsr_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/csr_counter_read_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/csr_mnxti_read_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/csr_irq_enable_write_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/rf_re_id_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/id_ready_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/id_valid_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/ex_ready_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/ex_valid_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/wb_ready_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/wb_valid_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/ctrl_byp_o
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/ctrl_fsm_o
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/fencei_flush_req_o
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/fencei_flush_ack_i
add wave -noupdate -group core -group controller /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/controller_i/xif_csr_error_i
add wave -noupdate -group core -group RF_wrap /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/register_file_wrapper_i/clk
add wave -noupdate -group core -group RF_wrap /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/register_file_wrapper_i/rst_n
add wave -noupdate -group core -group RF_wrap /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/register_file_wrapper_i/raddr_i
add wave -noupdate -group core -group RF_wrap /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/register_file_wrapper_i/rdata_o
add wave -noupdate -group core -group RF_wrap /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/register_file_wrapper_i/waddr_i
add wave -noupdate -group core -group RF_wrap /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/register_file_wrapper_i/wdata_i
add wave -noupdate -group core -group RF_wrap /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/register_file_wrapper_i/we_i
add wave -noupdate -group core -group RF_wrap -group RF /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/register_file_wrapper_i/register_file_i/clk
add wave -noupdate -group core -group RF_wrap -group RF /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/register_file_wrapper_i/register_file_i/rst_n
add wave -noupdate -group core -group RF_wrap -group RF /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/register_file_wrapper_i/register_file_i/raddr_i
add wave -noupdate -group core -group RF_wrap -group RF /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/register_file_wrapper_i/register_file_i/rdata_o
add wave -noupdate -group core -group RF_wrap -group RF /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/register_file_wrapper_i/register_file_i/waddr_i
add wave -noupdate -group core -group RF_wrap -group RF /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/register_file_wrapper_i/register_file_i/wdata_i
add wave -noupdate -group core -group RF_wrap -group RF /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/register_file_wrapper_i/register_file_i/we_i
add wave -noupdate -group core -group RF_wrap -group RF /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/register_file_wrapper_i/register_file_i/mem
add wave -noupdate -group core -group RF_wrap -group RF /redmule_complex_tb/i_dut/gen_cv32e40x/i_core/register_file_wrapper_i/register_file_i/we_dec
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/clk_i
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/rst_ni
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/test_mode_i
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/busy_o
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/evt_o
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/data_req_o
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/data_rsp_i
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/fsm_z_clk_en
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/ctrl_z_clk_en
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/enable
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/clear
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/soft_clear
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/y_buffer_depth_count
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/y_buffer_load
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/z_buffer_fill
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/z_buffer_store
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/w_shift
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/w_load
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/reg_enable
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/gate_en
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/w_cols_lftovr
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/y_cols_lftovr
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/w_rows_lftovr
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/y_rows_lftovr
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/cntrl_streamer
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/flgs_streamer
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/cntrl_engine
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/x_buffer_ctrl
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/x_buffer_flgs
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/w_buffer_ctrl
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/w_buffer_flgs
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/z_buffer_ctrl
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/z_buffer_flgs
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/cntrl_scheduler
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/flgs_scheduler
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/reg_file
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/w_fifo_flgs
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/x_buffer_clk_en
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/x_buffer_clock
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/x_buffer_q
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/w_buffer_q
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/z_buffer_d
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/y_bias_q
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/ctrl_engine
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/flgs_engine
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/accumulate
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/engine_flush
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/fma_is_boxed
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/noncomp_is_boxed
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/stage1_rnd
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/stage2_rnd
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/op1
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/op2
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/op_mod
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/in_tag
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/in_aux
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/in_valid
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/in_ready
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/flush
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/status
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/extension_bit
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/class_mask
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/is_class
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/out_tag
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/out_aux
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/out_valid
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/out_ready
add wave -noupdate -group redmule -group top /redmule_complex_tb/i_dut/i_redmule_top/busy
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/compressed_valid
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/compressed_ready
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/compressed_req
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/compressed_resp
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/issue_valid
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/issue_ready
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/issue_req
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/issue_resp
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/commit_valid
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/commit
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/mem_valid
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/mem_ready
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/mem_req
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/mem_resp
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/mem_result_valid
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/mem_result
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/result_valid
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/result_ready
add wave -noupdate -group redmule -group instr_decoder -group x_if /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/xif_issue_if_i/result
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/clk_i
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/rst_ni
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/clear_i
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/cfg_req_o
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/cfg_rsp_i
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/start_cfg_o
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/op_code
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/operation_d
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/format_d
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/cfg_reg_d
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/cfg_reg_q
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/is_gemm_d
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/widening_d
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/custom_fmt_d
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/cfg_ready
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/count_rst
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/count_update
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/reg_offs
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/current
add wave -noupdate -group redmule -group instr_decoder /redmule_complex_tb/i_dut/i_redmule_top/i_inst_decoder/next
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/clk_i
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/rst_ni
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/clear_o
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/ctrl_i
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/flags_o
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/reg_file
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/regfile_in
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/regfile_out
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/running_state
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/context_state
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/regfile_flags
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/offloading_core
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/pointer_context
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/running_context
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/counter_pending
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/s_enable_after
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/s_clear
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/s_clear_regfile
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/clear_regfile
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/triggered_q
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/context_addr
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/ext_access
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/ext_id_n
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/cfg_id_d
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/cfg_id_q
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/cfg_req_d
add wave -noupdate -group redmule -group control -group slave /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_slave/cfg_req_q
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/clk_i
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/rst_ni
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/clear_i
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/setback_i
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/start_cfg_i
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/reg_file_i
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/valid_o
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/reg_file_o
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/clk_en
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/clk_int
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/config_d
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/config_q
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/x_rows_iter_nolftovr
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/x_cols_iter_nolftovr
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/w_cols_iter_nolftovr
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/x_rows_by_w_cols_iter
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/x_rows_by_w_cols_iter_valid
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/x_rows_by_w_cols_iter_valid_d
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/x_rows_by_w_cols_iter_valid_q
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/x_rows_by_w_cols_iter_ready
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/x_rows_by_w_cols_by_x_cols_iter
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/x_rows_by_w_cols_by_x_cols_iter_valid
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/x_rows_by_w_cols_by_x_cols_iter_ready
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/x_rows_by_w_cols_by_w_rows_iter
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/x_rows_by_w_cols_by_w_rows_iter_valid
add wave -noupdate -group redmule -group control -group cfg_tiler /redmule_complex_tb/i_dut/i_redmule_top/i_control/i_cfg_tiler/x_rows_by_w_cols_by_w_rows_iter_ready
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/clk_i
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/rst_ni
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/test_mode_i
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/busy_o
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/clear_o
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/evt_o
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/z_fill_o
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/w_shift_o
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/z_buffer_clk_en_o
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/reg_file_o
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/reg_enable_i
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/start_cfg_i
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/flgs_z_buffer_i
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/flgs_engine_i
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/w_loaded_i
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/flush_o
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/accumulate_o
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/cntrl_scheduler_o
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/clear
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/accumulate_q
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/w_computed_en
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/w_computed_rst
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/count_w_q
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/accumulate_en
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/accumulate_rst
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/storing_rst
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/last_w_row
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/last_w_row_en
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/last_w_row_rst
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/z_buffer_clk_en
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/enable_depth_count
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/reset_depth_count
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/tiler_valid
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/w_computed
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/w_rows
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/w_rows_iter
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/w_row_count_d
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/w_row_count_q
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/z_storings_d
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/z_storings_q
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/tot_stores
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/current
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/next
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/reg_file_d
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/reg_file_q
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/cntrl_slave
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/flgs_slave
add wave -noupdate -group redmule -group control /redmule_complex_tb/i_dut/i_redmule_top/i_control/accumulate_ctrl_q
add wave -noupdate -group redmule -group streamer -group top /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/clk_i
add wave -noupdate -group redmule -group streamer -group top /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/rst_ni
add wave -noupdate -group redmule -group streamer -group top /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/test_mode_i
add wave -noupdate -group redmule -group streamer -group top /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/enable_i
add wave -noupdate -group redmule -group streamer -group top /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/clear_i
add wave -noupdate -group redmule -group streamer -group top /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/ctrl_i
add wave -noupdate -group redmule -group streamer -group top /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/flags_o
add wave -noupdate -group redmule -group streamer -group top /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/cast
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/clk_i
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/rst_ni
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/test_mode_i
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/clear_i
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/enable_i
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/ctrl_i
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/flags_o
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/cs
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/ns
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/addr_fifo_flags
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/done
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/address_gen_en
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/address_gen_clr
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/stream_valid_q
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/stream_data_q
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/addr_misaligned_q
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/addr_misaligned_valid
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/stream_data_misaligned
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/stream_data_aligned
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/stream_cnt_en
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/stream_cnt_clr
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/stream_cnt_d
add wave -noupdate -group redmule -group streamer -group x_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_x_stream_source/stream_cnt_q
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/clk_i
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/rst_ni
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/test_mode_i
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/clear_i
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/enable_i
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/ctrl_i
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/flags_o
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/cs
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/ns
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/addr_fifo_flags
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/done
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/address_gen_en
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/address_gen_clr
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/stream_valid_q
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/stream_data_q
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/addr_misaligned_q
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/addr_misaligned_valid
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/stream_data_misaligned
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/stream_data_aligned
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/stream_cnt_en
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/stream_cnt_clr
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/stream_cnt_d
add wave -noupdate -group redmule -group streamer -group w_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_w_stream_source/stream_cnt_q
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/clk_i
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/rst_ni
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/test_mode_i
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/clear_i
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/enable_i
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/ctrl_i
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/flags_o
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/cs
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/ns
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/addr_fifo_flags
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/done
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/address_gen_en
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/address_gen_clr
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/stream_valid_q
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/stream_data_q
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/addr_misaligned_q
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/addr_misaligned_valid
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/stream_data_misaligned
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/stream_data_aligned
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/stream_cnt_en
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/stream_cnt_clr
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/stream_cnt_d
add wave -noupdate -group redmule -group streamer -group y_source /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_y_stream_source/stream_cnt_q
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/clk_i
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/rst_ni
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/test_mode_i
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/clear_i
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/enable_i
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/ctrl_i
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/flags_o
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/cs
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/ns
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/addr_fifo_flags
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/address_gen_en
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/address_gen_clr
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/done
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/tcdm_inflight
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/address_cnt_en
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/address_cnt_clr
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/address_cnt_d
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/address_cnt_q
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/stream_data_misaligned
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/stream_strb_misaligned
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/stream_data_aligned
add wave -noupdate -group redmule -group streamer -group z_sink /redmule_complex_tb/i_dut/i_redmule_top/i_streamer/i_z_stream_sink/stream_strb_aligned
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/clk_i
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/rst_ni
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/clear_i
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/ctrl_i
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/flags_o
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/x_buffer_o
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/x_buffer_i
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/rst_w_load
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/rst_d_shift
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/rst_h_shift
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/empty_rst
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/w_index
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/w_limit
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/h_index
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/d_shift
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/empty_count
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/empty_count_q
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/depth
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/x_pad_q
add wave -noupdate -group redmule -group x_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_x_buffer/x_buffer_q
add wave -noupdate -group redmule -group w_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_w_buffer/clk_i
add wave -noupdate -group redmule -group w_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_w_buffer/rst_ni
add wave -noupdate -group redmule -group w_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_w_buffer/clear_i
add wave -noupdate -group redmule -group w_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_w_buffer/ctrl_i
add wave -noupdate -group redmule -group w_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_w_buffer/flags_o
add wave -noupdate -group redmule -group w_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_w_buffer/w_buffer_o
add wave -noupdate -group redmule -group w_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_w_buffer/w_buffer_i
add wave -noupdate -group redmule -group w_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_w_buffer/w_row
add wave -noupdate -group redmule -group w_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_w_buffer/count_limit
add wave -noupdate -group redmule -group w_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_w_buffer/depth
add wave -noupdate -group redmule -group w_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_w_buffer/w_buffer_q
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/clk_i
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/rst_ni
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/clear_i
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/reg_enable_i
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/ctrl_i
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/z_buffer_i
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/y_buffer_i
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/z_buffer_o
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/y_buffer_o
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/flags_o
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/rst_store
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/rst_fill
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/rst_w_load
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/rst_d_count
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/buffer_clock
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/fill_shift
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/d_index
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/depth
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/store_shift
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/w_index
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/y_width
add wave -noupdate -group redmule -group z_buffer /redmule_complex_tb/i_dut/i_redmule_top/i_z_buffer/z_buffer_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/clk_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/rst_ni
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/test_mode_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/clear_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_valid_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_strb_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_valid_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_strb_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_fifo_valid_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_fifo_strb_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/z_ready_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/accumulate_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/engine_flush_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/reg_file_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/flgs_streamer_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/flgs_x_buffer_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/flgs_w_buffer_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/flgs_z_buffer_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/flgs_engine_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/fifo_flgs_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/cntrl_scheduler_i
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/z_strb_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/soft_clear_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_load_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_cols_lftovr_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_rows_lftovr_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_cols_lftovr_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_rows_lftovr_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/gate_en_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_buffer_clk_en_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/z_buffer_clk_en_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/reg_enable_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/z_store_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_buffer_load_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/cntrl_engine_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/cntrl_streamer_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/cntrl_x_buffer_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/flgs_scheduler_o
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/clear_regs
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/loading_x_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/loading_y_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/load_x_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/load_y_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/hold_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/hold_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_push_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_loaded_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/h_shift_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/wait_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/load_x_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/load_y_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/transfer_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/hold_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_rows_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_cols_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_push_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/consume_y_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/consume_y_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/consume_y_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_preloaded_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_preloaded_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_preloaded_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/count_w_cycles_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/count_w_cycles_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/count_w_cycles_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_preloaded_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_preloaded_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_preloaded_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/last_store
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/last_store_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/last_store_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/store_cols_lftovr_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/store_cols_lftovr_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/store_cols_lftovr_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/store_rows_lftovr_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/store_rows_lftovr_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/gate
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/gate_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/gate_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/gate_comb
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/shift_lock_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/shift_lock_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/shift_lock_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/reg_enable
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/shift_count_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_loaded
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_rows_lftovr_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_rows_lftovr_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_rows_clk_gate_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_cols_lftovr_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_cols_lftovr_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_rows_lftovr_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_rows_lftovr_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_push_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/skip_w_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/skip_w_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/skip_w_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/reg_disable
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/shift_disable
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/skipped_w_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_rows_lftovr_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_rows_lftovr_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/store_rows_lftovr_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/n_waits_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/n_waits_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/tot_x_loaded_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/tot_x_loaded_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/tot_y_loaded_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/tot_y_loaded_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/tot_z_stored_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/tot_z_stored_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/transfer_count_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/transfer_count_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_rows_offs_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_rows_offs_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_cols_offs_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_cols_offs_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_loaded_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_loaded_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_iters_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_iters_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/tot_w_loaded_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/tot_w_loaded_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/new_w_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/new_w_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_rows_iter_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_rows_iter_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_cols_iter_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_cols_iter_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_rows_iter_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_rows_iter_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_cols_iter_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_cols_iter_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_cols_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_cols_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/tot_x_read_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/tot_x_read_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/h_shift_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/h_shift_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/d_shift_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/d_shift_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_cols_lftovr_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_cols_lftovr_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_cols_lftovr_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_cols_lftovr_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_cycles_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_cols_lftovr
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/y_cols_lftovr_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_cols_lftovr_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_rows_lftovr
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/strb
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_slots_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/input_cast_src_fmt
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/input_cast_dst_fmt
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/output_cast_src_fmt
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/output_cast_dst_fmt
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/current
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/next
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/gate_count_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/gate_count_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/store_count_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/store_count_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/tot_store_d
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/tot_store_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/count_w_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/shift_count_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/counter_index
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/en_w
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/w_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/shift_comb
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/wlq
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/shift_comb_n
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/shift_comb_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/end_computation
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/pre_ready_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/pre_ready_rst
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/pre_ready_x_q
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/x_buffer_clk_en
add wave -noupdate -group redmule -group scheduler /redmule_complex_tb/i_dut/i_redmule_top/i_scheduler/z_buffer_clk_en
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 342
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {3193050 ps}
