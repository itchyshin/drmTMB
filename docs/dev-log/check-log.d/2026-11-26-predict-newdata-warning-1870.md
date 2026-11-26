# 2026-11-26 predict newdata warning (#1870)

Approved decision: keep `predict(newdata)` population-level; warn once per session when random effects are omitted; document in `?predict.drmTMB`.

Evidence: `NOT_CRAN=true Rscript` → `testthat::test_file("tests/testthat/test-predict-newdata-random-effects-warning.R")` PASS.