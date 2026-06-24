# After Task: Sigma-Slope Interval Stability Probe

## Goal

Follow up the sigma-only one-slope interval smoke with stronger deterministic
fixtures for `phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and
K-matrix `relmat()` without promoting interval reliability, calibrated
coverage, REML, AI-REML, matched `mu+sigma` support, q4/q8 support, or broad
bridge support.

## Implemented

Added
`tools/run-structured-re-sigma-slope-interval-stability-probe.R`. The script
fits two deterministic sigma-only fixture variants, records Wald and
endpoint-profile intervals for the direct SD targets, and writes:

- `docs/dev-log/simulation-artifacts/2026-06-24-sigma-slope-interval-stability-probe/structured-re-sigma-slope-interval-stability-probe-results.tsv`
- `docs/dev-log/dashboard/structured-re-sigma-slope-interval-stability-probe.tsv`

The dashboard table has 16 variant-target rows: two variants, four providers,
and two endpoint members (`sigma:(Intercept)` and `sigma:x`). All rows remain
`interval_claim_status = diagnostic_only`.

## Mathematical Contract

The fitted Gaussian distributional model keeps fixed effects in location and a
structured intercept plus one structured slope on residual scale:

```r
y ~ x
sigma ~ provider(1 + x | group, K_or_source = ...)
```

The profiled targets are the sigma-only direct SD names
`sd:sigma:provider(...)`. They are not the matched `mu+sigma` target names
`sd:sigma:sigma:provider(...)`.

## Files Changed

- `tools/run-structured-re-sigma-slope-interval-stability-probe.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/structured-re-sigma-slope-interval-stability-probe.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-24-sigma-slope-interval-stability-probe/structured-re-sigma-slope-interval-stability-probe-results.tsv`

## Checks Run

- `air format tools/run-structured-re-sigma-slope-interval-stability-probe.R`
- `Rscript --vanilla tools/run-structured-re-sigma-slope-interval-stability-probe.R`
- `air format tools/run-structured-re-sigma-slope-interval-stability-probe.R tests/testthat/test-structured-re-conversion-contracts.R`
- `python3 -m py_compile tools/validate-mission-control.py`
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"`
- `python3 tools/validate-mission-control.py`
- Sigma-only overclaim scan across dashboard, design, README, ROADMAP, NEWS,
  tests, and mission-control validator.
- `git diff --check`

All checks passed. The focused test completed with 2371 assertions, and
mission-control reported 16 structured RE sigma-slope interval-stability probe
rows.

## Tests Of The Tests

The new test locks the exact row schema, target spelling, variant count,
provider and endpoint coverage, raw artifact row count, finite Wald/profile
status, diagnostic-only claim boundary, and unchanged linked q-series interval
and coverage statuses.

## Consistency Audit

`docs/dev-log/dashboard/README.md` and
`docs/design/218-structured-q-series-completion-map.md` now describe the
stability probe next to the sigma-only interval smoke. The wording treats the
animal `sigma:x` finite profile result as diagnostic stability evidence only,
not as interval reliability, coverage, or public support.

## GitHub Issue Maintenance

No GitHub issue was opened or updated in this local slice. The work is still
part of the active structured q-series completion branch and remains uncommitted.

## What Did Not Go Smoothly

The first summary command for the generated sidecar used shell double quotes
around R `$` expressions, so the shell expanded column names before R saw them.
The command was rerun with a single-quoted R expression.

## Team Learning

The same formula cell can have target-name differences depending on whether it
is sigma-only or matched `mu+sigma`. Future interval diagnostics should record
the exact `profile_targets()` spelling before any confidence interval logic is
interpreted.

## Known Limitations

This is deterministic stability evidence only. It does not provide interval
reliability, calibrated coverage, a coverage-evaluable denominator, REML,
AI-REML, q4/q8 support, matched `mu+sigma` support, broad bridge support,
range-estimating spatial support, pedigree/Ainv bridge marshalling, or relmat Q
bridge marshalling.

## Next Actions

Run the focused structured conversion tests and mission-control validation,
then decide whether the next narrow slice should add a bootstrap-denominator
admission row for sigma-only one-slope cells or return to runtime q-series gaps.
