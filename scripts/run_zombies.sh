#!/bin/bash

set -eu

# Set PARAM_LINE from the first argument to this script
# PARAM_LINE is the string containing the model parameters for a run.
PARAM_LINE=$1

# Set EMEWS_ROOT to the root directory of the project (i.e. the directory
# that contains the scripts, swift, etc. directories and files)
EMEWS_ROOT=$2

# Each model run, runs in its own "instance" directory
# Set INSTANCE_DIRECTORY to that and cd into it.
INSTANCE_DIRECTORY=$3
cd $INSTANCE_DIRECTORY


#source /home/nick/.venv/r4py-py3.10/bin/activate
PYTHON=$( which python3 )
echo $PYTHON
ZOMBIES_YAML=$EMEWS_ROOT/zombies/zombie_model.yaml
ZOMBIES_MODEL=$EMEWS_ROOT/zombies/zombies.py

# TODO: Define the command to run the model. For example,
# MODEL_CMD="python"
MODEL_CMD="mpirun"
# TODO: Define the arguments to the MODEL_CMD. Each argument should be
# surrounded by quotes and separated by spaces. For example,
# arg_array=("$EMEWS_ROOT/python/my_model.py" "$PARAM_LINE" "$OUTPUT_FILE" "$TRIAL_ID")
arg_array=( "-n" "1" "$PYTHON" "$ZOMBIES_MODEL" "$ZOMBIES_YAML" "$PARAM_LINE")

# Turn bash error checking off. This is
# required to properly handle the model execution
# return values and the optional timeout.
set +e
echo "Running $MODEL_CMD ${arg_array[@]}"

"$MODEL_CMD" "${arg_array[@]}"

# $? is the exit status of the most recently executed command (i.e the
# line above)
RES=$?
if [ "$RES" -ne 0 ]; then
	if [ "$RES" == 124 ]; then
    echo "---> Timeout error in $MODEL_CMD ${arg_array[@]}"
  else
	   echo "---> Error in $MODEL_CMD ${arg_array[@]}"
  fi
fi