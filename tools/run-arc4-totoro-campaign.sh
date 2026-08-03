#!/usr/bin/env bash
# Arc 4 Totoro campaign driver: 5 seeds for mc-0417 (bound spatial+relmat
# mu-side pair). Mirrors tools/run-arc3-totoro-campaign.sh exactly; the seed
# family (2026080501-05) is the SAME family used for the local point-fit
# gate recorded in tools/arc4-multiprovider-mu-fixtures.R's header, so the
# gate and this campaign share one seed family.
set -uo pipefail

REPO="${REPO:-$HOME/hsq_work/drmtmb-arc4}"
OUT="${OUT:-$HOME/hsq_work/arc4-out/campaign}"
RLIB="${RLIB:-$HOME/R/lib}"
SEEDS="${SEEDS:-2026080501 2026080502 2026080503 2026080504 2026080505}"

mkdir -p "$OUT"
cd "$REPO" || exit 1

# cell^target^fixture^estimator
# NOTE: the delimiter must NOT be '|' — random-effect targets embed a literal
# '|' (e.g. "sd:mu:spatial(1 | site)"), which silently shifts every field.
CELLS=(
  "mc-0417^sd:mu:spatial(1 | site)^arc4_nbinom2_mu_spatial_relmat_fixture^ML"
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
