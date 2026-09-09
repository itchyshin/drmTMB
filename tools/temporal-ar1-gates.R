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
  G5 = "tests/testthat/test-temporal-identities.R",
  G6 = "tests/testthat/test-temporal-gaussian-smoke.R",
  G7 = "tests/testthat/test-temporal-gaussian-smoke.R",
  G8 = "tests/testthat/test-temporal-gaussian-smoke.R",
  G9 = "tests/testthat/test-temporal-gaussian-smoke.R",
  G10 = "tests/testthat/test-temporal-gaussian-smoke.R",
  G11 = NULL,
  G12 = NULL,
  G13 = NULL,
  NULL
)
if (identical(gate, "G11")) {
  artifact_dir <- "docs/dev-log/simulation-artifacts/2026-09-08-temporal-ar1-local-recovery"
  required <- file.path(artifact_dir, c(
    "raw-attempts.csv", "recovery-estimates.csv", "criteria.csv",
    "provenance.csv", "recovery-results.rds", "RESULTS.md"
  ))
  if (!all(file.exists(required))) {
    stop("G11 recovery artifacts are missing; run tools/run-temporal-ar1-recovery.R.", call. = FALSE)
  }
  attempts <- utils::read.csv(file.path(artifact_dir, "raw-attempts.csv"))
  criteria <- utils::read.csv(file.path(artifact_dir, "criteria.csv"))
  if (nrow(attempts) != 24L || !all(table(attempts$fixture) == 2L) ||
      nrow(criteria) != 5L || !all(criteria$pass)) {
    stop("G11 retained recovery artifacts do not meet their predeclared checks.", call. = FALSE)
  }
  cat("TEMPORAL_G11_PASS\n")
  quit(save = "no", status = 0L)
}
if (identical(gate, "G12")) {
  artifact_dir <- "docs/dev-log/simulation-artifacts/2026-09-08-temporal-ar1-calibration-pilot"
  required <- file.path(artifact_dir, c(
    "raw-attempts.csv", "pilot-results.csv", "pilot-summary.csv",
    "provenance.csv", "pilot-results.rds", "resource-replay.txt", "RESULTS.md",
    "C1-SEED-2026091002-DIAGNOSIS.md"
  ))
  if (!all(file.exists(required))) {
    stop("G12 pilot artifacts are missing; run tools/run-temporal-ar1-pilot.R through /usr/bin/time -l.", call. = FALSE)
  }
  attempts <- utils::read.csv(file.path(artifact_dir, "raw-attempts.csv"))
  results <- utils::read.csv(file.path(artifact_dir, "pilot-results.csv"))
  resource <- readLines(file.path(artifact_dir, "resource-replay.txt"), warn = FALSE)
  if (nrow(results) != 25L || nrow(attempts) != 50L ||
      !all(table(attempts$fixture) == 2L) ||
      !all(results$selected & is.finite(results$objective)) ||
      !all(is.finite(results$elapsed_sec) & results$elapsed_sec > 0) ||
      !any(grepl("maximum resident set size", resource, fixed = TRUE))) {
    stop("G12 retained pilot artifacts do not meet their completeness checks.", call. = FALSE)
  }
  cat("TEMPORAL_G12_PASS\n")
  quit(save = "no", status = 0L)
}
if (identical(gate, "G13")) {
  pkgload::load_all(".", quiet = TRUE)
  output_dir <- tempfile("temporal-ar1-render-")
  dir.create(output_dir)
  rendered <- rmarkdown::render(
    "vignettes/temporal-random-effects.Rmd",
    output_dir = output_dir,
    quiet = TRUE
  )
  if (!file.exists(rendered)) {
    stop("G13 did not create the temporal AR1 tutorial HTML.", call. = FALSE)
  }
  html <- paste(readLines(rendered, warn = FALSE), collapse = "\n")
  required_text <- c("Temporal AR1 random effects", "What the intervals cover")
  if (!all(vapply(required_text, grepl, logical(1), x = html, fixed = TRUE))) {
    stop("G13 rendered tutorial is missing required reader-facing sections.", call. = FALSE)
  }
  cat("TEMPORAL_G13_PASS\n")
  quit(save = "no", status = 0L)
}
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
