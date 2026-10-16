# Minimal repro: Poisson / Gamma(log) + (1 | g) under engine = "julia" fail
# after the Julia fit at DRModels' coef_labels echo ("resd").
# drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a, DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7.
`%||%` <- function(x, y) if (is.null(x)) y else x   # R < 4.4 only (drmTMB #1550)
library(drmTMB)
# Data: sweep-oct16/t5/data/{poisson,gamma}_y00_x00.csv (no missing values).
# Nominal seeds 20261016509 (poisson) and 20261016518 (gamma); generator R/gen_data.R.
for (fam in c("poisson", "gamma")) {
  d <- read.csv(sprintf("sweep-oct16/t5/data/%s_y00_x00.csv", fam))
  FO <- if (fam == "poisson") poisson(link = "log") else Gamma(link = "log")
  F <- if (fam == "poisson") bf(y ~ x + (1 | g)) else bf(y ~ x + (1 | g), sigma ~ 1)
  nat <- drmTMB(F, family = FO, data = d)
  cat(fam, "native logLik:", format(as.numeric(logLik(nat)), digits = 12), "\n")
  r <- tryCatch(drmTMB(F, family = FO, data = d, engine = "julia"),
                error = function(e) conditionMessage(e))
  cat(fam, "engine = 'julia':", if (is.character(r)) r else "fit returned", "\n")
}
