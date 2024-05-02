#! /usr/bin/env bash
set -eu

if [ "$#" -ne 2 ]; then
  script_name=$(basename $0)
  echo "Usage: ${script_name} exp_id cfg_file"
  exit 1
fi

# Uncomment to turn on swift/t logging. Can also set TURBINE_LOG,
# TURBINE_DEBUG, and ADLB_DEBUG to 0 to turn off logging
# export TURBINE_LOG=1 TURBINE_DEBUG=1 ADLB_DEBUG=1
export EMEWS_PROJECT_ROOT=$( cd $( dirname $0 )/.. ; /bin/pwd )
# source some utility functions used by EMEWS in this script
source "${EMEWS_PROJECT_ROOT}/etc/emews_utils.sh"

export EXPID=$1
export TURBINE_OUTPUT=$EMEWS_PROJECT_ROOT/experiments/$EXPID
check_directory_exists

CFG_FILE=$2
source $CFG_FILE

echo "--------------------------"
echo "WALLTIME:              $CFG_WALLTIME"
echo "PROCS:                 $CFG_PROCS"
echo "PPN:                   $CFG_PPN"
echo "QUEUE:                 $CFG_QUEUE"
echo "PROJECT:               $CFG_PROJECT"
echo "DB_HOST:               $CFG_DB_HOST"
echo "DB_USER:               $CFG_DB_USER"
echo "TASK_TYPE:             $CFG_TASK_TYPE"
echo "WORKER_POOL_ID:        $CFG_POOL_ID"
echo "--------------------------"

export PROCS=$CFG_PROCS
export QUEUE=$CFG_QUEUE
export PROJECT=$CFG_PROJECT
export WALLTIME=$CFG_WALLTIME
export PPN=$CFG_PPN
export TURBINE_JOBNAME="${EXPID}_job"
export TURBINE_MPI_THREAD=1

# If your HPC system aborts with a fork() related error when trying to run the job,
# uncomment this export, and add "-e RDMAV_FORK_SAFE" to the swift-t arguments
# at the end this file.
# export RDMAV_FORK_SAFE=1

mkdir -p $TURBINE_OUTPUT
cp $CFG_FILE $TURBINE_OUTPUT/cfg.cfg

# TODO: If R cannot be found, then these will need to be
# uncommented and set correctly.
# export R_HOME=/path/to/R
# export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$R_HOME/lib

# EQSQL swift extension location
EQSQL=$EMEWS_PROJECT_ROOT/ext/EQ-SQL
EMEWS_EXT=$EMEWS_PROJECT_ROOT/ext/emews

# TODO: if Python cannot be found then uncomment
# and edit this line.
# export PYTHONHOME=/path/to/python

# TODO: if there are "Cannot find 
# X package" type Python errors then append
# the missing package's path to the PYTHONPATH
# variable below, separating the entries with ":"
export PYTHONPATH=$EMEWS_PROJECT_ROOT/python:$EQSQL

# Resident task workers and ranks
export TURBINE_RESIDENT_WORK_WORKERS=1
export RESIDENT_WORK_RANK=$(( PROCS - 2 ))

# EQSQ DB variables, set from the CFG file.
# To change, these edit the CFG file.
export DB_HOST=$CFG_DB_HOST
export DB_USER=$CFG_DB_USER
export DB_PORT=${CFG_DB_PORT:-}
export DB_NAME=$CFG_DB_NAME
export EQ_DB_RETRY_THRESHOLD=$CFG_DB_RETRY_THRESHOLD
export EQ_QUERY_TASK_TIMEOUT=1200

# TODO: Set MACHINE to your schedule type (e.g. pbs, slurm, cobalt etc.),
# or empty for an immediate non-queued unscheduled run
MACHINE=""

if [ -n "$MACHINE" ]; then
  MACHINE="-m $MACHINE"
else
  echo "Logging output and errors to $TURBINE_OUTPUT/output.txt"
  # Redirect stdout and stderr to output.txt
  # if running without a scheduler.
  exec &> "$TURBINE_OUTPUT/output.txt"
fi

CMD_LINE_ARGS="--trials=$CFG_TRIALS --task_type=$CFG_TASK_TYPE --batch_size=$CFG_BATCH_SIZE "
CMD_LINE_ARGS+="--batch_threshold=$CFG_BATCH_THRESHOLD --worker_pool_id=$CFG_POOL_ID $*"

# CMD_LINE_ARGS can be extended with +=:
# CMD_LINE_ARGS+="-another_arg=$ANOTHER_VAR"

# TODO: Some slurm machines may expect jobs to be run
# with srun, rather than mpiexec (for example). If
# so, uncomment this export.
# export TURBINE_LAUNCHER=srun

# TODO: Add any script variables that you want to log as
# part of the experiment meta data to the USER_VARS array,
# for example, USER_VARS=("VAR_1" "VAR_2")
USER_VARS=()
# log variables and script to to TURBINE_OUTPUT directory
log_script
# echo's anything following this to standard out
set -x
SWIFT_FILE=eqsql_worker_pool.swift
swift-t -n $PROCS $MACHINE -p -I $EQSQL -r $EQSQL \
    -I $EMEWS_EXT -r $EMEWS_EXT \
    -e TURBINE_MPI_THREAD \
    -e TURBINE_OUTPUT \
    -e EMEWS_PROJECT_ROOT \
    -e DB_HOST \
    -e DB_USER \
    -e DB_PORT \
    -e DB_NAME \
    -e EQ_DB_RETRY_THRESHOLD \
    -e EQ_QUERY_TASK_TIMEOUT \
    -e PYTHONPATH \
    -e RESIDENT_WORK_RANK \
    $EMEWS_PROJECT_ROOT/swift/$SWIFT_FILE \
    $CMD_LINE_ARGS
