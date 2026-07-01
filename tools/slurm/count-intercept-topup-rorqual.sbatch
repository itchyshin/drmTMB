#!/bin/bash
#SBATCH --job-name=cnttopup
#SBATCH --account=def-snakagaw_cpu
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=4G
#SBATCH --time=0-02:00:00
#SBATCH --output=logs/%x-%j.out

# Primary-cluster confirmation for the three non-Gaussian count-intercept
# top-up recovery rows. Submit from the campaign root after setting:
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

RESULTS_DIR="$RUN_ROOT/results/count-intercept-topup-rorqual"
mkdir -p "$RUN_ROOT"/{logs,metadata,results} "$RESULTS_DIR" "$RLIB"

{
  echo "date=$(date -Iseconds)"
  echo "job=${SLURM_JOB_ID:-manual}"
  echo "node=${SLURMD_NODENAME:-unknown}"
  echo "run_root=$RUN_ROOT"
  echo "repo=$REPO"
  echo "git_sha=$GIT_SHA"
  echo "R_LIBS=$R_LIBS"
} > "$RUN_ROOT/metadata/count-intercept-topup-run-log.txt"

printf "%s\n" "$GIT_SHA" > "$RUN_ROOT/metadata/git-sha.txt"
module list > "$RUN_ROOT/metadata/module-list.txt" 2>&1

find "$REPO/src" -type f \( \
  -name '*.o' -o \
  -name '*.so' -o \
  -name '*.dll' -o \
  -name '*.dylib' \
\) -print -delete > "$RUN_ROOT/metadata/source-clean.txt" 2>&1
rm -rf "$RLIB"/00LOCK-* "$RLIB/drmTMB"

Rscript --no-init-file - <<'RSCRIPT' \
  > "$RUN_ROOT/metadata/dependency-check.txt" 2>&1
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

R CMD INSTALL --library="$RLIB" "$REPO" \
  > "$RUN_ROOT/metadata/package-install.log" 2>&1

Rscript --no-init-file -e 'writeLines(capture.output(sessionInfo()))' \
  > "$RUN_ROOT/metadata/sessionInfo.txt"

cd "$REPO"

set +e
Rscript --no-init-file \
  "$REPO/tools/run-structured-re-count-intercept-denominator-diagnostic.R" \
  --output_dir="$RESULTS_DIR/artifacts" \
  --dashboard_output="$RESULTS_DIR/count-intercept-topup-condition-diagnostic.tsv" \
  --n_rep=80 \
  --seed_start=2026062921 \
  --cores="${SLURM_CPUS_PER_TASK:-4}" \
  --backend=multicore \
  --overwrite
RUN_EXIT_CODE=$?
set -eo pipefail

echo "runner_exit_code=$RUN_EXIT_CODE" \
  >> "$RUN_ROOT/metadata/count-intercept-topup-run-log.txt"

if [ "$RUN_EXIT_CODE" -eq 0 ]; then
  set +e
  Rscript --no-init-file \
    "$REPO/tools/summarize-structured-re-count-intercept-topup-recovery.R" \
    --artifact_dir="$RESULTS_DIR/artifacts" \
    --output="$RESULTS_DIR/structured-re-count-intercept-topup-recovery-results.tsv"
  SUMMARY_EXIT_CODE=$?
  set -eo pipefail
else
  SUMMARY_EXIT_CODE=99
fi

echo "summary_exit_code=$SUMMARY_EXIT_CODE" \
  >> "$RUN_ROOT/metadata/count-intercept-topup-run-log.txt"
echo "done=$(date -Iseconds)" \
  >> "$RUN_ROOT/metadata/count-intercept-topup-run-log.txt"

if command -v seff >/dev/null 2>&1 && [ -n "${SLURM_JOB_ID:-}" ]; then
  seff "$SLURM_JOB_ID" > "$RUN_ROOT/metadata/seff.txt" 2>&1 || true
fi

if [ "$RUN_EXIT_CODE" -ne 0 ]; then
  exit "$RUN_EXIT_CODE"
fi
exit "$SUMMARY_EXIT_CODE"
