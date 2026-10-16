#!/usr/bin/env bash
# t6 harness: one timed cell at a time. A hang becomes a finding.
set -u
ROOT="$(cd "$(dirname "$0")" && pwd)"
export T6_ROOT="$ROOT"
export R_LIBS_USER="${R_LIBS_USER:-/home/ubuntu/R/library}"
JL_PROJ="${JL_PROJ:-/home/ubuntu/jlsim}"
FE_TIMEOUT="${FE_TIMEOUT:-180}"
RE_TIMEOUT="${RE_TIMEOUT:-240}"
mkdir -p "$ROOT/results" "$ROOT/logs"

T1="gaussian student lognormal gamma poisson nbinom2 binomial beta"
FE_ONLY="tweedie skew_normal beta_binomial zero_one_beta"

echo "== t6 generate data =="
timeout 60 Rscript "$ROOT/t6_gen_data.R" "$ROOT" | tee "$ROOT/logs/gen_data.log"

run_cell() {
  local fam="$1" re="$2"
  local to="$FE_TIMEOUT"
  [[ "$re" == "re" ]] && to="$RE_TIMEOUT"
  local cell="${fam}_${re}"
  echo "== $cell R (timeout ${to}s) =="
  if ! timeout --signal=KILL "$to" Rscript "$ROOT/t6_run_drmTMB.R" "$ROOT" "$fam" "$re" \
       > "$ROOT/logs/${cell}_R.log" 2>&1; then
    echo "TIMEOUT_OR_FAIL $cell R" | tee -a "$ROOT/results/timeouts.txt"
    printf '%s\n' "engine,cell,family,re,check,status,pass,detail,time_s,seed,seed_r" \
      > "$ROOT/results/cells_${cell}.timeout.csv"
    printf 'drmTMB,%s,%s,%s,fit,timeout,FALSE,hard timeout %ss,,,\n' \
      "$cell" "$fam" "$re" "$to" >> "$ROOT/results/cells_${cell}.timeout.csv"
  fi
  echo "== $cell Julia (timeout ${to}s) =="
  if ! timeout --signal=KILL "$to" julia --project="$JL_PROJ" \
       "$ROOT/t6_run_DRModels.jl" "$ROOT" "$fam" "$re" \
       > "$ROOT/logs/${cell}_J.log" 2>&1; then
    echo "TIMEOUT_OR_FAIL $cell J" | tee -a "$ROOT/results/timeouts.txt"
    printf 'DRModels,%s,%s,%s,fit,timeout,FALSE,hard timeout %ss\n' \
      "$cell" "$fam" "$re" "$to" >> "$ROOT/results/cells_julia_${cell}.timeout.csv"
  fi
}

for fam in $T1; do
  run_cell "$fam" fe
  run_cell "$fam" re
done
for fam in $FE_ONLY; do
  run_cell "$fam" fe
done

echo "== compare R vs Julia predict =="
timeout 30 Rscript "$ROOT/t6_compare.R" "$ROOT" | tee "$ROOT/logs/compare.log"
echo "t6 run_all done"
