#!/bin/sh
set -eu

approval="${DRMTMB_Q2_TRANCHE129_EXECUTION_APPROVED:-}"
if [ "$approval" != "rose_fisher_gauss_noether_grace" ]; then
  echo "Refusing T129 execution: set DRMTMB_Q2_TRANCHE129_EXECUTION_APPROVED=rose_fisher_gauss_noether_grace after checkpoint and blocking-review approval." >&2
  exit 42
fi

host_label="${DRMTMB_Q2_TRANCHE129_HOST_LABEL:-}"
if [ -z "$host_label" ]; then
  echo "Refusing T129 execution: DRMTMB_Q2_TRANCHE129_HOST_LABEL must name the true host/run root provenance." >&2
  exit 43
fi

if [ ! -f DESCRIPTION ] || ! grep -q "^Package: drmTMB$" DESCRIPTION; then
  echo "Refusing T129 execution: run from the drmTMB repository root." >&2
  exit 44
fi

runner="tools/run-structured-re-q2-slope-coverage-grid.R"
if [ ! -f "$runner" ]; then
  echo "Refusing T129 execution: missing $runner." >&2
  exit 45
fi

r_bin="${R_BIN:-Rscript}"
out_root="${DRMTMB_Q2_TRANCHE129_OUT_ROOT:-docs/dev-log/simulation-artifacts/2026-07-03-q2-tranche129-spatial-g32-executable-contract/approved-run}"

export R_PROFILE_USER="${R_PROFILE_USER:-/dev/null}"
export NOT_CRAN="${NOT_CRAN:-true}"
export OMP_NUM_THREADS="${OMP_NUM_THREADS:-1}"
export OPENBLAS_NUM_THREADS="${OPENBLAS_NUM_THREADS:-1}"
export MKL_NUM_THREADS="${MKL_NUM_THREADS:-1}"
export TMB_NTHREADS="${TMB_NTHREADS:-1}"
export GSWEEP_N_GROUPS=32
export DRMTMB_Q2_TRANCHE129_HOST_LABEL="$host_label"

for spec in \
  "4 932001 spatial_mu1_x" \
  "5 932021 spatial_mu2_x" \
  "6 932041 spatial_cor_mu1_mu2_x"
do
  set -- $spec
  shard="$1"
  seed_start="$2"
  target_token="$3"
  shard_dir="$out_root/shard_${shard}_${target_token}"
  mkdir -p "$shard_dir"
  "$r_bin" --no-init-file "$runner" \
    --shard="$shard" \
    --n_rep=20 \
    --seed_start="$seed_start" \
    --n_each=20 \
    --bootstrap=0 \
    --out_dir="$shard_dir"
done
