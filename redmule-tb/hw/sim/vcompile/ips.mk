# Copyright (C) 2022-2023 ETH Zurich, University of Bologna
# All rights reserved.
#
# This software may be modified and distributed under the terms
# of the BSD license.  See the LICENSE file for details.
#
# Author: Yvan Tortorella (yvan.tortorella@unibo.it)
#
# List of IPs for ipstools dependency handling

mkfile_path := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))

.PHONY: build clean lib

build:
	@make --no-print-directory -f $(mkfile_path)/ips/common_cells.mk build
	@make --no-print-directory -f $(mkfile_path)/ips/tech_cells_generic.mk build
	@make --no-print-directory -f $(mkfile_path)/ips/scm.mk build
	@make --no-print-directory -f $(mkfile_path)/ips/zero-riscy.mk build
	@make --no-print-directory -f $(mkfile_path)/ips/cluster_interconnect.mk build
	@make --no-print-directory -f $(mkfile_path)/ips/hwpe-ctrl.mk build
	@make --no-print-directory -f $(mkfile_path)/ips/hwpe-stream.mk build
	@make --no-print-directory -f $(mkfile_path)/ips/hci.mk build
	@make --no-print-directory -f $(mkfile_path)/ips/fpnew.mk build
	@make --no-print-directory -f $(mkfile_path)/ips/redmule.mk build

lib:
	@make --no-print-directory -f $(mkfile_path)/ips/common_cells.mk lib
	@make --no-print-directory -f $(mkfile_path)/ips/tech_cells_generic.mk lib
	@make --no-print-directory -f $(mkfile_path)/ips/scm.mk lib
	@make --no-print-directory -f $(mkfile_path)/ips/zero-riscy.mk lib
	@make --no-print-directory -f $(mkfile_path)/ips/cluster_interconnect.mk lib
	@make --no-print-directory -f $(mkfile_path)/ips/hwpe-ctrl.mk lib
	@make --no-print-directory -f $(mkfile_path)/ips/hwpe-stream.mk lib
	@make --no-print-directory -f $(mkfile_path)/ips/hci.mk lib
	@make --no-print-directory -f $(mkfile_path)/ips/fpnew.mk lib
	@make --no-print-directory -f $(mkfile_path)/ips/redmule.mk lib

clean:
	@make --no-print-directory -f $(mkfile_path)/ips/common_cells.mk clean
	@make --no-print-directory -f $(mkfile_path)/ips/tech_cells_generic.mk clean
	@make --no-print-directory -f $(mkfile_path)/ips/scm.mk clean
	@make --no-print-directory -f $(mkfile_path)/ips/zero-riscy.mk clean
	@make --no-print-directory -f $(mkfile_path)/ips/cluster_interconnect.mk clean
	@make --no-print-directory -f $(mkfile_path)/ips/hwpe-ctrl.mk clean
	@make --no-print-directory -f $(mkfile_path)/ips/hwpe-stream.mk clean
	@make --no-print-directory -f $(mkfile_path)/ips/hci.mk clean
	@make --no-print-directory -f $(mkfile_path)/ips/fpnew.mk clean
	@make --no-print-directory -f $(mkfile_path)/ips/redmule.mk clean
