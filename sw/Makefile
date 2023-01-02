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
#
# Author: Yvan Tortorella (yvan.tortorella@unibo.it)
#
# RedMulE Makefile

APP = redmule_test
DMA ?= 0
INCDIR := $(shell pwd)/inc

APP_INC := $(INCDIR)

ifeq ($(DMA), 0)
    APP_SRCS += $(APP).c utils.c
else
    APP_SRCS += test_tpu_stall.c tpu_func.c lfsr32.c
endif

# This is because we run the test with pulp-sdk
platform=rtl

APP_CFLAGS += -O3 -g -I.

include $(RULES_DIR)/pmsis_rules.mk
