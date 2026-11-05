# After Task: Binomial mesh-slope SD checks across links

## 1. Goal

Extend the focused native Binomial fixed-kappa mesh-slope SD check from logit to probit and cloglog, then align the capability notes and evidence ledger.

## 2. Implemented

Added independent probit and cloglog synthetic fits for `spatial(0 + x | site, mesh = mesh)` with `sd(site, level = "spatial", coef = "x") ~ z_site`. Both cases check convergence, point recovery of the log-SD slope, site SD predictions against an independently constructed model matrix, and binary marginal simulation. The shared native likelihood path was already link-aware; this extension added tests and documented the exact tested scope.

## 3a. Decisions and Rejected Alternatives

The evidence supports all three Binomial links for this one mesh slope-only route at point-recovery level. The fuller projected-field, exact marginal-draw, and save/reload checks remain in the logit fixture. No interval coverage, range estimation, Julia mesh parity, multiple mesh coefficients, or other endpoints are claimed.

## 4. Files Touched

- `tests/testthat/test-binomial-mesh-sd-regression.R`
- `R/formula-markers.R`, `man/spatial.Rd`
- `NEWS.md`, `docs/design/01-formula-grammar.md`, `docs/design/18-random-effect-scale-models.md`
- `docs/dev-log/known-limitations.md`, `docs/dev-log/internal-roadmap.md`, `vignettes/formula-grammar.Rmd`
- `docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and its regenerated summary
- `docs/dev-log/general-sd-regression/evidence/native-binomial-mesh-slope-links-20261027/`
- `docs/dev-log/check-log.md` and the general-SD recovery checkpoint

## 5. Checks Run

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-mesh-sd-regression", reporter = "summary", stop_on_failure = TRUE)'`: passed, 40 expectations, zero failures or warnings.
- The test receipt binds the test file and five implementation source files with before/after SHA-256 manifests. Evidence reconciliation passed with 19,342 candidate rows, 90 linked rows, 19,252 unlinked rows, and 110 evidence records.
- `OPENBLAS_NUM_THREADS=1 Rscript -e 'devtools::document()'`: completed and regenerated `man/spatial.Rd`.
- Scoped `git diff --check` passed for the touched files.
- Interval calibration, live Julia mesh execution, the full R suite, and `R CMD check` were not run.

## 6. Tests of the Tests

The first test run exposed an assertion API mismatch: installed testthat 3.3.2 does not accept `info` in `expect_lt()`. Replacing that assertion with `expect_true(condition, info = link)` fixed the fixture. The final source-pinned run passed for all three links.

## 7a. Issue Ledger

No issue was opened or changed for this narrow evidence extension. The broader Phase 18 issue remains outside this slice.

## 8. Consistency Audit

The public formula guide, spatial help, NEWS, random-effect-scale design note, known limitations, roadmap, and formula-grammar vignette now distinguish three-link point recovery from the deeper logit-only output workflow. Evidence rows link the same run to the exact logit, probit, and cloglog mesh-slope candidates. The reconciler validates all receipt, manifest, and test hashes. No coverage or Julia parity wording was added.

The read-only native audit recommends the next candidate as a Binomial q1 phylogenetic-tree plus coordinate-spatial additive pair, beginning with logit. It identified explicit shared builder and TMB work, so no implementation claim is made for that candidate. The required R and TMB diffs and ownership must be reviewed before editing those files.

## 9. What Did Not Go Smoothly

The first focused run stopped on a testthat-version-specific `expect_lt()` argument. The assertion was rewritten using the installed API; the full focused file then passed. Evidence reconciliation also caught the old logit row's stale test hash after the test source changed. That row now points to the new source-pinned rerun; its earlier receipt files remain preserved.

## 10. Known Residuals

This remains a narrow point-recovery result. The one-seed recovery bound is not uncertainty calibration. Wald intervals, profile intervals, bootstrap intervals, interval coverage, broader mesh geometries, and Julia mesh support remain unverified here. The overall predictor-dependent random-effect SD goal remains active.

## 11. Team Learning

When a fixture grows, refresh the evidence-table binding to its exact current test bytes and retain the old receipt files. A passed link-specific recovery fixture supports only its exact likelihood, provider, coefficient, and output checks.

## 12. Cross-Product Coverage

This extension covers native R/TMB Binomial `mu`, one fixed-kappa spatial mesh slope, and complete-response probit and cloglog cases, alongside the existing logit evidence. It does NOT cover Julia mesh parity, interval calibration, other structured providers, other distributions, bivariate models, or the full general SD goal.
