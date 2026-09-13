#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) || !args[[1L]] %in% c("--contract", "--schema", "--preflight", "--local", "--decision")) stop("Usage: Rscript tools/verify-ou-v1-r2.R --contract|--schema|--preflight|--local|--decision", call. = FALSE)
mode <- args[[1L]]; root <- file.path("docs", "dev-log", "evidence", "ou-v1-r2"); runner <- "tools/run-phylo-ou-r2-information-preflight.R"; design <- "docs/design/265-ou-v1-r2-information-preflight.md"
fail <- function(x) stop(x, call. = FALSE); csv <- function(x) utils::read.csv(file.path(root, x), stringsAsFactors = FALSE)
if (mode %in% c("--contract", "--schema")) {
  text <- paste(readLines(design, warn = FALSE), readLines(runner, warn = FALSE), collapse = "\n")
  need <- c("128", "12", "five independent", "30", "alpha_mu", "alpha_sigma", "--preflight", "--local")
  if (!all(vapply(need, grepl, logical(1L), x = text, fixed = TRUE))) fail("R2 design/runner contract is incomplete.")
  cat(if (mode == "--contract") "OU_V1_R2_CONTRACT_PASS\n" else "OU_V1_R2_SCHEMA_PASS\n")
} else if (mode == "--preflight") {
  x <- csv("preflight.csv"); if (nrow(x) != 1L || x$preflight_attempts != 3L || !is.finite(x$projected_r2_seconds) || !isTRUE(x$within_30_minutes)) fail("R2 preflight is incomplete or exceeds local budget."); cat("OU_V1_R2_PREFLIGHT_PASS\n")
} else {
  required <- c("manifest.csv", "starts.csv", "attempts.csv", "selected-fits.csv", "diagnostics.csv", "DATA-SHA256SUMS", "SOURCE-PROVENANCE.tsv", "RESULTS.md")
  if (!all(file.exists(file.path(root, required)))) fail("R2 retained schema is incomplete.")
  a <- csv("attempts.csv"); s <- csv("selected-fits.csv"); if (nrow(a) != 30L || nrow(s) != 10L || anyDuplicated(a[c("task_id", "start_id")]) || !all(table(a$task_id) == 3L)) fail("R2 denominator is incomplete.")
  if (mode == "--decision" && (!all(c("abs_log_error_mu", "abs_log_error_sigma") %in% names(s)) || !grepl("not a recovery", paste(readLines(file.path(root, "RESULTS.md"), warn = FALSE), collapse = " "), fixed = TRUE))) fail("R2 decision report lacks rate-specific no-promotion output.")
  cat(if (mode == "--local") "OU_V1_R2_LOCAL_PASS\n" else "OU_V1_R2_DECISION_PASS\n")
}
