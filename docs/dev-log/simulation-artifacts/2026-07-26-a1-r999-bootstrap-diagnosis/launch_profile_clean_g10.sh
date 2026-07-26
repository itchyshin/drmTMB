#!/usr/bin/env bash
# Clean, cap-compliant provenance rerun for the affected scalar-A1 g=10 cell.
# Run only after the explicit authorisation recorded in the companion receipt.

set -euo pipefail
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
export A1_REQUIRE_PROVENANCE=1
export DRMTMB_COMMIT="37091153b4bdd55a48a6de758d893d75eb9888dc"
: "${DRMTMB_TARBALL_SHA256:?Set the SHA-256 of the tarball installed for this clean rerun.}"

work_dir="$HOME/drm_work"
run_id="a1_profile_clean_g10_20260726"
out_dir="$work_dir/results_${run_id}"
log_dir="$work_dir/logs_${run_id}"
lock_dir="$work_dir/.${run_id}.lock"
runner="$work_dir/profile_vs_bootstrap.R"
helper="$work_dir/a1_profile_common.R"
expected_runner_sha="7dc63ca348c5df42519aa30e58066a8387b3bdfa9f62b2a8d2d4fd69aaf45cfc"
expected_helper_sha="727b6e3b9582b77bb6f92fc0dddc42794d2b48537339299d28c3e4d50255cb9b"
launcher_sha="$(sha256sum "$0" | awk '{print $1}')"

for path in "$runner" "$helper"; do
  [[ -f "$path" ]] || { printf 'Missing required source: %s\n' "$path" >&2; exit 1; }
done
[[ "$(sha256sum "$runner" | awk '{print $1}')" == "$expected_runner_sha" ]] || {
  printf 'Runner hash mismatch; refusing clean rerun.\n' >&2; exit 1;
}
[[ "$(sha256sum "$helper" | awk '{print $1}')" == "$expected_helper_sha" ]] || {
  printf 'Helper hash mismatch; refusing clean rerun.\n' >&2; exit 1;
}

if ! mkdir "$lock_dir"; then
  printf 'Clean rerun lock exists at %s; refusing a second launcher.\n' "$lock_dir" >&2
  exit 1
fi
cleanup() { rmdir "$lock_dir"; }
trap cleanup EXIT

manifest="$out_dir/campaign-manifest.txt"
if [[ -e "$manifest" ]]; then
  printf 'Manifest already exists at %s; refusing to mix a rerun.\n' "$manifest" >&2
  exit 1
fi
mkdir -p "$out_dir" "$log_dir"

Rscript -e '
  .libPaths(c(file.path(Sys.getenv("HOME"), "drm_work", "lib"), .libPaths()))
  library(drmTMB)
  stopifnot(identical(as.character(packageVersion("drmTMB")), "0.6.0"))
  stopifnot("refit_control" %in% names(formals(getS3method("confint", "drmTMB"))))
  cat("drmTMB", as.character(packageVersion("drmTMB")), "profile interface verified\n")
'

{
  printf 'run_kind=clean_g10_provenance_rerun\n'
  printf 'package_commit=%s\n' "$DRMTMB_COMMIT"
  printf 'package_tarball_sha256=%s\n' "$DRMTMB_TARBALL_SHA256"
  printf 'runner_sha256=%s\n' "$expected_runner_sha"
  printf 'helper_sha256=%s\n' "$expected_helper_sha"
  printf 'launcher_sha256=%s\n' "$launcher_sha"
  printf 'R_boot=999\nouter_attempts=1000\nworkers=100\ncell_id=g10_n10_sd05\n'
  date -u '+started_utc=%Y-%m-%dT%H:%M:%SZ'
} > "$manifest"

launch_one() {
  local offset="$1" shard
  shard="o$(printf '%04d' "$offset")"
  Rscript "$runner" 1 10 999 "$out_dir" "$offset" "$shard" \
    > "$log_dir/${shard}.log" 2>&1
}
export -f launch_one
export out_dir log_dir runner DRMTMB_COMMIT A1_REQUIRE_PROVENANCE

seq 0 10 990 | xargs -P 100 -n 1 bash -c 'launch_one "$@"' _

date -u '+completed_utc=%Y-%m-%dT%H:%M:%SZ' >> "$manifest"
printf 'Clean g=10 rerun completed; analyse with analyse_profile_clean_g10.R %s\n' "$out_dir"
