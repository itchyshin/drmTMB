#!/usr/bin/env bash
# Approved scalar A1 ML-versus-REML attribution campaign for Totoro only.
# Run after installing the pinned drmTMB tarball into $HOME/drm_work/a1_ml_reml_lib.

set -euo pipefail

export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
: "${DRMTMB_TARBALL_SHA256:?Set the SHA-256 of the installed drmTMB tarball.}"

work_dir="${A1_ML_REML_WORK_DIR:-$HOME/drm_work/a1_ml_reml_20260726}"
run_id="a1_ml_reml_full_20260726"
out_dir="$work_dir/results_${run_id}"
log_dir="$work_dir/logs_${run_id}"
lock_dir="$work_dir/.${run_id}.lock"
lib_dir="$work_dir/a1_ml_reml_lib"
runner="$work_dir/a1_ml_reml_smoke.R"
analyser="$work_dir/analyse_a1_ml_reml_smoke.R"
helper="$work_dir/a1_ml_reml_common.R"
oracle="$work_dir/a1_ml_reml_oracle.R"
workers=100
expected_runner_sha="cb4ff4020be5ade71c500c5fb85a3dab190ec0ece3a53a318393306814010076"
expected_analyser_sha="b84f717b276f17d5af3ebef7686417b6d3b11f995c84b2f38b98a988cbe456c2"
expected_helper_sha="f23ee237b00c93f4b5ac20355679b86384278f051ee05dd4e980739eaf2f7178"
expected_oracle_sha="557cfcab8edec40f9a0f1c3f0b2229369d50a5bcd99f71387013672a8fb9fafc"
launcher_sha="$(sha256sum "$0" | awk '{print $1}')"

(( workers <= 100 )) || { printf 'Worker ceiling exceeds 100.\n' >&2; exit 1; }
for path in "$runner" "$analyser" "$helper" "$oracle"; do
  [[ -f "$path" ]] || { printf 'Missing required source: %s\n' "$path" >&2; exit 1; }
done
[[ "$(sha256sum "$runner" | awk '{print $1}')" == "$expected_runner_sha" ]] || { printf 'Runner hash mismatch.\n' >&2; exit 1; }
[[ "$(sha256sum "$analyser" | awk '{print $1}')" == "$expected_analyser_sha" ]] || { printf 'Analyser hash mismatch.\n' >&2; exit 1; }
[[ "$(sha256sum "$helper" | awk '{print $1}')" == "$expected_helper_sha" ]] || { printf 'Helper hash mismatch.\n' >&2; exit 1; }
[[ "$(sha256sum "$oracle" | awk '{print $1}')" == "$expected_oracle_sha" ]] || { printf 'Oracle hash mismatch.\n' >&2; exit 1; }
[[ -d "$lib_dir" ]] || { printf 'Missing isolated package library: %s\n' "$lib_dir" >&2; exit 1; }
[[ ! -e "$out_dir" && ! -e "$log_dir" ]] || { printf 'Run output already exists; refusing to mix attempts.\n' >&2; exit 1; }
if ! mkdir "$lock_dir"; then
  printf 'Campaign lock exists at %s; refusing a second launcher.\n' "$lock_dir" >&2
  exit 1
fi
cleanup() { rmdir "$lock_dir"; }
trap cleanup EXIT

R_LIBS="$lib_dir" Rscript --vanilla -e '
  library(drmTMB)
  stopifnot(identical(as.character(packageVersion("drmTMB")), "0.6.0"))
  stopifnot("profile_engine" %in% names(formals(getS3method("confint", "drmTMB"))))
  cat("drmTMB", as.character(packageVersion("drmTMB")), "profile interface verified\\n")
'

mkdir -p "$out_dir" "$log_dir"
manifest="$out_dir/campaign-manifest.txt"
{
  printf 'run_kind=scalar_a1_ml_reml_attribution\n'
  printf 'package_tarball_sha256=%s\n' "$DRMTMB_TARBALL_SHA256"
  printf 'runner_sha256=%s\n' "$expected_runner_sha"
  printf 'analyser_sha256=%s\n' "$expected_analyser_sha"
  printf 'helper_sha256=%s\n' "$expected_helper_sha"
  printf 'oracle_sha256=%s\n' "$expected_oracle_sha"
  printf 'launcher_sha256=%s\n' "$launcher_sha"
  printf 'outer_attempts_per_cell=1000\nworkers=%s\n' "$workers"
  printf 'cells=g10_n10_sd05,g25_n10_sd05,g50_n10_sd05\n'
  date -u '+started_utc=%Y-%m-%dT%H:%M:%SZ'
} > "$manifest"

launch_one() {
  local cell="$1" offset="$2"
  R_LIBS="$lib_dir" DRMTMB_TARBALL_SHA256="$DRMTMB_TARBALL_SHA256" \
    Rscript --vanilla "$runner" "$cell" 10 "$out_dir" "$offset" \
    > "$log_dir/c${cell}_o$(printf '%04d' "$offset").log" 2>&1
}
export -f launch_one
export lib_dir runner out_dir log_dir DRMTMB_TARBALL_SHA256

{
  for cell in 1 2 3; do
    for offset in $(seq 0 10 990); do printf '%s %s\n' "$cell" "$offset"; done
  done
} | xargs -P "$workers" -n 2 bash -c 'launch_one "$@"' _

R_LIBS="$lib_dir" Rscript --vanilla "$analyser" "$out_dir" 1000
date -u '+completed_utc=%Y-%m-%dT%H:%M:%SZ' >> "$manifest"
printf 'Campaign completed and key-grid validation passed: %s\n' "$out_dir"
