# drmTMB's sd(g) boundary label uses an absolute rule (sd < 1e-4 on the response
# scale; R/profile.R wald_boundary_targets(), R/check.R drm_inference_at_boundary()),
# so whether a fit is called "boundary" depends on the units of y.
# Run from this directory: Rscript repro_sd_boundary_units.R
suppressPackageStartupMessages(library(drmTMB))
f <- bf(y ~ x + (1 | g), sigma ~ z)
show <- function(file, scale) {
  d <- read.csv(file); d$g <- factor(d$g); d$y <- d$y * scale
  fit <- suppressWarnings(drmTMB(f, data = d))
  tg <- drmTMB:::drm_profile_targets(fit)
  k <- which(tg$parm == "sd:mu:(1 | g)")
  se <- tryCatch(sqrt(diag(drmTMB:::drm_sdreport_cov_fixed(fit)))[drmTMB:::profile_target_opt_positions(fit, tg)][k],
                 error = function(e) NA_real_)   # NA: sdreport Hessian not positive definite
  ci <- suppressWarnings(confint(fit, method = "wald"))
  r <- ci[ci$parm == "sd:mu:(1 | g)", ]
  cat(sprintf("%-22s y x %-6g sd(g) = %.3g (sd/sd(y) = %.2g)  SE(log sd) = %.3g  status = %-10s is_converged = %s  Wald = [%g, %g] (%s)\n",
              file, scale, exp(tg$link_estimate[k]), exp(tg$link_estimate[k]) / sd(d$y), se,
              convergence_status(fit), is_converged(fit), r$lower, r$upper, r$conf.status))
}
for (s in c(1, 1000)) show("n0050_G20_rep121.csv", s)
for (s in c(1, 1e-3)) show("n0050_G20_rep445.csv", s)
