# Check log — IC and Wald confint convergence warnings (#1891, #1892)

- `R_LIBS_USER=~/R/library devtools::load_all()`
- `testthat::test_file("tests/testthat/test-issue-1892-ic-convergence-warning.R")` — PASS (11)
- `testthat::test_file("tests/testthat/test-issue-1891-confint-wald-nonfinite.R")` — PASS (4)
- `testthat::test_file("tests/testthat/test-information-criterion-guard.R")` — PASS (16)