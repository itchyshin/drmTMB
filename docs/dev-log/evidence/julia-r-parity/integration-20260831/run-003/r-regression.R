pkgload::load_all(quiet=TRUE,recompile=FALSE)
Sys.setenv(NOT_CRAN="false",DRMTMB_JULIA_TESTS="false",OPENBLAS_NUM_THREADS="1")
pattern <- "^(cran-lane-filter|julia-(batch-startup|bridge|bridge-coef-labels|conditional-components|conditional-prediction|gate-vs-engine|joint-(prediction-labels|binary-levels|dispatch|finite-prepare|finite-result|methods|missing|two)|phylo-(labels|polytomy)|predict-newdata|prediction-scales)|missing-predictor-(prediction|public-covariance|transformed-covariance)|selected-state-prediction)$"
cat("RUNTIME",R.version.string,"\n");cat("FILTER",pattern,"\n")
result <- testthat::test_dir("tests/testthat",filter=pattern,reporter="summary",stop_on_failure=TRUE,load_helpers=TRUE)
saveRDS(result,"../receipts-003/r-regression-results.rds")
tab <- as.data.frame(result)
tab <- tab[!vapply(tab,is.list,logical(1))]
write.csv(tab,"../receipts-003/r-regression-results.csv",row.names=FALSE)
cat("R_INTEGRATION_REGRESSION_PASS\n")
