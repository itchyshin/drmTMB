#!/usr/bin/env bash
# Diagnose whether R = 199 percentile-endpoint Monte Carlo error explains the
# A1 marginal-bootstrap RE-SD coverage shortfall.  Run on Totoro from
# ~/drm_work after confirming a1_coverage.R has the recorded SHA-256.
#
# The two cells preserve the original DGP and outer-replicate seeds:
#   c01: 10 groups, 4 observations/group, sd_mu = 0.5
#   c03: 50 groups, 4 observations/group, sd_mu = 0.5
# Each has 1,000 outer fits split into 100 independent ten-fit shards.  The
# only changed design dimension is R_boot: 199 -> 999.

set -euo pipefail
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1

work_dir="$HOME/drm_work"
out_dir="$work_dir/results_r999_subset"
log_dir="$work_dir/logs_r999_subset"
script="$work_dir/a1_coverage.R"
expected_sha="18439f2d90b0cf31a905f401fa0ba4626b41c8415d8f8fab8b12264711abce1b"

actual_sha="$(sha256sum "$script" | awk '{print $1}')"
if [[ "$actual_sha" != "$expected_sha" ]]; then
  printf 'Refusing to run: %s has SHA-256 %s (expected %s)\n' \
    "$script" "$actual_sha" "$expected_sha" >&2
  exit 1
fi

mkdir -p "$out_dir" "$log_dir"

launch_one() {
  local cell="$1"
  local offset="$2"
  local shard
  shard="r999_o$(printf '%04d' "$offset")"
  Rscript "$script" "$cell" 10 999 "$out_dir" "$offset" "$shard" \
    > "$log_dir/c${cell}_${shard}.log" 2>&1
}
export -f launch_one
export out_dir log_dir script

{
  for cell in 1 3; do
    for offset in $(seq 0 10 990); do
      printf '%s %s\n' "$cell" "$offset"
    done
  done
} | xargs -P 200 -n 2 bash -c 'launch_one "$@"' _
