# After-task: Bernoulli non-logit correlated q2 bridge check

## 1. Goal

Check whether the existing native-to-Julia bridge fits the same correlated Bernoulli intercept-and-slope datasets under probit and complementary log-log links.

## 2. Implemented

No production code changed. The existing focused bridge test completed on the current native and paired Julia candidate worktrees. It generated the same response data once per link and fitted that dataset through both engines.

## 3a. Decisions and Rejected Alternatives

Kept this slice to the existing q2 block with coefficient-specific predictor-dependent marginal SDs and one constant correlation. The fixture uses fixed-seed independent standard-normal latent coordinates, then creates the correlated intercept and slope using the specified correlation. No new correlation or link parameterization was introduced.

## 4. Files Touched

- `docs/dev-log/after-task/2026-10-27-binomial-correlated-nonlogit-bridge.md`
- `docs/dev-log/check-log.d/2026-10-27-binomial-correlated-nonlogit-bridge.md`
- `docs/dev-log/evidence/general-sd-regression/binomial-correlated-nonlogit-bridge-20261027/run.txt`
- `docs/dev-log/evidence/general-sd-regression/binomial-correlated-nonlogit-bridge-20261027/source.sha256`

The bridge test and production source files were read and exercised but not modified in this slice.

## 5. Checks Run

`DRMTMB_JULIA_TESTS=true DRM_JL_PATH='/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia' DRM_JL_JULIA_HOME=/Users/z3437171/.juliaup/bin JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 PATH=/Users/z3437171/.juliaup/bin:$PATH Rscript -e 'devtools::test(filter = "julia-binomial-nonlogit-correlated-sd-bridge", reporter = "summary", stop_on_failure = TRUE)'` completed with the testthat `DONE` marker and one live Julia test. No failed expectation or warning was displayed. The installed reporter did not print a numeric assertion total. Source hashes are recorded with the receipt.

## 6. Tests of the Tests

The bridge fixture constructs the correlated latent intercept and slope from shared and independent normal draws, applies the requested link to the simulated linear predictor, and passes the same data and formula to native TMB and Julia. The assertions compare convergence, named SD coefficients, fitted correlation, point recovery directions and broad errors, and group-level predicted SDs. This is one fixed-seed design per non-logit link.

## 7a. Issue Ledger

No issue or pull request was created or changed. I sent the active parity lane the result and asked it to flag any overlap with its work. No response was received before this receipt was written; no other lane file was edited.

## 8. Consistency Audit

The formula uses `sd(id, dpar = "mu", coef = ...)` for both members of one ordinary correlated q2 block. Its SD predictors are constant within `id`. Probit and cloglog are used in both the synthetic response generator and the fitted family. The test makes point and prediction comparisons only; it does not make a claim about uncertainty calibration.

## 9. What Did Not Go Smoothly

The reporter printed progress dots and the `DONE` marker but no numeric assertion total. The run completed without a failure display, but I did not infer a count from the dots.

## 10. Known Residuals

This does not establish interval coverage, practical identifiability under low information, reliable Wald uncertainty, parity for every q2 block or link, or general response-family support. It does not by itself admit any required capability rows. The broader parity lane remains active. I sent it a coordination note about this exact Bernoulli cell before running the bridge check.

## 11. Team Learning

For JuliaCall bridge tests, retain the exact runtime environment and candidate paths in the receipt. When the configured reporter omits assertion totals, preserve that limitation instead of estimating a count from progress dots.

## 12. Cross-Product Coverage

Covers one same-data native TMB and Julia correlated q2 Bernoulli fixture under probit and complementary log-log, including selected SD coefficients, correlation, convergence, and group-level predictions. It does NOT cover interval calibration, all q2 layouts, or other random-effect providers and response families. Next action: reconcile this exact test receipt with the Bernoulli q2 rows, then select the next unclosed implementation cell.
