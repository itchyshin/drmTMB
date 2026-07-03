#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bash tools/run-q4-location-relmat-pregrid-totoro.sh [--execute] [--shards=13,14,15,16] [--attempt-temp-install]

Host-side Totoro wrapper for the relmat q4 location SR150 pregrid. The default
is dry-run: it prints the exact Rscript commands and exits without fitting.

Execution is fail-closed and requires:
  --execute
  DRMTMB_Q4LOC_EXECUTION_APPROVED=rose_fisher_grace

Expected environment:
  DRMTMB_REPO             repository root on Totoro (default: current directory)
  DRMTMB_Q4LOC_RUN_ROOT   output root for logs and shard directories
  DRMTMB_SOURCE_SHA       source SHA copied into provenance, or derived from git
  DRMTMB_SOURCE_DIRTY     dirty/clean copied into provenance, or derived from git
  DRMTMB_HOST_LABEL       host label (default: totoro_q4_t8_relmat_pregrid)
  DRMTMB_Q4LOC_ATTEMPT_TEMP_INSTALL=true
                           optional env alternative to --attempt-temp-install
USAGE
}

execute=false
shards="13,14,15,16"
attempt_temp_install="${DRMTMB_Q4LOC_ATTEMPT_TEMP_INSTALL:-false}"
for arg in "$@"; do
  case "$arg" in
    --execute)
      execute=true
      ;;
    --dry-run)
      execute=false
      ;;
    --shards=*)
      shards="${arg#--shards=}"
      ;;
    --attempt-temp-install)
      attempt_temp_install=true
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

repo="${DRMTMB_REPO:-$(pwd)}"
cd "$repo"

source_sha="${DRMTMB_SOURCE_SHA:-$(git rev-parse --short HEAD 2>/dev/null || echo unknown)}"
if [[ -n "${DRMTMB_SOURCE_DIRTY:-}" ]]; then
  source_dirty="$DRMTMB_SOURCE_DIRTY"
elif [[ -n "$(git status --short 2>/dev/null || true)" ]]; then
  source_dirty="dirty"
else
  source_dirty="clean"
fi
host_label="${DRMTMB_HOST_LABEL:-totoro_q4_t8_relmat_pregrid}"
run_root="${DRMTMB_Q4LOC_RUN_ROOT:-/home/snakagaw/drmtmb-qseries/20260701-tranche8-q4-relmat-sr150-${source_sha}/totoro}"
n_rep="${DRMTMB_Q4LOC_N_REP:-150}"
n_each="${DRMTMB_Q4LOC_N_EACH:-20}"
bootstrap="${DRMTMB_Q4LOC_BOOTSTRAP:-0}"

seed_for_shard() {
  local shard="$1"
  echo $((980000 + (shard - 13) * 1000))
}

token_for_shard() {
  case "$1" in
    13) echo "shard-13-relmat-mu1-intercept" ;;
    14) echo "shard-14-relmat-mu1-x" ;;
    15) echo "shard-15-relmat-mu2-intercept" ;;
    16) echo "shard-16-relmat-mu2-x" ;;
    *)
      echo "Unsupported relmat q4 shard: $1" >&2
      exit 2
      ;;
  esac
}

IFS=',' read -r -a shard_array <<< "$shards"
for shard in "${shard_array[@]}"; do
  case "$shard" in
    13|14|15|16) ;;
    *)
      echo "Only relmat q4 location shards 13,14,15,16 are allowed; got $shard" >&2
      exit 2
      ;;
  esac
done

mkdir -p "$run_root/logs"

echo -e "source_sha\tsource_dirty\thost_label\trun_root"
echo -e "${source_sha}\t${source_dirty}\t${host_label}\t${run_root}"

if [[ "$execute" == true && "${DRMTMB_Q4LOC_EXECUTION_APPROVED:-}" != "rose_fisher_grace" ]]; then
  echo "Refusing execution: set DRMTMB_Q4LOC_EXECUTION_APPROVED=rose_fisher_grace after explicit Rose/Fisher/Grace approval." >&2
  exit 2
fi

if [[ "$execute" == true ]]; then
  {
    echo -e "source_sha\tsource_dirty\thost_label\trun_root"
    echo -e "${source_sha}\t${source_dirty}\t${host_label}\t${run_root}"
  } > "$run_root/source-provenance.tsv"
  {
    hostname
    date -Iseconds
    Rscript --version
  } > "$run_root/host-provenance.txt" 2>&1
  R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'sessionInfo()' \
    > "$run_root/sessionInfo.txt" 2>&1
fi

for shard in "${shard_array[@]}"; do
  seed_start="$(seed_for_shard "$shard")"
  token="$(token_for_shard "$shard")"
  out_dir="$run_root/$token"
  log_path="$run_root/logs/${token}.log"
  cmd=(
    env
    R_PROFILE_USER=/dev/null
    NOT_CRAN=true
    OMP_NUM_THREADS=1
    OPENBLAS_NUM_THREADS=1
    MKL_NUM_THREADS=1
    TMB_NTHREADS=1
    DRMTMB_SOURCE_SHA="$source_sha"
    DRMTMB_SOURCE_DIRTY="$source_dirty"
    DRMTMB_HOST_LABEL="$host_label"
    Rscript --no-init-file
    tools/run-structured-re-q4-location-coverage-grid.R
    "--shard=$shard"
    "--n_rep=$n_rep"
    "--seed_start=$seed_start"
    "--n_each=$n_each"
    "--bootstrap=$bootstrap"
    "--out_dir=$out_dir"
  )
  if [[ "$attempt_temp_install" == true ]]; then
    cmd+=(--attempt-temp-install)
  fi
  printf '[totoro-q4-relmat] '
  printf '%q ' "${cmd[@]}"
  printf '> %q 2>&1\n' "$log_path"
  if [[ "$execute" == true ]]; then
    mkdir -p "$out_dir"
    "${cmd[@]}" > "$log_path" 2>&1
  fi
done

if [[ "$execute" != true ]]; then
  echo "[totoro-q4-relmat] dry-run only; no coverage job executed."
fi
