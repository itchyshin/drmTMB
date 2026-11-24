# After Task: bring the converged-rule branch up to date with main

Reader: the next contributor reviewing draft PR #1781 (refs #1452).

## Goal

Merge `origin/main` into `claude/converged-rule-drm-20261118` and leave the 19 Nov Newton-step cut in place, so the branch can be tested without moving any receipt or any expectation outside the files the PR already owns.

## Implemented

`convergence_status()` uses the gradient stored at fit time. `drmTMB()` evaluates `obj$gr(opt$par)` once and keeps it on `fit$gradient`. `drm_newton_step_se()` forms the Newton step in standard-error units, `max_i |(H^-1 g)_i| / SE_i`, from that vector and the stored fixed-effect covariance. A finite step above `1e-3`, or a non-finite stored gradient, is `not_converged`, and that test runs before the boundary and degenerate steps. A missing gradient or a Hessian that is not positive definite leaves the step as `NA`, and the later steps screen the fit. That matches CONV-GRADIENT-CUT (19 Nov 2026) and the order in `docs/design/278-twin-convergence-status.md`.

The exported help for `convergence_status()` still described the earlier relative-gradient test. The roxygen comment and `man/convergence_status.Rd` now name the stored-gradient Newton step. `NEWS.md` already did.

## Mathematical Contract

A fit is `not_converged` on the gradient when

`max_i |(H^{-1} g)_i| / sqrt((H^{-1})_{ii}) > 1e-3`

with `g` the stored outer gradient and `H^{-1}` the `sdreport` fixed-effect covariance. The cut is the one Shinichi set on 19 Nov 2026. No tolerance in tests was changed.

## Files Changed

- Merge of `origin/main` `a8c034388`: `R/missing-data.R`, `tests/testthat/test-fix-1749-impute-gaussian-link.R`, `docs/dev-log/check-log.d/2026-11-21-fix-1749-impute-gaussian-link.md`.
- Help text: `R/check.R`, `man/convergence_status.Rd`.
- This report and `docs/dev-log/check-log.d/2026-11-22-converged-rule-main-merge.md`.

`src/skewnormal.jl` and DRModels.jl were not edited. No test expectation moved.

## Checks Run

Local install: R 4.6.2, TMB 1.9.25, testthat 3.3.2, `NOT_CRAN=true`.

`testthat::test_dir(filter = "converg|temporal-review-fixes|phylo-temporal-ou-methods")`: 209 passed, 0 failed, 0 errors, 0 warnings, 2 skipped. The skips are the live Julia engine tests in `test-julia-convergence-status-parity.R`. The R-side status test in that file passed. The R-CMD-check workflow does not install Julia.

`python3 tools/capability_ledger.py --check`, `--check-c14-receipt-equivalence`, and `python3 tools/qseries_v1_release_ledger.py --check` all exited 0. The C14 check printed `C17 current-source compatibility PASS`. Receipt digits, including mc-0568, were left as committed.

## Tests Of The Tests

No new test was added. The existing twin file already pins the failure path: a stored gradient containing `NA` is `not_converged` with `max_gradient = Inf`, and a fit that is both on the boundary and off the Newton-step cut reports `not_converged` rather than `boundary` (`tests/testthat/test-convergence-status-twin.R`). Those expectations passed on this tree.

## Consistency Audit

Searched `relative (unit-free) gradient`. The only remaining hits are the historical sentence in `docs/design/278-twin-convergence-status.md` (the 18 Nov draft was replaced by the Newton step) and older dev-log notes. `NEWS.md` already states the Newton step. `README.md`, `docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`, `vignettes/formula-grammar.Rmd`, and `_pkgdown.yml` were not edited: this merge does not change formula grammar or the family list.

`pkgdown::check_pkgdown()` and a full `devtools::check()` were not run. The targeted tests and the three ledger checks were.

## GitHub Issue Maintenance

The issue tracker was left unchanged. The work stays on draft PR #1781 and uses refs #1452 only. No closing keyword was added, and the PR body was not edited.

## What Did Not Go Smoothly

Ubuntu 24.04's own R 4.3.3 cannot install the current r2u binaries, which need R 4.6. The test run used CRAN's `noble-cran40` R 4.6.2 plus r2u. That is a newer R than the 4.3.3 note in the PR body. The named tests still passed.

## Team Learning

A help page can keep describing a cut the code has already replaced. When a ruling changes the quantity, update `?convergence_status` in the same change as `drm_newton_step_se()`, not only `NEWS.md` and design doc 278.

## Known Limitations

The two live Julia parity tests did not run here. CI's R-CMD-check lane also has no Julia, so those skips match that lane. A missing stored gradient still yields `NA` and is screened by the boundary and degenerate steps, which is what design doc 278 says.

## Next Actions

Push this branch and let the pull-request checks run. If a later main merge moves a C14 or mc-0568 receipt digit, stop and report the old and new values instead of refreshing the receipt.
