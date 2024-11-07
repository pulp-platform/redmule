# Copyright 2021 ETH Zurich and University of Bologna.
# Solderpad Hardware License, Version 0.51, see LICENSE for details.
# SPDX-License-Identifier: SHL-0.51
#
# Yvan Tortorella <yvan.tortorella@unibo.it>

onerror {resume}
quietly WaveActivateNextPane {} 0

set Testbench redmule_tb_wrap/i_redmule_tb
if {$TbType == {redmule_tb}} {
  set TopLevelPath i_redmule_wrap/i_redmule_top
  set CorePath i_cv32e40p_core
} elseif {$TbType == {redmule_complex_tb}} {
  set DutPath i_dut
  set TopLevelPath $DutPath/i_redmule_top
  set CorePath $DutPath/gen_cv32e40x/i_core
}
set MinHeight 16
set MaxHeight 32
set WavesRadix hexadecimal

# Core
add wave -noupdate -group Core -group top -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$CorePath/*
# Top level
add wave -noupdate -group RedMulE -group top -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/*
add wave -noupdate -group RedMulE -group periph -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/periph/*
add wave -noupdate -group RedMulE -group tcdm -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/tcdm/*
# Streamer
add wave -noupdate -group Streamer -group top -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_streamer/*
add wave -noupdate -group Streamer -group LDST-Mux -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_streamer/i_ldst_mux/*
add wave -noupdate -group Streamer -group LDST-Mux -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_streamer/i_source_mux/*
## X stream
add wave -noupdate -group Streamer -group X-Stream -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_streamer/gen_tcdm2stream[0]/i_load_tcdm_fifo/*
add wave -noupdate -group Streamer -group X-Stream -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_streamer/gen_tcdm2stream[0]/i_load_cast/*
add wave -noupdate -group Streamer -group X-Stream -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_streamer/gen_tcdm2stream[0]/i_stream_source/*
## W stream
add wave -noupdate -group Streamer -group W-Stream -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_streamer/gen_tcdm2stream[1]/i_load_tcdm_fifo/*
add wave -noupdate -group Streamer -group W-Stream -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_streamer/gen_tcdm2stream[1]/i_load_cast/*
add wave -noupdate -group Streamer -group W-Stream -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_streamer/gen_tcdm2stream[1]/i_stream_source/*
## Y stream
add wave -noupdate -group Streamer -group Y-Stream -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_streamer/gen_tcdm2stream[2]/i_load_tcdm_fifo/*
add wave -noupdate -group Streamer -group Y-Stream -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_streamer/gen_tcdm2stream[2]/i_load_cast/*
add wave -noupdate -group Streamer -group Y-Stream -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_streamer/gen_tcdm2stream[2]/i_stream_source/*
## Z stream
add wave -noupdate -group Streamer -group Z-Stream -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_streamer/i_stream_sink/*
add wave -noupdate -group Streamer -group Z-Stream -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_streamer/i_store_cast/*
add wave -noupdate -group Streamer -group Z-Stream -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_streamer/i_store_fifo/*
# Buffers and FIFOs
## X
add wave -noupdate -group X-channel -group x-buffer_fifo -group fifo_interface -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/x_buffer_fifo/*
add wave -noupdate -group X-channel -group x-buffer_fifo -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_x_buffer_fifo/*
add wave -noupdate -group X-channel -group x-buffer -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_x_buffer/*
## W
add wave -noupdate -group W-channel -group w-buffer_fifo -group fifo_interface -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/w_buffer_fifo/*
add wave -noupdate -group W-channel -group w-buffer_fifo -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_w_buffer_fifo/*
add wave -noupdate -group W-channel -group w-buffer -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_w_buffer/*
## Y
add wave -noupdate -group Y-channel -group y-buffer_fifo -group fifo_interface -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/y_buffer_fifo/*
add wave -noupdate -group Y-channel -group y-buffer_fifo -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_y_buffer_fifo/*
## Z
add wave -noupdate -group Z-channel -group z-buffer_fifo -group fifo_interface -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/z_buffer_fifo/*
add wave -noupdate -group Z-channel -group z-buffer_fifo -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_z_buffer_fifo/*
add wave -noupdate -group Z-channel -group z-buffer -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_z_buffer/*
# Engine
set NumRows [examine -radix dec redmule_pkg::ARRAY_WIDTH]
set NumCols [examine -radix dec redmule_pkg::ARRAY_HEIGHT]

for {set row 0}  {$row < $NumRows} {incr row} {
  for {set col 0}  {$col < $NumCols} {incr col} {
    add wave -noupdate -group Engine -group row_$row -group CE_$col -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_redmule_engine/gen_redmule_rows[$row]/i_row/gen_computing_element[$col]/i_computing_element/*
  }
}
# Scheduler
add wave -noupdate -group Scheduler -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_scheduler/*
# Controller
add wave -noupdate -group Controller -color {} -height $MinHeight -max $MaxHeight -radix $WavesRadix $Testbench/$TopLevelPath/i_control/*

# Remove the hierarchial strip from signals
config wave -signalnamewidth 1
