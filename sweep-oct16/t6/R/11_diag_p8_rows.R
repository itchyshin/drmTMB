# t6: follow-up on P8 per-row diagnostics. Recomputes per-row z_i with the
# row's OWN sample SD (as in the harness) and with the MODEL variance V_i, to
# tell a sampling artefact of the studentised statistic (skewed counts) apart
# from a simulate() defect. Same seeds as the harness.
suppressPackageStartupMessages(library(drmTMB))
source("/home/user/drmTMB/sweep-oct16/t6/R/lib_t6.R")
cells <- utils::read.csv(file.path(T6_DATA, "cells.csv"), stringsAsFactors = FALSE,
  colClasses = c(seed = "character", seed_r = "character"))
keys <- commandArgs(TRUE)
if (!length(keys)) keys <- c("nbinom2_fixed", "binomial_fixed", "truncated_nbinom2_fixed", "lognormal_fixed", "truncated_nbinom2_ri")
for (key in keys) {
  cr <- cells[paste(cells$family, cells$re, sep = "_") == key, ]
  fam <- cr$family; re <- cr$re
  d <- t6_read_cell(cr$file, fam)
  fit <- drmTMB(t6_formula(fam, re)$bf, family = t6_family_object(fam), data = d)
  dps <- names(fit$coefficients)
  bh <- if (re == "ri") t6_bhat_rows(fit, d) else 0
  eta <- lapply(setNames(dps, dps), function(dp) t6_eta(fit, fam, dp, d))
  resp <- lapply(setNames(dps, dps), function(dp) t6_invlink(T6_LINKS[[fam]][[dp]], eta[[dp]]))
  par <- c(resp[setdiff(dps, "mu")], list(trials = if (fam %in% c("binomial", "beta_binomial")) d$successes + d$failures))
  mods <- list(default = list(re.form = NA), cond = list(re.form = NULL))
  if (re == "fixed") mods <- mods[1]
  for (mn in names(mods)) {
    if (mn == "default") {
      sims <- simulate(fit, nsim = 1000, seed = as.numeric(cr$seed_r) + 100)
      mom <- if (re == "ri") t6_marg_moments(fam, eta$mu, par, fit$sdpars$mu[[1]]) else t6_cond_moments(fam, eta$mu, par)
    } else {
      sims <- suppressMessages(simulate(fit, nsim = 1000, seed = as.numeric(cr$seed_r) + 100, re.form = NULL))
      mom <- t6_cond_moments(fam, eta$mu + bh, par)
    }
    Y <- as.matrix(sims)
    ybar <- rowMeans(Y); sdi <- apply(Y, 1, sd)
    z_own <- (ybar - mom$E) / (sdi / sqrt(1000))
    z_mod <- (ybar - mom$E) / sqrt(mom$V / 1000)
    vr <- sdi^2 / mom$V
    cat(sprintf("%s [%s]: own-SD z: n>3=%d max=%.2f | model-V z: n>3=%d max=%.2f mean=%.3f sd=%.3f | KS p (model z ~ N(0,1)) = %.3f | mean(s2/V)=%.4f\n",
      key, mn, sum(abs(z_own) > 3), max(abs(z_own)), sum(abs(z_mod) > 3), max(abs(z_mod)),
      mean(z_mod), sd(z_mod), suppressWarnings(ks.test(z_mod, "pnorm")$p.value), mean(vr)))
    bad <- which(abs(z_own) > 3 | abs(z_mod) > 3)
    if (length(bad)) print(data.frame(row = bad, x = d$x[bad], f = d$f[bad], E = round(mom$E[bad], 4),
      V = round(mom$V[bad], 4), ybar = round(ybar[bad], 4), s2 = round(sdi[bad]^2, 4),
      z_own = round(z_own[bad], 2), z_model = round(z_mod[bad], 2),
      skew = if (fam %in% c("nbinom2", "truncated_nbinom2")) round((2 * mom$E[bad] * resp$sigma[bad]^2 + 1) / sqrt(mom$V[bad]), 2) else NA))
  }
}
