# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Yvan Tortorella <yvan.tortorella@unibo.it>
#
# Top-level Makefile

# Paths to folders
mkfile_path    := $(shell git rev-parse --show-toplevel)
SW             ?= $(mkfile_path)/sw
BUILD_DIR      ?= $(SW)/build
VSIM_DIR       ?= $(mkfile_path)/vsim
QUESTA         ?= questa-2023.4
BENDER_DIR     ?= .
BENDER         ?= bender
ISA            ?= riscv
ARCH           ?= rv
XLEN           ?= 32
XTEN           ?= imc_zicsr


ifeq ($(REDMULE_COMPLEX),1)
	TEST_SRCS := $(SW)/redmule_complex.c
else
	TEST_SRCS := $(SW)/redmule.c
endif

compile_script ?= $(mkfile_path)/scripts/compile.tcl
compile_script_synth ?= $(mkfile_path)/scripts/synth_compile.tcl
compile_flag   ?= +acc -permissive -suppress 2583 -suppress 13314

INI_PATH  = $(mkfile_path)/modelsim.ini
WORK_PATH = $(VSIM_DIR)/work

# Useful Parameters
gui      ?= 0
ipstools ?= 0
P_STALL  ?= 0.0

ifeq ($(verbose),1)
	FLAGS += -DVERBOSE
endif

ifeq ($(debug),1)
	FLAGS += -DDEBUG
endif

# Include directories
INC += -I$(SW)
INC += -I$(SW)/inc
INC += -I$(SW)/utils

BOOTSCRIPT := $(SW)/kernel/crt0.S
LINKSCRIPT := $(SW)/kernel/link.ld

# Setup toolchain (from SDK) and options
RV_CC=$(ISA)$(XLEN)-unknown-elf-gcc
RV_LD=$(ISA)$(XLEN)-unknown-elf-gcc
RV_OBJDUMP=$(ISA)$(XLEN)-unknown-elf-objdump
RV_CC_OPTS=-march=$(ARCH)$(XLEN)$(XTEN) -mabi=ilp32 -D__$(ISA)__ -O2 -g -Wextra -Wall -Wno-unused-parameter -Wno-unused-variable -Wno-unused-function -Wundef -fdata-sections -ffunction-sections -MMD -MP
RV_LD_OPTS=-march=$(ARCH)$(XLEN)$(XTEN) -mabi=ilp32 -D__$(ISA)__ -MMD -MP -nostartfiles -nostdlib -Wl,--gc-sections


# Setup build object dirs
CRT=$(BUILD_DIR)/crt0.o
OBJ=$(BUILD_DIR)/verif.o
BIN=$(BUILD_DIR)/verif
DUMP=$(BUILD_DIR)/verif.dump
STIM_INSTR=$(VSIM_DIR)/stim_instr.txt
STIM_DATA=$(VSIM_DIR)/stim_data.txt

# Build implicit rules
$(STIM_INSTR) $(STIM_DATA): $(BIN)
	objcopy --srec-len 1 --output-target=srec $(BIN) $(BIN).s19
	scripts/parse_s19.pl $(BIN).s19 > $(BIN).txt 2>$(BUILD_DIR)/parse_s19.pl.log
	python scripts/s19tomem.py $(BIN).txt $(STIM_INSTR) $(STIM_DATA) 

$(BIN): $(CRT) $(OBJ)
	$(RV_LD) $(RV_LD_OPTS) -o $(BIN) $(CRT) $(OBJ) -T$(LINKSCRIPT)

$(CRT): $(BUILD_DIR)
	$(RV_CC) $(CC_OPTS) -c $(BOOTSCRIPT) -o $(CRT)

$(OBJ): $(TEST_SRCS)
	$(RV_CC) $(CC_OPTS) -c $(TEST_SRCS) $(FLAGS) $(INC) -o $(OBJ)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

SHELL := /bin/bash

# Generate instructions and data stimuli
sw-build: $(VSIM_DIR) $(STIM_INSTR) $(STIM_DATA) dis

# Run the simulation
run: $(CRT)
ifeq ($(gui), 0)
	cd $(VSIM_DIR);             \
	$(QUESTA) vsim -c $(tb)_opt \
	-do "run -a"                \
	-gSTIM_INSTR=$(STIM_INSTR)  \
	-gSTIM_DATA=$(STIM_DATA)    \
	-gPROB_STALL=$(P_STALL)
else
	cd $(VSIM_DIR);            \
	$(QUESTA) vsim $(tb)_opt   \
	-do "set Testbench $(tb)"  \
	-do "log -r /*"            \
	-do "source $(WAVES)"      \
	-gSTIM_INSTR=$(STIM_INSTR) \
	-gSTIM_DATA=$(STIM_DATA)   \
	-gPROB_STALL=$(P_STALL)
endif

# Download bender
bender:
	curl --proto '=https'  \
	--tlsv1.2 https://pulp-platform.github.io/bender/init -sSf | sh -s -- 0.24.0

include bender_common.mk
include bender_sim.mk
include bender_synth.mk
include Makefile.verilator

WAVES := $(mkfile_path)/scripts/wave.tcl

ifeq ($(REDMULE_COMPLEX),1)
	tb := redmule_complex_tb
else
	tb := redmule_tb
endif

$(VSIM_DIR):
	mkdir -p $(VSIM_DIR)

update-ips: $(VSIM_DIR)
	$(BENDER) update
	$(BENDER) script vsim          \
	--vlog-arg="$(compile_flag)"   \
	--vcom-arg="-pedanticerrors"   \
	$(common_targs) $(common_defs) \
	$(sim_targs)                   \
	> ${compile_script}
	echo 'vopt $(compile_flag) $(tb) -o $(tb)_opt' >> ${compile_script}

synth-ips:
	$(BENDER) update
	$(BENDER) script synopsys      \
	$(common_targs) $(common_defs) \
	$(synth_targs) $(synth_defs)   \
	> ${compile_script_synth}

sw-clean:
	rm -rf $(BUILD_DIR)
	@rm -vf $(STIM_INSTR)
	@rm -vf $(STIM_DATA)

hw-clean:
	rm -rf $(VSIM_DIR)

dis:
	$(RV_OBJDUMP) -d $(BIN) > $(DUMP)

OP     ?= gemm
fp_fmt ?= FP16
M      ?= 12
N      ?= 16
K      ?= 16

golden: golden-clean
	$(MAKE) -C golden-model $(OP) SW=$(SW)/inc M=$(M) N=$(N) K=$(K) fp_fmt=$(fp_fmt)

golden-clean:
	$(MAKE) -C golden-model golden-clean

clean-all: hw-clean sw-clean
	rm -rf $(mkfile_path)/.bender
	rm -rf $(mkfile_path)/Bender.lock
	rm -rf $(compile_script)

hw-build: $(VSIM_DIR)
	cd $(VSIM_DIR); \
	$(QUESTA) vsim -c -do 'quit -code [source $(compile_script)]'

sw-all: sw-clean sw-build

hw-all: hw-clean hw-build

