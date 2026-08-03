#!/bin/bash
#SBATCH --job-name=drmtmb-ce-q2
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=02:00:00
#SBATCH --output=%x-%A_%a.out
#SBATCH --error=%x-%A_%a.err

set -euo pipefail
: "${CE_STAGE:?set CE_STAGE to smoke or full}"
: "${CE_PACKET:?set CE_PACKET to the frozen packet directory}"
: "${CE_OUTPUT:?set CE_OUTPUT to the raw output directory}"
: "${DRMTMB_REPO:?set DRMTMB_REPO to the extracted source directory}"
: "${DRMTMB_LIB:?set DRMTMB_LIB to the isolated R library}"
: "${SLURM_ARRAY_TASK_ID:?submit as a SLURM array}"

export R_PROFILE_USER=/dev/null
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

Rscript --vanilla "${DRMTMB_REPO}/tools/run-spatial-q2-confidence-eye-task.R" \
  --stage "${CE_STAGE}" \
  --task "${SLURM_ARRAY_TASK_ID}" \
  --packet "${CE_PACKET}" \
  --output "${CE_OUTPUT}" \
  --lib "${DRMTMB_LIB}"
