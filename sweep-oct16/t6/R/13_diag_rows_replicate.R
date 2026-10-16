# t6: do the rows flagged by the P8 per-row diagnostic stay flagged at other
# seeds (row-specific defect) or not (chance)? Generic over cells; default
# (re.form = NA) mode for fixed cells. Args: cell key, rows...
suppressPackageStartupMessages(library(drmTMB))
source("/home/user/drmTMB/sweep-oct16/t6/R/lib_t6.R")
a <- commandArgs(TRUE); key <- a[1]; rows <- as.integer(a[-1])
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
print(cbind(d[rows, ], E = mom$E[rows], V = mom$V[rows]))
base <- as.numeric(cr$seed_r) + 100
for (k in 0:5) {
  Y <- as.matrix(simulate(fit, nsim = 1000, seed = base + k))
  z <- (rowMeans(Y) - mom$E) / sqrt(mom$V / 1000)
  cat(sprintf("seed+%d: z at rows %s = %s | all-row n|z|>3 = %d\n", k, paste(rows, collapse = ","),
    paste(sprintf("%.2f", z[rows]), collapse = ", "), sum(abs(z) > 3)))
}
