#!/bin/bash
#SBATCH --job-name=cntslope
#SBATCH --account=def-snakagaw_cpu
#SBATCH --array=1-8%2
#SBATCH --cpus-per-task=2
#SBATCH --mem-per-cpu=4G
#SBATCH --time=0-02:00:00
#SBATCH --output=logs/%x-%A_%a.out

# Primary-cluster recovery-only reproduction for the eight non-Gaussian
# count-slope q1 mu rows. Submit from the campaign root after setting:
#
#   export DRMTMB_REPO=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>/source
#   export DRMTMB_RUN_ROOT=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>
#   export DRMTMB_GIT_SHA=<sha>
#
# Optional top-up controls, defaulting to the original reproduction grid:
#
#   export DRMTMB_COUNT_SLOPE_N_REP=80
#   export DRMTMB_COUNT_SLOPE_SEED_START=760001
#
# This is point-recovery evidence only. It does not compute intervals,
# coverage, inference readiness, support, REML, or AI-REML evidence.

set -euo pipefail

module load StdEnv/2023 gcc/12.3 r-bundle-bioconductor/3.21

export R_PROFILE_USER=/dev/null
export NOT_CRAN=true
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1

REPO="${DRMTMB_REPO:?DRMTMB_REPO not set}"
RUN_ROOT="${DRMTMB_RUN_ROOT:?DRMTMB_RUN_ROOT not set}"
GIT_SHA="${DRMTMB_GIT_SHA:-unknown}"
TASK_ID="${SLURM_ARRAY_TASK_ID:-1}"
N_REP="${DRMTMB_COUNT_SLOPE_N_REP:-80}"
SEED_START="${DRMTMB_COUNT_SLOPE_SEED_START:-760001}"

case "$TASK_ID" in
  1)
    SHARD="phylo-poisson"
    SCRIPT="run-structured-re-count-slope-phylo-poisson-local-micro-shard.R"
    CELL_ID="qseries_phylo_poisson_q1_mu_one_slope"
    ;;
  2)
    SHARD="phylo-nbinom2"
    SCRIPT="run-structured-re-count-slope-phylo-nbinom2-local-micro-shard.R"
    CELL_ID="qseries_phylo_nbinom2_q1_mu_one_slope"
    ;;
  3)
    SHARD="spatial-poisson"
    SCRIPT="run-structured-re-count-slope-spatial-poisson-local-micro-shard.R"
    CELL_ID="qseries_spatial_poisson_q1_mu_one_slope"
    ;;
  4)
    SHARD="spatial-nbinom2"
    SCRIPT="run-structured-re-count-slope-spatial-nbinom2-local-micro-shard.R"
    CELL_ID="qseries_spatial_nbinom2_q1_mu_one_slope"
    ;;
  5)
    SHARD="animal-poisson"
    SCRIPT="run-structured-re-count-slope-animal-poisson-local-micro-shard.R"
    CELL_ID="qseries_animal_poisson_q1_mu_one_slope"
    ;;
  6)
    SHARD="animal-nbinom2"
    SCRIPT="run-structured-re-count-slope-animal-nbinom2-local-micro-shard.R"
    CELL_ID="qseries_animal_nbinom2_q1_mu_one_slope"
    ;;
  7)
    SHARD="relmat-poisson"
    SCRIPT="run-structured-re-count-slope-relmat-poisson-local-micro-shard.R"
    CELL_ID="qseries_relmat_poisson_q1_mu_one_slope"
    ;;
  8)
    SHARD="relmat-nbinom2"
    SCRIPT="run-structured-re-count-slope-relmat-nbinom2-local-micro-shard.R"
    CELL_ID="qseries_relmat_nbinom2_q1_mu_one_slope"
    ;;
  *)
    echo "Unsupported SLURM_ARRAY_TASK_ID: $TASK_ID" >&2
    exit 2
    ;;
esac

RLIB="$RUN_ROOT/rlib/$SHARD"
WORK_REPO="$RUN_ROOT/work/source-$SHARD"
RESULTS_DIR="$RUN_ROOT/results/count-slope-recovery-rorqual/$SHARD"
METADATA_DIR="$RUN_ROOT/metadata/count-slope-recovery-rorqual/$SHARD"
ARTIFACT_NAME="2026-06-26-count-slope-${SHARD}-local-micro-shard"

mkdir -p \
  "$RUN_ROOT/logs" \
  "$RUN_ROOT/rlib" \
  "$RUN_ROOT/work" \
  "$RESULTS_DIR" \
  "$METADATA_DIR" \
  "$RLIB"

{
  echo "date=$(date -Iseconds)"
  echo "job=${SLURM_JOB_ID:-manual}"
  echo "array_job=${SLURM_ARRAY_JOB_ID:-manual}"
  echo "array_task=$TASK_ID"
  echo "node=${SLURMD_NODENAME:-unknown}"
  echo "run_root=$RUN_ROOT"
  echo "source_repo=$REPO"
  echo "work_repo=$WORK_REPO"
  echo "git_sha=$GIT_SHA"
  echo "shard=$SHARD"
  echo "cell_id=$CELL_ID"
  echo "script=$SCRIPT"
  echo "n_rep=$N_REP"
  echo "seed_start=$SEED_START"
  echo "R_LIBS=$RLIB"
} > "$METADATA_DIR/run-log.txt"

printf "%s\n" "$GIT_SHA" > "$METADATA_DIR/git-sha.txt"
module list > "$METADATA_DIR/module-list.txt" 2>&1

rm -rf "$WORK_REPO" "$RLIB"/00LOCK-* "$RLIB/drmTMB"
rsync -a \
  --exclude='.git/' \
  --exclude='docs/dev-log/simulation-artifacts/' \
  "$REPO"/ "$WORK_REPO"/

find "$WORK_REPO/src" -type f \( \
  -name '*.o' -o \
  -name '*.so' -o \
  -name '*.dll' -o \
  -name '*.dylib' \
\) -print -delete > "$METADATA_DIR/source-clean.txt" 2>&1

export R_LIBS="$RLIB"

Rscript --no-init-file - <<'RSCRIPT' \
  > "$METADATA_DIR/dependency-check.txt" 2>&1
needed <- c("cli", "RcppEigen", "TMB", "ape", "Matrix")
available <- vapply(needed, requireNamespace, logical(1), quietly = TRUE)
print(data.frame(package = needed, available = available))
if (!all(available)) {
  stop(
    "Missing module-backed R dependencies: ",
    paste(needed[!available], collapse = ", "),
    call. = FALSE
  )
}
print(vapply(needed, function(pkg) as.character(packageVersion(pkg)), character(1)))
print(.libPaths())
RSCRIPT

R CMD INSTALL --library="$RLIB" "$WORK_REPO" \
  > "$METADATA_DIR/package-install.log" 2>&1

Rscript --no-init-file -e 'writeLines(capture.output(sessionInfo()))' \
  > "$METADATA_DIR/sessionInfo.txt"

cd "$WORK_REPO"
set +e
Rscript --no-init-file \
  "$WORK_REPO/tools/$SCRIPT" \
  --n_rep="$N_REP" \
  --seed_start="$SEED_START" \
  > "$METADATA_DIR/runner.stdout" \
  2> "$METADATA_DIR/runner.stderr"
RUN_EXIT_CODE=$?
set -eo pipefail

echo "runner_exit_code=$RUN_EXIT_CODE" >> "$METADATA_DIR/run-log.txt"

if [ "$RUN_EXIT_CODE" -eq 0 ]; then
  cp -R \
    "$WORK_REPO/docs/dev-log/simulation-artifacts/$ARTIFACT_NAME" \
    "$RESULTS_DIR/artifacts"
fi

echo "done=$(date -Iseconds)" >> "$METADATA_DIR/run-log.txt"

exit "$RUN_EXIT_CODE"
