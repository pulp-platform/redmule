export PENV=$(pwd)/venv
python -m venv $PENV
source $PENV/bin/activate
pip install --upgrade pip
pip3 install numpy
pip3 install torch==1.11.0
deactivate
