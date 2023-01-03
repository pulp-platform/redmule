# RedMulE
RedMulE (**Red**uced-Precision Matrix **Mul**tiplication **E**ngine) is an open-source hardware accelerator based on the [HWPE](https://hwpe-doc.readthedocs.io/en/latest/index.html) template. It is designed to accelerate General Matrix-Matrix Operations (GEMM-Ops) on Floating-Point (FP) FP16 and FP8 input matrices. The keyword GEMM-Ops includes all the matrix operations of the kind **Z = (X op1 W) op2 Y**. The operators *op1* and *op2* can be any of those grouped in the following table:

|         Kernel            |  *op1*   |  *op2*  |           Res           |
| ------------------------- | -------- | ------- | ----------------------- |
|          GEMM             |    x     |    +    | *Z = (X x W) + Y*       |
| Maximum Critical Path     |    +     |   max   | *Z = max[(X + W), Y]*   |
| All-Pairs Shortest Paths  |    +     |   min   | *Z = min[(X + W), Y]*   |
| Maximum Reliability Path  |    x     |   max   | *Z = max[(X x W), Y]*   |
| Minimum Reliability Path  |    x     |   max   | *Z = min[(X x W), Y]*   |
| Minimum Spanning Tree     |   max    |   min   | *Z = min[max(X, W), Y]* |
| Maximum Capacity Tree     |   min    |   max   | *Z = max[min(X, W), Y]* |

To support GEMM-Ops with both FP8 and FP16 formats, RedMulE features input and output cast modules that allow for casting input matrices from FP8 to FP16 and the computed output matrix from FP16 to FP8. This allows for operating on larger internal precision guaranteeing enough accuracy during intermediate accumulations. 
## Hardware Architecture
RedMulE is fully parametric and based on a 2-Dimensional array (*Engine*) of Computing Elements (CE) that operate in lock-step. The overall architecture is shown in the figure below.

![](doc/redmule_overview.png)

RedMulE's *Engine* features a parametric number of CEs (expressed as *ARRAY_WIDTH* and *ARRAY_HEIGHT*), and a parametric number of Pipeline Registers (*PIPE_REGS*) within each CE. The value of the *ARRAY_WIDTH* parameter is upper-bounded as it depends on the *ARRAY_HEIGHT* and the *PIPE_REGS* parameters. Its maximum value equals **ARRAY_HEIGHTxPIPE_REGS**, while the bitwidth of the memory port can be calculated as **ARRAY_HEIGHTx(PIPE_REGS+1)xnumbits(FP_FORMAT)**. *FP_FORMAT* corresponds always to the internal precision (FP16). For example, the default RedMulE configuration provides *ARRAY_HEIGHT*=4 and *PIPE_REGS*=3, resulting in a 256-bits memory port and in *ARRAY_WIDTH* $\le$ 12. Each CE contains a Fused Multiply-Add (FMA) and two FP Non Computation Operators (FNCOMP) to support all the GEMM-Ops grouped under the table above. The FMA and FNCOMP modules are adapted from the open-source [Transprecision Floating-Point Unit](https://github.com/openhwgroup/cvfpu).
RedMulE code is written in System Verilog and all its submodules are available under the `rtl` folder. The `rtl/redmule_pkg.sv` contains all the required parameters available to instantiate RedMulE.
RedMulE's dependencies are handled through [bender](https://github.com/pulp-platform/bender), but can also be managed through IPstools.

## RedMulE Testbench and Golden Model
A complete testing environment for RedMulE is available in the [redmule-tb](https://github.com/pulp-platform/redmule-tb). In this environment it is possible to write bare-metal C code for an Ibex core to program RedMulE and start its operation. The *redmule-tb* also features the [redmule-golden-model](https://github.com/pulp-platform/redmule-golden-model) written in Python to generate random FP16 or FP8 stimuly and golden results for RedMulE using GEMM-Ops to further improve and develop the accelerator.

## License and Citation
RedMulE is an open-source project licensed under the SolderPad Hardware License v0.51.
If you want to use RedMulE for academic purposes, please cite it as:

```
@INPROCEEDINGS{9774759,
  author={Tortorella, Yvan and Bertaccini, Luca and Rossi, Davide and Benini, Luca and Conti, Francesco},
  booktitle={2022 Design, Automation & Test in Europe Conference & Exhibition (DATE)}, 
  title={RedMulE: A Compact FP16 Matrix-Multiplication Accelerator for Adaptive Deep Learning on RISC-V-Based Ultra-Low-Power SoCs}, 
  year={2022},
  pages={1099-1102},
  doi={10.23919/DATE54114.2022.9774759}
}
```

See you, space cowboy!