# Build the Markdown tables quoted in RECEIPT_t2.md from the summary CSVs, so
# no receipt number is transcribed by hand.
#
# Usage: Rscript t2_receipt_tables.R   (run from sweep-oct16/t2)
# Writes summary/t2_receipt_tables.md.

p <- utils::read.csv("summary/t2_summary.csv", stringsAsFactors = FALSE)
cmp <- utils::read.csv("summary/t2_confirm_compare.csv", stringsAsFactors = FALSE)
conv <- utils::read.csv("summary/t2_convergence.csv", stringsAsFactors = FALSE)
pa <- utils::read.csv("summary/t2_paired.csv", stringsAsFactors = FALSE)
pac <- utils::read.csv("summary_confirm/t2_paired.csv", stringsAsFactors = FALSE)
pt <- utils::read.csv("summary/t2_posthoc_t_drmTMB.csv", stringsAsFactors = FALSE)

pc <- function(x, d = 1) ifelse(is.na(x), "-", sprintf(paste0("%.", d, "f%%"), 100 * x))
sg <- function(x, d = 2) sprintf(paste0("%+.", d, "f%%"), 100 * x)
pord <- c("mu_intercept", "mu_x", "sigma_intercept", "sigma_z", "sd_g")
md <- character()

# 1. Gate cells (n >= 200): engines are identical, so one row per cell x parameter.
g <- cmp[cmp$engine == "drmTMB", ]
g$cell_order <- match(g$cell, c("n0200_none", "n1000_none", "n0200_G20", "n1000_G20",
                                "n0200_G50", "n1000_G50"))
g <- g[order(g$cell_order, match(g$param, pord)), ]
gp <- p[p$engine == "drmTMB" & p$n >= 200, c("cell", "param", "rel_bias_mcse", "coverage_mcse", "se_ratio")]
g <- merge(g, gp, by = c("cell", "param"), sort = FALSE)
g <- g[order(g$cell_order, match(g$param, pord)), ]
v <- function(pass) ifelse(pass == "PASS", "PASS", "**FAIL**")
md <- c(md, "<!-- table:gate -->",
  "| cell | parameter | rel. bias, reps 1-500 (MCSE) | bias verdict | coverage, reps 1-500 (MCSE) | coverage verdict | SE/SD | pooled 2,500: rel. bias | pooled 2,500: coverage (MCSE) | pooled verdict |",
  "|---|---|---:|:---:|---:|:---:|---:|---:|---:|:---:|")
for (i in seq_len(nrow(g))) {
  r <- g[i, ]
  pooled <- if (r$pooled_bias == "PASS" && r$pooled_cov == "PASS") "PASS" else
    paste0("**FAIL** (", paste(c(if (r$pooled_bias != "PASS") "bias", if (r$pooled_cov != "PASS") "coverage"), collapse = ", "), ")")
  md <- c(md, sprintf("| %s | %s | %s (%.2f) | %s | %s (%.1f) | %s | %.3f | %s | %s (%.2f) | %s |",
    r$cell, r$param, sg(r$rel_bias.p), 100 * r$rel_bias_mcse, v(r$primary_bias),
    pc(r$coverage.p), 100 * r$coverage_mcse, v(r$primary_cov), r$se_ratio,
    sg(r$rel_bias.pool), pc(r$coverage.pool, 2), 100 * r$coverage_mcse.pool, pooled))
}

# 2. n = 50 cells, both engines (report only).
s50 <- p[p$n == 50, ]
s50$cell_order <- match(s50$cell, c("n0050_none", "n0050_G20", "n0050_G50"))
s50 <- s50[order(s50$cell_order, match(s50$param, pord), s50$engine), ]
md <- c(md, "", "<!-- table:n50 -->",
  "| cell | parameter | engine | converged fits | rel. bias (MCSE) | median rel. bias | coverage (MCSE) |",
  "|---|---|---|---:|---:|---:|---:|")
for (i in seq_len(nrow(s50))) {
  r <- s50[i, ]
  md <- c(md, sprintf("| %s | %s | %s | %d | %s (%.2f) | %s | %s (%.1f) |", r$cell, r$param,
    r$engine, r$n_conv, sg(r$rel_bias), 100 * r$rel_bias_mcse, sg(r$median_rel_bias),
    pc(r$coverage), 100 * r$coverage_mcse))
}

# 3. Convergence (primary run, both engines).
conv$cell_order <- match(conv$cell, c("n0050_none", "n0200_none", "n1000_none", "n0050_G20",
  "n0200_G20", "n1000_G20", "n0050_G50", "n0200_G50", "n1000_G50"))
cw <- reshape(conv[, c("cell", "cell_order", "engine", "converged", "reps_run", "statuses", "median_time_s")],
              idvar = c("cell", "cell_order"), timevar = "engine", direction = "wide")
cw <- cw[order(cw$cell_order), ]
md <- c(md, "", "<!-- table:conv -->",
  "| cell | drmTMB converged | drmTMB status counts | DRModels.jl converged | DRModels.jl status counts | median fit time, s (drmTMB / DRModels.jl) |",
  "|---|---:|---|---:|---|---|")
fl <- function(k, n) sprintf("%d / %d (%s)%s", k, n, pc(k / n), if (k / n < 0.99) " **FAIL**" else "")
for (i in seq_len(nrow(cw))) {
  r <- cw[i, ]
  md <- c(md, sprintf("| %s | %s | %s | %s | %s | %.3f / %.4f |", r$cell,
    fl(r$converged.drmTMB, r$reps_run.drmTMB), r$statuses.drmTMB,
    fl(r$converged.DRModels, r$reps_run.DRModels), r$statuses.DRModels,
    r$median_time_s.drmTMB, r$median_time_s.DRModels))
}

# 4. Paired agreement, primary + confirmatory.
pall <- rbind(transform(pa, run = "1-500"), transform(pac, run = "501-2500"))
md <- c(md, "", "<!-- table:paired -->",
  "| reps | cell | both converged | excluded (sd(g) < 1e-4) | max abs dlogLik | max abs d(link estimate) | SE ratio range |",
  "|---|---|---:|---:|---:|---:|---|")
for (i in seq_len(nrow(pall))) {
  r <- pall[i, ]
  md <- c(md, sprintf("| %s | %s | %d | %d | %.1e | %.1e | %.6f - %.6f |", r$run, r$cell,
    r$both_converged, r$sd_boundary_reps, r$max_abs_dloglik, r$max_abs_dest_link,
    r$se_ratio_min, r$se_ratio_max))
}

# 5. Post-hoc t(G-1).
md <- c(md, "", "<!-- table:posthoc -->",
  "| cell | target | reps | z interval (reported) | t(G-1) | t(G-1) + log(G/(G-1)) centre shift |",
  "|---|---|---:|---:|---:|---:|",
  sprintf("| %s | %s | %d | %s | %s | %s |", pt$cell, pt$param, pt$reps, pc(pt$z, 2),
          pc(pt$t_Gm1, 2), pc(pt$t_Gm1_shift, 2)))
writeLines(md, "summary/t2_receipt_tables.md")
message("wrote summary/t2_receipt_tables.md")
