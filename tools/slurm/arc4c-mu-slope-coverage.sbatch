#!/bin/bash
#SBATCH --job-name=arc4cMuSlope
#SBATCH --account=def-snakagaw_cpu
#SBATCH --array=1-1440%96
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=0-00:30:00
#SBATCH --output=logs/%x-%A_%a.out

# Arc 4c full array worker.  Submit only after the explicit compute gate and
# smoke selection.  Override --array, --time, and --mem from the generated
# dispatch plan; never submit the 1-1440 default after a smoke exclusion.
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
PREFLIGHT_DIR="$RUN_ROOT/preflight"
RECEIPT="$PREFLIGHT_DIR/receipt.tsv"

source_tree_sha256() {
  (cd "$REPO" && git ls-files -z | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}')
}
receipt_value() { awk -F '\t' -v key="$1" '$1 == key { print $2; exit }' "$RECEIPT"; }
verify_clean_source() {
  [[ -d "$REPO/.git" && -d "$SHARED_RLIB" ]] || { echo "Verified project clone/library missing." >&2; exit 2; }
  [[ "$(git -C "$REPO" rev-parse HEAD)" == "$MERGE_SHA" ]] || { echo "Repository HEAD does not match required merge SHA." >&2; exit 2; }
  [[ -z "$(git -C "$REPO" status --porcelain)" ]] || { echo "Repository must be clean after preflight." >&2; exit 2; }
}
write_preflight_receipt() {
  mkdir -p "$PREFLIGHT_DIR" "$SHARED_RLIB"
  verify_clean_source
  export R_LIBS="$SHARED_RLIB:$BASE_RLIB" DRMTMB_ARC4C_REPO="$REPO"
  Rscript --no-init-file -e 'pkgload::load_all(Sys.getenv("DRMTMB_ARC4C_REPO"), recompile = TRUE); invisible(TMB::MakeADFun)' \
    > "$PREFLIGHT_DIR/pkgload.stdout" 2> "$PREFLIGHT_DIR/pkgload.stderr"
  DLL="$REPO/src/drmTMB.so"
  [[ -f "$DLL" ]] || { echo "Preflight did not create the drmTMB DLL." >&2; exit 2; }
  module list > "$PREFLIGHT_DIR/module-list.txt" 2>&1 || true
  Rscript --no-init-file -e 'writeLines(capture.output(sessionInfo()))' > "$PREFLIGHT_DIR/sessionInfo.txt"
  {
    printf 'key\tvalue\n'
    printf 'merge_sha\t%s\nhead_sha\t%s\ntree_sha\t%s\ngit_status\tclean\n' "$MERGE_SHA" "$(git -C "$REPO" rev-parse HEAD)" "$(git -C "$REPO" rev-parse HEAD^{tree})"
    printf 'source_tree_sha256\t%s\ndll_sha256\t%s\nR_LIBS\t%s\n' "$(source_tree_sha256)" "$(sha256sum "$DLL" | awk '{print $1}')" "$R_LIBS"
    printf 'R_version\t%s\ngcc_version\t%s\nTMB_version\t%s\n' "$(R --version | head -1)" "$(gcc --version | head -1)" "$(Rscript --no-init-file -e 'cat(as.character(packageVersion("TMB")))')"
    printf 'module_list\t%s\nsession_info\t%s\nmodule_list_sha256\t%s\nsession_info_sha256\t%s\n' \
      "$PREFLIGHT_DIR/module-list.txt" "$PREFLIGHT_DIR/sessionInfo.txt" \
      "$(sha256sum "$PREFLIGHT_DIR/module-list.txt" | awk '{print $1}')" "$(sha256sum "$PREFLIGHT_DIR/sessionInfo.txt" | awk '{print $1}')"
  } > "$RECEIPT"
  (cd "$PREFLIGHT_DIR" && sha256sum receipt.tsv > receipt.tsv.sha256)
}
verify_preflight_receipt() {
  verify_clean_source
  [[ -f "$RECEIPT" && -f "$PREFLIGHT_DIR/receipt.tsv.sha256" ]] || { echo "Missing required compute-node preflight receipt." >&2; exit 2; }
  (cd "$PREFLIGHT_DIR" && sha256sum -c receipt.tsv.sha256) || { echo "Preflight receipt checksum failed." >&2; exit 2; }
  [[ "$(receipt_value merge_sha)" == "$MERGE_SHA" && "$(receipt_value head_sha)" == "$MERGE_SHA" ]] || { echo "Preflight receipt SHA mismatch." >&2; exit 2; }
  [[ "$(receipt_value tree_sha)" == "$(git -C "$REPO" rev-parse HEAD^{tree})" ]] || { echo "Preflight tree SHA mismatch." >&2; exit 2; }
  [[ "$(receipt_value git_status)" == "clean" && "$(receipt_value source_tree_sha256)" == "$(source_tree_sha256)" ]] || { echo "Preflight source checksum mismatch." >&2; exit 2; }
  [[ -f "$REPO/src/drmTMB.so" && "$(receipt_value dll_sha256)" == "$(sha256sum "$REPO/src/drmTMB.so" | awk '{print $1}')" ]] || { echo "Preflight DLL checksum mismatch." >&2; exit 2; }
  [[ "$(receipt_value R_LIBS)" == "$SHARED_RLIB:$BASE_RLIB" ]] || { echo "Preflight library path mismatch." >&2; exit 2; }
  [[ "$(receipt_value R_version)" == "$(R --version | head -1)" && "$(receipt_value gcc_version)" == "$(gcc --version | head -1)" && "$(receipt_value TMB_version)" == "$(Rscript --no-init-file -e 'cat(as.character(packageVersion("TMB")))')" ]] || { echo "Preflight R/compiler/TMB environment mismatch." >&2; exit 2; }
  [[ "$(receipt_value module_list_sha256)" == "$(sha256sum "$PREFLIGHT_DIR/module-list.txt" | awk '{print $1}')" && "$(receipt_value session_info_sha256)" == "$(sha256sum "$PREFLIGHT_DIR/sessionInfo.txt" | awk '{print $1}')" ]] || { echo "Preflight module/session checksum mismatch." >&2; exit 2; }
}

# Run once with sbatch --array=1 and DRMTMB_ARC4C_PREFLIGHT_ONLY=true.  It is
# the only Arc 4c worker permitted to compile; regular shards always reuse it.
if [[ "${DRMTMB_ARC4C_PREFLIGHT_ONLY:-false}" == "true" ]]; then
  write_preflight_receipt
  exit 0
fi
verify_preflight_receipt

MANIFEST="${DRMTMB_ARC4C_MANIFEST:?DRMTMB_ARC4C_MANIFEST must be a generated full manifest}"
TASK_INDEX="${SLURM_ARRAY_TASK_ID:?SLURM_ARRAY_TASK_ID not set}"
RUNNER="${DRMTMB_ARC4C_RUNNER:-tools/run-arc4c-mu-slope-coverage.R}"

ROW=$(awk -F '\t' -v n="$TASK_INDEX" 'NR == n + 1 { print; exit }' "$MANIFEST")
[[ -n "$ROW" ]] || { echo "No manifest row for dense array index $TASK_INDEX." >&2; exit 2; }
IFS=$'\t' read -r ARRAY_INDEX LOGICAL_TASK_ID CELL_ID FAMILY M SHARD REPLICATE_START REPLICATE_END <<< "$ROW"
[[ "$ARRAY_INDEX" == "$TASK_INDEX" ]] || { echo "Manifest array-index mismatch." >&2; exit 2; }

# The retained shard filenames encode cell/M/shard and are globally unique; keep
# them flat because the fail-closed aggregator deliberately scans one directory.
PROJECT_TASK_DIR="$RUN_ROOT/shards"
TASK_WORK_ROOT="${SLURM_TMPDIR:-$RUN_ROOT/work/${SLURM_JOB_ID}_${TASK_INDEX}}"
TASK_OUTPUT_DIR="$TASK_WORK_ROOT/results"
mkdir -p "$TASK_WORK_ROOT" "$TASK_OUTPUT_DIR" "$PROJECT_TASK_DIR"
export R_LIBS="$SHARED_RLIB:$BASE_RLIB" DRMTMB_RLIB="$SHARED_RLIB" DRMTMB_ARC4C_REPO="$REPO" DRMTMB_TASK_REPO="$REPO"
SHARD_BASENAME=$(printf 'arc4c-%s-M%02d-shard%03d.tsv' "$CELL_ID" "$M" "$SHARD")
if [[ -f "$PROJECT_TASK_DIR/$SHARD_BASENAME" || -f "$PROJECT_TASK_DIR/$SHARD_BASENAME.md5" ]]; then
  # Stage either side independently.  The runner owns checksum validation and
  # quarantine, including an interrupted publication with only TSV or MD5.
  [[ -f "$PROJECT_TASK_DIR/$SHARD_BASENAME" ]] && cp "$PROJECT_TASK_DIR/$SHARD_BASENAME" "$TASK_OUTPUT_DIR/"
  [[ -f "$PROJECT_TASK_DIR/$SHARD_BASENAME.md5" ]] && cp "$PROJECT_TASK_DIR/$SHARD_BASENAME.md5" "$TASK_OUTPUT_DIR/"
fi

copy_back() {
  rsync -a "$TASK_OUTPUT_DIR/" "$PROJECT_TASK_DIR/" || return 1
  cp "$MANIFEST" "$PROJECT_TASK_DIR/manifest-logical_${LOGICAL_TASK_ID}.tsv" || return 1
}
on_exit() {
  status=$?
  set +e
  copy_back
  copy_status=$?
  if [[ $status -eq 0 && $copy_status -ne 0 ]]; then status=$copy_status; fi
  exit "$status"
}
trap on_exit EXIT

{
  echo "logical_task_id=$LOGICAL_TASK_ID"; echo "cell_id=$CELL_ID"; echo "family=$FAMILY"; echo "M=$M"; echo "shard=$SHARD"
  echo "replicate_start=$REPLICATE_START"; echo "replicate_end=$REPLICATE_END"; echo "merge_sha=$MERGE_SHA"
  echo "preflight_receipt=$RECEIPT"; echo "preflight_receipt_sha256=$(awk '{print $1}' "$PREFLIGHT_DIR/receipt.tsv.sha256")"
  echo "hostname=${SLURMD_NODENAME:-$(hostname)}"; echo "slurm_job_id=${SLURM_JOB_ID}"
  echo "slurm_array_job_id=${SLURM_ARRAY_JOB_ID:-$SLURM_JOB_ID}"; echo "slurm_array_task_id=${SLURM_ARRAY_TASK_ID}"
} > "$TASK_OUTPUT_DIR/provenance-logical_${LOGICAL_TASK_ID}.txt"
env | sort > "$TASK_OUTPUT_DIR/environment-logical_${LOGICAL_TASK_ID}.txt"

# This is executed inside a Slurm allocation, never on a login node.  Curie's
# runner owns the fit and persists one raw row per attempted replicate.
set +e
(
  cd "$REPO"
  Rscript --no-init-file "$RUNNER" \
    --mode=full --cell-id="$CELL_ID" --family="$FAMILY" --M="$M" \
    --replicate-start="$REPLICATE_START" --replicate-end="$REPLICATE_END" --out-dir="$TASK_OUTPUT_DIR"
) > "$TASK_OUTPUT_DIR/runner-logical_${LOGICAL_TASK_ID}.stdout" 2> "$TASK_OUTPUT_DIR/runner-logical_${LOGICAL_TASK_ID}.stderr"
RUN_STATUS=$?
set -e
printf 'runner_exit_code=%s\n' "$RUN_STATUS" >> "$TASK_OUTPUT_DIR/provenance-logical_${LOGICAL_TASK_ID}.txt"
exit "$RUN_STATUS"
