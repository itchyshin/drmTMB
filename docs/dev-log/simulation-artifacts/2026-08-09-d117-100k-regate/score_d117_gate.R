#!/usr/bin/env Rscript
# Scores the D-117 10-group profile gate against the rule frozen in
# PREREGISTRATION.md. The rule is NOT recomputed or re-tuned here; it is applied.
#
#   ss_floor(g) = 0.95 - 0.04 * (8 / g)   ->  ss_floor(10) = 0.918
#   PASS       : coverage + 2*MCSE >= 0.918  AND  >= 95% finite ordered intervals
#   BORDERLINE : 0.880 <= coverage + 2*MCSE < 0.918
#   FAIL       : coverage + 2*MCSE < 0.880   OR  > 5% intervals not finite/ordered

script_dir <- {
  f <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
  if (length(f)) dirname(normalizePath(sub("^--file=", "", f[[1L]]))) else getwd()
}
source(file.path(script_dir, "a1_profile_common.R"))

ss_floor <- function(g, nominal = 0.95) nominal - 0.04 * (8 / max(g, 1))
FLOOR <- ss_floor(10L)
BORDERLINE_FLOOR <- 0.880

files <- sort(list.files(file.path(script_dir, "results"), pattern = "\\.csv$", full.names = TRUE))
stopifnot(length(files) == 4L)

fmt <- function(x, d = 4) formatC(x, format = "f", digits = d)
out <- list()

cat("\n=== D-117 10-group profile RE-SD coverage gate ===\n")
cat("Rule frozen in PREREGISTRATION.md (committed e9bccb26b, before any fit).\n")
cat("ss_floor(10) =", fmt(FLOOR, 3), "  test: coverage + 2*MCSE >= floor\n\n")

for (f in files) {
  d <- utils::read.csv(f, stringsAsFactors = FALSE)
  cell <- unique(d$cell_id); stopifnot(length(cell) == 1L)
  n <- nrow(d)

  cov_tab <- a1_exact_binomial(d$profile_covers)
  p <- cov_tab$coverage
  mcse <- sqrt(p * (1 - p) / n)
  score <- p + 2 * mcse
  finite_frac <- mean(d$profile_status == "valid")

  verdict <- if (finite_frac < 0.95) "FAIL (intervals unavailable)"
             else if (score >= FLOOR) "PASS"
             else if (score >= BORDERLINE_FLOOR) "BORDERLINE"
             else "FAIL"

  miss <- table(factor(d$profile_miss_direction,
                       levels = c("covered", "lower", "upper", "nonfinite")))
  n_bound_est <- sum(!is.na(d$estimate_sd) & d$estimate_sd < 1e-3)
  n_bound_prof <- sum(!is.na(d$profile_boundary) & d$profile_boundary)

  # The diagnostic that matters most: does boundary pinning PROP UP coverage?
  # A profile lower bound pinned at 0 covers any positive truth trivially.
  is_b <- !is.na(d$profile_boundary) & d$profile_boundary
  cov_b  <- if (any(is_b))  mean(d$profile_covers[is_b]  %in% TRUE) else NA_real_
  cov_nb <- if (any(!is_b)) mean(d$profile_covers[!is_b] %in% TRUE) else NA_real_
  lower_at_zero <- sum(!is.na(d$profile_lower) & d$profile_lower <= 1e-8)

  cat(sprintf("--- %s  (n_groups=%d, n_per=%d, sd_mu=%.1f, N=%d, %s)\n",
              cell, d$n_groups[1], d$n_per_group[1], d$truth_sd[1],
              d$n_groups[1] * d$n_per_group[1], unique(d$cell_kind)))
  cat(sprintf("  coverage        %s  exact 95%% CI (%s, %s)   MCSE %s\n",
              fmt(p), fmt(cov_tab$coverage_lo), fmt(cov_tab$coverage_hi), fmt(mcse)))
  cat(sprintf("  score (cov+2MCSE) %s   vs floor %s   -> %s\n",
              fmt(score), fmt(FLOOR, 3), verdict))
  cat(sprintf("  finite intervals  %d/%d (%s)\n", sum(d$profile_status == "valid"), n, fmt(finite_frac, 3)))
  cat(sprintf("  misses            lower %d / upper %d   (nonfinite %d)\n",
              miss[["lower"]], miss[["upper"]], miss[["nonfinite"]]))
  cat(sprintf("  boundary          estimate_sd<1e-3: %d   profile_boundary: %d   lower==0: %d\n",
              n_bound_est, n_bound_prof, lower_at_zero))
  cat(sprintf("  coverage | boundary %s   | non-boundary %s\n",
              ifelse(is.na(cov_b), "  n/a", fmt(cov_b)), ifelse(is.na(cov_nb), "  n/a", fmt(cov_nb))))
  cat(sprintf("  convergence %s   pdHess %s   median width %s\n",
              fmt(mean(d$fit_converged %in% TRUE), 3), fmt(mean(d$pdHess %in% TRUE), 3),
              fmt(stats::median(d$profile_width, na.rm = TRUE))))
  cat("\n")

  out[[cell]] <- data.frame(
    cell_id = cell, kind = unique(d$cell_kind), n_groups = d$n_groups[1],
    n_per = d$n_per_group[1], sd_mu = d$truth_sd[1], n = n,
    coverage = p, coverage_lo = cov_tab$coverage_lo, coverage_hi = cov_tab$coverage_hi,
    mcse = mcse, score = score, floor = FLOOR, verdict = verdict,
    finite = sum(d$profile_status == "valid"),
    miss_lower = miss[["lower"]], miss_upper = miss[["upper"]],
    boundary_est = n_bound_est, boundary_profile = n_bound_prof,
    cov_boundary = cov_b, cov_nonboundary = cov_nb,
    median_width = stats::median(d$profile_width, na.rm = TRUE),
    stringsAsFactors = FALSE)
}

summ <- do.call(rbind, out)
overall <- if (all(summ$verdict == "PASS")) "PASS" else if (any(grepl("FAIL", summ$verdict))) "FAIL" else "BORDERLINE"
cat("=== OVERALL (every tested 10-group cell must pass) :", overall, "===\n")
utils::write.csv(summ, file.path(script_dir, "results", "SUMMARY.csv"), row.names = FALSE)
cat("wrote results/SUMMARY.csv\n")
