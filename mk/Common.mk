###############################################################################
#
# Copyleft  2024
# Copyright 2020 OpenHW Group
#
# Licensed under the Solderpad Hardware Licence, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://solderpad.org/licenses/
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# SPDX-License-Identifier: Apache-2.0 WITH SHL-2.0
#
###############################################################################
#
# Common code for simulation Makefiles.
#
###############################################################################
#
# Copyright 2019 Claire Wolf
# Copyright 2019 Robert Balas
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
# REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT,
# INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
# LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR
# OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR
# PERFORMANCE OF THIS SOFTWARE.
#
# Original Author: Robert Balas (balasr@iis.ee.ethz.ch)
#
###############################################################################

RISCV            = $(CV_SW_TOOLCHAIN)
RISCV_PREFIX     = $(CV_SW_PREFIX)
RISCV_EXE_PREFIX = $(RISCV)/bin/$(RISCV_PREFIX)

RISCV_MARCH      =  $(CV_SW_MARCH)
RISCV_CC         =  $(CV_SW_CC)
RISCV_CFLAGS     += 

CFLAGS ?= -Os -g -static -mabi=ilp32 -march=$(RISCV_MARCH) -Wall -pedantic $(RISCV_CFLAGS)

TEST_FILES        = $(filter %.c %.S,$(wildcard  $(TEST_TEST_DIR)/*))
# Optionally use linker script provided in test directory
# this must be evaluated at access time, so ifeq/ifneq does
# not get parsed correctly
TEST_RESULTS_LD = $(addprefix $(SIM_TEST_PROGRAM_RESULTS)/, link.ld)
TEST_LD         = $(addprefix $(TEST_TEST_DIR)/, link.ld)

LD_LIBRARY 	= $(if $(wildcard $(TEST_RESULTS_LD)),-L $(SIM_TEST_PROGRAM_RESULTS),$(if $(wildcard $(TEST_LD)),-L $(TEST_TEST_DIR),))
LD_FILE 	= $(if $(wildcard $(TEST_RESULTS_LD)),$(TEST_RESULTS_LD),$(if $(wildcard $(TEST_LD)),$(TEST_LD),$(BSP)/link.ld))

$(warning TEST_TEST_DIR set to $(TEST_TEST_DIR))
$(warning RISCV set to $(RISCV))
$(warning RISCV_PREFIX set to $(RISCV_PREFIX))
$(warning RISCV_EXE_PREFIX set to $(RISCV_EXE_PREFIX))
$(warning RISCV_MARCH set to $(RISCV_MARCH))
$(warning RISCV_CC set to $(RISCV_CC))
$(warning RISCV_CFLAGS set to $(RISCV_CFLAGS))

BSP                                  = $(CORE_V_VERIF)/$(CV_CORE_LC)/bsp

RISCV_CFLAGS += -I $(BSP)

%.hex: %.elf
	@echo "$(BANNER)"
	@echo "* Generating hexfile, readelf and objdump files"
	@echo "$(BANNER)"
	$(RISCV_EXE_PREFIX)objcopy -O verilog \
		$< \
		$@
	$(RISCV_EXE_PREFIX)readelf -a $< > $*.readelf
	$(RISCV_EXE_PREFIX)objdump \
		-fhSD \
		-M no-aliases \
		-M numeric \
		-S \
		$*.elf > $*.objdump



TEST_FILES_FULL   = $(filter %.c %.S,$(wildcard $(TEST_TEST_DIR)/*))
TEST_FILES        = $(notdir $(TEST_FILES_FULL))


# Separate object file lists for .c and .S files
C_OBJS := $(patsubst %.c,%.o,$(filter %.c,$(TEST_FILES)))
S_OBJS := $(patsubst %.S,%.o,$(filter %.S,$(TEST_FILES)))

# Combine them to get TEST_OBJS
TEST_OBJS := $(C_OBJS) $(S_OBJS)


# If a test defines "default_cflags" in its yaml, then it is responsible to define ALL flags
# Otherwise add the default cflags in the variable CFLAGS defined above
ifneq ($(TEST_DEFAULT_CFLAGS),)
TEST_CFLAGS += $(TEST_DEFAULT_CFLAGS)
else
TEST_CFLAGS += $(CFLAGS)
endif

# Optionally use linker script provided in test directory
# this must be evaluated at access time, so ifeq/ifneq does
# not get parsed correctly
TEST_RESULTS_LD = $(addprefix $(SIM_TEST_PROGRAM_RESULTS)/, link.ld)
TEST_LD         = $(addprefix $(TEST_TEST_DIR)/, link.ld)

LD_LIBRARY 	= $(if $(wildcard $(TEST_RESULTS_LD)),-L $(SIM_TEST_PROGRAM_RESULTS),$(if $(wildcard $(TEST_LD)),-L $(TEST_TEST_DIR),))
LD_FILE 	= $(if $(wildcard $(TEST_RESULTS_LD)),$(TEST_RESULTS_LD),$(if $(wildcard $(TEST_LD)),$(TEST_LD),$(BSP)/link.ld))
LD_LIBRARY += -L $(SIM_BSP_RESULTS)


#.PHONY: hex

# Shorthand target to only build the firmware using the hex and elf suffix rules above
#hex: $(SIM_TEST_PROGRAM_RESULTS)/$(TEST_PROGRAM)$(OPT_RUN_INDEX_SUFFIX).hex

bsp:
	@echo "$(BANNER)"
	@echo "* Compiling the BSP"
	@echo "$(BANNER)"
	mkdir -p $(SIM_BSP_RESULTS)
	cp $(BSP)/Makefile $(SIM_BSP_RESULTS)
	make -C $(SIM_BSP_RESULTS) \
		VPATH=$(BSP) \
		RISCV=$(RISCV) \
		RISCV_PREFIX=$(RISCV_PREFIX) \
		RISCV_EXE_PREFIX=$(RISCV_EXE_PREFIX) \
		RISCV_MARCH=$(RISCV_MARCH) \
		RISCV_CC=$(RISCV_CC) \
		RISCV_CFLAGS="$(RISCV_CFLAGS)" \
		all

compile:
	@echo "$(BANNER)"
	@echo "* Compiling the test"
	@echo "$(BANNER)"
	mkdir -p $(SIM_BSP_RESULTS)
	cp $(BSP)/Makefile $(SIM_BSP_RESULTS)
	make -C $(SIM_BSP_RESULTS) \
		SRCS=$(TEST_FILES)     \
		VPATH=$(TEST_TEST_DIR) \
		RISCV=$(RISCV) \
		RISCV_PREFIX=$(RISCV_PREFIX) \
		RISCV_EXE_PREFIX=$(RISCV_EXE_PREFIX) \
		RISCV_MARCH=$(RISCV_MARCH) \
		RISCV_CC=$(RISCV_CC) \
		RISCV_CFLAGS="$(RISCV_CFLAGS)" \
		compile

%.elf:
	@echo "$(BANNER)"
	@echo "* Compiling the test"
	@echo "$(BANNER)"
	mkdir -p $(SIM_BSP_RESULTS)
	cp $(BSP)/Makefile $(SIM_BSP_RESULTS)
	make -C $(SIM_BSP_RESULTS) \
		APP_FILES=$(TEST_FILES)    \
		VPATH=$(TEST_TEST_DIR):$(BSP) \
		RISCV=$(RISCV) \
		RISCV_PREFIX=$(RISCV_PREFIX) \
		RISCV_EXE_PREFIX=$(RISCV_EXE_PREFIX) \
		RISCV_MARCH=$(RISCV_MARCH) \
		RISCV_CC=$(RISCV_CC) \
		RISCV_CFLAGS="$(RISCV_CFLAGS)" \
		LD_FILE=$(BSP)/link.ld \
		$@


clean_bsp:
#	make -C $(BSP) clean
	rm -rf $(SIM_BSP_RESULTS)