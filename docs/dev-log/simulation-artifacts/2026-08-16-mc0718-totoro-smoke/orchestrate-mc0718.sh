#!/usr/bin/env bash
# Totoro-side orchestrator: deploy SHA, copy runners, launch toy + 27-fit.
# Invoked as: bash ~/hsq_work/mc0718-staging/orchestrate-mc0718.sh

set -euo pipefail

STAGING="${DRMTMB_STAGING:-$HOME/hsq_work/mc0718-staging}"
REPO="${DRMTMB_REPO:-$HOME/hsq_work/drmTMB-mc0718}"
LIB="${DRMTMB_LIB:-$HOME/hsq_work/drmTMB-mc0718-library}"
OUT="$REPO/docs/dev-log/simulation-artifacts/2026-08-16-mc0718-totoro-smoke"

export DRMTMB_REPO="$REPO"
export DRMTMB_LIB="$LIB"
export DRMTMB_EXPECT_SHA="${DRMTMB_EXPECT_SHA:-3e8a9aaec9aae3e20a5e3bbd46fb65561304e368}"
export NWORKERS="${NWORKERS:-8}"

echo "[mc0718] deploy"
bash "$STAGING/deploy-mc0718.sh"

mkdir -p "$OUT"
cp -f "$STAGING/run-mc0718-smoke.R" "$OUT/run-mc0718-smoke.R"
cp -f "$STAGING/launch-mc0718-smoke.sh" "$OUT/launch-mc0718-smoke.sh"
cp -f "$STAGING/deploy-mc0718.sh" "$OUT/deploy-mc0718.sh"
chmod +x "$OUT/launch-mc0718-smoke.sh" "$OUT/deploy-mc0718.sh"

echo "[mc0718] launch"
bash "$OUT/launch-mc0718-smoke.sh"
echo "[mc0718] orchestrate DONE"
