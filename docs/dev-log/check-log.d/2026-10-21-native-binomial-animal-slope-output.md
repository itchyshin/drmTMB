# Check log: native Bernoulli animal-slope outputs

## Scope

The q=1 native structured-effect prediction and fresh marginal-draw helper now applies the stored animal slope design. Intercepts remain unchanged because their design column is one.

## Checks

- `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 Rscript -e 'results <- devtools::test(filter = "binomial-animal-slope-sd-regression", reporter = "summary"); if (!testthat:::all_passed(results)) quit(status = 1); cat("ANIMAL_SLOPE_TESTS_PASS\\n")'`: PASS. The suite completed with no failures and printed `ANIMAL_SLOPE_TESTS_PASS`.
- `git diff --check -- R/methods.R` plus whitespace/newline validation of `tests/testthat/test-binomial-animal-slope-sd-regression.R`: PASS.
- Fixture guard: `expect_gt(sum(fx$data$x == 0), 0L)` with 33 equally spaced predictor values per group: PASS; the design is symmetric and contains an exact zero.
- Independent code review: PASS for q=1 intercept safety, slope-design application, and shared marginal simulator path. Reviewer did not execute tests.
- Unlazy leaf `binomial-animal-slope-output-GATES.md`: G1 focused test PASS; G2 scoped whitespace PASS; G3 independent review recorded.

## Limits

This focused R run does not exercise a live Julia engine and does not establish profile/bootstrap refit behavior or interval calibration. Those remain open in the programme.
