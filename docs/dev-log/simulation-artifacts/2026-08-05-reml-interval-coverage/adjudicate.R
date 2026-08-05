# Harness investigation demanded by PREREGISTRATION.md §6(a): the n_each = 3
# falsifier fired. Before reporting anything, decompose WHY coverage differs.
#
# The suspicious pattern: REML has WORSE point bias and (at g10) NARROWER
# intervals, yet HIGHER coverage. If that is real it must show up as a shift in
# interval LOCATION, not width. If it is an artifact it should show up as a
# broken endpoint, a scale mismatch, or a survivorship difference.

files <- Sys.glob("results/cell*.csv")
TRUTH <- 0.5

miss <- function(lo, hi, truth) {
  ifelse(!is.finite(lo) | !is.finite(hi), "nonfinite",
    ifelse(truth < lo, "lower_miss", ifelse(truth > hi, "upper_miss", "covered")))
}

rows <- list()
for (f in files) {
  d <- read.csv(f, stringsAsFactors = FALSE)
  u <- d$ml_ok & d$re_ok & is.finite(d$ml_p_lo) & is.finite(d$re_p_lo)
  d <- d[u, , drop = FALSE]
  cid <- d$cell_id[[1L]]

  m_ml <- miss(d$ml_p_lo, d$ml_p_hi, TRUTH)
  m_re <- miss(d$re_p_lo, d$re_p_hi, TRUTH)

  cat(sprintf("\n########## %s  (n = %d) ##########\n", cid, nrow(d)))

  cat("\n-- miss decomposition (profile) --\n")
  print(rbind(ML = table(factor(m_ml, c("covered","lower_miss","upper_miss","nonfinite"))),
              REML = table(factor(m_re, c("covered","lower_miss","upper_miss","nonfinite")))))

  cat("\n-- endpoint location (mean) --\n")
  cat(sprintf("  lower : ML %.4f  REML %.4f   (REML - ML = %+.4f)\n",
              mean(d$ml_p_lo), mean(d$re_p_lo), mean(d$re_p_lo - d$ml_p_lo)))
  cat(sprintf("  upper : ML %.4f  REML %.4f   (REML - ML = %+.4f)\n",
              mean(d$ml_p_hi), mean(d$re_p_hi), mean(d$re_p_hi - d$ml_p_hi)))
  cat(sprintf("  point : ML %.4f  REML %.4f   (REML - ML = %+.4f)\n",
              mean(d$ml_est, na.rm = TRUE), mean(d$re_est, na.rm = TRUE),
              mean(d$re_est - d$ml_est, na.rm = TRUE)))

  # Where does the coverage gain come from? Split by ML's boundary status.
  b <- !is.na(d$ml_p_bnd) & d$ml_p_bnd
  for (lab in c("AT boundary", "NOT at boundary")) {
    s <- if (lab == "AT boundary") b else !b
    if (sum(s) == 0L) next
    cat(sprintf("\n-- %s (n = %d) --\n", lab, sum(s)))
    cat(sprintf("  profile coverage : ML %.4f   REML %.4f   (delta %+.4f)\n",
                mean(m_ml[s] == "covered"), mean(m_re[s] == "covered"),
                mean(m_re[s] == "covered") - mean(m_ml[s] == "covered")))
    cat(sprintf("  mean upper       : ML %.4f   REML %.4f\n",
                mean(d$ml_p_hi[s]), mean(d$re_p_hi[s])))
    cat(sprintf("  mean lower       : ML %.4f   REML %.4f\n",
                mean(d$ml_p_lo[s]), mean(d$re_p_lo[s])))
  }

  # Survivorship guard (PREREG 6c): did the arms keep the same replicates?
  d0 <- read.csv(f, stringsAsFactors = FALSE)
  cat(sprintf("\n-- survivorship -- usable ML-only %d, REML-only %d, both %d, of %d\n",
              sum(d0$ml_ok & is.finite(d0$ml_p_lo) & !(d0$re_ok & is.finite(d0$re_p_lo))),
              sum(d0$re_ok & is.finite(d0$re_p_lo) & !(d0$ml_ok & is.finite(d0$ml_p_lo))),
              nrow(d), nrow(d0)))

  rows[[cid]] <- data.frame(
    cell = cid, n = nrow(d),
    cov_ml = mean(m_ml == "covered"), cov_re = mean(m_re == "covered"),
    upper_shift = mean(d$re_p_hi - d$ml_p_hi),
    lower_shift = mean(d$re_p_lo - d$ml_p_lo),
    point_shift = mean(d$re_est - d$ml_est, na.rm = TRUE),
    stringsAsFactors = FALSE)
}

cat("\n\n########## SUMMARY ##########\n")
print(do.call(rbind, rows), row.names = FALSE, digits = 4)
