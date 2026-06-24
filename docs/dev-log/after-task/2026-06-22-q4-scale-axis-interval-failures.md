# After Task: SR136 q4 Scale-Axis Interval Failures

Date: 2026-06-22

## Goal

Keep q4 scale-axis interval failures visible as target-specific blocker rows for
`sd_sigma1` and `sd_sigma2`, without promoting q4 interval reliability,
interval coverage, q4 parity, q4 REML, AI-REML, or bridge support.

## Changes

- Added `phase18_structured_re_q4_scale_axis_interval_failure_ledger()` in
  `inst/sim/R/sim_structured_re_bridge_fixtures.R`.
- Added
  `docs/dev-log/dashboard/structured-re-q4-scale-axis-interval-failures.tsv`
  with one row each for `sigma1` and `sigma2`.
- Connected the rows to native TMB bootstrap accounting and direct DRM.jl
  q4 bootstrap evidence:
  `docs/dev-log/dashboard/bootstrap-refit-accounting.tsv` and
  `/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot/docs/dev-log/after-task/2026-06-13-bivariate-bootstrap-sigma-a.md`.
- Added fixture, dashboard-contract, validator, widget, executable-evidence,
  closeout, and finish-ledger checks for SR136.

## Evidence

Checks run:

```sh
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh -n tools/start-mission-control.sh
git diff --check
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/structured-re-q4-scale-axis-interval-failures.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-finish-100-slices.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-closeout-package.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-executable-evidence.tsv >/dev/null
```

Result:

- `structured-re-bridge-fixtures` and `structured-re-conversion-contracts`
  passed with 325 assertions, 0 failures, 0 warnings, and 0 skips.
- `tools/validate-mission-control.py` passed with 2 q4 scale-axis
  interval-failure rows, 21 closeout-package rows, and 37
  executable-evidence rows.
- JSON parsing, shell syntax, whitespace checks, and direct widget fetches
  passed.
- SR136 is now banked with `bridge_status = experimental`. SR101-SR200 is now
  32 banked, 21 blocked, and 47 queued.

## Boundary

This is failure-ledger evidence only. Native 100-tip q4 bootstrap refit failures
and direct DRM.jl scale-axis undercoverage are design inputs and blockers, not
R bridge support. This does not establish q4 interval reliability, interval
coverage, q4 all-four parity, q4 `corpairs()` parity, q4 REML, HSquared
AI-REML, public bridge support, a commit, a PR, or an Ayumi-facing reply.

## Next Gate

Diagnose scale-axis bias and refit failures before any q4 interval wording,
coverage claim, or bridge-support transition.
