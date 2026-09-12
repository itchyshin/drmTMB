#!/usr/bin/env Rscript

# Focused acceptance commands for the ML-only joint independent phylogenetic
# OU location/log-scale intercept slice. Each gate reports one Unlazy token.

args <- commandArgs(trailingOnly = TRUE)
gate <- if (length(args) == 1L) args[[1L]] else ""

if (!requireNamespace("pkgload", quietly = TRUE) ||
    !requireNamespace("testthat", quietly = TRUE)) {
  stop("This gate needs pkgload and testthat in the active R library.", call. = FALSE)
}

pkgload::load_all(".", compile = TRUE, quiet = TRUE)
run_test <- function(file) {
  result <- testthat::test_file(file, reporter = "summary")
  failed <- unlist(lapply(result, function(test) vapply(
    test$results,
    function(expectation) inherits(expectation, "expectation_failure") ||
      inherits(expectation, "expectation_error"),
    logical(1L)
  )), use.names = FALSE)
  if (any(failed)) quit(status = 1L)
}

if (identical(gate, "G1")) {
  run_test("tests/testthat/test-phylo-ou-covariance-parser.R")
} else if (identical(gate, "G2") || identical(gate, "G3")) {
  run_test("tests/testthat/test-phylo-ou-covariance-native.R")
} else if (identical(gate, "G4")) {
  run_test("tests/testthat/test-phylo-ou-covariance-parser.R")
  run_test("tests/testthat/test-phylo-ou-covariance-native.R")
} else if (identical(gate, "G5")) {
  run_test("tests/testthat/test-phylo-gaussian.R")
} else if (identical(gate, "G6")) {
  status <- system2(
    "Rscript",
    c("--vanilla", "tools/run-phylo-ou-sigma-recovery-preflight.R", "--check"),
    stdout = TRUE, stderr = TRUE
  )
  cat(status, sep = "\n")
  if (!any(grepl("PHYLO_OU_SIGMA_NEGATIVE_PREFLIGHT_PASS", status, fixed = TRUE))) {
    quit(status = 1L)
  }
} else if (identical(gate, "G9")) {
  docs <- c(
    "R/formula-markers.R", "docs/design/01-formula-grammar.md",
    "docs/design/03-likelihoods.md", "README.md", "NEWS.md",
    "docs/dev-log/known-limitations.md", "vignettes/formula-grammar.Rmd",
    "vignettes/phylogenetic-models.Rmd", "vignettes/implementation-map.Rmd"
  )
  text <- paste(unlist(lapply(docs, readLines, warn = FALSE)), collapse = "\n")
  required <- c("decay_phylo:sigma", "alpha_sigma", "alpha_mu", "independent", "REML")
  if (!all(vapply(required, grepl, logical(1L), x = text, fixed = TRUE))) {
    stop("Joint OU documentation is missing a required capability boundary.", call. = FALSE)
  }
  stale <- c(
    "does not create `alpha_sigma`", "sigma-side OU/`alpha_sigma`",
    "phylogenetic residual-scale OU field (`alpha_sigma`)"
  )
  if (any(vapply(stale, grepl, logical(1L), x = text, fixed = TRUE))) {
    stop("Joint OU documentation still says alpha_sigma is deferred.", call. = FALSE)
  }
} else {
  stop("Usage: tools/phylo-ou-sigma-gates.R {G1|G2|G3|G4|G5|G6|G9}", call. = FALSE)
}

cat(sprintf("PHYLO_OU_SIGMA_%s_PASS\n", gate))
