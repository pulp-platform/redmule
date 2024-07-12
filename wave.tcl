onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate -group Testbench /redmule_tb/i_redmule_wrap/*

add wave -noupdate -group Core /redmule_tb/i_cv32e40p_core/*

add wave -noupdate -group X_Buffer /redmule_tb/i_redmule_wrap/i_redmule_top/i_x_buffer/*

add wave -noupdate -group X_Fifo -group Input /redmule_tb/i_redmule_wrap/i_redmule_top/x_buffer_d/*
add wave -noupdate -group X_Fifo -group Output /redmule_tb/i_redmule_wrap/i_redmule_top/x_buffer_fifo/*
add wave -noupdate -group X_Fifo /redmule_tb/i_redmule_wrap/i_redmule_top/i_x_buffer_fifo/*

add wave -noupdate -group W_Buffer /redmule_tb/i_redmule_wrap/i_redmule_top/i_w_buffer/*

add wave -noupdate -group W_Fifo -group Input /redmule_tb/i_redmule_wrap/i_redmule_top/w_buffer_d/*
add wave -noupdate -group W_Fifo -group Output /redmule_tb/i_redmule_wrap/i_redmule_top/w_buffer_fifo/*
add wave -noupdate -group W_Fifo /redmule_tb/i_redmule_wrap/i_redmule_top/i_w_buffer_fifo/*

add wave -noupdate -group Z/Y_Buffer /redmule_tb/i_redmule_wrap/i_redmule_top/i_z_buffer/*

add wave -noupdate -group Z_Fifo -group Input /redmule_tb/i_redmule_wrap/i_redmule_top/z_buffer_fifo/*
add wave -noupdate -group Z_Fifo -group Output /redmule_tb/i_redmule_wrap/i_redmule_top/z_buffer_q/*
add wave -noupdate -group Z_Fifo /redmule_tb/i_redmule_wrap/i_redmule_top/i_z_buffer_fifo/*

add wave -noupdate -group Y_Fifo -group Input /redmule_tb/i_redmule_wrap/i_redmule_top/y_buffer_d/*
add wave -noupdate -group Y_Fifo -group Output /redmule_tb/i_redmule_wrap/i_redmule_top/y_buffer_fifo/*
add wave -noupdate -group Y_Fifo /redmule_tb/i_redmule_wrap/i_redmule_top/i_y_buffer_fifo/*

add wave -noupdate -group Streamer -group tcdm /redmule_tb/i_redmule_wrap/i_redmule_top/i_streamer/tcdm/*
add wave -noupdate -group Streamer -group X_Addresgen -position insertpoint sim:/redmule_tb/i_redmule_wrap/i_redmule_top/i_streamer/i_x_stream_in/i_stream_source/i_addressgen/*
add wave -noupdate -group Streamer -group W_Addresgen -position insertpoint sim:/redmule_tb/i_redmule_wrap/i_redmule_top/i_streamer/i_w_stream_in/i_stream_source/i_addressgen/*
add wave -noupdate -group Streamer -group Y_Addresgen -position insertpoint sim:/redmule_tb/i_redmule_wrap/i_redmule_top/i_streamer/i_y_stream_in/i_stream_source/i_addressgen/*
add wave -noupdate -group Streamer -group Z_Addresgen -position insertpoint sim:/redmule_tb/i_redmule_wrap/i_redmule_top/i_streamer/i_z_stream_out/i_stream_sink/i_addressgen/*
add wave -noupdate -group Streamer /redmule_tb/i_redmule_wrap/i_redmule_top/i_streamer/*

set arraw_width 12
set array_hight 4

# Add all CEs to an array
for {set w 0} {$w < $arraw_width} {incr w} {
  for {set h 0} {$h < $array_hight} {incr h} {
    add wave -noupdate -group Engine -group Row_$w -group CE_$h /redmule_tb/i_redmule_wrap/i_redmule_top/i_redmule_engine/gen_row_array[$w]/i_row/computing_element[$h]/i_computing_element/*
  }
}

# Add only the inputs to quickly compare same / different for redundancy
for {set w 0} {$w < $arraw_width} {incr w} {
  for {set h 0} {$h < $array_hight} {incr h} {
	add wave -noupdate -group Engine_Inputs -group Row_$w -group CE_$h /redmule_tb/i_redmule_wrap/i_redmule_top/i_redmule_engine/gen_row_array[$w]/i_row/computing_element[$h]/i_computing_element/x_input_i
	add wave -noupdate -group Engine_Inputs -group Row_$w -group CE_$h /redmule_tb/i_redmule_wrap/i_redmule_top/i_redmule_engine/gen_row_array[$w]/i_row/computing_element[$h]/i_computing_element/w_input_i
	add wave -noupdate -group Engine_Inputs -group Row_$w -group CE_$h /redmule_tb/i_redmule_wrap/i_redmule_top/i_redmule_engine/gen_row_array[$w]/i_row/computing_element[$h]/i_computing_element/y_bias_i
  }
}

for {set w 0} {$w < $arraw_width} {incr w} {
  for {set h 0} {$h < $array_hight} {incr h} {
  add wave -noupdate -group Engine_Outputs -group Row_$w -group CE_$h /redmule_tb/i_redmule_wrap/i_redmule_top/i_redmule_engine/gen_row_array[$w]/i_row/computing_element[$h]/i_computing_element/z_output_o
  }
}


add wave -noupdate -group Scheduler /redmule_tb/i_redmule_wrap/i_redmule_top/gen_scheduler[0]/i_scheduler/*

add wave -noupdate -group Control /redmule_tb/i_redmule_wrap/i_redmule_top/gen_controllers[0]/i_control/*

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
WaveRestoreZoom {0 ps} {1045800 ps}
