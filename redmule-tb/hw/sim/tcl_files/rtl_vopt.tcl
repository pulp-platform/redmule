#!/usr/bin/env tclsh

source ./tcl_files/config/vsim_ips.tcl
source ./tcl_files/config/vsim_rtl.tcl

if {[catch {
  eval exec >@stdout vopt +acc=mnpr +cover -o vopt_tb tb_hwpe -floatparameters+tb_hwpe -Ldir modelsim_libs $VSIM_IP_LIBS $VSIM_RTL_LIBS -work work
}]} {
  exit 1
}

