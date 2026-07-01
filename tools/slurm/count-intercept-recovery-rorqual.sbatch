#!/bin/bash
#SBATCH --job-name=cntintrec
#SBATCH --account=def-snakagaw_cpu
#SBATCH --cpus-per-task=4
#SBATCH --mem-per-cpu=4G
#SBATCH --time=0-04:00:00
#SBATCH --output=logs/%x-%j.out

# Primary-cluster recovery-only reproduction for the ten non-Gaussian
# count-intercept q1 mu rows. Submit from the campaign root after setting:
#
#   export DRMTMB_REPO=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>/source
#   export DRMTMB_RUN_ROOT=/project/def-snakagaw/snakagaw/drmtmb-qseries/<run>
#   export DRMTMB_GIT_SHA=<sha>
#   export DRMTMB_COUNT_INTERCEPT_N_REP=80
#   export DRMTMB_COUNT_INTERCEPT_SEED_START=2026062931
#   export DRMTMB_COUNT_INTERCEPT_LANES=ordinary_structured,phylo_formal,phylo_interaction
#   export DRMTMB_COUNT_INTERCEPT_FAMILIES=poisson,nbinom2
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
RLIB="${DRMTMB_RLIB:-$RUN_ROOT/rlib}"
COUNT_INTERCEPT_N_REP="${DRMTMB_COUNT_INTERCEPT_N_REP:-80}"
COUNT_INTERCEPT_SEED_START="${DRMTMB_COUNT_INTERCEPT_SEED_START:-2026062931}"
COUNT_INTERCEPT_LANES="${DRMTMB_COUNT_INTERCEPT_LANES:-ordinary_structured,phylo_formal,phylo_interaction}"
COUNT_INTERCEPT_FAMILIES="${DRMTMB_COUNT_INTERCEPT_FAMILIES:-poisson,nbinom2}"
RESULTS_DIR="$RUN_ROOT/results/count-intercept-recovery-rorqual"
METADATA_DIR="$RUN_ROOT/metadata/count-intercept-recovery-rorqual"

mkdir -p \
  "$RUN_ROOT/logs" \
  "$RUN_ROOT/results" \
  "$RUN_ROOT/metadata" \
  "$RESULTS_DIR" \
  "$METADATA_DIR" \
  "$RLIB"

{
  echo "date=$(date -Iseconds)"
  echo "job=${SLURM_JOB_ID:-manual}"
  echo "node=${SLURMD_NODENAME:-unknown}"
  echo "run_root=$RUN_ROOT"
  echo "repo=$REPO"
  echo "git_sha=$GIT_SHA"
  echo "n_rep=$COUNT_INTERCEPT_N_REP"
  echo "seed_start=$COUNT_INTERCEPT_SEED_START"
  echo "lanes=$COUNT_INTERCEPT_LANES"
  echo "families=$COUNT_INTERCEPT_FAMILIES"
  echo "R_LIBS=$RLIB"
} > "$METADATA_DIR/run-log.txt"

printf "%s\n" "$GIT_SHA" > "$METADATA_DIR/git-sha.txt"
module list > "$METADATA_DIR/module-list.txt" 2>&1

find "$REPO/src" -type f \( \
  -name '*.o' -o \
  -name '*.so' -o \
  -name '*.dll' -o \
  -name '*.dylib' \
\) -print -delete > "$METADATA_DIR/source-clean.txt" 2>&1
rm -rf "$RLIB"/00LOCK-* "$RLIB/drmTMB"

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

R CMD INSTALL --library="$RLIB" "$REPO" \
  > "$METADATA_DIR/package-install.log" 2>&1

Rscript --no-init-file -e 'writeLines(capture.output(sessionInfo()))' \
  > "$METADATA_DIR/sessionInfo.txt"

cd "$REPO"
set +e
Rscript --no-init-file \
  "$REPO/tools/run-structured-re-count-intercept-recovery-grid.R" \
  --output_dir="$RESULTS_DIR/artifacts" \
  --n_rep="$COUNT_INTERCEPT_N_REP" \
  --seed_start="$COUNT_INTERCEPT_SEED_START" \
  --cores="${SLURM_CPUS_PER_TASK:-4}" \
  --backend=multicore \
  --lanes="$COUNT_INTERCEPT_LANES" \
  --families="$COUNT_INTERCEPT_FAMILIES" \
  --overwrite \
  > "$METADATA_DIR/runner.stdout" \
  2> "$METADATA_DIR/runner.stderr"
RUN_EXIT_CODE=$?
set -eo pipefail

echo "runner_exit_code=$RUN_EXIT_CODE" >> "$METADATA_DIR/run-log.txt"
echo "done=$(date -Iseconds)" >> "$METADATA_DIR/run-log.txt"

if command -v seff >/dev/null 2>&1 && [ -n "${SLURM_JOB_ID:-}" ]; then
  seff "$SLURM_JOB_ID" > "$METADATA_DIR/seff.txt" 2>&1 || true
fi

exit "$RUN_EXIT_CODE"
