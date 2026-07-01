#!/bin/bash
#SBATCH --job-name=q2btTopup
#SBATCH --account=def-snakagaw_cpu
#SBATCH --array=1-4
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --time=0-02:00:00
#SBATCH --output=logs/%x-%A_%a.out

# q2 spatial/animal bias+t top-up runner.
#
# Array task IDs:
#   1 spatial mu1:x
#   2 spatial mu2:x
#   3 animal  mu1:x
#   4 animal  mu2:x
#
# Submit from the campaign root after setting:
#
#   export DRMTMB_REPO=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>/source
#   export DRMTMB_RUN_ROOT=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>
#   export DRMTMB_RLIB=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>/rlib
#   export DRMTMB_GIT_SHA=<sha>

set -euo pipefail

module load StdEnv/2023 gcc/12.3 r-bundle-bioconductor/3.21

export R_PROFILE_USER=/dev/null
export NOT_CRAN=true
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1

REPO="${DRMTMB_REPO:?DRMTMB_REPO not set -- export it before sbatch}"
RUN_ROOT="${DRMTMB_RUN_ROOT:?DRMTMB_RUN_ROOT not set -- export it before sbatch}"
GIT_SHA="${DRMTMB_GIT_SHA:-unknown}"
RLIB="${DRMTMB_RLIB:-$RUN_ROOT/rlib}"
export R_LIBS="$RLIB"

RESULTS_DIR="${RUN_ROOT}/results/shard_${SLURM_ARRAY_TASK_ID}"
LOG_DIR="${RUN_ROOT}/logs"
META_DIR="${RUN_ROOT}/metadata"
mkdir -p "$RESULTS_DIR" "$LOG_DIR" "$META_DIR" "$RLIB"

TASK_WORK_ROOT="${SLURM_TMPDIR:-$RUN_ROOT/work/${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}}"
TASK_REPO="${TASK_WORK_ROOT}/drmTMB-source"
mkdir -p "$TASK_WORK_ROOT"

{
  echo "[sbatch] date=$(date -Iseconds)"
  echo "[sbatch] job=${SLURM_JOB_ID} array_task=${SLURM_ARRAY_TASK_ID}"
  echo "[sbatch] node=${SLURMD_NODENAME}"
  echo "[sbatch] repo=${REPO}"
  echo "[sbatch] task_repo=${TASK_REPO}"
  echo "[sbatch] run_root=${RUN_ROOT}"
  echo "[sbatch] git_sha=${GIT_SHA}"
  echo "[sbatch] results_dir=${RESULTS_DIR}"
  echo "[sbatch] R_LIBS=${R_LIBS}"
} | tee "${LOG_DIR}/q2bt-${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.run-log.txt"

printf "%s\n" "$GIT_SHA" > "${META_DIR}/git-sha-${SLURM_ARRAY_TASK_ID}.txt"
module list > "${META_DIR}/module-list-${SLURM_ARRAY_TASK_ID}.txt" 2>&1 || true

rsync -a --delete \
  --exclude='.git/' \
  --exclude='docs/dev-log/simulation-artifacts/' \
  --exclude='pkgdown-site/' \
  "$REPO/" "$TASK_REPO/"

find "$TASK_REPO/src" -type f \( \
  -name '*.o' -o \
  -name '*.so' -o \
  -name '*.dll' -o \
  -name '*.dylib' \
\) -print -delete > "${META_DIR}/source-clean-${SLURM_ARRAY_TASK_ID}.txt" 2>&1 || true
rm -rf "$RLIB"/00LOCK-*

set +e
Rscript --no-init-file \
  "$TASK_REPO/tools/run-structured-re-q2-bias-t-coverage-topup.R" \
  --shard="${SLURM_ARRAY_TASK_ID}" \
  --n_rep=525 \
  --seed_start=730476 \
  --out_dir="$RESULTS_DIR" \
  --attempt-temp-install \
  --no-load-all
EXIT_CODE=$?
set -eo pipefail

echo "[sbatch] R exit code: ${EXIT_CODE}" | tee -a "${LOG_DIR}/q2bt-${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.run-log.txt"
echo "[sbatch] done $(date -Iseconds)" | tee -a "${LOG_DIR}/q2bt-${SLURM_ARRAY_JOB_ID}_${SLURM_ARRAY_TASK_ID}.run-log.txt"

exit "$EXIT_CODE"
