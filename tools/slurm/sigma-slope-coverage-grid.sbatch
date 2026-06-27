#!/bin/bash
#SBATCH --job-name=sigcov
#SBATCH --account=def-snakagaw_cpu
#SBATCH --array=1-7
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=3G
#SBATCH --time=0-01:00:00
#SBATCH --output=%x-%A_%a.out

# ---------------------------------------------------------------------------
# SR475 sigma-slope coverage grid -- SLURM array (fir / DRAC)
#
# Array task IDs 1..7 map to (provider, target) shards:
#   1  phylo   sigma:(Intercept)
#   2  phylo   sigma:x
#   3  spatial sigma:(Intercept)
#   4  spatial sigma:x
#   5  animal  sigma:(Intercept)
#   6  relmat  sigma:(Intercept)
#   7  relmat  sigma:x
# animal sigma:x is an EXCLUDED holdout; it is NOT in the array.
#
# BEFORE SUBMITTING -- set/export these two env vars in your login session:
#
#   export DRMTMB_RLIB=/project/def-snakagaw/snakagaw/R/x86_64-pc-linux-gnu-library/4.4
#   export DRMTMB_REPO=/project/def-snakagaw/snakagaw/drmTMB
#
# Then submit:
#   sbatch tools/slurm/sigma-slope-coverage-grid.sbatch
#
# --time sizing rationale (corrected against measured smoke artifacts):
#   Local smoke (n_rep=6) measured ~0.10-0.21 s per replicate
#   (fit + Wald + endpoint-profile), i.e. ~0.1-1.0 s/fit allowing for
#   occasional slow profile seeds. 475 reps x ~1 s ~ 8 min/shard; even 5x
#   slower stays well under 1 h. --time=1h is a large safety margin.
#   The runner is resumable (skips seeds already written), so a requeued
#   task continues from the last completed seed if it ever runs long.
#
# --mem-per-cpu sizing rationale:
#   Each fit (160 obs, 8 groups, Wald+profile) uses ~200-400 MB RSS locally.
#   3 GB/task provides ~8x safety margin; reduce to 2G if tasks stay <500 MB.
# ---------------------------------------------------------------------------

set -euo pipefail

# --- Environment -----------------------------------------------------------
module load StdEnv/2023 gcc/12.3 r/4.4.0

# R library where drmTMB (and its dependencies) are installed on the cluster.
# User MUST set DRMTMB_RLIB before submitting. See header above.
export R_LIBS="${DRMTMB_RLIB:?DRMTMB_RLIB not set -- export it before sbatch}"

# Repo root (clone or copy of drmTMB on /project).
# User MUST set DRMTMB_REPO before submitting.
REPO="${DRMTMB_REPO:?DRMTMB_REPO not set -- export it before sbatch}"

# TMB single-thread pinning (avoids OpenMP over-subscription)
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1

# --- Output dir ------------------------------------------------------------
OUT_DIR="$SCRATCH/sigcov/$SLURM_ARRAY_JOB_ID"
mkdir -p "$OUT_DIR"

echo "[sbatch] date=$(date -Iseconds)"
echo "[sbatch] job=$SLURM_JOB_ID  array_task=$SLURM_ARRAY_TASK_ID"
echo "[sbatch] node=$SLURMD_NODENAME"
echo "[sbatch] out_dir=$OUT_DIR"
echo "[sbatch] R_LIBS=$R_LIBS"

# --- Run -------------------------------------------------------------------
Rscript --no-init-file \
  "$REPO/tools/run-structured-re-sigma-slope-coverage-grid.R" \
  --shard="$SLURM_ARRAY_TASK_ID" \
  --n_rep=475 \
  --seed_start=740001 \
  --out_dir="$OUT_DIR" \
  --bootstrap=0

EXIT_CODE=$?
echo "[sbatch] R exit code: $EXIT_CODE"

# --- Copy results to project -----------------------------------------------
RESULTS_DIR="/project/def-snakagaw/snakagaw/sigcov-results"
mkdir -p "$RESULTS_DIR"
cp -v "$OUT_DIR"/*.tsv "$RESULTS_DIR/" || true

echo "[sbatch] done $(date -Iseconds)"
exit $EXIT_CODE
