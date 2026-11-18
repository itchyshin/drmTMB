# After Task: Non-logit Binomial structured SD bridge

## 1. Goal

Allow the Julia bridge to reach Binomial animal and related-matrix random-effect SD routes for probit and complementary log-log when the structured route is implemented and identifiable.

## 2. Implemented

The early non-logit guard now defers to the exact structured Binomial route checks for animal intercepts, animal-plus-IID intercepts, animal slopes, and relmat intercepts. It also checks matrix-slot compatibility before allowing the formula past the guard: animal slopes require `A`; animal intercept routes allow `A` or `Ainv`; relmat requires `K`. Other structured shapes remain refused.

The new opt-in live test simulates an animal slope with covariance `D A D`, where `log(SD) = -0.7 + 0.4 z`, and fits the same probit and cloglog data with native TMB and Julia. It checks convergence, recovery of the SD slope, and rowwise SD prediction against the fitted coefficients and across engines.

## Mathematical Contract

For animal slope effects, the test uses `b ~ N(0, D A D)` and `log(diag(D)) = X_sd alpha`. The random slope enters the link-scale predictor as `x b_g`. The bridge change alters only admission; it does not change this covariance or link-scale model.

## 3a. Decisions and Rejected Alternatives

Preserve the Binomial link when structured formulas take the bridge route. The structured family tag now includes `probit` or `cloglog` only for the exact admitted animal or related-matrix SD routes; the generic family tag remains in use for existing callers that omit a link. Do not loosen the route guard or change the covariance model. The live comparisons showed that dropping the link was not a harmless label change: DRM.jl otherwise fitted the logit likelihood.

## 4. Files Touched

- `R/julia-bridge.R`: exact non-logit structured-route and matrix-slot guard.
- `tests/testthat/test-julia-binomial-nonlogit-structured-sd-bridge.R`: unsupported-route negatives and live probit/cloglog R-to-Julia checks.
- `docs/dev-log/check-log.d/2026-10-25-binomial-nonlogit-structured-sd-bridge.md`: focused command and evidence record.
- This report.

## 5. Checks Run

- Before the fix, `devtools::test(filter = "julia-binomial-animal-sd-regression", reporter = "summary")` reproduced eight failures: the early guard rejected animal intercepts, animal slopes, and relmat intercept formulas for probit/cloglog before their dedicated route gates.
- After the fix, `testthat::test_file("tests/testthat/test-julia-binomial-animal-sd-regression.R")` passed 35 expectations, with two live-engine cases skipped because Julia tests were not opted in.
- After the final matrix-slot guard, the same animal test and the new test file passed 41 expectations total; the new live test was skipped in this fit-free run.
- Final live command: `DRMTMB_JULIA_TESTS=true DRMODELS_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' JULIA_HOME='/Users/z3437171/.juliaup/bin' OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=4 Rscript -e 'devtools::load_all(); testthat::test_file("tests/testthat/test-julia-binomial-nonlogit-structured-sd-bridge.R")'` passed 24 expectations, including probit and cloglog fits on both engines. JuliaCall used Julia 1.10.0.
- Final rerun after preserving the link in the structured family tag passed both live tests (probit and cloglog animal-slope and relmat-intercept routes). A neighboring fit-free check initially found that older calls omitting `link` caused a zero-length condition; the helper now treats a missing link as the existing default route. The fit-free non-logit bridge, relmat parity, and phylogenetic test files then passed; opt-in live tests were skipped in that check by design.
- Neighbouring filter `devtools::test(filter = "julia-binomial-(animal-sd-regression|phylo-sd|sd-links-bridge|nonlogit-structured-sd-bridge)", reporter = "summary")` exited 0. The live Julia engine was not exercised in that opt-out run; the separate live command above did exercise it.
- `git diff --check -- R/julia-bridge.R` passed.

The source worktree was dirty and based at `425bee81572c625a634b2b083050c5c57c1dc1f1`. At final verification, SHA-256 was `bfbf785014bfc1228ae94795e254f9b8237305f8c7fdfa90180b90ad200e5925` for `R/julia-bridge.R` and `860a4bee1be5e79a4b1f5a1120ffdb5c6a646dcf72555bf08ed8f6a7c8637431` for the bridge test.

## 6. Tests of the Tests

The existing animal-route test failed before the fix and passed afterward. New negative checks prove that an animal intercept-slope q2 block, an animal-slope `Ainv` route, and a pedigree input do not pass the non-logit guard. The live test compares recovered SD coefficients and predictions with independent synthetic truth and a second engine; it is one seeded fixture per link, not interval calibration.

## 7a. Issue Ledger

The exact issue search recorded no matching open issue. No issue was opened or changed.

## 8. Consistency Audit

The test formula is `y ~ x + animal(0 + x | id, A = A)` with `sd(id, level = "animal") ~ z`. The simulation uses a unit-diagonal AR(1) relatedness matrix, group-constant `z`, and the same `D A D` covariance passed to each engine. The guard's slot checks match `drm_julia_structured_payload()` restrictions for these routes.

The required status-inventory search was `rg -n -i "Binomial.*(probit|cloglog).*animal|probit.*animal|non-logit.*(animal|structured)|structured.*(probit|cloglog)" README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml docs/src/capabilities.md docs/src/families.md docs/src/tutorials/animal-models.md`. It found current-boundary wording in `vignettes/formula-grammar.Rmd:81` and `docs/design/01-formula-grammar.md:268` that says correlated non-logit blocks and other structured Julia Binomial shapes are unavailable. Those statements need reconciliation with the expanded candidate support; the historical first-slice note in `NEWS.md:3765` was left intact. I sent the specific findings to the active documentation-audit lane and did not edit its files. The direct Julia probit phylogenetic route also passed its live focused test in a prior recorded run; do not describe it as an open implementation gap. The audit reported missing explicit link coverage in the Julia capability table/tutorial and native Binomial formula help for phylogenetic intercept and animal-slope SDs.

## 9. What Did Not Go Smoothly

The first live attempt failed because the test process did not inherit Juliaup's executable path; the tests do not call the helper that translates `DRM_JL_JULIA_HOME`, so the successful command set `JULIA_HOME` directly. A subsequent attempt reached the fits but used `expect_lt(info = ...)`, which testthat does not support; the assertion was changed to `expect_true(..., info = ...)` before the passing run.

## 11. Team Learning

An early family/link guard must defer to the same exact route predicates and input-slot rules used by the later model builder. Formula-shape admission alone can make a supported route unreachable or give an unsupported matrix choice a misleading error.

## 10. Known Residuals

This is focused point-recovery, likelihood, and public SD-prediction evidence for probit/cloglog animal slopes and relmat intercepts through the Julia bridge. It does not establish interval calibration, full suite status, non-logit parity for every structured effect, other distributions, or the Julia inference API. The identified capability and formula-help wording remains pending the active documentation-audit lane; no public documentation was edited here.

## 12. Cross-Product Coverage

Native TMB remains the comparison engine for the live bridge cases. Julia routes now receive the intended non-logit family tags for the admitted structured SD combinations. The direct Julia probit phylogenetic route had a separate passing focused run; this bridge slice does not claim that every structured effect or every distribution is at parity. The active documentation lane owns the public capability wording. Interval calibration remains future work. This slice does NOT cover native TMB changes, Julia inference/profile/bootstrap behavior, missing-data routes, REML, penalties, aggregation, other response families, arbitrary structured combinations, or uncertainty calibration.

## Next Actions

Continue Bernoulli parity for the remaining structured effect routes, coordinate the documented link-coverage statement with the active documentation-audit lane, and then map and implement remaining response-family combinations. Keep interval coverage as a separate later validation phase.
