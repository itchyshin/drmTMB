#!/usr/bin/env Rscript

# Read-only verifier/summarizer for immutable marginal homogeneous Toeplitz
# campaign results. It never loads drmTMB, calls a fit, or creates task output.

args <- commandArgs(trailingOnly = TRUE)
script_file <- sub("^--file=", "", commandArgs(trailingOnly = FALSE)[grep("^--file=", commandArgs(trailingOnly = FALSE))])
if (length(script_file) != 1L) stop("Cannot locate the campaign summarizer script.", call. = FALSE)
sys.source(file.path(dirname(normalizePath(script_file)),
  "temporal-homtoep-profile-campaign-assessment.R"), envir = globalenv())

value <- function(name) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) != 1L) stop(sprintf("Require exactly one --%s=<path>.", name), call. = FALSE)
  sub(paste0("^--", name, "="), "", hit)
}
mode <- if (any(args == "--reverify")) "reverify" else if (any(args == "--write-summary")) "write" else {
  stop("Choose --reverify or --write-summary.", call. = FALSE)
}
if (length(args) != 3L) {
  stop("Usage: ... --input-dir=<dir> --output-dir=<dir> [--reverify|--write-summary]", call. = FALSE)
}
input_dir <- value("input-dir")
output_dir <- value("output-dir")
summary_file <- file.path(output_dir, "temporal-homtoep-profile-campaign-summary.csv")
if (!dir.exists(input_dir)) stop("Campaign input directory is absent.", call. = FALSE)

expected_parm <- c("fixef:mu:(Intercept)", "fixef:mu:between", "fixef:mu:within")
expected_cell <- rep(c("P1", "P2", "P3", "S1"), each = 1000L)
fail <- function(...) stop(..., call. = FALSE)

read_attempt <- function(path, task) {
  required <- c("raw-attempts.csv", "profile-results.csv", "profile-intervals.csv",
                "provenance.csv", "session-info.txt", "RESULTS.md")
  if (!all(file.exists(file.path(path, required)))) fail("Incomplete campaign task ", task, ".")
  results <- read.csv(file.path(path, "profile-results.csv"), stringsAsFactors = FALSE)
  attempts <- read.csv(file.path(path, "raw-attempts.csv"), stringsAsFactors = FALSE)
  intervals <- read.csv(file.path(path, "profile-intervals.csv"), stringsAsFactors = FALSE)
  provenance <- read.csv(file.path(path, "provenance.csv"), stringsAsFactors = FALSE)
  source_commit <- provenance$value[provenance$key == "source_commit"]
  runner_md5 <- provenance$value[provenance$key == "runner_md5"]
  required_columns <- c("task", "attempt", "cell", "role", "replicate", "seed",
    "parm", "coefficient", "truth", "estimate", "lower", "upper",
    "interval_available", "covered", "conf.status")
  if (length(source_commit) != 1L || length(runner_md5) != 1L ||
      !grepl("^[0-9a-f]{40}$", source_commit) || !grepl("^[0-9a-f]{32}$", runner_md5) ||
      nrow(results) != 1L || nrow(attempts) < 1L || nrow(intervals) != 3L ||
      !all(required_columns %in% names(intervals)) ||
      !identical(intervals$parm, expected_parm) || anyDuplicated(intervals$parm) ||
      any(intervals$task != task) || results$task[[1L]] != task ||
      any(intervals$cell != results$cell[[1L]]) || any(intervals$seed != results$seed[[1L]])) {
    fail("Malformed retained rows in task ", task, ".")
  }
  intervals$source_commit <- source_commit
  intervals$runner_md5 <- runner_md5
  intervals
}

task_dirs <- file.path(input_dir, sprintf("task-%04d", 1:4000))
if (!all(dir.exists(task_dirs))) fail("Require task-0001 through task-4000 directories.")
attempt_dirs <- lapply(task_dirs, function(path) {
  found <- list.dirs(path, full.names = TRUE, recursive = FALSE)
  found <- found[grepl("/attempt-[0-9]{3}$", found)]
  if (length(found) != 1L) {
    fail("Each task must have exactly one retained initial attempt; retry selection requires a separate recorded decision.")
  }
  found
})
rows <- do.call(rbind, Map(function(path, task) read_attempt(path[[1L]], task), attempt_dirs, 1:4000))
if (length(unique(rows$source_commit)) != 1L || length(unique(rows$runner_md5)) != 1L) {
  fail("Campaign tasks do not share one frozen source and worker fingerprint.")
}
source_commit <- unique(rows$source_commit)
runner_md5 <- unique(rows$runner_md5)
if (system2("git", c("cat-file", "-e", paste0(source_commit, "^{commit}"))) != 0L) {
  fail("Campaign provenance names a source commit absent from this checkout.")
}
source_worker <- tempfile("temporal-homtoep-campaign-worker-", fileext = ".R")
on.exit(unlink(source_worker), add = TRUE)
if (system2("git", c("show", paste0(source_commit,
    ":tools/run-temporal-homtoep-marginal-profile-campaign.R")),
    stdout = source_worker, stderr = FALSE) != 0L || !file.exists(source_worker)) {
  fail("Campaign source commit does not contain the declared worker.")
}
if (!identical(unname(tools::md5sum(source_worker)), runner_md5)) {
  fail("Campaign worker MD5 does not match the declared immutable source commit.")
}
if (anyDuplicated(paste(rows$task, rows$parm)) ||
    !identical(rows$cell[match(seq_len(4000L), rows$task)], expected_cell) ||
    any(table(rows$cell) != 3000L) || any(table(rows$cell, rows$parm) != 1000L)) {
  fail("Campaign denominator is not exactly 1,000 data sets per cell and coefficient.")
}

summary <- do.call(rbind, lapply(split(rows, interaction(rows$cell, rows$parm, drop = TRUE)), function(x) {
  available <- as.logical(x$interval_available)
  covered <- as.logical(x$covered)
  coverage <- mean(covered)
  data.frame(
    cell = x$cell[[1L]], role = x$role[[1L]], parm = x$parm[[1L]],
    n_attempted = nrow(x), n_available = sum(available),
    availability = mean(available), coverage_all = coverage,
    coverage_conditional = if (any(available)) mean(covered[available]) else NA_real_,
    coverage_mcse = sqrt(coverage * (1 - coverage) / nrow(x)),
    bias = mean(x$estimate - x$truth, na.rm = TRUE),
    empirical_sd = stats::sd(x$estimate, na.rm = TRUE),
    mean_interval_width = if (any(available)) mean(x$upper[available] - x$lower[available]) else NA_real_,
    median_interval_width = if (any(available)) stats::median(x$upper[available] - x$lower[available]) else NA_real_,
    unavailable = sum(!available),
    source_commit = x$source_commit[[1L]], runner_md5 = x$runner_md5[[1L]],
    stringsAsFactors = FALSE
  )
}))
summary <- summary[order(summary$cell, summary$parm), , drop = FALSE]
row.names(summary) <- NULL
summary <- temporal_homtoep_profile_campaign_assess(summary)
if (identical(mode, "write")) {
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (file.exists(summary_file)) fail("Refuse to overwrite retained campaign summary.")
  write.csv(summary, summary_file, row.names = FALSE)
} else {
  if (!file.exists(summary_file)) fail("Reverify requires a retained campaign summary; it will not write one.")
  old <- read.csv(summary_file, stringsAsFactors = FALSE)
  if (!isTRUE(all.equal(old, summary, check.attributes = FALSE))) {
    fail("Retained campaign summary does not reproduce from immutable task results.")
  }
}
cat("TEMPORAL_HOMTOEP_PROFILE_CAMPAIGN_SUMMARY_PASS\\n")
primary <- summary$role == "primary"
if (all(summary$qualification[primary] == "qualified_in_simulated_cell")) {
  cat("TEMPORAL_HOMTOEP_PROFILE_CAMPAIGN_QUALIFIED\\n")
} else {
  cat("TEMPORAL_HOMTOEP_PROFILE_CAMPAIGN_UNQUALIFIED\\n")
}
