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

# Best-effort: pick up the module-provided toolchain if `module` is
# available. No-op if the tools are already on PATH some other way.
module load questasim bender pulp-gcc7 >/dev/null 2>&1 || true

BASE_TIMEOUT=500
REGR_FILE="${REGR_FILE:-$ScriptDir/regression.yml}"

export Target

make hw-clean hw-build target=$Target Bender=bender Questa= 1>/dev/null 2>&1

python3 "$ScriptDir/bwruntests.py" --yaml -t $BASE_TIMEOUT -p 1 "$REGR_FILE"
