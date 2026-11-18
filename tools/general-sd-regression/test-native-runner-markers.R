runner <- "tools/general-sd-regression/run-native-tests.R"
expressions <- as.list(parse(runner))
source_text <- vapply(expressions, function(x) {
  paste(deparse(x), collapse = "")
}, character(1L))
marker_start <- grep("^tested_files <- unique\\(basename\\(paths\\)\\)",
                     source_text)
stopifnot(length(marker_start) == 1L,
          marker_start + 2L == length(expressions))

run_markers <- function(paths) {
  env <- new.env(parent = baseenv())
  env$paths <- paths
  capture.output(for (i in marker_start:length(expressions)) {
    eval(expressions[[i]], envir = env)
  })
}

lognormal <- run_markers("tests/testthat/test-lognormal-sd-integration.R")
binomial <- run_markers("tests/testthat/test-binomial-sd-integration.R")
beta_binomial <- run_markers("tests/testthat/test-beta-binomial.R")
mixed <- run_markers(c("tests/testthat/test-lognormal-sd-integration.R",
                       "tests/testthat/test-binomial-sd-integration.R"))

stopifnot(identical(lognormal,
                    "NATIVE_SD_TESTS_PASS files=test-lognormal-sd-integration.R"),
          identical(binomial,
                    c("NATIVE_SD_TESTS_PASS files=test-binomial-sd-integration.R",
                      "NATIVE_BINOMIAL_SD_PASS")),
          identical(beta_binomial,
                    "NATIVE_SD_TESTS_PASS files=test-beta-binomial.R"),
          identical(mixed,
                    c(paste("NATIVE_SD_TESTS_PASS files=",
                            "test-lognormal-sd-integration.R,",
                            "test-binomial-sd-integration.R", sep = ""),
                      "NATIVE_BINOMIAL_SD_PASS")))
cat("NATIVE_RUNNER_MARKERS_PASS cases=4\n")
