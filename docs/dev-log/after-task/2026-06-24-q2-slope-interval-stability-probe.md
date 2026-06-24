# After Task: Q2 Slope Interval Stability Probe

## Goal

Check whether stronger deterministic slope-only q=2 fixtures move the bivariate
Gaussian structured `mu1`/`mu2` SD and correlation targets away from
Wald/profile boundary failures, without promoting interval reliability,
coverage, REML, AI-REML, q4/q8, or broad bridge support.

## Implemented

- Added `tools/run-structured-re-q2-slope-interval-stability-probe.R`, a
  rerunnable stability harness for the four slope-only q=2 provider cells.
- Wrote the method-level artifact at
  `docs/dev-log/simulation-artifacts/2026-06-24-q2-slope-interval-stability-probe/structured-re-q2-slope-interval-stability-probe-results.tsv`.
- Added
  `docs/dev-log/dashboard/structured-re-q2-slope-interval-stability-probe.tsv`
  with 24 variant-target status rows.
- Added mission-control validation and R conversion-contract coverage for the
  stability sidecar and method artifact.
- Updated the dashboard README and q-series completion map with the observed
  boundary/profile result.

## Mathematical Contract

The probe covers two deterministic fixture variants:

- `strong`: `n_each = 28`, `sd_mu1_x = 0.95`, `sd_mu2_x = 0.85`,
  `cor_mu1_mu2_x = 0.25`.
- `stronger_slope`: `n_each = 36`, `sd_mu1_x = 1.35`,
  `sd_mu2_x = 1.15`, `cor_mu1_mu2_x = 0.20`.

Each variant was run for `phylo()`, fixed-covariance `spatial()`, A-matrix
`animal()`, and K-matrix `relmat()` over three targets:

- `sd:mu:mu1:provider(0 + x | p | group)`
- `sd:mu:mu2:provider(0 + x | p | group)`
- `cor:provider:cor(mu1:x,mu2:x | p | group)`

Only Wald and endpoint-profile intervals were run. This probe tests
boundary/profile geometry; it is not bootstrap evidence and not coverage
evidence.

## Files Changed

- `tools/run-structured-re-q2-slope-interval-stability-probe.R`
- `docs/dev-log/simulation-artifacts/2026-06-24-q2-slope-interval-stability-probe/structured-re-q2-slope-interval-stability-probe-results.tsv`
- `docs/dev-log/dashboard/structured-re-q2-slope-interval-stability-probe.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla tools/run-structured-re-q2-slope-interval-stability-probe.R
air format tools/run-structured-re-q2-slope-interval-stability-probe.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
```

Interim probe result: the harness wrote 48 method rows and 24 dashboard status
rows. The first run exposed unexpectedly small fitted structured slope SDs.
After fixing the bivariate structured-effect design multiplication and rerunning
the probe, all 24 variant-target rows had finite Wald/profile status and
`pdHess = TRUE`. This remains diagnostic-only evidence, not interval
reliability or coverage evidence.

## Tests Of The Tests

The conversion-contract test checks the 24-row stability sidecar, the 48-row
method artifact, finite Wald/profile status for every variant-target row, the
diagnostic-only claim status, and the linked q-series rows. The Python
validator independently checks the same variant settings, target identities,
provider-specific boundaries, local evidence paths, and unchanged q-series
interval/coverage statuses.

## Consistency Audit

The q-series completion map and dashboard README now say that the post-fix
stronger q2 slope interval stability probe has finite Wald/profile status for
every variant-target row. The linked support-cell rows remain at
`interval_status = planned` and `coverage_status = planned`.

## GitHub Issue Maintenance

No GitHub issue action was taken. This remains an internal evidence-ladder
diagnostic under the structured q-series completion lane.

## What Did Not Go Smoothly

The stronger fixtures initially appeared not to improve the direct SD interval
path. That was not enough to diagnose boundary geometry, because a runtime
mapping mismatch meant the bivariate likelihood ignored the structured slope
design column. The fixed rerun is a better diagnostic baseline.

## Team Learning

For slope-only q=2, stronger data is a useful diagnostic only after the support
cell has a design-column contribution test. The support-cell workflow caught
that q-neighbour success and extractor labels are not enough; the likelihood
path itself needs provider/member-level checks.

## Known Limitations

This slice does not provide calibrated coverage, interval reliability,
coverage MCSE, REML, AI-REML, broad bridge support, range-estimating spatial
support, pedigree/Ainv bridge marshalling, relmat Q bridge marshalling,
intercept-plus-slope q4/q8 structured slope support, or non-Gaussian
structured slope support.

## Next Actions

Repeat q2 slope diagnostics over more deterministic fixtures and add
denominator accounting before running any coverage-grid or DRAC work. Keep
SR150 blocked until denominator evidence and MCSE-calibrated coverage evidence
exist.
