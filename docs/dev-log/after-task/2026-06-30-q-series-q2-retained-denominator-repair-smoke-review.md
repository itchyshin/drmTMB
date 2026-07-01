# After Task: Q-Series q2 Retained-Denominator Repair-Smoke Review

## 1. Goal

Turn the imported Totoro q2 retained-denominator repair smoke into an explicit
Fisher/Rose/Grace review decision, without promoting any Q-Series support cell
or authorizing a blind top-up.

## 2. Implemented

Added
`tools/summarize-structured-re-q2-retained-denominator-repair-smoke-review.R`.
The generator reads
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-dispatch.tsv`,
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-review-decision.tsv`,
and
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-contract.tsv`,
then writes
`docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-review.tsv`.
With `--sync-dashboard=true`, the generator also updates the Q-Series
row-level next gates, closure triage, and next-campaign queue so the widget now
shows the post-smoke no-top-up decision instead of the earlier pending-smoke
instruction.

The review table records five no-promotion decisions. The four q2 intercept
rows are `repair_smoke_existing_route_not_enough_no_topup`; the Totoro smoke
reran the existing route, did not evaluate a new interval repair, and therefore
does not repair the SR150 interval-shape blockers. The q2-plus-q2 phylo
intercept row is `repair_smoke_finiteness_blocked_no_topup` because the imported
smoke still has `profile_finite_min=14`.

## 3a. Decisions and Rejected Alternatives

I rejected treating the Totoro smoke as a green light for SR475/SR1000 top-up.
The smoke is useful as a gate, but it did not evaluate a named repair route and
therefore cannot overturn the prior SR150 Fisher/Rose/Grace blocker decision.

The next compute step is explicitly blocked until a named interval-repair route
exists. After that route exists, the same small retained-denominator smoke must
pass before larger Totoro, Nibi, Rorqual, Trillium, or DRAC top-up work.

## 4. Files Touched

- `tools/summarize-structured-re-q2-retained-denominator-repair-smoke-review.R`
- `tools/validate-mission-control.py`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/dashboard/structured-re-q2-retained-denominator-repair-smoke-review.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-closure-triage.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-next-campaign-queue.tsv`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-06-30-q-series-q2-retained-denominator-repair-smoke-review.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file tools/summarize-structured-re-q2-retained-denominator-repair-smoke-review.R --overwrite=true --sync-dashboard=true`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file -e 'invisible(parse("tools/summarize-structured-re-q2-retained-denominator-repair-smoke-review.R")); invisible(parse("tests/testthat/test-structured-re-conversion-contracts.R"))'`: passed.
- `python3 -m py_compile tools/validate-mission-control.py`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, including 5 structured RE q2 retained-denominator repair-smoke review rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 MKL_NUM_THREADS=1 TMB_NTHREADS=1 Rscript --no-init-file -e 'devtools::test(filter = "structured-re-conversion-contracts")'`: 10089 PASS / 0 FAIL / 0 WARN / 0 SKIP.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true Rscript --no-init-file /Users/z3437171/shinichi-brain/tools/check-after-task.R docs/dev-log/after-task/2026-06-30-q-series-q2-retained-denominator-repair-smoke-review.md`: passed.

## 6. Tests of the Tests

Mission control now validates the review table schema, exact five-cell scope,
source links, no-promotion decisions, support-cell non-movement, review status,
finite/coverage/miss signals, and the stop rule against further compute until a
named repair route exists.

The focused R test checks the review table against the repair-smoke dispatch,
the prior SR150 decision table, the repair contract, and all local source
artifact paths. It also checks the q2-plus `profile_finite_min=14` blocker and
the q2 intercept `existing_interval_route_only_no_new_repair` rule.

## 7a. Issue Ledger

No GitHub issue or PR thread was opened or closed in this slice. The work
records a local evidence decision that should feed the existing Q-Series PR
surface rather than create a new issue.

## 8. Consistency Audit

No support-cell status changed. The linked q2 repair cells remain
`point_fit/planned/planned`, and the review table states
`do_not_promote_keep_point_fit_planned_planned` for every row.

The review table keeps Totoro, Nibi, Rorqual, Trillium, and DRAC top-up blocked
until a named repair route exists. It also preserves the existing no-claims
boundary for q2 slope inheritance, q2-plus inheritance, q4/q8, non-Gaussian
intervals, REML, AI-REML, bridge support, and public support.

## 9. What Did Not Go Smoothly

The first validator pass caught that the q2-plus Fisher decision did not
explicitly say the smoke reran the existing interval route. I fixed the
generator and regenerated the TSV before rerunning mission control.

## 10. Known Residuals

The five q2 retained-denominator repair cells remain unfinished. The next real
work is not more replicate count on the same route; it is a named interval
repair route for the interval-shape and profile-finiteness blockers.

Trillium is connected, but this review keeps it out of denominator-sensitive
q2 top-up work until source/root staging and a repaired interval route exist.

## 11. Team Learning

Small smoke results need their own review surface. A smoke that reruns an
unchanged route can be good operational evidence and still be negative
scientific evidence for top-up. Recording that distinction keeps Q-Series
progress honest while preserving the ability to use Totoro and DRAC quickly once
there is a real repair to test.
