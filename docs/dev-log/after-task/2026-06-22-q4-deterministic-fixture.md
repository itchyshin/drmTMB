# After Task: SR138 q4 Deterministic Fixture

Date: 2026-06-22

## Goal

Create a small deterministic q4 phylogenetic fixture that future parity slices
can reuse for same-target native R/TMB, direct DRM.jl, and R-via-Julia
comparisons.

## Changes

- Added `phase18_structured_re_q4_deterministic_fixture()` in
  `inst/sim/R/sim_structured_re_bridge_fixtures.R`.
- The fixture returns a deterministic 8-species, 16-observation balanced-tree
  data set with `y1`, `y2`, `x`, `species`, `sigma1_truth`, `sigma2_truth`,
  a fixed Newick string, known fixed effects, latent species effects, and a
  positive-definite 4x4 `Sigma_a` over `mu1`, `mu2`, `sigma1`, and `sigma2`.
- Added `phase18_structured_re_q4_deterministic_fixture_status()` and
  `docs/dev-log/dashboard/structured-re-q4-deterministic-fixture.tsv`.
- Added fixture, dashboard-contract, validator, widget, executable-evidence,
  closeout, and finish-ledger checks for SR138.

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
curl -fsS http://127.0.0.1:8765/structured-re-q4-deterministic-fixture.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-finish-100-slices.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-closeout-package.tsv >/dev/null
curl -fsS http://127.0.0.1:8765/structured-re-executable-evidence.tsv >/dev/null
```

Result:

- `structured-re-bridge-fixtures` and `structured-re-conversion-contracts`
  passed with 376 assertions, 0 failures, 0 warnings, and 0 skips.
- `tools/validate-mission-control.py` passed with 1 q4 deterministic fixture
  row, 23 closeout-package rows, and 39 executable-evidence rows.
- JSON parsing, shell syntax, whitespace checks, and direct widget fetches
  passed.
- SR138 is now banked with `bridge_status = planned`. SR101-SR200 is now
  34 banked, 21 blocked, and 45 queued.

## Boundary

This is deterministic fixture evidence only. It does not establish native R/TMB,
direct DRM.jl, or R-via-Julia q4 parity, q4 REML support, HSquared AI-REML,
interval reliability, interval coverage, broad bridge support, a commit, a PR,
or an Ayumi-facing reply.

## Next Gate

Use the fixture for same-target q4 point comparisons across native R/TMB, direct
DRM.jl, and R-via-Julia routes before accepting q4 parity.
