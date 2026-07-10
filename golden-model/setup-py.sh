# Copyright 2023 ETH Zurich and University of Bologna.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0
#
# Yvan Tortorella <yvan.tortorella@unibo.it>
#

export PYTHON=python3
export PENV=$(pwd)/venv
command -v uv >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh
uv venv --python $PYTHON $PENV
source $PENV/bin/activate
uv pip install numpy
uv pip install torch --index-url https://download.pytorch.org/whl/cpu
uv pip install prettytable pyyaml junit-xml

deactivate
