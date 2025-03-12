# #!/usr/bin/env bash
# Copyright 2022 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Cyril Koenig <cykoenig@iis.ee.ethz.ch>

TESTBENCH=redmule_tb

# Set full path to c++ compiler.
if [ -z "${CXX_PATH}" ]; then
    if [ -z "${CXX}" ]; then
        CXX="g++"
    fi
    CXX_PATH=`which ${CXX}`
fi

# Set default VCS binary
[[ -z "${VERDI_VERSION}" ]] && VERDI_VERSION=""
[[ -z "${VCS_VERSION}" ]]   && VCS_VERSION=""
[[ -z "${VCS_BIN}" ]]       && VCS_BIN="${VCS_VERSION} vcs"

flags="-full64 -kdb "
# Set default to fast simulation flags.
if [ -z "${VCSARGS}" ]; then
    # Use -debug_access+all for waveform debugging
    flags+="-O2 -debug_access=r -debug_region=1,${TESTBENCH} "
fi

flags+="-cpp ${CXX_PATH} "

pargs=""

COLOR_NC='\e[0m'
COLOR_BLUE='\e[0;34m'

${VCS_BIN} ${flags} ${TESTBENCH} | tee elaborate.log

# Start simulation
printf ${COLOR_BLUE}"${VCS_VERSION} ${VERDI_VERSION} ./simv ${pargs}"${COLOR_NC}"\n"
${VCS_VERSION} ${VERDI_VERSION} ./simv ${pargs} | tee simulate.log
