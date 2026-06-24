# After Task: Spatial Mu Profile Geometry

## Goal

Diagnose the fixed-covariance spatial `mu:x` endpoint-profile failures by
separating lower and upper constrained-profile crossings, without promoting
interval reliability, coverage, REML, AI-REML, or broad bridge support.

## Implemented

- Added `tools/run-structured-re-spatial-mu-profile-geometry.R`, a rerunnable
  side-specific endpoint-profile geometry diagnostic for the spatial `mu:x`
  direct SD target.
- Wrote the method-level artifact at
  `docs/dev-log/simulation-artifacts/2026-06-24-spatial-mu-profile-geometry/structured-re-spatial-mu-profile-geometry-results.tsv`.
- Added
  `docs/dev-log/dashboard/structured-re-spatial-mu-profile-geometry.tsv`
  with 12 design-by-side rows.
- Added Python validator checks and R conversion-contract tests for the
  geometry sidecar and method artifact.
- Updated the dashboard README and q-series completion map to record the
  lower-side profile geometry failure without changing support claims.

## Mathematical Contract

The diagnostic covers the fixed-covariance `spatial()` matched `mu+sigma`
one-slope cell and only the `mu:x` direct SD target. It reuses the six designs
from the spatial `mu` boundary diagnostic, then evaluates endpoint-profile
lower and upper crossings separately using the same constrained optimizer path
as `confint(method = "profile", profile_engine = "endpoint")`.

## Files Changed

- `tools/run-structured-re-spatial-mu-profile-geometry.R`
- `docs/dev-log/simulation-artifacts/2026-06-24-spatial-mu-profile-geometry/structured-re-spatial-mu-profile-geometry-results.tsv`
- `docs/dev-log/dashboard/structured-re-spatial-mu-profile-geometry.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla tools/run-structured-re-spatial-mu-profile-geometry.R
air format tools/run-structured-re-spatial-mu-profile-geometry.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
rg -n "qseries_.*mu_sigma_one_slope.*(interval_feasible|inference_ready|supported)|mu\\+sigma.*one-slope.*(interval_feasible|inference_ready|supported)|spatial.*mu.*coverage-ready|interval_status\\t(interval_feasible|inference_ready|supported)|coverage_status\\t(inference_ready|supported)" docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-status.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-plan.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-stability-probe.tsv docs/dev-log/dashboard/structured-re-spatial-mu-boundary-diagnostic.tsv docs/dev-log/dashboard/structured-re-spatial-mu-profile-geometry.tsv docs/design/218-structured-q-series-completion-map.md docs/dev-log/dashboard/README.md README.md ROADMAP.md NEWS.md
```

Results: the diagnostic wrote 12 geometry rows. All six upper endpoint-profile
crossings succeeded. Three lower crossings succeeded, and three lower
crossings failed with constrained-optimizer `NA/NaN gradient evaluation`:
`strong_seed202`, `strong_n50_seed202`, and `mu_dominant_seed202`. The
`strong_seed202` lower side is the most boundary-like case: the fitted `mu:x`
SD is effectively zero and the curvature-derived initial step is enormous.
Conversion-contract tests passed with 1777 assertions, and mission-control
validation passed with 12 structured RE spatial-`mu` profile-geometry rows.

## Tests Of The Tests

The conversion-contract test checks the 12-row sidecar, verifies that the
method artifact is identical to the dashboard row set, asserts the 9 OK sides
and 3 lower-side optimizer errors, and checks the linked q-series row remains
at fixture parity with planned intervals and coverage. The Python validator
independently checks the same side identities, provider boundary wording,
local evidence paths, numeric geometry fields, and unchanged support-cell
statuses.

## Consistency Audit

The dashboard README and q-series completion map now state that spatial `mu:x`
endpoint-profile failures are lower-side constrained-optimizer failures. The
target remains direct and `profile_ready`; the failure is in the constrained
endpoint crossing, not in target discovery.

## GitHub Issue Maintenance

No GitHub issue action was taken. This is an internal diagnostic under the
q-series completion plan.

## What Did Not Go Smoothly

The profile target is officially profile-ready, but the lower-side constrained
optimizer can still fail for seed/design-sensitive spatial `mu:x` fits. The
status map therefore needs a finer distinction than target readiness alone.

## Team Learning

Endpoint-profile diagnostics should record lower and upper sides separately
before any interval denominator is considered. A two-sided interval failure can
hide an asymmetric geometry problem.

## Known Limitations

This slice does not provide interval reliability, calibrated coverage,
coverage MCSE, REML, AI-REML, broad bridge support, range-estimating spatial
support, labelled structured slope covariance, q4/q6/q8 structured slope
support, or non-Gaussian structured slope support.

## Next Actions

Decide whether a safer lower-side endpoint-profile strategy is possible for
spatial `mu:x`, or whether coverage-denominator design should exclude those
seed/design regimes until a stronger profiling method is available.
