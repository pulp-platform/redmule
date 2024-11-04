# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Andrea Belano <andrea.belano@studio.unibo.it>
# Yvan Tortorella <yvan.tortorella@unibo.it>
#

#!/bin/bash
Red="\e[31m"
Green="\e[32m"
EndColor="\e[0m"

BASE_TIMEOUT=45

# Print the matrix when there are errors
VERBOSE=1

M_STEP=12
N_STEP=4
K_STEP=16

M_RANGE=(0 1 2)
N_RANGE=(0 1 3 4 5 7)
K_RANGE=(0 1 2)

# The possible values of M, N and K are computed as STEP * RANGE + PATTERN
PATTERNS=(
    '0' 
    '1' 
    'STEP-1' 
    'STEP/2'
    'STEP/2+1'
    'STEP/2-1'
)

LINE=""
OLDOFFS=0

function build_matrix {
    NUM_GREEN=$(($OFFSET - $OLDOFFS - 2))
         
    if [[ $NUM_GREEN -gt 0 ]]; then
        LINE="$LINE"$(printf O'%.0s' $(seq $NUM_GREEN))
    fi

    case $MSW$LSW in
        01)
            LINE="$LINE"XO
        ;;

        10)
            LINE="$LINE"OX
        ;;

        11)
            LINE="$LINE"XX
        ;;
    esac

    OLDOFFS=$OFFSET
}

function print_matrix {
    if [[ $(($OFFSET + 2)) -ne $(($M*$K)) ]]; then
        LINE="$LINE"$(printf O'%.0s' $(seq $(($M*$K - $OFFSET - 2))))
    fi

    MAT=$(echo -e $LINE | fold -w $K | sed s/'\(O\|X\)'/" \\0"/g | sed s/'\(O\+\)'/"\\$Green"\\0"\\$EndColor"/g | sed s/'\(X\+\)'/"\\$Red"\\0"\\$EndColor"/g)

    echo -e "$MAT"
}

for param in M N K
do
    RANGE_NAME="$param"_RANGE
    LIST="$RANGE_NAME[@]"
    STEP="$param"_STEP
    VALS="$param"_VALS
    VALS_LIST="$VALS[@]"

    k=0

    for i in ${!LIST}
    do
        for  offs in ${PATTERNS[@]}
        do
            EXPR=${offs//STEP/${!STEP}}

            if ! (printf '%s\0' ${!VALS_LIST} | grep -Fxqz -- $((i*$STEP+$EXPR)) || [[ $((i*$STEP+$EXPR)) -lt 1 ]]); then
                (($VALS[$k]=$((i*$STEP+$EXPR))))
            fi

            k=$(($k+1))
        done
    done
done

echo M={${M_VALS[@]}}
echo N={${N_VALS[@]}}
echo K={${K_VALS[@]}}

make hw-clean hw-build 1>/dev/null 2>&1

for M in ${M_VALS[@]}
do
    for N in ${N_VALS[@]}
    do
        for K in ${K_VALS[@]}
        do
            LEN=$(($M * $K))
        
            make golden M=$M N=$N K=$K 1>/dev/null 2>&1

            make sw-clean sw-build verbose=$VERBOSE 1>/dev/null 2>&1

            timeout $BASE_TIMEOUT make run 1>/dev/null 2>&1

            if [[ $? -eq 124 ]]; then
                echo -e "${Red}TIMEOUT\t${EndColor}: M=$M N=$N K=$K"
            else
                grep -rn "Success!" $PWD/vsim/transcript 1>/dev/null 2>&1
            
                if [[ $? -eq 0 ]]; then
                    echo -e "${Green}OK\t${EndColor}: M=$M N=$N K=$K"
                else
                    echo -e "${Red}ERROR\t${EndColor}: M=$M N=$N K=$K"

                    if [[ $VERBOSE -eq 1 ]]; then
                        ERRORS=$(grep -Eo "(MSW|LSW|@ 0x[0-f]*$)" $PWD/vsim/transcript | grep -Eo "(MSW|LSW|0x[0-f]+)")

                        MSW=0
                        LSW=0

                        for S in $ERRORS
                        do
                            if [[ $S == "MSW" ]]; then
                                MSW=1
                            elif [[ $S == "LSW" ]]; then
                                LSW=1
                            else
                                OFFSET=$(($S / 2))
                                
                                build_matrix                                

                                MSW=0
                                LSW=0
                            fi
                        done

                        print_matrix

                        LINE=""
                        OLDOFFS=0
                    fi
                fi
            fi
        done
    done
done
