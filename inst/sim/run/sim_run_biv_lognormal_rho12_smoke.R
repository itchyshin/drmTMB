#!/usr/bin/env Rscript

# One-cell non-empty smoke for the exact bivariate-lognormal rho12 interval
# route.  This is deliberately small: the replicated n-ladder belongs on
# Totoro after this output has been inspected.

args <- commandArgs(trailingOnly = TRUE)
output_dir <- if (length(args)) args[[1L]] else file.path(
  "docs", "dev-log", "simulation-artifacts", "2026-07-24-biv-lognormal-rho12-smoke"
)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

if (!requireNamespace("drmTMB", quietly = TRUE)) {
  stop("Install drmTMB before running this smoke.", call. = FALSE)
}

set.seed(2026072401)
n <- 160L
x <- seq(-1, 1, length.out = n)
rho_truth <- 0.5
z1 <- stats::rnorm(n)
z2 <- rho_truth * z1 + sqrt(1 - rho_truth^2) * stats::rnorm(n)
dat <- data.frame(
  x = x,
  y1 = exp(0.2 + 0.3 * x + 0.4 * z1),
  y2 = exp(-0.1 - 0.2 * x + 0.7 * z2)
)

fit <- drmTMB::drmTMB(
  drmTMB::bf(
    mu1 = y1 ~ x, mu2 = y2 ~ x,
    sigma1 = ~ 1, sigma2 = ~ 1, rho12 = ~ 1
  ),
  family = drmTMB::biv_lognormal(), data = dat
)
wald <- stats::confint(fit, parm = "rho12", method = "wald")
profile_ci <- stats::confint(
  fit, parm = "rho12", method = "profile", profile_precision = "fast"
)
bootstrap <- stats::confint(
  fit, parm = "rho12", method = "bootstrap", R = 9, seed = 2026072402
)

summary <- data.frame(
  n = n,
  rho_truth = rho_truth,
  rho_estimate = drmTMB::rho12(fit)[[1L]],
  convergence = fit$opt$convergence,
  pdHess = fit$sdr$pdHess,
  wald_status = wald$conf.status,
  profile_status = profile_ci$conf.status,
  bootstrap_status = bootstrap$conf.status,
  bootstrap_success = bootstrap$bootstrap.n,
  bootstrap_failed = bootstrap$bootstrap.failed
)

if (fit$opt$convergence != 0L || !isTRUE(fit$sdr$pdHess) ||
    !is.finite(summary$rho_estimate) ||
    bootstrap$bootstrap.n < 2L) {
  stop("The biv_lognormal rho12 smoke did not produce a valid non-empty result.", call. = FALSE)
}

utils::write.csv(summary, file.path(output_dir, "summary.csv"), row.names = FALSE)
saveRDS(
  list(summary = summary, wald = wald, profile = profile_ci, bootstrap = bootstrap),
  file.path(output_dir, "intervals.rds")
)
message("Wrote biv_lognormal rho12 smoke artefacts to ", normalizePath(output_dir))
