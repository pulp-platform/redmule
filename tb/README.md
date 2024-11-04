## CV32/TB: testbenches for the CV32E40P CORE-V family of RISC-V cores.
Derived from the
[tb](https://github.com/pulp-platform/riscv/tree/master/tb)
directory of the PULP-Platform RI5CY project.  There are two distinct
testbenches:

### core
Modified to remove a few RTL files (placed these in the rtl directory). This
testbench supports Verilator and we will do what we can to maintain Verilator
support here.  Note that `tb_riscv` is now a sub-directory of `core`.

