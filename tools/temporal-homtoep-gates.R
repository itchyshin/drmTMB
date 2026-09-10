#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L || !args[[1L]] %in% c("T3-1", "T3-2", "T3-3", "T3-4")) {
  stop("Only `T3-1`, `T3-2`, `T3-3`, and `T3-4` are implemented in this runner. Other gates remain pending.", call. = FALSE)
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
    c("--vanilla", "-e", shQuote(code)),
    stdout = FALSE,
    stderr = FALSE
  )
  if (!identical(status, 0L)) {
    stop(sprintf("%s failed in its isolated R process.", path), call. = FALSE)
  }
}

if (identical(gate, "T3-1")) {
  run_test_file("tests/testthat/test-temporal-homtoep-parser.R")
  cat("TEMPORAL_HOMTOEP_T3_1_PASS\n")
} else if (identical(gate, "T3-2")) {
  source("tools/temporal-homtoep-map-study.R")
  result <- homtoep_map_study()
  if (result$draws != 480L ||
      result$minimum_eigenvalue <= 1e-13 ||
      result$derivative_difference >= 1e-4 ||
      result$lagwise_counterexample_minimum_eigenvalue >= 0 ||
      result$generic_cholesky_toeplitz_deviation <= 1e-3) {
    stop("T3-2 map study did not satisfy its prespecified acceptance criteria.", call. = FALSE)
  }

  eta <- c(-1.3, 0.2, 1.1, -0.7, 0.4)
  rho <- homtoep_reflection_rho(eta)
  if (max(abs(homtoep_eta_from_rho(rho) - eta)) >= 1e-10 ||
      max(abs(homtoep_reflection_cor(eta) - homtoep_dense_from_lags(rho))) >= 1e-13 ||
      max(abs(homtoep_reflection_cor(eta) - stats::toeplitz(rho))) >= 1e-13) {
    stop("T3-2 reconstruction or dense-reference check failed.", call. = FALSE)
  }

  cat("TEMPORAL_HOMTOEP_T3_2_PASS\n")
} else if (identical(gate, "T3-3")) {
  run_test_file("tests/testthat/test-temporal-homtoep-native.R")
  cat("TEMPORAL_HOMTOEP_T3_3_PASS\n")
} else {
  run_test_file("tests/testthat/test-temporal-homtoep-native.R")
  cat("TEMPORAL_HOMTOEP_T3_4_PASS\n")
}
