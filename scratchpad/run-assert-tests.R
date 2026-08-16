suppressMessages(pkgload::load_all(".", compile = FALSE, quiet = TRUE))
files <- c("test-beta-binomial.R","test-cumulative-logit.R","test-hurdle-nbinom2.R",
           "test-profile-targets.R","test-truncated-nbinom2-location-scale.R",
           "test-zi-nbinom2.R","test-zi-poisson.R")
for (f in files) {
  t0 <- Sys.time()
  res <- as.data.frame(testthat::test_file(file.path("tests/testthat", f), reporter = "silent"))
  el <- round(as.numeric(difftime(Sys.time(), t0, units="secs")),1)
  cat(sprintf("%-46s FAIL=%d WARN=%d PASS=%d  (%ss)\n", f, sum(res$failed), sum(res$warning), sum(res$passed), el))
}
