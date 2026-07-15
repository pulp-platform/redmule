# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Yvan Tortorella <yvan.tortorella@unibo.it>
#
# Makefragment for Verilator simulation.

Questa ?=
Module := redmule
ProbStall ?= 0.05
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

VsimFlags += -suppress 3009

hw-clean:
	rm -rf $(VsimCompileScript) $(VsimDir)/transcript $(VsimDir)/modelsim.ini $(VsimDir)/*.wlf $(VsimDir)/work

hw-script:
	$(Bender) checkout
	$(Bender) script $(target)     \
	--vlog-arg="$(CompileFlags)"   \
	--vcom-arg="-pedanticerrors"   \
	$(common_targs) $(common_defs) \
	$(sim_targs)                   \
	> $(VsimCompileScript)
	echo 'vopt $(CompileFlags) -floatparameters+$(Tb) $(Tb) -o $(Tb)_opt' >> $(VsimCompileScript)

hw-build: hw-script
	cd $(VsimDir); \
	$(Questa) $(target) -c    \
	+STIM_INSTR=$(STIM_INSTR) \
	+STIM_DATA=$(STIM_DATA)   \
	-do 'quit -code [source $(VsimCompileScript)]'

# Run each test inside its own per-test $(BUILD_DIR) (keyed by TEST_ID) so that
# concurrent regression runs never clobber each other's transcript/*.wlf. The
# compiled design lives in the single shared $(VsimDir)/work library built once
# by hw-build; we symlink it in so vsim resolves $(Tb)_opt. Stimuli are passed
# as explicit absolute plusargs, so the working directory no longer matters.
hw-run:
	mkdir -p $(BUILD_DIR)
	ln -sfn $(VsimDir)/work $(BUILD_DIR)/work
	cd $(BUILD_DIR);              \
	$(QUESTA) $(target) $(Tb)_opt \
	$(VsimFlags)                  \
	-gPROB_STALL=$(ProbStall)     \
	+STIM_INSTR=$(STIM_INSTR)     \
	+STIM_DATA=$(STIM_DATA)       \
	-do "run -a"

hw-all: hw-clean hw-script hw-build hw-run
