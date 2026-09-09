#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L || !grepl("^G([1-9]|1[0-8])$", args[[1L]])) {
  stop("Usage: Rscript --vanilla tools/temporal-ar1-gates.R G<number>", call. = FALSE)
}

gate <- args[[1L]]
files <- switch(
  gate,
  G1 = "tests/testthat/test-temporal-parser.R",
  G2 = "tests/testthat/test-temporal-gaussian-smoke.R",
  G3 = "tests/testthat/test-temporal-gaussian-smoke.R",
  G4 = "tests/testthat/test-temporal-dense-oracle.R",
  NULL
)
if (is.null(files)) {
  stop(
    sprintf("%s has no implemented executable check yet; its gate remains pending.", gate),
    call. = FALSE
  )
}

pkgload::load_all(".", quiet = TRUE)
results <- lapply(files, testthat::test_file, reporter = "silent")
expectations <- unlist(
  lapply(results, function(result) {
    unlist(lapply(result, `[[`, "results"), recursive = FALSE)
  }),
  recursive = FALSE
)
failed <- vapply(
  expectations,
  function(expectation) {
    inherits(expectation, c("expectation_failure", "expectation_error"))
  },
  logical(1L)
)
if (any(failed)) {
  stop(sprintf("%s failed (%d expectation failure/error result%s).", gate, sum(failed), if (sum(failed) == 1L) "" else "s"), call. = FALSE)
}

cat(sprintf("TEMPORAL_%s_PASS\n", gate))
