#!/usr/bin/env bash
# Run one t4 cell through both engines with a hard GNU timeout.
# Usage: run_cell.sh <cell> [timeout_sec_per_engine]
# A hang is recorded as TIMEOUT (the fitter resumes skipped rows; leftover
# datasets after a kill are appended as TIMEOUT by this wrapper).
set -u
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
T="$ROOT/sweep-oct16/t4"
DRMODELS="${DRMODELS:-/home/ubuntu/src/DRModels.jl}"
JULIA="${JULIA:-julia}"
export R_LIBS_USER="${R_LIBS_USER:-/home/ubuntu/R/library}"
export OMP_NUM_THREADS=1 MKL_NUM_THREADS=1
CELL="${1:?cell name}"
TIMEOUT="${2:-900}"   # 15 min per engine per cell (50 fits)
mkdir -p "$T/results" "$T/logs"

append_timeout_rows() {
  # Args: engine csv path. Any index rows for CELL missing from the csv
  # become TIMEOUT rows so a kill is a finding, not a stall.
  local engine="$1" csv="$2"
  python3 - "$engine" "$csv" "$T/data/index.csv" "$CELL" <<'PY'
import csv, sys, os
engine, csv_path, index_path, cell = sys.argv[1:5]
idx = [r for r in csv.DictReader(open(index_path)) if r["cell"] == cell]
done = set()
fieldnames = None
if os.path.exists(csv_path) and os.path.getsize(csv_path) > 0:
    with open(csv_path, newline="") as f:
        r = csv.DictReader(f)
        fieldnames = r.fieldnames
        for row in r:
            done.add(row["file"])
if fieldnames is None:
    sys.exit(0)
missing = [r for r in idx if r["file"] not in done]
if not missing:
    sys.exit(0)
with open(csv_path, "a", newline="") as f:
    w = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
    for r in missing:
        row = {k: "" for k in fieldnames}
        row.update({k: r.get(k, "") for k in r})
        row["fitted"] = "FALSE"
        row["timeout"] = "TRUE"
        row["error"] = "TIMEOUT (cell-level GNU timeout or kill)"
        row["converged"] = "FALSE"
        w.writerow(row)
    print(f"appended {len(missing)} TIMEOUT rows to {csv_path}", file=sys.stderr)
PY
}

echo "[$(date -Is)] R cell=$CELL timeout=${TIMEOUT}s"
timeout --kill-after=10 "$TIMEOUT" \
  Rscript "$T/t4_fit_drmTMB.R" "$T/data" "$T/results/fits_drmTMB" "$CELL" 60 \
  > "$T/logs/fit_R_${CELL}.log" 2>&1
rc_r=$?
if [ "$rc_r" -eq 124 ] || [ "$rc_r" -eq 137 ]; then
  echo "[$(date -Is)] R TIMEOUT cell=$CELL rc=$rc_r"
  append_timeout_rows drmTMB "$T/results/fits_drmTMB.csv"
fi

echo "[$(date -Is)] Julia cell=$CELL timeout=${TIMEOUT}s"
timeout --kill-after=10 "$TIMEOUT" \
  "$JULIA" --project="$DRMODELS" "$T/t4_fit_DRModels.jl" "$T/data" "$T/results/fits_DRModels.csv" "$CELL" \
  > "$T/logs/fit_J_${CELL}.log" 2>&1
rc_j=$?
if [ "$rc_j" -eq 124 ] || [ "$rc_j" -eq 137 ]; then
  echo "[$(date -Is)] Julia TIMEOUT cell=$CELL rc=$rc_j"
  append_timeout_rows DRModels "$T/results/fits_DRModels.csv"
fi

echo "[$(date -Is)] done cell=$CELL R_rc=$rc_r J_rc=$rc_j"
exit 0
