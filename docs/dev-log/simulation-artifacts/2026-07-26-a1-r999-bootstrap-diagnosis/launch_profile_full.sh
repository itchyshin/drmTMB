#!/usr/bin/env bash
# Approved full scalar-A1 profile-versus-bootstrap campaign.
#
# Prerequisites on Totoro:
#   1. install drmTMB from the source tarball built at the recorded commit into
#      ~/drm_work/lib;
#   2. copy this script, profile_vs_bootstrap.R, and a1_profile_common.R into
#      ~/drm_work;
#   3. run from ~/drm_work.  It launches 300 deterministic ten-attempt shards
#      with at most 100 concurrent R processes.

set -euo pipefail
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
export A1_REQUIRE_PROVENANCE=1
export DRMTMB_COMMIT="37091153b4bdd55a48a6de758d893d75eb9888dc"

work_dir="$HOME/drm_work"
out_dir="$work_dir/results_a1_profile_full_20260726"
log_dir="$work_dir/logs_a1_profile_full_20260726"
runner="$work_dir/profile_vs_bootstrap.R"
helper="$work_dir/a1_profile_common.R"
expected_runner_sha="7dc63ca348c5df42519aa30e58066a8387b3bdfa9f62b2a8d2d4fd69aaf45cfc"
expected_helper_sha="083949bf1868d32a771b7124443f05f44a354b70598cd1703b2c2007a7731435"
launcher_sha="$(sha256sum "$0" | awk '{print $1}')"

for path in "$runner" "$helper"; do
  [[ -f "$path" ]] || { printf 'Missing required source: %s\n' "$path" >&2; exit 1; }
done
[[ "$(sha256sum "$runner" | awk '{print $1}')" == "$expected_runner_sha" ]] || {
  printf 'Runner hash mismatch; refusing full campaign.\n' >&2; exit 1;
}
[[ "$(sha256sum "$helper" | awk '{print $1}')" == "$expected_helper_sha" ]] || {
  printf 'Helper hash mismatch; refusing full campaign.\n' >&2; exit 1;
}

Rscript -e '
  .libPaths(c(file.path(Sys.getenv("HOME"), "drm_work", "lib"), .libPaths()))
  library(drmTMB)
  stopifnot(identical(as.character(packageVersion("drmTMB")), "0.6.0"))
  stopifnot("refit_control" %in% names(formals(getS3method("confint", "drmTMB"))))
  cat("drmTMB", as.character(packageVersion("drmTMB")), "profile interface verified\n")
'

manifest="$out_dir/campaign-manifest.txt"
if [[ -e "$manifest" ]]; then
  printf 'Campaign manifest already exists at %s; refusing to overwrite or mix attempts.\n' "$manifest" >&2
  exit 1
fi
mkdir -p "$out_dir" "$log_dir"
{
  printf 'package_commit=%s\n' "$DRMTMB_COMMIT"
  printf 'runner_sha256=%s\n' "$expected_runner_sha"
  printf 'helper_sha256=%s\n' "$expected_helper_sha"
  printf 'launcher_sha256=%s\n' "$launcher_sha"
  printf 'R_boot=999\nouter_attempts_per_cell=1000\nworkers=100\n'
  date -u '+started_utc=%Y-%m-%dT%H:%M:%SZ'
} > "$manifest"

launch_one() {
  local cell="$1" offset="$2" shard
  shard="o$(printf '%04d' "$offset")"
  Rscript "$runner" "$cell" 10 999 "$out_dir" "$offset" "$shard" \
    > "$log_dir/c${cell}_${shard}.log" 2>&1
}
export -f launch_one
export out_dir log_dir runner DRMTMB_COMMIT A1_REQUIRE_PROVENANCE

{
  for cell in 1 2 3; do
    for offset in $(seq 0 10 990); do printf '%s %s\n' "$cell" "$offset"; done
  done
} | xargs -P 100 -n 2 bash -c 'launch_one "$@"' _

date -u '+completed_utc=%Y-%m-%dT%H:%M:%SZ' >> "$manifest"
printf 'Full campaign completed; analyse with analyse_profile_vs_bootstrap.R %s\n' "$out_dir"
