#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
gate_arg <- grep("^--gate=", args, value = TRUE)
if (!length(gate_arg)) {
  at <- match("--gate", args)
  if (!is.na(at) && length(args) >= at + 1L) gate_arg <- paste0("--gate=", args[[at + 1L]])
}
if (!length(gate_arg)) stop("usage: Rscript tools/check-cmr.R --gate exact|derivatives", call. = FALSE)
gate <- sub("^--gate=", "", gate_arg[[1L]])
if (!gate %in% c("exact", "derivatives", "parity")) {
  stop("CMR_GATE_UNAVAILABLE: this M1 lane implements exact, derivatives and parity; integration, selection, recovery, and documentation gates remain future work.", call. = FALSE)
}

if (!requireNamespace("devtools", quietly = TRUE)) stop("devtools is required to load drmTMB and its TMB DLL.", call. = FALSE)
devtools::load_all(".", quiet = TRUE)
if (gate == "parity") {
  source("tools/check-cmr-parity.R")
  quit(status = 0L)
}
files <- if (gate == "exact") {
  c("tests/testthat/test-cmr-data.R", "tests/testthat/test-cmr-exact.R", "tests/testthat/test-cmr-contract.R")
} else {
  "tests/testthat/test-cmr-derivatives.R"
}
for (file in files) {
  if (!file.exists(file)) stop("CMR_GATE_ERROR: required test file is missing: ", file, call. = FALSE)
  results <- testthat::test_file(file, package = "drmTMB", reporter = "summary",
                                 stop_on_failure = TRUE)
  expectations <- unlist(lapply(results, function(test) test$results), recursive = FALSE)
  if (!length(expectations)) stop("CMR_GATE_ERROR: test file executed no expectations: ", file, call. = FALSE)
  failed <- vapply(expectations, function(x) inherits(x, c("expectation_failure", "expectation_error")), logical(1))
  if (any(failed)) stop("CMR_GATE_ERROR: failed expectations in ", file, call. = FALSE)
}
cat(if (gate == "exact") "CMR_EXACT_OK\n" else "CMR_DERIVATIVES_OK\n")
