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
CompileFlags := +acc -permissive -suppress 2583 -suppress 13314

ifeq ($(REDMULE_COMPLEX),1)
	TbType := redmule_complex_tb
else
	TbType := redmule_tb
endif

ifeq ($(gui),1)
	VsimFlags += -do "set TbType $(TbType)" \
               -do "log -r /*"            \
               -do "source $(VsimWaves)"
else
	VsimFlags += -c
endif

hw-clean:
	rm -rf $(VsimCompileScript) $(VsimDir)/transcript $(VsimDir)/modelsim.ini $(VsimDir)/*.wlf $(VsimDir)/work

hw-script:
	$(BENDER) update
	$(BENDER) script $(target)     \
	--vlog-arg="$(CompileFlags)"   \
	--vcom-arg="-pedanticerrors"   \
	$(common_targs) $(common_defs) \
	$(sim_targs)                   \
	> $(VsimCompileScript)
	echo 'vopt $(CompileFlags) $(Tb) -o $(Tb)_opt' >> $(VsimCompileScript)

hw-build: hw-script
	cd $(VsimDir); \
	$(Questa) $(target) -c    \
	+STIM_INSTR=$(STIM_INSTR) \
	+STIM_INSTR=$(STIM_DATA)  \
	+PROB_STALL=$(P_STALL)    \
	-do 'quit -code [source $(VsimCompileScript)]'

hw-run:
	cd $(VsimDir);                \
	$(QUESTA) $(target) $(Tb)_opt \
	$(VsimFlags)                  \
	-do "run -a"

hw-all: hw-clean hw-script hw-build hw-run
