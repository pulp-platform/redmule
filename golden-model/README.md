# RedMulE Golden Model

Python golden model for the RedMulE accelerator

## Structure
The RedMulE Golden Model is intended to generate Floating-Point (FP) input and resulting matrices
for all the General Matrix-Matrix Operations (GEMM-Ops) supported by RedMulE, where GEMM-Ops
are all the operations of the kind:
```
Z = (X op1 Y) op2 Y
```

The repository contains two main folders for FP16 and FP8 golden model generation. Each folder
contains a `script` folder to generate the model for all the supported GEMM-Ops, i. e. :
* ADDMAX: Z = max((X + W), Y)
* ADDMIN: Z = min((X + W), Y)
* GEMM  : Z = (X x W) + Y
* MAXMIN: Z = min(max(X, W), Y)
* MINMAX: Z = max(min(X, W), Y)
* MULMAX: Z = max((X x W), Y)
* MULMIN: Z = min((X x W), Y)

## Getting started
First of all, clone the repository and move into it:
```
git@github.com:pulp-platform/redmule-golden-model.git
cd redmule-golden-model
```
The golden model make use of Python3.6 virtual environment, Numpy and Pytorch. These modules have
to be installed if they are not already present. To simplify this procedure, the repository
contains a `setup-py.sh` that can be sourced to install all these modules, and to export the
required environment variables. Thus, the first step is to:
```
source setup-py.sh
```

This will install a Python3.6 virtual environment under the `venv` folder.
The RedMulE Golden Model contains a `Makefile` that allows for easy golden matrices generation.
The parameters needed by such a Makefile are the following:
* M     : number of rows of the X, Y, and Z matrices;
* N     : number of columns of the X matrix, and as a consequence the number of rows of the W one;
* K     : number of columns of the W, Y, and Z matrices;
* fp_fmt: FP format, this can be FP16 or FP8;
* SW    : path to a folder to which it is desired to export the golden data as header files.

For example, if you want to generate the golden model for the MINMAX operation, using FP8 encoding,
under a local `inc` directory and using 64x64x64 matrices, first create the `inc` folder (`mkdir inc`) and then run:
```
make clean minmax M=64 N=64 K=64 fp_fmt=FP8 SW=$(pwd)/inc
```

Each execution of the RedMulE Golden Model also generates data in `.txt` format under the root
folder. The example showed above will generate a `minmax` folder containing a `txt` folder containing
the generated matrices.
