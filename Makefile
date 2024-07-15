# Copyright (C) 2022-2023 ETH Zurich and University of Bologna
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# SPDX-License-Identifier: Apache-2.0
#
# Author: Yvan Tortorella (yvan.tortorella@unibo.it)
#
# Top-level Makefile

# Paths to folders
mkfile_path    := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
SW             ?= $(mkfile_path)/sw
BUILD_DIR      ?= $(mkfile_path)/work
QUESTA         ?= questa-2019.3-kgf
BENDER_DIR     ?= .
BENDER         ?= bender
TEST_SRCS      ?= sw/redmule.c
WAVES          ?= $(mkfile_path)/wave.do
ISA            ?= riscv
ARCH           ?= rv
XLEN           ?= 32
XTEN           ?= imc

compile_script ?= scripts/compile.tcl
compile_flag   ?= -suppress 2583 -suppress 13314

INI_PATH  = $(mkfile_path)/modelsim.ini
WORK_PATH = $(BUILD_DIR)

# Useful Parameters
gui      ?= 0
ipstools ?= 0
P_STALL  ?= 0.0
USE_ECC  ?= 0

ifeq ($(verbose),1)
FLAGS += -DVERBOSE
endif

# Setup toolchain (from SDK) and options
CC=$(PULP_RISCV_GCC_TOOLCHAIN)/bin/$(ISA)$(XLEN)-unknown-elf-gcc
LD=$(PULP_RISCV_GCC_TOOLCHAIN)/bin/$(ISA)$(XLEN)-unknown-elf-gcc
OBJDUMP=$(ISA)$(XLEN)-unknown-elf-objdump
CC_OPTS=-march=$(ARCH)$(XLEN)$(XTEN) -D__$(ISA)__ -O2 -g -Wextra -Wall -Wno-unused-parameter -Wno-unused-variable -Wno-unused-function -Wundef -fdata-sections -ffunction-sections -MMD -MP
LD_OPTS=-march=$(ARCH)$(XLEN)$(XTEN) -D__$(ISA)__ -MMD -MP -nostartfiles -nostdlib -Wl,--gc-sections

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
	sw/parse_s19.pl $(BIN).s19 > $(BIN).txt
	python sw/s19tomem.py $(BIN).txt $(STIM_INSTR) $(STIM_DATA)
	ln -sfn $(INI_PATH) $(VSIM_INI)
	ln -sfn $(WORK_PATH) $(VSIM_LIBS)

$(BIN): $(CRT) $(OBJ) sw/link.ld
	$(LD) $(LD_OPTS) -o $(BIN) $(CRT) $(OBJ) -Tsw/link.ld

$(CRT): $(BUILD_DIR) sw/crt0.S
	$(CC) $(CC_OPTS) -c sw/crt0.S -o $(CRT)

$(OBJ): $(TEST_SRCS) $(BUILD_DIR)/$(TEST_SRCS)
	$(CC) $(CC_OPTS) -c $(TEST_SRCS) $(FLAGS) -Isw -o $(OBJ)

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
	-gPROB_STALL=$(P_STALL)                \
	-gUSE_ECC=$(USE_ECC)                   \
		-suppress vsim-3009
else
	cd $(BUILD_DIR)/$(TEST_SRCS);      \
	$(QUESTA) vsim vopt_tb             \
	-do "add log -r sim:/redmule_tb/*" \
	-do "source $(WAVES)"              \
	-gSTIM_INSTR=stim_instr.txt        \
	-gSTIM_DATA=stim_data.txt          \
	-gPROB_STALL=$(P_STALL)            \
	-gUSE_ECC=$(USE_ECC)               \
		-suppress vsim-3009
endif

# Download bender
bender:
	curl --proto '=https'  \
	--tlsv1.2 https://pulp-platform.github.io/bender/init -sSf | sh -s -- 0.24.0

update-ips:
	$(BENDER) update
	$(BENDER) script vsim                                       \
	--vlog-arg="$(compile_flag)"                                \
	--vcom-arg="-pedanticerrors"                                \
	-t rtl -t test -t cv32e40p_exclude_tracer -t redmule_test   \
	> ${compile_script}

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
	$(QUESTA) vopt +acc=npr -o vopt_tb redmule_tb -floatparameters+redmule_tb -work $(BUILD_DIR)

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
