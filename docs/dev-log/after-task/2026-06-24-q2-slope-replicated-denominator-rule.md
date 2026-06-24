# After Task: Q2 Slope Replicated-Denominator Rule

## Goal

Define the replicated-denominator rule for a future bivariate Gaussian
structured q2 slope coverage pre-grid, without running coverage or promoting
interval reliability, calibrated coverage, REML, AI-REML, q4/q8, DRAC
execution, SR150 readiness, or broad bridge support.

## Implemented

- Added `tools/run-structured-re-q2-slope-replicated-denominator-rule.R`, a
  rerunnable policy-sidecar generator.
- Wrote
  `docs/dev-log/dashboard/structured-re-q2-slope-replicated-denominator-rule.tsv`
  with 12 target rows.
- Wired the sidecar into `tools/validate-mission-control.py` and
  `tests/testthat/test-structured-re-conversion-contracts.R`.
- Updated the dashboard README, q-series completion map, and check log.

## Mathematical Contract

The rule covers the same exact 12 bivariate Gaussian structured q2 slope
targets as the denominator-admission and denominator-extension sidecars:

- `sd:mu:mu1:provider(0 + x | p | group)`
- `sd:mu:mu2:provider(0 + x | p | group)`
- `cor:provider:cor(mu1:x,mu2:x | p | group)`

Targets with finite smoke profiles and two finite extension variants are
marked `eligible_for_pregrid_with_retention`. The animal and relmat
correlation targets remain `visible_holdout_until_smoke_profile_reconciled`
because their earlier smoke endpoint profiles failed, even though the later
extension variants were finite.

The future coverage pre-grid rule is explicit: use a predeclared
150-replicate seed manifest, retain failed profiles in denominators, retain
nonconverged fits in denominators, retain nonfinite intervals in denominators,
record bootstrap-refit attempts while retaining target denominators, and
require MCSE <= 0.01 before coverage wording.

## Files Changed

- `tools/run-structured-re-q2-slope-replicated-denominator-rule.R`
- `docs/dev-log/dashboard/structured-re-q2-slope-replicated-denominator-rule.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla tools/run-structured-re-q2-slope-replicated-denominator-rule.R
air format tools/run-structured-re-q2-slope-replicated-denominator-rule.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
```

## Evidence Result

The generator wrote 12 dashboard rows. Ten rows are
`eligible_for_pregrid_with_retention`; the animal and relmat correlation rows
are `visible_holdout_until_smoke_profile_reconciled`. Every row keeps
`coverage_evaluable = FALSE`, `coverage_status = not_evaluated`, and
`interval_claim_status = diagnostic_only`.

## Tests Of The Tests

The R conversion-contract test checks the 12-row sidecar, joins it back to the
denominator-admission and denominator-extension sidecars, verifies the 10/2
eligible/holdout split, enforces the 150-replicate seed-manifest rule,
retention policy, MCSE threshold, and unchanged q-series interval, coverage,
and denominator-policy statuses. The Python validator independently checks row
identity, source paths, provider-specific claim boundaries, the two visible
holdouts, and linked support-cell status.

## Consistency Audit

The dashboard README and q-series completion map call this a
replicated-denominator rule, not coverage evidence. The sidecar does not move
support cells from `interval_status = planned`, `coverage_status = planned`,
or `denominator_policy = fixture_not_coverage`.

## GitHub Issue Maintenance

No GitHub issue action was taken. This is internal q-series evidence-ladder
work.

## What Did Not Go Smoothly

The main subtlety is provenance: a later finite extension cannot erase an
earlier failed smoke profile. The rule makes that visible by keeping the two
correlation targets as named holdouts instead of dropping them or admitting
them silently.

## Team Learning

Coverage denominators need two separate policies: target admission and outcome
retention. The new sidecar separates them, which should prevent future
coverage rows from looking better simply because failed profiles or
nonconverged fits disappeared from the denominator.

## Known Limitations

This slice does not run a coverage pre-grid. It does not provide calibrated
coverage, coverage MCSE, interval reliability, REML, AI-REML, broad bridge
support, range-estimating spatial support, pedigree/Ainv bridge marshalling,
relmat Q bridge marshalling, intercept-plus-slope q4/q8 structured slope
support, two-slope support, or non-Gaussian structured slope support.

## Next Actions

Run a small q2 slope coverage pre-grid only after the seed manifest and
retention accounting are fixed in advance. Keep SR150 blocked until
coverage-evaluable denominator evidence and MCSE-calibrated coverage evidence
exist.
