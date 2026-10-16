#!/usr/bin/env bash
# Run one t8 case with hard timeouts. Usage: run_case.sh <case_id> [timeout_s]
set -u
ID="${1:?case id}"
TO="${2:-180}"
export T8_ROOT="${T8_ROOT:-/workspace/sweep-oct16/t8}"
export R_LIBS_USER="${R_LIBS_USER:-/home/ubuntu/R/library}"
LOGDIR="$T8_ROOT/logs"
mkdir -p "$LOGDIR" "$T8_ROOT/fits/$ID"
echo "===== $ID  timeout=${TO}s  $(date -u +%FT%TZ) =====" | tee -a "$LOGDIR/${ID}.log"

echo "--- R drmTMB + ref ---" | tee -a "$LOGDIR/${ID}.log"
timeout --signal=KILL "$TO" Rscript "$T8_ROOT/prepare_and_fit_r.R" "$ID" \
  >>"$LOGDIR/${ID}.log" 2>&1
RSTAT=$?
echo "R_EXIT=$RSTAT" | tee -a "$LOGDIR/${ID}.log"

echo "--- Julia DRModels.jl ---" | tee -a "$LOGDIR/${ID}.log"
timeout --signal=KILL "$TO" julia --project=/tmp/DRModels.jl "$T8_ROOT/fit_jl.jl" "$ID" \
  >>"$LOGDIR/${ID}.log" 2>&1
JSTAT=$?
echo "JL_EXIT=$JSTAT" | tee -a "$LOGDIR/${ID}.log"

timeout --signal=KILL 60 Rscript "$T8_ROOT/compare_case.R" "$ID" \
  >>"$LOGDIR/${ID}.log" 2>&1
CSTAT=$?
echo "COMPARE_EXIT=$CSTAT R_EXIT=$RSTAT JL_EXIT=$JSTAT" | tee -a "$LOGDIR/${ID}.log"
# 124 = timeout
exit 0
