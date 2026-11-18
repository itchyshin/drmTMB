# After Task: verify NB2 SD coefficient uncertainty outputs

## 1. Goal

Add a direct regression check for public variance and standard-error outputs on NB2 predictor-dependent random-effect SD coefficients.

## 2. Implemented

The existing NB2 SD integration test now checks that both `sd(id)` coefficients have positive finite diagonal entries in `vcov(fit)` and positive finite `summary(fit)$coefficients` standard errors.

## 3a. Decisions and Rejected Alternatives

No C++ report change was made. Independent static review found that coefficient extraction uses optimizer parameters and ML `vcov()` uses the fixed-parameter covariance, so the absent `ADREPORT(beta_sd_mu)` did not establish a public failure. Assumptions made without asking: none.

## 4. Files Touched

- `tests/testthat/test-nbinom2-sd-integration.R`
- `docs/dev-log/check-log.d/2026-10-20-nbinom2-sd-vcov.md`
- `docs/dev-log/after-task/2026-10-20-nbinom2-sd-vcov.md`

## 5. Checks Run

- `Rscript -e "devtools::test(filter = '^nbinom2-sd-integration$', reporter = 'summary')"`: passed.
- An initial broad filter selected the truncated-NB2 suite as well; that process was interrupted. The exact filter rerun produced a clean completion.

## 6. Tests of the Tests

The assertions require the two named SD coefficient rows to yield positive finite variances and standard errors. The suite passed on the existing recovery fixture. No deliberate covariance corruption was used to test these assertions.

## 7a. Issue Ledger

No issue or pull request was changed. Interval coverage remains outside this check.

## 8. Consistency Audit

The independent audit traced NB2 coefficient extraction to optimizer parameters and ML covariance to `sdr$cov.fixed`. The new assertions confirm those outputs through the public `vcov()` and `summary()` methods. This does not establish profile accuracy, bootstrap accuracy, or coverage.

## 9. What Did Not Go Smoothly

The first filter also matched the truncated-NB2 test file and ran beyond its two-minute estimate. I stopped it and reran the intended file with an anchored filter; the clean run completed in about two minutes.

## 10. Known Residuals

No interval-calibration evidence was added. The assertions cover the ordinary NB2 intercept-SD fixture, not every NB2 model type or SD target.

## 11. Team Learning

For public uncertainty output claims, prefer a focused assertion through `vcov()` and `summary()` before interpreting an internal `REPORT`/`ADREPORT` omission as a user-facing defect.

## 12. Cross-Product Coverage

Native NB2 ordinary-intercept `sd(id)` variance and standard-error output is covered. This task does NOT cover Julia, other response families, other NB2 effect types, or interval calibration.
