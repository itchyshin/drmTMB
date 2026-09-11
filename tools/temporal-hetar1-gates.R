#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L || !args[[1L]] %in% c("T4-1", "T4-2", "T4-3", "T4-4", "T4-5")) {
  stop("Implemented gates are T4-1 through T4-5. Evidence, documentation, and close gates remain pending.", call. = FALSE)
}

gate <- args[[1L]]
run_test_file <- function(path) {
  code <- paste(
    "pkgload::load_all('.', compile = TRUE, quiet = TRUE)",
    sprintf("result <- testthat::test_file(%s, reporter = 'silent')", deparse(path)),
    "expectations <- unlist(lapply(result, `[[`, 'results'), recursive = FALSE)",
    "failed <- vapply(expectations, function(x) inherits(x, 'expectation_failure') || inherits(x, 'expectation_error'), logical(1))",
    "quit(status = as.integer(any(failed)))",
    sep = "; "
  )
  status <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", "-e", shQuote(code)), stdout = FALSE, stderr = FALSE
  )
  if (!identical(status, 0L)) {
    stop(sprintf("%s failed in its isolated R process.", path), call. = FALSE)
  }
}

if (identical(gate, "T4-1")) {
  run_test_file("tests/testthat/test-temporal-hetar1-parser.R")
  cat("TEMPORAL_HETAR1_T4_1_PASS\n")
} else if (identical(gate, "T4-2")) {
  run_test_file("tests/testthat/test-temporal-hetar1-native.R")
  cat("TEMPORAL_HETAR1_T4_2_PASS\n")
} else if (identical(gate, "T4-3")) {
  run_test_file("tests/testthat/test-temporal-hetar1-native.R")
  cat("TEMPORAL_HETAR1_T4_3_PASS\n")
} else if (identical(gate, "T4-4")) {
  run_test_file("tests/testthat/test-temporal-hetar1-native.R")
  cat("TEMPORAL_HETAR1_T4_4_PASS\n")
} else {
  run_test_file("tests/testthat/test-temporal-hetar1-reductions.R")
  cat("TEMPORAL_HETAR1_T4_5_PASS\n")
}
