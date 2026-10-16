## F2: objective noise of the drmTMB beta_family() objective at phi ~ 1e4.
## Data: sweep-oct16/t4 cell beta_phi1e4 (k = 10), rep 15, nominal seed 20261017314
## (R seed 20261017314 %% 2^31 = 933664482); see t4_gen_data.R.
## Run from this directory:  Rscript f2_noise.R > f2_noise.out 2>&1            (installed drmTMB, pin ca3ddefa)
##                           Rscript f2_noise.R <lib> > f2_noise_pr1547.out 2>&1 (library holding the PR #1547 build)
args <- commandArgs(trailingOnly = TRUE); lib <- if (length(args)) args[1] else NULL
suppressPackageStartupMessages({ library(drmTMB, lib.loc = lib); library(Rmpfr) })
cat("drmTMB", as.character(packageVersion("drmTMB", lib.loc = lib)), "from", find.package("drmTMB"), " TMB", as.character(packageVersion("TMB")),
    " Rmpfr", as.character(packageVersion("Rmpfr")), "\n")
d <- read.csv("../../data/beta_phi1e4_r15.csv")
fit <- withCallingHandlers(drmTMB(bf(y ~ x, sigma ~ 1), family = beta_family(), data = d),
  warning = function(w) { cat("WARNING:", conditionMessage(w), "\n"); invokeRestart("muffleWarning") })
obj <- fit$obj
X <- cbind(1, d$x); y <- d$y
## exact nll with the drmTMB parameterisation (mu nudge 1e-12, phi = exp(-2 log_sigma)),
## evaluated in 256-bit MPFR from the same double inputs
nll_exact <- function(p, prec = 256) {
  eta <- mpfr(drop(X %*% p[1:2]), prec)          # X %*% beta in double, as TMB does
  mu_raw <- 1 / (1 + exp(-eta))
  mu <- mpfr(1e-12, prec) + (1 - 2 * mpfr(1e-12, prec)) * mu_raw
  phi <- exp(-2 * mpfr(p[3], prec))
  a <- mu * phi; b <- (1 - mu) * phi
  yy <- mpfr(y, prec)
  ll <- lgamma(a + b) - lgamma(a) - lgamma(b) + (a - 1) * log(yy) + (b - 1) * log(1 - yy)
  as.numeric(-sum(ll))
}
nll_dbeta <- function(p) {             # base R dbeta (double), same nudge
  eta <- drop(X %*% p[1:2]); mu <- 1e-12 + (1 - 2e-12) * plogis(eta); phi <- exp(-2 * p[3])
  -sum(dbeta(y, mu * phi, (1 - mu) * phi, log = TRUE))
}
p0 <- fit$opt$par
cat("\nAt the returned optimum:\n")
cat(sprintf("  obj$fn    = %.15f\n  exact     = %.15f\n  dbeta()   = %.15f\n",
            obj$fn(p0), nll_exact(p0), nll_dbeta(p0)))
cat(sprintf("  obj$fn - exact = %.3e ; dbeta - exact = %.3e\n",
            obj$fn(p0) - nll_exact(p0), nll_dbeta(p0) - nll_exact(p0)))

## 1. Error of obj$fn vs exact along a fine line through the optimum, per coordinate
set.seed(1)
cat("\n1. obj$fn - exact on 41-point lines p0 + t*e_j, |t| <= 1e-6 (absolute units)\n")
for (j in 1:3) {
  ts <- seq(-1e-6, 1e-6, length.out = 41)
  err <- sapply(ts, function(t) { p <- p0; p[j] <- p[j] + t; obj$fn(p) - nll_exact(p) })
  derr <- sapply(ts, function(t) { p <- p0; p[j] <- p[j] + t; nll_dbeta(p) - nll_exact(p) })
  cat(sprintf("  coord %d (%s): TMB err mean %.2e sd %.2e range [%.2e, %.2e] | dbeta err sd %.2e max|.| %.2e\n",
      j, names(p0)[j], mean(err), sd(err), min(err), max(err), sd(derr), max(abs(derr))))
}
## 2. Per-observation kernel error at the optimum
eta <- drop(X %*% p0[1:2]); mu <- 1e-12 + (1 - 2e-12) * plogis(eta); phi <- exp(-2 * p0[3])
a <- mu * phi; b <- (1 - mu) * phi
ll_tmb_form <- lgamma(a + b) - lgamma(a) - lgamma(b) + (a - 1) * log(y) + (b - 1) * log(1 - y)
prec <- 256; A <- mpfr(a, prec); B <- mpfr(b, prec); Y <- mpfr(y, prec)
ll_ex <- as.numeric(lgamma(A + B) - lgamma(A) - lgamma(B) + (A - 1) * log(Y) + (B - 1) * log(1 - Y))
cat(sprintf("\n2. per-observation error of the lgamma-difference form (double, R's lgamma) at phi = %.1f:\n", phi))
cat(sprintf("   max|err| %.2e, sd %.2e, sum %.2e; typical term size |lgamma(a+b)| = %.0f\n",
    max(abs(ll_tmb_form - ll_ex)), sd(ll_tmb_form - ll_ex), sum(ll_tmb_form - ll_ex), lgamma(phi)))

## 3. Noise relative to what nlminb needs: rel.tol * |f|
cat(sprintf("\n3. nlminb rel.tol * |f| = 1e-10 * %.1f = %.2e\n", abs(fit$opt$objective), 1e-10 * abs(fit$opt$objective)))
## 4. Jaggedness: second differences of obj$fn vs exact on a tiny grid along the gradient-of-log-sigma direction
hs <- 10^(-(4:9))
cat("\n4. central second difference f(p+h)-2f(p)+f(p-h) along beta_sigma, TMB vs exact (true value ~ H*h^2, H ~ 200)\n")
for (h in hs) {
  e3 <- c(0, 0, h)
  s_tmb <- obj$fn(p0 + e3) - 2 * obj$fn(p0) + obj$fn(p0 - e3)
  s_ex  <- nll_exact(p0 + e3) - 2 * nll_exact(p0) + nll_exact(p0 - e3)
  cat(sprintf("   h = %.0e : TMB %.3e  exact %.3e\n", h, s_tmb, s_ex))
}
cat("\nsessionInfo():\n"); print(sessionInfo())
