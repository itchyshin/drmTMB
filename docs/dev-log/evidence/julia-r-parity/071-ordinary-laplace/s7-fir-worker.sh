#!/usr/bin/env bash
# This is a worker wrapper, not a submission command.  The compute-node
# preflight must verify its runtime and measured resource envelope before use.
#SBATCH --job-name=drmtmb071
#SBATCH --cpus-per-task=1
#SBATCH --time=02:00:00
#SBATCH --mem=8G

set -euo pipefail

: "${SLURM_JOB_ID:?S7 worker refuses to run outside a Slurm allocation}"
: "${SLURM_ARRAY_TASK_ID:?S7 worker requires a logical array task id}"
: "${S7_CAMPAIGN_ROOT:?S7 worker requires the approved campaign keeper root}"
: "${S7_BUNDLE:?S7 worker requires an immutable campaign bundle path}"
: "${S7_SOURCE_ROOT:?S7 worker requires the pinned drmTMB source root}"

task_id="${SLURM_ARRAY_TASK_ID}"
if ! [[ "${task_id}" =~ ^[0-9]+$ ]] || (( task_id < 1 || task_id > 2000 )); then
  printf '%s\n' "S7 worker task id must be in frozen bounds 1..2000" >&2
  exit 64
fi

export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export FLEXIBLAS_NUM_THREADS=1
export BLIS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1
export JULIA_NUM_THREADS=1

scratch_base="${SLURM_TMPDIR:-${TMPDIR:-/tmp}}"
task_scratch="${scratch_base}/s7-${SLURM_JOB_ID}-${task_id}"
mkdir -p "${task_scratch}"
cleanup() {
  rm -rf "${task_scratch}"
}
trap cleanup EXIT INT TERM

task_out="${task_scratch}/receipt"
mkdir -p "${task_out}"
Rscript "${S7_SOURCE_ROOT}/docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-run-task.R" \
  "--root=${S7_SOURCE_ROOT}" \
  "--bundle=${S7_BUNDLE}" \
  "--task=${task_id}" \
  "--out=${task_out}" \
  "--dry-run=false" \
  "--approved=true"

printf '%s\n' "S7 task ${task_id} completed its guarded R worker" >&2
