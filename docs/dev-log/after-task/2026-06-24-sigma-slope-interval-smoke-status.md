# After Task: Sigma Slope Interval Smoke Status

## Goal

Run a deterministic interval smoke for Gaussian structured sigma-only
one-slope random effects across `phylo()`, fixed-covariance `spatial()`,
A-matrix `animal()`, and K-matrix `relmat()` without promoting interval
reliability, calibrated coverage, REML, AI-REML, matched `mu+sigma` support,
or broad bridge support.

## Implemented

- Added
  `docs/dev-log/simulation-artifacts/2026-06-24-sigma-slope-interval-smoke/structured-re-sigma-slope-interval-smoke-results.tsv`
  with 24 method rows.
- Added
  `docs/dev-log/dashboard/structured-re-sigma-slope-interval-diagnostic-status.tsv`
  with eight status rows.
- Wired the status sidecar into mission-control validation and R conversion
  contracts.

## Mathematical Contract

The smoke covers two direct SD targets for each provider:

- `sd:sigma:provider(1 | group)`
- `sd:sigma:provider(0 + x | group)`

Each target runs Wald, endpoint-profile, and two-refit bootstrap intervals at
the diagnostic level. A finite interval row is not an interval reliability or
coverage claim.

## Files Changed

- `tools/run-structured-re-sigma-slope-interval-smoke.R`
- `docs/dev-log/dashboard/structured-re-sigma-slope-interval-diagnostic-plan.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-sigma-slope-interval-smoke/structured-re-sigma-slope-interval-smoke-results.tsv`
- `docs/dev-log/dashboard/structured-re-sigma-slope-interval-diagnostic-status.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla tools/run-structured-re-sigma-slope-interval-smoke.R
air format tools/run-structured-re-sigma-slope-interval-smoke.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
```

## Evidence Result

All eight direct SD targets were found. All provider fits converged and had
`pdHess = TRUE`. Seven targets had finite Wald/profile/bootstrap intervals.
Animal `sigma:x` had finite Wald/bootstrap intervals but endpoint-profile
failure. All rows keep `interval_claim_status = diagnostic_only`.

## Tests Of The Tests

The R contract checks the raw 24-row method artifact, the eight-row status
sidecar, the seven/one finite/profile-failed split, the corrected target names,
and unchanged q-series interval, coverage, and denominator-policy statuses.
The Python validator independently checks target identity, method status,
claim boundaries, evidence paths, and linked support-cell status.

## Consistency Audit

The documentation calls this sigma-only interval smoke evidence. It does not
upgrade the sigma one-slope q-series cells beyond planned interval and
coverage status.

## GitHub Issue Maintenance

No GitHub issue action was taken. This is internal q-series evidence-ladder
work.

## What Did Not Go Smoothly

The first target-name attempt reused matched `mu+sigma` profile target names,
which caused every interval method to report an unknown target. The corrected
sigma-only target names resolved this and turned the diagnostic into real
target-level evidence.

## Team Learning

Neighbouring q-cells can share formula grammar but still have different
extractor/profile target identities. The support-cell map should keep target
identity explicit for each cell.

## Known Limitations

This slice does not provide interval reliability, calibrated coverage,
coverage-evaluable denominator evidence, REML, AI-REML, broad bridge support,
range-estimating spatial support, pedigree/Ainv bridge marshalling, relmat Q
bridge marshalling, matched `mu+sigma` support, q4/q8 structured slope support,
two-slope support, or non-Gaussian structured slope support.

## Next Actions

Run a small stability probe or targeted animal `sigma:x` profile diagnostic
before designing any sigma-only denominator or coverage pre-grid.
