# F2 scorer. Thresholds are F1's, quoted from PREREGISTRATION.md sec 4 and sec 5.
# Nothing is chosen here after seeing output.

d <- read.delim("data/f2_raw.tsv", stringsAsFactors = FALSE)
stopifnot(nrow(d) == 8000L)

m <- d[d$estimator == "mspl", ]
l <- d[d$estimator == "ml", ]

ok <- function(x) !is.na(x) & x
m$E1 <- ok(m$fi_finite_pos)
m$E2 <- !is.na(m$logdet_fi) & is.finite(m$logdet_fi)
m$E3 <- !is.na(m$beta) & is.finite(m$beta)
m$E4 <- ok(m$hess_pd)                      # reported, NOT gating
m$E5 <- !is.na(m$conv) & m$conv == 0L      # reported, NOT gating
m$PRIMARY <- m$E1 & m$E2 & m$E3            # NA scores as FAILURE, never dropped

cp_lower <- function(k, n) if (k == 0) 0 else qbeta(0.025, k, n - k + 1)

res <- do.call(rbind, lapply(sort(unique(m$cell)), function(cc) {
  s <- m[m$cell == cc, ]; lc <- l[l$cell == cc, ]
  k <- sum(s$PRIMARY); n <- nrow(s); lo <- cp_lower(k, n)
  data.frame(cell = cc, eta_d = s$eta_d[1], G = s$G[1], n_per = s$n_per[1],
             N = s$G[1] * s$n_per[1],
             mean_prev = mean(s$event_rate),
             pct_zero_event = mean(s$event_rate == 0),
             primary_prop = k / n, cp_lower = lo,
             FINITENESS = (k / n >= 0.99) && (lo >= 0.97),
             E4_pd = mean(s$E4), E5_conv = mean(s$E5),
             median_logdet = median(s$logdet_fi, na.rm = TRUE),
             ml_divergent = mean(is.na(lc$se) | !is.finite(lc$se) | abs(lc$se) > 1e3),
             stringsAsFactors = FALSE)
}))
res$control_ok <- res$ml_divergent >= 0.50   # prereg sec 5: EVERY cell

cat("=== PRIMARY (prereg sec 4) ===\n")
print(res[, c("cell","eta_d","G","n_per","N","mean_prev","pct_zero_event",
              "primary_prop","cp_lower","FINITENESS")], row.names = FALSE, digits = 4)

cat("\n=== CONTROL (prereg sec 5): ML must diverge/fail in >= 50% of EVERY cell ===\n")
print(res[, c("cell","eta_d","G","n_per","ml_divergent","control_ok",
              "E4_pd","E5_conv")], row.names = FALSE, digits = 4)

cat("\n=== SECONDARY: median logdet, eta_d = -6 vs -8, within (G, n_per) ===\n")
for (gg in unique(res$G)) for (nn in unique(res$n_per)) {
  a <- res[res$G == gg & res$n_per == nn & res$eta_d == -6, "median_logdet"]
  b <- res[res$G == gg & res$n_per == nn & res$eta_d == -8, "median_logdet"]
  cat(sprintf("  G=%-4d n_per=%-3d  logdet %8.3f (-6) -> %8.3f (-8)   lower_at_-8=%s\n",
              gg, nn, a, b, b < a))
}

cat("\n=== VERDICT ===\n")
nf <- sum(res$FINITENESS); nc <- sum(res$control_ok)
cat(sprintf("  finiteness holds : %d / %d cells\n", nf, nrow(res)))
cat(sprintf("  control satisfied: %d / %d cells\n", nc, nrow(res)))
cat(sprintf("  rarest cell      : prevalence %.2e, finiteness %s\n",
            min(res$mean_prev), res$FINITENESS[which.min(res$mean_prev)]))
cat(sprintf("  OVERALL: %s\n",
    if (nc < nrow(res)) "VOID in cells where the control failed - see sec 5"
    else if (nf == nrow(res)) "PASS"
    else "FAIL - finiteness not retained in every cell"))

write.table(res, "data/f2_cells.tsv", sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nwrote data/f2_cells.tsv\n")
