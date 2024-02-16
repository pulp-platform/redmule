# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Yvan Tortorella <yvan.tortorella@unibo.it>
#
# Top-level Makefile

# Paths to folders
mkfile_path    := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
SW             ?= $(mkfile_path)/sw
BUILD_DIR      ?= $(mkfile_path)/work
QUESTA         ?= questa-2020.1
BENDER_DIR     ?= .
BENDER         ?= bender
ISA            ?= riscv
ARCH           ?= rv
XLEN           ?= 32
XTEN           ?= imc

ifeq ($(REDMULE_COMPLEX),1)
	TEST_SRCS := sw/redmule_complex.c
else
	TEST_SRCS := sw/redmule.c
endif

compile_script ?= scripts/compile.tcl
compile_script_synth ?= scripts/synth_compile.tcl
compile_flag   ?= -suppress 2583 -suppress 13314

INI_PATH  = $(mkfile_path)/modelsim.ini
WORK_PATH = $(BUILD_DIR)

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
INC += -Isw
INC += -Isw/inc
INC += -Isw/utils

BOOTSCRIPT := sw/kernel/crt0.S
LINKSCRIPT := sw/kernel/link.ld

CC=$(ISA)$(XLEN)-unknown-elf-gcc
LD=$(CC)
OBJDUMP=$(ISA)$(XLEN)-unknown-elf-objdump
CC_OPTS=-march=$(ARCH)$(XLEN)$(XTEN) -mabi=ilp32 -D__$(ISA)__ -O2 -g -Wextra -Wall -Wno-unused-parameter -Wno-unused-variable -Wno-unused-function -Wundef -fdata-sections -ffunction-sections -MMD -MP
LD_OPTS=-march=$(ARCH)$(XLEN)$(XTEN) -mabi=ilp32 -D__$(ISA)__ -MMD -MP -nostartfiles -nostdlib -Wl,--gc-sections

# Setup build object dirs
CRT=$(BUILD_DIR)/crt0.o
OBJ=$(BUILD_DIR)/$(TEST_SRCS)/verif.o
BIN=$(BUILD_DIR)/$(TEST_SRCS)/verif
DUMP=$(BUILD_DIR)/$(TEST_SRCS)/verif.dump
STIM_INSTR=$(BUILD_DIR)/$(TEST_SRCS)/stim_instr.txt
STIM_DATA=$(BUILD_DIR)/$(TEST_SRCS)/stim_data.txt
VSIM_INI=$(BUILD_DIR)/$(TEST_SRCS)/modelsim.ini
VSIM_LIBS=$(BUILD_DIR)/$(TEST_SRCS)/work

# Build implicit rules
$(STIM_INSTR) $(STIM_DATA): $(BIN)
	objcopy --srec-len 1 --output-target=srec $(BIN) $(BIN).s19
	scripts/parse_s19.pl $(BIN).s19 > $(BIN).txt
	python scripts/s19tomem.py $(BIN).txt $(STIM_INSTR) $(STIM_DATA)
	ln -sfn $(INI_PATH) $(VSIM_INI)
	ln -sfn $(WORK_PATH) $(VSIM_LIBS)

$(BIN): $(CRT) $(OBJ)
	$(LD) $(LD_OPTS) -o $(BIN) $(CRT) $(OBJ) -T$(LINKSCRIPT)

$(CRT): $(BUILD_DIR)
	$(CC) $(CC_OPTS) -c $(BOOTSCRIPT) -o $(CRT)

$(OBJ): $(TEST_SRCS) $(BUILD_DIR)/$(TEST_SRCS)
	$(CC) $(CC_OPTS) -c $(TEST_SRCS) $(FLAGS) $(INC) -o $(OBJ)

$(BUILD_DIR)/$(TEST_SRCS):
	mkdir -p $(BUILD_DIR)/$(TEST_SRCS)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

SHELL := /bin/bash

# Generate instructions and data stimuli
all: $(STIM_INSTR) $(STIM_DATA) dis

# Run the simulation
run: $(CRT)
ifeq ($(gui), 0)
	cd $(BUILD_DIR)/$(TEST_SRCS);          \
	$(QUESTA) vsim -c vopt_tb -do "run -a" \
	-gSTIM_INSTR=stim_instr.txt            \
	-gSTIM_DATA=stim_data.txt              \
	-gPROB_STALL=$(P_STALL)
else
	cd $(BUILD_DIR)/$(TEST_SRCS); \
	$(QUESTA) vsim vopt_tb        \
	-do "add log -r sim:/$(tb)/*" \
	-do "source $(WAVES)"         \
	-gSTIM_INSTR=stim_instr.txt   \
	-gSTIM_DATA=stim_data.txt     \
	-gPROB_STALL=$(P_STALL)
endif

# Download bender
bender:
	curl --proto '=https'  \
	--tlsv1.2 https://pulp-platform.github.io/bender/init -sSf | sh -s -- 0.24.0

include bender_common.mk
include bender_sim.mk
include bender_synth.mk

bender_defs += -D COREV_ASSERT_OFF

bender_targs += -t rtl
bender_targs += -t test
bender_targs += -t cv32e40p_exclude_tracer

ifeq ($(REDMULE_COMPLEX),1)
	tb := redmule_complex_tb
	WAVES := $(mkfile_path)/wave_complex_xif.do
	bender_targs += -t redmule_complex
else
	tb := redmule_tb
	WAVES := $(mkfile_path)/wave.do
	bender_targs += -t redmule_hwpe
endif

update-ips:
	$(BENDER) update
	$(BENDER) script vsim          \
	--vlog-arg="$(compile_flag)"   \
	--vcom-arg="-pedanticerrors"   \
	$(bender_targs) $(bender_defs) \
	$(sim_targs)    $(sim_deps)    \
	> ${compile_script}

synth-ips:
	$(BENDER) update
	$(BENDER) script synopsys      \
	$(common_targs) $(common_defs) \
	$(synth_targs) $(synth_defs)   \
	> ${compile_script_synth}

build-hw: hw-all

sdk:
	cd $(SW); \
	git clone \
	git@github.com:pulp-platform/pulp-sdk.git

clean-sdk:
	rm -rf $(SW)/pulp-sdk

clean:
	rm -rf $(BUILD_DIR)/$(TEST_SRCS)

dis:
	$(OBJDUMP) -d $(BIN) > $(DUMP)

OP     ?= gemm
fp_fmt ?= FP16
M      ?= 12
N      ?= 16
K      ?= 16

golden: golden-clean
	$(MAKE) -C golden-model $(OP) SW=$(SW)/inc M=$(M) N=$(N) K=$(K) fp_fmt=$(fp_fmt)

golden-clean:
	$(MAKE) -C golden-model golden-clean

# Hardware rules
hw-clean-all:
	rm -rf $(BUILD_DIR)
	rm -rf .bender
	rm -rf $(compile_script)
	rm -rf modelsim.ini
	rm -rf *.log
	rm -rf transcript
	rm -rf .cached_ipdb.json

hw-opt:
	$(QUESTA) vopt +acc=npr -o vopt_tb $(tb) -floatparameters+$(tb) -work $(BUILD_DIR)

hw-compile:
	$(QUESTA) vsim -c +incdir+$(UVM_HOME) -do 'quit -code [source $(compile_script)]'

hw-lib:
	@touch modelsim.ini
	@mkdir -p $(BUILD_DIR)
	@$(QUESTA) vlib $(BUILD_DIR)
	@$(QUESTA) vmap work $(BUILD_DIR)
	@chmod +w modelsim.ini

hw-clean:
	rm -rf transcript
	rm -rf modelsim.ini

hw-all: hw-clean hw-lib hw-compile hw-opt
