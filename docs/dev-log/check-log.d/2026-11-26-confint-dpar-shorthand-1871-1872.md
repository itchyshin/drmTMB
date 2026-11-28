# 2026-11-26 confint bare dpar shorthand (#1871, #1872)

Approved decision: a bare dpar name (for example `parm = "mu"`) expands to all of that dpar's fixef targets.

Evidence: `NOT_CRAN=true Rscript` → `testthat::test_file("tests/testthat/test-confint-dpar-shorthand.R")` PASS.