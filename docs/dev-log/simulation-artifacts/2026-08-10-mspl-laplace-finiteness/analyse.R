# F1 scorer. Implements PREREGISTRATION.md sec 5 and sec 6 exactly.
# No rule is chosen here; every threshold below is quoted from the frozen doc.

d <- read.delim("data/f1_raw.tsv", stringsAsFactors = FALSE)
stopifnot(nrow(d) == 20000L)

m <- d[d$estimator == "mspl", ]
l <- d[d$estimator == "ml", ]

# --- sec 5: primary endpoint -------------------------------------------------
# E1 fixed_information_finite_positive TRUE; E2 logdet finite; E3 beta finite.
# NA counts as FAILURE, never a dropped row (E1's first scorer filtered with
# is.finite() and removed the evidence itself).
ok <- function(x) !is.na(x) & x
m$E1 <- ok(m$fi_finite_pos)
m$E2 <- !is.na(m$logdet_fi) & is.finite(m$logdet_fi)
m$E3 <- !is.na(m$beta) & is.finite(m$beta)
m$E4 <- ok(m$hess_pd)                       # reported, NOT gating
m$E5 <- !is.na(m$conv) & m$conv == 0L       # reported, NOT gating
m$PRIMARY <- m$E1 & m$E2 & m$E3

cp_lower <- function(k, n) if (k == 0) 0 else qbeta(0.025, k, n - k + 1)

cells <- sort(unique(m$cell))
res <- do.call(rbind, lapply(cells, function(cc) {
  s  <- m[m$cell == cc, ]
  lc <- l[l$cell == cc, ]
  k  <- sum(s$PRIMARY); n <- nrow(s)
  lo <- cp_lower(k, n)
  # sec 6 control: ML must diverge (|SE| > 1e3) or fail, in >= 50% of reps,
  # in every cell with eta_d <= -6.
  ml_bad <- mean(is.na(lc$se) | !is.finite(lc$se) | abs(lc$se) > 1e3)
  data.frame(cell = cc, q = s$q[1], eta_d = s$eta_d[1], G = s$G[1],
             n = n, primary_k = k, primary_prop = k / n, cp_lower = lo,
             FINITENESS = (k / n >= 0.99) && (lo >= 0.97),
             E4_pd = mean(s$E4), E5_conv = mean(s$E5),
             median_logdet = median(s$logdet_fi, na.rm = TRUE),
             median_event_rate = median(s$event_rate),
             ml_divergent = ml_bad,
             control_ok = if (s$eta_d[1] <= -6) ml_bad >= 0.50 else NA,
             max_abs_ident_err = max(abs(s$ident_err), na.rm = TRUE),
             stringsAsFactors = FALSE)
}))

cat("=== PRIMARY (prereg sec 5): finiteness by cell ===\n")
print(res[, c("cell","q","eta_d","G","primary_prop","cp_lower","FINITENESS",
              "E4_pd","E5_conv","median_logdet")], row.names = FALSE, digits = 4)

cat("\n=== CONTROL (prereg sec 6): ML must diverge where MSPL stays finite ===\n")
print(res[, c("cell","q","eta_d","G","median_event_rate","ml_divergent","control_ok")],
      row.names = FALSE, digits = 4)

cat("\n=== SECONDARY: median logdet must decline as eta_d falls, per (q,G) ===\n")
for (qq in unique(res$q)) for (gg in unique(res$G)) {
  s <- res[res$q == qq & res$G == gg, ]
  s <- s[order(-s$eta_d), ]
  mono <- all(diff(s$median_logdet) <= 0)
  cat(sprintf("  %s G=%-3d  logdet: %s   monotone_decline=%s\n", qq, gg,
              paste(sprintf("%.3f", s$median_logdet), collapse = " -> "), mono))
}

cat("\n=== VERDICT ===\n")
n_fin  <- sum(res$FINITENESS)
ctrl   <- res[!is.na(res$control_ok), ]
n_ctrl <- sum(ctrl$control_ok)
cat(sprintf("  finiteness holds : %d / %d cells\n", n_fin, nrow(res)))
cat(sprintf("  control satisfied: %d / %d cells with eta_d <= -6\n", n_ctrl, nrow(ctrl)))
cat(sprintf("  max |objective identity error| : %.3e\n", max(res$max_abs_ident_err)))
cat(sprintf("  OVERALL: %s\n",
    if (n_fin == nrow(res) && n_ctrl == nrow(ctrl)) "PASS"
    else if (n_ctrl < nrow(ctrl)) "VOID - control failed, harness suspect (sec 6)"
    else "FAIL - finiteness not retained in every cell"))

write.table(res, "data/f1_cells.tsv", sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nwrote data/f1_cells.tsv\n")
