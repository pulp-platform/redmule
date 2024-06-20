#!/bin/bash

BASE_TIMEOUT=120

PARAMS=(
    96 96 96
    128 128 128
    12 16 16
    24 16 16
    48 32 32
    30 32 17
    24 32 1
    31 32 16
    17 32 16
    31 32 31
    17 32 3
    5  32 17
    5  32 3
    36 31 32
    12 31 16
    # 23 31 31 
    24 17 32
    24 20 32
    #23 17 33
    #23 20 33
    #3  11 32
    #17 13 16
    #17 13 17
)

VSIM_LOGFILE=vsim.log
rm -f $VSIM_LOGFILE


run_regr() {
    make golden M=$M N=$N K=$K > /dev/null
    make all USE_REDUNDANCY=$SW_REDUNDANCY 1>/dev/null 2>&1
    timeout $BASE_TIMEOUT make run USE_ECC=$USE_ECC USE_REDUNDANCY=$HW_REDUNDANCY 1>$VSIM_LOGFILE 2>&1
    
    # If you want detailed output, uncomment this line
    # tail -10 $VSIM_LOGFILE

    if [[ $? -eq 124 ]]; then
        STATUS="TIMEOUT"
    else
        if grep -wq "Errors: 0," $VSIM_LOGFILE; then
            STATUS="OK     "
        else
            STATUS="ERROR  "
        fi
    fi
    echo "$STATUS: M=$M N=$N K=$K, ECC=$USE_ECC, HW_RED=$HW_REDUNDANCY, SW_RED=${SW_REDUNDANCY}"
}

for SW_REDUNDANCY in 0 1; do
    for HW_REDUNDANCY in 0 1; do
        for USE_ECC in 0 1; do
            i=0
            while [[ $i -lt ${#PARAMS[@]} ]]; do

                # For redundant operations we reduce the size of the matrix so run time is about the same
                M=$((${PARAMS[$i]} / (1 + $SW_REDUNDANCY)))
                N=${PARAMS[$((i + 1))]}
                K=${PARAMS[$((i + 2))]}
                i=$((i + 3))        
                run_regr
            done
        done
    done
done