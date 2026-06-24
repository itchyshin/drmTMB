# After Task: Sigma Slope Interval Diagnostic Plan

## Goal

Name the exact Gaussian structured sigma-only one-slope interval targets for
`phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix
`relmat()` before interpreting any interval smoke evidence.

## Implemented

- Added
  `docs/dev-log/dashboard/structured-re-sigma-slope-interval-diagnostic-plan.tsv`
  through `tools/run-structured-re-sigma-slope-interval-smoke.R`.
- Named two direct SD targets per provider: `sigma:(Intercept)` and
  `sigma:x`.
- Linked the plan to the existing sigma-slope parity fixture cells.

## Mathematical Contract

Sigma-only profile target names are not the same as matched `mu+sigma` target
names. The sigma-only registry uses:

- `sd:sigma:provider(1 | group)`
- `sd:sigma:provider(0 + x | group)`

Matched `mu+sigma` uses `sd:sigma:sigma:provider(...)`, so that evidence
cannot be copied back to the sigma-only half-cell.

## Files Changed

- `tools/run-structured-re-sigma-slope-interval-smoke.R`
- `docs/dev-log/dashboard/structured-re-sigma-slope-interval-diagnostic-plan.tsv`
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

## Tests Of The Tests

The R contract checks the eight planned targets, corrected sigma-only profile
target names, fit evidence requirements, denominator fields, and linked
support-cell boundaries. The Python validator independently checks the same
row identities and provider-specific unsupported-scope clauses.

## Consistency Audit

The dashboard README and q-series completion map both state that this is a
target plan only and that matched `mu+sigma` profile names do not generalize
to sigma-only.

## GitHub Issue Maintenance

No GitHub issue action was taken. This is internal q-series evidence-ladder
work.

## What Did Not Go Smoothly

The first smoke attempt used matched `mu+sigma` target names and found zero
targets. That was useful evidence: half-cells need target-registry checks
before interval claims.

## Team Learning

Every q-cell needs its own target identity row, even when neighbouring cells
look syntactically similar.

## Known Limitations

The plan does not provide interval reliability, calibrated coverage, REML,
AI-REML, matched `mu+sigma` support, q4/q8 support, or broad bridge support.

## Next Actions

Use the paired smoke-status sidecar to decide whether to run additional
deterministic sigma-only fixtures or diagnose the animal `sigma:x` endpoint
profile failure first.
