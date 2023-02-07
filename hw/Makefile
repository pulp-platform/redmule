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
# Makefile to manage dependencies through bender

ROOT           := $(shell pwd)
compile_script ?= compile.tcl

compile_flag = -suppress 2583 -suppress 13314

clean-env:
	rm -rf work
	rm -rf .bender
	rm -rf Bender.lock
	rm -rf compile.tcl
	rm -rf modelsim.ini
	rm -rf *.log
	rm -rf transcript
	rm -rf .cached_ipdb.json

update:
	bender/bender update

scripts: update
	bender/bender script vsim               \
	--vlog-arg="$(compile_flag)"     \
	--vcom-arg="-pedanticerrors"     \
	-t rtl -t test > ${compile_script}

opt:
	vopt +acc=npr -o vopt_tb redmule_tb -floatparameters+redmule_tb -work work

build:
	vsim -c -do 'source compile.tcl; quit'

lib:
	@touch modelsim.ini
	@mkdir -p work
	@vlib work
	@vmap work work
	@chmod +w modelsim.ini

clean:
	rm -rf work
	rm -rf modelsim.ini
