.libPaths(c("~/drm_campaign_20261108/Rlib", .libPaths()))
Sys.setenv(OMP_NUM_THREADS = 1, OPENBLAS_NUM_THREADS = 1)
suppressPackageStartupMessages({library(drmTMB); library(ape)})
tree <- read.tree("tree.nwk")
rows <- list(); summ <- list()
for (seed in 1:10) {
  d <- read.csv(sprintf("data_seed%d.csv", seed)); d$g <- factor(d$id, levels = tree$tip.label)
  t0 <- Sys.time()
  res <- try({
    fml <- bf(y ~ x + phylo(1 + x | p | g, tree = tree),
      sd(g, level = "phylogenetic", dpar = "mu", coef = "(Intercept)") ~ z0,
      sd(g, level = "phylogenetic", dpar = "mu", coef = "x") ~ z1)
    fit <- drmTMB(fml, family = binomial(), data = d)
    s <- summary(fit$sdr, "fixed")      # TMB fixed-effect table (estimate, se)
    par <- fit$opt$par
    list(fit = fit, s = s)
  }, silent = TRUE)
  el <- as.numeric(difftime(Sys.time(), t0, units = "secs"))
  if (inherits(res, "try-error")) { summ[[seed]] <- data.frame(seed, conv = NA, ll = NA, secs = el, err = as.character(res)); next }
  fit <- res$fit; s <- res$s
  nm <- names(fit$opt$par)
  rho <- unname(fit$corpars$phylo[[1]])
  summ[[seed]] <- data.frame(seed, conv = fit$opt$convergence, ll = as.numeric(logLik(fit)), secs = el, rho = rho,
                             maxgrad = fit$gradient_max_component, err = "")
  rows[[seed]] <- data.frame(seed, idx = seq_along(nm), par = nm, est = unname(fit$opt$par),
                             se = s[, "Std. Error"])
}
write.csv(do.call(rbind, summ), "R_summary.csv", row.names = FALSE)
write.csv(do.call(rbind, rows), "R_pars.csv", row.names = FALSE)
cat("done\n")
