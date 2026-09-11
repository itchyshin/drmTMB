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
} else if (identical(gate, "PO5")) {
  if (reverify) stop("PO5 does not accept --reverify.", call. = FALSE)
  run_test_file("tests/testthat/test-phylo-ou-covariance-native.R", compile = TRUE)
  cat("PHYLO_OU_COVARIANCE_PO5_PASS\n")
} else if (identical(gate, "PO6")) {
  if (reverify) stop("PO6 does not accept --reverify.", call. = FALSE)
  run_test_file("tests/testthat/test-phylo-ou-covariance-native.R", compile = TRUE)
  cat("PHYLO_OU_COVARIANCE_PO6_PASS\n")
} else if (identical(gate, "PO7")) {
  if (reverify) stop("PO7 does not accept --reverify.", call. = FALSE)
  result_path <- "docs/dev-log/plans/2026-09-11-phylo-ou-covariance/recovery/RESULTS.md"
  data_path <- "docs/dev-log/plans/2026-09-11-phylo-ou-covariance/recovery/results.csv"
  if (!file.exists(result_path) || !file.exists(data_path)) {
    stop("PO7 retained recovery output is missing.", call. = FALSE)
  }
  results <- utils::read.csv(data_path, stringsAsFactors = FALSE)
  report <- paste(readLines(result_path, warn = FALSE), collapse = "\n")
  if (nrow(results) != 12L || !all(results$status == "fit") ||
      !all(is.finite(results$objective)) ||
      !grepl("all_fixed_effect_errors_le_0_20: FAIL", report, fixed = TRUE)) {
    stop("PO7 retained recovery assessment is incomplete or its failed intercept criterion was not retained.", call. = FALSE)
  }
  cat("PHYLO_OU_COVARIANCE_PO7_PASS\n")
} else if (identical(gate, "PO8")) {
  if (reverify) stop("PO8 does not accept --reverify.", call. = FALSE)
  pilot_path <- "docs/dev-log/plans/2026-09-11-phylo-ou-covariance/pilot/RESULTS.md"
  if (!file.exists(pilot_path)) stop("PO8 timing receipt is missing.", call. = FALSE)
  pilot <- paste(readLines(pilot_path, warn = FALSE), collapse = "\n")
  required <- c("Fixtures | 5 / 5 complete", "Median elapsed time | 0.240 seconds",
    "Positive-definite Hessians | 5 / 5")
  if (!all(vapply(required, grepl, logical(1), x = pilot, fixed = TRUE))) {
    stop("PO8 timing receipt is incomplete.", call. = FALSE)
  }
  cat("PHYLO_OU_COVARIANCE_PO8_PASS\n")
} else if (identical(gate, "PO9")) {
  if (reverify) stop("PO9 does not accept --reverify.", call. = FALSE)
  required_files <- c(
    "man/phylo.Rd",
    "docs/design/01-formula-grammar.md",
    "docs/design/03-likelihoods.md",
    "vignettes/formula-grammar.Rmd",
    "docs/dev-log/plans/2026-09-11-phylo-ou-covariance/render/formula-grammar.html"
  )
  if (!all(file.exists(required_files))) stop("PO9 required reader artifacts are missing.", call. = FALSE)
  all_text <- paste(vapply(required_files, function(path) {
    paste(readLines(path, warn = FALSE), collapse = "\n")
  }, character(1)), collapse = "\n")
  required_text <- c(
    "model = \"ou\"",
    "decay_phylo",
    "fit$decaypars$phylo[[\"decay_phylo\"]]",
    "inverse",
    "separate from temporal OU",
    "interval"
  )
  if (!all(vapply(required_text, grepl, logical(1), x = all_text, fixed = TRUE))) {
    stop("PO9 reader artifacts do not state the OU-tree boundary.", call. = FALSE)
  }
  cat("PHYLO_OU_COVARIANCE_PO9_PASS\n")
} else if (identical(gate, "PO11")) {
  if (!reverify) stop("PO11 requires --reverify and never launches a new check.", call. = FALSE)
  ledger_path <- "docs/dev-log/plans/2026-09-11-phylo-ou-covariance/unlazy/GATES.md"
  check_path <- "docs/dev-log/plans/2026-09-11-phylo-ou-covariance/closeout/package-check-no-tests.log"
  report_path <- "docs/dev-log/after-task/2026-09-11-phylogenetic-ou-covariance.md"
  if (!all(file.exists(c(ledger_path, check_path, report_path)))) {
    stop("PO11 closeout artifacts are missing.", call. = FALSE)
  }
  ledger <- paste(readLines(ledger_path, warn = FALSE), collapse = "\n")
  check <- paste(readLines(check_path, warn = FALSE), collapse = "\n")
  required_ledger <- sprintf("- [x] PO%d", 0:10)
  required_check <- c(
    "0 errors",
    "formula-grammar.Rmd’ using ‘UTF-8’... OK",
    "checking examples ...",
    "checking package vignettes ... OK"
  )
  if (!all(vapply(required_ledger, grepl, logical(1), x = ledger, fixed = TRUE)) ||
      !all(vapply(required_check, grepl, logical(1), x = check, fixed = TRUE))) {
    stop("PO11 final-source package receipt or prerequisite ledger is incomplete.", call. = FALSE)
  }
  cat("PHYLO_OU_COVARIANCE_PO11_PASS\n")
} else {
  stop(
    sprintf("%s is pending: its gate has no accepted implementation evidence yet.", gate),
    call. = FALSE
  )
}
