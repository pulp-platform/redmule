RTL=/scratch/ytortorella/upstream-redmule-tb/redmule-tb/hw/rtl
IPS=/scratch/ytortorella/upstream-redmule-tb/redmule-tb/hw/ips


# tb_veri
SRC_TB_VERI= \
    ${RTL}/./sim_hwpe.sv \
    ${RTL}/./tb_dummy_memory.sv \

INC_RTL=${INC_TB_VERI} \


SRC_RTL=${SRC_TB_VERI} \
