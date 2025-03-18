# This script was generated automatically by bender.
set ROOT "/scratch/ope_pagonis/redmule-ope"

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "$ROOT/.bender/git/checkouts/common_verification-149a8baf816d0f55/src/clk_rst_gen.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-149a8baf816d0f55/src/sim_timeout.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-149a8baf816d0f55/src/stream_watchdog.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-149a8baf816d0f55/src/signal_highlighter.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "$ROOT/.bender/git/checkouts/common_verification-149a8baf816d0f55/src/rand_id_queue.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-149a8baf816d0f55/src/rand_stream_mst.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-149a8baf816d0f55/src/rand_synch_holdable_driver.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-149a8baf816d0f55/src/rand_verif_pkg.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-149a8baf816d0f55/src/rand_synch_driver.sv" \
    "$ROOT/.bender/git/checkouts/common_verification-149a8baf816d0f55/src/rand_stream_slv.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-9d9ba23d5bf3a109/src/rtl/tc_sram.sv" \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-9d9ba23d5bf3a109/src/rtl/tc_sram_impl.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-9d9ba23d5bf3a109/src/rtl/tc_clk.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-9d9ba23d5bf3a109/src/deprecated/cluster_pwr_cells.sv" \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-9d9ba23d5bf3a109/src/deprecated/generic_memory.sv" \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-9d9ba23d5bf3a109/src/deprecated/generic_rom.sv" \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-9d9ba23d5bf3a109/src/deprecated/pad_functional.sv" \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-9d9ba23d5bf3a109/src/deprecated/pulp_buffer.sv" \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-9d9ba23d5bf3a109/src/deprecated/pulp_pwr_cells.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-9d9ba23d5bf3a109/src/tc_pwr.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-9d9ba23d5bf3a109/src/deprecated/pulp_clock_gating_async.sv" \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-9d9ba23d5bf3a109/src/deprecated/cluster_clk_cells.sv" \
    "$ROOT/.bender/git/checkouts/tech_cells_generic-9d9ba23d5bf3a109/src/deprecated/pulp_clk_cells.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/include" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/binary_to_gray.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/include" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/cb_filter_pkg.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/cc_onehot.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/cdc_reset_ctrlr_pkg.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/cf_math_pkg.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/clk_int_div.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/credit_counter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/delta_counter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/ecc_pkg.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/edge_propagator_tx.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/exp_backoff.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/fifo_v3.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/gray_to_binary.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/isochronous_4phase_handshake.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/isochronous_spill_register.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/lfsr.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/lfsr_16bit.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/lfsr_8bit.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/lossy_valid_to_stream.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/mv_filter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/onehot_to_bin.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/plru_tree.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/passthrough_stream_fifo.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/popcount.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/rr_arb_tree.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/rstgen_bypass.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/serial_deglitch.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/shift_reg.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/shift_reg_gated.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/spill_register_flushable.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_demux.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_filter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_fork.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_intf.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_join_dynamic.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_mux.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_throttle.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/sub_per_hash.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/sync.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/sync_wedge.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/unread.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/read.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/addr_decode_dync.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/cdc_2phase.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/cdc_4phase.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/clk_int_div_static.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/addr_decode.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/addr_decode_napot.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/multiaddr_decode.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/include" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/cb_filter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/cdc_fifo_2phase.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/clk_mux_glitch_free.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/counter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/ecc_decode.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/ecc_encode.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/edge_detect.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/lzc.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/max_counter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/rstgen.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/spill_register.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_delay.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_fifo.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_fork_dynamic.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_join.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/cdc_reset_ctrlr.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/cdc_fifo_gray.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/fall_through_register.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/id_queue.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_to_mem.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_arbiter_flushable.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_fifo_optimal_wrap.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_register.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_xbar.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/cdc_fifo_gray_clearable.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/cdc_2phase_clearable.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/mem_to_banks_detailed.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_arbiter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/stream_omega_net.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/mem_to_banks.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/include" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/deprecated/sram.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/include" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/deprecated/clock_divider_counter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/deprecated/clk_div.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/deprecated/find_first_one.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/deprecated/generic_LFSR_8bit.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/deprecated/generic_fifo.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/deprecated/prioarbiter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/deprecated/pulp_sync.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/deprecated/pulp_sync_wedge.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/deprecated/rrarbiter.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/deprecated/clock_divider.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/deprecated/fifo_v2.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/deprecated/fifo_v1.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/edge_propagator_ack.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/edge_propagator.sv" \
    "$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/src/edge_propagator_rx.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/include" \
    "$ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-6f47e499794a44e3/hdl/defs_div_sqrt_mvp.sv" \
    "$ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-6f47e499794a44e3/hdl/iteration_div_sqrt_mvp.sv" \
    "$ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-6f47e499794a44e3/hdl/control_mvp.sv" \
    "$ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-6f47e499794a44e3/hdl/norm_div_sqrt_mvp.sv" \
    "$ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-6f47e499794a44e3/hdl/preprocess_mvp.sv" \
    "$ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-6f47e499794a44e3/hdl/nrbd_nrsc_mvp.sv" \
    "$ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-6f47e499794a44e3/hdl/div_sqrt_top_mvp.sv" \
    "$ROOT/.bender/git/checkouts/fpu_div_sqrt_mvp-6f47e499794a44e3/hdl/div_sqrt_mvp_wrapper.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco" \
    "+incdir+$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/peripheral_interco" \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/include" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/tcdm_interconnect/tcdm_interconnect_pkg.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/tcdm_interconnect/addr_dec_resp_mux.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/tcdm_interconnect/amo_shim.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/variable_latency_interconnect/addr_decoder.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/tcdm_interconnect/xbar.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/variable_latency_interconnect/simplex_xbar.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/tcdm_interconnect/clos_net.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/tcdm_interconnect/bfly_net.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/variable_latency_interconnect/full_duplex_xbar.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/tcdm_interconnect/tcdm_interconnect.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/variable_latency_interconnect/variable_latency_bfly_net.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/variable_latency_interconnect/variable_latency_interconnect.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/FanInPrimitive_Req.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/ArbitrationTree.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/MUX2_REQ.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/AddressDecoder_Resp.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/TestAndSet.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/RequestBlock2CH.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/RequestBlock1CH.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/FanInPrimitive_Resp.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/ResponseTree.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/ResponseBlock.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/AddressDecoder_Req.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/XBAR_TCDM.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/XBAR_TCDM_WRAPPER.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/TCDM_PIPE_REQ.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/TCDM_PIPE_RESP.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/grant_mask.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco/priority_Flag_Req.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/peripheral_interco/AddressDecoder_PE_Req.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/peripheral_interco/AddressDecoder_Resp_PE.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/peripheral_interco/ArbitrationTree_PE.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/peripheral_interco/FanInPrimitive_Req_PE.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/peripheral_interco/RR_Flag_Req_PE.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/peripheral_interco/MUX2_REQ_PE.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/peripheral_interco/FanInPrimitive_PE_Resp.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/peripheral_interco/RequestBlock1CH_PE.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/peripheral_interco/RequestBlock2CH_PE.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/peripheral_interco/ResponseBlock_PE.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/peripheral_interco/ResponseTree_PE.sv" \
    "$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/peripheral_interco/XBAR_PE.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/include" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/src/fpnew_pkg.sv" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/src/fpnew_cast_multi.sv" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/src/fpnew_classifier.sv" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/vendor/opene906/E906_RTL_FACTORY/gen_rtl/clk/rtl/gated_clk_cell.v" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_ctrl.v" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_ff1.v" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_pack_single.v" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_prepare.v" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_round_single.v" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_special.v" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_srt_single.v" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fdsu/rtl/pa_fdsu_top.v" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_dp.v" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_frbus.v" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/vendor/opene906/E906_RTL_FACTORY/gen_rtl/fpu/rtl/pa_fpu_src_type.v" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/src/fpnew_divsqrt_th_32.sv" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/src/fpnew_divsqrt_multi.sv" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/src/fpnew_fma.sv" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/src/fpnew_fma_multi.sv" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/src/fpnew_sdotp_multi.sv" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/src/fpnew_sdotp_multi_wrapper.sv" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/src/fpnew_noncomp.sv" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/src/fpnew_opgroup_block.sv" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/src/fpnew_opgroup_fmt_slice.sv" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/src/fpnew_opgroup_multifmt_slice.sv" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/src/fpnew_rounding.sv" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/src/lfsr_sr.sv" \
    "$ROOT/.bender/git/checkouts/fpnew-596368a327261645/src/fpnew_top.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/hwpe_stream_package.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/hwpe_stream_interfaces.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/basic/hwpe_stream_assign.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/basic/hwpe_stream_buffer.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/basic/hwpe_stream_demux_static.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/basic/hwpe_stream_deserialize.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/basic/hwpe_stream_fence.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/basic/hwpe_stream_merge.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/basic/hwpe_stream_mux_static.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/basic/hwpe_stream_serialize.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/basic/hwpe_stream_split.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/fifo/hwpe_stream_fifo_ctrl.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/fifo/hwpe_stream_fifo_scm.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/streamer/hwpe_stream_addressgen.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/streamer/hwpe_stream_addressgen_v2.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/streamer/hwpe_stream_addressgen_v3.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/streamer/hwpe_stream_sink_realign.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/streamer/hwpe_stream_source_realign.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/streamer/hwpe_stream_strbgen.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/streamer/hwpe_stream_streamer_queue.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/tcdm/hwpe_stream_tcdm_assign.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/tcdm/hwpe_stream_tcdm_mux.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/tcdm/hwpe_stream_tcdm_mux_static.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/tcdm/hwpe_stream_tcdm_reorder.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/tcdm/hwpe_stream_tcdm_reorder_static.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/fifo/hwpe_stream_fifo_earlystall.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/fifo/hwpe_stream_fifo_earlystall_sidech.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/fifo/hwpe_stream_fifo_scm_test_wrap.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/fifo/hwpe_stream_fifo_sidech.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/fifo/hwpe_stream_fifo.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/tcdm/hwpe_stream_tcdm_fifo_load_sidech.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/fifo/hwpe_stream_fifo_passthrough.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/streamer/hwpe_stream_source.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/tcdm/hwpe_stream_tcdm_fifo.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/tcdm/hwpe_stream_tcdm_fifo_load.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/tcdm/hwpe_stream_tcdm_fifo_store.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-stream-ab150de1021c0132/rtl/streamer/hwpe_stream_sink.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/l2_tcdm_demux.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/lint_2_apb.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/lint_2_axi.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/axi_2_lint/axi64_2_lint32.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/axi_2_lint/axi_read_ctrl.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/axi_2_lint/axi_write_ctrl.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/axi_2_lint/lint64_to_32.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_L2/AddressDecoder_Req_L2.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_L2/AddressDecoder_Resp_L2.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_L2/ArbitrationTree_L2.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_L2/FanInPrimitive_Req_L2.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_L2/FanInPrimitive_Resp_L2.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_L2/MUX2_REQ_L2.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_L2/RequestBlock_L2_1CH.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_L2/RequestBlock_L2_2CH.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_L2/ResponseBlock_L2.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_L2/ResponseTree_L2.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_L2/RR_Flag_Req_L2.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_L2/XBAR_L2.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_BRIDGE/AddressDecoder_Req_BRIDGE.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_BRIDGE/AddressDecoder_Resp_BRIDGE.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_BRIDGE/ArbitrationTree_BRIDGE.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_BRIDGE/FanInPrimitive_Req_BRIDGE.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_BRIDGE/FanInPrimitive_Resp_BRIDGE.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_BRIDGE/MUX2_REQ_BRIDGE.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_BRIDGE/RequestBlock1CH_BRIDGE.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_BRIDGE/RequestBlock2CH_BRIDGE.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_BRIDGE/ResponseBlock_BRIDGE.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_BRIDGE/ResponseTree_BRIDGE.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_BRIDGE/RR_Flag_Req_BRIDGE.sv" \
    "$ROOT/.bender/git/checkouts/l2_tcdm_hybrid_interco-c454a1d770326823/RTL/XBAR_BRIDGE/XBAR_BRIDGE.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/include" \
    "+incdir+$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/bhv" \
    "+incdir+$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/include" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/include/cv32e40p_apu_core_pkg.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/include/cv32e40p_fpu_pkg.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/include/cv32e40p_pkg.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_alu.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_alu_div.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_aligner.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_compressed_decoder.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_controller.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_cs_registers.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_decoder.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_int_controller.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_ex_stage.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_fifo.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_hwloop_regs.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_id_stage.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_if_stage.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_load_store_unit.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_mult.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_prefetch_buffer.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_prefetch_controller.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_obi_interface.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_core.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_apu_disp.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_popcnt.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_ff_one.sv" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_sleep_unit.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/include" \
    "+incdir+$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/bhv" \
    "+incdir+$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/include" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/cv32e40p_register_file_latch.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/include" \
    "+incdir+$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/bhv" \
    "+incdir+$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/rtl/include" \
    "$ROOT/.bender/git/checkouts/cv32e40p-0c712058920bd787/bhv/cv32e40p_sim_clock_gate.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/low_latency_interco" \
    "+incdir+$ROOT/.bender/git/checkouts/cluster_interconnect-3cafd41fb1ea3828/rtl/peripheral_interco" \
    "+incdir+$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/common" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/common/hci_package.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/common/hci_interfaces.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/core/hci_core_assign.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/core/hci_core_fifo.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/core/hci_core_mux_dynamic.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/core/hci_core_mux_static.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/core/hci_core_mux_ooo.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/core/hci_core_r_valid_filter.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/core/hci_core_r_id_filter.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/core/hci_core_source.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/core/hci_core_split.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/interco/hci_log_interconnect.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/interco/hci_log_interconnect_l2.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/interco/hci_new_log_interconnect.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/interco/hci_arbiter.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/interco/hci_router_reorder.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/core/hci_core_sink.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/interco/hci_router.sv" \
    "$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/hci_interconnect.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/hwpe-ctrl-baf519a1b44955c2/rtl" \
    "$ROOT/.bender/git/checkouts/hwpe-ctrl-baf519a1b44955c2/rtl/hwpe_ctrl_interfaces.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-ctrl-baf519a1b44955c2/rtl/hwpe_ctrl_package.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-ctrl-baf519a1b44955c2/rtl/hwpe_ctrl_regfile_ff.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-ctrl-baf519a1b44955c2/rtl/hwpe_ctrl_regfile_latch.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-ctrl-baf519a1b44955c2/rtl/hwpe_ctrl_seq_mult.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-ctrl-baf519a1b44955c2/rtl/hwpe_ctrl_uloop.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-ctrl-baf519a1b44955c2/rtl/hwpe_ctrl_regfile_latch_test_wrap.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-ctrl-baf519a1b44955c2/rtl/hwpe_ctrl_regfile.sv" \
    "$ROOT/.bender/git/checkouts/hwpe-ctrl-baf519a1b44955c2/rtl/hwpe_ctrl_slave.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_register_file_latch.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_register_file_ff.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_register_file_fpga.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl" \
    "+incdir+$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/vendor/lowrisc_ip/ip/prim/rtl" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_pkg.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/vendor/lowrisc_ip/ip/prim/rtl/prim_assert.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_alu.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_compressed_decoder.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_controller.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_counter.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_csr.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_decoder.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_fetch_fifo.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_load_store_unit.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_multdiv_fast.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_multdiv_slow.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_pmp.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_wb_stage.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_cs_registers.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_ex_block.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_id_stage.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_prefetch_buffer.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_if_stage.sv" \
    "$ROOT/.bender/git/checkouts/ibex-b31972101ad06c84/rtl/ibex_core.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/include" \
    "+incdir+$ROOT/.bender/git/checkouts/cv32e40x-b02547e8c1b6e597/sva" \
    "+incdir+$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/common" \
    "$ROOT/rtl/redmule_pkg.sv" \
    "$ROOT/rtl/redmule_tiler.sv" \
    "$ROOT/rtl/redmule_ctrl.sv" \
    "$ROOT/rtl/redmule_scheduler.sv" \
    "$ROOT/rtl/redmule_castin.sv" \
    "$ROOT/rtl/redmule_castout.sv" \
    "$ROOT/rtl/redmule_streamer.sv" \
    "$ROOT/rtl/x_buffer/redmule_x_buffer.sv" \
    "$ROOT/rtl/x_buffer/redmule_x_pad_scm.sv" \
    "$ROOT/rtl/x_buffer/redmule_x_buffer_scm.sv" \
    "$ROOT/rtl/w_buffer/redmule_w_buffer.sv" \
    "$ROOT/rtl/w_buffer/redmule_w_buffer_scm.sv" \
    "$ROOT/rtl/z_buffer/redmule_z_buffer.sv" \
    "$ROOT/rtl/z_buffer/redmule_z_buffer_scm.sv" \
    "$ROOT/rtl/redmule_fma.sv" \
    "$ROOT/rtl/redmule_noncomp.sv" \
    "$ROOT/rtl/redmule_ce.sv" \
    "$ROOT/rtl/redmule_row.sv" \
    "$ROOT/rtl/redmule_engine.sv" \
    "$ROOT/rtl/redmule_top.sv" \
    "$ROOT/rtl/redmule_memory_scheduler.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/include" \
    "+incdir+$ROOT/.bender/git/checkouts/cv32e40x-b02547e8c1b6e597/sva" \
    "+incdir+$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/common" \
    "$ROOT/rtl/redmule_wrap.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/include" \
    "+incdir+$ROOT/.bender/git/checkouts/cv32e40x-b02547e8c1b6e597/sva" \
    "+incdir+$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/common" \
    "$ROOT/target/sim/src/tb_dummy_memory.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/include" \
    "+incdir+$ROOT/.bender/git/checkouts/cv32e40x-b02547e8c1b6e597/sva" \
    "+incdir+$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/common" \
    "$ROOT/target/sim/src/redmule_tb.sv" \
}]} {return 1}

if {[catch { vlog -incr -sv \
    +acc -permissive -suppress 2583 -suppress 13314 \
    +define+TARGET_CV32E40P_EXCLUDE_TRACER \
    +define+TARGET_REDMULE_HWPE \
    +define+TARGET_REDMULE_TEST_HWPE \
    +define+TARGET_RTL \
    +define+TARGET_SIMULATION \
    +define+TARGET_VSIM \
    +define+COREV_ASSERT_OFF \
    "+incdir+$ROOT/.bender/git/checkouts/common_cells-c395fc6010bcbc9d/include" \
    "+incdir+$ROOT/.bender/git/checkouts/cv32e40x-b02547e8c1b6e597/sva" \
    "+incdir+$ROOT/.bender/git/checkouts/hci-5afd8126f874b49f/rtl/common" \
    "$ROOT/target/sim/src/redmule_tb_wrap.sv" \
}]} {return 1}

vopt +acc -permissive -suppress 2583 -suppress 13314 redmule_tb_wrap -o redmule_tb_wrap_opt
