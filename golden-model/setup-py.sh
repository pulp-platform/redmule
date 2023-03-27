export PYTHON=python3
export PENV=$(pwd)/venv
$PYTHON -m venv $PENV
source $PENV/bin/activate
pip install --upgrade pip
pip3 install numpy
pip3 install torch
deactivate
