#!/bin/bash
#SBATCH --job-name=aoi2-bnb
#SBATCH --account=def-snakagaw_cpu
#SBATCH --array=1-60%4
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=0-02:00:00
#SBATCH --output=/project/def-snakagaw/snakagaw/drmTMB-aoi2/2026-07-29-aoi2-bnb-fixed-r2/logs/%x-%A_%a.out

# AOI-2 point-recovery only.  This script never computes uncertainty,
# intervals, coverage, public capability status, or AOI-3 results.
set -euo pipefail

module load StdEnv/2023 gcc/12.3 r-bundle-bioconductor/3.21

export R_PROFILE_USER=/dev/null
export NOT_CRAN=true
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1

# The original immutable root is retained as a failed mechanical-dispatch
# receipt.  Recovery uses a new root so a corrected task cannot overwrite or
# be confused with its pre-created empty result directories.
RUN_ROOT="/project/def-snakagaw/snakagaw/drmTMB-aoi2/2026-07-29-aoi2-bnb-fixed-r2"
SOURCE="$RUN_ROOT/source"
TASK_ID="${SLURM_ARRAY_TASK_ID:?SLURM_ARRAY_TASK_ID not set}"
case "$RUN_ROOT" in
  /project/def-snakagaw/snakagaw/drmTMB-aoi2/*) ;;
  *) echo "Unsafe RUN_ROOT: $RUN_ROOT" >&2; exit 2 ;;
esac
if [ ! -d "$SOURCE" ]; then
  echo "Staged source not found: $SOURCE" >&2
  exit 2
fi
if [ "$TASK_ID" -lt 1 ] || [ "$TASK_ID" -gt 60 ]; then
  echo "Unsupported array task: $TASK_ID" >&2
  exit 2
fi

FORMULAS=(additive mixed factor_interaction numeric_interaction transformation)
SIZES=(360 720 1440)
ZERO=$((TASK_ID - 1))
FORMULA_INDEX=$((ZERO / 12))
WITHIN_FORMULA=$((ZERO % 12))
SIZE_INDEX=$((WITHIN_FORMULA / 4))
SHARD_INDEX=$((WITHIN_FORMULA % 4))
FORMULA_ID="${FORMULAS[$FORMULA_INDEX]}"
N="${SIZES[$SIZE_INDEX]}"
REPLICATE_START=$((SHARD_INDEX * 50 + 1))
REPLICATE_END=$((REPLICATE_START + 49))
SHARD="${FORMULA_ID}-n${N}-r${REPLICATE_START}-${REPLICATE_END}"
WORK_SOURCE="$RUN_ROOT/work/$SHARD/source"
RLIB="$RUN_ROOT/rlib/$SHARD"
RESULT_DIR="$RUN_ROOT/results/$SHARD"
METADATA_DIR="$RUN_ROOT/metadata/$SHARD"

if [ -e "$RESULT_DIR" ]; then
  echo "Refusing to overwrite immutable result directory: $RESULT_DIR" >&2
  exit 2
fi
mkdir -p "$RUN_ROOT/logs" "$RUN_ROOT/work/$SHARD" "$RLIB" "$METADATA_DIR"
rsync -a --exclude='.git/' --exclude='docs/dev-log/simulation-artifacts/' "$SOURCE/" "$WORK_SOURCE/"
find "$WORK_SOURCE/src" -type f \( -name '*.o' -o -name '*.so' -o -name '*.dll' -o -name '*.dylib' \) -print -delete > "$METADATA_DIR/source-clean.txt" 2>&1

{
  echo "date=$(date -Iseconds)"
  echo "job=${SLURM_JOB_ID:-manual}"
  echo "array_job=${SLURM_ARRAY_JOB_ID:-manual}"
  echo "array_task=$TASK_ID"
  echo "node=${SLURMD_NODENAME:-unknown}"
  echo "run_root=$RUN_ROOT"
  echo "source=$SOURCE"
  echo "git_sha=$(cat "$SOURCE/.aoi2-source-sha")"
  echo "formula_id=$FORMULA_ID"
  echo "n=$N"
  echo "replicate_start=$REPLICATE_START"
  echo "replicate_end=$REPLICATE_END"
  echo "R_LIBS=$RLIB"
} > "$METADATA_DIR/run-log.txt"
module list > "$METADATA_DIR/module-list.txt" 2>&1

Rscript --no-init-file - <<'RSCRIPT' > "$METADATA_DIR/dependency-check.txt" 2>&1
needed <- c("RcppEigen", "TMB", "ape", "Matrix")
available <- vapply(needed, requireNamespace, logical(1), quietly = TRUE)
print(data.frame(package = needed, available = available))
if (!all(available)) stop("Missing dependencies: ", paste(needed[!available], collapse = ", "))
print(vapply(needed, function(pkg) as.character(packageVersion(pkg)), character(1)))
RSCRIPT

R CMD INSTALL --library="$RLIB" "$WORK_SOURCE" > "$METADATA_DIR/package-install.log" 2>&1
export R_LIBS="$RLIB"
set +e
Rscript --no-init-file "$WORK_SOURCE/tools/run-aoi2-bernoulli-nb2-recovery.R" \
  --out-dir="$RESULT_DIR" --formula-id="$FORMULA_ID" --n="$N" \
  --replicate-start="$REPLICATE_START" --replicate-end="$REPLICATE_END" \
  > "$METADATA_DIR/runner.stdout" 2> "$METADATA_DIR/runner.stderr"
EXIT_CODE=$?
set -e
echo "runner_exit_code=$EXIT_CODE" >> "$METADATA_DIR/run-log.txt"
echo "done=$(date -Iseconds)" >> "$METADATA_DIR/run-log.txt"
exit "$EXIT_CODE"
