# After Task: Sigma Slope Coverage Dispatch Review

## 1. Goal

Bank a dispatch-review gate for the sigma-only one-slope coverage pre-grid
without submitting Totoro or DRAC jobs and without promoting interval or
coverage support.

## 2. Implemented

The slice adds a rerunnable generator and dashboard sidecar for the seven
eligible sigma-only one-slope pre-grid targets. The dispatch review records the
planned Totoro/DRAC backends, provider shards, seed range, retained failure
classes, and not-executed status before any compute job is launched.

## 3. Mathematical Contract

The target cells are the exact Gaussian structured residual-scale one-slope
cells already listed in the support-cell registry: `sigma` random effects for
`phylo()`, fixed-covariance `spatial()`, `animal()`, and `relmat()`, with
direct SD targets for `sigma:(Intercept)` and `sigma:x`. Animal `sigma:x`
remains excluded from the executable dispatch manifest because it is still the
visible holdout from the first endpoint-profile smoke.

## 3a. Decisions and Rejected Alternatives

The accepted route was to add a validation-backed dispatch-review gate before
running any compute jobs.

Rejected alternatives:

- Do not submit Totoro or DRAC jobs from this slice.
- Do not include the animal `sigma:x` holdout in the executable target
  manifest.
- Do not treat a dispatch manifest as coverage-evaluable denominator evidence.
- Do not promote interval reliability, calibrated coverage, q4/q8 support,
  REML, AI-REML, broad bridge support, public support, or SR150 readiness.

## 4. Files Touched

- `tools/plan-structured-re-sigma-slope-coverage-dispatch-review.R`
- `docs/dev-log/dashboard/structured-re-sigma-slope-coverage-dispatch-review.tsv`
- `docs/dev-log/simulation-artifacts/2026-06-25-sigma-slope-coverage-dispatch-review/structured-re-sigma-slope-coverage-dispatch-target-manifest.tsv`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `Rscript --vanilla tools/plan-structured-re-sigma-slope-coverage-dispatch-review.R`
  wrote seven dispatch-review rows and seven target-manifest rows.
- `air format tools/plan-structured-re-sigma-slope-coverage-dispatch-review.R tests/testthat/test-structured-re-conversion-contracts.R`
  passed.
- `python3 -m py_compile tools/validate-mission-control.py` passed.
- `python3 tools/validate-mission-control.py` passed and reported seven
  structured RE sigma-slope coverage-dispatch review rows.
- `Rscript --vanilla -e "devtools::test(filter = 'structured-re-conversion-contracts', stop_on_failure = TRUE)"`
  passed with 4,322 assertions.
- `git diff --check` passed.
- `Rscript --vanilla -e "source('/Users/z3437171/shinichi-brain/tools/check-after-task.R'); main_check_after_task('docs/dev-log/after-task/2026-06-25-sigma-slope-coverage-dispatch-review.md')"`
  passed.

## 6. Tests of the Tests

The new validator and test fail if the dispatch review includes the held-out
animal `sigma:x` target, changes from `not_executed`, promotes
`coverage_evaluable = TRUE`, drops scheduler-exit retention, or lets the linked
q-series cells move beyond planned interval and coverage status.

## 7a. Issue Ledger

`gh issue list --repo itchyshin/drmTMB --search "sigma slope coverage dispatch q-series" --limit 20 --json number,title,state,url,labels`
returned no matching issues. No issue was opened because this slice is an
internal dispatch-review gate on the existing q-series evidence ladder.

## 8. Consistency Audit

The dispatch review is intentionally narrower than execution evidence. It
keeps `coverage_status = not_evaluated`, `coverage_evaluable = FALSE`, and
`interval_claim_status = diagnostic_only`, and it repeats the no-q4/q8,
no-REML, no-AI-REML, no-broad-bridge, no-public-support, and no-SR150-readiness
boundaries.

## 9. What Did Not Go Smoothly

The first generated rows inherited the pre-grid formula string rather than the
support-cell formula string. The generator now reads
`structured-re-q-series-support-cells.tsv` so the dispatch review remains
aligned with the support-cell authority.

## 10. Known Residuals

No Totoro or DRAC job was submitted. No coverage-evaluable denominator evidence
exists from this slice, and SR150 remains below the MCSE threshold for coverage
wording.

## 11. Team Learning

For compute-heavy q-series work, add a dispatch-review sidecar before launching
Totoro or DRAC jobs. The review row should name the retained denominator
classes and the exact targets so later execution cannot quietly change the
question being estimated.

## 12. Next Actions

Review the dispatch and runner contract, then execute one provider shard only
after scheduler, retention, and denominator accounting have been checked.
