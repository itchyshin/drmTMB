#!/bin/bash
#SBATCH --job-name=drmtmb-ce-q2-full
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=02:00:00

set -euo pipefail
: "${CE_PACKET:?set CE_PACKET to the frozen full packet directory}"
: "${CE_OUTPUT:?set CE_OUTPUT to the raw output directory}"
: "${CE_RUN_ROOT:?set CE_RUN_ROOT to the immutable run directory}"
: "${DRMTMB_LIB:?set DRMTMB_LIB to the isolated R library}"
: "${CE_BASE_R_LIB:?set CE_BASE_R_LIB to the read-only dependency library}"
: "${SLURM_ARRAY_TASK_ID:?submit as a SLURM array}"
if (( SLURM_ARRAY_TASK_ID < 1 || SLURM_ARRAY_TASK_ID > 1500 )); then
  echo "Full task ID must be in 1..1500" >&2
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
  --stage full \
  --task "${SLURM_ARRAY_TASK_ID}" \
  --packet "${CE_PACKET}" \
  --output "${CE_OUTPUT}" \
  --lib "${DRMTMB_LIB}"
