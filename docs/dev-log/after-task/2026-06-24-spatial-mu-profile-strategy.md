# After Task: Spatial Mu Profile Strategy

## Goal

Check whether the existing `auto` and `tmbprofile` profile engines rescue the
fixed-covariance spatial `mu:x` lower-side endpoint-profile failures, without
promoting interval reliability, coverage, REML, AI-REML, or broad bridge
support.

## Implemented

- Added `tools/run-structured-re-spatial-mu-profile-strategy.R`, a rerunnable
  profile-engine strategy diagnostic for the spatial `mu:x` direct SD target.
- Wrote the method-level artifact at
  `docs/dev-log/simulation-artifacts/2026-06-24-spatial-mu-profile-strategy/structured-re-spatial-mu-profile-strategy-results.tsv`.
- Added
  `docs/dev-log/dashboard/structured-re-spatial-mu-profile-strategy.tsv`
  with 12 design-by-engine rows.
- Added Python validator checks and R conversion-contract tests for the
  strategy sidecar and method artifact.
- Updated the dashboard README and q-series completion map to record that
  existing fallback does not rescue the problematic seed-202 spatial `mu:x`
  rows.

## Mathematical Contract

The diagnostic covers only the fixed-covariance `spatial()` matched
`mu+sigma` one-slope cell and only the `mu:x` direct SD target. It compares
three requested profile engines, `endpoint`, `auto`, and `tmbprofile`, for the
finite `smoke_seed102` control and the three seed-202 designs that failed the
lower-side endpoint-profile geometry diagnostic.

## Files Changed

- `tools/run-structured-re-spatial-mu-profile-strategy.R`
- `docs/dev-log/simulation-artifacts/2026-06-24-spatial-mu-profile-strategy/structured-re-spatial-mu-profile-strategy-results.tsv`
- `docs/dev-log/dashboard/structured-re-spatial-mu-profile-strategy.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla tools/run-structured-re-spatial-mu-profile-strategy.R
air format tools/run-structured-re-spatial-mu-profile-strategy.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
rg -n "qseries_.*mu_sigma_one_slope.*(interval_feasible|inference_ready|supported)|mu\\+sigma.*one-slope.*(interval_feasible|inference_ready|supported)|spatial.*mu.*coverage-ready|interval_status\\t(interval_feasible|inference_ready|supported)|coverage_status\\t(inference_ready|supported)" docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-status.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-plan.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-stability-probe.tsv docs/dev-log/dashboard/structured-re-spatial-mu-boundary-diagnostic.tsv docs/dev-log/dashboard/structured-re-spatial-mu-profile-geometry.tsv docs/dev-log/dashboard/structured-re-spatial-mu-profile-strategy.tsv docs/design/218-structured-q-series-completion-map.md docs/dev-log/dashboard/README.md README.md ROADMAP.md NEWS.md
```

Results: the strategy diagnostic wrote 12 rows. The `smoke_seed102` finite
control stayed finite under endpoint, `auto`, and `tmbprofile` engines. The
three seed-202 problematic designs stayed nonfinite under endpoint profiling
and under the existing `auto`/`tmbprofile` fallback path. Conversion-contract
tests passed with 1826 assertions, and mission-control validation passed with
12 structured RE spatial-`mu` profile-strategy rows.

## Tests Of The Tests

The conversion-contract test checks the 12-row sidecar, verifies that the
method artifact is identical to the dashboard row set, asserts the exact three
finite-control and nine non-rescued rows, and checks that the linked q-series
row remains at fixture parity with planned intervals and coverage. The Python
validator independently checks design identities, requested and effective
engine mappings, local evidence paths, non-rescued status classes, unchanged
denominator admission, and unchanged q-series interval/coverage statuses.

## Consistency Audit

The dashboard README and q-series completion map now state that the existing
fallback path is not enough for the seed-202 spatial `mu:x` lower-side problem.
The q-series support cell remains at `interval_status = planned` and
`coverage_status = planned`.

## GitHub Issue Maintenance

No GitHub issue action was taken. This is an internal diagnostic under the
q-series completion plan.

## What Did Not Go Smoothly

The `auto` engine did exactly what it was designed to do, falling back to
`tmbprofile` for the problematic rows, but that did not produce finite
intervals. A stronger strategy will need more than engine selection.

## Team Learning

Profile fallback evidence should be recorded as a separate strategy cell before
changing interval denominator policy. A finite control plus a non-rescued
fallback pattern is useful evidence, but it is still diagnostic evidence.

## Known Limitations

This slice does not provide interval reliability, calibrated coverage,
coverage MCSE, REML, AI-REML, broad bridge support, range-estimating spatial
support, labelled structured slope covariance, q4/q6/q8 structured slope
support, or non-Gaussian structured slope support.

## Next Actions

Design a safer lower-side strategy for spatial `mu:x`, or keep those
seed/design regimes outside coverage denominators until the interval method has
replicated denominator evidence and MCSE-calibrated coverage evidence.
