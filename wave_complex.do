onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/clk_i
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/rst_ni
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/test_mode_i
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/fetch_enable_i
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/boot_addr_i
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/irq_i
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/irq_id_o
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/irq_ack_o
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/core_sleep_o
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/core_inst_rsp_i
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/core_inst_req_o
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/core_data_rsp_i
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/core_data_req_o
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/redmule_data_rsp_i
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/redmule_data_req_o
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/busy
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/s_clk
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/s_clk_en
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/evt
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/core_inst_req
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/core_inst_rsp
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/core_data_req
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/core_data_rsp
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/redmule_ctrl_req
add wave -noupdate -expand -group complex_core /redmule_complex_tb/i_dut/redmule_ctrl_rsp
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/clk_i
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/rst_ni
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/test_mode_i
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/busy_o
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/evt_o
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/data_req_o
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/data_rsp_i
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/fsm_z_clk_en
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/ctrl_z_clk_en
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/enable
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/clear
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/soft_clear
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/y_buffer_depth_count
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/y_buffer_load
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/z_buffer_fill
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/z_buffer_store
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/w_shift
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/w_load
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/reg_enable
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/gate_en
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/w_cols_lftovr
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/y_cols_lftovr
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/w_rows_lftovr
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/y_rows_lftovr
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/cntrl_streamer
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/flgs_streamer
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/cntrl_engine
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/x_buffer_ctrl
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/x_buffer_flgs
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/w_buffer_ctrl
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/w_buffer_flgs
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/z_buffer_ctrl
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/z_buffer_flgs
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/cntrl_scheduler
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/flgs_scheduler
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/reg_file
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/w_fifo_flgs
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/x_buffer_clk_en
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/x_buffer_clock
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/x_buffer_q
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/w_buffer_q
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/z_buffer_d
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/y_bias_q
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/ctrl_engine
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/flgs_engine
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/accumulate
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/engine_flush
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/fma_is_boxed
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/noncomp_is_boxed
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/stage1_rnd
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/stage2_rnd
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/op1
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/op2
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/op_mod
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/in_tag
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/in_aux
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/in_valid
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/in_ready
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/flush
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/status
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/extension_bit
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/class_mask
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/is_class
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/out_tag
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/out_aux
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/out_valid
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/out_ready
add wave -noupdate -expand -group complex_core -group redmule /redmule_complex_tb/i_dut/i_redmule_top/busy
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/clk_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/rst_ni
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/pulp_clock_en_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/scan_cg_en_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/boot_addr_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mtvec_addr_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/dm_halt_addr_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/hart_id_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/dm_exception_addr_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/instr_req_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/instr_gnt_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/instr_rvalid_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/instr_addr_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/instr_rdata_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_req_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_gnt_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_rvalid_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_we_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_be_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_addr_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_wdata_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_rdata_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_req_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_gnt_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_operands_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_op_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_flags_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_rvalid_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_result_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_flags_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/irq_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/irq_ack_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/irq_id_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/debug_req_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/debug_havereset_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/debug_running_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/debug_halted_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/fetch_enable_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/core_sleep_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_atop_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/irq_sec_i
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/sec_lvl_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/instr_valid_id
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/instr_rdata_id
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/is_compressed_id
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/illegal_c_insn_id
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/is_fetch_failed_id
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/clear_instr_valid
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/pc_set
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/pc_mux_id
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/exc_pc_mux_id
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/m_exc_vec_pc_mux_id
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/u_exc_vec_pc_mux_id
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/exc_cause
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/trap_addr_mux
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/pc_if
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/pc_id
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/is_decoding
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/useincr_addr_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_misaligned
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mult_multicycle
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/jump_target_id
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/jump_target_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/branch_in_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/branch_decision
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/ctrl_busy
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/if_busy
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/lsu_busy
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_busy
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/pc_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/alu_en_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/alu_operator_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/alu_operand_a_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/alu_operand_b_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/alu_operand_c_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/bmask_a_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/bmask_b_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/imm_vec_ext_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/alu_vec_mode_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/alu_is_clpx_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/alu_is_subrot_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/alu_clpx_shift_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mult_operator_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mult_operand_a_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mult_operand_b_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mult_operand_c_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mult_en_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mult_sel_subword_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mult_signed_mode_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mult_imm_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mult_dot_op_a_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mult_dot_op_b_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mult_dot_op_c_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mult_dot_signed_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mult_is_clpx_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mult_clpx_shift_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mult_clpx_img_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/frm_csr
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/fflags_csr
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/fflags_we
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_en_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_flags_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_op_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_lat_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_operands_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_waddr_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_read_regs
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_read_regs_valid
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_read_dep
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_write_regs
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_write_regs_valid
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_write_dep
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/perf_apu_type
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/perf_apu_cont
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/perf_apu_dep
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/perf_apu_wb
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/regfile_waddr_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/regfile_we_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/regfile_waddr_fw_wb_o
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/regfile_we_wb
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/regfile_wdata
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/regfile_alu_waddr_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/regfile_alu_we_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/regfile_alu_waddr_fw
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/regfile_alu_we_fw
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/regfile_alu_wdata_fw
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_access_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_op_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mtvec
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/utvec
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mtvec_mode
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/utvec_mode
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_op
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_addr
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_addr_int
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_rdata
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_wdata
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/current_priv_lvl
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_we_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_atop_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_type_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_sign_ext_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_reg_offset_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_req_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_load_event_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_misaligned_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/p_elw_start
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/p_elw_finish
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/lsu_rdata
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/halt_if
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/id_ready
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/ex_ready
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/id_valid
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/ex_valid
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/wb_valid
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/lsu_ready_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/lsu_ready_wb
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/apu_ready_wb
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/instr_req_int
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/m_irq_enable
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/u_irq_enable
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_irq_sec
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mepc
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/uepc
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/depc
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mie_bypass
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mip
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_save_cause
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_save_if
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_save_id
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_save_ex
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_cause
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_restore_mret_id
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_restore_uret_id
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_restore_dret_id
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_mtvec_init
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mcounteren
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/debug_mode
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/debug_cause
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/debug_csr_save
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/debug_single_step
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/debug_ebreakm
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/debug_ebreaku
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/trigger_match
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/debug_p_elw_no_sleep
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/hwlp_start
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/hwlp_end
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/hwlp_cnt
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/hwlp_target
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/hwlp_jump
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_hwlp_regid
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_hwlp_we
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/csr_hwlp_data
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mhpmevent_minstret
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mhpmevent_load
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mhpmevent_store
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mhpmevent_jump
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mhpmevent_branch
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mhpmevent_branch_taken
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mhpmevent_compressed
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mhpmevent_jr_stall
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mhpmevent_imiss
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mhpmevent_ld_stall
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/mhpmevent_pipe_stall
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/perf_imiss
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/wake_from_sleep
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/pmp_addr
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/pmp_cfg
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_req_pmp
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_addr_pmp
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_gnt_pmp
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_err_pmp
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/data_err_ack
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/instr_req_pmp
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/instr_gnt_pmp
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/instr_addr_pmp
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/instr_err_pmp
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/clk
add wave -noupdate -expand -group complex_core -group core /redmule_complex_tb/i_dut/gen_cv32e40p/i_core/fetch_enable
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {142000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 215
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
WaveRestoreZoom {28563476 ps} {28585818 ps}
