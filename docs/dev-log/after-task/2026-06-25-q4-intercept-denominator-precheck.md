# After Task: q4 Intercept Denominator Precheck

## 1. Goal

Record the denominator precheck implied by the first q4 all-four intercept
direct-SD interval smoke, without admitting coverage denominators or promoting
interval reliability, coverage, q4 REML, native-TMB q4 REML, q4 AI-REML,
HSquared AI-REML, broad bridge support, public support, or DRAC/Totoro
execution.

## 2. Implemented

- Added `tools/run-structured-re-q4-intercept-denominator-precheck.R`, which
  derives a dashboard sidecar from
  `structured-re-q4-intercept-interval-diagnostic-status.tsv`.
- Generated
  `docs/dev-log/dashboard/structured-re-q4-intercept-denominator-precheck.tsv`
  with 16 direct-SD rows for the exact q4 all-four intercept phylo,
  fixed-covariance spatial, A-matrix animal, and K-matrix relmat cells.
- Marked phylo, fixed-covariance spatial, and K-matrix relmat rows as
  `not_admitted_pdhess_false`.
- Marked A-matrix animal rows as `not_admitted_bootstrap_nonfinite`.
- Wired the sidecar into mission-control validation and
  `test-structured-re-conversion-contracts.R`.
- Updated the q-series support-cell `next_gate` fields, dashboard README, and
  q-series completion map while leaving q4 intercept interval and coverage
  statuses planned.

## 3a. Decisions and Rejected Alternatives

- I used a derived precheck instead of another runtime fit. The input smoke
  already showed the blocker class by target: `pdHess = FALSE` for phylo,
  fixed-covariance spatial, and K-matrix relmat, and nonfinite bootstrap rows
  for A-matrix animal.
- I did not call this a stability success or denominator admission. The row
  status is a blocking diagnostic, and all rows keep coverage unevaluated.
- I did not include derived-correlation targets in this precheck because the
  current smoke covered direct-SD targets only; derived-correlation interval
  reconstruction remains a separate design gate.

## 4. Files Touched

- `tools/run-structured-re-q4-intercept-denominator-precheck.R`
- `docs/dev-log/dashboard/structured-re-q4-intercept-denominator-precheck.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-25-q4-intercept-denominator-precheck.md`

## 5. Checks Run

- `Rscript --vanilla tools/run-structured-re-q4-intercept-denominator-precheck.R`
  passed and wrote 16 q4 intercept denominator-precheck rows.
- `air format tools/run-structured-re-q4-intercept-denominator-precheck.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with 4,096 assertions, 0 failures, 0 warnings, and 0 skips after the
  stale next-gate expectation was corrected.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-bridge-fixtures|structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with 4,812 assertions, 0 failures, 0 warnings, and 0 skips.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported 16
  structured RE q4 intercept denominator-precheck rows.
- `Rscript --vanilla -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-25-q4-intercept-denominator-precheck.md')"`
  passed.
- `git diff --check` passed.

## 6. Tests of the Tests

The first focused test run failed because an existing q4 intercept parity test
still expected the old `interval diagnostics` next-gate phrase. That failure
proved the dashboard test was sensitive to q-series support-cell wording. I
updated the neighbouring assertion to require
`structured-re-q4-intercept-denominator-precheck.tsv` and denominator-accounting
language, then reran the focused test successfully.

## 7a. Issue Ledger

I searched open GitHub issues with:

- `gh issue list --repo itchyshin/drmTMB --state open --search "q4 intercept denominator" --limit 20`
- `gh issue list --repo itchyshin/drmTMB --state open --search "structured q4 interval" --limit 20`

The search found broad overlapping planning issues (#33, #491, #555, #59) but
no exact q4 intercept denominator-precheck issue. I did not open or comment on
a duplicate issue in this slice; the draft PR will carry the reviewable evidence.

## 8. Consistency Audit

I checked the neighbourhood around the new sidecar:

- The generator derives rows from the interval status sidecar, so it cannot
  silently disagree with the observed smoke statuses.
- The validator checks all 16 rows, exact source-status/source-artifact links,
  provider-specific blocker classes, `coverage_status = not_evaluated`,
  `interval_claim_status = diagnostic_only`, and q-series
  `denominator_policy = fixture_not_coverage`.
- The conversion-contract test cross-checks the precheck rows against the
  interval status sidecar and keeps the q-series interval and coverage statuses
  planned.
- The dashboard README and q-series completion map now describe the precheck as
  diagnostic-only.

I also ran stale-wording searches:

- `rg -n "q4.*intercept.*(coverage|supported|reliable|REML)|native-TMB q4 REML|q4 AI-REML|HSquared AI-REML|denominator admission" README.md ROADMAP.md NEWS.md docs vignettes R tests`
- `rg -n "structured-re-q4-intercept-(interval-diagnostic-status|denominator-precheck)|q4 all-four intercept direct-SD" docs/dev-log/dashboard/README.md docs/design/218-structured-q-series-completion-map.md docs/dev-log/check-log.md docs/dev-log/after-task tests/testthat/test-structured-re-conversion-contracts.R tools/validate-mission-control.py`

The broad search returned many historical guardrail mentions, but no new
unbounded support claim from this slice.

## 9. What Did Not Go Smoothly

The first focused test run exposed a stale neighbouring assertion that still
expected the older interval-diagnostics next gate. That was a useful failure:
the test was doing its job, and the fix was to update the expected wording to
the new denominator-precheck boundary.

## 10. Known Residuals

- No denominator is admitted for q4 all-four intercept direct-SD targets.
- Phylo, fixed-covariance spatial, and K-matrix relmat still need Hessian
  geometry or stability variants before denominator accounting.
- A-matrix animal still needs bootstrap diagnosis before denominator
  accounting.
- Derived-correlation intervals remain blocked on reconstruction design.
- This slice did not run DRAC/Totoro jobs and does not make SR150
  coverage-ready.

## 11. Team Learning

For q-series inference lanes, separate three different nouns in the dashboard:
interval smoke, denominator precheck, and denominator admission. A finite
Wald/profile subset is not enough to admit a denominator when another required
method fails or when `pdHess` blocks the interval methods entirely.
