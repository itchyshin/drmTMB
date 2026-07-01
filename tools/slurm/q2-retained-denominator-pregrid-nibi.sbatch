#!/bin/bash
#SBATCH --job-name=q2RetPre
#SBATCH --account=def-snakagaw_cpu
#SBATCH --array=1-5
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=6G
#SBATCH --time=0-08:00:00
#SBATCH --output=logs/%x-%A_%a.out

# Reviewed SR150 retained-denominator pregrid for q2 intercept and q2-plus-q2
# ready targets. This is pregrid evidence only, not coverage-signoff evidence,
# and writes artifacts only; any dashboard import must be reviewed separately.
#
# Array task IDs:
#   1 q2_intercept phylo
#   2 q2_intercept spatial
#   3 q2_intercept animal
#   4 q2_intercept relmat
#   5 q2_plus_q2_intercept phylo, five ready targets only
#
# Submit from the campaign root after setting:
#
#   export DRMTMB_REPO=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>/source
#   export DRMTMB_RUN_ROOT=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>
#   export DRMTMB_RLIB=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>/rlib
#   export DRMTMB_PACKAGE_CACHE=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>/package-cache
#   export DRMTMB_GIT_SHA=<sha>
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

REPO="${DRMTMB_REPO:?DRMTMB_REPO not set}"
RUN_ROOT="${DRMTMB_RUN_ROOT:?DRMTMB_RUN_ROOT not set}"
GIT_SHA="${DRMTMB_GIT_SHA:-unknown}"
RLIB_ROOT="${DRMTMB_RLIB:-$RUN_ROOT/rlib}"
RLIB="$RLIB_ROOT/shard_${SLURM_ARRAY_TASK_ID}"
BASE_RLIB="${DRMTMB_BASE_RLIB:-/project/def-snakagaw/snakagaw/R/x86_64-pc-linux-gnu-library/4.4}"
PACKAGE_CACHE="${DRMTMB_PACKAGE_CACHE:-$RUN_ROOT/package-cache}"
export R_LIBS="$RLIB:$BASE_RLIB"
export DRMTMB_RLIB="$RLIB"
export DRMTMB_PACKAGE_CACHE="$PACKAGE_CACHE"
export DRMTMB_RUN_ROOT="$RUN_ROOT"
export DRMTMB_META_DIR="$RUN_ROOT/metadata/shard_${SLURM_ARRAY_TASK_ID}"
export DRMTMB_LOG_DIR="$RUN_ROOT/logs"
export DRMTMB_RUN_INSTALLED=true

case "${SLURM_ARRAY_TASK_ID}" in
  1)
    PREFAMILY="q2_intercept"
    PROVIDERS="phylo"
    PROFILE_MAX_EVAL=60
    TARGET_NAME="q2-intercept-phylo"
    ;;
  2)
    PREFAMILY="q2_intercept"
    PROVIDERS="spatial"
    PROFILE_MAX_EVAL=60
    TARGET_NAME="q2-intercept-spatial"
    ;;
  3)
    PREFAMILY="q2_intercept"
    PROVIDERS="animal"
    PROFILE_MAX_EVAL=60
    TARGET_NAME="q2-intercept-animal"
    ;;
  4)
    PREFAMILY="q2_intercept"
    PROVIDERS="relmat"
    PROFILE_MAX_EVAL=60
    TARGET_NAME="q2-intercept-relmat"
    ;;
  5)
    PREFAMILY="q2_plus_q2_intercept"
    PROVIDERS="phylo"
    PROFILE_MAX_EVAL=80
    TARGET_NAME="q2-plus-q2-phylo-ready-targets"
    ;;
  *)
    echo "Unsupported SLURM_ARRAY_TASK_ID=${SLURM_ARRAY_TASK_ID}" >&2
    exit 2
    ;;
esac

RESULTS_DIR="$RUN_ROOT/results/q2-retained-denominator-sr150-pregrid/shard_${SLURM_ARRAY_TASK_ID}_${TARGET_NAME}/artifacts"
LOG_DIR="$RUN_ROOT/logs"
META_DIR="$DRMTMB_META_DIR"
mkdir -p "$RESULTS_DIR" "$LOG_DIR" "$META_DIR" "$RLIB" "$PACKAGE_CACHE"

TASK_WORK_ROOT="${SLURM_TMPDIR:-$RUN_ROOT/work/${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}}"
TASK_REPO="$TASK_WORK_ROOT/drmTMB-source"
mkdir -p "$TASK_WORK_ROOT"

HOST_NAME="${SLURMD_NODENAME:-$(hostname)}"
CLUSTER_NAME="${SLURM_CLUSTER_NAME:-unknown}"
HOST_CLASS="${CLUSTER_NAME}_retained_denominator_pregrid"
RUN_COMMAND="R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 R_LIBS=$R_LIBS DRMTMB_PACKAGE_CACHE=$PACKAGE_CACHE DRMTMB_RUN_INSTALLED=true DRMTMB_RUN_ROOT=$RUN_ROOT DRMTMB_META_DIR=$META_DIR DRMTMB_LOG_DIR=$LOG_DIR Rscript --no-init-file tools/run-structured-re-q2-retained-denominator-pregrid.R --pregrid-family=$PREFAMILY --n-rep=150 --providers=$PROVIDERS --profile-max-eval=$PROFILE_MAX_EVAL --host-class=$HOST_CLASS --host-name=$HOST_NAME --output-dir=$RESULTS_DIR --overwrite=true --write-dashboard=false"

{
  echo "date=$(date -Iseconds)"
  echo "job=${SLURM_JOB_ID:-manual}"
  echo "array_task=${SLURM_ARRAY_TASK_ID}"
  echo "node=$HOST_NAME"
  echo "slurm_cluster_name=$CLUSTER_NAME"
  echo "slurm_job_id=${SLURM_JOB_ID:-manual}"
  echo "run_root=$RUN_ROOT"
  echo "repo=$REPO"
  echo "task_repo=$TASK_REPO"
  echo "git_sha=$GIT_SHA"
  echo "R_LIBS=$R_LIBS"
  echo "package_cache=$PACKAGE_CACHE"
  echo "contract=structured-re-q2-retained-denominator-design.tsv"
  echo "pregrid_family=$PREFAMILY"
  echo "providers=$PROVIDERS"
  echo "n_rep=150"
  echo "promotion_decision=do_not_promote"
  echo "mcse_rule=MCSE <= 0.01 is a top-up target, not an SR150 pass claim"
} > "$META_DIR/q2-retained-denominator-pregrid-run-log.txt"

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
  > "$LOG_DIR/install-run-deps-${SLURM_ARRAY_TASK_ID}.stdout" \
  2> "$LOG_DIR/install-run-deps-${SLURM_ARRAY_TASK_ID}.stderr"
lib <- Sys.getenv("DRMTMB_RLIB")
cache <- Sys.getenv("DRMTMB_PACKAGE_CACHE")
base_lib <- Sys.getenv("DRMTMB_BASE_RLIB", "")
if (!nzchar(lib)) {
  lib <- strsplit(Sys.getenv("R_LIBS"), .Platform$path.sep, fixed = TRUE)[[1]][[1]]
}
if (!nzchar(cache) || !dir.exists(cache)) {
  stop("DRMTMB_PACKAGE_CACHE does not exist: ", cache, call. = FALSE)
}
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, base_lib[nzchar(base_lib)], .libPaths()))
install_one <- function(pkg) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    message(pkg, " already available")
    return(invisible())
  }
  tarballs <- list.files(
    cache,
    pattern = paste0("^", pkg, "_.*[.]tar[.]gz$"),
    full.names = TRUE
  )
  if (length(tarballs) != 1L) {
    stop(
      "Expected exactly one source tarball for ",
      pkg,
      " in ",
      cache,
      "; found ",
      length(tarballs),
      call. = FALSE
    )
  }
  install.packages(tarballs, lib = lib, repos = NULL, type = "source")
}
for (pkg in c("cli", "Rcpp", "RcppEigen", "TMB")) {
  install_one(pkg)
}
missing <- c("cli", "Rcpp", "RcppEigen", "TMB")[
  !vapply(
    c("cli", "Rcpp", "RcppEigen", "TMB"),
    requireNamespace,
    quietly = TRUE,
    FUN.VALUE = logical(1L)
  )
]
if (length(missing) > 0L) {
  stop("Run dependency install left missing packages: ", paste(missing, collapse = ", "), call. = FALSE)
}
RSCRIPT

R CMD INSTALL -l "$RLIB" "$TASK_REPO" \
  > "$LOG_DIR/r-cmd-install-${SLURM_ARRAY_TASK_ID}.stdout" \
  2> "$LOG_DIR/r-cmd-install-${SLURM_ARRAY_TASK_ID}.stderr"

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
  DRMTMB_PACKAGE_CACHE="$PACKAGE_CACHE" \
  DRMTMB_RUN_ROOT="$RUN_ROOT" \
  DRMTMB_META_DIR="$META_DIR" \
  DRMTMB_LOG_DIR="$LOG_DIR" \
  DRMTMB_GIT_SHA="$GIT_SHA" \
  Rscript --no-init-file \
    tools/run-structured-re-q2-retained-denominator-pregrid.R \
    --pregrid-family="$PREFAMILY" \
    --n-rep=150 \
    --providers="$PROVIDERS" \
    --profile-max-eval="$PROFILE_MAX_EVAL" \
    --host-class="$HOST_CLASS" \
    --host-name="$HOST_NAME" \
    --output-dir="$RESULTS_DIR" \
    --overwrite=true \
    --write-dashboard=false
) > "$LOG_DIR/q2-retained-denominator-pregrid-${SLURM_ARRAY_TASK_ID}.stdout" \
  2> "$LOG_DIR/q2-retained-denominator-pregrid-${SLURM_ARRAY_TASK_ID}.stderr"
RUN_EXIT_CODE=$?
set -eo pipefail

echo "runner_exit_code=$RUN_EXIT_CODE" >> "$META_DIR/q2-retained-denominator-pregrid-run-log.txt"
echo "done=$(date -Iseconds)" >> "$META_DIR/q2-retained-denominator-pregrid-run-log.txt"

if [ "$RUN_EXIT_CODE" -eq 0 ]; then
  printf "%s\n" "nibi q2 retained-denominator SR150 pregrid completed for $TARGET_NAME" \
    > "$META_DIR/run-status.txt"
else
  printf "%s\n" "nibi q2 retained-denominator SR150 pregrid failed for $TARGET_NAME: $RUN_EXIT_CODE" \
    > "$META_DIR/run-status.txt"
fi

if command -v seff >/dev/null 2>&1 && [ -n "${SLURM_JOB_ID:-}" ]; then
  seff "$SLURM_JOB_ID" > "$META_DIR/seff.txt" 2>&1 || true
fi

exit "$RUN_EXIT_CODE"
