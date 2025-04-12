# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Yvan Tortorella <yvan.tortorella@unibo.it>
#

common_targs += -t rtl
common_defs  += -D COREV_ASSERT_OFF

ifeq ($(UseXif),1)
	common_targs += -t redmule_complex
else
	common_targs += -t redmule_hwpe
endif
