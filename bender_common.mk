# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Yvan Tortorella <yvan.tortorella@unibo.it>
#

common_targs += -t cv32e40p_exclude_tracer

ifeq ($(REDMULE_COMPLEX),1)
	common_targs += -t redmule_complex
else
	common_targs += -t redmule_hwpe
endif

common_defs  += -D COREV_ASSERT_OFF
