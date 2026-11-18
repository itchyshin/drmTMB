# After Task: native Bernoulli animal-slope outputs

## 1. Goal

Carry the animal random-slope design through native q=1 structured-effect prediction and fresh marginal simulation while preserving intercept behavior.

## 2. Implemented

The q=1 contribution helper now multiplies each indexed latent value by its stored design value. This applies the row's slope loading in conditional predictions and fresh marginal draws.

For an animal slope, observation i receives `x_i b_g`, where b has the fitted animal covariance. The helper multiplies the indexed latent coefficient by `x_i`. For an intercept, the design is one and the previous contribution is unchanged.

## 3a. Decisions and Rejected Alternatives

The zero-row regression check needs a real `x = 0` observation. Replacing one endpoint in the earlier 32-row fixture broke predictor balance and produced a poor SD-slope estimate, so the final fixture uses 33 symmetric points from -1 to 1. The recovery tolerance was not relaxed.

## 4. Files Touched

- `R/methods.R`: q=1 structured-effect contributions apply the stored design; the shared worktree contains other general-SD programme changes outside this slice.
- `tests/testthat/test-binomial-animal-slope-sd-regression.R`: conditional predictions and fresh draws include zero-design and within-group proportionality checks.
- `docs/dev-log/general-sd-regression/binomial-animal-slope-output-GATES.md`: gate and independent-review evidence.
- `docs/dev-log/check-log.d/2026-10-21-native-binomial-animal-slope-output.md`: exact check receipt.
- This report.

## 5. Checks Run

The focused command `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'results <- devtools::test(filter = "binomial-animal-slope-sd-regression", reporter = "summary"); if (!testthat:::all_passed(results)) quit(status = 1); cat("ANIMAL_SLOPE_TESTS_PASS\\n")'` passed and printed `ANIMAL_SLOPE_TESTS_PASS`. The Unlazy leaf rerun passed G1 and G2. The independent review is recorded in G3. The test output stated that no live Julia tests ran in this R invocation. No full package check or interval-coverage campaign was run.

The scoped whitespace check and an explicit fixture count check passed. The report's style scan found 0 findings (1.7 per 1,000 words; 0 em dashes). The report structure checker is being run against this file. The full programme acceptance ledger remains outside this slice's completion claim.

## 6. Tests of the Tests

An independent reviewer found that the previous 32-point fixture had no exact zero, so its zero-row assertions did not test anything. Replacing an endpoint with zero caused the slope recovery assertion and a numerical SD prediction assertion to fail. Using 33 symmetric points restored predictor balance while retaining one zero row per group. The focused suite then passed, and `expect_gt(sum(fx$data$x == 0), 0L)` makes the condition explicit.

## 7a. Issue Ledger

Read-only GitHub searches used `repo:itchyshin/drmTMB animal slope random effect sd` and `repo:itchyshin/drmTMB predictor-dependent random-effect SD prediction simulation`, filtered to open issues. They returned no narrowly matching issue. The broad simulation framework issue #59 is not specific to this output correction. No issue was opened, commented on, or closed.

## 8. Consistency Audit

For q=1, `phylo_mu_contribution()` multiplies the indexed latent value by its design column. An intercept design of one leaves the contribution unchanged; an animal slope uses its row-level loading. The marginal simulator uses the same helper. This aligns conditional and fresh-draw output with the fitted slope model. The test and gate describe this limited behavior; no formula grammar or likelihood changed.

## 9. What Did Not Go Smoothly

The first fixture correction inserted zero by overwriting an endpoint and disturbed predictor balance. That test failed, which exposed the fixture problem. The final symmetric odd-length design fixed it without changing the recovery threshold.

## 10. Known Residuals

This slice does not cover profile or bootstrap refit behavior, calibrated uncertainty, other structured providers, broader response families, or full Julia parity. The broad general-SD goal remains active. No email was sent.

## 11. Team Learning

Add explicit fixture invariants for design conditions used by assertions. When adjusting a synthetic design, preserve the estimability properties that recovery tests depend on before considering any tolerance change.

## 12. Cross-Product Coverage

This is a native R/TMB output-path correction for one Bernoulli animal slope. It covers q=1 conditional prediction and fresh marginal draws, with the intercept behavior protected by the design-multiplier implementation and independent review. It does NOT cover profile, bootstrap, uncertainty calibration, other providers or response families, Julia execution, or the broader response-family and random-effect cross-product.
