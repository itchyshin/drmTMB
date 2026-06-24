# After Task: Spatial Mu Boundary Diagnostic

## Goal

Diagnose the fixed-covariance `spatial()` `mu` boundary/profile failures seen
in the matched Gaussian structured `mu+sigma` one-slope stability probe,
without promoting interval reliability, coverage, REML, AI-REML, or broad
bridge support.

## Implemented

- Added `tools/run-structured-re-spatial-mu-boundary-diagnostic.R`, a
  rerunnable focused diagnostic for the spatial `mu:(Intercept)` and `mu:x`
  direct SD targets.
- Wrote the method-level artifact at
  `docs/dev-log/simulation-artifacts/2026-06-24-spatial-mu-boundary-diagnostic/structured-re-spatial-mu-boundary-diagnostic-results.tsv`.
- Added
  `docs/dev-log/dashboard/structured-re-spatial-mu-boundary-diagnostic.tsv`
  with 12 design-by-target status rows.
- Added Python validator checks and R conversion-contract tests for the
  diagnostic sidecar and its method artifact.
- Updated the dashboard README and q-series completion map to keep the
  diagnostic separate from interval reliability and coverage claims.

## Mathematical Contract

The diagnostic covers the fixed-covariance `spatial()` matched `mu+sigma`
one-slope cell only. It compares six deterministic designs: the original finite
smoke seed, the boundary-producing stronger seed, two alternate strong seeds,
a higher-replication version of the boundary seed, and a
`mu`-dominant/low-`sigma` version of the boundary seed. Each design checks
`mu:(Intercept)` and `mu:x` direct SD targets with Wald and endpoint-profile
intervals.

## Files Changed

- `tools/run-structured-re-spatial-mu-boundary-diagnostic.R`
- `docs/dev-log/simulation-artifacts/2026-06-24-spatial-mu-boundary-diagnostic/structured-re-spatial-mu-boundary-diagnostic-results.tsv`
- `docs/dev-log/dashboard/structured-re-spatial-mu-boundary-diagnostic.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla tools/run-structured-re-spatial-mu-boundary-diagnostic.R
air format tools/run-structured-re-spatial-mu-boundary-diagnostic.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
rg -n "qseries_.*mu_sigma_one_slope.*(interval_feasible|inference_ready|supported)|mu\\+sigma.*one-slope.*(interval_feasible|inference_ready|supported)|spatial.*mu.*coverage-ready|interval_status\\t(interval_feasible|inference_ready|supported)|coverage_status\\t(inference_ready|supported)" docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-status.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-plan.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-stability-probe.tsv docs/dev-log/dashboard/structured-re-spatial-mu-boundary-diagnostic.tsv docs/design/218-structured-q-series-completion-map.md docs/dev-log/dashboard/README.md README.md ROADMAP.md NEWS.md
```

Results: the diagnostic wrote 24 method rows and 12 dashboard status rows.
Eight target rows had finite Wald/profile intervals, two had finite Wald but
failed endpoint profile, and two stayed at the Wald/profile boundary. The
boundary-producing strong seed was not a universal spatial `mu` failure:
alternate strong seeds were finite, and higher replication or lower
`sigma` competition rescued Wald intervals. The `mu:x` endpoint profile
remained fragile in the rescued seed-202 variants. Conversion-contract tests
passed with 1732 assertions, and mission-control validation passed with 12
structured RE spatial-`mu` boundary diagnostic rows.

## Tests Of The Tests

The conversion-contract test checks the 12-row sidecar, the 24-row method
artifact, the exact 8 finite / 2 partial / 2 boundary pattern, the
diagnostic-only claim status, and the linked q-series row. The Python validator
independently checks the design identities, intended SDs, positive realized
SDs, local evidence paths, provider boundary wording, and unchanged q-series
interval/coverage statuses.

## Consistency Audit

The dashboard README and q-series completion map now state that the spatial
`mu` issue is seed/design sensitive and endpoint-profile fragile. The q-series
support cell remains at `interval_status = planned` and `coverage_status =
planned`.

## GitHub Issue Maintenance

No GitHub issue action was taken. This is an internal diagnostic under the
q-series completion plan.

## What Did Not Go Smoothly

Higher replication and lower `sigma` competition rescued Wald intervals for
the seed-202 designs, but did not fully rescue the `mu:x` endpoint profile.
That leaves profile geometry, not just point-fit support, as the next
diagnostic target.

## Team Learning

Deterministic interval fixtures need seed/design sensitivity checks before
they become denominator candidates. A finite smoke can prove plumbing for one
cell, but it cannot by itself prove a stable interval denominator.

## Known Limitations

This slice does not provide interval reliability, calibrated coverage,
coverage MCSE, REML, AI-REML, broad bridge support, range-estimating spatial
support, labelled structured slope covariance, q4/q6/q8 structured slope
support, or non-Gaussian structured slope support.

## Next Actions

Inspect the endpoint-profile geometry for the fixed-covariance spatial
`mu:x` target before any replicated coverage-grid design. Keep SR150 blocked
until denominator evidence and MCSE-calibrated coverage evidence exist.
