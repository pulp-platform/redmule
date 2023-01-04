include verilate_ips.mk
include verilate_rtl.mk

run: verilated/Vsim_hwpe
	cd verilated; HWPE_TB_STIM_INSTR=../../../build/sw/tb_hwpe.c/stim_instr.txt HWPE_TB_STIM_DATA=../../../build/sw/tb_hwpe.c/stim_data.txt ./Vsim_hwpe; cd -

all: verilated/Vsim_hwpe

verilated/Vsim_hwpe: verilated/Vsim_hwpe.mk
	make OPT_FAST="-O3 -fno-stack-protector" OPT_SLOW="-O2 -fno-stack-protector" -C verilated -f Vsim_hwpe.mk Vsim_hwpe

verilated/Vsim_hwpe.mk:
	verilator -O3 -cc -Wno-fatal --exe ../sim_main.cpp --Mdir verilated \
        --trace --trace-structs --trace-params \
        --autoflush \
        --Wno-width \
        --Wno-stmtdly \
        --Wno-unoptflat \
        --top-module sim_hwpe -Wno-BLKANDNBLK \
        ${INC_IPS} \
        ${INC_RTL} \
        ${SRC_IPS} \
        ${SRC_RTL}

clean:
	rm -rf verilated

