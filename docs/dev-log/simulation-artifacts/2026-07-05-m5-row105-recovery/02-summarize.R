# M5 row-105 crossed recovery ladder: summarize 01-results.tsv into a
# per-rung (mean / bias / rmse) table for sd_spatial, sd_relmat, sigma_nb2.

art <- "docs/dev-log/simulation-artifacts/2026-07-05-m5-row105-recovery"
res <- utils::read.delim(file.path(art, "01-results.tsv"), stringsAsFactors = FALSE)
res <- res[!is.na(res$sd_spatial_hat), ]  # drop any error rows

rung_order <- c("crossed_n10", "crossed_n20", "crossed_n30", "noncrossed_control_n10")
res$rung <- factor(res$rung, levels = rung_order)

summarize_param <- function(df, hat_col, truth_col) {
  hat <- df[[hat_col]]
  truth <- df[[truth_col]]
  err <- hat - truth
  c(
    n_seeds = length(hat),
    mean_hat = mean(hat),
    truth = mean(truth),
    bias = mean(err),
    rmse = sqrt(mean(err^2))
  )
}

rows <- list()
for (r in levels(res$rung)) {
  sub <- res[res$rung == r, ]
  if (!nrow(sub)) next
  for (param in c("sd_spatial", "sd_relmat", "sigma_nb2")) {
    s <- summarize_param(sub, paste0(param, "_hat"), paste0(param, "_true"))
    rows[[length(rows) + 1L]] <- data.frame(
      rung = r, n_lvl = sub$n_lvl[[1L]], param = param,
      n_seeds = s[["n_seeds"]], truth = round(s[["truth"]], 4),
      mean_hat = round(s[["mean_hat"]], 4), bias = round(s[["bias"]], 4),
      rmse = round(s[["rmse"]], 4),
      pdHess_rate = round(mean(as.logical(sub$pdHess)), 3),
      conv0_rate = round(mean(sub$conv == 0), 3),
      cap_sat_rate = round(mean(as.logical(sub$cap_sat)), 3)
    )
  }
}
summary_tab <- do.call(rbind, rows)
rownames(summary_tab) <- NULL
utils::write.table(
  summary_tab, file.path(art, "02-summary.tsv"), sep = "\t",
  row.names = FALSE, quote = FALSE
)
print(summary_tab, row.names = FALSE)
