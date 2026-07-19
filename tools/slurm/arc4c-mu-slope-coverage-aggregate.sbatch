#!/bin/bash
#SBATCH --job-name=arc4cAggregate
#SBATCH --account=def-snakagaw_cpu
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=0-02:00:00
#SBATCH --output=logs/%x-%j.out

# Submit only after a successful array, for example:
# sbatch --dependency=afterok:<array-job-id> tools/slurm/arc4c-mu-slope-coverage-aggregate.sbatch
# For the N=1 smoke selector, export DRMTMB_ARC4C_AGGREGATE_MODE=smoke and
# submit this same script with --dependency=afterok:<smoke-array-job-id>.
set -euo pipefail
[[ -n "${SLURM_JOB_ID:-}" ]] || { echo "Refusing login-node execution." >&2; exit 2; }
module load StdEnv/2023 gcc/12.3 r/4.4.0
export R_PROFILE_USER=/dev/null NOT_CRAN=true
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 FLEXIBLAS_NUM_THREADS=1 BLIS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1

RUN_ROOT="${DRMTMB_ARC4C_RUN_ROOT:?DRMTMB_ARC4C_RUN_ROOT must be set}"
REPO="${DRMTMB_ARC4C_REPO:?DRMTMB_ARC4C_REPO must be the verified project clone}"
MERGE_SHA="${DRMTMB_ARC4C_MERGE_SHA:?DRMTMB_ARC4C_MERGE_SHA must be the verified PR-A merge SHA}"
SHARED_RLIB="${DRMTMB_ARC4C_RLIB:?DRMTMB_ARC4C_RLIB must be the single preflight project library}"
BASE_RLIB="${DRMTMB_BASE_RLIB:-/project/def-snakagaw/snakagaw/R/x86_64-pc-linux-gnu-library/4.4}"
export R_LIBS="$SHARED_RLIB:$BASE_RLIB" DRMTMB_RLIB="$SHARED_RLIB"
MODE="${DRMTMB_ARC4C_AGGREGATE_MODE:-full}"
case "$MODE" in
  full)
    MANIFEST="${DRMTMB_ARC4C_MANIFEST:?DRMTMB_ARC4C_MANIFEST must be the approved full manifest}"
    INPUT_DIR="$RUN_ROOT/shards"; FINAL_DIR="$RUN_ROOT/aggregate"
    ;;
  smoke)
    MANIFEST="${DRMTMB_ARC4C_SMOKE_MANIFEST:?DRMTMB_ARC4C_SMOKE_MANIFEST must be the generated 12-row smoke manifest}"
    INPUT_DIR="$RUN_ROOT/smoke/shards"; FINAL_DIR="$RUN_ROOT/smoke/aggregate"
    ;;
  *) echo "DRMTMB_ARC4C_AGGREGATE_MODE must be full or smoke." >&2; exit 2 ;;
esac
AGGREGATOR="${DRMTMB_ARC4C_AGGREGATOR:-tools/summarize-arc4c-mu-slope-coverage.R}"
PREFLIGHT_DIR="$RUN_ROOT/preflight"; RECEIPT="$PREFLIGHT_DIR/receipt.tsv"
receipt_value() { awk -F '\t' -v key="$1" '$1 == key { print $2; exit }' "$RECEIPT"; }
source_tree_sha256() { (cd "$REPO" && git ls-files -z | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}'); }
[[ -d "$REPO/.git" && -d "$SHARED_RLIB" && -f "$MANIFEST" && -f "$RECEIPT" && -f "$PREFLIGHT_DIR/receipt.tsv.sha256" ]] || { echo "Missing verified preflight clone/library/receipt/manifest." >&2; exit 2; }
(cd "$PREFLIGHT_DIR" && sha256sum -c receipt.tsv.sha256) || { echo "Preflight receipt checksum failed." >&2; exit 2; }
[[ "$(git -C "$REPO" rev-parse HEAD)" == "$MERGE_SHA" && -z "$(git -C "$REPO" status --porcelain)" ]] || { echo "Repository SHA/clean-status verification failed." >&2; exit 2; }
[[ "$(receipt_value merge_sha)" == "$MERGE_SHA" && "$(receipt_value head_sha)" == "$MERGE_SHA" && "$(receipt_value tree_sha)" == "$(git -C "$REPO" rev-parse HEAD^{tree})" ]] || { echo "Preflight receipt SHA mismatch." >&2; exit 2; }
[[ "$(receipt_value source_tree_sha256)" == "$(source_tree_sha256)" && "$(receipt_value git_status)" == "clean" && "$(receipt_value R_LIBS)" == "$SHARED_RLIB:$BASE_RLIB" ]] || { echo "Preflight source/library checksum mismatch." >&2; exit 2; }
[[ "$(receipt_value R_version)" == "$(R --version | head -1)" && "$(receipt_value gcc_version)" == "$(gcc --version | head -1)" && "$(receipt_value TMB_version)" == "$(Rscript --no-init-file -e 'cat(as.character(packageVersion("TMB")))')" ]] || { echo "Preflight R/compiler/TMB environment mismatch." >&2; exit 2; }
[[ "$(receipt_value module_list_sha256)" == "$(sha256sum "$PREFLIGHT_DIR/module-list.txt" | awk '{print $1}')" && "$(receipt_value session_info_sha256)" == "$(sha256sum "$PREFLIGHT_DIR/sessionInfo.txt" | awk '{print $1}')" ]] || { echo "Preflight module/session checksum mismatch." >&2; exit 2; }
TASK_WORK_ROOT="${SLURM_TMPDIR:-$RUN_ROOT/aggregate-work/${SLURM_JOB_ID}}"
TASK_OUTPUT_DIR="$TASK_WORK_ROOT/results"
mkdir -p "$TASK_WORK_ROOT" "$TASK_OUTPUT_DIR" "$FINAL_DIR"
copy_back() { rsync -a "$TASK_OUTPUT_DIR/" "$FINAL_DIR/"; }
on_exit() { status=$?; set +e; copy_back; copy_status=$?; [[ $status -eq 0 && $copy_status -ne 0 ]] && status=$copy_status; exit "$status"; }
trap on_exit EXIT
{
  echo "aggregate_mode=$MODE"; echo "hostname=${SLURMD_NODENAME:-$(hostname)}"; echo "slurm_job_id=${SLURM_JOB_ID}"
  echo "slurm_array_job_id=${SLURM_ARRAY_JOB_ID:-none}"; echo "slurm_array_task_id=${SLURM_ARRAY_TASK_ID:-none}"
  echo "slurm_job_dependency=${SLURM_JOB_DEPENDENCY:-unknown}"; echo "merge_sha=$MERGE_SHA"; echo "preflight_receipt=$RECEIPT"
} > "$TASK_OUTPUT_DIR/provenance-aggregate-job_${SLURM_JOB_ID}.txt"
env | sort > "$TASK_OUTPUT_DIR/environment-aggregate-job_${SLURM_JOB_ID}.txt"
set +e
(
  cd "$REPO"
  Rscript --no-init-file "$AGGREGATOR" --mode="$MODE" --manifest="$MANIFEST" --input-dir="$INPUT_DIR" --output-dir="$TASK_OUTPUT_DIR"
) > "$TASK_OUTPUT_DIR/runner-aggregate-job_${SLURM_JOB_ID}.stdout" 2> "$TASK_OUTPUT_DIR/runner-aggregate-job_${SLURM_JOB_ID}.stderr"
RUN_STATUS=$?
set -e
printf 'aggregate_exit_code=%s\n' "$RUN_STATUS" >> "$TASK_OUTPUT_DIR/provenance-aggregate-job_${SLURM_JOB_ID}.txt"
exit "$RUN_STATUS"
