#!/bin/bash
# Resume only a timed-out G5 Gaussian-cohort cell from an already-retained
# checkpoint.  This wrapper deliberately shares the original runner, manifest,
# G4 records, deterministic registry, and array indices; it changes only the
# wall-time allowance and writes partial checkpoints to durable campaign space.
# Submit, after staging the original scratch receipts, with:
#   sbatch --array=6,12,18 tools/mr-g5-drac-timeout-resume.sbatch
#SBATCH --account=def-snakagaw
#SBATCH --job-name=mr-g5-gaussian-resume
#SBATCH --time=0-08:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=6G
#SBATCH --output=mr-g5-gaussian-resume-%A_%a.out

set -euo pipefail
module load StdEnv/2023 r-bundle-bioconductor/3.21
export R_LIBS_USER="$HOME/R/g4g5-lib"
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
campaign_root="$HOME/g4g5"
resume_root="$campaign_root/artifacts/g5-gaussian-timeout-resume/$SLURM_ARRAY_TASK_ID"
mkdir -p "$resume_root" "$campaign_root/artifacts/g5-gaussian"
export MR_G5_OUT_DIR="$resume_root"
export MR_G5_RUNNER_PATH="$campaign_root/drmTMB/inst/sim/R/sim_missing_response_g4g5.R"
Rscript --vanilla "$campaign_root/drmTMB/tools/mr-g5-drac-array.R" \
  "$campaign_root/artifacts/target-manifests.rds" \
  "$campaign_root/artifacts/g4-reconciled-records.rds" \
  "$SLURM_ARRAY_TASK_ID"
cp "$resume_root"/*.rds "$campaign_root/artifacts/g5-gaussian/"
