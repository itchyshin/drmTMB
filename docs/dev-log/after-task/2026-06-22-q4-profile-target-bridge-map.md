# After Task: SR134 q4 Profile-Target Bridge Map

Date: 2026-06-22

## Goal

Bank a row-shaped q4 profile-target bridge map for the four direct phylogenetic
covariance SD axes without promoting q4 parity, q4 REML, AI-REML, interval
reliability, interval coverage, or public bridge support.

## Changes

- Added `phase18_structured_re_q4_profile_target_bridge_map()` in
  `inst/sim/R/sim_structured_re_bridge_fixtures.R`.
- Added `docs/dev-log/dashboard/structured-re-q4-profile-target-bridge-map.tsv`
  with one row each for `mu1`, `mu2`, `sigma1`, and `sigma2`.
- Mapped native R/TMB target names such as
  `sd:mu:sigma1:phylo(1 | p | species)` to bridge-facing labels such as
  `sd:sigma1:phylo(1 | species)`.
- Added fixture, dashboard-contract, validator, widget, executable-evidence,
  closeout, and finish-ledger checks for SR134.

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
curl -fsS http://127.0.0.1:8765/status.json >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-q4-profile-target-bridge-map.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-finish-100-slices.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-executable-evidence.tsv >/dev/null
```

Result:

- `structured-re-bridge-fixtures` and `structured-re-conversion-contracts`
  passed with 298 assertions, 0 failures, 0 warnings, and 0 skips.
- `tools/validate-mission-control.py` passed with 4 q4 profile-target
  bridge-map rows, 20 closeout-package rows, and 36 executable-evidence rows.
- JSON parsing, shell syntax, whitespace checks, and direct widget fetches
  passed.
- SR134 is now banked with `bridge_status = experimental`. SR101-SR200 is now
  31 banked, 21 blocked, and 48 queued.

## Boundary

This is target-label contract evidence only. It does not establish q4 all-four
parity, q4 `corpairs()` same-fixture parity, q4 REML, HSquared AI-REML,
profile-interval reliability, interval coverage, broad R-via-Julia bridge
support, a commit, a PR, or an Ayumi-facing reply.

## Next Gate

Compare same-target q4 SD point estimates and interval availability across
native R/TMB, direct DRM.jl, and R-via-Julia routes before changing any q4
interval or bridge-support wording.
