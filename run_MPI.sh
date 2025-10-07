#!/bin/bash
#SBATCH -J vol_data_screech           # Job name
#SBATCH -o output/get_vol_data.o%j       # Name of stdout output file
#SBATCH -e output/get_vol_data.e%j       # Name of stderr error file
#SBATCH -p wholenode    # Queue (partition) name
#SBATCH --nodes=2
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=120
#SBATCH -t 4:00:00        # Run time (hh:mm:ss)
#SBATCH --mail-user=ogmartin@stanford.edu
#SBATCH --mail-type=all    # Send email at begin and end of job
##SBATCH --account=behb-delta-cpu 
#SBATCH --mem=200G

pwd
date

source ~/venvs/pyspod-env/bin/activate
module load matlab/R2023a
module load python/3.9.5
module list

# INPUTS
START_GLOBAL=969800
END_GLOBAL=989800
DT=100
SNAPS_PER_BLOCK=100
OVERLAP_PERCENT=0.0            # unused if always 0
NUM_T=$(( (END_GLOBAL - START_GLOBAL)/DT + 1 ))
NUM_BLOCKS=$(( NUM_T / SNAPS_PER_BLOCK ))
NUM_CORES=${SLURM_CPUS_PER_TASK:-1}

WORKDIR="/anvil/scratch/x-omartin/jet_screech/.../postprocess_screech_data"

srun bash -c '
  RANK=$SLURM_PROCID
  START_GLOBAL='"$START_GLOBAL"'
  END_GLOBAL='"$END_GLOBAL"'
  DT='"$DT"'
  SNAPS_PER_BLOCK='"$SNAPS_PER_BLOCK"'
  NUM_CORES='"$NUM_CORES"'
  WD="'"$WORKDIR"'"

  START_TID=$(( START_GLOBAL + (SNAPS_PER_BLOCK*DT)*RANK ))
  END_TID=$(( START_TID + (SNAPS_PER_BLOCK-1)*DT ))

  echo "Rank $RANK: $START_TID → $END_TID"

  if (( END_TID <= END_GLOBAL )); then
    CMD="analyze_volume_data($START_TID,$END_TID,$RANK,$NUM_CORES);"
    matlab -batch "$CMD"
  else
    echo "Rank $RANK does nothing (out of range)."
  fi
'
