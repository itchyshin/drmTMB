#!/bin/bash
# B1 worker template.  Submit only after the local smoke, a compute-node
# preflight, and a frozen source/manifest receipt.  The submission command
# supplies --array and its benchmarked throttle (never above 1000).
#SBATCH --job-name=drmTMBB1
#SBATCH --account=def-snakagaw_cpu
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --time=0-02:00:00
#SBATCH --output=logs/%x-%A_%a.out

set -euo pipefail
[[ -n "${SLURM_JOB_ID:-}" ]] || { echo "Refusing login-node execution." >&2; exit 2; }
module load StdEnv/2023 gcc/12.3 r/4.4.0
export R_PROFILE_USER=/dev/null NOT_CRAN=true
export OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 FLEXIBLAS_NUM_THREADS=1 BLIS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1

RUN_ROOT="${DRMTMB_B1_RUN_ROOT:?B1 run root under /project is required}"
REPO="${DRMTMB_B1_REPO:?verified clean drmTMB clone is required}"
SOURCE_SHA="${DRMTMB_B1_SOURCE_SHA:?frozen source SHA is required}"
MANIFEST="${DRMTMB_B1_MANIFEST:?partition manifest is required}"
SHARED_RLIB="${DRMTMB_B1_RLIB:?preflight R library is required}"
BASE_RLIB="${DRMTMB_BASE_RLIB:-/project/def-snakagaw/snakagaw/R/x86_64-pc-linux-gnu-library/4.4}"
export R_LIBS="$SHARED_RLIB:$BASE_RLIB"
export DRMTMB_B1_REPO="$REPO"
PREFLIGHT="$RUN_ROOT/preflight/receipt.tsv"

[[ "$(git -C "$REPO" rev-parse HEAD)" == "$SOURCE_SHA" ]] || { echo "Source SHA mismatch." >&2; exit 2; }
[[ -z "$(git -C "$REPO" status --porcelain)" ]] || { echo "Source clone is dirty." >&2; exit 2; }
if [[ "${DRMTMB_B1_PREFLIGHT_ONLY:-false}" == "true" ]]; then
  mkdir -p "$RUN_ROOT/preflight" "$SHARED_RLIB"
  Rscript --no-init-file -e 'pkgload::load_all(Sys.getenv("DRMTMB_B1_REPO"), recompile = TRUE); invisible(TMB::MakeADFun)'
  {
    printf 'key\tvalue\n'
    printf 'source_sha\t%s\nhead_sha\t%s\ntree_sha\t%s\ngit_status\tclean\n' "$SOURCE_SHA" "$(git -C "$REPO" rev-parse HEAD)" "$(git -C "$REPO" rev-parse HEAD^{tree})"
    printf 'R_version\t%s\nTMB_version\t%s\n' "$(R --version | head -1)" "$(Rscript --no-init-file -e 'cat(as.character(packageVersion("TMB")))')"
  } > "$RUN_ROOT/preflight/receipt.tsv"
  sha256sum "$RUN_ROOT/preflight/receipt.tsv" > "$RUN_ROOT/preflight/receipt.tsv.sha256"
  exit 0
fi
[[ -f "$PREFLIGHT" ]] || { echo "Missing compute-node preflight receipt." >&2; exit 2; }
grep -Fqx "$(printf 'source_sha\t%s' "$SOURCE_SHA")" "$PREFLIGHT" || { echo "Receipt/source mismatch." >&2; exit 2; }

TASK_INDEX="${SLURM_ARRAY_TASK_ID:?array task ID is required}"
ROW=$(awk -F '\t' -v n="$TASK_INDEX" 'NR == n + 1 { print; exit }' "$MANIFEST")
[[ -n "$ROW" ]] || { echo "No manifest row for task." >&2; exit 2; }
IFS=$'\t' read -r ARRAY_INDEX LOGICAL_TASK_ID CELL_ID FAMILY DPAR EFFECT ADAPTER ADAPTER_STATUS TARGET RUNG SHARD REP_START REP_END SEED_START SEED_END <<< "$ROW"
[[ "$ARRAY_INDEX" == "$TASK_INDEX" ]] || { echo "Manifest array mismatch." >&2; exit 2; }

SHARDS="$RUN_ROOT/shards"; TASK_ROOT="${SLURM_TMPDIR:-$RUN_ROOT/work/${SLURM_JOB_ID}_${TASK_INDEX}}"; OUT="$TASK_ROOT/results"
mkdir -p "$SHARDS" "$OUT"
OUTFILE=$(printf 'b1-task-%06d.tsv' "$LOGICAL_TASK_ID")
trap 'status=$?; rsync -a "$OUT/" "$SHARDS/" || status=1; exit "$status"' EXIT
{
  echo "source_sha=$SOURCE_SHA"; echo "logical_task_id=$LOGICAL_TASK_ID"; echo "array_task_id=$TASK_INDEX"; echo "hostname=$(hostname)"; echo "manifest_sha256=$(sha256sum "$MANIFEST" | awk '{print $1}')"; echo "preflight_sha256=$(sha256sum "$PREFLIGHT" | awk '{print $1}')"
} > "$OUT/provenance-logical_${LOGICAL_TASK_ID}.txt"

set +e
(cd "$REPO" && Rscript --no-init-file tools/run-b1-breadth-validation.R --manifest="$MANIFEST" --array-index="$TASK_INDEX" --out-dir="$OUT") > "$OUT/runner-logical_${LOGICAL_TASK_ID}.stdout" 2> "$OUT/runner-logical_${LOGICAL_TASK_ID}.stderr"
status=$?
set -e
printf 'runner_exit_code=%s\n' "$status" >> "$OUT/provenance-logical_${LOGICAL_TASK_ID}.txt"
exit "$status"
