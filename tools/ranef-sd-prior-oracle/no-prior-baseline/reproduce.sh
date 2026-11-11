#!/usr/bin/env bash
set -euo pipefail
if [ "$#" -ne 2 ]; then
  printf 'Usage: %s /path/to/drmTMB-git-repo /path/to/new-run-directory\n' "$0" >&2
  exit 2
fi
repo=$(cd "$1" && pwd -P)
run=$2
case "$run" in /*) ;; *) echo 'Run directory must be an absolute path.' >&2; exit 2;; esac
if [ -e "$run" ]; then
  echo 'Run directory already exists; choose a new path.' >&2
  exit 2
fi
here=$(cd "$(dirname "$0")" && pwd -P)
for tool in git tar python3 Rscript shasum; do command -v "$tool" >/dev/null || { echo "Missing tool: $tool" >&2; exit 2; }; done
git -C "$repo" rev-parse --git-dir >/dev/null
(cd "$here" && shasum -a 256 -c SHA256SUMS)
mkdir "$run"
mkdir "$run/base" "$run/candidate"
git -C "$repo" archive bfa7acf5bb85e298fe675c5713c34fa208abd860 | tar -xf - -C "$run/base"
git -C "$repo" archive bcb6755861494aa8bfdc692067b8c861e97c06ce | tar -xf - -C "$run/candidate"
cp "$here/data.csv" "$run/data.csv"
python3 "$here/verify_source.py" "$repo" "$run" --output "$run/source-before.json" > "$run/source-before.log"
export OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1
Rscript "$here/run_case.R" base "$run" > "$run/base.log" 2>&1
Rscript "$here/run_case.R" candidate "$run" > "$run/candidate.log" 2>&1
Rscript "$here/compare.R" "$run" > "$run/compare.log" 2>&1
python3 "$here/verify_source.py" "$repo" "$run" --output "$run/source-after.json" > "$run/source-after.log"
cmp "$run/source-before.json" "$run/source-after.json"
cat "$run/compare.log"
