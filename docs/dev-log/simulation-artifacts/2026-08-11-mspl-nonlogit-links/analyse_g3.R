# G3 — grading against PREREGISTRATION-G3-SE.md. Frozen before any replicate.
#
# Three rules from the retracted 2026-08-09 analysis are enforced here in code:
#   (a) degeneracy guard  -- a collapsed cell gets NO calibration verdict
#   (b) retention is an endpoint -- every cell appears, none is filtered away
#   (c) pairing (D-117)  -- cross-engine figures use the common replicate set
#
# Usage: Rscript --no-init-file analyse_g3.R [--raw data/g3_raw.tsv.gz]

args <- commandArgs(trailingOnly = TRUE)
getarg <- function(k, d = NULL) { i <- match(k, args); if (is.na(i)) d else args[i + 1L] }
RAW <- getarg("--raw", "data/g3_raw.tsv.gz")

d <- read.delim(gzfile(RAW), stringsAsFactors = FALSE)
stopifnot(nrow(d) == 180000L, length(unique(d$cell)) == 60L)

usable <- function(z) isTRUE(z)
d$has_est <- d$ok %in% TRUE & is.finite(d$beta) & is.finite(d$se)

cells <- unique(d[, c("cell","cond","q","eta_d","G","regime")])
cells <- cells[order(cells$cell), ]

band <- function(regime) if (regime == "identified")
  list(pass = c(0.95, 1.05), border = c(0.90, 1.10)) else
  list(pass = c(0.90, 1.15), border = c(0.80, 1.25))

res <- do.call(rbind, lapply(seq_len(nrow(cells)), function(i) {
  cc <- cells[i, ]
  s  <- d[d$cell == cc$cell, ]
  m  <- s[s$engine == "mspl", ]
  # (c) PAIRED set: replicates where ALL THREE engines produced an estimate.
  by_rep <- tapply(s$has_est, list(s$rep, s$engine), function(z) isTRUE(z[1]))
  paired_reps <- rownames(by_rep)[apply(by_rep, 1, function(r) all(r %in% TRUE))]
  mm <- m[m$has_est, ]                       # MSPL marginal retained set
  n_ret <- nrow(mm)
  # (a) DEGENERACY: R_mad infinite (mad == 0) or < 10% distinct estimates.
  mad_b <- if (n_ret > 1) stats::mad(mm$beta) else NA_real_
  sd_b  <- if (n_ret > 1) stats::sd(mm$beta)  else NA_real_
  n_dist <- length(unique(round(mm$beta, 8)))
  degenerate <- n_ret > 0 && ((!is.na(mad_b) && mad_b == 0) ||
                                (n_ret > 0 && n_dist < 0.10 * n_ret))
  R_sd  <- if (!is.na(sd_b)  && sd_b  > 0) mean(mm$se) / sd_b  else NA_real_
  R_mad <- if (!is.na(mad_b) && mad_b > 0) mean(mm$se) / mad_b else Inf
  b <- band(cc$regime)
  verdict <- if (n_ret < 50) "UNVERDICTABLE-RETENTION"
    else if (degenerate) "DEGENERATE"
    else if (is.na(R_sd)) "UNVERDICTABLE"
    else if (R_sd >= b$pass[1] && R_sd <= b$pass[2]) "PASS"
    else if (R_sd >= b$border[1] && R_sd <= b$border[2]) "BORDERLINE"
    else if (R_sd < b$border[1]) "FAIL-ANTICONSERVATIVE"
    else "FAIL-HIGH"
  # (3) SE-AVAILABILITY: reported success, no usable SE.
  conv_ok <- m$ok %in% TRUE & m$conv %in% 0L
  se_na_rate <- if (sum(conv_ok) > 0)
    mean(is.na(m$se[conv_ok]) | !is.finite(m$se[conv_ok])) else NA_real_
  data.frame(cc,
             n_mspl_retained = n_ret,
             n_paired = length(paired_reps),
             retention_mspl = n_ret / 1000,
             se_na_rate_given_conv0 = se_na_rate,
             n_distinct_beta = n_dist,
             R_sd = R_sd, R_mad = R_mad,
             degenerate = degenerate,
             verdict = verdict, stringsAsFactors = FALSE)
}))

cat("=== (b) RETENTION IS AN ENDPOINT: all", nrow(res), "cells present ===\n\n")

cat("=== PER-LINK VERDICT, identified regime (the calibration claim) ===\n")
id <- res[res$regime == "identified", ]
byc <- do.call(rbind, lapply(unique(id$cond), function(cn) {
  r <- id[id$cond == cn, ]
  data.frame(cond = cn, cells = nrow(r),
             pass = sum(r$verdict == "PASS"),
             borderline = sum(r$verdict == "BORDERLINE"),
             anticons_fail = sum(r$verdict == "FAIL-ANTICONSERVATIVE"),
             other = sum(!r$verdict %in% c("PASS","BORDERLINE","FAIL-ANTICONSERVATIVE")),
             min_R = min(r$R_sd, na.rm = TRUE), max_R = max(r$R_sd, na.rm = TRUE),
             claim = if (any(r$verdict == "FAIL-ANTICONSERVATIVE")) "NOT CALIBRATED"
                     else "CALIBRATED", stringsAsFactors = FALSE)
}))
print(byc, row.names = FALSE, digits = 4)

cat("\n=== separated regime ===\n")
sp <- res[res$regime == "separated", ]
bys <- do.call(rbind, lapply(unique(sp$cond), function(cn) {
  r <- sp[sp$cond == cn, ]
  data.frame(cond = cn, cells = nrow(r),
             pass = sum(r$verdict == "PASS"), borderline = sum(r$verdict == "BORDERLINE"),
             degenerate = sum(r$verdict == "DEGENERATE"),
             low_retention = sum(r$verdict == "UNVERDICTABLE-RETENTION"),
             anticons_fail = sum(r$verdict == "FAIL-ANTICONSERVATIVE"),
             stringsAsFactors = FALSE)
}))
print(bys, row.names = FALSE)

cat("\n=== ANTI-CONSERVATIVE FAILURES (one fails the campaign for that link) ===\n")
bad <- res[res$verdict == "FAIL-ANTICONSERVATIVE", ]
if (nrow(bad)) print(bad[, c("cell","cond","q","eta_d","G","regime","R_sd","n_mspl_retained")],
                     row.names = FALSE, digits = 4) else cat("none\n")

cat("\n=== SE-AVAILABILITY: reported convergence == 0 but NO usable SE ===\n")
cat("(prereg §3 -- what a user actually receives)\n")
sa <- res[!is.na(res$se_na_rate_given_conv0) & res$se_na_rate_given_conv0 > 0, ]
if (nrow(sa)) {
  print(sa[order(-sa$se_na_rate_given_conv0),
           c("cell","cond","q","eta_d","G","regime","se_na_rate_given_conv0","retention_mspl")],
        row.names = FALSE, digits = 4)
} else cat("none -- every converged MSPL fit carried a usable SE\n")
cat("\nby condition, worst cell:\n")
print(do.call(rbind, lapply(unique(res$cond), function(cn) {
  r <- res[res$cond == cn, ]
  data.frame(cond = cn, worst_se_na_rate = max(r$se_na_rate_given_conv0, na.rm = TRUE),
             cells_with_any = sum(r$se_na_rate_given_conv0 > 0, na.rm = TRUE))
})), row.names = FALSE, digits = 4)

cat("\n=== DEGENERATE cells (R is not a calibration statistic there) ===\n")
dg <- res[res$degenerate, ]
if (nrow(dg)) print(dg[, c("cell","cond","q","eta_d","G","n_mspl_retained","n_distinct_beta","R_sd","R_mad")],
                    row.names = FALSE, digits = 4) else cat("none\n")

write.csv(res, "G3-cell-results.csv", row.names = FALSE)
cat("\nwrote G3-cell-results.csv\n")
