# After Task: Dinnage Arc 3 A2 Request-Changes Repair

## Goal

Repair PR #1369 after the independent D-263 review requested changes for #1338
A-8 and accepted #1343 Mi-5 only after a test fix.

## Implemented

`drmTMB()` now stores the fit-time input data frame that aligns with
`spec$keep`, after fixed-predictor factor cleanup and before MSPL filtering.
`check_fit_input_data()` reads that stored data instead of evaluating
`object$call$data`, so local-scope fits keep enough evidence for
`check_dropped_group_levels()` and the `groups_lost=` message. The stored copy
is removed when `drm_control(keep_data = FALSE)` is used.

The Wave4a regression test now fits the #1338 case inside `local({ ... })`,
checks that `check_fit_input_data()` sees all 320 input rows, and checks the
public `groups_lost=6` and `id lost 6 levels` message. The #1343 test now uses
`expect_warning()` instead of passing a string to `capture_warnings()`, and the
stale `check_drm()` wording no longer tells users to switch to
`method = "profile"` for residual `rho12`.

## Mathematical Contract

No likelihood, transform, family, formula grammar, estimator, or interval
definition changed. This task changes diagnostic bookkeeping and warning text.

## Files Changed

`R/drmTMB.R`, `R/check.R`, `R/control.R`,
`tests/testthat/test-dinnage-audit-wave4a.R`, `tests/testthat/test-control.R`,
and `docs/dev-log/check-log.md`.

## Checks Run

Pre-fix reproduction:
`Rscript -e 'devtools::load_all(); devtools::test(filter = "dinnage-audit-wave4a")'`
reported `[ FAIL 3 | WARN 0 | SKIP 0 | PASS 1 ]`.

After repair, the same command reported
`[ FAIL 0 | WARN 0 | SKIP 0 | PASS 11 ]`.

Neighboring diagnostics:
`Rscript -e 'devtools::load_all(); devtools::test(filter = "check-drm")'`
reported `[ FAIL 0 | WARN 14 | SKIP 0 | PASS 270 ]`. The warnings were existing
`sd_phylo()` deprecation warnings and one NaN fixture warning.

Storage guard coverage:
`Rscript -e 'devtools::load_all(); devtools::test(filter = "dinnage-audit-wave4a|control")'`
reported `[ FAIL 0 | WARN 2 | SKIP 0 | PASS 340 ]`. The warnings were existing
`sd_phylo()` deprecations in `test-control.R`.

Full `devtools::test()`, `devtools::check()`, and pkgdown checks were not run
for this narrow PR-response repair.

## Tests Of The Tests

The A-8 regression failed before the fix because `check_fit_input_data(fit)` was
`NULL` for the local-scope fit, `check_dropped_group_levels(fit)` had zero rows,
and the public row lacked `groups_lost=6`. The fixed test now asserts the
internal data contract and the user-facing diagnostic row.

The Mi-5 regression failed before the fix because this testthat version treated
the second unnamed `capture_warnings()` argument as `ignore_deprecation`. The
new expectation captures the actual warning condition and then checks its text.

## Consistency Audit

Task-specific scan:
`rg "object\\$call\\$data|switching to method = \"profile\"|confint\\(method = \"profile\"\\)|groups_lost|input_data" . --glob '*.{R,Rmd,md}'`.

The scan found no remaining `object$call$data` diagnostic recovery and no
remaining `switching to method = "profile"` wording. Remaining
`confint(method = "profile")` hits are ordinary profile documentation or
historical notes. `NEWS.md` already has the #1338 and #1343 Wave A2 bullets.

## GitHub Issue Maintenance

PR #1369 will receive a repair comment after the commit is pushed. No merge is
authorized in this task.

## What Did Not Go Smoothly

`air format` with relative paths failed to find the Wave4a test in the scratch
worktree, and the absolute-path retry reformatted too much of `R/drmTMB.R`.
That formatter churn was removed before testing and committing.

## Team Learning

Diagnostic rows that compare fit-time filters to original rows need a stored
fit-time contract. Re-evaluating user calls from a diagnostic is fragile because
local variables may already be out of scope.

## Known Limitations

`groups_lost=` is unavailable after users deliberately fit with
`drm_control(keep_data = FALSE)`, because that storage mode drops the data
needed to compare original grouping levels to the retained rows.

## Next Actions

Push the repair commit to PR #1369 and reply to the review comment with the
commit and test evidence.
