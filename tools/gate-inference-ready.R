#!/usr/bin/env Rscript
# gate-inference-ready.R -- compute the BINDING inference-ready gate from a
# coverage replicate TSV. Fisher audit, 2026-07-08 (VERDICT: SOFT): the 8
# `inference_ready` cells were promoted via a hard-coded allowlist in
# validate-mission-control.py, not a computed gate, and 6 of 8 fail a
# miss-ratio > 2 check. This replaces the allowlist with a computation.
#
# It reads a `*-replicates.tsv` with columns:
#   truth_sd, and a {member}_lower / {member}_upper pair per interval channel
#   (e.g. profile_lower/profile_upper, wald_lower/wald_upper), plus optionally
#   estimate_sd. Per (member, channel) it emits the gate metrics + PASS/FAIL.
#
# The gate (per endpoint member, on the UNCENSORED denominator):
#   P0  finite-interval rate >= 0.95 over fitted replicates; a non-finite
#       interval is NOT dropped -- scored as a miss on the side its estimate lies.
#   P1  n_miss >= MIN_MISS (default 40): a power floor. Below it -> interval_feasible.
#   G1  |coverage - nominal| <= 2 * MCSE_coverage    (two-sided; over-coverage fails)
#   G2  exact two-sided binomial test of n_high among n_miss vs p=0.5:
#       p_value >= 0.05 AND point ratio in [0.5, 2]
#   G3  every member passes independently (no pooling) -- enforced by the caller.
#
# This file is BOTH a CLI and a library. `source()` it to get `gate_one()`
# (the driver tools/gate-inference-ready-driver.R does exactly this); run it as
# a script for a one-file report. The CLI block is guarded by sys.nframe()==0L
# so sourcing does not trigger it (same pattern as tools/check-after-task.R and
# ~/shinichi-brain/tools/check-after-task.R).
#
# Usage (CLI):
#   Rscript tools/gate-inference-ready.R <replicates.tsv> [--truth=0.60] \
#       [--members=profile,wald] [--min-miss=40] [--nominal=0.95]

# --- the gate, as a pure function (min_miss/nominal are PARAMETERS, not globals,
#     so it is safe to source and call directly) ----------------------------
gate_one <- function(lo, hi, est, truth, label,
                     min_miss = 40L, nominal = 0.95) {
  fitted <- !(is.na(lo) & is.na(hi))            # a produced row (fit ok)
  n_fit <- sum(fitted)
  finite <- is.finite(lo) & is.finite(hi)
  finite_rate <- sum(finite) / max(n_fit, 1L)
  covered <- finite & lo <= truth & hi >= truth
  coverage <- sum(covered) / max(n_fit, 1L)     # UNCENSORED: denominator = fitted
  mcse <- sqrt(coverage * (1 - coverage) / max(n_fit, 1L))
  hi_miss <- sum(finite & hi < truth)
  lo_miss <- sum(finite & lo > truth)
  if (!all(is.na(est))) {                       # score non-finite intervals by their estimate
    nf <- fitted & !finite
    hi_miss <- hi_miss + sum(nf & est > truth, na.rm = TRUE)
    lo_miss <- lo_miss + sum(nf & est <= truth, na.rm = TRUE)
  }
  n_miss <- hi_miss + lo_miss
  ratio <- if (lo_miss == 0) if (hi_miss == 0) 1 else Inf else hi_miss / lo_miss
  binom_p <- if (n_miss > 0) stats::binom.test(hi_miss, n_miss, 0.5)$p.value else NA_real_
  P0 <- finite_rate >= 0.95
  P1 <- n_miss >= min_miss
  G1 <- abs(coverage - nominal) <= 2 * mcse
  G2 <- !is.na(binom_p) && binom_p >= 0.05 && ratio >= 0.5 && ratio <= 2
  status <- if (!P0) "interval_feasible(finite_rate<0.95)"
            else if (!P1) "interval_feasible(underpowered)"
            else if (G1 && G2) "PASS"
            else "FAIL"
  data.frame(member = label, n_fit = n_fit, finite_rate = round(finite_rate, 3),
             coverage = round(coverage, 3), mcse = round(mcse, 4),
             n_high = hi_miss, n_low = lo_miss, ratio = round(ratio, 2),
             binom_p = signif(binom_p, 3),
             P0 = P0, P1 = P1, G1 = G1, G2 = G2, status = status,
             stringsAsFactors = FALSE)
}

# Gate every {member}_lower/_upper channel present in a data frame.
gate_data_frame <- function(d, truth, members = c("profile", "wald"),
                            min_miss = 40L, nominal = 0.95) {
  est <- if ("estimate_sd" %in% names(d)) d$estimate_sd else rep(NA_real_, nrow(d))
  rows <- list()
  for (chan in members) {
    lo_col <- paste0(chan, "_lower"); hi_col <- paste0(chan, "_upper")
    if (!all(c(lo_col, hi_col) %in% names(d))) next
    rows[[chan]] <- gate_one(d[[lo_col]], d[[hi_col]], est, truth, chan,
                             min_miss = min_miss, nominal = nominal)
  }
  if (!length(rows)) return(NULL)
  do.call(rbind, rows)
}

# --- CLI (only when run as a script, not when sourced) ---------------------
if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 1L) stop("usage: gate-inference-ready.R <replicates.tsv> [--truth=] [--members=] [--min-miss=] [--nominal=]")
  path <- args[[1L]]
  opt <- function(flag, default) {
    hit <- grep(paste0("^--", flag, "="), args, value = TRUE)
    if (length(hit)) sub(paste0("^--", flag, "="), "", hit[[1L]]) else default
  }
  truth_arg <- opt("truth", NA)
  members   <- strsplit(opt("members", "profile,wald"), ",")[[1L]]
  min_miss  <- as.integer(opt("min-miss", "40"))
  nominal   <- as.numeric(opt("nominal", "0.95"))

  d <- utils::read.delim(path, stringsAsFactors = FALSE, check.names = FALSE)
  truth <- if (!is.na(truth_arg)) as.numeric(truth_arg) else if ("truth_sd" %in% names(d)) d$truth_sd[[1L]] else
    stop("no truth_sd column and no --truth=")

  out <- gate_data_frame(d, truth, members = members, min_miss = min_miss, nominal = nominal)
  if (is.null(out)) stop("no member/channel columns found for: ", paste(members, collapse = ", "))
  cat(sprintf("# gate-inference-ready  file=%s  truth=%.3f  min_miss=%d  nominal=%.2f\n",
              basename(path), truth, min_miss, nominal))
  print(out, row.names = FALSE)
  overall <- if (any(out$status == "PASS")) "PASS_SOME" else if (all(grepl("interval_feasible", out$status))) "INTERVAL_FEASIBLE" else "FAIL"
  cat(sprintf("GATE_RESULT=%s\n", overall))
}
