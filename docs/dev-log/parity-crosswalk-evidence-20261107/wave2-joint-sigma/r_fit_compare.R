# R side: native drmTMB (installed 0.8.1 from origin/main) on the Julia-written
# data, then the comparison table. Rscript r_fit_compare.R
SP <- "/private/tmp/claude-503/-Users-z3437171--claude-spares-spare-t7eZxY/4c45dda1-dd05-4a24-a138-9970e0359a32/scratchpad"
.libPaths(c(file.path(SP, "agree-poisson-q2/lib"), .libPaths())); suppressMessages(library(drmTMB))
O <- if (length(commandArgs(TRUE))) commandArgs(TRUE)[1] else getwd()
cases <- list(nb2_crossed = c("nb2", FALSE), nb2_same = c("nb2", TRUE), gamma_crossed = c("gamma", FALSE),
              gamma_same = c("gamma", TRUE), gaussian_same = c("gaussian", TRUE))
rows <- list()
for (nm in names(cases)) {
  fam <- cases[[nm]][1]; same <- as.logical(cases[[nm]][2])
  d <- read.csv(file.path(O, paste0("data_", nm, ".csv"))); d$id <- factor(d$id); d$g <- factor(d$g)
  fm <- if (same) bf(y ~ x + (1 | id), sigma ~ 1 + (1 | id), sd(id) ~ w, sd(id, dpar = "sigma") ~ z) else
                  bf(y ~ x + (1 | id), sigma ~ 1 + (1 | g), sd(id) ~ w, sd(g, dpar = "sigma") ~ z)
  family <- switch(fam, nb2 = nbinom2(), gamma = Gamma(link = "log"), gaussian = gaussian())
  fit <- drmTMB(fm, family = family, data = d)
  est <- fit$opt$par; se <- sqrt(diag(fit$sdr$cov.fixed))
  j <- read.csv(file.path(O, paste0("jcoef_", nm, ".csv")))
  jll <- as.numeric(readLines(file.path(O, paste0("jll_", nm, ".txt")), warn = FALSE))
  stopifnot(length(est) == nrow(j))
  rll <- as.numeric(logLik(fit))
  rows[[nm]] <- data.frame(case = nm, n_par = length(est), r_conv = fit$opt$convergence,
    max_abs_diff = max(abs(est - j$est)), max_diff_in_se = max(abs(est - j$est) / se),
    max_se_rel_diff = max(abs(se - j$se) / se), r_loglik = sprintf("%.10f", rll),
    j_loglik = sprintf("%.10f", jll), loglik_diff = signif(jll - rll, 3))
  cat(sprintf("%s: par %s\n", nm, paste(names(est), collapse = " ")))
}
tab <- do.call(rbind, rows); print(tab, row.names = FALSE)
write.csv(tab, file.path(O, "comparison.csv"), row.names = FALSE)
cat("drmTMB", as.character(packageVersion("drmTMB")), "\n")
