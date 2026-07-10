# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Yvan Tortorella <yvan.tortorella@unibo.it>
#
# Makefragment for Verilator simulation.

# Prefer a verilator already on PATH (system package, environment module, ...);
# fall back to the copy vendored under vendor/install (see the `verilator`
# target in the top-level Makefile) only if none is found. Force one or the
# other explicitly with `make ... Verilator=verilator` or
# `make ... Verilator=$(VerilatorInstallDir)/bin/verilator`.
Verilator ?= $(if $(shell command -v verilator 2>/dev/null),verilator,$(VerilatorInstallDir)/bin/verilator)
GtkWave ?= gtkwave
VerilatorRoot ?= $(VerilatorInstallDir)/share/verilator
Module := redmule
ObjDirName := obj_dir
Vmodule := V$(Module)
VerilatorDir := $(SimDir)/$(target)
VerilatorSrc := $(SimDir)/src
VerilatorObjDir := $(VerilatorPath)/$(ObjDirName)
VerilatorAbsObjDir := $(VerilatorDir)/$(ObjDirName)
VerilatorCompileScript := $(VerilatorDir)/compile.$(target).tcl
VerilatorWaves := $(VerilatorDir)/redmule.vcd

hw-clean:
	rm -rf $(VerilatorAbsObjDir) $(VerilatorCompileScript) $(VerilatorWaves) $(VerilatorDir)/transcript

hw-script:
	$(Bender) checkout
	$(Bender) script $(target)     \
	$(common_targs) $(common_defs) \
	$(sim_targs)                   \
	> $(VerilatorCompileScript)

hw-build: hw-script
	$(Verilator) --trace --timing --bbox-unsup \
	-Wall -Wno-fatal --Wno-lint --Wno-UNOPTFLAT --Wno-MODDUP -Wno-BLKANDNBLK -Wno-ENUMVALUE \
	--x-assign unique --x-initial unique --top-module $(Module)_tb --Mdir $(VerilatorAbsObjDir) \
	-CFLAGS "-DTbName=$(Vmodule)_tb -DWafeformPath=$(VerilatorWaves)" \
	-sv -cc -f $(VerilatorCompileScript) --exe $(VerilatorSrc)/$(Module)_tb.cpp
	make -C $(VerilatorAbsObjDir) -f $(Vmodule)_tb.mk $(Vmodule)_tb \
	OBJCACHE=ccache OPT_SLOW=-O0 OPT_FAST=-O0 OPT_GLOBAL=-O0

hw-run:
	mkdir -p $(BUILD_DIR)
	cd $(BUILD_DIR);                    \
	$(VerilatorAbsObjDir)/$(Vmodule)_tb  \
	+STIM_INSTR=$(STIM_INSTR)           \
	+STIM_DATA=$(STIM_DATA)             \
	$(if $(filter 1,$(gui)),,+NOTRACE)
ifeq ($(gui),1)
	$(GtkWave) $(VerilatorWaves)
endif

hw-all: hw-clean hw-script hw-build hw-run
