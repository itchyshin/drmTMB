#!/bin/bash
#SBATCH --job-name=stgEtaBoot
#SBATCH --account=def-snakagaw_cpu
#SBATCH --array=1-4800%96
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=0-02:00:00
#SBATCH --output=logs/%x-%A_%a.out

# Immutable 24-cell staged eta campaign: each array task owns exactly one of
# 200 all-attempt outer datasets.  It must run from a prepared /project
# snapshot, never a login node or GitHub Actions.  A later aggregation step
# combines the one-outer ledgers without dropping failures.
set -euo pipefail
[[ -n "${SLURM_JOB_ID:-}" ]] || { echo "Refusing login-node execution." >&2; exit 2; }

module load StdEnv/2023 gcc/12.3 r/4.4.0
export R_PROFILE_USER=/dev/null NOT_CRAN=true
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 FLEXIBLAS_NUM_THREADS=1 BLIS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1

RUN_ROOT="${STAGED_ETA_RUN_ROOT:?STAGED_ETA_RUN_ROOT must name the prepared /project campaign directory}"
REPO="${STAGED_ETA_REPO:?STAGED_ETA_REPO must name the exact campaign source snapshot}"
RLIB="${STAGED_ETA_RLIB:?STAGED_ETA_RLIB must name the prepared isolated R library}"
export R_LIBS="$RLIB"

TASK_ID="${SLURM_ARRAY_TASK_ID:?SLURM_ARRAY_TASK_ID is required}"
CELL_INDEX=$(( (TASK_ID - 1) / 200 + 1 ))
OUTER_INDEX=$(( (TASK_ID - 1) % 200 + 1 ))
CELL_ID=$(printf 'staged_eta_%02d' "$CELL_INDEX")
[[ "$CELL_INDEX" -ge 1 && "$CELL_INDEX" -le 24 ]] || { echo "Invalid array task $TASK_ID" >&2; exit 2; }

TASK_DIR="$RUN_ROOT/results/$CELL_ID/outer_$(printf '%03d' "$OUTER_INDEX")"
mkdir -p "$RUN_ROOT/logs" "$RUN_ROOT/metadata" "$TASK_DIR"

{
  printf 'task_id=%s\ncell_id=%s\nouter_index=%s\n' "$TASK_ID" "$CELL_ID" "$OUTER_INDEX"
  printf 'job_id=%s\nhost=%s\nrepo=%s\nR_LIBS=%s\n' "$SLURM_JOB_ID" "${SLURMD_NODENAME:-$(hostname)}" "$REPO" "$R_LIBS"
  git -C "$REPO" rev-parse HEAD 2>/dev/null || true
} > "$TASK_DIR/provenance.txt"

cd "$REPO"
RUN_STAGED_ETA_BOOTSTRAP=true \
  STAGED_ETA_CELL_ID="$CELL_ID" \
  STAGED_ETA_OUTER_INDEX="$OUTER_INDEX" \
  OUTDIR="$TASK_DIR" \
  Rscript --no-init-file inst/sim/run/sim_run_staged_eta_bernoulli_nbinom2_bootstrap.R \
  > "$TASK_DIR/runner.stdout" 2> "$TASK_DIR/runner.stderr"
