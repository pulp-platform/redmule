# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Yvan Tortorella <yvan.tortorella@unibo.it>
#
# Top-level Makefile

# Paths to folders
Verilator ?= verilator-5.020
Bender ?= bender
Module := redmule
Vmodule := V$(Module)
mkfile_path    := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
SW             ?= $(mkfile_path)sw
BUILD_DIR      ?= $(SW)/build
SIM_DIR        ?= $(mkfile_path)vsim
QUESTA         ?= questa-2023.4
BENDER_DIR     ?= .
BENDER         ?= bender
ISA            ?= riscv
ARCH           ?= rv
XLEN           ?= 32
XTEN           ?= imc

ifeq ($(REDMULE_COMPLEX),1)
	TEST_SRCS := $(SW)/redmule_complex.c
else
	TEST_SRCS := $(SW)/redmule.c
endif

compile_script ?= $(mkfile_path)scripts/compile.tcl
compile_script_synth ?= $(mkfile_path)scripts/synth_compile.tcl
compile_flag   ?= +acc -permissive -suppress 2583 -suppress 13314

INI_PATH  = $(mkfile_path)modelsim.ini
WORK_PATH = $(SIM_DIR)/work

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

CC=$(ISA)$(XLEN)-unknown-elf-gcc
LD=$(CC)
OBJDUMP=$(ISA)$(XLEN)-unknown-elf-objdump
CC_OPTS=-march=$(ARCH)$(XLEN)$(XTEN) -mabi=ilp32 -D__$(ISA)__ -O2 -g -Wextra -Wall -Wno-unused-parameter -Wno-unused-variable -Wno-unused-function -Wundef -fdata-sections -ffunction-sections -MMD -MP
LD_OPTS=-march=$(ARCH)$(XLEN)$(XTEN) -mabi=ilp32 -D__$(ISA)__ -MMD -MP -nostartfiles -nostdlib -Wl,--gc-sections

# Setup build object dirs
CRT=$(BUILD_DIR)/crt0.o
OBJ=$(BUILD_DIR)/verif.o
BIN=$(BUILD_DIR)/verif
DUMP=$(BUILD_DIR)/verif.dump
STIM_INSTR=$(SIM_DIR)/stim_instr.txt
STIM_DATA=$(SIM_DIR)/stim_data.txt

# Build implicit rules
$(STIM_INSTR) $(STIM_DATA): $(BIN)
	objcopy --srec-len 1 --output-target=srec $(BIN) $(BIN).s19
	scripts/parse_s19.pl $(BIN).s19 > $(BIN).txt
	python scripts/s19tomem.py $(BIN).txt $(STIM_INSTR) $(STIM_DATA)

$(BIN): $(CRT) $(OBJ)
	$(LD) $(LD_OPTS) -o $(BIN) $(CRT) $(OBJ) -T$(LINKSCRIPT)

$(CRT): $(BUILD_DIR)
	$(CC) $(CC_OPTS) -c $(BOOTSCRIPT) -o $(CRT)

$(OBJ): $(TEST_SRCS)
	$(CC) $(CC_OPTS) -c $(TEST_SRCS) $(FLAGS) $(INC) -o $(OBJ)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

SHELL := /bin/bash

# Generate instructions and data stimuli
sw-build: $(STIM_INSTR) $(STIM_DATA) dis

# Run the simulation
run: $(CRT)
ifeq ($(gui), 0)
	cd $(SIM_DIR);             \
	$(QUESTA) vsim -c $(tb)_opt \
	-do "run -a"                \
	-gSTIM_INSTR=$(STIM_INSTR)  \
	-gSTIM_DATA=$(STIM_DATA)    \
	-gPROB_STALL=$(P_STALL)
else
	cd $(SIM_DIR);            \
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

WAVES := $(mkfile_path)scripts/wave.tcl

ifeq ($(REDMULE_COMPLEX),1)
	tb := redmule_complex_tb
else
	tb := redmule_tb
endif

$(SIM_DIR):
	mkdir -p $(SIM_DIR)

target ?= vsim

ifeq ($(target),vsim)
	SIM_DIR := $(mkfile_path)vsim
	TARGET := vsim --vlog-arg="$(compile_flag)" --vcom-arg="-pedanticerrors"
else ifeq ($(target),verilator)
	SIM_DIR := $(mkfile_path)verilator
	TARGET := verilator
endif

update-ips: $(VSIM_DIR)
	$(BENDER) update
	$(BENDER) script $(TARGET)     \
	$(common_targs) $(common_defs) \
	$(sim_targs)                   \
	> ${compile_script}
ifeq ($(target),vsim)
	echo 'vopt $(compile_flag) $(tb) -o $(tb)_opt' >> ${compile_script}
endif

hw-verilator-script: $(VSIM_DIR)
	$(BENDER) update
	$(BENDER) script verilator     \
	$(common_targs) $(common_defs) \
	$(sim_targs)                   \
	> scripts/compile.flist

synth-ips:
	$(BENDER) update
	$(BENDER) script synopsys      \
	$(common_targs) $(common_defs) \
	$(synth_targs) $(synth_defs)   \
	> ${compile_script_synth}

sw-clean:
	rm -rf $(BUILD_DIR)

hw-clean:
	rm -rf $(VSIM_DIR)

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

clean-all: hw-clean sw-clean
	rm -rf $(mkfile_path).bender
	rm -rf $(compile_script)

hw-build: $(VSIM_DIR)
	cd $(VSIM_DIR); \
	$(QUESTA) vsim -c -do 'quit -code [source $(compile_script)]'

VLT_ROOT := /usr/pack/verilator-5.006-zr/verilator-5.006

VERI_TRACE +="--trace"
VLT_FLAGS  += -Wno-fatal
VLT_FLAGS  += --timing
VLT_CFLAGS += -DTOPLEVEL_NAME=tb_$(Module)
VLT_CFLAGS += -std=c++17
VLT_CFLAGS += -DVCD_TRACE
VLT_CFLAGS += -g -I $(VLT_ROOT)/include -I $(VLT_ROOT)/include/vltstd
VERI_OBJ_DIR := obj_dir

hw-verilator-build:
	$(Verilator) verilator --trace --timing --bbox-unsup \
	-Wall -Wno-fatal --Wno-lint --Wno-UNOPTFLAT --Wno-MODDUP -Wno-BLKANDNBLK \
	--x-assign unique --x-initial unique --top-module $(Module)_tb --Mdir $(mkfile_path)target/verilator/obj_dir \
	-sv -cc -f $(mkfile_path)scripts/compile.flist --exe $(mkfile_path)target/verilator/$(Module)_tb.cpp
	make -C $(mkfile_path)target/verilator/obj_dir -f Vredmule_tb.mk Vredmule_tb

sw-all: sw-clean sw-build

hw-all: hw-clean hw-build
