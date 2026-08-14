#!/bin/bash
# Before submitting, install the reviewed source ONCE (serially) with
# `R CMD INSTALL -l "$DRMTMB_RLIB" "$DRMTMB_REPO"`. Array tasks must never
# compile into a shared library concurrently. Export DRMTMB_REPO,
# DRMTMB_RUN_ROOT, DRMTMB_RLIB, and DRMTMB_GIT_SHA. Array index maps to 12
# cells x 5 shards.
#SBATCH --job-name=jointMiG
#SBATCH --account=def-snakagaw_cpu
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=6G
#SBATCH --time=0-06:00:00
#SBATCH --array=1-60%40
#SBATCH --output=logs/%x-%A_%a.out

set -euo pipefail
module load StdEnv/2023 gcc/12.3 r/4.4.0
export R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1
REPO="${DRMTMB_REPO:?DRMTMB_REPO not set}"
RUN_ROOT="${DRMTMB_RUN_ROOT:?DRMTMB_RUN_ROOT not set}"
RLIB="${DRMTMB_RLIB:?DRMTMB_RLIB not set}"
export R_LIBS="$RLIB:${DRMTMB_BASE_RLIB:-/project/def-snakagaw/snakagaw/R/x86_64-pc-linux-gnu-library/4.4}"
mkdir -p "$RUN_ROOT/results" "$RUN_ROOT/logs" "$RUN_ROOT/metadata"
cd "$REPO"
TASK=$SLURM_ARRAY_TASK_ID
CELL=$(( (TASK - 1) / 5 + 1 ))
SHARD=$(( (TASK - 1) % 5 ))
REP_START=$(( SHARD * 50 + 1 ))
REP_END=$(( REP_START + 49 ))
DRMTMB_RUN_INSTALLED=true Rscript --no-init-file "$REPO/tools/run-joint-mi-gaussian-recovery.R" \
  --cell="$CELL" --rep-start="$REP_START" --rep-end="$REP_END" \
  --out-dir="$RUN_ROOT/results"
