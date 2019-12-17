#!/bin/sh

#INPUT Sequences file

#SBATCH -J rga_sim
#SBATCH -n 1
#SBATCH -N 1
#SBATCH --output=logfiles/rga_sim_%A_%a.out
#SBATCH --error=logfiles/rga_sim_%A_%a.err
#SBATCH -p BigMem
#SBATCH --array=1-1000%100

#change tmp
export TMPDIR="/local/${USER}"
export CLARA_HOME=/work/gothelab/clas12/software/clara
export CLAS12DIR=/work/gothelab/clas12/software/clara/plugins/clas12
export PATH=$PATH:$CLARA_HOME/bin:$CLAS12DIR/bin
export DATA_DIR=/work/gothelab/clas12/simulations/data
export HIPO_TOOLS=/work/gothelab/clas12/software
export ELASTIC_GEN=/work/gothelab/clas12/software/ElasticGen
export PATH=$PATH:$HIPO_TOOLS/bin:$ELASTIC_GEN/bin
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$HIPO_TOOLS/share/pkgconfig
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$HIPO_TOOLS/lib
export PYTHONPATH=$PYTHONPATH:$HIPO_TOOLS/lib


#load singularity
module load singularity/2.6.0
module load java/1.8.0_162

##***********************************************##
# Setup event generator
export NUM_EVENTS=50000
export BEAM_E=10.6041
export W_MIN=1.0
export W_MAX=3.5
export Q2_MIN=0.01
export Q2_MAX=20.0
# Change thse to change torus and solonid for run
export TOR=-1.0
export SOL=-1.0
# Software Version
export GEMC_VERSION=4.3.1
## Availible Run Periods
#clas12-default
#rga-spring2018 
#rga-fall2018 
#rga-spring2019
#rgb-spring2019
#rgk-fall2018
export RUN_PERIOD=rga-spring2019
# Change type to append to simulation name
# Doesn't change configuration but nice to change
# Depending on the testing you want to compelte
export TYPE="elastic_rga_Q2_20"
##***********************************************##

# Use this for simulations runs but idk why??
export RUN=11
# Make a unique name with type date etc.
export DATE=`date +%m-%d-%Y`
export NAME=${TYPE}_${NUM_EVENTS}_${BEAM_E}_${DATE}_${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}

res1=$(date +%s.%N)

# Generate events
ElasticGen "${DATA_DIR}/lund/${NAME}.lund" ${NUM_EVENTS} ${BEAM_E} ${Q2_MIN} ${Q2_MAX}

# Run Gemc
singularity shell -B $DATA_DIR:$DATA_DIR \
		  -B $PWD:/jlab/work/code \
		  /work/gothelab/clas12/software/gemc_${GEMC_VERSION}.img -c \
	    	  "bash /jlab/work/code/gemc.sh ${TOR} ${SOL} ${DATA_DIR}/lund/${NAME}.lund ${DATA_DIR}/gemc/gemc_${NAME}.evio ${RUN_PERIOD}"

# Convert evio 2 hipo		  
evio2hipo -r $RUN -t $TOR -s $SOL -o ${DATA_DIR}/gemc/gemc_${NAME}.hipo ${DATA_DIR}/gemc/gemc_${NAME}.evio
xz -9 -v ${DATA_DIR}/gemc/gemc_${NAME}.evio

# Cook hipo file
recon-util -y $PWD/yamls/${RUN_PERIOD}.yaml -i ${DATA_DIR}/gemc/gemc_${NAME}.hipo -o ${DATA_DIR}/hipo/sim_${NAME}.hipo 
#recon-util -c 2 -i ${DATA_DIR}/gemc/gemc_${NAME}.hipo -o ${DATA_DIR}/hipo/sim_${NAME}.hipo 
rm -rf ${DATA_DIR}/gemc/gemc_${NAME}.hipo

# Convert to root
dst2root -mc ${DATA_DIR}/hipo/sim_${NAME}.hipo ${DATA_DIR}/root/elastic/sim_${NAME}.root
rm -rf ${DATA_DIR}/hipo/sim_${NAME}.hipo

res2=$(date +%s.%N)
dt=$(echo "$res2 - $res1" | bc)
dd=$(echo "$dt/86400" | bc)
dt2=$(echo "$dt-86400*$dd" | bc)
dh=$(echo "$dt2/3600" | bc)
dt3=$(echo "$dt2-3600*$dh" | bc)
dm=$(echo "$dt3/60" | bc)
ds=$(echo "$dt3-60*$dm" | bc)
echo "Hostname: $HOSTNAME"
printf "Total runtime: %d:%02d:%02d:%02.4f\n" $dd $dh $dm $ds
