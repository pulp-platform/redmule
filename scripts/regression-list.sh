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

export Target

python3 "$ScriptDir/bwruntests.py" --yaml -t $BASE_TIMEOUT -p "$N_PROC" "$REGR_FILE"
