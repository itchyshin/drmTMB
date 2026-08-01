#!/bin/bash
# Submit with: sbatch --export=ALL,MR_G5_ROUTE_ID=<route> tools/mr-g5-drac-route-smoke.sbatch
# This runs three frozen seeds for the first target-rung cell only.  It is an
# infrastructure/receipt gate, not a coverage-calibration result.
#SBATCH --account=def-snakagaw
#SBATCH --job-name=mr-g5-route-smoke
#SBATCH --time=0-01:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=6G
#SBATCH --output=mr-g5-route-smoke-%j.out

set -euo pipefail
: "${MR_G5_ROUTE_ID:?Set MR_G5_ROUTE_ID to one frozen G5 route}"

module load StdEnv/2023 r-bundle-bioconductor/3.21
export R_LIBS_USER="$HOME/R/g4g5-lib"
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1

campaign_root="$HOME/g4g5"
scratch_root="$SCRATCH/mr-g5-route-smoke-${MR_G5_ROUTE_ID}-${SLURM_JOB_ID}"
receipt_dir="$campaign_root/artifacts/g5-smoke-${MR_G5_ROUTE_ID}"
mkdir -p "$scratch_root" "$receipt_dir"
export MR_G5_OUT_DIR="$scratch_root"
export MR_G5_RUNNER_PATH="$campaign_root/drmTMB/inst/sim/R/sim_missing_response_g4g5.R"

Rscript --vanilla "$campaign_root/drmTMB/tools/mr-g5-drac-route-array.R" \
  "$campaign_root/artifacts/target-manifests.rds" \
  "$campaign_root/artifacts/g4-reconciled-records.rds" \
  "$MR_G5_ROUTE_ID" 1 3
cp "$scratch_root"/*.rds "$receipt_dir/"
