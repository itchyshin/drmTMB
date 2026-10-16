## F5-tiny-n-gaussian: is drmTMB's default fit the maximum of its own (soft-clamped) objective?
## drmTMB's default drm_control(logsigma_clamp = c(-12, 12), logsigma_clamp_margin = 3) replaces
## each log sigma_i < -12 by -12 - 3 tanh((-12 - log sigma_i) / 3) (src/drmTMB.cpp:27-33), so the
## fitted model is the Gaussian with that soft-clamped scale. This script maximises that clamped
## log-likelihood with a 300-start BFGS search written here (base R only) and compares the best
## value with drmTMB's reported logLik and with the unclamped maximum.
## Run from this folder:  Rscript f5_clamped_check.R > f5_clamped_check.out 2>&1
suppressPackageStartupMessages(library(drmTMB))
cat(R.version.string, "| drmTMB", as.character(packageVersion("drmTMB")), "\n")
ddir <- "../../data"
rd <- function(r) read.csv(file.path(ddir, sprintf("gauss_n8_r%02d.csv", r)))
soft <- function(ls, lo = -12, hi = 12, m = 3)
  ifelse(ls < lo, lo - m * tanh((lo - ls) / m), ifelse(ls > hi, hi + m * tanh((ls - hi) / m), ls))
nll_cl <- function(th, y, x) { ls <- soft(th[3] + th[4] * x)
  -sum(dnorm(y, th[1] + th[2] * x, exp(ls), log = TRUE)) }
A <- read.csv("f5_reference_maxima.csv")
set.seed(1)
for (r in c(4, 30, 31, 49, 6, 19)) {
  d <- rd(r); y <- d$y; x <- d$x
  f <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = d)
  b <- coef(lm(y ~ x)); best <- Inf
  for (s in 1:300) {
    st <- c(b + rnorm(2, 0, 0.5), log(sd(y)) + rnorm(1, 0, 3), rnorm(1, 0, 6))
    o <- try(optim(st, nll_cl, y = y, x = x, method = "BFGS", control = list(maxit = 2000, reltol = 1e-14)), silent = TRUE)
    if (!inherits(o, "try-error") && is.finite(o$value) && o$value < best) { best <- o$value; par <- o$par }
  }
  fin <- A$ll[A$rep == r & A$grid_edge == 0]
  cat(sprintf("r%02d drmTMB default logLik %.6f (converged %s) | clamped-objective max (300 starts) %.6f | unclamped finite max %s\n",
              r, as.numeric(logLik(f)), is_converged(f), -best,
              if (length(fin)) sprintf("%.6f", max(fin)) else "none (unbounded)"))
}
