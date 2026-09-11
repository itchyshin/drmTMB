#!/usr/bin/env Rscript

# Fail-closed gate runner for the phylogenetic OU covariance arc.
# Only PO1 is runnable during orientation. Later gates deliberately refuse to
# assert success until their implementation fixtures exist.
args <- commandArgs(trailingOnly = TRUE)
allowed <- c(paste0("PO", 1:12))
if (length(args) < 1L || length(args) > 2L || !args[[1L]] %in% allowed ||
    (length(args) == 2L && !identical(args[[2L]], "--reverify"))) {
  stop("Usage: Rscript --vanilla tools/phylo-ou-covariance-gates.R PO1|...|PO12 [--reverify]", call. = FALSE)
}

gate <- args[[1L]]
reverify <- length(args) == 2L
run_test_file <- function(path, compile = FALSE) {
  code <- paste(
    sprintf("pkgload::load_all('.', compile = %s, quiet = TRUE)", if (compile) "TRUE" else "FALSE"),
    sprintf("result <- testthat::test_file(%s, reporter = 'silent')", deparse(path)),
    "expectations <- unlist(lapply(result, `[[`, 'results'), recursive = FALSE)",
    "failed <- vapply(expectations, function(x) inherits(x, 'expectation_failure') || inherits(x, 'expectation_error'), logical(1))",
    "quit(status = as.integer(any(failed)))",
    sep = "; "
  )
  status <- system2(file.path(R.home("bin"), "Rscript"), c("--vanilla", "-e", shQuote(code)))
  if (!identical(status, 0L)) {
    stop(sprintf("%s failed in its isolated R process.", path), call. = FALSE)
  }
}

if (identical(gate, "PO1")) {
  if (reverify) stop("PO1 does not accept --reverify.", call. = FALSE)
  plan <- "docs/dev-log/plans/2026-09-11-phylo-ou-covariance/PLAN.md"
  ledger <- "docs/dev-log/plans/2026-09-11-phylo-ou-covariance/unlazy/GATES.md"
  required_plan <- c(
    "phylo(1 | species, tree = tree, model = \"bm\")",
    "phylo(1 | species, tree = tree, model = \"ou\")",
    "ape::corMartins",
    "not** a BM limit"
  )
  text <- if (file.exists(plan)) paste(readLines(plan, warn = FALSE), collapse = "\n") else ""
  ledger_text <- if (file.exists(ledger)) paste(readLines(ledger, warn = FALSE), collapse = "\n") else ""
  if (!all(vapply(required_plan, grepl, logical(1), x = text, fixed = TRUE)) ||
      !grepl("PHYLO_OU_COVARIANCE_PO2_PASS", ledger_text, fixed = TRUE)) {
    stop("PO1 plan or ledger contract is incomplete.", call. = FALSE)
  }
  cat("PHYLO_OU_COVARIANCE_PO1_PASS\n")
} else if (identical(gate, "PO2")) {
  if (reverify) stop("PO2 does not accept --reverify.", call. = FALSE)
  run_test_file("tests/testthat/test-phylo-ou-covariance-parser.R")
  cat("PHYLO_OU_COVARIANCE_PO2_PASS\n")
} else if (identical(gate, "PO3")) {
  if (reverify) stop("PO3 does not accept --reverify.", call. = FALSE)
  run_test_file("tests/testthat/test-phylo-ou-covariance-parser.R", compile = TRUE)
  run_test_file("tests/testthat/test-phylo-ou-covariance-native.R")
  cat("PHYLO_OU_COVARIANCE_PO3_PASS\n")
} else if (identical(gate, "PO4")) {
  if (reverify) stop("PO4 does not accept --reverify.", call. = FALSE)
  run_test_file("tests/testthat/test-phylo-ou-covariance-native.R", compile = TRUE)
  cat("PHYLO_OU_COVARIANCE_PO4_PASS\n")
} else {
  stop(
    sprintf("%s is pending: its gate has no accepted implementation evidence yet.", gate),
    call. = FALSE
  )
}
