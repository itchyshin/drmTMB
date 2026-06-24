# After Task: Sigma-Slope Denominator Admission

## Goal

Reconcile the sigma-only one-slope interval smoke and stability probe into a
denominator-admission ledger without promoting interval reliability,
calibrated coverage, REML, AI-REML, matched `mu+sigma` support, q4/q8 support,
or broad bridge support.

## Implemented

Added
`tools/run-structured-re-sigma-slope-denominator-admission.R`. The script reads
the sigma-only interval smoke status and the sigma-only stability probe, then
writes
`docs/dev-log/dashboard/structured-re-sigma-slope-denominator-admission.tsv`.

The ledger has eight rows: four providers by two direct SD endpoint members.
Seven rows are `diagnostic_denominator_candidate`. Animal `sigma:x` remains
`not_admitted_profile_failure` because the first Wald/profile/bootstrap smoke
had endpoint-profile failure for that target.

## Mathematical Contract

The ledger is not a new model fit. It is an evidence reconciliation table for
Gaussian sigma-only structured one-slope cells:

```r
y ~ x
sigma ~ provider(1 + x | group, K_or_source = ...)
```

A row is admitted only when the smoke has finite Wald/profile/bootstrap
intervals and the two stability variants have finite Wald/profile intervals
with positive-definite Hessian status.

## Files Changed

- `tools/run-structured-re-sigma-slope-denominator-admission.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/structured-re-sigma-slope-denominator-admission.tsv`

## Checks Run

- `air format tools/run-structured-re-sigma-slope-denominator-admission.R`
- `Rscript --vanilla tools/run-structured-re-sigma-slope-denominator-admission.R`
- `air format tools/run-structured-re-sigma-slope-denominator-admission.R tests/testthat/test-structured-re-conversion-contracts.R`
- `python3 -m py_compile tools/validate-mission-control.py`
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
- `python3 tools/validate-mission-control.py`
- Sigma-only denominator overclaim scan across dashboard, design, README,
  ROADMAP, NEWS, tests, and mission-control validator.
- `git diff --check`

All checks passed. The focused test completed with 2413 assertions, and
mission-control reported eight structured RE sigma-slope denominator-admission
rows.

## Tests Of The Tests

The new test locks the exact schema, eight target rows, seven
`diagnostic_denominator_candidate` rows, one animal `sigma:x`
`not_admitted_profile_failure` row, unchanged q-series interval and coverage
status, and claim-boundary text that blocks interval reliability and coverage
acceptance.

## Consistency Audit

The dashboard README and q-series completion map now describe the denominator
admission as a diagnostic gate. They do not call the admitted rows
coverage-ready or supported.

## GitHub Issue Maintenance

No GitHub issue was opened or updated in this local slice. The work remains
part of the active uncommitted structured q-series branch.

## What Did Not Go Smoothly

Nothing unusual in this slice. The main judgment call was conservative:
although animal `sigma:x` stabilized under stronger deterministic settings, it
was kept out of denominator admission because the first smoke still had a
profile failure.

## Team Learning

Denominator admission should reconcile multiple evidence tiers instead of
taking the most favorable run. This keeps q-neighbour and half-cell inference
from creeping into public support language.

## Known Limitations

This is not coverage evidence. It does not provide calibrated coverage, MCSE
evidence, interval reliability, REML, AI-REML, q4/q8 support, matched
`mu+sigma` support, broad bridge support, range-estimating spatial support,
pedigree/Ainv bridge marshalling, or relmat Q bridge marshalling.

## Next Actions

Run the focused structured conversion tests and mission-control validation.
After that, the next conservative slice is a sigma-only replicated-denominator
rule or dry-run pre-grid manifest that keeps SR150 blocked.
