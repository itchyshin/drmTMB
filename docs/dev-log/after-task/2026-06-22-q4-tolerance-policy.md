# After Task: SR139 q4 Tolerance Policy

Date: 2026-06-22

## Goal

Predeclare q4 point-parity tolerances before any acceptance gate uses the
deterministic fixture.

## Changes

- Added `phase18_structured_re_q4_tolerance_policy()` in
  `inst/sim/R/sim_structured_re_bridge_fixtures.R`.
- Added `docs/dev-log/dashboard/structured-re-q4-tolerance-policy.tsv`.
- Declared tolerances for log likelihood, fixed coefficients, direct SD
  targets, and derived correlations across native R/TMB, direct DRM.jl, and
  R-via-Julia routes.
- Added fixture, dashboard-contract, validator, widget, executable-evidence,
  closeout, and finish-ledger checks for SR139.

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
curl -fsS http://127.0.0.1:8765/structured-re-q4-tolerance-policy.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-finish-100-slices.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-closeout-package.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-executable-evidence.tsv >/dev/null
```

Result:

- `structured-re-bridge-fixtures` and `structured-re-conversion-contracts`
  passed with 397 assertions, 0 failures, 0 warnings, and 0 skips.
- `tools/validate-mission-control.py` passed with 4 q4 tolerance-policy rows,
  24 closeout-package rows, and 40 executable-evidence rows.
- JSON parsing, shell syntax, whitespace checks, and direct widget fetches
  passed.
- SR139 is now banked with `bridge_status = planned`. SR101-SR200 is now
  35 banked, 21 blocked, and 44 queued.

## Boundary

This is tolerance-policy evidence only. It does not establish q4 point parity,
R-via-Julia q4 bridge support, q4 REML support in drmTMB, HSquared AI-REML,
interval reliability, interval coverage, broad bridge support, a commit, a PR,
or an Ayumi-facing reply.

## Next Gate

Apply these tolerances to same-fixture native R/TMB, direct DRM.jl, and
R-via-Julia q4 point outputs before changing q4 parity status.
