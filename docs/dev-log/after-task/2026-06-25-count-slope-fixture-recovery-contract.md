# After Task: Count Slope Fixture/Recovery Contract

## 1. Goal

Make the next evidence gate explicit for ordinary Poisson/NB2 q1 structured
`mu` intercept-plus-one-slope cells in `phylo()`, fixed-covariance
`spatial()`, `animal()`, and `relmat()`.

## 2. Implemented

- Added
  `docs/dev-log/dashboard/structured-re-count-slope-fixture-recovery-contract.tsv`
  with eight exact rows: Poisson and NB2 crossed with `phylo()`,
  fixed-covariance `spatial()`, `animal()`, and `relmat()`.
- Linked each contract row to the existing native TMB ML/Laplace point-fit and
  extractor evidence in `tests/testthat/test-count-structured-mu.R`.
- Marked same-target fixture status as `planned_not_banked` and calibrated
  recovery status as `designed_not_run`.
- Added mission-control validator checks for schema, row count, family/provider
  identity, matrix slot, coefficient order, conservative statuses, claim
  boundaries, evidence URLs, and linked q-series support-cell consistency.
- Added a focused R dashboard contract in
  `tests/testthat/test-structured-re-conversion-contracts.R` that cross-checks
  the new sidecar against `structured-re-q-series-support-cells.tsv`.
- Updated the dashboard README, q-series completion map, and check log to make
  the count one-slope next gate visible without widening public claims.

## 3a. Decisions and Rejected Alternatives

- Kept this as a contract slice. The runtime point-fit/extractor evidence was
  already banked by the count structured `mu` one-slope slice; this task records
  the next exact fixture and recovery gate instead of pretending that gate has
  already passed.
- Rejected a provider-agnostic single row. The q-series rule is that family,
  provider, endpoint, estimator, matrix source, and evidence status are part of
  the support cell, so the sidecar uses eight exact rows.
- Kept `bridge_status = unsupported`, `interval_status = unsupported`, and
  `coverage_status = planned`. No fixture parity, calibrated recovery,
  interval reliability, coverage denominator, q2/q4 count covariance, REML,
  AI-REML, broad bridge support, public support, labelled or multiple count
  slopes, structured count scale, or zero-inflated structured-effect evidence
  was added.
- Did not submit Totoro or DRAC jobs. This slice is local contract plumbing;
  compute belongs to a later reviewed recovery/coverage design.

## 4. Files Touched

- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-count-slope-fixture-recovery-contract.tsv`
- `docs/dev-log/after-task/2026-06-25-count-slope-fixture-recovery-contract.md`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `tools/validate-mission-control.py`

## 5. Checks Run

- `air format tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed with 86 structured RE
  q-series cells and 8 structured RE count-slope fixture/recovery contract
  rows.
- `git diff --check` passed.
- `Rscript --no-environ --no-init-file -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-25-count-slope-fixture-recovery-contract.md')"`
  passed.
- `gh issue list --repo itchyshin/drmTMB --search "count structured mu one-slope fixture recovery" --limit 20 --json number,title,state,url,labels`
  returned `[]`.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  could not run because `devtools` is absent from the clean local R library.
  The current local R startup/library state is inconsistent: non-vanilla R
  startup points arm64 R 4.6 at an old
  `x86_64-pc-linux-gnu-library/4.4` library, while `--vanilla` lacks the
  devtools/testthat package stack needed for package tests.

## 6. Tests of the Tests

The new R dashboard contract checks the sidecar schema, exact eight-row
provider/family identity, q1 `mu` one-slope status, coefficient order,
ML/Laplace effective estimator, unsupported bridge and interval status,
planned coverage status, and the `tests/testthat/test-count-structured-mu.R`
evidence URL. It then joins back to `structured-re-q-series-support-cells.tsv`
and verifies that the linked q-series rows keep the same exact formula,
family, provider, route, estimator, point-fit/extractor status, denominator
policy, and unsupported/planned inference statuses.

The Python validator independently checks the same contract at mission-control
time and requires conservative claim-boundary wording for fixture parity,
calibrated recovery, intervals, coverage, q2, q4, REML, AI-REML, public
support, and broad bridge support. Changing a row into a support claim without
changing the evidence ladder should now fail both local dashboard validation
and the package test contract.

## 7a. Issue Ledger

`gh issue list --repo itchyshin/drmTMB --search "count structured mu one-slope fixture recovery" --limit 20 --json number,title,state,url,labels`
returned no matching issues. No issue was opened because this is a narrow
stacked-PR evidence-contract slice tied to the q-series support-cell ledger.

## 8. Consistency Audit

- Checked the exact q-series rows for the eight ordinary count one-slope cells
  in `structured-re-q-series-support-cells.tsv`; the new sidecar links to those
  rows instead of creating a competing ledger.
- Updated `docs/dev-log/dashboard/README.md` and
  `docs/design/218-structured-q-series-completion-map.md` so the new sidecar is
  described as a next-gate contract, not as fixture parity or coverage
  evidence.
- Kept NEWS, roxygen, examples, and formula grammar unchanged because this
  slice does not add runtime model behavior or a user-facing API change.
- Re-ran mission-control validation so the dashboard schema and row counts
  include the new sidecar.

## 9. What Did Not Go Smoothly

Local R execution is still blocked by the current startup/library mismatch.
This slice therefore relies on non-R local validation plus the stacked PR
R-CMD-check workflow for R execution proof. I avoided editing the global R
startup files because that would be outside this package slice.

## 10. Known Residuals

- The eight ordinary count one-slope rows still have only native TMB
  ML/Laplace point-fit and extractor evidence.
- Same-target fixture parity and calibrated recovery diagnostics are named but
  not banked.
- Bridge support, intervals, coverage, q2/q4 count covariance, REML,
  AI-REML, public support, labelled or multiple count slopes, structured count
  scale routes, zero-inflated structured effects, and non-Gaussian REML remain
  unsupported or planned.
- Totoro/DRAC execution remains unsubmitted pending a later race-safety and
  recovery-design review.

## 11. Team Learning

For non-Gaussian structured slopes, a "next gate" should become a row before
the team starts coding the diagnostic. This gives the next runtime or recovery
slice a precise target and prevents native point-fit evidence from drifting
into fixture, interval, coverage, bridge, or public-support language.
