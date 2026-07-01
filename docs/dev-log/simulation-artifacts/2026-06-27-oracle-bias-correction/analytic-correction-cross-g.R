#!/usr/bin/env Rscript
# Closed-form, truth-free analytic bias correction, validated across g.
#
# The oracle recompute (recompute.R) showed the g=8 mu-slope SD under-coverage is
# a CENTRE problem and a centre fix reaches nominal. The single-level parametric
# bootstrap could NOT estimate that centre (it measures bias at theta_hat, ~ -0.01,
# not at truth). This script tests a CLOSED-FORM correction that needs no truth and
# no refits: shift the log-scale SD point by +log(g/(g-1)) (i.e. sigma_corrected =
# sigma_ML * g/(g-1) -- the variance Bessel factor on the SD scale), then build the
# t(df=g-1) interval.
#
# Result: the measured mean log-shrinkage TRACKS log(g/(g-1)), and the correction
# holds nominal at every g, including the deployment default g=8:
#   g=8  : bias -0.129 ~ -0.134 ; analytic_bc+t = 0.955   (Wald-z 0.887)
#   g=16 : bias -0.081 ~ -0.065 ; analytic_bc+t = 0.949
#   g=32 : bias -0.029 ~ -0.032 ; analytic_bc+t = 0.963
# => a simulation-calibrated, closed-form bias correction (doctrine-endorsed) makes
#    coverage nominal at the deployment default -- the engine path to `supported`.

z <- qnorm(0.975)
lanes <- list(
  list(g = 8L,  dir = "docs/dev-log/simulation-artifacts/2026-06-27-q2-slope-coverage-grid-local"),
  list(g = 16L, dir = "docs/dev-log/simulation-artifacts/2026-06-27-slope-coverage-gsweep-local/gsweep-q2-g16"),
  list(g = 32L, dir = "docs/dev-log/simulation-artifacts/2026-06-27-slope-coverage-gsweep-local/gsweep-q2-g32")
)
cat(sprintf("%3s %6s %10s %12s %9s %10s %12s\n",
            "g", "n", "mean_bias", "log(g/(g-1))", "wald_z", "wald_t", "analytic_bc+t"))
for (ln in lanes) {
  g <- ln$g; tq <- qt(0.975, g - 1); shift <- log(g / (g - 1))
  files <- list.files(ln$dir, pattern = "-(mu1_x|mu2_x)-replicates.tsv$", full.names = TRUE)
  bias_acc <- 0; nz <- 0; nt <- 0; nbc <- 0; ntot <- 0
  for (f in files) {
    d <- read.delim(f, stringsAsFactors = FALSE)
    est <- suppressWarnings(as.numeric(d$estimate)); tru <- suppressWarnings(as.numeric(d$truth_value))
    L <- suppressWarnings(as.numeric(d$wald_lower)); U <- suppressWarnings(as.numeric(d$wald_upper))
    ok <- is.finite(L) & is.finite(U) & L > 0 & U > 0 & is.finite(est) & est > 0 & is.finite(tru)
    L <- L[ok]; U <- U[ok]; est <- est[ok]; tru <- tru[ok]; if (!length(tru)) next
    se <- (log(U) - log(L)) / (2 * z); m <- log(est); n <- length(tru); ntot <- ntot + n
    bias_acc <- bias_acc + sum(m - log(tru))
    nz <- nz + sum(tru >= L & tru <= U)
    nt <- nt + sum(tru >= exp(m - tq * se) & tru <= exp(m + tq * se))
    nbc <- nbc + sum(tru >= exp((m + shift) - tq * se) & tru <= exp((m + shift) + tq * se))
  }
  cat(sprintf("%3d %6d %10.3f %12.3f %9.3f %10.3f %12.3f\n",
              g, ntot, bias_acc / ntot, -shift, nz / ntot, nt / ntot, nbc / ntot))
}
