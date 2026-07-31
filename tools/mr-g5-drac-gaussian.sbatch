#!/bin/bash
#SBATCH --account=def-snakagaw
#SBATCH --job-name=mr-g5-gaussian
#SBATCH --array=1-54%18
#SBATCH --time=0-04:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=6G
#SBATCH --output=mr-g5-gaussian-%A_%a.out

set -euo pipefail
module load StdEnv/2023 r-bundle-bioconductor/3.21
export R_LIBS_USER="$HOME/R/g4g5-lib"
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
campaign_root="$HOME/g4g5"
scratch_root="$SCRATCH/mr-g5-gaussian-${SLURM_ARRAY_JOB_ID}-${SLURM_ARRAY_TASK_ID}"
mkdir -p "$scratch_root"
export MR_G5_OUT_DIR="$scratch_root"
export MR_G5_RUNNER_PATH="$campaign_root/drmTMB/inst/sim/R/sim_missing_response_g4g5.R"
Rscript --vanilla "$campaign_root/drmTMB/tools/mr-g5-drac-array.R" \
  "$campaign_root/artifacts/target-manifests.rds" \
  "$campaign_root/artifacts/g4-reconciled-records.rds" \
  "$SLURM_ARRAY_TASK_ID"
mkdir -p "$campaign_root/artifacts/g5-gaussian"
cp "$scratch_root"/*.rds "$campaign_root/artifacts/g5-gaussian/"
