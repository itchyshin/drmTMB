# After Task: SR137 q4 Direct DRM.jl Export

Date: 2026-06-22

## Goal

Make direct DRM.jl q4 point SD targets row-shaped before any q4 bridge parity
claim. The target rows cover `sd_mu1`, `sd_mu2`, `sd_sigma1`, and `sd_sigma2`
from `fit.ranef.Sigma_a`.

## Changes

- Added DRM.jl internal helpers `_bridge_q4_direct_export_schema()`,
  `_bridge_q4_direct_export_status()`, and
  `_bridge_q4_validate_direct_export_status()` in
  `/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot/src/bridge.jl`.
- Added DRM.jl bridge payload helper `_bridge_q4_point_export()` so bridge
  fits carrying a 4-by-4 `fit.ranef.Sigma_a` retain the raw point matrix,
  per-axis SDs, and the derived correlation matrix.
- Added
  `/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot/test/test_bridge_q4_direct_export.jl`
  and included it from DRM.jl `test/runtests.jl`.
- Added `phase18_structured_re_q4_direct_drmjl_export_status()` in
  `inst/sim/R/sim_structured_re_bridge_fixtures.R`.
- Added `docs/dev-log/dashboard/structured-re-q4-direct-drmjl-export.tsv`
  and validator, widget, executable-evidence, closeout, and finish-ledger rows.

## Evidence

Checks run:

```sh
julia --project=/Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot /Users/z3437171/worktrees/DRM-ai-reml-gaussian-mme-pilot/test/test_bridge_q4_direct_export.jl
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
python3 -m json.tool docs/dev-log/dashboard/status.json >/dev/null
python3 -m json.tool docs/dev-log/dashboard/sweep.json >/dev/null
sh -n tools/start-mission-control.sh
git diff --check
DRMTMB_DASHBOARD_DIR=/tmp/drm-dashboard DRMTMB_DASHBOARD_PORT=8765 sh tools/start-mission-control.sh --background
curl -fsS http://127.0.0.1:8765/structured-re-q4-direct-drmjl-export.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-finish-100-slices.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-closeout-package.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-executable-evidence.tsv >/dev/null
```

Result:

- The focused Julia q4 direct export test now passes with 36 assertions: 19 for
  the status contract, 16 for the point-matrix payload, and 1 for the
  log-Cholesky label order used by the R bridge.
- `structured-re-bridge-fixtures` and `structured-re-conversion-contracts`
  passed with 347 assertions, 0 failures, 0 warnings, and 0 skips.
- `tools/validate-mission-control.py` passed with 4 q4 direct-DRM.jl export
  rows, 22 closeout-package rows, and 38 executable-evidence rows.
- JSON parsing, shell syntax, whitespace checks in both active worktrees, and
  direct widget fetches passed.
- SR137 is now banked with `bridge_status = experimental`. SR101-SR200 is now
  33 banked, 21 blocked, and 46 queued.

## Boundary

This is direct DRM.jl point-target and point-matrix export evidence only. It
does not establish R-via-Julia q4 bridge parity, q4 all-four parity, q4
`corpairs()` parity, q4 REML support in drmTMB, HSquared AI-REML, interval
reliability, interval coverage, broad bridge support, a commit, a PR, or an
Ayumi-facing reply.

## Next Gate

Compare same-target native R/TMB, direct DRM.jl, and R-via-Julia q4 point
outputs on a deterministic fixture before accepting q4 parity.
