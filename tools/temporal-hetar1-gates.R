#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L || length(args) > 2L || !args[[1L]] %in% c("T4-1", "T4-2", "T4-3", "T4-4", "T4-5", "T4-6", "T4-7", "T4-11", "T4-12", "T4-14") ||
    (length(args) == 2L && !identical(args[[2L]], "--reverify"))) {
  stop("Usage: Rscript --vanilla tools/temporal-hetar1-gates.R T4-1|...|T4-7|T4-11|T4-12|T4-14 [--reverify]", call. = FALSE)
}

gate <- args[[1L]]
reverify <- length(args) == 2L
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
    c("--vanilla", "-e", shQuote(code)), stdout = FALSE, stderr = FALSE
  )
  if (!identical(status, 0L)) {
    stop(sprintf("%s failed in its isolated R process.", path), call. = FALSE)
  }
}

artifact_root <- file.path(
  "docs", "dev-log", "simulation-artifacts",
  "2026-09-11-temporal-hetar1-interval-feasibility"
)
verify_artifact <- function(mode, expected_fixtures) {
  out_dir <- file.path(artifact_root, mode)
  required <- file.path(out_dir, c(
    "configuration.csv", "raw-attempts.csv", "fixture-results.csv",
    "interval-results.csv", "summary.csv", "provenance.csv", "results.rds",
    "session-info.txt", "RESULTS.md"
  ))
  if (!all(file.exists(required))) {
    stop(sprintf("%s interval-feasibility artifacts are missing.", mode), call. = FALSE)
  }
  configuration <- utils::read.csv(file.path(out_dir, "configuration.csv"), stringsAsFactors = FALSE)
  attempts <- utils::read.csv(file.path(out_dir, "raw-attempts.csv"), stringsAsFactors = FALSE)
  results <- utils::read.csv(file.path(out_dir, "fixture-results.csv"), stringsAsFactors = FALSE)
  intervals <- utils::read.csv(file.path(out_dir, "interval-results.csv"), stringsAsFactors = FALSE)
  provenance <- utils::read.csv(file.path(out_dir, "provenance.csv"), stringsAsFactors = FALSE)
  source_commit <- provenance$value[provenance$key == "source_commit"]
  runner_md5 <- provenance$value[provenance$key == "runner_md5"]
  source_runner <- tryCatch(
    system2(
      "git",
      c("show", paste0(source_commit, ":tools/run-temporal-hetar1-interval-feasibility.R")),
      stdout = TRUE,
      stderr = TRUE
    ),
    error = function(...) character()
  )
  source_runner_path <- tempfile("temporal-hetar1-source-runner-")
  on.exit(unlink(source_runner_path), add = TRUE)
  writeLines(source_runner, source_runner_path, useBytes = TRUE)
  source_runner_md5 <- unname(tools::md5sum(source_runner_path))
  expected_starts <- sort(rep(c(-0.3, 0.3), expected_fixtures))
  if (length(source_commit) != 1L || length(runner_md5) != 1L ||
      length(source_runner) == 0L || !identical(runner_md5, source_runner_md5) ||
      nrow(configuration) != expected_fixtures || nrow(results) != expected_fixtures ||
      nrow(attempts) != 2L * expected_fixtures ||
      !all(table(attempts$fixture) == 2L) ||
      !identical(sort(attempts$persistence_start), expected_starts) ||
      !all(tapply(attempts$selected, attempts$fixture, sum) == 1L) ||
      nrow(intervals) != 3L * expected_fixtures ||
      !identical(sort(unique(intervals$fixture)), sort(configuration$fixture))) {
    stop(sprintf("%s interval-feasibility artifacts fail their immutable-output contract.", mode), call. = FALSE)
  }
  invisible(list(results = results, intervals = intervals))
}

if (identical(gate, "T4-6")) {
  if (reverify) stop("T4-6 creates no fits; use T4-11 --reverify for immutable-output verification.", call. = FALSE)
  full <- verify_artifact("full", expected_fixtures = 20L)
  if (!any(full$intervals$finite_interval)) {
    stop("T4-6 retained no finite fixed-mean Wald interval to assess.", call. = FALSE)
  }
  cat("TEMPORAL_HETAR1_T4_6_PASS\n")
} else if (identical(gate, "T4-7")) {
  if (reverify) stop("T4-7 does not accept --reverify.", call. = FALSE)
  pilot <- verify_artifact("pilot", expected_fixtures = 5L)
  if (!all(is.finite(pilot$results$elapsed_sec) & pilot$results$elapsed_sec > 0)) {
    stop("T4-7 pilot is missing elapsed-time measurements.", call. = FALSE)
  }
  cat("TEMPORAL_HETAR1_T4_7_PASS\n")
} else if (identical(gate, "T4-11")) {
  if (!reverify) stop("T4-11 requires --reverify and never launches fits.", call. = FALSE)
  verify_artifact("pilot", expected_fixtures = 5L)
  verify_artifact("full", expected_fixtures = 20L)
  cat("TEMPORAL_HETAR1_T4_11_PASS\n")
} else if (identical(gate, "T4-14")) {
  if (!reverify) stop("T4-14 requires --reverify and never launches fits.", call. = FALSE)
  verify_artifact("pilot", expected_fixtures = 5L)
  verify_artifact("full", expected_fixtures = 20L)
  report <- file.path("docs", "dev-log", "after-task", "2026-09-11-temporal-hetar1-closeout.md")
  report_text <- if (file.exists(report)) paste(readLines(report, warn = FALSE), collapse = "\n") else ""
  required_report_text <- c(
    "## 1. Goal", "## 5. Checks Run", "R CMD check", "Noether", "Pat", "#1302", "## 10. Known Residuals", "does NOT cover"
  )
  clean_tree <- length(system2("git", c("status", "--porcelain"), stdout = TRUE)) == 0L
  if (!all(vapply(required_report_text, grepl, logical(1), x = report_text, fixed = TRUE)) || !clean_tree) {
    stop("T4-14 requires the complete closeout report and a clean committed tree.", call. = FALSE)
  }
  cat("TEMPORAL_HETAR1_T4_14_PASS\n")
} else if (identical(gate, "T4-12")) {
  if (reverify) stop("T4-12 does not accept --reverify.", call. = FALSE)
  pkgload::load_all(".", compile = FALSE, quiet = TRUE)
  output_dir <- tempfile("temporal-hetar1-render-")
  dir.create(output_dir)
  rendered <- rmarkdown::render(
    "vignettes/temporal-random-effects.Rmd", output_dir = output_dir, quiet = TRUE
  )
  html <- paste(readLines(rendered, warn = FALSE), collapse = "\n")
  required <- c(
    "Different temporal process SDs at different occasions",
    "temporal-process",
    "coverage",
    "standard-error"
  )
  if (!file.exists(rendered) || !all(vapply(required, grepl, logical(1), x = html, fixed = TRUE))) {
    stop("T4-12 reader workflow render is incomplete.", call. = FALSE)
  }
  cat("TEMPORAL_HETAR1_T4_12_PASS\n")
} else if (reverify) {
  stop("--reverify is implemented only for T4-11 and T4-14.", call. = FALSE)
} else if (identical(gate, "T4-1")) {
  run_test_file("tests/testthat/test-temporal-hetar1-parser.R")
  cat("TEMPORAL_HETAR1_T4_1_PASS\n")
} else if (identical(gate, "T4-2")) {
  run_test_file("tests/testthat/test-temporal-hetar1-native.R")
  cat("TEMPORAL_HETAR1_T4_2_PASS\n")
} else if (identical(gate, "T4-3")) {
  run_test_file("tests/testthat/test-temporal-hetar1-native.R")
  cat("TEMPORAL_HETAR1_T4_3_PASS\n")
} else if (identical(gate, "T4-4")) {
  run_test_file("tests/testthat/test-temporal-hetar1-native.R")
  cat("TEMPORAL_HETAR1_T4_4_PASS\n")
} else {
  run_test_file("tests/testthat/test-temporal-hetar1-reductions.R")
  cat("TEMPORAL_HETAR1_T4_5_PASS\n")
}
