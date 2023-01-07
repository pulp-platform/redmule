export PENV=$(pwd)/venv
python3.6 -m venv $PENV
source $PENV/bin/activate
pip install --upgrade pip
pip3 install numpy
pip3 install torch
deactivate
