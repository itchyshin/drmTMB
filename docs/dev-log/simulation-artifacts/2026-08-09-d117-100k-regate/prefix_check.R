#!/usr/bin/env Rscript
# D-117 100k re-gate -- PREFIX REPRODUCTION CHECK.
#
# The seed scheme is seed = 20260727 + 100000*cell_i + r, with set.seed() called
# fresh inside each replicate. So replicates r = 1..1000 of the 100,000-rep run
# use EXACTLY the seeds of the banked 2026-08-04 campaign. The 100k run is an
# extension of that campaign, not a replacement.
#
# This script proves it. If the prefix does NOT reproduce the banked numbers,
# the harness or the package has changed and EVERY conclusion downstream --
# including the pre-registration -- is void.
#
# Usage: Rscript --no-init-file prefix_check.R <new_results_dir> <banked_results_dir>

args <- commandArgs(trailingOnly = TRUE)
stopifnot(length(args) == 2L)
new_dir <- args[[1L]]; old_dir <- args[[2L]]

fmt <- function(x, d = 6) formatC(x, format = "f", digits = d)
ok_all <- TRUE

new_files <- sort(list.files(new_dir, pattern = "\\.csv$", full.names = TRUE))
new_files <- new_files[!grepl("SUMMARY", basename(new_files))]
stopifnot(length(new_files) == 4L)

cat("\n=== PREFIX REPRODUCTION CHECK (r = 1..1000 vs banked 2026-08-04) ===\n\n")

for (nf in new_files) {
  base <- basename(nf)
  of <- file.path(old_dir, base)
  if (!file.exists(of)) { cat("MISSING banked file:", base, "\n"); ok_all <- FALSE; next }

  new <- utils::read.csv(nf, stringsAsFactors = FALSE)
  old <- utils::read.csv(of, stringsAsFactors = FALSE)

  # align on seed -- the only identifier guaranteed stable across runs
  pre <- new[new$seed %in% old$seed, , drop = FALSE]
  pre <- pre[order(pre$seed), , drop = FALSE]
  old <- old[order(old$seed), , drop = FALSE]

  cat("---", base, "\n")
  cat(sprintf("  banked rows %d   matched-seed rows in 100k run %d\n", nrow(old), nrow(pre)))
  if (nrow(pre) != nrow(old)) { cat("  ROW COUNT MISMATCH\n"); ok_all <- FALSE; next }
  if (!identical(pre$seed, old$seed)) { cat("  SEED SET MISMATCH\n"); ok_all <- FALSE; next }

  # numeric agreement on the quantities the gate depends on
  num_cols <- c("estimate_sd", "profile_lower", "profile_upper", "profile_width")
  for (cc in num_cols) {
    a <- pre[[cc]]; b <- old[[cc]]
    both_na <- is.na(a) & is.na(b)
    d <- abs(a - b); d[both_na] <- 0
    worst <- suppressWarnings(max(d, na.rm = TRUE))
    bad <- sum(!both_na & (is.na(a) != is.na(b)))
    flag <- if (!is.finite(worst)) "NON-FINITE" else if (worst < 1e-8) "ok" else "DIFFERS"
    if (flag != "ok" || bad > 0) ok_all <- FALSE
    cat(sprintf("  %-16s max|diff| %-14s NA-mismatch %d   %s\n",
                cc, ifelse(is.finite(worst), fmt(worst, 10), "inf"), bad, flag))
  }

  # logical agreement
  for (cc in c("profile_covers", "profile_boundary", "fit_converged", "pdHess")) {
    a <- pre[[cc]] %in% TRUE; b <- old[[cc]] %in% TRUE
    dis <- sum(a != b)
    if (dis > 0) ok_all <- FALSE
    cat(sprintf("  %-16s disagreements %d / %d   %s\n",
                cc, dis, length(a), ifelse(dis == 0, "ok", "DIFFERS")))
  }

  cat(sprintf("  coverage  banked %s   prefix %s\n",
              fmt(mean(old$profile_covers %in% TRUE), 4),
              fmt(mean(pre$profile_covers %in% TRUE), 4)))
  cat("\n")
}

cat("=== PREFIX CHECK:", if (ok_all) "PASS -- the 100k run reproduces the banked campaign exactly"
    else "FAIL -- harness or package changed; downstream conclusions are VOID", "===\n")
if (!ok_all) quit(status = 1L)
