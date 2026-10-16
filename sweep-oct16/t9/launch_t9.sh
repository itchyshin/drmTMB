#!/usr/bin/env bash
# Launch the four R cells in parallel, then Julia (or overlap if T9_OVERLAP=1).
set -u
export R_LIBS_USER="${R_LIBS_USER:-$HOME/R/library}"
export OMP_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export MKL_NUM_THREADS=1
export TMB_NUM_THREADS=1
ROOT="/workspace/sweep-oct16/t9"
LOG="$ROOT/logs"
RES="$ROOT/results"
mkdir -p "$LOG" "$RES"

run_r_cell() {
  local idx="$1" G="$2" sd="$3"
  echo "$(date -u +'%F %T UTC') start R cell $idx G=$G sd_g=$sd"
  timeout 4h env R_LIBS_USER="$R_LIBS_USER" Rscript "$ROOT/run_t9_r.R" \
    --G "$G" --sd_g "$sd" --n_rep 300 --n_boot_rep 100 --n_g 10 --B 199 \
    --cell_index "$idx" --out "$RES/r_cell${idx}.tsv" \
    > "$LOG/r_cell${idx}.log" 2>&1
  local rc=$?
  echo "$(date -u +'%F %T UTC') end R cell $idx rc=$rc"
  return $rc
}

run_jl() {
  echo "$(date -u +'%F %T UTC') start Julia"
  timeout 4h env T9_JL_OUT="$RES/jl_reps.tsv" \
    julia --project=/tmp/DRModels.jl --startup-file=no "$ROOT/run_t9_jl.jl" \
    > "$LOG/jl.log" 2>&1
  local rc=$?
  echo "$(date -u +'%F %T UTC') end Julia rc=$rc"
  return $rc
}

echo "$(date -u +'%F %T UTC') t9 launch begin"

run_r_cell 1 10 0.1 &
p1=$!
run_r_cell 2 10 0.5 &
p2=$!
run_r_cell 3 30 0.1 &
p3=$!
run_r_cell 4 30 0.5 &
p4=$!
run_jl &
pj=$!

rc=0
for p in $p1 $p2 $p3 $p4 $pj; do
  if ! wait "$p"; then
    rc=1
  fi
done

# Concatenate R cells
{
  head -n 1 "$RES/r_cell1.tsv" 2>/dev/null || true
  for i in 1 2 3 4; do
    if [[ -s "$RES/r_cell${i}.tsv" ]]; then
      tail -n +2 "$RES/r_cell${i}.tsv"
    fi
  done
} > "$RES/r_reps.tsv"

env R_LIBS_USER="$R_LIBS_USER" Rscript "$ROOT/summarize_t9.R" \
  "$RES/r_reps.tsv" "$RES/jl_reps.tsv" "$RES" \
  > "$LOG/summarize.log" 2>&1 || true

echo "$(date -u +'%F %T UTC') t9 launch end rc=$rc"
exit $rc
