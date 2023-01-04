# Copyright (C) 2022-2023 ETH Zurich, University of Bologna
# All rights reserved.
#
# This software may be modified and distributed under the terms
# of the BSD license.  See the LICENSE file for details.
#
# Author: Yvan Tortorella (yvan.tortorella@unibo.it)
#
# List of RTL components for ipstools dependency handling

mkfile_path := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))

.PHONY: build clean lib

build:
	@make --no-print-directory -f $(mkfile_path)/rtl/rtl.mk build

lib:
	@make --no-print-directory -f $(mkfile_path)/rtl/rtl.mk lib

clean:
	@make --no-print-directory -f $(mkfile_path)/rtl/rtl.mk clean
