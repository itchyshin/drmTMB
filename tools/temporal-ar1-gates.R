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
  artifact_dir <- "docs/dev-log/simulation-artifacts/2026-09-08-temporal-ar1-local-recovery-final-source"
  required <- file.path(artifact_dir, c(
    "raw-attempts.csv", "recovery-estimates.csv", "criteria.csv",
    "provenance.csv", "recovery-results.rds", "session-info.txt", "RESULTS.md"
  ))
  if (!all(file.exists(required))) {
    stop("G11 recovery artifacts are missing; run tools/run-temporal-ar1-recovery.R.", call. = FALSE)
  }
  attempts <- utils::read.csv(file.path(artifact_dir, "raw-attempts.csv"))
  criteria <- utils::read.csv(file.path(artifact_dir, "criteria.csv"))
  provenance <- utils::read.csv(file.path(artifact_dir, "provenance.csv"), stringsAsFactors = FALSE)
  source_commit <- provenance$value[provenance$key == "source_commit"]
  runner_md5 <- provenance$value[provenance$key == "runner_md5"]
  implementation_changed <- system2(
    "git", c("diff", "--name-only", paste0(source_commit, "..HEAD"), "--", "R", "src", "DESCRIPTION", "NAMESPACE"),
    stdout = TRUE
  )
  expected_fixtures <- as.vector(outer(c("ar1_only", "ordinary_plus_ar1"), sprintf("P%02d", 1:6), paste, sep = "_"))
  expected_starts <- sort(rep(c(-0.3, 0.3), length(expected_fixtures)))
  if (length(source_commit) != 1L || length(runner_md5) != 1L ||
      !identical(runner_md5, unname(tools::md5sum("tools/run-temporal-ar1-recovery.R"))) ||
      length(implementation_changed) != 0L ||
      nrow(attempts) != 24L || !identical(sort(unique(attempts$fixture)), sort(expected_fixtures)) ||
      !all(table(attempts$fixture) == 2L) ||
      !identical(sort(attempts$persistence_start), expected_starts) ||
      !all(tapply(attempts$selected, attempts$fixture, sum) == 1L) ||
      nrow(criteria) != 5L || !all(criteria$pass)) {
    stop("G11 retained recovery artifacts do not meet their predeclared checks.", call. = FALSE)
  }
  cat("TEMPORAL_G11_PASS\n")
  quit(save = "no", status = 0L)
}
if (identical(gate, "G12")) {
  artifact_dir <- "docs/dev-log/simulation-artifacts/2026-09-08-temporal-ar1-calibration-pilot-final-source"
  required <- file.path(artifact_dir, c(
    "raw-attempts.csv", "pilot-results.csv", "pilot-summary.csv",
    "provenance.csv", "pilot-results.rds", "session-info.txt", "resource-replay.txt", "RESULTS.md",
    "C1-SEED-2026091002-DIAGNOSIS.md"
  ))
  if (!all(file.exists(required))) {
    stop("G12 pilot artifacts are missing; run tools/run-temporal-ar1-pilot.R through /usr/bin/time -l.", call. = FALSE)
  }
  attempts <- utils::read.csv(file.path(artifact_dir, "raw-attempts.csv"))
  results <- utils::read.csv(file.path(artifact_dir, "pilot-results.csv"))
  provenance <- utils::read.csv(file.path(artifact_dir, "provenance.csv"), stringsAsFactors = FALSE)
  source_commit <- provenance$value[provenance$key == "source_commit"]
  runner_md5 <- provenance$value[provenance$key == "runner_md5"]
  implementation_changed <- system2(
    "git", c("diff", "--name-only", paste0(source_commit, "..HEAD"), "--", "R", "src", "DESCRIPTION", "NAMESPACE"),
    stdout = TRUE
  )
  resource <- readLines(file.path(artifact_dir, "resource-replay.txt"), warn = FALSE)
  expected_fixtures <- as.vector(outer(c("C1", "C2", "C3", "C4", "C5"), 2026091001:2026091005, paste, sep = "_"))
  expected_starts <- sort(rep(c(-0.3, 0.3), length(expected_fixtures)))
  if (length(source_commit) != 1L || length(runner_md5) != 1L ||
      !identical(runner_md5, unname(tools::md5sum("tools/run-temporal-ar1-pilot.R"))) ||
      length(implementation_changed) != 0L ||
      nrow(results) != 25L || !identical(sort(results$fixture), sort(expected_fixtures)) || nrow(attempts) != 50L ||
      !all(table(attempts$fixture) == 2L) ||
      !identical(sort(attempts$persistence_start), expected_starts) ||
      !all(tapply(attempts$selected, attempts$fixture, sum) == 1L) ||
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
if (identical(gate, "G14")) {
  source_root <- normalizePath(".", mustWork = TRUE)
  check_root <- tempfile("temporal-ar1-package-check-")
  dir.create(check_root)
  on.exit(unlink(check_root, recursive = TRUE, force = TRUE), add = TRUE)
  old_wd <- getwd()
  on.exit(setwd(old_wd), add = TRUE)
  setwd(check_root)
  build_status <- system2("R", c("CMD", "build", source_root))
  tarballs <- list.files(check_root, pattern = "^drmTMB_.*\\.tar\\.gz$", full.names = TRUE)
  if (build_status != 0L || length(tarballs) != 1L) {
    stop("G14 could not build a clean temporal-AR1 source tarball.", call. = FALSE)
  }
  check_status <- system2("R", c("CMD", "check", tarballs[[1L]]))
  check_log <- file.path(check_root, "drmTMB.Rcheck", "00check.log")
  check_text <- if (file.exists(check_log)) readLines(check_log, warn = FALSE) else character()
  if (check_status != 0L || !any(grepl("^Status: OK$", check_text))) {
    stop("G14 package check did not report Status: OK.", call. = FALSE)
  }
  cat("TEMPORAL_G14_PASS\n")
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
