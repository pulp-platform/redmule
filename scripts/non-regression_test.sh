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
    23 31 31 
    24 17 32
    24 20 32
    #23 17 33
    #23 20 33
    #3  11 32
    #17 13 16
    #17 13 17
)

run_regr() {
    local use_ecc=$1
    make golden M=$M N=$N K=$K > /dev/null
    make all 1>/dev/null 2>&1
    if [[ $use_ecc -eq 1 ]]; then
        timeout $BASE_TIMEOUT make run USE_ECC=1 1>/dev/null 2>&1
    else
        timeout $BASE_TIMEOUT make run 1>/dev/null 2>&1
    fi
    if [[ $? -eq 124 ]]; then
        echo "ERROR : M=$M N=$N K=$K"
    else
        echo "OK    : M=$M N=$N K=$K"
    fi
}

i=0
while [[ $i -lt ${#PARAMS[@]} ]]; do
    M=${PARAMS[$i]}
    N=${PARAMS[$((i + 1))]}
    K=${PARAMS[$((i + 2))]}
    i=$((i + 3))

    run_regr 0
done

# Second loop: USE_ECC=1
echo "Running with USE_ECC=1"
i=0
while [[ $i -lt ${#PARAMS[@]} ]]; do
    M=${PARAMS[$i]}
    N=${PARAMS[$((i + 1))]}
    K=${PARAMS[$((i + 2))]}
    i=$((i + 3))

    run_regr 1
done