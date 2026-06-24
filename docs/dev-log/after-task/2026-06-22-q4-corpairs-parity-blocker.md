# After-Task: SR133 q4 Corpairs Parity Blocker

## Goal

Evaluate whether q4 `corpairs()` evidence can be treated as native/direct/bridge
parity.

## Result

The answer is no. The existing q4 bridge test shows live point extraction and
valid among-axis correlations from the R-via-Julia route, and the R-side
reconstruction test checks a hand-built `Sigma_a`. It does not compare native
R/TMB, direct DRM.jl, and R-via-Julia `corpairs()` on the same q4 fixture.

## Changes

- Added `phase18_structured_re_q4_corpairs_parity_gate()`.
- Added `structured-re-q4-corpairs-parity-gate.tsv`.
- Added validator checks that keep q4 `corpairs()` parity blocked until a
  same-fixture native/direct/bridge comparison exists.
- Updated dashboard rendering, dashboard README, fixture tests, and
  dashboard-contract tests.

## Checks Run

```sh
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
```

Result:

- `structured-re-bridge-fixtures` and `structured-re-conversion-contracts`
  passed with 275 assertions, 0 failures, 0 warnings, and 0 skips.
- `python3 tools/validate-mission-control.py` passed with one q4
  corpairs-parity gate row.

## Boundary

This is blocker evidence, not q4 parity support. It does not promote q4
all-four parity, q4 REML, HSquared AI-REML, interval coverage, public bridge
support, a commit, a PR, or an Ayumi-facing reply.
