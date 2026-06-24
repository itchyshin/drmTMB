# After Task: Relmat K/Q Mu-Slope Parity Fixture

## Goal

Close the relmat K-versus-Q evidence gap for the one independent structured
location (`mu`) slope cell.

The target cell is exact and narrow:

`relmat(1 + x | id, K = K)` in Gaussian `mu`, ML, independent one-slope,
deterministic native/direct/R-via-Julia fixture parity.

## Implemented

- Added a same-target runtime check comparing
  `relmat(1 + x | id, Q = Q)` with `relmat(1 + x | id, K = K)` in
  `tests/testthat/test-animal-relmat-gaussian.R`.
- Promoted `relmat` in
  `phase18_structured_re_mu_slope_payload_fixture()` from planned to a
  deterministic K-matrix one-slope `mu` payload fixture.
- Updated `phase18_structured_re_mu_slope_parity_fixture_contract()` so the
  relmat row is `fixture_parity`, with interval and coverage statuses still
  planned.
- Updated `docs/dev-log/dashboard/structured-re-mu-slope-parity-fixture.tsv`.
- Updated `qseries_relmat_q1_mu_one_slope` in
  `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv` to point
  at the parity fixture sidecar.
- Updated `tools/validate-mission-control.py` so relmat is now part of the
  implemented one-slope `mu` fixture set and must still name the K-matrix and
  K/Q same-target boundary.
- Updated the R fixture contract tests and the dashboard conversion-contract
  tests.
- Updated the dashboard README, q-series design note, and check log.

## Evidence

The runtime test now fits both relmat matrix routes on the same generated data:

- `relmat(1 + x | id, Q = Q)`
- `relmat(1 + x | id, K = K)`

It checks convergence, extractor identity, profile-target identity,
log-likelihood parity, fixed-effect parity, and structured-SD parity.

The fixture contract remains deterministic fixture evidence. It is not live
bridge coverage evidence and it is not interval evidence.

## Checks Run

- `git status --short --branch` showed a clean `main` before the branch was
  created.
- `git diff --check` passed before the slice and after the focused tests.
- `air format inst/sim/R/sim_structured_re_bridge_fixtures.R tests/testthat/test-animal-relmat-gaussian.R tests/testthat/test-structured-re-bridge-fixtures.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `Rscript --vanilla -e "devtools::test(filter = 'animal-relmat-gaussian')"`
  passed with 178 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures')"`
  passed with 300 assertions.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
  passed with 1481 assertions.
- `python3 tools/validate-mission-control.py` passed and reported 69 structured
  RE q-series cells, 4 structured RE mu-slope audit rows, and 4 structured RE
  mu-slope parity-fixture rows.

## Claim Boundary

This slice supports one exact evidence claim: relmat one-slope Gaussian `mu`
has deterministic same-target fixture parity with K-matrix bridge marshalling
and runtime K/Q target parity.

It does not add residual-scale (`sigma`) structured slopes, labelled
structured slope covariance, structured q4/q6/q8 slopes, broad bridge support,
derived-correlation interval support, q4 interval reliability, q4 interval
coverage, q4 native-TMB REML, q4 AI-REML, HSquared AI-REML, non-Gaussian REML,
DRAC execution, or SR150 evidence.

## What Changed From The Prior Boundary

The previous spatial/animal parity fixture slice kept relmat planned because
the artifact writer used `Q = Q` and the bridge contract used `K = K`. This
slice adds the missing same-target K/Q runtime comparison and promotes only the
deterministic relmat one-slope `mu` fixture row.

## Next Actions

1. Start the separate residual-scale (`sigma`) one-slope tranche with the same
   support-cell discipline.
2. Add the first provider-safe sigma one-slope runtime test before moving any
   dashboard row out of planned.
3. Keep interval and coverage statuses planned until there is denominator and
   MCSE-calibrated coverage evidence.
