# After Task: Same-Response q2 Package Validation Cleanup

## Goal

Clean up the accumulated same-response q2 `mu`/`sigma` branch after the
hardening audit by running package-level validation, fixing stale test
expectations, and recording which gates passed.

## Implemented

This was a validation and cleanup pass, not a new likelihood change. The branch
already contained the fitted same-response q2 slope covariance route, the Phase
18 smoke/recovery lane, and the local formal plus hardening audit. This pass
patched stale tests exposed by the first full test run:

- `tests/testthat/test-gaussian-random-intercepts.R` now expects the current
  larger labelled `mu`/`sigma` covariance-block error and the covariance-block
  label requirement for the unlabelled bivariate `sigma1` slope case.
- `tests/testthat/test-phase18-correlation-block-status.R` now expects 12 plan
  and dispatch rows after the same-response q2 smoke and recovery tasks were
  added.

## Mathematical Contract

No model equations changed in this cleanup pass. The fitted same-response q2
route remains the matching one-coefficient ordinary block:

```r
mu1 = y1 ~ x + (0 + x | p | id)
sigma1 = ~ x + (0 + x | p | id)
mu2 = y2 ~ x
sigma2 = ~ x
rho12 = ~ 1
```

Larger labelled `mu`/`sigma` blocks, unlabelled bivariate covariance blocks,
cross-response pairs, and all-four p8/q8 endpoints remain rejected.

## Files Changed

This cleanup touched `tests/testthat/test-gaussian-random-intercepts.R`,
`tests/testthat/test-phase18-correlation-block-status.R`, and
`docs/dev-log/check-log.md`. `devtools::document()` confirmed the existing
roxygen output, including the current `man/corpairs.Rd` wording.

## Checks Run

- `air format` over the touched R, simulation, and test files completed without
  output.
- `Rscript -e "devtools::document()"` completed after loading `drmTMB`.
- First `Rscript -e "devtools::test()"` ran for 969.7s and reported 9,985
  passes, zero warnings, zero skips, and four failures from stale expectations.
- `Rscript -e "devtools::test(filter = 'gaussian-random-intercepts|phase18-correlation-block-status')"`
  returned 444 passes, no failures, warnings, or skips after the stale tests
  were patched.
- Final `Rscript -e "devtools::test()"` ran for 956.6s and returned 9,995
  passes, no failures, warnings, or skips.
- `Rscript -e "pkgdown::check_pkgdown()"` returned "No problems found."
- `Rscript -e "pkgdown::build_site()"` completed and wrote `pkgdown-site`. It
  emitted the known local `glmmTMB`/`TMB` version mismatch warning.
- `Rscript -e "devtools::check()"` returned `Status: OK` in 8m 55.1s with
  0 errors, 0 warnings, and 0 notes. The build printed the local Git fsmonitor
  socket notice, then continued successfully.
- Source and rendered stale-wording scans returned only intended planning,
  hold-language, and p8/q8 boundary rows. The rendered evidence scan found the
  new same-response q2 diagnostic and hardening wording in NEWS and the
  homepage.
- `Rscript tools/codex-checkpoint.R --goal "same-response q2 branch package validation cleanup" --next "Review the broad validation diff and decide whether to open PR review or continue another roadmap/status cleanup slice."`
  wrote
  `docs/dev-log/recovery-checkpoints/2026-06-06-120943-codex-checkpoint.md`.
- `git diff --check` passed.

## Tests Of The Tests

The first full `devtools::test()` run failed before the stale expectations were
patched. The targeted rerun confirmed the two fixed contexts, and the second
full `devtools::test()` run confirmed the full suite after those changes.

## Consistency Audit

The package now has a coherent validation story for this branch: the
same-response q2 route is fitted and artifact-routed, the local formal and
hardening audits keep it out of power-grid support, and the broad package gates
pass after updating stale count and error-message expectations.

## GitHub Issue Maintenance

Issue #491 is the active work-queue issue for this lane. The earlier hardening
audit comment records the promotion hold decision. This cleanup pass was added
as a short validation comment:
<https://github.com/itchyshin/drmTMB/issues/491#issuecomment-4639932209>.

## What Did Not Go Smoothly

The first full suite took about 16 minutes and exposed three stale assumptions:
two older error-message patterns in `test-gaussian-random-intercepts.R` and one
10-row fixed-count assumption in `test-phase18-correlation-block-status.R`.
Those were test drift from the branch changes, not new model failures.

## Team Learning

When adding Phase 18 task rows, update all registry-facing fixed-count tests in
the same pass, not only the main structured-workflow registry tests. Error
message tests around unsupported covariance blocks should assert the current
reader guidance rather than older implementation boundaries.

## Known Limitations

This validation pass did not change the promotion decision. Same-response q2
power claims remain gated, all-four p8/q8 endpoints remain closed, and broader
profile/bootstrap interval calibration remains a future sharded lane.

## Next Actions

Decide whether this branch is ready for PR review or whether another repeated
cleanup slice should target remaining roadmap/status surfaces.
