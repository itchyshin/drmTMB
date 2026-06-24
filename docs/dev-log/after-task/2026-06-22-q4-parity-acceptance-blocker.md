# After Task: SR140 q4 Parity Acceptance Blocker

Date: 2026-06-22

## Goal

Evaluate whether q4 parity can be accepted after banking the target map, direct
DRM.jl export, deterministic fixture, and tolerance policy.

## Decision

SR140 is blocked. The prerequisite pieces exist, but no same-fixture native
R/TMB, direct DRM.jl, and R-via-Julia point comparison has been run under the
predeclared tolerance policy. q4 `corpairs()` same-fixture parity and interval
reliability also remain missing.

## Changes

- Added `phase18_structured_re_q4_parity_acceptance_gate()` in
  `inst/sim/R/sim_structured_re_bridge_fixtures.R`.
- Added `docs/dev-log/dashboard/structured-re-q4-parity-acceptance-gate.tsv`
  with a single blocked gate row.
- Added fixture, dashboard-contract, validator, widget, executable-evidence,
  closeout, and finish-ledger checks for SR140.

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
curl -fsS http://127.0.0.1:8765/structured-re-q4-parity-acceptance-gate.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-finish-100-slices.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-closeout-package.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-executable-evidence.tsv >/dev/null
```

Result:

- `structured-re-bridge-fixtures` and `structured-re-conversion-contracts`
  passed with 424 assertions, 0 failures, 0 warnings, and 0 skips.
- `tools/validate-mission-control.py` passed with 1 q4 parity-acceptance gate
  row, 25 closeout-package rows, and 41 executable-evidence rows.
- JSON parsing, shell syntax, whitespace checks, and direct widget fetches
  passed.
- SR140 is now blocked with `bridge_status = experimental`. SR101-SR200 is now
  35 banked, 22 blocked, and 43 queued.

## Boundary

This is blocker evidence only. It does not promote q4 point parity,
R-via-Julia q4 bridge support, q4 REML support in drmTMB, HSquared AI-REML,
interval reliability, interval coverage, broad bridge support, a commit, a PR,
or an Ayumi-facing reply.

## Next Gate

Run same-fixture native R/TMB, direct DRM.jl, and R-via-Julia q4 point
comparison on the deterministic fixture under the predeclared tolerance policy.
