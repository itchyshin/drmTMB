#!/bin/bash
#SBATCH --job-name=sigtopup
#SBATCH --account=def-snakagaw_cpu
#SBATCH --array=1,6
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3G
#SBATCH --time=0-01:00:00
#SBATCH --output=logs/%x-%A_%a.out

# Top up the two borderline sigma one-slope intercept targets to 1000 reps:
#   1  phylo   sigma:(Intercept)
#   6  relmat  sigma:(Intercept)
#
# Submit from the campaign root after setting:
#   export DRMTMB_RLIB=/project/def-snakagaw/snakagaw/R/x86_64-pc-linux-gnu-library/4.4
#   export DRMTMB_REPO=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>/repo
#   export DRMTMB_RUN_ROOT=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>
#   export DRMTMB_GIT_SHA=<sha>

set -euo pipefail

module load StdEnv/2023 gcc/12.3 r/4.4.0

export R_PROFILE_USER=/dev/null
export NOT_CRAN=true
export R_LIBS="${DRMTMB_RLIB:?DRMTMB_RLIB not set}"
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1

REPO="${DRMTMB_REPO:?DRMTMB_REPO not set}"
RUN_ROOT="${DRMTMB_RUN_ROOT:?DRMTMB_RUN_ROOT not set}"
GIT_SHA="${DRMTMB_GIT_SHA:-unknown}"

RESULTS_DIR="$RUN_ROOT/results/shard_${SLURM_ARRAY_TASK_ID}"
mkdir -p "$RUN_ROOT"/{logs,results,metadata} "$RESULTS_DIR"

{
  echo "date=$(date -Iseconds)"
  echo "job=$SLURM_JOB_ID"
  echo "array_task=$SLURM_ARRAY_TASK_ID"
  echo "node=$SLURMD_NODENAME"
  echo "run_root=$RUN_ROOT"
  echo "repo=$REPO"
  echo "git_sha=$GIT_SHA"
  echo "R_LIBS=$R_LIBS"
} > "$RUN_ROOT/metadata/run-log-${SLURM_ARRAY_TASK_ID}.txt"

printf "%s\n" "$GIT_SHA" > "$RUN_ROOT/metadata/git-sha.txt"
module list > "$RUN_ROOT/metadata/module-list-${SLURM_ARRAY_TASK_ID}.txt" 2>&1
Rscript --no-init-file -e 'writeLines(capture.output(sessionInfo()))' \
  > "$RUN_ROOT/metadata/sessionInfo-${SLURM_ARRAY_TASK_ID}.txt"

set +e
Rscript --no-init-file \
  "$REPO/tools/run-structured-re-sigma-slope-coverage-grid.R" \
  --shard="$SLURM_ARRAY_TASK_ID" \
  --n_rep=1000 \
  --seed_start=740001 \
  --out_dir="$RESULTS_DIR" \
  --bootstrap=0
EXIT_CODE=$?
set -eo pipefail

echo "exit_code=$EXIT_CODE" >> "$RUN_ROOT/metadata/run-log-${SLURM_ARRAY_TASK_ID}.txt"
echo "done=$(date -Iseconds)" >> "$RUN_ROOT/metadata/run-log-${SLURM_ARRAY_TASK_ID}.txt"

exit "$EXIT_CODE"
