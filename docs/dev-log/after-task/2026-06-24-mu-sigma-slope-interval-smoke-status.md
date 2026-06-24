# After Task: Matched Mu+Sigma Slope Interval Smoke Status

## Goal

Run and bank the first deterministic interval-smoke status for the matched
Gaussian structured `mu+sigma` one-slope direct SD targets without promoting
interval reliability, coverage, REML, AI-REML, or broad bridge support.

## Implemented

- Added `tools/run-structured-re-mu-sigma-slope-interval-smoke.R`, a
  rerunnable smoke harness for the four matched provider cells.
- Wrote the method-level artifact at
  `docs/dev-log/simulation-artifacts/2026-06-24-mu-sigma-slope-interval-smoke/structured-re-mu-sigma-slope-interval-smoke-results.tsv`.
- Added
  `docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-status.tsv`
  with 16 target-level status rows.
- Added Python validator checks and R conversion-contract tests for the status
  sidecar and its method artifact.
- Updated the dashboard README and q-series completion map to distinguish the
  plan sidecar from actual deterministic smoke status.

## Mathematical Contract

The smoke status covers the 16 direct SD targets formed by four providers
(`phylo()`, fixed-covariance `spatial()`, A-matrix `animal()`, and K-matrix
`relmat()`) and four endpoint members (`mu:(Intercept)`, `mu:x`,
`sigma:(Intercept)`, and `sigma:x`). Each target was checked with Wald,
endpoint-profile, and bootstrap intervals using a deterministic complete-data
Gaussian fixture. Bootstrap used two refits, so it is plumbing and finite-row
evidence only, not calibrated uncertainty.

## Files Changed

- `tools/run-structured-re-mu-sigma-slope-interval-smoke.R`
- `docs/dev-log/simulation-artifacts/2026-06-24-mu-sigma-slope-interval-smoke/structured-re-mu-sigma-slope-interval-smoke-results.tsv`
- `docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-status.tsv`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## Checks Run

```sh
Rscript --vanilla tools/run-structured-re-mu-sigma-slope-interval-smoke.R
air format tools/run-structured-re-mu-sigma-slope-interval-smoke.R tests/testthat/test-structured-re-conversion-contracts.R
python3 -m py_compile tools/validate-mission-control.py
Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts')"
python3 tools/validate-mission-control.py
git diff --check
rg -n "qseries_.*mu_sigma_one_slope.*(interval_feasible|inference_ready|supported)|mu\\+sigma.*one-slope.*(interval_feasible|inference_ready|supported)|interval_status\\t(interval_feasible|inference_ready|supported)|coverage_status\\t(inference_ready|supported)" docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-status.tsv docs/dev-log/dashboard/structured-re-mu-sigma-slope-interval-diagnostic-plan.tsv docs/design/218-structured-q-series-completion-map.md docs/dev-log/dashboard/README.md README.md ROADMAP.md NEWS.md
```

Results: the smoke harness wrote 48 method rows and 16 dashboard status rows;
five targets had finite Wald/profile/bootstrap intervals, one target had finite
Wald/bootstrap with profile failure, and ten targets were bootstrap-only finite
with Wald boundary or profile failure. Conversion-contract tests passed with
1647 assertions, mission-control validation passed with 16 matched `mu+sigma`
slope interval-diagnostic status rows, `git diff --check` passed, and the stale
promotion scan returned no hits.

## Tests Of The Tests

The conversion-contract test checks the 16-row status sidecar, the 48-row
method artifact, the exact finite/nonfinite pattern, the diagnostic-only claim
status, and the linked q-series rows. The Python validator independently checks
the same target identities, provider-specific boundaries, local evidence paths,
and unchanged q-series interval/coverage statuses.

## Consistency Audit

The q-series completion map and dashboard README now say that deterministic
interval smoke has run, but only as diagnostic evidence. The support-cell rows
remain at `interval_status = planned` and `coverage_status = planned`.

## GitHub Issue Maintenance

No GitHub issue action was taken. This is an internal evidence-ladder sidecar
under the existing q-series completion plan rather than a new user-facing
tracker.

## What Did Not Go Smoothly

The first generated method artifact preserved multi-line warning text, which
made the TSV hard to audit. The harness now normalizes condition text to
one-line ASCII before writing artifacts.

## Team Learning

Finite bootstrap rows can coexist with Wald boundary intervals and profile
failures. The status table needs to keep those method-level facts separate so a
finite bootstrap smoke cannot become an interval reliability or coverage claim.

## Known Limitations

This slice does not provide calibrated coverage, interval reliability,
coverage MCSE, REML, AI-REML, broad bridge support, range-estimating spatial
support, pedigree/Ainv bridge marshalling, relmat Q bridge marshalling,
labelled structured slope covariance, q4/q6/q8 structured slope support, or
non-Gaussian structured slope support.

## Next Actions

Diagnose the boundary/profile failures with more stable deterministic fixtures
before considering any replicated coverage-grid design. Keep SR150 blocked
until denominator evidence and MCSE-calibrated coverage evidence exist.
