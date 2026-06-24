# After Task: Matched Mu+Sigma Slope Interval Diagnostic Plan

## Goal

Add a machine-checked target inventory for the first matched Gaussian
structured `mu+sigma` one-slope interval diagnostics without promoting any
interval, coverage, REML, AI-REML, or broad bridge claim.

## Implemented

- Added
  `docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-plan.tsv`
  with 16 direct SD targets: four providers by four endpoint members.
- Added dashboard validation and conversion-contract checks that keep the rows
  at `status = planned` with `current_blocker =
  interval_diagnostics_not_run`.
- Updated the dashboard README and q-series completion map so the target-level
  interval plan sits after fixture parity and before any finite-interval or
  calibrated coverage evidence.

## Mathematical Contract

The diagnostic plan targets only direct SD profile targets for matched
`q1_plus_q1` location-scale cells. The endpoint members are
`mu:(Intercept)`, `mu:x`, `sigma:(Intercept)`, and `sigma:x`; the providers are
`phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix
`relmat()`. The plan names Wald, profile, and bootstrap smoke methods plus
denominator and MCSE fields required before any calibrated coverage wording.

## Files Changed

- `docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-plan.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
air format tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
rg -n "mu\\+sigma.*interval_(feasible|ready|supported)|interval_status\\tinterval_feasible|coverage_status\\tsupported|qseries_.*mu_sigma_one_slope.*interval_feasible" docs/dev-log/dashboard docs/design README.md ROADMAP.md NEWS.md
```

Results: conversion-contract tests passed with 1602 assertions,
mission-control validation passed with 16 matched `mu+sigma` slope
interval-diagnostic plan rows, `git diff --check` passed, and the stale
promotion scan returned no hits.

## Tests Of The Tests

The conversion-contract test fails if the sidecar loses a provider, endpoint
member, direct SD target, interval method, denominator field, conservative
claim boundary, or linked q-series `planned` interval/coverage status. The
Python validator independently checks the same schema and exact profile-target
mapping.

## Consistency Audit

The q-series completion map and dashboard README now describe the interval
diagnostic plan as the next gate after matched one-slope fixture parity. They
do not claim finite intervals, interval reliability, interval coverage, REML,
AI-REML, broad bridge support, range-estimating spatial support, pedigree/Ainv
bridge marshalling, or relmat Q bridge marshalling.

## GitHub Issue Maintenance

No GitHub issue action was taken for this plan-only sidecar. The work is
tracked by the q-series support-cell map and its validator-owned dashboard row.

## What Did Not Go Smoothly

The first focused contract run caught inconsistent claim-boundary wording in
the non-phylo rows. Those rows semantically blocked interval reliability, but
did not use the exact machine-checked phrase "no interval reliability." The
sidecar now uses that phrase for every provider.

## Team Learning

Treat interval work as target-level evidence. A fixture-passing matched cell
still needs its direct SD targets, interval methods, denominators, and MCSE
fields named before anybody runs coverage language forward.

## Known Limitations

No interval diagnostics were run. No finite intervals, interval reliability,
coverage, REML, AI-REML, labelled structured slope covariance, broad bridge
support, relmat Q bridge marshalling, q4/q6/q8 slope blocks, or non-Gaussian
structured slope cells are promoted by this slice.

## Next Actions

Run deterministic Wald/profile/bootstrap smoke diagnostics for the 16 direct
SD targets, then review the finite-interval denominator evidence before any
coverage-grid design or public support wording.
