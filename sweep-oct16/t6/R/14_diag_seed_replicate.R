# t6: generic multi-seed replication of the P8 global mean / batch-variance z
# for a FIXED cell (default simulate mode), to tell chance from a systematic
# bias when the lane-seed z is close to the |z| < 3 bar. Args: cell key.
suppressPackageStartupMessages(library(drmTMB))
source("/home/user/drmTMB/sweep-oct16/t6/R/lib_t6.R")
key <- commandArgs(TRUE)[1]
cells <- utils::read.csv(file.path(T6_DATA, "cells.csv"), stringsAsFactors = FALSE,
  colClasses = c(seed = "character", seed_r = "character"))
cr <- cells[paste(cells$family, cells$re, sep = "_") == key, ]
fam <- cr$family
d <- t6_read_cell(cr$file, fam)
fit <- drmTMB(t6_formula(fam, cr$re)$bf, family = t6_family_object(fam), data = d)
dps <- names(fit$coefficients)
resp <- lapply(setNames(dps, dps), function(dp) t6_invlink(T6_LINKS[[fam]][[dp]], t6_eta(fit, fam, dp, d)))
par <- c(resp[setdiff(dps, "mu")], list(trials = if (fam %in% c("binomial", "beta_binomial")) d$successes + d$failures))
mom <- t6_cond_moments(fam, t6_eta(fit, fam, "mu", d), par)
base <- as.numeric(cr$seed_r) + 100
zs <- t(sapply(0:9, function(k) {
  st <- t6_sim_stats(as.matrix(simulate(fit, nsim = 1000, seed = base + k)), mom$E, mom$V, d)
  c(seed_offset = k, z_mean = st$z_mean, z_var = st$z_var)
}))
print(round(zs, 2))
cat(sprintf("%s: mean z_mean over 10 seeds = %.2f (SE %.2f); mean z_var = %.2f (SE %.2f)\n", key,
  mean(zs[, 2]), sd(zs[, 2]) / sqrt(10), mean(zs[, 3]), sd(zs[, 3]) / sqrt(10)))
st <- t6_sim_stats(as.matrix(simulate(fit, nsim = 20000, seed = base + 99)), mom$E, mom$V, d, nbatch = 40L)
cat(sprintf("nsim = 20000: z_mean = %.2f, z_var = %.2f\n", st$z_mean, st$z_var))
