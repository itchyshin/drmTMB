#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (!identical(args, "--contract") && !identical(args, "--independent")) {
  stop("Usage: Rscript tools/verify-ou-v1-oracle.R --contract|--independent", call. = FALSE)
}

native_test <- "tests/testthat/test-phylo-ou-covariance-native.R"
r1_verifier <- "tools/verify-phylo-ou-sigma-recovery-calibration.R"
fail <- function(message) stop(message, call. = FALSE)

check_contract <- function() {
  text <- paste(readLines(native_test, warn = FALSE), collapse = "\n")
  required <- c(
    "independent dense oracle", "joint OU conditional objective, score, and Hessian",
    "swapped_rate", "missing_root", "wrong_transition", "missing_sigma", "permuted_registry"
  )
  if (!all(vapply(required, grepl, logical(1L), x = text, fixed = TRUE))) {
    fail("Native OU test does not declare the required independent-oracle mutations.")
  }
  cat("OU_V1_INDEPENDENT_ORACLE_CONTRACT_PASS\n")
}

run_checked <- function(command, args) {
  output <- system2(command, args, stdout = TRUE, stderr = TRUE)
  if (!is.null(attr(output, "status")) && attr(output, "status") != 0L) {
    fail(paste(output, collapse = "\n"))
  }
  output
}

check_independent <- function() {
  check_contract()
  r1 <- run_checked("Rscript", c(r1_verifier, "--oracle"))
  if (!any(grepl("PHYLO_OU_SIGMA_R1_ORACLE_PASS", r1, fixed = TRUE))) {
    fail("The root-edge oracle did not pass.")
  }
  expression <- sprintf("testthat::test_file(\"%s\")", native_test)
  test <- run_checked("Rscript", c("-e", shQuote(expression)))
  if (!any(grepl("FAIL 0", test, fixed = TRUE))) fail("Native OU oracle test did not report a clean result.")
  cat("OU_V1_INDEPENDENT_ORACLE_PASS\n")
}

if (identical(args, "--contract")) check_contract() else check_independent()
