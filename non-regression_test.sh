#!/bin/bash

BASE_TIMEOUT=10

PARAMS=(
    12 16 16
    48 32 32
    30 32 17
    24 32 1
    31 32 16
    17 32 16
    31 32 31
    17 32 3
    5  32 17
    #5  32 3
    #36 31 32
    #16 31 16
    #3  11 32
    #17 13 16
    #17 13 17
)

i=0

while [[ $i -lt ${#PARAMS[@]} ]]
do

    M=${PARAMS[$i]}
    N=${PARAMS[$(( $i + 1 ))]}
    K=${PARAMS[$(( $i + 2 ))]}

    i=$(( $i + 3 ))
    
    make golden M=$M N=$N K=$K > /dev/null
    make all 1>/dev/null 2>&1
    timeout $BASE_TIMEOUT make run 1>/dev/null 2>&1
            
    if [[ $? -eq 124 ]]
    then
        echo "ERROR : M=$M N=$N K=$K"
    else
        echo "OK    : M=$M N=$N K=$K"
    fi
    
done
