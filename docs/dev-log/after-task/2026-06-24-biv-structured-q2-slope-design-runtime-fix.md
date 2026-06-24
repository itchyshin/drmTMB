# After Task: Bivariate Structured Q2 Slope Design Runtime Fix

## Goal

Fix and bank the bivariate Gaussian structured q2 slope runtime path after the
interval stability probe showed fitted structured slope SDs near zero even
under strong simulated slope variance.

## Implemented

- Updated the bivariate Gaussian structured-effect contribution in
  `src/drmTMB.cpp` so q2/q4 `mu1`, `mu2`, and location-scale structured effects
  multiply each latent structured effect by the corresponding structured design
  column.
- Updated `phylo_mu_contribution()` so extractor-side structured contributions
  use the same endpoint/member design multiplication.
- Added provider tests for `phylo()`, fixed-covariance `spatial()`, A-matrix
  `animal()`, and K-matrix `relmat()` showing that manual node effects are
  multiplied by the structured slope design column.
- Reran the q2 slope interval smoke and stability probe artifacts after the
  runtime fix.
- Updated the q2 diagnostic sidecar contracts, dashboard README, q-series
  completion map, and earlier q2 interval after-task notes to the post-fix
  evidence pattern.

## Mathematical Contract

For a bivariate Gaussian slope-only structured cell, the likelihood contribution
for observation `i` and endpoint/member `k` must use

```text
eta_endpoint(i) += structured_design(i, k) * u_structured(level(i), k)
```

The old bivariate runtime path used `u_structured(level(i), k)` directly in the
q2/q4 branch. That made slope-only q2 behave like an intercept-like structured
effect in the likelihood, while extractor labels and bridge target labels still
looked slope-specific. Intercept-only q4 fixtures were not affected because the
design column is 1 for intercept members.

## Files Changed

- `src/drmTMB.cpp`
- `R/methods.R`
- `tests/testthat/test-phylo-gaussian.R`
- `tests/testthat/test-spatial-gaussian.R`
- `tests/testthat/test-animal-relmat-gaussian.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/structured-re-q2-slope-interval-diagnostic-status.tsv`
- `docs/dev-log/dashboard/structured-re-q2-slope-interval-stability-probe.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-q2-slope-interval-smoke/structured-re-q2-slope-interval-smoke-results.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-q2-slope-interval-stability-probe/structured-re-q2-slope-interval-stability-probe-results.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/after-task/2026-06-24-q2-slope-interval-smoke-status.md`
- `docs/dev-log/after-task/2026-06-24-q2-slope-interval-stability-probe.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format R/methods.R tests/testthat/test-phylo-gaussian.R tests/testthat/test-spatial-gaussian.R tests/testthat/test-animal-relmat-gaussian.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'phylo-gaussian')"
Rscript --vanilla -e "devtools::test(filter = 'spatial-gaussian')"
Rscript --vanilla -e "devtools::test(filter = 'animal-relmat-gaussian')"
git diff --check
```

The focused tests passed with 2,091 structured-re conversion assertions, 336
phylo Gaussian assertions, 211 spatial Gaussian assertions, and 329
animal/relmat Gaussian assertions. Mission-control validation passed with 73
structured RE q-series cells and accepted the regenerated q2 interval smoke and
stability sidecars.

## Evidence Result

The regenerated q2 interval-smoke status has 12 target rows: 10 rows have
finite Wald/profile/bootstrap diagnostics, and two correlation rows
(`animal` and `relmat`) have finite Wald/bootstrap diagnostics with endpoint
profile failure. All fits converged with `pdHess = TRUE`.

The regenerated q2 stability probe has 24 variant-target rows. All 24 rows have
finite Wald/profile diagnostics and `pdHess = TRUE`.

## Consistency Audit

The linked support cells remain at `interval_status = planned` and
`coverage_status = planned`, with denominator policy
`fixture_not_coverage`. The documentation explicitly keeps this as
diagnostic-only evidence and does not promote q2 interval reliability,
coverage, q4/q8, REML, AI-REML, broad bridge support, range-estimating spatial
support, pedigree/Ainv bridge marshalling, or relmat Q bridge marshalling.

## GitHub Issue Maintenance

No GitHub issue action was taken. This is an internal q-series implementation
and evidence-ladder correction inside the current structured random-effect
completion lane.

## What Did Not Go Smoothly

The initial interval probe looked like numerical boundary behavior. The
support-cell workflow helped localize the mismatch: extractor labels and bridge
targets were correct, but the runtime likelihood path had not applied the
slope design multiplier in the bivariate q2/q4 branch.

## Team Learning

Future structured slope cells need provider/member contribution tests before
interval diagnostics are interpreted. A q-cell can have correct parser,
metadata, and target labels while the likelihood contribution still behaves
like a neighboring cell.

## Known Limitations

This slice does not provide calibrated coverage, interval reliability, coverage
MCSE, REML, AI-REML, broad bridge support, range-estimating spatial support,
pedigree/Ainv bridge marshalling, relmat Q bridge marshalling,
intercept-plus-slope q4/q8 structured slope support, two-slope support, or
non-Gaussian structured slope support.

## Next Actions

Repeat q2 slope diagnostics across more deterministic fixtures with denominator
accounting before designing calibrated coverage grids. Continue to keep SR150
blocked until coverage-evaluable denominator evidence and MCSE-calibrated
coverage evidence exist.
