# engine = "julia": fitted() returns DRModels.jl's fitted values, not drmTMB's documented fitted().
# drmTMB ca3ddefa5ea11bbfd3b765615dfbb89305d2485a + DRModels.jl f71b2923360e9e5d4591e0d6e15a9ef9db0356d7; R 4.3.3, Julia 1.12.7
# Data: sweep-oct16/t6/data/*.csv, committed at
#   https://github.com/itchyshin/drmTMB/tree/cd6d3da751bdec440996ca2168f68c4d31490ffa/sweep-oct16/t6/data
Sys.setenv(JULIA_DEPOT_PATH = "/opt/julia-depot", DRMODELS_JL_PATH = "/home/user/DRModels.jl",
           NOT_CRAN = "true", JULIA_HOME = "/opt/julia-env/bin")
library(drmTMB)
if (!exists("%||%", baseenv())) assign("%||%", function(x, y) if (is.null(x)) y else x, envir = globalenv())  # #1550 (R < 4.4)
D <- "/home/user/drmTMB/sweep-oct16/t6/data"
same_fit <- function(a, b) { ca <- unlist(coef(a)); cb <- unlist(coef(b))
  c(coef = max(abs(ca - cb[names(ca)])), logLik = as.numeric(logLik(a) - logLik(b))) }

## 1. lognormal (seed 20261016606): ?fitted.drmTMB documents exp(mu + sigma^2/2)
d <- read.csv(file.path(D, "lognormal_fixed.csv"))
f <- bf(y ~ x + f, sigma ~ x)
fj <- drmTMB(f, family = lognormal(), data = d, engine = "julia")
ft <- drmTMB(f, family = lognormal(), data = d)
same_fit(fj, ft)                                   # ~1e-11: the same fit
m <- predict(fj, dpar = "mu", type = "link"); s <- predict(fj, dpar = "sigma")
max(abs(fitted(fj) - exp(m)))                      # ~1e-15: bridge ships the median exp(mu)
max(abs(fitted(ft) - exp(m + s^2 / 2)))            # ~1e-9: native ships the documented mean
max(abs(fitted(fj) - fitted(ft)))                  # expected ~1e-9; observed 5.9
c(bridge = mean(fitted(fj)), tmb = mean(fitted(ft)), y = mean(d$y))

## 2. truncated_nbinom2 (seed 20261016622): documented mean mu / (1 - P_NB2(0))
d <- read.csv(file.path(D, "truncated_nbinom2_fixed.csv"))
fj <- drmTMB(f, family = truncated_nbinom2(), data = d, engine = "julia")
ft <- drmTMB(f, family = truncated_nbinom2(), data = d)
same_fit(fj, ft)                                   # ~1e-10
m <- predict(fj, dpar = "mu"); s <- predict(fj, dpar = "sigma")
max(abs(fitted(fj) - m))                           # ~1e-16: bridge ships the untruncated mu
max(abs(fitted(ft) - m / (1 - dnbinom(0, size = 1 / s^2, mu = m))))  # ~1e-10: native = documented mean
max(abs(fitted(fj) - fitted(ft)))                  # expected ~1e-9; observed 7.05
c(bridge = mean(fitted(fj)), tmb = mean(fitted(ft)), y = mean(d$y))

## 3. Gaussian (1 | g) (seed 20261016601): native fitted() includes the fitted modes
d <- read.csv(file.path(D, "gaussian_ri.csv"))
f <- bf(y ~ x + (1 | g), sigma ~ x)   # numeric-only: the factor version is refused (separate finding)
fj <- drmTMB(f, family = gaussian(), data = d, engine = "julia")
ft <- drmTMB(f, family = gaussian(), data = d)
same_fit(fj, ft)
max(abs(predict(fj, dpar = "mu") - fitted(ft)))                          # ~1e-11: bridge CAN give conditional mu
max(abs(fitted(fj) - drop(model.matrix(~ x, d) %*% coef(fj, "mu"))))     # ~1e-15: but fitted() is X beta
max(abs(fitted(fj) - fitted(ft)))                  # expected ~1e-9; observed 0.98
max(abs(residuals(fj) - residuals(ft)))            # same gap in residuals()
