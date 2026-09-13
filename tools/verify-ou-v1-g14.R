#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (!identical(args, "--schema") && !identical(args, "--local")) {
  stop("Usage: Rscript tools/verify-ou-v1-g14.R --schema|--local", call. = FALSE)
}

runner <- "tools/run-phylo-ou-sigma-recovery-calibration.R"
out_dir <- file.path("docs", "dev-log", "evidence", "ou-v1-g14")
fail <- function(message) stop(message, call. = FALSE)
required_files <- c(
  "trees", "data", "fields", "trees.csv", "manifest.csv", "starts.csv", "attempts.csv",
  "selected-fits.csv", "diagnostics.csv", "DATA-SHA256SUMS", "SOURCE-PROVENANCE.tsv", "RESULTS.md"
)

check_schema <- function() {
  text <- paste(readLines(runner, warn = FALSE), collapse = "\n")
  required_text <- c(
    "--calibration", "docs\", \"dev-log\", \"evidence\", \"ou-v1-g14",
    "write_calibration_artifacts", "DATA-SHA256SUMS", "SOURCE-PROVENANCE.tsv",
    "selected-fits.csv", "diagnostics.csv", "negative_control", "NO_QUALIFIED_START"
  )
  if (!all(vapply(required_text, grepl, logical(1L), x = text, fixed = TRUE))) {
    fail("G14 runner does not declare the complete artifact schema.")
  }
  cat("OU_V1_G14_SCHEMA_PASS\n")
}

check_local <- function() {
  missing <- required_files[!file.exists(file.path(out_dir, required_files))]
  if (length(missing)) fail(sprintf("G14 artifacts are missing: %s", paste(missing, collapse = ", ")))
  read_csv <- function(name) utils::read.csv(file.path(out_dir, name), stringsAsFactors = FALSE, check.names = FALSE)
  manifest <- read_csv("manifest.csv")
  starts <- read_csv("starts.csv")
  attempts <- read_csv("attempts.csv")
  selected <- read_csv("selected-fits.csv")
  diagnostics <- read_csv("diagnostics.csv")
  if (nrow(manifest) != 18L || sum(manifest$design_class == "ordinary") != 16L ||
      sum(manifest$design_class == "negative_control") != 2L || anyDuplicated(manifest$task_id) ||
      nrow(starts) != 54L || anyDuplicated(starts[c("task_id", "start_id")]) ||
      nrow(attempts) != 54L || anyDuplicated(attempts[c("task_id", "start_id")]) ||
      nrow(selected) != 18L || anyDuplicated(selected$task_id) ||
      nrow(diagnostics) != 18L || anyDuplicated(diagnostics$task_id) ||
      !all(table(starts$task_id) == 3L) || !all(table(attempts$task_id) == 3L)) {
    fail("G14 task, start, or attempt denominator is not retained completely.")
  }
  sums <- readLines(file.path(out_dir, "DATA-SHA256SUMS"), warn = FALSE)
  if (!length(sums) || !file.exists(file.path(out_dir, "trees", "tree_n32_v1.nwk")) ||
      !file.exists(file.path(out_dir, "trees", "tree_n64_v1.nwk"))) {
    fail("G14 tree or checksum receipt is incomplete.")
  }
  if (!grepl("not a retained multi-seed recovery campaign", paste(readLines(file.path(out_dir, "RESULTS.md"), warn = FALSE), collapse = " "), fixed = TRUE)) {
    fail("G14 results do not preserve the no-claim boundary.")
  }
  cat("OU_V1_G14_LOCAL_PASS\n")
}

if (identical(args, "--schema")) check_schema() else check_local()
