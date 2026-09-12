#!/usr/bin/env Rscript

# Focused, reproducible acceptance commands for the first predictor-aware
# phylogenetic OU field.  Keep this runner intentionally small: each gate is
# evidence, not a substitute for the retained recovery/empirical campaign.

args <- commandArgs(trailingOnly = TRUE)
gate <- if (length(args) == 1L) args[[1L]] else ""
files <- switch(
  gate,
  G1 = c(
    "tests/testthat/test-phylo-ou-covariance-parser.R",
    "tests/testthat/test-phylo-ou-covariance-native.R"
  ),
  G2 = "tests/testthat/test-phylo-ou-covariance-native.R",
  G3 = "tests/testthat/test-phylo-ou-covariance-native.R",
  G4 = c(
    "tests/testthat/test-phylo-ou-covariance-parser.R",
    "tests/testthat/test-phylo-ou-covariance-native.R"
  ),
  stop("Usage: tools/phylo-ou-general-gates.R {G1|G2|G3|G4}", call. = FALSE)
)

if (!requireNamespace("pkgload", quietly = TRUE) ||
    !requireNamespace("testthat", quietly = TRUE)) {
  stop("This gate needs pkgload and testthat in the active R library.", call. = FALSE)
}

pkgload::load_all(".", compile = TRUE, quiet = TRUE)
results <- lapply(files, testthat::test_file, reporter = "summary")
failed <- unlist(lapply(
  results,
  function(result) unlist(lapply(result, function(test) vapply(
    test$results,
    function(expectation) inherits(expectation, "expectation_failure") ||
      inherits(expectation, "expectation_error"),
    logical(1L)
  )), use.names = FALSE)
), use.names = FALSE)
if (any(failed)) {
  quit(status = 1L)
}
cat(sprintf("PHYLO_OU_%s_PASS\n", gate))
