#!/usr/bin/env bash
# Arc 2 Totoro campaign driver: 3 seeds per cell for the interval-feasibility contract.
# Bounded fan-out; each run is a single small fit plus one profile execution.
set -uo pipefail

REPO="${REPO:-$HOME/hsq_work/drmTMB-arc2-interval}"
OUT="${OUT:-$HOME/hsq_work/arc2-out/campaign}"
RLIB="${RLIB:-$HOME/hsq_work/arc2-Rlib}"
SEEDS="${SEEDS:-2026080201 2026080202 2026080203}"

mkdir -p "$OUT"
cd "$REPO" || exit 1

# cell^target^fixture^estimator
# NOTE: the delimiter must NOT be '|' — random-effect targets embed a literal
# '|' (e.g. "sd:mu:phylo(1 | species)"), which silently shifts every field.
CELLS=(
  "mc-0186^rho12^biv_reml_fixture^REML"
  "mc-0263^fixef:sigma:x^reml_hetero_fixture^REML"
  "mc-0274^sd:mu:phylo(1 | species)^reml_phylo_location_fixture^REML"
)

pids=()
for spec in "${CELLS[@]}"; do
  IFS='^' read -r cell target fixture estimator <<< "$spec"
  for seed in $SEEDS; do
    logf="$OUT/${cell}-seed${seed}.log"
    (
      OPENBLAS_NUM_THREADS=1 \
      R_LIBS_USER="$RLIB" \
      R_PROFILE_USER=/dev/null \
      Rscript --no-init-file tools/run-arc2-profile-feasibility.R \
        --cell="$cell" \
        --target="$target" \
        --fixture="$fixture" \
        --estimator="$estimator" \
        --seed="$seed" \
        --outdir="$OUT/$cell" \
        > "$logf" 2>&1
      echo "exit=$? $cell seed=$seed" >> "$OUT/status.txt"
    ) &
    pids+=($!)
  done
done

for p in "${pids[@]}"; do wait "$p"; done
echo "CAMPAIGN_COMPLETE" >> "$OUT/status.txt"
