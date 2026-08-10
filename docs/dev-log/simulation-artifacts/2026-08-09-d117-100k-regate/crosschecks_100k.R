#!/usr/bin/env Rscript
# D-117 100k re-gate -- CROSS-CHECKS ONLY.
#
# These are reported ALONGSIDE the frozen rule in score_d117_gate.R and never
# replace it. score_d117_gate.R is copied here byte-identical (verify with
# shasum against the 2026-08-04 original) so the gate verdict cannot drift.
#
# Pre-registered in PREREGISTRATION.md before any 100k fit was run:
#   1. a standard one-sided lower confidence bound, p_hat - z*SE >= floor
#   2. re-estimated conditional-on-boundary coverage, whose 2026-08-04 values
#      rested on only 495 / 41 / 63 / 0 boundary events
#
# Usage: Rscript --no-init-file crosschecks_100k.R [results_dir]

args <- commandArgs(trailingOnly = TRUE)
script_dir <- {
  f <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(f)) dirname(normalizePath(sub("^--file=", "", f[[1L]]))) else getwd()
}
res_dir <- if (length(args)) args[[1L]] else file.path(script_dir, "results")

FLOOR <- 0.95 - 0.04 * (8 / 10)          # ss_floor(10) = 0.918, frozen
Z <- stats::qnorm(0.95)                   # one-sided 95%
fmt <- function(x, d = 4) formatC(x, format = "f", digits = d)

files <- sort(list.files(res_dir, pattern = "\\.csv$", full.names = TRUE))
files <- files[!grepl("SUMMARY", basename(files))]
stopifnot(length(files) == 4L)

cat("\n=== D-117 100k re-gate -- CROSS-CHECKS (not the gate) ===\n")
cat("floor =", fmt(FLOOR, 3), " one-sided z =", fmt(Z, 3), "\n\n")

rows <- list()
for (f in files) {
  d <- utils::read.csv(f, stringsAsFactors = FALSE)
  cell <- unique(d$cell_id); stopifnot(length(cell) == 1L)
  n <- nrow(d)
  p <- mean(d$profile_covers %in% TRUE)
  se <- sqrt(p * (1 - p) / n)

  # --- cross-check 1: one-sided lower confidence bound -------------------
  lcb <- p - Z * se
  lcb_verdict <- if (lcb >= FLOOR) "PASS (LCB)" else "FAIL (LCB)"
  # exact one-sided binomial test of H0: coverage >= floor
  bt <- stats::binom.test(sum(d$profile_covers %in% TRUE), n, p = FLOOR,
                          alternative = "less")

  # --- cross-check 2: conditional coverage, now on many more events ------
  is_b <- !is.na(d$profile_boundary) & d$profile_boundary
  nb <- sum(is_b)
  cov_b  <- if (nb > 0)   mean(d$profile_covers[is_b]  %in% TRUE) else NA_real_
  se_b   <- if (nb > 0)   sqrt(cov_b * (1 - cov_b) / nb) else NA_real_
  cov_nb <- if (any(!is_b)) mean(d$profile_covers[!is_b] %in% TRUE) else NA_real_
  se_nb  <- if (any(!is_b)) sqrt(cov_nb * (1 - cov_nb) / sum(!is_b)) else NA_real_

  cat(sprintf("--- %s  (n_groups=%d, n_per=%d, sd=%.1f, N=%d, nrep=%d)\n",
              cell, d$n_groups[1], d$n_per_group[1], d$truth_sd[1],
              d$n_groups[1] * d$n_per_group[1], n))
  cat(sprintf("  coverage %s  SE %s\n", fmt(p, 6), fmt(se, 6)))
  cat(sprintf("  [x1] one-sided LCB  p - z*SE = %s  vs floor %s  -> %s\n",
              fmt(lcb, 6), fmt(FLOOR, 3), lcb_verdict))
  cat(sprintf("  [x1] exact binom.test(H0: cov >= floor, alt=less) p = %s\n",
              format.pval(bt$p.value, digits = 3)))
  cat(sprintf("  [x2] boundary events %d (%s of reps)\n", nb, fmt(nb / n, 4)))
  cat(sprintf("  [x2] coverage | boundary     %s  SE %s\n",
              ifelse(is.na(cov_b), "n/a", fmt(cov_b, 6)),
              ifelse(is.na(se_b), "n/a", fmt(se_b, 6))))
  cat(sprintf("  [x2] coverage | non-boundary %s  SE %s\n",
              ifelse(is.na(cov_nb), "n/a", fmt(cov_nb, 6)),
              ifelse(is.na(se_nb), "n/a", fmt(se_nb, 6))))
  cat("\n")

  rows[[cell]] <- data.frame(
    cell_id = cell, n = n, coverage = p, se = se, lcb = lcb,
    lcb_pass = lcb >= FLOOR, binom_p_less = bt$p.value,
    n_boundary = nb, boundary_frac = nb / n,
    cov_boundary = cov_b, se_boundary = se_b,
    cov_nonboundary = cov_nb, se_nonboundary = se_nb,
    stringsAsFactors = FALSE)
}

out <- do.call(rbind, rows)
utils::write.csv(out, file.path(script_dir, "CROSSCHECKS.csv"), row.names = FALSE)
cat("wrote CROSSCHECKS.csv\n")
cat("\nNOTE: the GATE verdict is whatever score_d117_gate.R prints. These are context.\n")
