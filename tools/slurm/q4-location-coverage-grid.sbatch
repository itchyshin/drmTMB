#!/bin/bash
#SBATCH --job-name=q4loccov
#SBATCH --account=def-snakagaw_cpu
#SBATCH --array=1-16
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --time=0-02:00:00
#SBATCH --output=%x-%A_%a.out

# ---------------------------------------------------------------------------
# Q4-location coverage grid -- SLURM array (fir / DRAC)
#
# Array task IDs 1..16 map to (provider, target) shards:
#    1  phylo   mu1:(Intercept)
#    2  phylo   mu1:x
#    3  phylo   mu2:(Intercept)
#    4  phylo   mu2:x
#    5  spatial mu1:(Intercept)
#    6  spatial mu1:x
#    7  spatial mu2:(Intercept)
#    8  spatial mu2:x
#    9  animal  mu1:(Intercept)
#   10  animal  mu1:x
#   11  animal  mu2:(Intercept)
#   12  animal  mu2:x
#   13  relmat  mu1:(Intercept)
#   14  relmat  mu1:x
#   15  relmat  mu2:(Intercept)
#   16  relmat  mu2:x
#
# 16 direct-SD shards.  Derived-correlation targets are NOT included (blocked
# on reconstruction design; 24 targets deferred).
#
# BEFORE SUBMITTING -- set/export these two env vars in your login session:
#
#   export DRMTMB_RLIB=/project/def-snakagaw/snakagaw/R/x86_64-pc-linux-gnu-library/4.4
#   export DRMTMB_REPO=/project/def-snakagaw/snakagaw/drmTMB
#
# Then submit:
#   sbatch tools/slurm/q4-location-coverage-grid.sbatch
#
# --time sizing rationale:
#   The bivariate Gaussian biv_gaussian() model with 4 correlated location-axis
#   REs is heavier than the univariate sigma-slope model.  Local smoke
#   (n_rep=6) measured ~0.5-2 s per replicate (fit + Wald + endpoint-profile).
#   475 reps x ~2 s ~ 16 min/shard; 5x safety factor ~ 80 min.  --time=2h
#   provides >7x headroom.  The runner is resumable if a task is ever
#   requeued.
#
# --mem-per-cpu sizing rationale:
#   Each biv_gaussian fit with 8 groups and 160 obs uses ~400-800 MB RSS
#   locally.  4 GB/task provides ~5-10x safety margin; reduce to 3G if tasks
#   stay well under 1 GB.
# ---------------------------------------------------------------------------

set -euo pipefail

# --- Environment -----------------------------------------------------------
module load StdEnv/2023 gcc/12.3 r/4.4.0

# R library where drmTMB (and its dependencies) are installed on the cluster.
export R_LIBS="${DRMTMB_RLIB:?DRMTMB_RLIB not set -- export it before sbatch}"

# Repo root (clone or copy of drmTMB on /project).
REPO="${DRMTMB_REPO:?DRMTMB_REPO not set -- export it before sbatch}"

# TMB single-thread pinning (avoids OpenMP over-subscription)
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1

# --- Output dir ------------------------------------------------------------
OUT_DIR="$SCRATCH/q4loccov/$SLURM_ARRAY_JOB_ID"
mkdir -p "$OUT_DIR"

echo "[sbatch] date=$(date -Iseconds)"
echo "[sbatch] job=$SLURM_JOB_ID  array_task=$SLURM_ARRAY_TASK_ID"
echo "[sbatch] node=$SLURMD_NODENAME"
echo "[sbatch] out_dir=$OUT_DIR"
echo "[sbatch] R_LIBS=$R_LIBS"

# --- Run -------------------------------------------------------------------
# Wrap in `set +e` so a non-zero Rscript exit does NOT abort the script before
# the copy-back below -- per-rep results live on purged $SCRATCH until copied to
# /project. Restore with `set -eo pipefail` (faithful to the top-of-file guard;
# bare `set -e` would drop pipefail). `set -u` is unaffected by +e/-e and stays on.
set +e
Rscript --no-init-file \
  "$REPO/tools/run-structured-re-q4-location-coverage-grid.R" \
  --shard="$SLURM_ARRAY_TASK_ID" \
  --n_rep=475 \
  --seed_start=850001 \
  --out_dir="$OUT_DIR" \
  --bootstrap=0
EXIT_CODE=$?
set -eo pipefail
echo "[sbatch] R exit code: $EXIT_CODE"

# --- Copy results to project -----------------------------------------------
RESULTS_DIR="/project/def-snakagaw/snakagaw/q4loccov-results"
mkdir -p "$RESULTS_DIR"
cp -v "$OUT_DIR"/*.tsv "$RESULTS_DIR/" || true

echo "[sbatch] done $(date -Iseconds)"
exit $EXIT_CODE
