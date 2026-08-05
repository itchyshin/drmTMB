#!/usr/bin/env bash
# Totoro driver for the 135-trace Prong B campaign.
# Authority: LOOP/ultra-plan.md · PREREGISTRATION.md · D-50 (never Actions).
#
# OPEN GATE: do not launch the full grid until Shinichi gives explicit Totoro approval.
#
# Usage:
#   ./tools/run-135-trace-totoro.sh --list
#   ./tools/run-135-trace-totoro.sh --emit-jobs /tmp/135-jobs.txt
#   ./tools/run-135-trace-totoro.sh --local-smoke          # mc-0568 seed1 via runner
#   DRMTMB_TOTORO_GO=1 ./tools/run-135-trace-totoro.sh --launch --cores 48
#
# Job lines use ^ as the field delimiter (cell^seed_index^target).

set -euo pipefail

REPO="${DRMTMB_REPO:-$(cd "$(dirname "$0")/.." && pwd)}"
OUTDIR="${DRMTMB_135_OUTDIR:-$REPO/docs/dev-log/simulation-artifacts/2026-08-05-135-trace-campaign}"
Rscript_bin="${RSCRIPT:-Rscript}"
RUNNER="$REPO/tools/run-135-trace-campaign.R"
CORES="${DRMTMB_135_CORES:-48}"
MODE=""
JOBFILE=""

usage() {
  sed -n '1,16p' "$0" | sed 's/^# \{0,1\}//'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --list) MODE=list; shift ;;
    --emit-jobs) MODE=emit; JOBFILE="${2:?}"; shift 2 ;;
    --local-smoke) MODE=smoke; shift ;;
    --launch) MODE=launch; shift ;;
    --cores) CORES="${2:?}"; shift 2 ;;
    --outdir) OUTDIR="${2:?}"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$MODE" ]]; then
  usage
  exit 2
fi

export DRMTMB_REPO="$REPO"

case "$MODE" in
  list)
    "$Rscript_bin" --vanilla "$RUNNER" --repo "$REPO" --list
    ;;
  emit)
    "$Rscript_bin" --vanilla "$RUNNER" --repo "$REPO" --emit-jobfile "$JOBFILE"
    ;;
  smoke)
    echo "[135] local C1 smoke: mc-0568 seed_index=1 via tmbprofile runner"
    "$Rscript_bin" --vanilla "$RUNNER" \
      --repo "$REPO" \
      --outdir "$OUTDIR" \
      --cell "mc-0568" \
      --seed-index "1" \
      --target "sd:sigma:(1 | id)"
    ;;
  launch)
    if [[ "${DRMTMB_TOTORO_GO:-}" != "1" ]]; then
      echo "REFUSED: Totoro launch requires DRMTMB_TOTORO_GO=1 (explicit owner approval)." >&2
      echo "This is the OPEN GATE named in LOOP/GOAL.md." >&2
      exit 3
    fi
    if (( CORES > 100 )); then
      echo "REFUSED: cores=$CORES exceeds campaign ceiling 100." >&2
      exit 3
    fi
    JOBFILE="${JOBFILE:-$OUTDIR/joblist.txt}"
    mkdir -p "$OUTDIR"
    "$Rscript_bin" --vanilla "$RUNNER" --repo "$REPO" --emit-jobfile "$JOBFILE"
    echo "[135] launching $(wc -l < "$JOBFILE") jobs with GNU parallel -j $CORES"
    if ! command -v parallel >/dev/null 2>&1; then
      echo "GNU parallel not found on PATH." >&2
      exit 1
    fi
    parallel -j "$CORES" --colsep '\^' \
      "$Rscript_bin" --vanilla "$RUNNER" --repo "$REPO" --outdir "$OUTDIR" \
      --cell {1} --seed-index {2} --target {3} \
      :::: "$JOBFILE"
    ;;
esac
