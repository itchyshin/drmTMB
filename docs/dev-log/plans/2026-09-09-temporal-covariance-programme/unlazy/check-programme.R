#!/usr/bin/env Rscript

# Planning-ledger integrity checker. It cannot certify an unimplemented provider.
root <- "docs/dev-log/plans/2026-09-09-temporal-covariance-programme"
plan_file <- file.path(root, "PLAN.md")
ledger_file <- file.path(root, "unlazy", "GATES.md")
ids <- paste0("G", 0:18)

fail <- function(...) stop(..., call. = FALSE)
contents <- function(path) {
  if (!file.exists(path)) fail("Missing planning artifact: ", path)
  paste(readLines(path, warn = FALSE), collapse = "\n")
}
need <- function(text, patterns, label) {
  missing <- patterns[!vapply(patterns, grepl, logical(1), x = text,
                               fixed = TRUE, USE.NAMES = FALSE)]
  if (length(missing)) fail(label, " missing: ", paste(missing, collapse = "; "))
}
check_ledger <- function(lines) {
  observed <- sub(".*(G[0-9]+):.*", "\\1",
                  grep("^- \\[[ x]\\] G[0-9]+:", lines, value = TRUE))
  if (!identical(observed, ids)) fail("Ledger IDs must be G0 through G18 exactly once.")
  for (id in setdiff(ids, c("G0", "G12", "G17"))) {
    at <- grep(paste0("^- \\[[ x]\\] ", id, ":"), lines)
    block <- paste(lines[at:min(length(lines), at + 4L)], collapse = "\n")
    if (!grepl("CHECK: Rscript --vanilla", block, fixed = TRUE) ||
        !grepl(paste0("EXPECT: TEMPORAL_PROGRAMME_", id, "_PASS"), block, fixed = TRUE)) {
      fail("Runnable gate ", id, " lacks a CHECK/EXPECT pair.")
    }
  }
}
self_test <- function() {
  lines <- paste0("- [ ] ", ids, ": gate")
  for (id in setdiff(ids, c("G0", "G12", "G17"))) {
    at <- match(paste0("- [ ] ", id, ": gate"), lines)
    lines <- append(lines, c("  CHECK: Rscript --vanilla x",
      paste0("  EXPECT: TEMPORAL_PROGRAMME_", id, "_PASS")), after = at)
  }
  check_ledger(lines)
  if (!inherits(try(check_ledger(lines[-1L]), silent = TRUE), "try-error")) {
    fail("Malformed-ledger negative control passed.")
  }
  cat("TEMPORAL_PROGRAMME_RUNNER_SELFTEST_PASS controls=1\n")
}
check_gate <- function(id, reverify = FALSE) {
  plan <- contents(plan_file)
  ledger <- readLines(ledger_file, warn = FALSE)
  check_ledger(ledger)
  cases <- list(
    G1 = c("# 🎯 GOAL", "## Programme gates and authority", "## Explicit deferrals"),
    G2 = c("independent-series Gaussian AR1 and OU provider",
      "stable intercept plus an independent within-species OU process",
      "separable phylogeny-by-time field"),
    G3 = c("## Arc T3 — homogeneous Toeplitz",
      "Cov}(a_{ik},a_{il})=s_a^2r_{|k-l|}", "positive-definite map"),
    G4 = c("AR1 is the nested restriction", "a dense multivariate-normal", "Mutations must detect"),
    G5 = c("## Arc T4 — heterogeneous AR1",
      "Cov}(a_{ik},a_{il})=s_ks_l\\phi^{|k-l|}", "residual measurement noise"),
    G6 = c("homogeneous AR1 reduction", "diagonal reduction", "extraction and simulation"),
    G7 = c("## Arc T5 — heterogeneous Toeplitz",
      "Cov}(a_{ik},a_{il})=s_ks_lr_{|k-l|}", "low-information stress cell"),
    G8 = c("phylogenetic provider changes covariance", "spatial provider",
      "bivariate residual correlation"),
    G9 = c("## Arc T6 — a decision map", "Start only when", "not a queue of promised code"),
    G10 = c("ARMA(1,1) only", "invertibility transforms", "innovation-aware simulation"),
    G11 = c("glmmTMB", "Matilda", "NotebookLM"),
    G13 = c("independently coded covariance, likelihood and simulation oracles",
      "native TMB likelihoods", "interval result transfers"),
    G14 = c("No more than two production leaves", "sequential within an arc",
      "disjoint ownership"),
    G15 = c("reader workflow explaining why AR1, OU", "render", "realistic reader example"),
    G16 = c("## Explicit deferrals", "generic", "spatial-temporal product"),
    G18 = c("final programme reverify reads retained evidence", "never launches a new campaign")
  )
  if (!id %in% names(cases)) fail("Unsupported programme check: ", id)
  need(plan, cases[[id]], id)
  malformed <- ledger[-grep("^- \\[[ x]\\] G0:", ledger)[[1L]]]
  if (identical(id, "G1") &&
      !inherits(try(check_ledger(malformed), silent = TRUE), "try-error")) {
    fail("Malformed-ledger negative control passed.")
  }
  cat("TEMPORAL_PROGRAMME_", id, "_PASS", if (reverify) " REVERIFY" else "", "\n", sep = "")
}
args <- commandArgs(trailingOnly = TRUE)
if (identical(args, "--self-test")) {
  self_test()
} else if (length(args) %in% c(1L, 2L) && args[[1L]] %in% ids &&
           (length(args) == 1L || identical(args[[2L]], "--reverify"))) {
  if (args[[1L]] %in% c("G0", "G12", "G17")) fail(args[[1L]], " is manual.")
  check_gate(args[[1L]], length(args) == 2L)
} else {
  fail("Use --self-test, G1..G18, or G18 --reverify from the package root.")
}
