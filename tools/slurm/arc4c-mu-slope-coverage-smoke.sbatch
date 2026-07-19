#!/bin/bash
#SBATCH --job-name=arc4cSmoke
#SBATCH --account=def-snakagaw_cpu
#SBATCH --array=1-12%12
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=0-00:30:00
#SBATCH --output=logs/%x-%A_%a.out

# Arc 4c N=1 smoke worker: all 3 families x M {8,16,32,64}.  This script is
# intentionally a worker only; it is not authorization to run the smoke.
set -euo pipefail
[[ -n "${SLURM_JOB_ID:-}" ]] || { echo "Refusing login-node execution." >&2; exit 2; }
module load StdEnv/2023 gcc/12.3 r/4.4.0
export R_PROFILE_USER=/dev/null NOT_CRAN=true
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 FLEXIBLAS_NUM_THREADS=1 BLIS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1

RUN_ROOT="${DRMTMB_ARC4C_RUN_ROOT:?DRMTMB_ARC4C_RUN_ROOT must be a /project campaign directory}"
REPO="${DRMTMB_ARC4C_REPO:?DRMTMB_ARC4C_REPO must be the verified project clone}"
MERGE_SHA="${DRMTMB_ARC4C_MERGE_SHA:?DRMTMB_ARC4C_MERGE_SHA must be the verified PR-A merge SHA}"
SHARED_RLIB="${DRMTMB_ARC4C_RLIB:?DRMTMB_ARC4C_RLIB must be the single preflight project library}"
BASE_RLIB="${DRMTMB_BASE_RLIB:-/project/def-snakagaw/snakagaw/R/x86_64-pc-linux-gnu-library/4.4}"
export R_LIBS="$SHARED_RLIB:$BASE_RLIB" DRMTMB_RLIB="$SHARED_RLIB"
PREFLIGHT_DIR="$RUN_ROOT/preflight"; RECEIPT="$PREFLIGHT_DIR/receipt.tsv"
source_tree_sha256() { (cd "$REPO" && git ls-files -z | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}'); }
receipt_value() { awk -F '\t' -v key="$1" '$1 == key { print $2; exit }' "$RECEIPT"; }
[[ -d "$REPO/.git" && -d "$SHARED_RLIB" && -f "$RECEIPT" && -f "$PREFLIGHT_DIR/receipt.tsv.sha256" ]] || { echo "Missing verified preflight clone/library/receipt." >&2; exit 2; }
(cd "$PREFLIGHT_DIR" && sha256sum -c receipt.tsv.sha256) || { echo "Preflight receipt checksum failed." >&2; exit 2; }
[[ "$(git -C "$REPO" rev-parse HEAD)" == "$MERGE_SHA" && -z "$(git -C "$REPO" status --porcelain)" ]] || { echo "Repository SHA/clean-status verification failed." >&2; exit 2; }
[[ "$(receipt_value merge_sha)" == "$MERGE_SHA" && "$(receipt_value head_sha)" == "$MERGE_SHA" && "$(receipt_value tree_sha)" == "$(git -C "$REPO" rev-parse HEAD^{tree})" ]] || { echo "Preflight receipt SHA mismatch." >&2; exit 2; }
[[ "$(receipt_value source_tree_sha256)" == "$(source_tree_sha256)" && "$(receipt_value git_status)" == "clean" ]] || { echo "Preflight source checksum mismatch." >&2; exit 2; }
[[ -f "$REPO/src/drmTMB.so" && "$(receipt_value dll_sha256)" == "$(sha256sum "$REPO/src/drmTMB.so" | awk '{print $1}')" ]] || { echo "Preflight DLL checksum mismatch." >&2; exit 2; }
[[ "$(receipt_value R_LIBS)" == "$SHARED_RLIB:$BASE_RLIB" ]] || { echo "Preflight library path mismatch." >&2; exit 2; }
[[ "$(receipt_value R_version)" == "$(R --version | head -1)" && "$(receipt_value gcc_version)" == "$(gcc --version | head -1)" && "$(receipt_value TMB_version)" == "$(Rscript --no-init-file -e 'cat(as.character(packageVersion("TMB")))')" ]] || { echo "Preflight R/compiler/TMB environment mismatch." >&2; exit 2; }
[[ "$(receipt_value module_list_sha256)" == "$(sha256sum "$PREFLIGHT_DIR/module-list.txt" | awk '{print $1}')" && "$(receipt_value session_info_sha256)" == "$(sha256sum "$PREFLIGHT_DIR/sessionInfo.txt" | awk '{print $1}')" ]] || { echo "Preflight module/session checksum mismatch." >&2; exit 2; }
MANIFEST="${DRMTMB_ARC4C_SMOKE_MANIFEST:?DRMTMB_ARC4C_SMOKE_MANIFEST must be the generated 12-row smoke manifest}"
TASK_INDEX="${SLURM_ARRAY_TASK_ID:?SLURM_ARRAY_TASK_ID not set}"
RUNNER="${DRMTMB_ARC4C_RUNNER:-tools/run-arc4c-mu-slope-coverage.R}"
ROW=$(awk -F '\t' -v n="$TASK_INDEX" 'NR == n + 1 { print; exit }' "$MANIFEST")
[[ -n "$ROW" ]] || { echo "No smoke manifest row for index $TASK_INDEX." >&2; exit 2; }
IFS=$'\t' read -r ARRAY_INDEX LOGICAL_SMOKE_ID CELL_ID FAMILY M SHARD REPLICATE_START REPLICATE_END <<< "$ROW"
[[ "$ARRAY_INDEX" == "$TASK_INDEX" ]] || { echo "Smoke manifest array-index mismatch." >&2; exit 2; }

# Keep canonical smoke shard files flat: Curie's afterok selector validates the
# exact 12-file manifest in this one directory before making any selection.
PROJECT_TASK_DIR="$RUN_ROOT/smoke/shards"
TASK_WORK_ROOT="${SLURM_TMPDIR:-$RUN_ROOT/smoke-work/${SLURM_JOB_ID}_${TASK_INDEX}}"
TASK_OUTPUT_DIR="$TASK_WORK_ROOT/results"
mkdir -p "$TASK_WORK_ROOT" "$TASK_OUTPUT_DIR" "$PROJECT_TASK_DIR"
export R_LIBS="$SHARED_RLIB:$BASE_RLIB" DRMTMB_RLIB="$SHARED_RLIB" DRMTMB_ARC4C_REPO="$REPO" DRMTMB_TASK_REPO="$REPO"
SHARD_BASENAME=$(printf 'arc4c-%s-M%02d-shard000.tsv' "$CELL_ID" "$M")
if [[ -f "$PROJECT_TASK_DIR/$SHARD_BASENAME" || -f "$PROJECT_TASK_DIR/$SHARD_BASENAME.md5" ]]; then
  # Curie's runner quarantines an incomplete pair and starts a fresh shard.
  [[ -f "$PROJECT_TASK_DIR/$SHARD_BASENAME" ]] && cp "$PROJECT_TASK_DIR/$SHARD_BASENAME" "$TASK_OUTPUT_DIR/"
  [[ -f "$PROJECT_TASK_DIR/$SHARD_BASENAME.md5" ]] && cp "$PROJECT_TASK_DIR/$SHARD_BASENAME.md5" "$TASK_OUTPUT_DIR/"
fi
copy_back() { rsync -a "$TASK_OUTPUT_DIR/" "$PROJECT_TASK_DIR/" && cp "$MANIFEST" "$PROJECT_TASK_DIR/manifest-smoke-logical_${LOGICAL_SMOKE_ID}.tsv"; }
on_exit() { status=$?; set +e; copy_back; copy_status=$?; [[ $status -eq 0 && $copy_status -ne 0 ]] && status=$copy_status; exit "$status"; }
trap on_exit EXIT
{
  echo "logical_smoke_id=$LOGICAL_SMOKE_ID"; echo "cell_id=$CELL_ID"; echo "family=$FAMILY"; echo "M=$M"; echo "n_rep=1"
  echo "merge_sha=$MERGE_SHA"; echo "preflight_receipt=$RECEIPT"; echo "preflight_receipt_sha256=$(awk '{print $1}' "$PREFLIGHT_DIR/receipt.tsv.sha256")"
  echo "hostname=${SLURMD_NODENAME:-$(hostname)}"; echo "slurm_job_id=${SLURM_JOB_ID}"
  echo "slurm_array_job_id=${SLURM_ARRAY_JOB_ID:-$SLURM_JOB_ID}"; echo "slurm_array_task_id=${SLURM_ARRAY_TASK_ID}"
} > "$TASK_OUTPUT_DIR/provenance-smoke-logical_${LOGICAL_SMOKE_ID}.txt"
env | sort > "$TASK_OUTPUT_DIR/environment-smoke-logical_${LOGICAL_SMOKE_ID}.txt"
set +e
(
  cd "$REPO"
  Rscript --no-init-file "$RUNNER" \
    --mode=smoke --cell-id="$CELL_ID" --family="$FAMILY" --M="$M" \
    --replicate-start=1 --replicate-end=1 --out-dir="$TASK_OUTPUT_DIR"
) > "$TASK_OUTPUT_DIR/runner-smoke-logical_${LOGICAL_SMOKE_ID}.stdout" 2> "$TASK_OUTPUT_DIR/runner-smoke-logical_${LOGICAL_SMOKE_ID}.stderr"
RUN_STATUS=$?
set -e
printf 'runner_exit_code=%s\n' "$RUN_STATUS" >> "$TASK_OUTPUT_DIR/provenance-smoke-logical_${LOGICAL_SMOKE_ID}.txt"
exit "$RUN_STATUS"
