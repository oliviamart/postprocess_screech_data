#!/bin/sh -l

#SBATCH -J spod           # Job name
#SBATCH -o output/spod.o%j       # Name of stdout output file
#SBATCH -e output/spod.e%j       # Name of stderr error file
#SBATCH -p highmem   # Queue (partition) name
#SBATCH --nodes=1             # Total # of nodes 
#SBATCH --ntasks-per-node=1
#SBATCH -t 4:00:00        # Run time (hh:mm:ss)
#SBATCH --mail-user=ogmartin@stanford.edu
#SBATCH --mail-type=all    # Send email at begin and end of job
#SBATCH --mem=800G

pwd
date

module load matlab/R2023a
module list

cat run_spod.m

matlab -nodisplay < run_spod.m  
