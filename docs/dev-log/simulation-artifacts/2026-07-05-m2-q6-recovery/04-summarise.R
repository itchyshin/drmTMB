# Summarise the streamed q6 recovery results into a recovery-vs-n curve and a
# per-provider n=512 multi-seed robustness table. Read-only over the TSV.
#   Rscript --no-init-file 04-summarise.R
art <- "docs/dev-log/simulation-artifacts/2026-07-05-m2-q6-recovery"
d <- utils::read.delim(file.path(art, "03-recovery-results.tsv"),
                       stringsAsFactors = FALSE)
d$pdHess <- as.logical(d$pdHess)
d$conv <- as.integer(d$conv)
d$rmse <- as.numeric(d$rmse)
d$max_abs_rho_hat <- as.numeric(d$max_abs_rho_hat)
d$frobenius <- as.numeric(d$frobenius)

cat("=== recovery-vs-n curve (seed 20260705) ===\n")
curve <- d[d$seed == 20260705L, ]
curve <- curve[order(curve$provider, curve$n_group), ]
print(curve[, c("provider", "n_group", "n_obs", "conv", "pdHess",
                "max_abs_rho_hat", "cap_saturated", "rmse", "frobenius",
                "elapsed_s")],
      row.names = FALSE)

cat("\n=== n=512 multi-seed robustness (all seeds) ===\n")
rob <- d[d$n_group == 512L, ]
agg <- do.call(rbind, lapply(split(rob, rob$provider), function(g) {
  data.frame(
    provider = g$provider[1],
    n_seed = nrow(g),
    pct_conv0 = mean(g$conv == 0, na.rm = TRUE),
    pct_pdHess = mean(g$pdHess, na.rm = TRUE),
    pct_cap_sat = mean(as.logical(g$cap_saturated), na.rm = TRUE),
    median_rmse = round(median(g$rmse, na.rm = TRUE), 3),
    max_rmse = round(max(g$rmse, na.rm = TRUE), 3),
    stringsAsFactors = FALSE
  )
}))
print(agg, row.names = FALSE)

cat("\n=== provider verdict (does q6 reach pdHess=TRUE at scale?) ===\n")
for (prov in unique(d$provider)) {
  g <- d[d$provider == prov, ]
  big <- g[g$n_group >= 512L, ]
  cat(sprintf("%-8s: pdHess@>=512 = %d/%d ; best rmse = %.3f (n=%d)\n",
              prov, sum(big$pdHess, na.rm = TRUE), nrow(big),
              min(g$rmse, na.rm = TRUE),
              g$n_group[which.min(g$rmse)]))
}
