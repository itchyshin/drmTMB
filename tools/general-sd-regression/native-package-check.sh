#!/usr/bin/env bash
# Bounded static package check for one exact built source tarball on Totoro.
set -euo pipefail
if [[ $# -ne 1 ]]; then
  echo "usage: native-package-check.sh JOB_DIR" >&2
  exit 2
fi
job="$1"
tarball="$job/built-package.tar.gz"
[[ -f "$tarball" ]]
[[ ! -e "$job/library" ]]
mkdir "$job/library"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
export MAKEFLAGS=-j2
export _R_CHECK_FORCE_SUGGESTS_=false
printf '%s\n' "OPENBLAS_NUM_THREADS=1" "OMP_NUM_THREADS=1" "MKL_NUM_THREADS=1" \
  "MAKEFLAGS=-j2" "_R_CHECK_FORCE_SUGGESTS_=false" > "$job/runtime.env"
date -u > "$job/started-utc.txt"
set +e
R CMD check --no-tests --no-examples --no-vignettes --no-manual \
  --library="$job/library" "$tarball" > "$job/check.log" 2>&1
rc=$?
set -e
printf '%s\n' "$rc" > "$job/check-exit-status.txt"
date -u > "$job/completed-utc.txt"
exit "$rc"
