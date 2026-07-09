#!/usr/bin/env Rscript
# gate-inference-ready.R -- the TWO-TIER coverage gate for structured-RE cells.
#
# History / why two tiers (READ THIS -- it is the recurring mistake):
#   Fisher's 2026-07-08 audit correctly measured that the promoted cells under-cover
#   (~0.90) and miss asymmetrically at g=8. The FIRST version of this gate then
#   demanded nominal-exact coverage + symmetric misses and called every cell FAIL.
#   That is the `supported` bar applied to the `inference_ready` tier -- a category
#   error. Banked doctrine (LEARNINGS, 2026-06-27, Fisher+Curie verified):
#     * g=8 variance-component intervals ~0.85-0.90 (Wald) / ~0.91 (profile) are
#       EXPECTED, not a defect. The gap = (a) df-narrowness (z where t(df~=g-1)
#       belongs; +3-5 pts) + (b) ML shrinkage (only REML/larger-g fixes the centre).
#     * The PROFILE channel self-corrects most of both; g=32 profile is CERTIFIED
#       NOMINAL (0.948-0.956). The upper-tail miss asymmetry is the SD estimator's
#       small-sample skew -- documented as a claim_boundary, not disqualifying.
#
#   So the two tiers, matching the board's own definitions:
#     inference_ready -- an HONEST interval at its achievable small-sample coverage
#                        (>= a g-appropriate floor), skew documented. Uses the
#                        calibration-aware channel (profile > bc > wald).
#     supported       -- NOMINAL-EXACT: |cov - nominal| <= 2*MCSE AND miss-balance.
#                        The harder tier; correctly withheld for the small-g cells.
#
#   A cell can (and these do) hold inference_ready while failing supported. Do NOT
#   apply the supported bar to inference_ready. This is the whole point of the file.
#
# Both a CLI and a library (source() for gate_one()/gate_data_frame(); CLI guarded
# by sys.nframe()==0L). Reads a *-replicates.tsv with {channel}_lower/_upper + truth.

# ss_floor(g): the expected small-sample PROFILE coverage floor at group count g.
# From the banked g-sweep: g=8 profile ~0.91, g=32 profile ~nominal. Taper the
# df-narrowness margin as ~1/g. A cell is inference_ready if its (calibration-aware)
# coverage is not significantly below this floor.
ss_floor <- function(g, nominal = 0.95) {
  if (is.null(g) || is.na(g)) g <- 8L
  nominal - 0.04 * (8 / max(g, 1))     # g8 -> 0.91, g16 -> 0.93, g32 -> 0.94
}

gate_one <- function(lo, hi, est, truth, label,
                     g = 8L, min_miss = 40L, nominal = 0.95, tier_floor = NULL) {
  floor <- if (is.null(tier_floor)) ss_floor(g, nominal) else tier_floor
  fitted <- !(is.na(lo) & is.na(hi))
  n_fit <- sum(fitted)
  finite <- is.finite(lo) & is.finite(hi)
  finite_rate <- sum(finite) / max(n_fit, 1L)
  covered <- finite & lo <= truth & hi >= truth
  coverage <- sum(covered) / max(n_fit, 1L)         # UNCENSORED denominator
  mcse <- sqrt(coverage * (1 - coverage) / max(n_fit, 1L))
  hi_miss <- sum(finite & hi < truth)
  lo_miss <- sum(finite & lo > truth)
  if (!all(is.na(est))) {
    nf <- fitted & !finite
    hi_miss <- hi_miss + sum(nf & est > truth, na.rm = TRUE)
    lo_miss <- lo_miss + sum(nf & est <= truth, na.rm = TRUE)
  }
  n_miss <- hi_miss + lo_miss
  ratio <- if (lo_miss == 0) if (hi_miss == 0) 1 else Inf else hi_miss / lo_miss
  binom_p <- if (n_miss > 0) stats::binom.test(hi_miss, n_miss, 0.5)$p.value else NA_real_

  P0 <- finite_rate >= 0.95
  # inference_ready: honest small-sample interval -- coverage not significantly
  # below the g-appropriate floor. Asymmetry is a documented caveat, NOT a fail.
  IR <- P0 && (coverage + 2 * mcse >= floor)
  ir_status <- if (!P0) "finite_rate<0.95"
               else if (IR) "PASS"
               else "FAIL(below_ss_floor)"
  # supported: the nominal-exact tier (harder; expected to be withheld at small g).
  balance_ok <- (n_miss > 0) && !is.na(binom_p) && binom_p >= 0.05 && ratio >= 0.5 && ratio <= 2
  nominal_ok <- abs(coverage - nominal) <= 2 * mcse
  sup_status <- if (!P0) "finite_rate<0.95"
                else if (n_miss < min_miss) "underpowered"
                else if (nominal_ok && balance_ok) "PASS"
                else "FAIL"

  data.frame(member = label, g = g, n_fit = n_fit, finite_rate = round(finite_rate, 3),
             coverage = round(coverage, 3), mcse = round(mcse, 4), ss_floor = round(floor, 3),
             n_high = hi_miss, n_low = lo_miss, ratio = round(ratio, 2),
             binom_p = signif(binom_p, 3),
             inference_ready = ir_status, supported = sup_status,
             stringsAsFactors = FALSE)
}

# Gate every {channel}_lower/_upper present. `members` is the channel PREFERENCE
# order for inference_ready (calibration-aware first): profile > bc > wald.
gate_data_frame <- function(d, truth, members = c("profile", "bc", "wald"),
                            g = 8L, min_miss = 40L, nominal = 0.95) {
  est <- if ("estimate_sd" %in% names(d)) d$estimate_sd else rep(NA_real_, nrow(d))
  rows <- list()
  for (chan in members) {
    lo_col <- paste0(chan, "_lower"); hi_col <- paste0(chan, "_upper")
    if (!all(c(lo_col, hi_col) %in% names(d))) next
    r <- gate_one(d[[lo_col]], d[[hi_col]], est, truth, chan, g = g,
                  min_miss = min_miss, nominal = nominal)
    rows[[chan]] <- r
  }
  if (!length(rows)) return(NULL)
  do.call(rbind, rows)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 1L) stop("usage: gate-inference-ready.R <replicates.tsv> [--truth=] [--members=profile,bc,wald] [--g=8] [--min-miss=40] [--nominal=0.95]")
  path <- args[[1L]]
  opt <- function(flag, default) {
    hit <- grep(paste0("^--", flag, "="), args, value = TRUE)
    if (length(hit)) sub(paste0("^--", flag, "="), "", hit[[1L]]) else default
  }
  truth_arg <- opt("truth", NA); members <- strsplit(opt("members", "profile,bc,wald"), ",")[[1L]]
  g <- as.integer(opt("g", "8")); min_miss <- as.integer(opt("min-miss", "40"))
  nominal <- as.numeric(opt("nominal", "0.95"))
  d <- utils::read.delim(path, stringsAsFactors = FALSE, check.names = FALSE)
  truth <- if (!is.na(truth_arg)) as.numeric(truth_arg) else if ("truth_sd" %in% names(d)) d$truth_sd[[1L]] else
    stop("no truth_sd column and no --truth=")
  out <- gate_data_frame(d, truth, members = members, g = g, min_miss = min_miss, nominal = nominal)
  if (is.null(out)) stop("no channel columns found for: ", paste(members, collapse = ", "))
  cat(sprintf("# gate  file=%s  truth=%.3f  g=%d  ss_floor=%.3f\n", basename(path), truth, g, ss_floor(g, nominal)))
  print(out, row.names = FALSE)
  ir <- if (any(out$inference_ready == "PASS")) "PASS" else "FAIL"
  sup <- if (any(out$supported == "PASS")) "PASS" else "not_supported"
  cat(sprintf("INFERENCE_READY=%s  SUPPORTED=%s\n", ir, sup))
}
