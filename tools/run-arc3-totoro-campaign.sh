#!/usr/bin/env bash
# Arc 3 Totoro campaign driver: 3 seeds per cell for mc-0421/mc-0424 after the
# nbinom2 sigma-provider DGP redesign (Grafen branch lengths for phylo;
# n_id 40->80 for relmat). Mirrors tools/run-arc2-totoro-campaign.sh exactly.
set -uo pipefail

REPO="${REPO:-$HOME/hsq_work/drmTMB-arc3}"
OUT="${OUT:-$HOME/hsq_work/arc3-out/campaign}"
RLIB="${RLIB:-$HOME/R/lib}"
SEEDS="${SEEDS:-2026080301 2026080302 2026080303}"

mkdir -p "$OUT"
cd "$REPO" || exit 1

# cell^target^fixture^estimator
# NOTE: the delimiter must NOT be '|' — random-effect targets embed a literal
# '|' (e.g. "sd:sigma:phylo(1 | species)"), which silently shifts every field.
CELLS=(
  "mc-0421^sd:sigma:phylo(1 | species)^arc3_nbinom2_sigma_phylo_fixture^ML"
  "mc-0424^sd:sigma:relmat(1 | id)^arc3_nbinom2_sigma_relmat_fixture^ML"
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
