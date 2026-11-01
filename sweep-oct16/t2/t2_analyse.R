# Summarise t2 fits against the pass bar and compare the two engines per dataset.
#
# Usage: Rscript t2_analyse.R <resultsdir> <outdir>
# Reads every drmTMB_*.csv / DRModels_*.csv under <resultsdir>, writes
#   <outdir>/t2_fits_long.csv.gz   all per-rep, per-parameter rows (both engines)
#   <outdir>/t2_summary.csv        one row per engine x cell x parameter
#   <outdir>/t2_convergence.csv    one row per engine x cell
#   <outdir>/t2_paired.csv         per-cell cross-engine agreement on shared data
#   <outdir>/t2_tables.md          the Markdown tables quoted in the receipt

args <- commandArgs(trailingOnly = TRUE)
resdir <- args[[1]]
outdir <- args[[2]]
dir.create(outdir, recursive = TRUE, showWarnings = FALSE)

files <- list.files(resdir, pattern = "^(drmTMB|DRModels)_n.*\\.csv$", full.names = TRUE)
read_one <- function(f) {
  d <- utils::read.csv(f, stringsAsFactors = FALSE, na.strings = c("NA", "", "NaN"))
  d$converged <- as.logical(d$converged)
  d
}
cols <- c("engine", "cell", "n", "re", "G", "rep", "time_s", "param", "true", "est",
          "est_link", "se_link", "lower", "upper", "conf_status", "converged",
          "conv_status", "loglik", "warnings")
fits <- do.call(rbind, lapply(files, function(f) read_one(f)[, cols]))
fits$cell_order <- match(fits$cell, c(
  "n0050_none", "n0200_none", "n1000_none",
  "n0050_G20", "n0200_G20", "n1000_G20",
  "n0050_G50", "n0200_G50", "n1000_G50"))
fits <- fits[order(fits$engine, fits$cell_order, fits$rep, fits$param), ]
gz <- gzfile(file.path(outdir, "t2_fits_long.csv.gz"), "w")
utils::write.csv(fits, gz, row.names = FALSE)
close(gz)

# ---- convergence: one row per engine x cell x rep ------------------------------
per_rep <- unique(fits[, c("engine", "cell", "cell_order", "n", "re", "G", "rep",
                           "converged", "conv_status", "loglik", "time_s")])
stopifnot(!anyDuplicated(per_rep[, c("engine", "cell", "rep")]))
conv <- do.call(rbind, lapply(split(per_rep, list(per_rep$engine, per_rep$cell), drop = TRUE),
  function(d) {
    data.frame(engine = d$engine[1], cell = d$cell[1], cell_order = d$cell_order[1],
               n = d$n[1], re = d$re[1], reps_run = nrow(d),
               errors = sum(d$conv_status == "error", na.rm = TRUE),
               converged = sum(d$converged %in% TRUE),
               conv_rate = sum(d$converged %in% TRUE) / nrow(d),
               statuses = paste(names(table(d$conv_status)), table(d$conv_status),
                                sep = ":", collapse = " "),
               median_time_s = stats::median(d$time_s),
               stringsAsFactors = FALSE)
  }))
conv <- conv[order(conv$engine, conv$cell_order), ]
conv$pass_conv <- conv$conv_rate >= 0.99
utils::write.csv(conv, file.path(outdir, "t2_convergence.csv"), row.names = FALSE)

# ---- bias and coverage over converged fits -------------------------------------
ok <- fits[fits$converged %in% TRUE & !is.na(fits$param), ]
summ <- do.call(rbind, lapply(split(ok, list(ok$engine, ok$cell, ok$param), drop = TRUE),
  function(d) {
    th <- d$true[1]
    m <- nrow(d)
    covered <- d$lower <= th & th <= d$upper
    n_ci <- sum(!is.na(covered))
    cov_rate <- mean(covered, na.rm = TRUE)
    data.frame(
      engine = d$engine[1], cell = d$cell[1], cell_order = d$cell_order[1],
      n = d$n[1], re = d$re[1], param = d$param[1], true = th, n_conv = m,
      mean_est = mean(d$est), rel_bias = (mean(d$est) - th) / th,
      rel_bias_mcse = stats::sd(d$est) / sqrt(m) / abs(th),
      median_rel_bias = (stats::median(d$est) - th) / th,
      emp_sd_link = stats::sd(d$est_link),
      mean_se_link = mean(d$se_link[is.finite(d$se_link)]),
      se_ratio = mean(d$se_link[is.finite(d$se_link)]) / stats::sd(d$est_link),
      n_ci = n_ci, ci_unavailable = m - n_ci,
      coverage = cov_rate,
      coverage_mcse = sqrt(cov_rate * (1 - cov_rate) / n_ci),
      miss_low = mean(th < d$lower, na.rm = TRUE), # truth below interval
      miss_high = mean(th > d$upper, na.rm = TRUE), # truth above interval
      conf_status = paste(names(table(d$conf_status)), table(d$conf_status),
                          sep = ":", collapse = " "),
      stringsAsFactors = FALSE)
  }))
param_order <- c("mu_intercept", "mu_x", "sigma_intercept", "sigma_z", "sd_g")
summ <- summ[order(summ$engine, summ$cell_order, match(summ$param, param_order)), ]
summ$gate <- summ$n >= 200
summ$pass_bias <- abs(summ$rel_bias) < 0.05
summ$pass_cov <- summ$coverage >= 0.93 & summ$coverage <= 0.97
utils::write.csv(summ, file.path(outdir, "t2_summary.csv"), row.names = FALSE)

# ---- paired cross-engine agreement on identical datasets -----------------------
w <- reshape(per_rep[, c("engine", "cell", "rep", "converged", "loglik")],
             idvar = c("cell", "rep"), timevar = "engine", direction = "wide")
pe <- reshape(fits[!is.na(fits$param), c("engine", "cell", "rep", "param", "est_link", "se_link")],
              idvar = c("cell", "rep", "param"), timevar = "engine", direction = "wide")
both <- w[w$converged.drmTMB %in% TRUE & w$converged.DRModels %in% TRUE, ]
# A rep whose sd(g) estimate sits on the zero boundary (either engine below
# 1e-4) has a flat log-sd direction: the engines stop at different points on
# that ridge with the same logLik, so those reps are counted, not compared.
sdg <- fits[fits$param %in% "sd_g", c("engine", "cell", "rep", "est")]
bnd <- unique(sdg[sdg$est < 1e-4, c("cell", "rep")])
bnd$boundary <- rep(TRUE, nrow(bnd))
pe <- merge(pe, both[, c("cell", "rep")], by = c("cell", "rep"))
pe <- merge(pe, bnd, by = c("cell", "rep"), all.x = TRUE)
pe$boundary[is.na(pe$boundary)] <- FALSE
pe_all <- pe
pe <- pe[!pe$boundary, ]
paired <- do.call(rbind, lapply(split(both, both$cell), function(d) {
  p <- pe[pe$cell == d$cell[1], ]
  n_bnd <- length(unique(pe_all$rep[pe_all$cell == d$cell[1] & pe_all$boundary]))
  dl <- d$loglik.DRModels - d$loglik.drmTMB
  sr <- p$se_link.DRModels / p$se_link.drmTMB
  data.frame(
    cell = d$cell[1], both_converged = nrow(d), sd_boundary_reps = n_bnd,
    only_drmTMB = sum(w$cell == d$cell[1] & w$converged.drmTMB %in% TRUE & !(w$converged.DRModels %in% TRUE)),
    only_DRModels = sum(w$cell == d$cell[1] & !(w$converged.drmTMB %in% TRUE) & w$converged.DRModels %in% TRUE),
    max_abs_dloglik = max(abs(dl)),
    n_dloglik_gt_1e4 = sum(abs(dl) > 1e-4),
    n_DRModels_higher_1e4 = sum(dl > 1e-4),
    n_drmTMB_higher_1e4 = sum(dl < -1e-4),
    max_abs_dest_link = max(abs(p$est_link.DRModels - p$est_link.drmTMB)),
    n_dest_gt_1e3 = sum(abs(p$est_link.DRModels - p$est_link.drmTMB) > 1e-3),
    se_ratio_min = min(sr, na.rm = TRUE), se_ratio_max = max(sr, na.rm = TRUE),
    n_se_rel_gt_1e2 = sum(abs(sr - 1) > 1e-2, na.rm = TRUE),
    stringsAsFactors = FALSE)
}))
paired <- paired[order(match(paired$cell, unique(fits$cell[order(fits$cell_order)]))), ]
utils::write.csv(paired, file.path(outdir, "t2_paired.csv"), row.names = FALSE)

# ---- Markdown tables -----------------------------------------------------------
pct <- function(x, d = 1) ifelse(is.na(x), "NA", sprintf(paste0("%.", d, "f%%"), 100 * x))
md <- character()
md <- c(md, "### Convergence (pass bar: converged rate >= 99%)", "",
        "| engine | cell | converged / reps | rate | errors | status counts | median fit s | pass |",
        "|---|---|---:|---:|---:|---|---:|:---:|")
for (i in seq_len(nrow(conv))) {
  r <- conv[i, ]
  md <- c(md, sprintf("| %s | %s | %d / %d | %s | %d | %s | %.3f | %s |", r$engine, r$cell,
                      r$converged, r$reps_run, pct(r$conv_rate), r$errors, r$statuses,
                      r$median_time_s, if (r$pass_conv) "PASS" else "**FAIL**"))
}
md <- c(md, "", "### Bias and Wald coverage (converged fits)", "",
        "Relative bias is (mean estimate - truth) / truth, with its Monte Carlo SE.",
        "Coverage is the share of nominal 95% Wald intervals containing the truth,",
        "with its binomial Monte Carlo SE. Gate cells (n >= 200) are marked PASS/FAIL;",
        "n = 50 cells are reported only.", "",
        "| engine | cell | parameter | n_conv | rel. bias (MCSE) | median rel. bias | SE/SD | coverage (MCSE) | below / above | bias | coverage |",
        "|---|---|---|---:|---:|---:|---:|---:|---:|:---:|:---:|")
for (i in seq_len(nrow(summ))) {
  r <- summ[i, ]
  fb <- if (!r$gate) "report" else if (r$pass_bias) "PASS" else "**FAIL**"
  fc <- if (!r$gate) "report" else if (isTRUE(r$pass_cov)) "PASS" else "**FAIL**"
  md <- c(md, sprintf("| %s | %s | %s | %d | %+.2f%% (%.2f) | %+.2f%% | %.3f | %s (%.1f) | %s / %s | %s | %s |",
                      r$engine, r$cell, r$param, r$n_conv, 100 * r$rel_bias,
                      100 * r$rel_bias_mcse, 100 * r$median_rel_bias, r$se_ratio,
                      pct(r$coverage), 100 * r$coverage_mcse, pct(r$miss_low),
                      pct(r$miss_high), fb, fc))
}
md <- c(md, "", "### Cross-engine agreement on identical datasets", "",
        "Estimates and SEs are compared on reps where both engines converged, excluding",
        "reps where either engine puts sd(g) below 1e-4 (a flat log-sd direction; counted, not compared).", "",
        "| cell | both converged | of which sd(g) < 1e-4 (excluded) | only drmTMB | only DRModels | max abs dlogLik | reps with abs dlogLik > 1e-4 (DRModels higher / drmTMB higher) | max abs d(link est) | SE ratio range |",
        "|---|---:|---:|---:|---:|---:|---|---:|---|")
for (i in seq_len(nrow(paired))) {
  r <- paired[i, ]
  md <- c(md, sprintf("| %s | %d | %d | %d | %d | %.2e | %d (%d / %d) | %.2e | %.4f - %.4f |",
                      r$cell, r$both_converged, r$sd_boundary_reps, r$only_drmTMB, r$only_DRModels,
                      r$max_abs_dloglik, r$n_dloglik_gt_1e4, r$n_DRModels_higher_1e4,
                      r$n_drmTMB_higher_1e4, r$max_abs_dest_link, r$se_ratio_min,
                      r$se_ratio_max))
}
writeLines(md, file.path(outdir, "t2_tables.md"))
message("wrote ", outdir)
