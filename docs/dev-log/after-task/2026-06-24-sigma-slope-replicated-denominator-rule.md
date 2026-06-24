# After Task: Sigma-Slope Replicated Denominator Rule

## Goal

Record the replicated-denominator rule for sigma-only one-slope structured
random-effect targets without promoting interval reliability, calibrated
coverage, REML, AI-REML, matched `mu+sigma` support, q4/q8 support, broad
bridge support, DRAC execution, or SR150 readiness.

## Implemented

Added
`tools/run-structured-re-sigma-slope-replicated-denominator-rule.R`. The script
reads the sigma-only denominator-admission ledger and stability probe, then
writes
`docs/dev-log/dashboard/structured-re-sigma-slope-replicated-denominator-rule.tsv`.

The table has eight rows. Seven rows are
`eligible_for_pregrid_with_retention`; animal `sigma:x` remains
`visible_holdout_until_smoke_profile_reconciled`.

## Mathematical Contract

This ledger does not fit a new model. It records the denominator rule for the
Gaussian sigma-only structured one-slope cells:

```r
y ~ x
sigma ~ provider(1 + x | group, K_or_source = ...)
```

Any future coverage denominator must retain failed profiles, nonconverged fits,
nonfinite intervals, and bootstrap refit attempts.

## Files Changed

- `tools/run-structured-re-sigma-slope-replicated-denominator-rule.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/structured-re-sigma-slope-replicated-denominator-rule.tsv`

## Checks Run

- `air format tools/run-structured-re-sigma-slope-replicated-denominator-rule.R`
- `Rscript --vanilla tools/run-structured-re-sigma-slope-replicated-denominator-rule.R`
- `air format tools/run-structured-re-sigma-slope-replicated-denominator-rule.R tools/run-structured-re-sigma-slope-coverage-pregrid-dry-run.R tests/testthat/test-structured-re-conversion-contracts.R`
- `python3 -m py_compile tools/validate-mission-control.py`
- `python3 tools/validate-mission-control.py`
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
- Sigma-only replicated-denominator/pregrid overclaim scan across dashboard,
  design, README, ROADMAP, NEWS, tests, and mission-control validator.
- `git diff --check`

All checks passed. Mission-control reported eight structured RE sigma-slope
replicated-denominator rule rows, and the focused test completed with 2513
assertions.

## Tests Of The Tests

The new test locks the schema, eight target rows, seven eligible rows, one
animal `sigma:x` holdout, retention policy fields, MCSE threshold, and unchanged
linked q-series interval and coverage statuses.

## Consistency Audit

The dashboard README and q-series completion map now describe the replicated
denominator rule immediately after sigma denominator admission. The wording
does not call any row coverage-ready or supported.

## GitHub Issue Maintenance

No GitHub issue was opened or updated. This remains local q-series completion
work on the active branch.

## What Did Not Go Smoothly

Nothing unusual. The main choice was to omit a separate sigma denominator
extension table and use the two existing stability variants as the replicated
evidence source.

## Team Learning

Sigma-only target identity needs its own denominator artifacts rather than a
q2-shaped table, because the exact identity is `direct_sd_target` plus
`profile_target`, not a bivariate covariance estimand.

## Known Limitations

This is not coverage evidence. It does not provide calibrated coverage, MCSE
evidence from executed fits, interval reliability, REML, AI-REML, q4/q8
support, matched `mu+sigma` support, broad bridge support, range-estimating
spatial support, pedigree/Ainv bridge marshalling, or relmat Q bridge
marshalling.

## Next Actions

Run the focused structured conversion tests, mission-control validation, and
overclaim scans. Then keep the dry-run manifest separate from any actual DRAC
or local coverage execution.
