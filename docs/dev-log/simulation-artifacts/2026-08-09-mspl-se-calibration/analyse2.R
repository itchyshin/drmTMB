# Corrected analysis: SAME-REPLICATE pairing (prereg sec 5 / D-117) + degeneracy
# diagnostics + bootstrap MCSE. Supersedes analyse.R, which did none of these.
d <- do.call(rbind, lapply(list.files("out", pattern="\\.tsv$", full.names=TRUE), read.delim))
d$ok <- d$ok == "TRUE" | d$ok == TRUE
d$usable <- d$ok & is.finite(d$est) & is.finite(d$se)

cells <- sort(unique(d$cell))
out <- list(); drops <- list()
for (cl in cells) {
  s <- d[d$cell == cl, ]
  # SAME-REPLICATE INTERSECTION: seeds usable in EVERY engine
  keep <- Reduce(intersect, lapply(split(s, s$engine), function(g) g$seed[g$usable]))
  for (e in unique(s$engine)) {
    g_all <- s[s$engine == e, ]
    n_use <- sum(g_all$usable)
    drops[[length(drops)+1L]] <- data.frame(cell=cl, engine=e, n_total=nrow(g_all),
      n_ok=sum(g_all$ok), n_se_finite=sum(is.finite(g_all$se)),
      n_usable=n_use, n_paired=length(keep))
    if (length(keep) < 50) next
    g <- g_all[g_all$seed %in% keep, ]
    e_v <- g$est; s_v <- g$se
    sd_b <- sd(e_v)
    # degeneracy diagnostics (Fisher follow-up 2)
    modal <- max(table(signif(e_v, 6))); n_distinct <- length(unique(signif(e_v, 6)))
    # bootstrap MCSE of R (Fisher follow-up 4) - no Gaussian assumption
    set.seed(1); B <- 2000
    Rb <- replicate(B, { i <- sample(length(e_v), replace=TRUE); mean(s_v[i])/sd(e_v[i]) })
    out[[length(out)+1L]] <- data.frame(cell=cl, q=g$q[1], eta_d=g$eta_d[1], G=g$G[1],
      engine=e, n_paired=nrow(g), R_sd=mean(s_v)/sd_b, R_mad=mean(s_v)/mad(e_v),
      mcse_boot=sd(Rb), modal_frac=modal/length(e_v), n_distinct=n_distinct,
      degenerate = modal/length(e_v) > 0.20 || n_distinct < 0.5*length(e_v))
  }
}
R <- do.call(rbind, out); D <- do.call(rbind, drops)
write.table(R, "R_summary_paired.tsv", sep="\t", row.names=FALSE, quote=FALSE)
write.table(D, "retention_report.tsv", sep="\t", row.names=FALSE, quote=FALSE)

cat("=== RETENTION / DROP REPORT (prereg sec 8 rule 5: nothing silent) ===\n")
cat(sprintf("%-5s %-8s %7s %7s %11s %8s %8s\n","cell","engine","n","ok","se_finite","usable","paired"))
for (i in seq_len(nrow(D))) with(D[i,], if (n_usable < n_total)
  cat(sprintf("%-5d %-8s %7d %7d %11d %8d %8d\n",cell,engine,n_total,n_ok,n_se_finite,n_usable,n_paired)))
cat("\n(rows shown only where something was dropped)\n")

cat("\n=== PAIRED R, MSPL, with degeneracy flags ===\n")
m <- R[R$engine=="mspl",]
cat(sprintf("%-5s %-3s %6s %3s %7s %8s %8s %9s %10s %6s %s\n",
    "cell","q","eta_d","G","paired","R_sd","R_mad","mcse_bt","modal_frac","ndist","FLAG"))
for (i in seq_len(nrow(m))) with(m[i,], cat(sprintf("%-5d %-3s %6.0f %3d %7d %8.3f %8.3f %9.3f %10.3f %6d %s\n",
    cell,q,eta_d,G,n_paired,R_sd,R_mad,mcse_boot,modal_frac,n_distinct,
    if (degenerate) "DEGENERATE - R not interpretable" else "")))
cat("\nCells where R is interpretable (not degenerate):\n")
ok_cells <- m[!m$degenerate,]
for (i in seq_len(nrow(ok_cells))) with(ok_cells[i,],
  cat(sprintf("  cell %-3d eta_d=%-4.0f G=%-3d  R=%.3f (boot MCSE %.3f)\n", cell,eta_d,G,R_sd,mcse_boot)))
