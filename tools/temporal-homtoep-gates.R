#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
reverify <- length(args) == 2L && identical(args[[2L]], "--reverify")
if (!((length(args) == 1L && args[[1L]] %in% c("T3-1", "T3-2", "T3-3", "T3-4", "T3-5", "T3-6", "T3-7", "T3-7a", "T3-7c", "T3-8", "T3-11", "M3")) ||
      (length(args) == 2L && args[[1L]] %in% c("T3-10", "T3-12") && reverify))) {
  stop("Only implemented deterministic and retained-evidence gates are accepted. T3-10 and T3-12 require --reverify; other gates remain pending.", call. = FALSE)
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

if (identical(gate, "T3-12")) {
  closeout <- "docs/dev-log/evidence/temporal-homtoep/2026-09-10-p2-closeout.md"
  after_task <- "docs/dev-log/after-task/2026-09-10-temporal-homtoep-p2-closeout.md"
  required <- list(
    closeout = c(
      "Noether rechecked", "Pat rechecked", "R CMD build .",
      "R CMD check --no-manual", "two package-wide warnings",
      "not presented as a clean warning-free check"
    ),
    after_task = c(
      "## Goal", "## Mathematical Contract", "## Checks Run",
      "## Tests Of The Tests", "## Known Limitations", "## Next Actions",
      "temporal `sigma` (scale) capability"
    )
  )
  paths <- c(closeout = closeout, after_task = after_task)
  for (name in names(paths)) {
    if (!file.exists(paths[[name]])) {
      stop(sprintf("T3-12 is missing its %s receipt.", name), call. = FALSE)
    }
    text <- gsub("\\s+", " ", paste(readLines(paths[[name]], warn = FALSE), collapse = "\n"))
    if (!all(vapply(required[[name]], grepl, logical(1L), x = text, fixed = TRUE))) {
      stop(sprintf("T3-12 %s receipt is incomplete.", name), call. = FALSE)
    }
  }
  # T3-12 reuses the already-built native library: this closeout reverify
  # checks the current R interface and retained evidence, not compilation.
  run_test_file("tests/testthat/test-temporal-homtoep-parser.R", compile = FALSE)
  run_test_file("tests/testthat/test-temporal-homtoep-native.R", compile = FALSE)
  run_test_file("tests/testthat/test-temporal-homtoep-intervals.R", compile = FALSE)
  cat("TEMPORAL_HOMTOEP_T3_12_PASS\n")
} else if (identical(gate, "T3-10")) {
  campaign_dir <- Sys.getenv("DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_OUT")
  if (!nzchar(campaign_dir)) {
    stop("T3-10 requires DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_OUT naming retained campaign outputs; reverify never launches a campaign.", call. = FALSE)
  }
  status <- system2("Rscript", c(
    "--vanilla", "tools/summarize-temporal-homtoep-marginal-profile-campaign.R",
    paste0("--input-dir=", campaign_dir), paste0("--output-dir=", campaign_dir), "--reverify"
  ))
  if (!identical(status, 0L)) {
    stop("T3-10 retained campaign outputs do not reproduce.", call. = FALSE)
  }
  summary <- read.csv(file.path(campaign_dir, "temporal-homtoep-profile-campaign-summary.csv"), stringsAsFactors = FALSE)
  primary <- summary$role == "primary"
  if (nrow(summary) != 12L || !all(summary$qualification[primary] == "qualified_in_simulated_cell")) {
    stop("T3-10 retained campaign does not meet every frozen primary calibration criterion.", call. = FALSE)
  }
  cat("TEMPORAL_HOMTOEP_T3_10_PASS\n")
} else if (identical(gate, "T3-11")) {
  reader <- "vignettes/temporal-random-effects.Rmd"
  grammar <- "docs/design/01-formula-grammar.md"
  likelihood <- "docs/design/03-likelihoods.md"
  reference <- "man/temporal.Rd"
  needed <- list(
    reader = c(
      "Free correlation by discrete lag with homogeneous Toeplitz",
      "complete, equally spaced",
      "profile_engine = \"tmbprofile\"",
      "If elapsed gaps are genuinely irregular, use OU instead."
    ),
    grammar = c(
      "Implemented marginal-covariance profile slice",
      "4,000-fit campaign",
      "Wald, scale, and lag-correlation intervals remain unavailable"
    ),
    likelihood = c(
      "4,000-fit campaign qualified likelihood-profile intervals",
      "intercept coverage (0.916)",
      "Wald, total-scale, and lag-correlation intervals remain unavailable"
    ),
    reference = c(
      "Homogeneous Toeplitz fits provide likelihood-profile",
      "Scale and lag-correlation"
    )
  )
  paths <- c(reader = reader, grammar = grammar, likelihood = likelihood, reference = reference)
  for (name in names(paths)) {
    if (!file.exists(paths[[name]])) {
      stop(sprintf("T3-11 missing %s documentation.", name), call. = FALSE)
    }
    text <- gsub("\\s+", " ", paste(readLines(paths[[name]], warn = FALSE), collapse = "\n"))
    if (!all(vapply(needed[[name]], grepl, logical(1L), x = text, fixed = TRUE))) {
      stop(sprintf("T3-11 %s documentation is incomplete.", name), call. = FALSE)
    }
  }
  if (!requireNamespace("rmarkdown", quietly = TRUE) || !rmarkdown::pandoc_available()) {
    stop("T3-11 requires rmarkdown and Pandoc to render the temporal reader workflow.", call. = FALSE)
  }
  pkgload::load_all(".", compile = TRUE, quiet = TRUE)
  render_dir <- tempfile("temporal-homtoep-reader-")
  dir.create(render_dir)
  rendered <- rmarkdown::render(
    reader,
    output_dir = render_dir,
    intermediates_dir = render_dir,
    quiet = TRUE
  )
  if (!file.exists(rendered)) {
    stop("T3-11 did not create the temporal reader HTML.", call. = FALSE)
  }
  html <- gsub(
    "\\s+", " ",
    gsub("<[^>]+>", " ", paste(readLines(rendered, warn = FALSE), collapse = "\n"))
  )
  rendered_needed <- c(
    "Temporal AR1, OU, and Toeplitz effects",
    "Free correlation by discrete lag with homogeneous Toeplitz",
    "If elapsed gaps are genuinely irregular, use OU instead."
  )
  if (!all(vapply(rendered_needed, grepl, logical(1L), x = html, fixed = TRUE))) {
    stop("T3-11 rendered reader workflow is incomplete.", call. = FALSE)
  }
  cat("TEMPORAL_HOMTOEP_T3_11_PASS\n")
} else if (identical(gate, "T3-8")) {
  contract <- "docs/dev-log/plans/2026-09-10-temporal-homtoep/T3-8-MARGINAL-CALIBRATION-CONTRACT.md"
  required <- c("likelihood-profile", "P1", "P2", "P3", "S1", "1,000", "0.925", "0.975", "0.99", "all-attempt", "DRAC/Fir", "explicit approval")
  if (!file.exists(contract)) stop("T3-8 calibration contract is missing.", call. = FALSE)
  text <- paste(readLines(contract, warn = FALSE), collapse = "\n")
  if (!all(vapply(required, grepl, logical(1), x = text, fixed = TRUE))) {
    stop("T3-8 calibration contract is incomplete.", call. = FALSE)
  }
  cat("TEMPORAL_HOMTOEP_T3_8_PASS\n")
} else if (identical(gate, "M3")) {
  out_dir <- Sys.getenv("DRMTMB_TEMPORAL_HOMTOEP_MARGINAL_RECOVERY_OUT", unset =
    "docs/dev-log/simulation-artifacts/2026-09-10-temporal-homtoep-marginal-recovery-v1")
  required <- file.path(out_dir, c("raw-attempts.csv", "recovery-estimates.csv", "criteria.csv", "provenance.csv", "recovery-results.rds", "session-info.txt", "RESULTS.md"))
  if (!all(file.exists(required))) stop("M3 cannot find the retained marginal-Toeplitz recovery evidence.", call. = FALSE)
  criteria <- read.csv(file.path(out_dir, "criteria.csv"), stringsAsFactors = FALSE)
  attempts <- read.csv(file.path(out_dir, "raw-attempts.csv"), stringsAsFactors = FALSE)
  recovery <- read.csv(file.path(out_dir, "recovery-estimates.csv"), stringsAsFactors = FALSE)
  provenance <- read.csv(file.path(out_dir, "provenance.csv"), stringsAsFactors = FALSE)
  source_commit <- provenance$value[provenance$key == "source_commit"]
  runner_hash <- provenance$value[provenance$key == "runner_md5"]
  runner <- "tools/run-temporal-homtoep-marginal-recovery.R"
  primary <- recovery$cell %in% c("A_ar1", "B_nonexponential", "C_negative_lag")
  if (length(source_commit) != 1L || length(runner_hash) != 1L ||
      system2("git", c("cat-file", "-e", paste0(source_commit, "^{commit}"))) != 0L ||
      system2("git", c("cat-file", "-e", paste0(source_commit, ":", runner))) != 0L ||
      !identical(runner_hash, unname(tools::md5sum(runner))) ||
      nrow(recovery) != 12L || nrow(attempts) != 12L ||
      sum(recovery$selected & primary) != 9L ||
      !all(table(attempts$fixture) == 1L) || !all(criteria$pass)) {
    stop("M3 retained marginal-Toeplitz recovery evidence fails its source, denominator, or frozen criteria checks.", call. = FALSE)
  }
  cat("TEMPORAL_HOMTOEP_M3_PASS\n")
} else if (identical(gate, "T3-1")) {
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
  if (identical(gate, "T3-7c")) {
    status <- system2(file.path(R.home("bin"), "Rscript"),
      c("--vanilla", "tools/temporal-homtoep-marginal-spike.R"))
    if (!identical(status, 0L)) stop("T3-7c marginal Toeplitz spike failed.", call. = FALSE)
    cat("TEMPORAL_HOMTOEP_T3_7C_PASS\n")
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
