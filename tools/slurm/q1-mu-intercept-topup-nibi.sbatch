#!/bin/bash
#SBATCH --job-name=q1MuTop
#SBATCH --account=def-snakagaw_cpu
#SBATCH --array=1-4
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=6G
#SBATCH --time=0-08:00:00
#SBATCH --output=logs/%x-%A_%a.out

# Retained-denominator SR475 top-up shards for the Gaussian q1 mu-intercept
# direct-SD support cells. This is top-up evidence only, not status-signoff
# evidence, and writes artifacts only; any dashboard import must be reviewed
# separately.
#
# Array task IDs:
#   1 phylo
#   2 spatial
#   3 animal
#   4 relmat
#
# Submit from the campaign root after setting:
#
#   export DRMTMB_REPO=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>/source
#   export DRMTMB_RUN_ROOT=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>
#   export DRMTMB_RLIB=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>/rlib
#   export DRMTMB_GIT_SHA=<sha>
#
# Optional:
#
#   export DRMTMB_TOPUP_N_REP=325
#   export DRMTMB_TOPUP_SEED_START=151
#
# The default top-up extends the reviewed SR150 run to SR475 by running seeds
# 151..475 for each provider. MCSE <= 0.01 is a top-up target, not a shard-level
# pass claim. These shards promote no Q-Series row.
#
# The submit directory must already contain logs/ because #SBATCH --output is
# resolved before this script starts.

set -euo pipefail

module load StdEnv/2023 gcc/12.3 r/4.4.0

export R_PROFILE_USER=/dev/null
export NOT_CRAN=true
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1

case "${SLURM_ARRAY_TASK_ID:?SLURM_ARRAY_TASK_ID not set}" in
  1) PROVIDER="phylo" ;;
  2) PROVIDER="spatial" ;;
  3) PROVIDER="animal" ;;
  4) PROVIDER="relmat" ;;
  *) echo "Unsupported array task ${SLURM_ARRAY_TASK_ID}" >&2; exit 2 ;;
esac

REPO="${DRMTMB_REPO:?DRMTMB_REPO not set}"
RUN_ROOT="${DRMTMB_RUN_ROOT:?DRMTMB_RUN_ROOT not set}"
GIT_SHA="${DRMTMB_GIT_SHA:-unknown}"
TOPUP_N_REP="${DRMTMB_TOPUP_N_REP:-325}"
TOPUP_SEED_START="${DRMTMB_TOPUP_SEED_START:-151}"
BASE_RLIB="${DRMTMB_BASE_RLIB:-/project/def-snakagaw/snakagaw/R/x86_64-pc-linux-gnu-library/4.4}"
RLIB_ROOT="${DRMTMB_RLIB:-$RUN_ROOT/rlib}"
RLIB="$RLIB_ROOT/shard_${SLURM_ARRAY_TASK_ID}"
export R_LIBS="$RLIB:$BASE_RLIB"
export DRMTMB_RLIB="$RLIB"
export DRMTMB_RUN_ROOT="$RUN_ROOT"
export DRMTMB_META_DIR="$RUN_ROOT/metadata/shard_${SLURM_ARRAY_TASK_ID}_${PROVIDER}"
export DRMTMB_LOG_DIR="$RUN_ROOT/logs/shard_${SLURM_ARRAY_TASK_ID}_${PROVIDER}"
export DRMTMB_RUN_INSTALLED=true

RESULTS_DIR="$RUN_ROOT/results/q1-mu-intercept-topup-sr475/shard_${SLURM_ARRAY_TASK_ID}_${PROVIDER}"
LOG_DIR="$DRMTMB_LOG_DIR"
META_DIR="$DRMTMB_META_DIR"
mkdir -p "$RESULTS_DIR" "$LOG_DIR" "$META_DIR" "$RLIB"

TASK_WORK_ROOT="${SLURM_TMPDIR:-$RUN_ROOT/work/${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}}"
TASK_REPO="$TASK_WORK_ROOT/drmTMB-source"
mkdir -p "$TASK_WORK_ROOT"

HOST_NAME="${SLURMD_NODENAME:-$(hostname)}"
CLUSTER_NAME="${SLURM_CLUSTER_NAME:-unknown}"
RUN_COMMAND="R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 R_LIBS=$R_LIBS DRMTMB_RUN_INSTALLED=true DRMTMB_RUN_ROOT=$RUN_ROOT DRMTMB_META_DIR=$META_DIR DRMTMB_LOG_DIR=$LOG_DIR Rscript --no-init-file tools/run-structured-re-gaussian-lowq-mu-intercept-topup.R --providers=$PROVIDER --n-rep=$TOPUP_N_REP --seed-start=$TOPUP_SEED_START --host-class=nibi_retained_denominator_topup --host-name=$HOST_NAME --output-dir=$RESULTS_DIR --overwrite=true --write-dashboard=false"

{
  echo "date=$(date -Iseconds)"
  echo "job=${SLURM_JOB_ID:-manual}"
  echo "array_job=${SLURM_ARRAY_JOB_ID:-manual}"
  echo "array_task=${SLURM_ARRAY_TASK_ID}"
  echo "provider=$PROVIDER"
  echo "node=$HOST_NAME"
  echo "slurm_cluster_name=$CLUSTER_NAME"
  echo "run_root=$RUN_ROOT"
  echo "repo=$REPO"
  echo "task_repo=$TASK_REPO"
  echo "git_sha=$GIT_SHA"
  echo "R_LIBS=$R_LIBS"
  echo "contract=structured-re-gaussian-lowq-mu-intercept-retained-denominator-contract.tsv"
  echo "n_rep=$TOPUP_N_REP"
  echo "seed_start=$TOPUP_SEED_START"
  echo "promotion_decision=do_not_promote"
  echo "claim_boundary=topup_shard_only_not_status_promotion"
  echo "mcse_rule=MCSE <= 0.01 is a top-up target, not a shard-level pass claim"
} > "$META_DIR/q1-mu-intercept-topup-run-log.txt"

printf "%s\n" "$GIT_SHA" > "$META_DIR/git-sha.txt"
printf "%s\n" "$HOST_NAME" > "$META_DIR/host.txt"
printf "%s\n" "$CLUSTER_NAME" > "$META_DIR/slurm-cluster-name.txt"
env | sort > "$META_DIR/slurm-env.txt"
printf "%s\n" "$RUN_COMMAND" > "$META_DIR/exact-command.txt"
printf "%s\n" "slurm_source_snapshot" > "$META_DIR/source-provenance.txt"
module list > "$META_DIR/module-list.txt" 2>&1 || true

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
\) -print -delete > "$META_DIR/source-clean.txt" 2>&1 || true
rm -rf "$RLIB"/00LOCK-* "$RLIB/drmTMB"

(
  cd "$TASK_REPO"
  find . -type f \
    -not -path './.git/*' \
    -not -path './docs/dev-log/simulation-artifacts/*' \
    -print0 |
    sort -z |
    xargs -0 sha256sum
) > "$META_DIR/source-sha256-manifest.txt"

Rscript --no-init-file - <<'RSCRIPT' \
  > "$LOG_DIR/install-rlang.stdout" 2> "$LOG_DIR/install-rlang.stderr"
lib <- Sys.getenv("DRMTMB_RLIB")
if (!nzchar(lib)) {
  lib <- strsplit(Sys.getenv("R_LIBS"), .Platform$path.sep, fixed = TRUE)[[1]][[1]]
}
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, .libPaths()))
if (!requireNamespace("rlang", quietly = TRUE)) {
  install.packages("rlang", lib = lib, repos = "https://cloud.r-project.org")
}
RSCRIPT

R CMD INSTALL -l "$RLIB" "$TASK_REPO" \
  > "$LOG_DIR/r-cmd-install.stdout" \
  2> "$LOG_DIR/r-cmd-install.stderr"

Rscript --no-init-file -e 'writeLines(capture.output(sessionInfo()))' \
  > "$META_DIR/sessionInfo.txt"

set +e
(
  cd "$TASK_REPO"
  R_PROFILE_USER=/dev/null \
  NOT_CRAN=true \
  OMP_NUM_THREADS=1 \
  OPENBLAS_NUM_THREADS=1 \
  MKL_NUM_THREADS=1 \
  TMB_NTHREADS=1 \
  R_LIBS="$R_LIBS" \
  DRMTMB_RUN_INSTALLED=true \
  DRMTMB_RUN_ROOT="$RUN_ROOT" \
  DRMTMB_META_DIR="$META_DIR" \
  DRMTMB_LOG_DIR="$LOG_DIR" \
  DRMTMB_GIT_SHA="$GIT_SHA" \
  Rscript --no-init-file \
    tools/run-structured-re-gaussian-lowq-mu-intercept-topup.R \
    --providers="$PROVIDER" \
    --n-rep="$TOPUP_N_REP" \
    --seed-start="$TOPUP_SEED_START" \
    --host-class=nibi_retained_denominator_topup \
    --host-name="$HOST_NAME" \
    --output-dir="$RESULTS_DIR" \
    --overwrite=true \
    --write-dashboard=false
) > "$LOG_DIR/q1-mu-intercept-topup.stdout" \
  2> "$LOG_DIR/q1-mu-intercept-topup.stderr"
RUN_EXIT_CODE=$?
set -eo pipefail

echo "runner_exit_code=$RUN_EXIT_CODE" >> "$META_DIR/q1-mu-intercept-topup-run-log.txt"
echo "done=$(date -Iseconds)" >> "$META_DIR/q1-mu-intercept-topup-run-log.txt"

if [ "$RUN_EXIT_CODE" -eq 0 ]; then
  printf "%s\n" "nibi q1 mu-intercept retained-denominator top-up shard completed for $PROVIDER" \
    > "$META_DIR/run-status.txt"
else
  printf "%s\n" "nibi q1 mu-intercept retained-denominator top-up shard failed for $PROVIDER: $RUN_EXIT_CODE" \
    > "$META_DIR/run-status.txt"
fi

if command -v seff >/dev/null 2>&1 && [ -n "${SLURM_JOB_ID:-}" ]; then
  seff "$SLURM_JOB_ID" > "$META_DIR/seff.txt" 2>&1 || true
fi

exit "$RUN_EXIT_CODE"
