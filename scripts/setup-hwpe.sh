export BENDER_DIR=$(pwd)/hw/bender
echo "Exporting bender path to $BENDER_DIR"
export PATH=$BENDER_DIR:$PATH
unset BENDER_DIR
echo "Exporting SDK and GCC Toolchain paths"
export PATH=/usr/pack/pulpsdk-1.0-kgf/artifactory/pulp-sdk-release/pkg/pulp_riscv_gcc/1.0.16/bin:$PATH
export PATH=/usr/pack/gcc-5.2.0-af/x86_64-rhe6-linux/bin:$PATH
export XLEN=32
export XTEN=imc
export REDMULE_COMPLEX=0
