#!/usr/bin/env bash
# Run the preregistered MD9b Gaussian recovery campaign on Totoro.
# This launcher owns at most 60 one-core R workers, below the binding 150-core
# shared-server cap. The source snapshot is supplied in DRMTMB_TOTORO_RUN_ROOT/source.

set -euo pipefail

readonly TOTORO_CORE_CAP=150
NWORKERS="${NWORKERS:-60}"
if (( NWORKERS < 1 || NWORKERS > TOTORO_CORE_CAP || NWORKERS > $(nproc) - 4 )); then
  echo "NWORKERS=$NWORKERS exceeds the Totoro ${TOTORO_CORE_CAP}-core cap." >&2
  exit 2
fi

RUN_ROOT="${DRMTMB_TOTORO_RUN_ROOT:?DRMTMB_TOTORO_RUN_ROOT not set}"
SOURCE="$RUN_ROOT/source"
RLIB="$RUN_ROOT/rlib"
RESULTS="$RUN_ROOT/results"
META="$RUN_ROOT/metadata"
LOGS="$RUN_ROOT/logs"
mkdir -p "$RLIB" "$RESULTS" "$META" "$LOGS"

export R_PROFILE_USER=/dev/null
export NOT_CRAN=true
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NTHREADS=1
export R_LIBS="$RLIB:${R_LIBS:-}"

R CMD INSTALL -l "$RLIB" "$SOURCE" > "$LOGS/install.stdout" 2> "$LOGS/install.stderr"

{
  echo "date=$(date -Iseconds)"
  echo "host=$(hostname)"
  echo "nworkers=$NWORKERS"
  echo "core_cap=$TOTORO_CORE_CAP"
  echo "run_root=$RUN_ROOT"
  echo "source=$SOURCE"
  echo "R_LIBS=$R_LIBS"
  R --version | head -1
} > "$META/run-start.txt"

awk 'BEGIN { OFS="\t"; for (cell = 1; cell <= 12; cell++) for (shard = 0; shard < 5; shard++) print cell, shard * 50 + 1, shard * 50 + 50 }' > "$META/jobs.tsv"

run_one() {
  local cell="$1"
  local rep_start="$2"
  local rep_end="$3"
  DRMTMB_RUN_INSTALLED=true Rscript --no-init-file \
    "$SOURCE/tools/run-joint-mi-gaussian-recovery.R" \
    --cell="$cell" --rep-start="$rep_start" --rep-end="$rep_end" \
    --out-dir="$RESULTS" \
    > "$LOGS/cell${cell}_rep${rep_start}-${rep_end}.stdout" \
    2> "$LOGS/cell${cell}_rep${rep_start}-${rep_end}.stderr"
}
export -f run_one
export SOURCE RESULTS LOGS

xargs -r -n 3 -P "$NWORKERS" bash -c 'run_one "$@"' _ < "$META/jobs.tsv"

find "$RESULTS" -maxdepth 1 -name '*.csv' -type f | sort > "$META/result-files.txt"
printf 'finished=%s\n' "$(date -Iseconds)" >> "$META/run-start.txt"
printf 'result_files=%s\n' "$(wc -l < "$META/result-files.txt")" >> "$META/run-start.txt"
