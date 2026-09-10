#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L || !args[[1L]] %in% c("T3-1", "T3-2", "T3-3", "T3-4", "T3-5", "T3-6", "T3-7", "T3-7a")) {
  stop("Only `T3-1` through `T3-7a` are implemented in this runner. Other gates remain pending.", call. = FALSE)
}
gate <- args[[1L]]

run_test_file <- function(path, compile = TRUE) {
  code <- paste(
    sprintf("pkgload::load_all('.', compile = %s, quiet = TRUE)", if (compile) "TRUE" else "FALSE"),
    sprintf("result <- testthat::test_file(%s, reporter = 'silent')", deparse(path)),
    "expectations <- unlist(lapply(result, `[[`, 'results'), recursive = FALSE)",
    "failed <- vapply(expectations, function(x) inherits(x, 'expectation_failure') || inherits(x, 'expectation_error'), logical(1))",
    "quit(status = as.integer(any(failed)))",
    sep = "; "
  )
  status <- system2(
    file.path(R.home("bin"), "Rscript"),
    c("--vanilla", "-e", shQuote(code)),
    stdout = FALSE,
    stderr = FALSE
  )
  if (!identical(status, 0L)) {
    stop(sprintf("%s failed in its isolated R process.", path), call. = FALSE)
  }
}

if (identical(gate, "T3-1")) {
  run_test_file("tests/testthat/test-temporal-homtoep-parser.R")
  cat("TEMPORAL_HOMTOEP_T3_1_PASS\n")
} else if (identical(gate, "T3-2")) {
  source("tools/temporal-homtoep-map-study.R")
  result <- homtoep_map_study()
  if (result$draws != 480L ||
      result$minimum_eigenvalue <= 1e-13 ||
      result$derivative_difference >= 1e-4 ||
      result$lagwise_counterexample_minimum_eigenvalue >= 0 ||
      result$generic_cholesky_toeplitz_deviation <= 1e-3) {
    stop("T3-2 map study did not satisfy its prespecified acceptance criteria.", call. = FALSE)
  }

  eta <- c(-1.3, 0.2, 1.1, -0.7, 0.4)
  rho <- homtoep_reflection_rho(eta)
  if (max(abs(homtoep_eta_from_rho(rho) - eta)) >= 1e-10 ||
      max(abs(homtoep_reflection_cor(eta) - homtoep_dense_from_lags(rho))) >= 1e-13 ||
      max(abs(homtoep_reflection_cor(eta) - stats::toeplitz(rho))) >= 1e-13) {
    stop("T3-2 reconstruction or dense-reference check failed.", call. = FALSE)
  }

  cat("TEMPORAL_HOMTOEP_T3_2_PASS\n")
} else if (identical(gate, "T3-3")) {
  run_test_file("tests/testthat/test-temporal-homtoep-native.R")
  cat("TEMPORAL_HOMTOEP_T3_3_PASS\n")
} else if (identical(gate, "T3-4")) {
  run_test_file("tests/testthat/test-temporal-homtoep-native.R")
  cat("TEMPORAL_HOMTOEP_T3_4_PASS\n")
} else if (identical(gate, "T3-5")) {
  run_test_file("tests/testthat/test-temporal-homtoep-reductions.R")
  cat("TEMPORAL_HOMTOEP_T3_5_PASS\n")
} else if (identical(gate, "T3-6")) {
  out_dir <- Sys.getenv("DRMTMB_TEMPORAL_HOMTOEP_RECOVERY_OUT", unset =
    "docs/dev-log/simulation-artifacts/2026-09-10-temporal-homtoep-local-recovery-final-source")
  required <- file.path(out_dir, c("raw-attempts.csv", "recovery-estimates.csv", "criteria.csv", "provenance.csv", "recovery-results.rds", "session-info.txt", "RESULTS.md"))
  if (!all(file.exists(required))) stop("T3-6 cannot find the retained final-source recovery evidence.", call. = FALSE)
  criteria <- read.csv(file.path(out_dir, "criteria.csv"), stringsAsFactors = FALSE)
  attempts <- read.csv(file.path(out_dir, "raw-attempts.csv"), stringsAsFactors = FALSE)
  recovery <- read.csv(file.path(out_dir, "recovery-estimates.csv"), stringsAsFactors = FALSE)
  provenance <- read.csv(file.path(out_dir, "provenance.csv"), stringsAsFactors = FALSE)
  source_commit <- provenance$value[provenance$key == "source_commit"]
  runner_hash <- provenance$value[provenance$key == "runner_md5"]
  if (length(source_commit) != 1L || length(runner_hash) != 1L ||
      system2("git", c("cat-file", "-e", paste0(source_commit, "^{commit}"))) != 0L ||
      system2("git", c("cat-file", "-e", paste0(source_commit, ":tools/run-temporal-homtoep-recovery.R"))) != 0L ||
      !identical(runner_hash, unname(tools::md5sum("tools/run-temporal-homtoep-recovery.R"))) ||
      nrow(recovery) != 12L || nrow(attempts) != 12L ||
      sum(recovery$cell %in% c("A_ar1", "B_nonexponential", "C_negative_lag") & recovery$selected) != 9L ||
      !all(criteria$pass)) {
    stop("T3-6 retained recovery evidence fails its source, denominator, or frozen criteria checks.", call. = FALSE)
  }
  cat("TEMPORAL_HOMTOEP_T3_6_PASS\n")
} else {
  if (identical(gate, "T3-7a")) {
    # The exact dense covariance identity is pure R; avoiding an unnecessary
    # native rebuild keeps this diagnostic independent of compiler state.
    run_test_file("tests/testthat/test-temporal-homtoep-identifiability.R", compile = FALSE)
    cat("TEMPORAL_HOMTOEP_T3_7A_PASS\n")
    quit(status = 0L)
  }
  out_dir <- Sys.getenv("DRMTMB_TEMPORAL_HOMTOEP_PILOT_OUT", unset =
    "docs/dev-log/simulation-artifacts/2026-09-10-temporal-homtoep-pilot-final-source")
  required <- file.path(out_dir, c("raw-attempts.csv", "pilot-results.csv", "pilot-summary.csv", "provenance.csv", "pilot-results.rds", "session-info.txt", "RESULTS.md", "resource-replay.txt"))
  if (!all(file.exists(required))) stop("T3-7 cannot find the retained final-source pilot evidence.", call. = FALSE)
  attempts <- read.csv(file.path(out_dir, "raw-attempts.csv"), stringsAsFactors = FALSE)
  results <- read.csv(file.path(out_dir, "pilot-results.csv"), stringsAsFactors = FALSE)
  provenance <- read.csv(file.path(out_dir, "provenance.csv"), stringsAsFactors = FALSE)
  source_commit <- provenance$value[provenance$key == "source_commit"]
  runner_hash <- provenance$value[provenance$key == "runner_md5"]
  resource <- paste(readLines(file.path(out_dir, "resource-replay.txt"), warn = FALSE), collapse = "\n")
  if (length(source_commit) != 1L || length(runner_hash) != 1L ||
      system2("git", c("cat-file", "-e", paste0(source_commit, "^{commit}"))) != 0L ||
      system2("git", c("cat-file", "-e", paste0(source_commit, ":tools/run-temporal-homtoep-pilot.R"))) != 0L ||
      !identical(runner_hash, unname(tools::md5sum("tools/run-temporal-homtoep-pilot.R"))) ||
      nrow(results) != 15L || nrow(attempts) != 15L || !all(table(attempts$fixture) == 1L) ||
      !all(results$selected & is.finite(results$objective) & is.finite(results$elapsed_sec) & results$elapsed_sec > 0) ||
      !all(!results$profile_available & results$n_profile_intervals == 0L & grepl("not yet qualified", results$profile_status, fixed = TRUE)) ||
      !grepl("maximum resident set size", resource, fixed = TRUE)) {
    stop("T3-7 retained pilot evidence fails its source, denominator, profile-guard, or resource checks.", call. = FALSE)
  }
  cat("TEMPORAL_HOMTOEP_T3_7_PASS\n")
}
