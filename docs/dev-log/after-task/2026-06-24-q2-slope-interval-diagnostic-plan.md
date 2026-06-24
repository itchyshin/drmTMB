# After Task: Q2 Slope Interval Diagnostic Plan

## Goal

Name the interval diagnostic targets for the exact bivariate Gaussian
structured slope-only q=2 `mu1`/`mu2` cells before any interval smoke or
coverage run.

## Implemented

- Added `docs/dev-log/dashboard/structured-re-q2-slope-interval-diagnostic-plan.tsv`.
- Added 12 planned diagnostic rows: `sd_mu1_x`, `sd_mu2_x`, and
  `cor_mu1_mu2_x` for `phylo()`, fixed-covariance `spatial()`, A-matrix
  `animal()`, and K-matrix `relmat()`.
- Added mission-control validation for row count, target names, profile target
  strings, provider boundaries, denominator fields, and linked q-series rows.
- Added conversion-contract coverage and dashboard/design-map prose.

## Mathematical Contract

The target set belongs only to the slope-only q=2 block:

```r
mu1 = y1 ~ x + provider(0 + x | p | group, ...)
mu2 = y2 ~ x + provider(0 + x | p | group, ...)
```

The planned interval targets are the two slope SDs and the slope-slope
correlation:

- `sd:mu:mu1:provider(0 + x | p | group)`
- `sd:mu:mu2:provider(0 + x | p | group)`
- `cor:provider:cor(mu1:x,mu2:x | p | group)`

## Files Changed

- `docs/dev-log/dashboard/structured-re-q2-slope-interval-diagnostic-plan.tsv`
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
```

Results:

- `structured-re-conversion-contracts`: 2,027 assertions passed.
- `python3 tools/validate-mission-control.py`: passed, with 12 structured RE
  q2 slope interval-diagnostic plan rows.

## Tests Of The Tests

The conversion-contract test requires all 12 planned targets, the exact profile
target strings already exercised by the provider native tests, and the linked
q-series rows to remain `interval_status = planned` and
`coverage_status = planned`.

## Consistency Audit

The plan does not change q-series support status. It only records what a future
diagnostic smoke must evaluate and which denominator fields must exist before
coverage wording can be considered.

## GitHub Issue Maintenance

No issue action was taken. This remains part of the local structured q-series
completion lane.

## What Did Not Go Smoothly

The existing `mu+sigma` interval plan schema was close but not quite right for
q2 because q2 has a correlation target as well as SD targets. A q2-specific
`estimand` field keeps that distinction clearer.

## Team Learning

Interval diagnostics should be planned at the target grain before any smoke run
starts. That prevents a future finite SD profile from being mistaken for
coverage or correlation-interval support.

## Known Limitations

- No interval smoke was run.
- No interval reliability or coverage is claimed.
- No REML, AI-REML, broad bridge support, range-estimating spatial support,
  pedigree/Ainv bridge marshalling, relmat Q bridge marshalling, or q4/q8
  support was added.

## Next Actions

1. Run a deterministic q2 slope interval smoke over the 12 planned targets.
2. Split finite SD and correlation behavior in the resulting diagnostic sidecar.
3. Keep calibrated coverage blocked until denominator and MCSE evidence exist.
