# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Yvan Tortorella <yvan.tortorella@unibo.it>
#
# Makefragment for Verilator simulation.

Questa ?= questa-2023.4
Module := redmule
VsimDir := $(SimDir)/$(target)
VsimCompileScript := $(VsimDir)/compile.$(target).tcl
VsimWaves := $(VsimDir)/wave.tcl

Tb := redmule_tb_wrap
CompileFlags := +acc -permissive -floatparameters+$(Tb) -suppress 2583 -suppress 13314 -suppress vlog-1952
VsimFlags += -suppress vsim-3009
ifeq ($(UseXif),1)
	CoreTraces := "+log_file=$(VsimDir)/trace_core_00000000.log"
endif
ifeq ($(gui),1)
	VsimFlags += -do "set XifSel $(UseXif)" \
               -do "log -r /*"            \
               -do "source $(VsimWaves)"
else
	VsimFlags += -c
endif

VsimFlags += -suppress 3009

hw-clean:
	rm -rf $(VsimCompileScript) $(VsimDir)/transcript $(VsimDir)/modelsim.ini $(VsimDir)/*.wlf $(VsimDir)/work $(VsimDir)/trace*

hw-script:
	$(Bender) update
	$(Bender) script $(target)     \
	--vlog-arg="$(CompileFlags)"   \
	--vcom-arg="-pedanticerrors"   \
	$(common_targs) $(common_defs) \
	$(sim_targs) $(sim_defs)       \
	> $(VsimCompileScript)
	echo 'vopt $(CompileFlags) $(Tb) -o $(Tb)_opt' >> $(VsimCompileScript)

hw-build: hw-script
	cd $(VsimDir); \
	$(Questa) $(target) -c    \
	-do 'echo XifSel'         \
	-do 'quit -code [source $(VsimCompileScript)]'

hw-run:
	cd $(VsimDir);                \
	$(Questa) $(target) $(Tb)_opt \
	$(VsimFlags)                  \
	$(CoreTraces)                 \
	+STIM_INSTR=$(STIM_INSTR)     \
	+STIM_DATA=$(STIM_DATA)       \
	+STACK_INIT=$(STACK_INIT)     \
	-gPROB_STALL=$(P_STALL)       \
  -gUseXif=$(UseXif)            \
	-do "run -a"

hw-all: hw-clean hw-script hw-build hw-run
