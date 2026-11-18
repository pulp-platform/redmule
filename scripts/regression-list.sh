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

if [ -z "$Target" ]; then
    echo -e "${Red}Error: no Target defined. Set the  Target variable to \"vsim\" or \"verilator\" before continue.${EndColor}"
    exit 1
fi

ScriptDir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BASE_TIMEOUT=500
REGR_FILE="${REGR_FILE:-$ScriptDir/regression.yml}"
# Number of tests to run concurrently. Each test now builds into its own
# per-TEST_ID folder and only reads the shared, already-compiled RTL work
# library, so the runs are isolated. Override N_PROC per invocation (bounded by
# available Questa licenses / cores).
N_PROC="${N_PROC:-4}"
REDMULE_PARAM_SETS="${REDMULE_PARAM_SETS:-8x8 16x16 8x32 8x32x3}"

export Target

status=0

for param_set in $REDMULE_PARAM_SETS; do
    IFS=x read -r redmule_height redmule_width redmule_pipe_regs <<EOF
$param_set
EOF
    redmule_pipe_regs="${redmule_pipe_regs:-1}"

    if [ -z "$redmule_height" ] || [ -z "$redmule_width" ]; then
        echo -e "${Red}Error: invalid REDMULE_PARAM_SETS entry '$param_set'. Use the form HxW or HxWxP (e.g. 16x16 or 8x32x3, P = pipeline registers per CE, default 1).${EndColor}"
        exit 1
    fi

    export RedmuleHeight="$redmule_height"
    export RedmuleWidth="$redmule_width"
    export RedmulePipeRegs="$redmule_pipe_regs"
    if [ "$RedmulePipeRegs" -eq 1 ]; then
        cfg_name="${RedmuleHeight}x${RedmuleWidth}"
    else
        cfg_name="${RedmuleHeight}x${RedmuleWidth}_p${RedmulePipeRegs}"
    fi

    echo "== Running regression for RedMulE wrapper ${RedmuleHeight}x${RedmuleWidth}, ${RedmulePipeRegs} pipeline registers =="
    build_status=0
    make hw-clean target="$Target" || build_status=$?
    make hw-build target="$Target" RedmuleHeight="$RedmuleHeight" RedmuleWidth="$RedmuleWidth" RedmulePipeRegs="$RedmulePipeRegs" || build_status=$?
    if [ "$build_status" -ne 0 ]; then
        # Record the failure but keep going with the remaining parameter sets.
        status=$build_status
        continue
    fi
    python3 "$ScriptDir/bwruntests.py" --yaml -t $BASE_TIMEOUT -p "$N_PROC" \
        --perf "$ScriptDir/perf_${cfg_name}.json" "$REGR_FILE" || status=$?
done

exit $status
