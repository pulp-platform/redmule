# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Yvan Tortorella <yvan.tortorella@unibo.it>
#

common_targs += -t rtl
common_defs  += -D COREV_ASSERT_OFF
common_defs  += -D PACE_ENABLED
