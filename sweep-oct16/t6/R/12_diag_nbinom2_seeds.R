# t6: is the nbinom2_fixed P8 tilt (global mean z = -2.02, mean per-row model
# z = -0.20, KS p = 0.014 at the lane seed) systematic or chance? Re-run
# simulate() at the lane seed + 1..6 with nsim = 1000 and once with nsim = 20000,
# and compare with base R rnbinom() at the same parameters as an independent
# reference sampler.
suppressPackageStartupMessages(library(drmTMB))
source("/home/user/drmTMB/sweep-oct16/t6/R/lib_t6.R")
key <- commandArgs(TRUE); if (!length(key)) key <- "nbinom2_fixed"
cells <- utils::read.csv(file.path(T6_DATA, "cells.csv"), stringsAsFactors = FALSE,
  colClasses = c(seed = "character", seed_r = "character"))
cr <- cells[paste(cells$family, cells$re, sep = "_") == key, ]
fam <- cr$family
d <- t6_read_cell(cr$file, fam)
fit <- drmTMB(t6_formula(fam, cr$re)$bf, family = t6_family_object(fam), data = d)
mu <- exp(t6_eta(fit, fam, "mu", d)); s <- exp(t6_eta(fit, fam, "sigma", d))
mom <- t6_cond_moments(fam, log(mu), list(sigma = s))
summ <- function(Y, lab) {
  G <- colMeans(Y); ns <- ncol(Y)
  zg <- (mean(G) - mean(mom$E)) / (sd(G) / sqrt(ns))
  zm <- (rowMeans(Y) - mom$E) / sqrt(mom$V / ns)
  cat(sprintf("%-28s nsim=%5d global z=%6.2f  mean(z_row)*sqrt(n)=%6.2f  sd(z_row)=%.3f  n|z_row|>3=%d\n",
    lab, ns, zg, mean(zm) * sqrt(length(zm)), sd(zm), sum(abs(zm) > 3)))
}
base <- as.numeric(cr$seed_r) + 100
for (k in 0:6) summ(as.matrix(simulate(fit, nsim = 1000, seed = base + k)), sprintf("drmTMB seed+%d", k))
summ(as.matrix(simulate(fit, nsim = 20000, seed = base + 7)), "drmTMB nsim=20000")
for (k in 0:3) { set.seed(base + 1000 + k); summ(replicate(1000, rnbinom(length(mu), size = 1 / s^2, mu = mu)), sprintf("base rnbinom seed %d", k)) }
