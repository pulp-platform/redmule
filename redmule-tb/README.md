# RedMulE Testbench

A complete testbench for the RedMulE accelerator.
The `redmule-tb` features:
* A RedMulE instance;
* An Ibex core as a controller and programmer;
* Dummy memories to simulate software stack, data-memory and instruction memory.

The redmule-tb is based on the [hwpe-tb](https://github.com/pulp-platform/hwpe-tb).

## Hardware Setup
All the HW components of the testbench are located under the `hw` folder. It contains:
* `rtl` folder containg:
    * redmule_tb.sv: System Verilog testbench of RedMulE for Questasim simulation;
    * tb_dummy_memory.sv: dummy memories used to test the accelerator resilience against memory stalls;
    * redmule_sim.sv: System Verilog testbench of RedMulE for Verilator simulation;
* Bender.yml: bender manifest for bender-based dependency handling;
* ips/rtl_list.yml: manifests for the IPstools-based depenendency handling.

## Software Setup
The software required to use the testbench is located under the `sw` folder. It contains:
* archi_redmule.h: a software description of the RedMulE architecture (like the register-file map, the supported FP format, ...);
* hal_redmule.h: a Hardware Abstraction Layer (HAL) containg a few APIs to program RedMulE and start its operation.
* redmule.c: the SW test executed by the Ibex core;

## Getting Started
From the `redmule-tb` folder source the `setup.sh` script to export the path to the bender, to the SDK, and to the toolchain (if not already installed, one can be downloaded from [here](https://github.com/pulp-platform/pulp-riscv-gnu-toolchain)):
```
source setup.sh
```
Install bender:
```
make bender
```
Bender installation is not mandatory. If any bender version is already installed, it is just needed to add the absolute path to the `bender` to the `PATH` variable. 

Clone the dependencies and generate the compilation script:
```
make update-ips
```
Build the hardware:
```
make build-hw
```
The last two steps can be done using IPstools instead of bender by running the make commands with `ipstools=1` (e.g. `make update-ips ipstools=1`).

## Run the test

Clone the pulp-sdk (if not already cloned somewhere else):
```
make sdk
```
Source the relative setup script:
```
source /absolute-path-to-the/pulp-sdk/configs/pulp-open.sh
```
The previouse make command clones the pulp-sdk under `sw`, so it is possible to:
```
source sw/pulp-sdk/configs/pulp-open.sh
```
Now, it is possible to execute the test:
```
make all
make run (gui=1 to open the Questasim Graphic User Interface)
```
It is possible to run the test introducing a parametric probability of stall by explicitly passing the `P_STALL` parameter while running the test. For example, to set a probability of stall of the 10% run:
```
make run P_STALL=0.1
```

## Golden Model Generation
When installing the project, the [redmule-golden-model](https://github.com/pulp-platform/redmule-golden-model) can be cloned through the command:
```
git submodule update --init --recursive
```
Refer to its README for its installation and to verify that all the prerequisites are satisfied.
It is possible to generate fresh golden models from the top-level folder of `redmule-tb` through its Makefile. The parameters that can be used to generate different golden models are the following:
* OP: this can be any of the GEMM-Ops supported by RedMulE (refer to the redmule-golde-model README to know more about it);
* fp_fmt: FP format fot the generated matrices, it can either be FP16 or FP8;
* M, N, K: number of rows and columns of the generated matrices (refer to the redmule-golde-model README to know more about it);
* SW: path to a folder to which it is desired to export the golden data as header files.

By default, the redmule-tb Makefile generates FP16 matrices for a GEMM operation, with M=12, N=16, K=16, and exports the generated header files under `sw/inc`. To generate a different golden model, let's say, for a MINMAX operation, using FP8 encoding and operating on [96x64]*[64x64] matrices, and exporting the header files under the `./inc` path, create the `inc` dir (`mkdir inc`) and then run:
```
make golden OP=minmax SW=$(pwd) M=96 N=64 K=64 fp_fmt=FP8
```
By removing the `SW=$(pwd)`, the same golden model is generated under `sw/inc`.