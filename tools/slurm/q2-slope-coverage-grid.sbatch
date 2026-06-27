#!/bin/bash
#SBATCH --job-name=q2slopcov
#SBATCH --account=def-snakagaw_cpu
#SBATCH --array=1-10
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --time=0-02:00:00
#SBATCH --output=%x-%A_%a.out

# ---------------------------------------------------------------------------
# SR475 q2-slope coverage grid -- SLURM array (fir / DRAC)
#
# Array task IDs 1..10 map to (provider, target) shards:
#   1  phylo   mu1:x            sd:mu:mu1:phylo(0 + x | p | species)
#   2  phylo   mu2:x            sd:mu:mu2:phylo(0 + x | p | species)
#   3  phylo   mu1:x+mu2:x      cor:phylo:cor(mu1:x,mu2:x | p | species)
#   4  spatial mu1:x            sd:mu:mu1:spatial(0 + x | p | site)
#   5  spatial mu2:x            sd:mu:mu2:spatial(0 + x | p | site)
#   6  spatial mu1:x+mu2:x      cor:spatial:cor(mu1:x,mu2:x | p | site)
#   7  animal  mu1:x            sd:mu:mu1:animal(0 + x | p | id)
#   8  animal  mu2:x            sd:mu:mu2:animal(0 + x | p | id)
#   9  relmat  mu1:x            sd:mu:mu1:relmat(0 + x | p | id)
#  10  relmat  mu2:x            sd:mu:mu2:relmat(0 + x | p | id)
#
# EXCLUDED HOLDOUTS (not in array; endpoint-profile failures in smoke):
#   animal  mu1:x+mu2:x   cor:animal:cor(mu1:x,mu2:x | p | id)
#   relmat  mu1:x+mu2:x   cor:relmat:cor(mu1:x,mu2:x | p | id)
# See structured-re-q2-slope-denominator-admission.tsv for admission status.
#
# BEFORE SUBMITTING -- set/export these two env vars in your login session:
#
#   export DRMTMB_RLIB=/project/def-snakagaw/snakagaw/R/x86_64-pc-linux-gnu-library/4.4
#   export DRMTMB_REPO=/project/def-snakagaw/snakagaw/drmTMB
#
# Then submit:
#   sbatch tools/slurm/q2-slope-coverage-grid.sbatch
#
# --time sizing rationale:
#   Bivariate biv_gaussian fits (160 obs, 8 groups, Wald+endpoint-profile)
#   are more expensive than univariate sigma-slope fits. Smoke timing
#   (see pilot artifacts) is recorded at ~s/rep for each shard; plan for
#   3-5x the univariate time. 475 reps x ~5 s/rep ~ 40 min/shard; with a
#   5x safety margin that is ~3.5 h, so --time=2h is aggressive but the
#   runner is resumable (skips seeds already written) so a requeued task
#   continues from the last completed seed if the array task times out.
#   Increase to --time=0-04:00:00 if measured s/rep on the first shard
#   exceeds ~10 s.
#
# --mem-per-cpu sizing rationale:
#   Bivariate biv_gaussian model with 8 groups + endpoint-profile typically
#   uses ~300-600 MB RSS locally. 4 GB/task provides ~7x safety margin;
#   reduce to 3G if tasks consistently stay under 600 MB (check via seff).
#
# Seed manifest: 730001..730475 (same block as pregrid dry-run manifests).
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
OUT_DIR="$SCRATCH/q2slopcov/$SLURM_ARRAY_JOB_ID"
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
  "$REPO/tools/run-structured-re-q2-slope-coverage-grid.R" \
  --shard="$SLURM_ARRAY_TASK_ID" \
  --n_rep=475 \
  --seed_start=730001 \
  --out_dir="$OUT_DIR" \
  --bootstrap=0
EXIT_CODE=$?
set -eo pipefail
echo "[sbatch] R exit code: $EXIT_CODE"

# --- Copy results to project -----------------------------------------------
RESULTS_DIR="/project/def-snakagaw/snakagaw/q2slopcov-results"
mkdir -p "$RESULTS_DIR"
cp -v "$OUT_DIR"/*.tsv "$RESULTS_DIR/" || true

echo "[sbatch] done $(date -Iseconds)"
exit $EXIT_CODE
