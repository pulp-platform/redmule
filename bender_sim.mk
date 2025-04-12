# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Yvan Tortorella <yvan.tortorella@unibo.it>
#

sim_targs += -t redmule_test

ifneq ($(target),verilator)
ifeq ($(UseXif),1)
	sim_targs += -t cv32e40x_bhv
	common_defs += -D CV32E40X_TRACE_EXECUTION
else
	sim_targs += -t cv32e40p_include_tracer
	sim_defs  += -D CV32E40P_TRACE_EXECUTION
endif
endif
