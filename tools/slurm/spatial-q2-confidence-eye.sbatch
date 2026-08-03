#!/bin/bash
#SBATCH --job-name=drmtmb-ce-q2
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=02:00:00
#SBATCH --output=%x-%A_%a.out
#SBATCH --error=%x-%A_%a.err

set -euo pipefail
: "${CE_PACKET:?set CE_PACKET to the frozen packet directory}"
: "${CE_OUTPUT:?set CE_OUTPUT to the raw output directory}"
: "${CE_RUN_ROOT:?set CE_RUN_ROOT to the immutable run directory}"
: "${DRMTMB_LIB:?set DRMTMB_LIB to the isolated R library}"
: "${CE_BASE_R_LIB:?set CE_BASE_R_LIB to the read-only dependency library}"
: "${SLURM_ARRAY_TASK_ID:?submit as a SLURM array}"
if (( SLURM_ARRAY_TASK_ID < 1 || SLURM_ARRAY_TASK_ID > 60 )); then
  echo "Smoke task ID must be in 1..60" >&2
  exit 64
fi
test -f "${CE_RUN_ROOT}/install.complete"
test -f "${CE_RUN_ROOT}/source/SOURCE_SHA"
expected_sha=$(awk -F '\t' '$1 == "source_sha" {print $2}' "${CE_PACKET}/metadata.tsv")
test "$(cat "${CE_RUN_ROOT}/source/SOURCE_SHA")" = "${expected_sha}"

module --force purge
module load StdEnv/2023 gcc/12.3 r/4.4.0
export R_PROFILE_USER=/dev/null
export R_LIBS="${DRMTMB_LIB}:${CE_BASE_R_LIB}"
export R_LIBS_USER="${DRMTMB_LIB}"
export OPENBLAS_NUM_THREADS=1
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1

Rscript --vanilla "${CE_RUN_ROOT}/source/tools/run-spatial-q2-confidence-eye-task.R" \
  --stage smoke \
  --task "${SLURM_ARRAY_TASK_ID}" \
  --packet "${CE_PACKET}" \
  --output "${CE_OUTPUT}" \
  --lib "${DRMTMB_LIB}"
