# After-task: Native Binomial non-logit animal plus IID SD checks

## 1. Goal

Check Binomial probit and cloglog animal-intercept and animal-slope plus IID SD routes in native R/TMB and Julia, including same-data bridge comparisons.

## 2. Implemented

Added a focused test file with independent synthetic probit and cloglog datasets. It checks a correlated animal intercept and a correlated animal slope, each combined with an independent site intercept; each coefficient has its own predictor-dependent SD. The native routes already existed; this task adds test evidence and no production code.

## 3a. Decisions and Rejected Alternatives

The test keeps the same response, random-effect layout, and SD predictors across the two links. It reverses the relationship-matrix dimname order relative to the data levels so matrix alignment is exercised. Recovery expectations check true SD-slope directions and allow an absolute error below 0.5. The first animal-slope fixture with 48 independent sites missed the IID-slope bound by 0.017. I increased the site count to 96 and reran the same seeds without changing the tolerance.

## 4. Files Touched

- `tests/testthat/test-binomial-nonlogit-animal-iid-sd-regression.R`
- `docs/dev-log/evidence/general-sd-regression/binomial-nonlogit-animal-iid-20261027/run.txt`
- `docs/dev-log/evidence/general-sd-regression/binomial-nonlogit-animal-iid-20261027/source.sha256`
- `docs/dev-log/evidence/general-sd-regression/binomial-nonlogit-animal-iid-20261027/bridge-run.txt`
- `docs/dev-log/check-log.d/2026-10-27-binomial-nonlogit-animal-iid-sd.md`
- This report.

The main shared `docs/dev-log/check-log.md` was not edited. Its path preflight did not complete after several minutes on the shared checkout; this result is recorded in the per-slice check-log directory instead.

## 5. Checks Run

The native focused command `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-nonlogit-animal-iid-sd-regression")'` passed 46 assertions with no failures, warnings, or skips in 63.3 seconds. Fresh matched bridge runs passed 25/25 assertions for probit/cloglog animal intercept plus IID and 39/39 for logit/probit/cloglog animal slope plus IID. The exact bridge command filters, timings, environment, and scope are recorded in `bridge-run.txt`; source hashes are in `source.sha256`. The new files have no trailing whitespace. `git diff --check` reports a blank line at EOF in the unrelated, unowned `tests/testthat/test-binomial-sd-integration.R`; that file was left unchanged.

## 6. Tests of the Tests

The independent data generator draws animal effects from the supplied covariance, multiplies them by the animal-level SD regression (and by row-level `x` for the animal-slope route), adds an independent site effect with a second SD regression, and applies the requested Binomial link before drawing responses. The test checks fitted convergence, slope directions, broad coefficient errors, and group-level predicted SDs. It does not compare the likelihood with an independent numerical oracle.

The initial run caught a missing local binding for `A`. Subsequent attempts exposed unsupported `info` arguments in this testthat version and use of the wrong prediction accessor for R. Those harness errors were fixed before the passing run; they were not model failures.

## 7a. Issue Ledger

No issue or pull request was created or changed. This adds test evidence for a route already present in the active SD programme, so no separate issue was needed.

## 8. Consistency Audit

The generated response uses `stats::binomial(link = link)$linkinv(eta)`, matching the family supplied to `drmTMB()`. Both SD formulas use predictors constant within their grouping factors. The predicted SD values match the fitted columns for each target. The existing formula grammar is unchanged.

Status-inventory search used the exact pattern `Bernoulli|Binomial|binomial animal` across `README.md`, `docs/dev-log/internal-roadmap.md`, `NEWS.md`, `docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`, `vignettes/formula-grammar.Rmd`, and `_pkgdown.yml`. The separate stale-wording search used `animal.*(iid|ordinary)|probit.*animal|cloglog.*animal|animal.*probit|animal.*cloglog` across the same inventory plus `docs/src/capabilities.md` and `docs/src/families.md`; those two paths do not exist in this R package checkout. Existing limitations describe the animal-plus-IID case, but the link-specific evidence has not yet been added to public documentation. The active documentation-audit lane has been sent the result.

## 9. What Did Not Go Smoothly

Three early attempts stopped on test-harness mistakes before reaching a complete run. The final focused run passed. The repository's main shared check-log preflight did not finish after several minutes, so the result was entered in the collision-free per-slice check-log directory. The worktree contains unrelated dirty changes in shared model files; this task did not edit them.

## 10. Known Residuals

This is fixed-seed point-recovery and output evidence for two Binomial links, an animal intercept or slope, and an IID intercept. Same-data R/TMB-to-Julia bridge checks now pass for the tested intercept+IID probit/cloglog and slope+IID logit/probit/cloglog fixtures. It does not establish interval coverage, other animal-slope layouts, other structured-effect combinations, or support across other distributions. A separate Julia test covers both the animal-intercept and animal-slope plus IID routes under these links (58/58 assertions); the implementations were not fitted to the same data. The full package suite and rendered documentation were not run. The after-task structure check passed, while the acceptance-ledger subcheck is UNKNOWN because Node or the gate checker is unavailable.

## 11. Team Learning

When adding a test in a user-facing R package, bind matrix objects in the formula's evaluation environment, use the public prediction accessor for the intended output, and check assertion-helper arguments against the installed testthat version before running the full synthetic fixture.

## 12. Cross-Product Coverage

Covers native and Julia Binomial probit/cloglog animal-intercept or animal-slope plus IID-intercept fits with separate predictor-dependent SD formulas, plus matched R/TMB-to-Julia bridge checks for intercept+IID probit/cloglog and slope+IID logit/probit/cloglog. It does NOT cover interval calibration, other random-effect types, or remaining response families.
