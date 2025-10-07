#!/bin/bash
#SBATCH -J vol_data_screech           # Job name
#SBATCH -o output/get_vol_data.o%j       # Name of stdout output file
#SBATCH -e output/get_vol_data.e%j       # Name of stderr error file
#SBATCH -p cpu    # Queue (partition) name
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=100
#SBATCH -t 4:00:00        # Run time (hh:mm:ss)
#SBATCH --mail-user=ogmartin@stanford.edu
#SBATCH --mail-type=all    # Send email at begin and end of job
#SBATCH --account=behb-delta-cpu 
#SBATCH --mem=200G

pwd
date

module load matlab/2024a 
module list

matlab -nodisplay -r "combine_data('volume_data_output/volume_data_', '.mat', {'T'}, 35, 'volDat.mat', 'volume_data_output/combined_data/'); exit;"
