# G2 — grading against PREREGISTRATION-G2-CN.md §3. Frozen before any replicate.
d <- read.delim(gzfile("data/g2_raw.tsv.gz"), stringsAsFactors = FALSE)
stopifnot(nrow(d) == 108000L, length(unique(d$cell)) == 36L)
d$has <- d$ok %in% TRUE & is.finite(d$beta)

cells <- unique(d[, c("cell","link","eta_d","G","n_eff")]); cells <- cells[order(cells$cell), ]
res <- do.call(rbind, lapply(seq_len(nrow(cells)), function(i) {
  cc <- cells[i, ]; s <- d[d$cell == cc$cell, ]
  w <- tapply(s$has, list(s$rep, s$arm), function(z) isTRUE(z[1]))
  # paired on BOTH mspl arms (prereg §3); ml used where available
  keep <- rownames(w)[w[, "shipped"] %in% TRUE & w[, "perlink"] %in% TRUE]
  sh <- s[s$arm == "shipped" & s$rep %in% keep, ]
  pl <- s[s$arm == "perlink" & s$rep %in% keep, ]
  ml <- s[s$arm == "ml"      & s$rep %in% keep & s$has, ]
  bias_sh <- mean(sh$beta) - 1; bias_pl <- mean(pl$beta) - 1
  sd_sh <- stats::sd(sh$beta)
  data.frame(cc, n_paired = length(keep),
    bias_shipped = bias_sh, bias_perlink = bias_pl,
    d_bias = abs(bias_sh - bias_pl), sd_beta = sd_sh,
    materiality = abs(bias_sh - bias_pl) / sd_sh,
    rmse_shipped = sqrt(mean((sh$beta - 1)^2)), rmse_perlink = sqrt(mean((pl$beta - 1)^2)),
    ml_gap_shipped = if (nrow(ml)) abs(mean(sh$beta) - mean(ml$beta)) else NA_real_,
    ml_gap_perlink = if (nrow(ml)) abs(mean(pl$beta) - mean(ml$beta)) else NA_real_,
    stringsAsFactors = FALSE)
}))
cat("=== NULL CONTROL: logit arms must be bit-identical ===\n")
lg <- res[res$link == "logit", ]
cat("max |d_bias| over logit cells:", format(max(lg$d_bias), scientific = TRUE),
    " -> control", if (max(lg$d_bias) == 0) "PASS" else "**FAIL**", "\n\n")
cat("=== MATERIALITY = |bias_shipped - bias_perlink| / sd(beta), n_eff >= 300 ===\n")
v <- res[res$link != "logit" & res$n_eff >= 300, ]
print(v[order(v$link, v$eta_d, v$n_eff),
        c("link","eta_d","n_eff","bias_shipped","bias_perlink","d_bias","sd_beta","materiality")],
      row.names = FALSE, digits = 4)
cat("\n=== VERDICT per link (prereg §3) ===\n")
for (lk in c("probit","cloglog")) {
  x <- v[v$link == lk, ]; mx <- max(x$materiality)
  verdict <- if (mx < 0.10) "IMMATERIAL" else if (mx < 0.25) "BORDERLINE" else "MATERIAL"
  cat(sprintf("%-8s max materiality = %.4f over %d cells  ->  %s\n", lk, mx, nrow(x), verdict))
}
cat("\n=== n_eff = 120 cells (reported, excluded from verdict) ===\n")
e <- res[res$link != "logit" & res$n_eff == 120, ]
print(e[, c("link","eta_d","n_eff","d_bias","sd_beta","materiality")], row.names = FALSE, digits = 4)
cat("\n=== SECONDARY: does |d_bias| decay ~sqrt(p/n)? expect ~3.16x from n=120 to 1200 ===\n")
for (lk in c("probit","cloglog")) for (ed in unique(res$eta_d[res$link == lk])) {
  x <- res[res$link == lk & res$eta_d == ed, ]; x <- x[order(x$n_eff), ]
  cat(sprintf("%-8s eta_d=%-5s  d_bias: %s   ratio n120/n1200 = %.2f\n", lk, ed,
      paste(sprintf("%.4f", x$d_bias), collapse = " "), x$d_bias[1] / x$d_bias[nrow(x)]))
}
write.csv(res, "G2-cell-results.csv", row.names = FALSE)
