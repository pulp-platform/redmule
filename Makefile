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
HW             := $(shell pwd)/hw
SW             ?= $(shell pwd)/sw
BUILD_DIR      ?= $(HW)/work
BENDER_DIR     ?= $(HW)/bender
TEST_SRCS      ?= sw/redmule.c
WAVES          ?= $(HW)/wave.do

ifeq ($(ipstools),1) # IPstools-based flow
INI_PATH  = $(mkfile_path)/hw/tb/modelsim.ini
WORK_PATH = $(mkfile_path)/hw/tb/work
else # Bender-based flow
INI_PATH  = $(HW)/modelsim.ini
WORK_PATH = $(BUILD_DIR)
endif

# Useful Parameters
gui         ?= 0
ipstools    ?= 0
P_STALL     ?= 0.0

# Setup toolchain (from SDK) and options
CC=$(PULP_RISCV_GCC_TOOLCHAIN)/bin/riscv32-unknown-elf-gcc
LD=$(PULP_RISCV_GCC_TOOLCHAIN)/bin/riscv32-unknown-elf-gcc
CC_OPTS=-march=rv32imc -D__riscv__ -O2 -g -Wextra -Wall -Wno-unused-parameter -Wno-unused-variable -Wno-unused-function -Wundef -fdata-sections -ffunction-sections -MMD -MP
LD_OPTS=-march=rv32imc -D__riscv__ -MMD -MP -nostartfiles -nostdlib -Wl,--gc-sections

# Setup build object dirs
CRT=$(BUILD_DIR)/crt0.o
OBJ=$(BUILD_DIR)/$(TEST_SRCS)/verif.o
BIN=$(BUILD_DIR)/$(TEST_SRCS)/verif
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
	$(CC) $(CC_OPTS) -c $(TEST_SRCS) -Isw -o $(OBJ)

$(BUILD_DIR)/$(TEST_SRCS):
	mkdir -p $(BUILD_DIR)/$(TEST_SRCS)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

SHELL := /bin/bash

# Generate instructions and data stimuli
all: $(STIM_INSTR) $(STIM_DATA)

# Run the simulation
run: $(CRT)
ifeq ($(gui), 0)
	cd $(BUILD_DIR)/$(TEST_SRCS);   \
	vsim -c vopt_tb -do "run -a"    \
	-gSTIM_INSTR=stim_instr.txt     \
	-gSTIM_DATA=stim_data.txt       \
	-gPROB_STALL=$(P_STALL)
else
	cd $(BUILD_DIR)/$(TEST_SRCS);      \
	vsim vopt_tb                       \
	-do "add log -r sim:/redmule_tb/*" \
	-do "source $(WAVES)"              \
	-gSTIM_INSTR=stim_instr.txt        \
	-gSTIM_DATA=stim_data.txt          \
	-gPROB_STALL=$(P_STALL)
endif

# Download bender
bender:
	mkdir -p $(BENDER_DIR)
	cd $(BENDER_DIR);      \
	curl --proto '=https'  \
	--tlsv1.2 https://pulp-platform.github.io/bender/init -sSf | sh -s -- 0.24.0

ifeq ($(ipstools),0) # Bender-based flow
update-ips:
	$(MAKE) -C $(HW) scripts

build-hw:
	$(MAKE) -C $(HW) lib build opt

clean-hw:
	$(MAKE) -C $(HW) clean-env

else # IPstools-based flow
update-ips:
	cd hw; ./update-ips

build-hw:
	cd hw/tb; make clean lib build opt

clean-hw:
	rm -rf $(HW)/ips
	rm -rf $(HW)/ipstools
	rm -rf $(HW)/ipstools_cfg.pyc
	rm -rf $(HW)/tb/modelsim*
	rm -rf $(HW)/tb/work
	rm -rf $(HW)/tb/vcompile/ips
	rm -rf $(HW)/tb/vcompile/rtl
	rm -rf $(HW)/tb/vcompile/tb
	rm -rf $(HW)/.cached_ipdb.json
endif

sdk:
	cd $(SW); \
	git clone \
	git@github.com:pulp-platform/pulp-sdk.git

clean-sdk:
	rm -rf $(SW)/pulp-sdk

clean:
	rm -rf $(BUILD_DIR)/$(TEST_SRCS)
	rm -rf modelsim.ini
	rm -rf transcript

OP     ?= gemm
fp_fmt ?= FP16
M      ?= 12
N      ?= 16
K      ?= 16

golden: clean-golden
	$(MAKE) -C golden-model $(OP) SW=$(SW)/inc M=$(M) N=$(N) K=$(K) fp_fmt=$(fp_fmt)

clean-golden:
	$(MAKE) -C golden-model clean
