# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Yvan Tortorella <yvan.tortorella@unibo.it>
#

synth_targs +=

ifeq ($(REDMULE_COMPLEX),1)
	synth_defs  += -D REDMULE_COMPLEX_SYNTH
	VLT_FLAGS   +=  -DREDMULE_COMPLEX_SYNTH
else
	synth_defs  += -D REDMULE_HWPE_SYNTH
	VLT_FLAGS   +=  -DREDMULE_HWPE_SYNTH
endif
