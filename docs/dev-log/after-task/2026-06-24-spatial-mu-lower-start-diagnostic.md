# After Task: Spatial Mu Lower-Start Diagnostic

## Goal

Check whether lower-side constrained-endpoint start variants rescue the
fixed-covariance spatial `mu:x` endpoint-profile failures, without changing
runtime behavior or promoting interval reliability, coverage, REML, AI-REML,
or broad bridge support.

## Implemented

- Added `tools/run-structured-re-spatial-mu-lower-start-diagnostic.R`, a
  rerunnable lower-side endpoint-start diagnostic for the spatial `mu:x`
  direct SD target.
- Wrote the method-level artifact at
  `docs/dev-log/simulation-artifacts/2026-06-24-spatial-mu-lower-start-diagnostic/structured-re-spatial-mu-lower-start-diagnostic-results.tsv`.
- Added
  `docs/dev-log/dashboard/structured-re-spatial-mu-lower-start-diagnostic.tsv`
  with 16 design-by-start-strategy rows.
- Added Python validator checks and R conversion-contract tests for the
  sidecar and method artifact.
- Updated the dashboard README and q-series completion map to record that
  warm/reset/capped/fixed lower-side starts do not rescue the problematic
  seed-202 spatial `mu:x` rows.

## Mathematical Contract

The diagnostic covers only the fixed-covariance `spatial()` matched
`mu+sigma` one-slope cell and only the lower side of the `mu:x` direct SD
target. It compares the current warm curvature start with reset curvature,
reset capped-step, and reset fixed-step variants for the finite `smoke_seed102`
control and the three seed-202 rows that failed the lower-side endpoint
geometry and profile-engine strategy diagnostics.

## Files Changed

- `tools/run-structured-re-spatial-mu-lower-start-diagnostic.R`
- `docs/dev-log/simulation-artifacts/2026-06-24-spatial-mu-lower-start-diagnostic/structured-re-spatial-mu-lower-start-diagnostic-results.tsv`
- `docs/dev-log/dashboard/structured-re-spatial-mu-lower-start-diagnostic.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla tools/run-structured-re-spatial-mu-lower-start-diagnostic.R
air format tools/run-structured-re-spatial-mu-lower-start-diagnostic.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
rg -n "qseries_.*mu_sigma_one_slope.*(interval_feasible|inference_ready|supported)|mu\\+sigma.*one-slope.*(interval_feasible|inference_ready|supported)|spatial.*mu.*coverage-ready|interval_status\\t(interval_feasible|inference_ready|supported)|coverage_status\\t(inference_ready|supported)" docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-status.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-plan.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-stability-probe.tsv docs/dev-log/dashboard/structured-re-spatial-mu-boundary-diagnostic.tsv docs/dev-log/dashboard/structured-re-spatial-mu-profile-geometry.tsv docs/dev-log/dashboard/structured-re-spatial-mu-profile-strategy.tsv docs/dev-log/dashboard/structured-re-spatial-mu-lower-start-diagnostic.tsv docs/design/218-structured-q-series-completion-map.md docs/dev-log/dashboard/README.md README.md ROADMAP.md NEWS.md
```

Results: the diagnostic wrote 16 lower-side rows. The `smoke_seed102` finite
control stayed finite under the current warm curvature start, reset curvature
start, reset capped-step start, and reset fixed-step start. The three
problematic seed-202 designs still failed under all four start strategies with
`NA/NaN gradient evaluation`. Conversion-contract tests passed with 1875
assertions, and mission-control validation passed with 16 structured RE
spatial-`mu` lower-start diagnostic rows.

## Tests Of The Tests

The conversion-contract test checks the 16-row sidecar, verifies that the
method artifact is identical to the dashboard row set, asserts the exact four
finite-control, four boundary-not-rescued, and eight lower-side-not-rescued
rows, and checks that the linked q-series row remains at fixture parity with
planned intervals and coverage. The Python validator independently checks the
same strategy identities, start modes, step rules, local evidence paths,
non-rescued status classes, unchanged denominator admission, and unchanged
q-series interval/coverage statuses.

## Consistency Audit

The dashboard README and q-series completion map now state that lower-side
start variants do not rescue the seed-202 spatial `mu:x` problem rows. The
q-series support cell remains at `interval_status = planned` and
`coverage_status = planned`.

## GitHub Issue Maintenance

No GitHub issue action was taken. This is an internal diagnostic under the
q-series completion plan.

## What Did Not Go Smoothly

The finite control behaved cleanly, but none of the lower-side start variants
rescued the problem rows. That suggests the next useful runtime review should
look at constrained-optimizer domain guards or explicit boundary handling, not
only start-vector reuse or initial-step size.

## Team Learning

Start-strategy diagnostics should be banked before runtime changes. A failed
rescue is still useful because it prevents the team from spending the next
slice on a plausible but insufficient fix.

## Known Limitations

This slice does not provide interval reliability, calibrated coverage,
coverage MCSE, REML, AI-REML, broad bridge support, range-estimating spatial
support, labelled structured slope covariance, q4/q6/q8 structured slope
support, or non-Gaussian structured slope support.

## Next Actions

Investigate whether constrained optimizer domain guards or explicit lower
boundary handling can make the spatial `mu:x` lower-side profile numerically
well-defined, or keep these seed/design regimes outside coverage denominators
until denominator evidence and MCSE-calibrated coverage evidence exist.
