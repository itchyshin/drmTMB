# After-Task Report: Q4 Location One-Slope Fixture Parity

Date: 2026-06-24

Branch: `codex/structured-relmat-kq-mu-slope-fixture`

## Purpose

Move the exact bivariate Gaussian structured `mu1+mu2`
intercept-plus-one-slope q4 location cells one evidence rung beyond native
point-fit/extractor status by adding deterministic same-target fixture parity.

The covered cells are:

- `phylo(1 + x | p | species, tree = tree)` in `mu1` and `mu2`;
- fixed-covariance `spatial(1 + x | p | site, coords = coords)` in `mu1` and
  `mu2`;
- A-matrix `animal(1 + x | p | id, A = A)` in `mu1` and `mu2`;
- K-matrix `relmat(1 + x | p | id, K = K)` in `mu1` and `mu2`.

## Implementation

- Added `phase18_structured_re_q4_location_slope_payload_fixture()` and
  `phase18_structured_re_q4_location_slope_parity_fixture_contract()` to the
  structured RE bridge fixture helpers.
- Added a focused bridge-fixture test for the exact four-member q4 location
  endpoint map, four SD terms, and six labelled correlation terms.
- Added
  `tools/run-structured-re-q4-location-slope-parity-fixture.R`.
- Added
  `docs/dev-log/dashboard/structured-re-q4-location-slope-parity-fixture.tsv`
  with four provider rows.
- Promoted the four matching q-series support-cell rows to
  `native_direct_bridge_fixture`, `fixture_parity`, and
  `fixture_not_coverage`, while keeping interval and coverage status planned.
- Wired the new sidecar into mission-control validation, the dashboard README,
  and the q-series completion map.

## Evidence

Focused checks passed:

```sh
Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures', stop_on_failure = TRUE)"
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"
python3 -m py_compile tools/validate-mission-control.py
python3 tools/validate-mission-control.py
git diff --check
```

Results: 560 `structured-re-bridge-fixtures` assertions and 3,041
`structured-re-conversion-contracts` assertions passed. Mission-control
validation passed and reported four structured RE q4 location slope
parity-fixture rows.

The targeted overclaim scan returned only negative boundary statements in
existing docs and logs.

## Claim Boundary

This slice is deterministic fixture parity for the exact four-member q4
location endpoint map only. It does not promote broad bridge support, partial
location-scale support, interval reliability, coverage, q4 REML, native-TMB q4
REML, q4 AI-REML, HSquared AI-REML, non-Gaussian REML, public optimizer
controls, public support, DRAC execution, SR150 coverage readiness, PR
undrafting/merging, or an Ayumi-facing reply.

The `relmat()` fixture is a K-matrix contract only. Q precision marshalling is
still separate, and this slice does not claim K/Q same-target parity for the
partial q4 location cell.

## Next Gate

Use the exact q4 location fixture as the input for target-level interval
diagnostic planning and smoke checks. Keep `sigma1+sigma2` partial-axis support,
partial location-scale layouts, calibrated coverage denominators, q4 REML, and
broader structured q8 support in separate cells.
