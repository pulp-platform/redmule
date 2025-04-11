# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Yvan Tortorella <yvan.tortorella@unibo.it>
#

sim_targs += -t rtl -t cv32e40p_include_tracer -t test
sim_defs  += -D CV32E40P_TRACE_EXECUTION

ifeq ($(REDMULE_COMPLEX),1)
	sim_targs += -t redmule_test_complex
else
	sim_targs += -t redmule_test_hwpe
endif
