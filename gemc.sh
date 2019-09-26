#!/bin/bash
export TOR=$1
export SOL=$2
export INPUT=$3
export OUTPUT=$4
export GCARD=$5

export JLAB_ROOT=/jlab
export JLAB_VERSION=2.3
export CLAS12TAG=4.3.0
export FIELD_DIR=/jlab/noarch/data

source /jlab/2.3/ce/jlab.sh


gemc /jlab/clas12Tags/gcards/${GCARD}.gcard -USE_GUI=0 -OUTPUT="evio, ${OUTPUT}" -INPUT_GEN_FILE="LUND, ${INPUT}" -SCALE_FIELD="TorusSymmetric, ${TOR}" -SCALE_FIELD="clas12-newSolenoid, ${SOL}"
