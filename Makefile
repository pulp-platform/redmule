# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Yvan Tortorella <yvan.tortorella@unibo.it>
#
# Top-level Makefile

# Paths to folders
RootDir    := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
TargetDir  := $(RootDir)target
SimDir     := $(TargetDir)/sim
ScriptsDir := $(RootDir)scripts
VerilatorPath := target/sim/verilator
VsimPath      := target/sim/vsim
SW         ?= $(RootDir)sw
SIM_DIR    ?= $(RootDir)vsim
ifneq (,$(wildcard /etc/iis.version))
    QUESTA ?= questa-2023.4
    Bender ?= $(CargoInstallDir)/bin/bende
    Gcc    ?= $(GccInstallDir)/bin/
else
    QUESTA ?=
    Bender ?= bender
    Gcc    ?= 
endif
OP     ?= gemm
fp_fmt ?= FP16
M      ?= 24
N      ?= 16
K      ?= 16
TEST_ID   ?= $(OP)_$(fp_fmt)_$(M)x$(N)x$(K)$(if $(filter 1,$(REDMULE_COMPLEX)),_cplx,)
INC_DIR   ?= $(SW)/inc/$(TEST_ID)
BUILD_DIR  ?= $(SW)/build/$(TEST_ID)
ISA        ?= riscv
ARCH       ?= rv
XLEN       ?= 32
# Local PULP GCC toolchains are based on older GCC and bundle
# Zicsr together with the I extension. For GitHub CI we use
# a newer version of GCC
ifeq ($(CI),true)
    XTEN ?= imc_zicsr
else
    XTEN ?= imc
endif
PYTHON     ?= python3

target ?= verilator
TargetPath := $(SimDir)/$(target)

# Included makefrags
include $(TargetPath)/$(target).mk
include bender_common.mk
include bender_sim.mk
include bender_synth.mk

ifeq ($(REDMULE_COMPLEX),1)
	TEST_SRCS := $(SW)/redmule_complex.c
else
	TEST_SRCS := $(SW)/redmule.c
endif

compile_script_synth ?= $(RootDir)scripts/synth_compile.tcl

INI_PATH  = $(RootDir)modelsim.ini
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
INC += -I$(INC_DIR)
INC += -I$(SW)/utils

BOOTSCRIPT := $(SW)/kernel/crt0.S
LINKSCRIPT := $(SW)/kernel/link.ld

CC=$(Gcc)$(ISA)$(XLEN)-unknown-elf-gcc
LD=$(CC)
OBJDUMP=$(Gcc)$(ISA)$(XLEN)-unknown-elf-objdump
CC_OPTS=-march=$(ARCH)$(XLEN)$(XTEN) -mabi=ilp32 -D__$(ISA)__ -O2 -g -Wextra -Wall -Wno-unused-parameter -Wno-unused-variable -Wno-unused-function -Wundef -fdata-sections -ffunction-sections -MMD -MP
LD_OPTS=-march=$(ARCH)$(XLEN)$(XTEN) -mabi=ilp32 -D__$(ISA)__ -MMD -MP -nostartfiles -nostdlib -Wl,--gc-sections

# Setup build object dirs
CRT=$(BUILD_DIR)/crt0.o
OBJ=$(BUILD_DIR)/verif.o
BIN=$(BUILD_DIR)/verif
DUMP=$(BUILD_DIR)/verif.dump
STIM_INSTR=$(BUILD_DIR)/stim_instr.txt
STIM_DATA=$(BUILD_DIR)/stim_data.txt

# Build implicit rules
$(STIM_INSTR) $(STIM_DATA): $(BIN)
	$(Gcc)$(ISA)$(XLEN)-unknown-elf-objcopy --srec-len 1 --output-target=srec $(BIN) $(BIN).s19
	$(PYTHON) scripts/parse_s19.py < $(BIN).s19 > $(BIN).txt
	$(PYTHON) scripts/s19tomem.py $(BIN).txt $(STIM_INSTR) $(STIM_DATA)

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

$(SIM_DIR):
	mkdir -p $(SIM_DIR)

synth-ips:
	$(Bender) update
	$(Bender) script synopsys      \
	$(common_targs) $(common_defs) \
	$(synth_targs) $(synth_defs)   \
	> ${compile_script_synth}

sw-clean:
	rm -rf $(BUILD_DIR)

dis:
	$(OBJDUMP) -d $(BIN) > $(DUMP)

golden:
	mkdir -p $(INC_DIR)
	PYTHONDONTWRITEBYTECODE=1 $(MAKE) -C golden-model $(OP) \
	SW=$(INC_DIR) TXT_DIR=$(BUILD_DIR)/golden_txt           \
	M=$(M) N=$(N) K=$(K) fp_fmt=$(fp_fmt)

golden-clean:
	$(MAKE) -C golden-model golden-clean

# ---------------------------------------------------------------------------- #
# One-shot memory-mapped test. In a single command this:
#   1. (re)generates the golden model for the requested M/N/K,
#   2. rebuilds the test software against the fresh operands/golden headers,
#   3. compiles and runs the RedMulE memory-mapped testbench in Questa.
# The TB prints "[TB] - Success!" (errors=0) on a passing run. Example:
#
#     make test M=32 N=32 K=32
#
# OP (gemm, matmul, addmax, ...) and fp_fmt (FP16, FP8) can also be overridden.
# The recipe pins the backend to vsim (memory-mapped Questa flow) and resolves
# the toolchain to the copies on PATH (bender, Questa, GCC). XTEN is picked
# automatically (see the CI check above): imc locally, imc_zicsr in CI.
# Override any of these on the command line, or call the underlying
# golden / sw-build / hw-* targets directly, if your environment differs.
# ---------------------------------------------------------------------------- #
.PHONY: test
test:
	$(MAKE) golden OP=$(OP) fp_fmt=$(fp_fmt) M=$(M) N=$(N) K=$(K)
	$(MAKE) sw-clean sw-build REDMULE_COMPLEX=0 Gcc=
	$(MAKE) hw-run REDMULE_COMPLEX=0 target=vsim Bender=bender Questa= QUESTA=

clean-all: sw-clean
	rm -rf $(RootDir).bender
	rm -rf $(compile_script)

sw-all: sw-clean sw-build

# Install tools
CXX ?= g++
NumCores := $(shell nproc)
NumCoresHalf := $(shell echo "$$(($(NumCores) / 2))")
VendorDir ?= $(RootDir)vendor
InstallDir ?= $(VendorDir)/install
# Verilator
# VerilatorInstallDir is only used as a fallback: target/sim/verilator/verilator.mk
# defaults to a verilator already on PATH (system package, environment module, ...)
# and only falls back to the vendored copy below if none is found.
# Resolve to the latest tagged release unless the caller pins a version explicitly.
VerilatorVersion ?= $(shell git ls-remote --tags --refs https://github.com/verilator/verilator.git \
	| sed 's/.*refs\/tags\///' | grep -E '^v[0-9]+\.[0-9]+$$' | sort -V | tail -1)
VerilatorInstallDir := $(InstallDir)/verilator
# GCC
GccInstallDir := $(InstallDir)/riscv
RiscvTarDir := riscv.tar.gz
GccUrl := https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2024.08.28/riscv32-elf-ubuntu-20.04-gcc-nightly-2024.08.28-nightly.tar.gz
# Bender (installed from prebuilt release binaries, no Rust toolchain needed)
BenderVersion ?= 0.32.1
CargoInstallDir := $(InstallDir)/cargo

# verilator: $(VerilatorInstallDir)/bin/verilator
# 
# $(VerilatorInstallDir)/bin/verilator:
# 	rm -rf $(VendorDir)/verilator
# 	mkdir -p $(VendorDir) && cd $(VendorDir) && git clone https://github.com/verilator/verilator.git
# 	# Checkout the latest tagged release (or VerilatorVersion, if overridden on the command line)
# 	cd $(VendorDir)/verilator && git reset --hard && git fetch --tags && git checkout $(VerilatorVersion)
# 	# Compile verilator
# 	rm -rf $(VerilatorInstallDir)
# 	mkdir -p $(VerilatorInstallDir) && cd $(VendorDir)/verilator && git clean -xfdf && autoconf && \
# 	./configure --prefix=$(VerilatorInstallDir) CXX=$(CXX) && make -j$(NumCoresHalf)  && make install

riscv32-gcc: $(GccInstallDir)

$(GccInstallDir):
	rm -rf $(GccInstallDir) $(VendorDir)/$(RiscvTarDir)
	mkdir -p $(InstallDir)
	cd $(VendorDir) && \
	wget $(GccUrl) -O $(RiscvTarDir) && \
	tar -xzvf $(RiscvTarDir) -C $(InstallDir) riscv

bender: $(CargoInstallDir)/bin/bender

$(CargoInstallDir)/bin/bender:
	mkdir -p $(InstallDir)
	curl --proto '=https' --tlsv1.2 -sSfL https://github.com/pulp-platform/bender/releases/download/v$(BenderVersion)/bender-installer.sh > $(InstallDir)/bender-installer.sh
	BENDER_INSTALL_DIR=$(CargoInstallDir) BENDER_NO_MODIFY_PATH=1 BENDER_DISABLE_UPDATE=1 \
		sh $(InstallDir)/bender-installer.sh
	rm -f $(InstallDir)/bender-installer.sh
