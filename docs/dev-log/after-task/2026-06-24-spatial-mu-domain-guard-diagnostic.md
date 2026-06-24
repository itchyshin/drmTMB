# After Task: Spatial Mu Domain-Guard Diagnostic

## Goal

Check whether the fixed-covariance spatial `mu:x` lower-side endpoint-profile
failures are caused by immediate target-domain non-finiteness or by the
constrained optimizer path, without changing runtime behavior or promoting
interval reliability, coverage, REML, AI-REML, or broad bridge support.

## Implemented

- Added `tools/run-structured-re-spatial-mu-domain-guard-diagnostic.R`, a
  rerunnable lower-side domain-guard diagnostic for the spatial `mu:x` direct
  SD target.
- Wrote the method-level artifact at
  `docs/dev-log/simulation-artifacts/2026-06-24-spatial-mu-domain-guard-diagnostic/structured-re-spatial-mu-domain-guard-diagnostic-results.tsv`.
- Added
  `docs/dev-log/dashboard/structured-re-spatial-mu-domain-guard-diagnostic.tsv`
  with four design rows.
- Added Python validator checks and R conversion-contract tests for the
  sidecar and method artifact.
- Updated the dashboard README and q-series completion map to record that
  fixed-nuisance target-domain evaluations are finite, but guarded constrained
  profiling still does not rescue the problematic seed-202 spatial `mu:x`
  rows.

## Mathematical Contract

The diagnostic covers only the fixed-covariance `spatial()` matched
`mu+sigma` one-slope cell and only the lower side of the `mu:x` direct SD
target. For the finite `smoke_seed102` control and the three seed-202 rows
that failed earlier lower-side diagnostics, it first holds nuisance parameters
at the fitted values and evaluates objective and gradient finiteness across
nine lower target offsets. It then compares two guarded lower-side prototypes:
one that penalizes nonfinite objective evaluations and one that also returns a
zero-gradient fallback at nonfinite points.

## Files Changed

- `tools/run-structured-re-spatial-mu-domain-guard-diagnostic.R`
- `docs/dev-log/simulation-artifacts/2026-06-24-spatial-mu-domain-guard-diagnostic/structured-re-spatial-mu-domain-guard-diagnostic-results.tsv`
- `docs/dev-log/dashboard/structured-re-spatial-mu-domain-guard-diagnostic.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla tools/run-structured-re-spatial-mu-domain-guard-diagnostic.R
air format tools/run-structured-re-spatial-mu-domain-guard-diagnostic.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
rg -n "qseries_.*mu_sigma_one_slope.*(interval_feasible|inference_ready|supported)|mu\\+sigma.*one-slope.*(interval_feasible|inference_ready|supported)|spatial.*mu.*coverage-ready|interval_status\\t(interval_feasible|inference_ready|supported)|coverage_status\\t(inference_ready|supported)" docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-status.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-plan.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-stability-probe.tsv docs/dev-log/dashboard/structured-re-spatial-mu-boundary-diagnostic.tsv docs/dev-log/dashboard/structured-re-spatial-mu-profile-geometry.tsv docs/dev-log/dashboard/structured-re-spatial-mu-profile-strategy.tsv docs/dev-log/dashboard/structured-re-spatial-mu-lower-start-diagnostic.tsv docs/dev-log/dashboard/structured-re-spatial-mu-domain-guard-diagnostic.tsv docs/design/218-structured-q-series-completion-map.md docs/dev-log/dashboard/README.md README.md ROADMAP.md NEWS.md
```

Results: the diagnostic wrote four design rows. Fixed-nuisance objective and
gradient evaluations were finite at all nine lower target offsets for all four
designs. The `smoke_seed102` finite control stayed finite under both guarded
prototype variants. The three problematic seed-202 designs still failed under
both variants with `both X-convergence and relative convergence (5)`.
Conversion-contract tests passed with 1940 assertions, and mission-control
validation passed with four structured RE spatial-`mu` domain-guard diagnostic
rows.

## Tests Of The Tests

The conversion-contract test checks the four-row sidecar, verifies that the
method artifact is identical to the dashboard row set, asserts fixed objective
and gradient finiteness counts, verifies the finite control, verifies the exact
three non-rescued problem rows, and checks that the linked q-series row remains
at fixture parity with planned intervals and coverage. The Python validator
independently checks the same schema, local evidence paths, design identities,
guarded prototype outcomes, unchanged denominator admission, and unchanged
q-series interval/coverage statuses.

## Consistency Audit

The dashboard README and q-series completion map now state that the blocker is
not immediate fixed-nuisance target-domain non-finiteness. The q-series support
cell remains at `interval_status = planned` and `coverage_status = planned`.

## GitHub Issue Maintenance

No GitHub issue action was taken. This is an internal diagnostic under the
q-series completion plan.

## What Did Not Go Smoothly

The guarded prototypes did not rescue any seed-202 problem row. That rules out
a narrow nonfinite-objective penalty as the next sufficient fix and points to
explicit constrained-profile boundary handling or denominator exclusion.

## Team Learning

Domain-guard diagnostics should separate objective-domain evidence from
optimizer-path evidence. A finite fixed-nuisance objective scan is not enough
to admit interval denominators when constrained profiling still fails.

## Known Limitations

This slice does not provide interval reliability, calibrated coverage,
coverage MCSE, REML, AI-REML, broad bridge support, range-estimating spatial
support, labelled structured slope covariance, q4/q6/q8 structured slope
support, or non-Gaussian structured slope support.

## Next Actions

Decide whether to implement explicit constrained-profile boundary handling for
the spatial `mu:x` lower side or keep these seed/design regimes outside
coverage denominators until the interval method has replicated denominator
evidence and MCSE-calibrated coverage evidence.
