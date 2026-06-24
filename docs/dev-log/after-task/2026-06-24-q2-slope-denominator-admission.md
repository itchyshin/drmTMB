# After Task: Q2 Slope Denominator Admission

## Goal

Bank the first denominator-admission ledger for bivariate Gaussian structured
q2 slope-only `mu1`/`mu2` interval diagnostics after the slope-design runtime
fix, without promoting interval reliability, coverage, REML, AI-REML, q4/q8,
or broad bridge support.

## Implemented

- Added `tools/run-structured-re-q2-slope-denominator-admission.R`, a
  rerunnable generator that joins the post-fix interval-smoke and stability
  sidecars.
- Added
  `docs/dev-log/dashboard/structured-re-q2-slope-denominator-admission.tsv`
  with 12 target-level denominator rows.
- Wired the new sidecar into `tools/validate-mission-control.py` and
  `tests/testthat/test-structured-re-conversion-contracts.R`.
- Updated the dashboard README, q-series completion map, and check log.

## Mathematical Contract

The sidecar covers the same exact q2 slope target set as the interval smoke:

- `sd:mu:mu1:provider(0 + x | p | group)`
- `sd:mu:mu2:provider(0 + x | p | group)`
- `cor:provider:cor(mu1:x,mu2:x | p | group)`

for `phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix
`relmat()`.

A target is marked `diagnostic_denominator_candidate` only when the
single-fixture smoke row has finite Wald, endpoint-profile, and bootstrap
diagnostics and both stability variants have finite Wald/profile diagnostics
with `pdHess = TRUE`. A target is marked `not_admitted_profile_failure` when
the smoke profile still fails.

## Files Changed

- `tools/run-structured-re-q2-slope-denominator-admission.R`
- `docs/dev-log/dashboard/structured-re-q2-slope-denominator-admission.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla tools/run-structured-re-q2-slope-denominator-admission.R
air format tools/run-structured-re-q2-slope-denominator-admission.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
```

## Evidence Result

The ledger has 12 target rows. Ten rows are
`diagnostic_denominator_candidate`; the animal and relmat correlation rows are
`not_admitted_profile_failure`. All rows keep
`coverage_status = not_evaluated` and `interval_claim_status =
diagnostic_only`.

## Tests Of The Tests

The R conversion-contract test checks the 12-row ledger, verifies the 10/2
candidate/admission split, cross-checks smoke statuses against
`structured-re-q2-slope-interval-diagnostic-status.tsv`, cross-checks stability
counts against `structured-re-q2-slope-interval-stability-probe.tsv`, and
verifies that the linked q-series support cells remain at
`interval_status = planned`, `coverage_status = planned`, and
`denominator_policy = fixture_not_coverage`.

The Python validator independently checks field names, row identities, source
artifact paths, provider-specific claim boundaries, denominator status, and the
unchanged support-cell interval and coverage statuses.

## Consistency Audit

The dashboard README and q-series completion map describe the sidecar as
denominator triage only. The sidecar does not admit coverage-evaluable
denominators, does not compute coverage, and does not move any public support
claim.

## GitHub Issue Maintenance

No GitHub issue action was taken. This is an internal evidence-ladder sidecar
for the structured q-series completion lane.

## What Did Not Go Smoothly

The two correlation targets that failed endpoint profiling in the smoke run are
now explicitly held out of denominator admission. That keeps the finite
stability probe from being read as enough evidence for coverage design.

## Team Learning

Finite diagnostics need an explicit denominator-admission row before any
coverage-grid planning. The support-cell row alone should not carry this
burden, because it describes capability status rather than the denominator
logic behind a future coverage study.

## Known Limitations

This slice does not provide calibrated coverage, interval reliability, coverage
MCSE, REML, AI-REML, broad bridge support, range-estimating spatial support,
pedigree/Ainv bridge marshalling, relmat Q bridge marshalling,
intercept-plus-slope q4/q8 structured slope support, two-slope support, or
non-Gaussian structured slope support.

## Next Actions

Repeat the q2 slope diagnostics across more deterministic fixtures before
promoting any target into coverage-evaluable denominator evidence. Keep SR150
blocked until coverage-evaluable denominator evidence and MCSE-calibrated
coverage evidence exist.
