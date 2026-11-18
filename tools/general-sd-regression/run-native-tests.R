# Run against a separately installed, freshly compiled package. The source-only
# runner is deliberately separate so assembly checks cannot become fit evidence.
library_path <- Sys.getenv("DRMTMB_SD_TEST_LIBRARY")
if (!nzchar(library_path)) stop("Set DRMTMB_SD_TEST_LIBRARY to the isolated install")
.libPaths(c(library_path, .libPaths()))
library(testthat)
library(drmTMB)
expected <- normalizePath(file.path(library_path, "drmTMB"), mustWork = TRUE)
if (!identical(normalizePath(find.package("drmTMB")), expected)) {
  stop("Loaded a different drmTMB installation")
}
cat("Compiled package: ", expected, "\n", sep = "")
test_env <- new.env(parent = asNamespace("drmTMB"))
sys.source("tests/testthat/helper-binomial-sd-regression.R", envir = test_env)
sys.source("tests/testthat/helper-gaussian-random-effect-scale.R", envir = test_env)
sys.source("tests/testthat/helper-convergence-warning.R", envir = test_env)
if (file.exists("tests/testthat/helper-poisson-sd-regression.R")) {
  sys.source("tests/testthat/helper-poisson-sd-regression.R", envir = test_env)
}
if (file.exists("tests/testthat/helper-poisson-slope-sd-reference.R")) {
  sys.source("tests/testthat/helper-poisson-slope-sd-reference.R", envir = test_env)
}
if (file.exists("tests/testthat/helper-lognormal-sd-reference.R")) {
  sys.source("tests/testthat/helper-lognormal-sd-reference.R", envir = test_env)
}
paths <- commandArgs(trailingOnly = TRUE)
if (!length(paths)) {
  paths <- file.path("tests", "testthat", c(
    "test-binomial-random-effect-scale.R", "test-binomial-sd-integration.R",
    "test-binomial-sd-links.R", "test-binomial-sd-profile.R",
    "test-binomial-sd-simulation.R", "test-binomial-sd-clamp.R"
  ))
}
for (path in paths) {
  testthat::test_file(path, reporter = "summary", env = test_env,
                      stop_on_failure = TRUE)
}
tested_files <- unique(basename(paths))
cat("NATIVE_SD_TESTS_PASS files=", paste(tested_files, collapse = ","), "\n", sep = "")
if (any(grepl("^test-binomial-", basename(paths)))) {
  # Retain the established gate marker only when binomial tests actually ran.
  cat("NATIVE_BINOMIAL_SD_PASS\n")
}
