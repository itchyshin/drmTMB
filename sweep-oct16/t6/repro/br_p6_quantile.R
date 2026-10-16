# SPEC P6 on bridge fits: predict(type = "quantile", prob = c(0.025, 0.5, 0.975)) from engine = "julia"
# versus engine = "tmb", in-sample and on nd_main, for the 14 *_fixed cells.
# drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a + DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7; R 4.3.3, Julia 1.12.7
# Data: sweep-oct16/t6/data/<family>_fixed.csv + nd_main.csv (seeds in data/cells.csv), committed at
#   https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
Sys.setenv(JULIA_DEPOT_PATH = "/opt/julia-depot", DRMODELS_JL_PATH = "/home/user/DRModels.jl",
           NOT_CRAN = "true", JULIA_HOME = "/opt/julia-env/bin")
library(drmTMB)
if (!exists("%||%", baseenv())) assign("%||%", function(x, y) if (is.null(x)) y else x, envir = globalenv())  # #1550 (R < 4.4)
D <- "/home/user/drmTMB/sweep-oct16/t6/data"
nd <- read.csv(file.path(D, "nd_main.csv"))
cells <- read.csv(file.path(D, "cells.csv"), colClasses = c(seed = "character"))
cells <- cells[cells$re == "fixed", ]
spec <- list(
  gaussian = list(gaussian(), bf(y ~ x + f, sigma ~ x)),
  student = list(student(), bf(y ~ x + f, sigma ~ x, nu ~ 1)),
  skew_normal = list(skew_normal(), bf(y ~ x + f, sigma ~ x, nu ~ 1)),
  lognormal = list(lognormal(), bf(y ~ x + f, sigma ~ x)),
  gamma = list(Gamma(link = "log"), bf(y ~ x + f, sigma ~ x)),
  beta = list(beta_family(), bf(y ~ x + f, sigma ~ x)),
  zero_one_beta = list(zero_one_beta(), bf(y ~ x + f, sigma ~ x, zoi ~ 1, coi ~ 1)),
  beta_binomial = list(beta_binomial(), bf(cbind(successes, failures) ~ x + f, sigma ~ x)),
  binomial = list(binomial(), bf(cbind(successes, failures) ~ x + f)),
  poisson = list(poisson(), bf(y ~ x + f)),
  nbinom2 = list(nbinom2(), bf(y ~ x + f, sigma ~ x)),
  truncated_nbinom2 = list(truncated_nbinom2(), bf(y ~ x + f, sigma ~ x)),
  tweedie = list(tweedie(), bf(y ~ x + f, sigma ~ x, nu ~ 1)),
  cumulative_logit = list(cumulative_logit(), bf(y ~ x + f)))
P <- c(0.025, 0.5, 0.975)
qd <- function(a, b) if (inherits(a, "error") || inherits(b, "error")) NA_real_ else max(abs(unclass(a) - unclass(b)))
msg1 <- function(e) if (inherits(e, "error")) gsub("\\s+", " ", strsplit(conditionMessage(e), "\n")[[1]][1]) else ""
rows <- list()
for (i in seq_len(nrow(cells))) {
  fam <- cells$family[i]; s <- spec[[fam]]
  d <- read.csv(file.path(D, cells$file[i]))
  if (fam == "cumulative_logit") d$y <- ordered(d$y)
  fj <- tryCatch(drmTMB(s[[2]], family = s[[1]], data = d, engine = "julia"), error = function(e) e)
  ft <- drmTMB(s[[2]], family = s[[1]], data = d)
  if (inherits(fj, "error")) { rows[[fam]] <- data.frame(cell = cells$file[i], seed = cells$seed[i],
    coef = NA, q_in = NA, q_nd = NA, note = paste("fit refused:", msg1(fj))); next }
  cj <- unlist(coef(fj)); ct <- unlist(coef(ft))
  # largest in-sample response-scale gap over the fit's own dpars, for context
  par_gap <- max(vapply(names(coef(ft)), function(dp) {
    a <- tryCatch(predict(fj, dpar = dp), error = function(e) NA); b <- predict(ft, dpar = dp)
    max(abs(a - b)) }, numeric(1)))
  qj_in <- tryCatch(predict(fj, type = "quantile", prob = P), error = function(e) e)
  qt_in <- tryCatch(predict(ft, type = "quantile", prob = P), error = function(e) e)
  qj_nd <- tryCatch(predict(fj, newdata = nd, type = "quantile", prob = P), error = function(e) e)
  qt_nd <- tryCatch(predict(ft, newdata = nd, type = "quantile", prob = P), error = function(e) e)
  note <- paste(c(if (inherits(qj_in, "error")) paste("julia in-sample:", msg1(qj_in)),
                  if (inherits(qt_in, "error")) paste("tmb in-sample:", msg1(qt_in)),
                  if (inherits(qj_nd, "error")) paste("julia nd_main:", msg1(qj_nd)),
                  if (inherits(qt_nd, "error")) paste("tmb nd_main:", msg1(qt_nd)),
                  if (!inherits(qj_in, "error") && !inherits(qt_in, "error") &&
                      !identical(dim(qj_in), dim(qt_in))) "dim mismatch in-sample",
                  if (!inherits(qj_in, "error") && !inherits(qt_in, "error") &&
                      !identical(attributes(qj_in)$calibrated, attributes(qt_in)$calibrated)) "calibrated attr differs"),
                collapse = "; ")
  rows[[fam]] <- data.frame(cell = sub(".csv", "", cells$file[i], fixed = TRUE), seed = cells$seed[i],
    coef = signif(max(abs(cj - ct[names(cj)])), 2), par = signif(par_gap, 2),
    q_in = signif(qd(qj_in, qt_in), 2), q_nd = signif(qd(qj_nd, qt_nd), 2), note = note)
  cat(sprintf("%-24s coef %.1e par %.1e q_in %.2e q_nd %.2e %s\n", fam, rows[[fam]]$coef, rows[[fam]]$par,
              rows[[fam]]$q_in, rows[[fam]]$q_nd, note)); flush.console()
}
tab <- do.call(rbind, rows); rownames(tab) <- NULL
print(tab, right = FALSE)
write.csv(tab, "/home/user/drmTMB/sweep-oct16/t6/results/bridge_p6_quantile_vs_tmb.csv", row.names = FALSE)
