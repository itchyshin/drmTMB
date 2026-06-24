# After Task: Matched Mu+Sigma Slope Interval Stability Probe

## Goal

Diagnose whether the matched Gaussian structured `mu+sigma` one-slope
boundary/profile interval failures from the first smoke are fixture-strength
dependent, without promoting interval reliability, coverage, REML, AI-REML, or
broad bridge support.

## Implemented

- Added `tools/run-structured-re-mu-sigma-slope-interval-stability-probe.R`, a
  rerunnable deterministic probe with two stronger fixture variants.
- Wrote the method-level artifact at
  `docs/dev-log/simulation-artifacts/2026-06-24-mu-sigma-slope-interval-stability-probe/structured-re-mu-sigma-slope-interval-stability-probe-results.tsv`.
- Added
  `docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-stability-probe.tsv`
  with 32 target-by-variant status rows.
- Added Python validator checks and R conversion-contract tests for the probe
  sidecar and its method artifact.
- Updated the dashboard README and q-series completion map to separate the
  stronger-fixture probe from interval reliability or coverage evidence.

## Mathematical Contract

The probe covers the same 16 direct SD targets as the matched `mu+sigma`
interval-smoke sidecar: four providers (`phylo()`, fixed-covariance
`spatial()`, A-matrix `animal()`, and K-matrix `relmat()`) crossed with
`mu:(Intercept)`, `mu:x`, `sigma:(Intercept)`, and `sigma:x`. Each target is
run under two deterministic stronger-signal variants and checked with Wald and
endpoint-profile intervals only.

## Files Changed

- `tools/run-structured-re-mu-sigma-slope-interval-stability-probe.R`
- `docs/dev-log/simulation-artifacts/2026-06-24-mu-sigma-slope-interval-stability-probe/structured-re-mu-sigma-slope-interval-stability-probe-results.tsv`
- `docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-stability-probe.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla tools/run-structured-re-mu-sigma-slope-interval-stability-probe.R
air format tools/run-structured-re-mu-sigma-slope-interval-stability-probe.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
rg -n "qseries_.*mu_sigma_one_slope.*(interval_feasible|inference_ready|supported)|mu\\+sigma.*one-slope.*(interval_feasible|inference_ready|supported)|interval_status\\t(interval_feasible|inference_ready|supported)|coverage_status\\t(inference_ready|supported)" docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-status.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-plan.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-stability-probe.tsv docs/design/218-structured-q-series-completion-map.md docs/dev-log/dashboard/README.md README.md ROADMAP.md NEWS.md
```

Results: the probe wrote 64 method rows and 32 dashboard status rows. Twenty
eight variant-target rows had finite Wald/profile intervals. Four rows stayed
nonfinite: fixed-covariance `spatial()` `mu:(Intercept)` and `mu:x` under both
stronger fixture variants. Conversion-contract tests passed with 1688
assertions, and mission-control validation passed with 32 matched `mu+sigma`
slope interval-stability probe rows. The q-series support cells remain at
`interval_status = planned` and `coverage_status = planned`.

## Tests Of The Tests

The conversion-contract test checks the 32-row probe sidecar, the 64-row
method artifact, the exact 28 finite and 4 persistent spatial-`mu` boundary
pattern, the diagnostic-only claim status, and the linked q-series rows. The
Python validator independently checks the same target identities,
provider-specific boundaries, local evidence paths, and unchanged q-series
interval/coverage statuses.

## Consistency Audit

The dashboard README and q-series completion map now state that stronger
fixtures remove most previous boundary/profile failures, while preserving the
fixed-covariance spatial `mu` boundary/profile issue as a blocker before any
coverage-grid design.

## GitHub Issue Maintenance

No GitHub issue action was taken. This is an internal evidence-ladder
diagnostic under the q-series completion plan.

## What Did Not Go Smoothly

The persistent spatial `mu` boundary/profile behavior survived both stronger
fixture variants. That is useful evidence, but it blocks any attempt to turn
the matched `mu+sigma` interval smoke into reliability or coverage language.

## Team Learning

Interval diagnostics need a stabilization probe before coverage-grid design.
In this slice, stronger signals separated fixture-strength failures from a
persistent provider/endpoint issue, which is exactly why status cells should be
more granular than q-dimension labels.

## Known Limitations

This slice does not provide interval reliability, calibrated coverage,
coverage MCSE, REML, AI-REML, broad bridge support, range-estimating spatial
support, pedigree/Ainv bridge marshalling, relmat Q bridge marshalling,
labelled structured slope covariance, q4/q6/q8 structured slope support, or
non-Gaussian structured slope support.

## Next Actions

Diagnose fixed-covariance spatial `mu` boundary/profile behavior before any
replicated coverage-grid design. Keep SR150 blocked until denominator evidence
and MCSE-calibrated coverage evidence exist.
