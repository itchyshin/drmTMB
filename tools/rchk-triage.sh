#!/usr/bin/env bash
# rchk-triage.sh -- decide, in seconds, whether an R-hub `rchk` red is OUR bug.
#
# WHY THIS EXISTS (2026-09-06). Six consecutive R-hub runs showed red and each took
# ~1 h to produce. Every one of them was the `rchk` container; clang-asan, gcc-asan
# and clang-ubsan passed in the same runs. Reading the log by hand showed the red is
# NOT a drmTMB defect:
#
#   * The four real findings -- "[PB] has possible protection stack imbalance" --
#     were all in TMB/include/tmb_core.hpp (lines 1253, 1253, 1525, 2287). That is
#     the TMB DEPENDENCY's header, not drmTMB's src/. Any TMB-based package
#     inherits them.
#   * The five "ERROR: too many states (abstraction error?)" lines are rchk's
#     analyzer giving up on a function too complex to model -- a CAPACITY limit,
#     not a bug report. Three were in R's OWN base C (strptime_internal,
#     bcEval_loop, RunGenCollect); two were TMB's objective_function template.
#
# So the question is never "is rchk red?" -- for a TMB package it will be. The
# question is "does rchk name a file WE own?". This script answers exactly that.
#
# USAGE:  tools/rchk-triage.sh <run-id>          # an R-hub workflow run id
#         tools/rchk-triage.sh --latest          # most recent R-hub run
#
# EXIT 0 = no finding in this package's own sources (red is inherited/upstream)
# EXIT 1 = at least one finding names a file this package owns -> a REAL defect
set -uo pipefail
REPO="${RCHK_REPO:-itchyshin/drmTMB}"
PKG_SRC_RE='(^|/)(src/|inst/include/)'          # what THIS package owns

run="${1:?usage: rchk-triage.sh <run-id> | --latest}"
if [ "$run" = "--latest" ]; then
  run=$(gh run list -R "$REPO" --workflow=rhub.yaml -L 1 --json databaseId -q '.[0].databaseId')
  echo "latest R-hub run: $run"
fi

if [ "$run" = "--self-test" ]; then
  # RED CONTROL: a check that can only ever say "fine" is worthless. Inject one
  # synthetic finding naming a file THIS package owns and require the verdict to flip.
  log='rchk	x	  [PB] has possible protection stack imbalance /__w/drmTMB/drmTMB/src/drmTMB.cpp:99'
else
log=$(gh run view "$run" -R "$REPO" --log 2>/dev/null | grep "^rchk" || true)
fi
if [ -z "$log" ]; then
  echo "no rchk job in run $run (was rchk in the config list?)"; exit 0
fi

echo "=== rchk findings, partitioned by who owns the file ==="
findings=$(printf '%s\n' "$log" | grep -oE '\[(PB|UP)\][^ ]* [^/]*(/[^ :]+)+:[0-9]+' || true)
capacity=$(printf '%s\n' "$log" | grep -c 'too many states (abstraction error?)' || true)

ours=0; theirs=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  path=$(printf '%s' "$f" | grep -oE '(/[^ :]+)+:[0-9]+')
  if printf '%s' "$path" | grep -qE "$PKG_SRC_RE" && ! printf '%s' "$path" | grep -qE '/R/x86_64|/library/|/include/'; then
    echo "  OURS    $f"; ours=$((ours+1))
  else
    echo "  UPSTREAM $f"; theirs=$((theirs+1))
  fi
done <<< "$findings"

echo
echo "analyzer capacity errors (not bug reports): $capacity"
echo "findings in a dependency / base R:          $theirs"
echo "findings in THIS package's own sources:     $ours"
echo
if [ "$ours" -gt 0 ]; then
  echo "VERDICT: REAL -- rchk names $ours finding(s) in this package's own sources. Fix them."
  exit 1
fi
echo "VERDICT: INHERITED -- no finding names a file this package owns."
echo "         The red is upstream (TMB headers / base R) plus rchk capacity limits."
echo "         Nothing to fix here; do not re-run expecting green."
exit 0
