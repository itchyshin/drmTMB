#!/bin/bash
# Submit with: sbatch --array=1-N%18 --export=ALL,MR_G5_ROUTE_ID=<route> tools/mr-g5-drac-route.sbatch
# N is the exact number of G4-feasible target-rung cells for the selected route.
# The route-specific R runner validates both the route and array index against
# the frozen registry before any fit is attempted.
#SBATCH --account=def-snakagaw
#SBATCH --job-name=mr-g5-route
#SBATCH --time=0-08:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=6G
#SBATCH --output=mr-g5-route-%A_%a.out

set -euo pipefail
: "${MR_G5_ROUTE_ID:?Set MR_G5_ROUTE_ID to one frozen G5 route}"
module load StdEnv/2023 r-bundle-bioconductor/3.21
export R_LIBS_USER="$HOME/R/g4g5-lib"
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1
campaign_root="$HOME/g4g5"
scratch_root="$SCRATCH/mr-g5-${MR_G5_ROUTE_ID}-${SLURM_ARRAY_JOB_ID}-${SLURM_ARRAY_TASK_ID}"
mkdir -p "$scratch_root" "$campaign_root/artifacts/g5-${MR_G5_ROUTE_ID}"
export MR_G5_OUT_DIR="$scratch_root"
export MR_G5_RUNNER_PATH="$campaign_root/drmTMB/inst/sim/R/sim_missing_response_g4g5.R"
# Design declaration is REQUIRED (#982); override on submission to run the v2 design.
export MR_G5_CENTRE_RANDOM_EFFECTS="${MR_G5_CENTRE_RANDOM_EFFECTS:-TRUE}"
Rscript --vanilla "$campaign_root/drmTMB/tools/mr-g5-drac-route-array.R" \
  "$campaign_root/artifacts/target-manifests.rds" \
  "$campaign_root/artifacts/g4-reconciled-records.rds" \
  "$MR_G5_ROUTE_ID" "$SLURM_ARRAY_TASK_ID"
cp "$scratch_root"/*.rds "$campaign_root/artifacts/g5-${MR_G5_ROUTE_ID}/"
