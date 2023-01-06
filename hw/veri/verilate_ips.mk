RTL=/scratch/ytortorella/upstream-redmule-tb/redmule-tb/hw/rtl
IPS=/scratch/ytortorella/upstream-redmule-tb/redmule-tb/hw/ips

# common_cells_all
SRC_COMMON_CELLS_ALL= \
    ${IPS}/common_cells/src/binary_to_gray.sv \
    ${IPS}/common_cells/src/cb_filter_pkg.sv \
    ${IPS}/common_cells/src/cc_onehot.sv \
    ${IPS}/common_cells/src/cf_math_pkg.sv \
    ${IPS}/common_cells/src/clk_int_div.sv \
    ${IPS}/common_cells/src/delta_counter.sv \
    ${IPS}/common_cells/src/ecc_pkg.sv \
    ${IPS}/common_cells/src/edge_propagator_tx.sv \
    ${IPS}/common_cells/src/exp_backoff.sv \
    ${IPS}/common_cells/src/fifo_v3.sv \
    ${IPS}/common_cells/src/gray_to_binary.sv \
    ${IPS}/common_cells/src/isochronous_4phase_handshake.sv \
    ${IPS}/common_cells/src/isochronous_spill_register.sv \
    ${IPS}/common_cells/src/lfsr.sv \
    ${IPS}/common_cells/src/lfsr_16bit.sv \
    ${IPS}/common_cells/src/lfsr_8bit.sv \
    ${IPS}/common_cells/src/mv_filter.sv \
    ${IPS}/common_cells/src/onehot_to_bin.sv \
    ${IPS}/common_cells/src/plru_tree.sv \
    ${IPS}/common_cells/src/popcount.sv \
    ${IPS}/common_cells/src/rr_arb_tree.sv \
    ${IPS}/common_cells/src/rstgen_bypass.sv \
    ${IPS}/common_cells/src/serial_deglitch.sv \
    ${IPS}/common_cells/src/shift_reg.sv \
    ${IPS}/common_cells/src/spill_register_flushable.sv \
    ${IPS}/common_cells/src/stream_demux.sv \
    ${IPS}/common_cells/src/stream_filter.sv \
    ${IPS}/common_cells/src/stream_fork.sv \
    ${IPS}/common_cells/src/stream_intf.sv \
    ${IPS}/common_cells/src/stream_join.sv \
    ${IPS}/common_cells/src/stream_mux.sv \
    ${IPS}/common_cells/src/stream_throttle.sv \
    ${IPS}/common_cells/src/sub_per_hash.sv \
    ${IPS}/common_cells/src/sync.sv \
    ${IPS}/common_cells/src/sync_wedge.sv \
    ${IPS}/common_cells/src/unread.sv \
    ${IPS}/common_cells/src/read.sv \
    ${IPS}/common_cells/src/cdc_reset_ctrlr_pkg.sv \
    ${IPS}/common_cells/src/cdc_2phase.sv \
    ${IPS}/common_cells/src/cdc_4phase.sv \
    ${IPS}/common_cells/src/addr_decode.sv \
    ${IPS}/common_cells/src/addr_decode_napot.sv \
    ${IPS}/common_cells/src/cb_filter.sv \
    ${IPS}/common_cells/src/cdc_fifo_2phase.sv \
    ${IPS}/common_cells/src/counter.sv \
    ${IPS}/common_cells/src/ecc_decode.sv \
    ${IPS}/common_cells/src/ecc_encode.sv \
    ${IPS}/common_cells/src/edge_detect.sv \
    ${IPS}/common_cells/src/lzc.sv \
    ${IPS}/common_cells/src/max_counter.sv \
    ${IPS}/common_cells/src/rstgen.sv \
    ${IPS}/common_cells/src/spill_register.sv \
    ${IPS}/common_cells/src/stream_delay.sv \
    ${IPS}/common_cells/src/stream_fifo.sv \
    ${IPS}/common_cells/src/stream_fork_dynamic.sv \
    ${IPS}/common_cells/src/clk_mux_glitch_free.sv \
    ${IPS}/common_cells/src/cdc_reset_ctrlr.sv \
    ${IPS}/common_cells/src/cdc_fifo_gray.sv \
    ${IPS}/common_cells/src/fall_through_register.sv \
    ${IPS}/common_cells/src/id_queue.sv \
    ${IPS}/common_cells/src/stream_to_mem.sv \
    ${IPS}/common_cells/src/stream_arbiter_flushable.sv \
    ${IPS}/common_cells/src/stream_fifo_optimal_wrap.sv \
    ${IPS}/common_cells/src/stream_register.sv \
    ${IPS}/common_cells/src/stream_xbar.sv \
    ${IPS}/common_cells/src/cdc_fifo_gray_clearable.sv \
    ${IPS}/common_cells/src/cdc_2phase_clearable.sv \
    ${IPS}/common_cells/src/mem_to_banks.sv \
    ${IPS}/common_cells/src/stream_arbiter.sv \
    ${IPS}/common_cells/src/stream_omega_net.sv \
    ${IPS}/common_cells/src/deprecated/clock_divider.sv \
    ${IPS}/common_cells/src/deprecated/clock_divider_counter.sv \
    ${IPS}/common_cells/src/deprecated/find_first_one.sv \
    ${IPS}/common_cells/src/deprecated/generic_LFSR_8bit.sv \
    ${IPS}/common_cells/src/deprecated/generic_fifo.sv \
    ${IPS}/common_cells/src/deprecated/generic_fifo_adv.sv \
    ${IPS}/common_cells/src/deprecated/pulp_sync.sv \
    ${IPS}/common_cells/src/deprecated/pulp_sync_wedge.sv \
    ${IPS}/common_cells/src/deprecated/sram.sv \
    ${IPS}/common_cells/src/deprecated/fifo_v2.sv \
    ${IPS}/common_cells/src/deprecated/prioarbiter.sv \
    ${IPS}/common_cells/src/deprecated/rrarbiter.sv \
    ${IPS}/common_cells/src/deprecated/fifo_v1.sv \
    ${IPS}/common_cells/src/edge_propagator_ack.sv \
    ${IPS}/common_cells/src/edge_propagator.sv \
    ${IPS}/common_cells/src/edge_propagator_rx.sv \

INC_COMMON_CELLS_ALL= \
    -I${IPS}/common_cells/include \



# tech_cells_verilator
SRC_TECH_CELLS_VERILATOR= \
    ${IPS}/tech_cells_generic/src/cluster_clock_gating.sv \


# tech_cells_rtl_synth
SRC_TECH_CELLS_RTL_SYNTH= \
    ${IPS}/tech_cells_generic/src/pulp_sync.sv \
    ${IPS}/tech_cells_generic/src/pulp_clock_gating_async.sv \





# zeroriscy
SRC_ZERORISCY= \
    ${IPS}/zero-riscy/include/zeroriscy_defines.sv \
    ${IPS}/zero-riscy/include/zeroriscy_tracer_defines.sv \
    ${IPS}/zero-riscy/zeroriscy_alu.sv \
    ${IPS}/zero-riscy/zeroriscy_compressed_decoder.sv \
    ${IPS}/zero-riscy/zeroriscy_controller.sv \
    ${IPS}/zero-riscy/zeroriscy_cs_registers.sv \
    ${IPS}/zero-riscy/zeroriscy_debug_unit.sv \
    ${IPS}/zero-riscy/zeroriscy_decoder.sv \
    ${IPS}/zero-riscy/zeroriscy_int_controller.sv \
    ${IPS}/zero-riscy/zeroriscy_ex_block.sv \
    ${IPS}/zero-riscy/zeroriscy_id_stage.sv \
    ${IPS}/zero-riscy/zeroriscy_if_stage.sv \
    ${IPS}/zero-riscy/zeroriscy_load_store_unit.sv \
    ${IPS}/zero-riscy/zeroriscy_multdiv_slow.sv \
    ${IPS}/zero-riscy/zeroriscy_multdiv_fast.sv \
    ${IPS}/zero-riscy/zeroriscy_prefetch_buffer.sv \
    ${IPS}/zero-riscy/zeroriscy_fetch_fifo.sv \
    ${IPS}/zero-riscy/zeroriscy_core.sv \

INC_ZERORISCY= \
    -I${IPS}/zero-riscy/include \





# low_latency_interco
SRC_LOW_LATENCY_INTERCO= \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/FanInPrimitive_Req.sv \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/ArbitrationTree.sv \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/MUX2_REQ.sv \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/AddressDecoder_Resp.sv \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/TestAndSet.sv \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/RequestBlock2CH.sv \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/RequestBlock1CH.sv \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/FanInPrimitive_Resp.sv \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/ResponseTree.sv \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/ResponseBlock.sv \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/AddressDecoder_Req.sv \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/XBAR_TCDM.sv \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/XBAR_TCDM_WRAPPER.sv \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/TCDM_PIPE_REQ.sv \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/TCDM_PIPE_RESP.sv \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/grant_mask.sv \
    ${IPS}/cluster_interconnect/rtl/low_latency_interco/priority_Flag_Req.sv \

INC_LOW_LATENCY_INTERCO= \
    -I${IPS}/cluster_interconnect/rtl/low_latency_interco \


# peripheral_interco
SRC_PERIPHERAL_INTERCO= \
    ${IPS}/cluster_interconnect/rtl/peripheral_interco/AddressDecoder_PE_Req.sv \
    ${IPS}/cluster_interconnect/rtl/peripheral_interco/AddressDecoder_Resp_PE.sv \
    ${IPS}/cluster_interconnect/rtl/peripheral_interco/ArbitrationTree_PE.sv \
    ${IPS}/cluster_interconnect/rtl/peripheral_interco/FanInPrimitive_Req_PE.sv \
    ${IPS}/cluster_interconnect/rtl/peripheral_interco/RR_Flag_Req_PE.sv \
    ${IPS}/cluster_interconnect/rtl/peripheral_interco/MUX2_REQ_PE.sv \
    ${IPS}/cluster_interconnect/rtl/peripheral_interco/FanInPrimitive_PE_Resp.sv \
    ${IPS}/cluster_interconnect/rtl/peripheral_interco/RequestBlock1CH_PE.sv \
    ${IPS}/cluster_interconnect/rtl/peripheral_interco/RequestBlock2CH_PE.sv \
    ${IPS}/cluster_interconnect/rtl/peripheral_interco/ResponseBlock_PE.sv \
    ${IPS}/cluster_interconnect/rtl/peripheral_interco/ResponseTree_PE.sv \
    ${IPS}/cluster_interconnect/rtl/peripheral_interco/XBAR_PE.sv \

INC_PERIPHERAL_INTERCO= \
    -I${IPS}/cluster_interconnect/rtl/peripheral_interco \
    -I${IPS}/cluster_interconnect/../../rtl/includes \


# tcdm_interconnect
SRC_TCDM_INTERCONNECT= \
    ${IPS}/cluster_interconnect/rtl/tcdm_interconnect/tcdm_interconnect_pkg.sv \
    ${IPS}/cluster_interconnect/rtl/tcdm_interconnect/addr_dec_resp_mux.sv \
    ${IPS}/cluster_interconnect/rtl/tcdm_interconnect/amo_shim.sv \
    ${IPS}/cluster_interconnect/rtl/tcdm_interconnect/xbar.sv \
    ${IPS}/cluster_interconnect/rtl/tcdm_interconnect/clos_net.sv \
    ${IPS}/cluster_interconnect/rtl/tcdm_interconnect/bfly_net.sv \
    ${IPS}/cluster_interconnect/rtl/tcdm_interconnect/tcdm_interconnect.sv \


# hwpe-ctrl
SRC_HWPE_CTRL= \
    ${IPS}/hwpe-ctrl/rtl/hwpe_ctrl_package.sv \
    ${IPS}/hwpe-ctrl/rtl/hwpe_ctrl_interfaces.sv \
    ${IPS}/hwpe-ctrl/rtl/hwpe_ctrl_regfile.sv \
    ${IPS}/hwpe-ctrl/rtl/hwpe_ctrl_regfile_latch.sv \
    ${IPS}/hwpe-ctrl/rtl/hwpe_ctrl_regfile_latch_test_wrap.sv \
    ${IPS}/hwpe-ctrl/rtl/hwpe_ctrl_slave.sv \
    ${IPS}/hwpe-ctrl/rtl/hwpe_ctrl_seq_mult.sv \
    ${IPS}/hwpe-ctrl/rtl/hwpe_ctrl_uloop.sv \

INC_HWPE_CTRL= \
    -I${IPS}/hwpe-ctrl/rtl \



# hwpe-stream
SRC_HWPE_STREAM= \
    ${IPS}/hwpe-stream/rtl/hwpe_stream_package.sv \
    ${IPS}/hwpe-stream/rtl/hwpe_stream_interfaces.sv \
    ${IPS}/hwpe-stream/rtl/basic/hwpe_stream_assign.sv \
    ${IPS}/hwpe-stream/rtl/basic/hwpe_stream_mux_static.sv \
    ${IPS}/hwpe-stream/rtl/basic/hwpe_stream_demux_static.sv \
    ${IPS}/hwpe-stream/rtl/basic/hwpe_stream_buffer.sv \
    ${IPS}/hwpe-stream/rtl/basic/hwpe_stream_merge.sv \
    ${IPS}/hwpe-stream/rtl/basic/hwpe_stream_fence.sv \
    ${IPS}/hwpe-stream/rtl/basic/hwpe_stream_split.sv \
    ${IPS}/hwpe-stream/rtl/basic/hwpe_stream_serialize.sv \
    ${IPS}/hwpe-stream/rtl/basic/hwpe_stream_deserialize.sv \
    ${IPS}/hwpe-stream/rtl/fifo/hwpe_stream_fifo_earlystall_sidech.sv \
    ${IPS}/hwpe-stream/rtl/fifo/hwpe_stream_fifo_earlystall.sv \
    ${IPS}/hwpe-stream/rtl/fifo/hwpe_stream_fifo_scm.sv \
    ${IPS}/hwpe-stream/rtl/fifo/hwpe_stream_fifo_scm_test_wrap.sv \
    ${IPS}/hwpe-stream/rtl/fifo/hwpe_stream_fifo_sidech.sv \
    ${IPS}/hwpe-stream/rtl/fifo/hwpe_stream_fifo.sv \
    ${IPS}/hwpe-stream/rtl/fifo/hwpe_stream_fifo_ctrl.sv \
    ${IPS}/hwpe-stream/rtl/streamer/hwpe_stream_addressgen.sv \
    ${IPS}/hwpe-stream/rtl/streamer/hwpe_stream_addressgen_v2.sv \
    ${IPS}/hwpe-stream/rtl/streamer/hwpe_stream_addressgen_v3.sv \
    ${IPS}/hwpe-stream/rtl/streamer/hwpe_stream_strbgen.sv \
    ${IPS}/hwpe-stream/rtl/streamer/hwpe_stream_sink.sv \
    ${IPS}/hwpe-stream/rtl/streamer/hwpe_stream_sink_realign.sv \
    ${IPS}/hwpe-stream/rtl/streamer/hwpe_stream_source.sv \
    ${IPS}/hwpe-stream/rtl/streamer/hwpe_stream_source_realign.sv \
    ${IPS}/hwpe-stream/rtl/streamer/hwpe_stream_streamer_queue.sv \
    ${IPS}/hwpe-stream/rtl/tcdm/hwpe_stream_tcdm_fifo_load.sv \
    ${IPS}/hwpe-stream/rtl/tcdm/hwpe_stream_tcdm_fifo_load_sidech.sv \
    ${IPS}/hwpe-stream/rtl/tcdm/hwpe_stream_tcdm_fifo_store.sv \
    ${IPS}/hwpe-stream/rtl/tcdm/hwpe_stream_tcdm_fifo.sv \
    ${IPS}/hwpe-stream/rtl/tcdm/hwpe_stream_tcdm_assign.sv \
    ${IPS}/hwpe-stream/rtl/tcdm/hwpe_stream_tcdm_mux.sv \
    ${IPS}/hwpe-stream/rtl/tcdm/hwpe_stream_tcdm_mux_static.sv \
    ${IPS}/hwpe-stream/rtl/tcdm/hwpe_stream_tcdm_reorder.sv \
    ${IPS}/hwpe-stream/rtl/tcdm/hwpe_stream_tcdm_reorder_static.sv \

INC_HWPE_STREAM= \
    -I${IPS}/hwpe-stream/rtl \


# tb_hwpe_stream
SRC_TB_HWPE_STREAM= \
    ${IPS}/hwpe-stream/tb/tb_hwpe_stream_reservoir.sv \
    ${IPS}/hwpe-stream/tb/tb_hwpe_stream_receiver.sv \


# tb_hwpe_stream_local
SRC_TB_HWPE_STREAM_LOCAL= \
    ${IPS}/hwpe-stream/tb/tb_hwpe_stream_sink_realign.sv \
    ${IPS}/hwpe-stream/tb/tb_hwpe_stream_source_realign.sv \
    ${IPS}/hwpe-stream/tb/tb_hwpe_stream_source_realign_decoupled.sv \


# hci
SRC_HCI= \
    ${IPS}/hci/rtl/common/hci_package.sv \
    ${IPS}/hci/rtl/common/hci_interfaces.sv \
    ${IPS}/hci/rtl/interco/hci_log_interconnect.sv \
    ${IPS}/hci/rtl/interco/hci_log_interconnect_l2.sv \
    ${IPS}/hci/rtl/interco/hci_new_log_interconnect.sv \
    ${IPS}/hci/rtl/hci_interconnect.sv \
    ${IPS}/hci/rtl/interco/hci_hwpe_reorder.sv \
    ${IPS}/hci/rtl/interco/hci_hwpe_interconnect.sv \
    ${IPS}/hci/rtl/interco/hci_shallow_interconnect.sv \
    ${IPS}/hci/rtl/core/hci_core_fifo.sv \
    ${IPS}/hci/rtl/core/hci_core_assign.sv \
    ${IPS}/hci/rtl/core/hci_core_memmap_filter.sv \
    ${IPS}/hci/rtl/core/hci_core_memmap_demux_interl.sv \
    ${IPS}/hci/rtl/core/hci_core_sink.sv \
    ${IPS}/hci/rtl/core/hci_core_source.sv \
    ${IPS}/hci/rtl/core/hci_core_mux_static.sv \
    ${IPS}/hci/rtl/core/hci_core_mux_dynamic.sv \
    ${IPS}/hci/rtl/core/hci_core_load_store_mixer.sv \
    ${IPS}/hci/rtl/core/hci_core_r_valid_filter.sv \
    ${IPS}/hci/rtl/core/hci_core_cmd_queue.sv \
    ${IPS}/hci/rtl/core/hci_core_split.sv \
    ${IPS}/hci/rtl/mem/hci_mem_assign.sv \


# fpnew
SRC_FPNEW= \
    ${IPS}/fpnew/src/fpnew_pkg.sv \
    ${IPS}/fpnew/src/fpnew_cast_multi.sv \
    ${IPS}/fpnew/src/fpnew_classifier.sv \
    ${IPS}/fpnew/src/fpnew_divsqrt_multi.sv \
    ${IPS}/fpnew/src/fpnew_fma.sv \
    ${IPS}/fpnew/src/fpnew_fma_multi.sv \
    ${IPS}/fpnew/src/fpnew_noncomp.sv \
    ${IPS}/fpnew/src/fpnew_opgroup_block.sv \
    ${IPS}/fpnew/src/fpnew_opgroup_fmt_slice.sv \
    ${IPS}/fpnew/src/fpnew_opgroup_multifmt_slice.sv \
    ${IPS}/fpnew/src/fpnew_rounding.sv \
    ${IPS}/fpnew/src/fpnew_top.sv \

INC_FPNEW= \
    -I${IPS}/fpnew/../common_cells/include \


# redmule
SRC_REDMULE= \
    ${IPS}/redmule/rtl/redmule_pkg.sv \
    ${IPS}/redmule/rtl/redmule_ctrl.sv \
    ${IPS}/redmule/rtl/redmule_fsm.sv \
    ${IPS}/redmule/rtl/redmule_castin.sv \
    ${IPS}/redmule/rtl/redmule_castout.sv \
    ${IPS}/redmule/rtl/redmule_streamer.sv \
    ${IPS}/redmule/rtl/redmule_x_buffer.sv \
    ${IPS}/redmule/rtl/redmule_w_buffer.sv \
    ${IPS}/redmule/rtl/redmule_z_buffer.sv \
    ${IPS}/redmule/rtl/redmule_ce.sv \
    ${IPS}/redmule/rtl/redmule_row.sv \
    ${IPS}/redmule/rtl/redmule_engine.sv \
    ${IPS}/redmule/rtl/redmule_top.sv \
    ${IPS}/redmule/rtl/redmule_wrap.sv \

INC_REDMULE= \
    -I${IPS}/redmule/../hwpe-ctrl/rtl \
    -I${IPS}/redmule/../hwpe-stream/rtl \
    -I${IPS}/redmule/../hci/rtl \
    -I${IPS}/redmule/../fpnew/src \

INC_IPS=${INC_COMMON_CELLS_ALL} \
${INC_TECH_CELLS_VERILATOR} \
${INC_TECH_CELLS_RTL_SYNTH} \
${INC_ZERORISCY} \
${INC_LOW_LATENCY_INTERCO} \
${INC_PERIPHERAL_INTERCO} \
${INC_TCDM_INTERCONNECT} \
${INC_HWPE_CTRL} \
${INC_HWPE_STREAM} \
${INC_TB_HWPE_STREAM} \
${INC_TB_HWPE_STREAM_LOCAL} \
${INC_HCI} \
${INC_FPNEW} \
${INC_REDMULE} \


SRC_IPS=${SRC_COMMON_CELLS_ALL} \
${SRC_TECH_CELLS_VERILATOR} \
${SRC_TECH_CELLS_RTL_SYNTH} \
${SRC_ZERORISCY} \
${SRC_LOW_LATENCY_INTERCO} \
${SRC_PERIPHERAL_INTERCO} \
${SRC_TCDM_INTERCONNECT} \
${SRC_HWPE_CTRL} \
${SRC_HWPE_STREAM} \
${SRC_TB_HWPE_STREAM} \
${SRC_TB_HWPE_STREAM_LOCAL} \
${SRC_HCI} \
${SRC_FPNEW} \
${SRC_REDMULE} \
