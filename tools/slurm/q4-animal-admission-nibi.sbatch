#!/bin/bash
#SBATCH --job-name=q4AnAdm
#SBATCH --account=def-snakagaw_cpu
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=6G
#SBATCH --time=0-03:00:00
#SBATCH --output=logs/%x-%j.out

# Current-source diagnostic for the animal q4 all-four direct-SD admission
# gate. This is admission evidence only, not coverage evidence.
#
# Submit from the campaign root after setting:
#
#   export DRMTMB_RLIB=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>/rlib
#   export DRMTMB_REPO=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>/source
#   export DRMTMB_RUN_ROOT=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>
#   export DRMTMB_GIT_SHA=<sha>

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
RLIB="${DRMTMB_RLIB:-$RUN_ROOT/rlib}"
export R_LIBS="$RLIB"

RESULTS_DIR="$RUN_ROOT/results/q4-animal-all-four-admission-16"
LOG_DIR="$RUN_ROOT/logs"
META_DIR="$RUN_ROOT/metadata"
mkdir -p "$RESULTS_DIR" "$LOG_DIR" "$META_DIR" "$RLIB"

TASK_WORK_ROOT="${SLURM_TMPDIR:-$RUN_ROOT/work/${SLURM_JOB_ID}}"
TASK_REPO="$TASK_WORK_ROOT/drmTMB-source"
mkdir -p "$TASK_WORK_ROOT"

{
  echo "date=$(date -Iseconds)"
  echo "job=${SLURM_JOB_ID:-manual}"
  echo "node=${SLURMD_NODENAME:-unknown}"
  echo "run_root=$RUN_ROOT"
  echo "repo=$REPO"
  echo "task_repo=$TASK_REPO"
  echo "git_sha=$GIT_SHA"
  echo "R_LIBS=$R_LIBS"
  echo "n_rep=16"
  echo "seed_start=910101"
  echo "variant=more_levels"
} > "$META_DIR/q4-animal-admission-run-log.txt"

printf "%s\n" "$GIT_SHA" > "$META_DIR/git-sha.txt"
module list > "$META_DIR/module-list.txt" 2>&1

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

Rscript --no-init-file - <<'RSCRIPT' \
  > "$META_DIR/dependency-check.txt" 2>&1
needed <- c("cli", "RcppEigen", "TMB", "ape")
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

Rscript --no-init-file -e 'writeLines(capture.output(sessionInfo()))' \
  > "$META_DIR/sessionInfo.txt"

set +e
Rscript --no-init-file \
  "$TASK_REPO/tools/run-structured-re-q4-animal-all-four-admission-probe.R" \
  --n-rep=16 \
  --seed-start=910101 \
  --variant=more_levels \
  --methods=wald,profile \
  --profile-max-eval=60 \
  --output-dir="$RESULTS_DIR" \
  --attempt-temp-install \
  --no-load-all \
  --write-dashboard=false \
  --overwrite=true
RUN_EXIT_CODE=$?
set -eo pipefail

echo "runner_exit_code=$RUN_EXIT_CODE" >> "$META_DIR/q4-animal-admission-run-log.txt"
echo "done=$(date -Iseconds)" >> "$META_DIR/q4-animal-admission-run-log.txt"

if command -v seff >/dev/null 2>&1 && [ -n "${SLURM_JOB_ID:-}" ]; then
  seff "$SLURM_JOB_ID" > "$META_DIR/seff.txt" 2>&1 || true
fi

exit "$RUN_EXIT_CODE"
