#!/usr/bin/env Rscript

# Optional local harness for Gaussian location-scale comparator checks.
# It uses simulated paper-shaped examples so the harness remains reproducible
# without bundling external tutorial data.

load_drmTMB <- function() {
  if (
    file.exists("DESCRIPTION") &&
      dir.exists("R") &&
      requireNamespace("devtools", quietly = TRUE)
  ) {
    devtools::load_all(quiet = TRUE)
    return(invisible(TRUE))
  }
  if (requireNamespace("drmTMB", quietly = TRUE)) {
    suppressPackageStartupMessages(library(drmTMB))
    return(invisible(TRUE))
  }
  stop(
    "Install drmTMB or run this script from the package root with devtools available.",
    call. = FALSE
  )
}

require_glmmTMB <- function() {
  ok <- suppressWarnings(requireNamespace("glmmTMB", quietly = TRUE))
  if (!ok) {
    stop(
      "Package glmmTMB is required for this optional comparator harness.",
      call. = FALSE
    )
  }
}

simulate_fixed_location_scale <- function(seed = 20260522, n = 360) {
  set.seed(seed)
  dat <- data.frame(
    sex = factor(rep(c("female", "male"), length.out = n)),
    treatment = factor(rep(c("control", "treated"), each = 2L, length.out = n))
  )
  X <- stats::model.matrix(~ sex * treatment, dat)
  beta_mu <- c(
    `(Intercept)` = 0.20,
    sexmale = 0.12,
    treatmenttreated = -0.18,
    `sexmale:treatmenttreated` = 0.30
  )
  beta_sigma <- c(
    `(Intercept)` = log(0.45),
    sexmale = 0.10,
    treatmenttreated = 0.25,
    `sexmale:treatmenttreated` = -0.12
  )
  mu <- as.vector(X %*% beta_mu)
  sigma <- exp(as.vector(X %*% beta_sigma))
  dat$y <- stats::rnorm(n, mean = mu, sd = sigma)
  dat
}

simulate_random_intercept_location_scale <- function(seed = 20260523) {
  set.seed(seed)
  n_nest <- 28
  n_each <- 8
  n <- n_nest * n_each
  dat <- data.frame(
    nest = factor(rep(seq_len(n_nest), each = n_each)),
    rank = factor(rep(c("low", "high"), length.out = n))
  )
  beta_mu <- c(`(Intercept)` = 0.15, rankhigh = 0.35)
  beta_sigma <- c(`(Intercept)` = log(0.40), rankhigh = -0.18)
  u_nest <- stats::rnorm(n_nest, sd = 0.32)
  X <- stats::model.matrix(~rank, dat)
  mu <- as.vector(X %*% beta_mu) + u_nest[dat$nest]
  sigma <- exp(as.vector(X %*% beta_sigma))
  dat$y <- stats::rnorm(n, mean = mu, sd = sigma)
  dat
}

compare_fixed_case <- function() {
  dat <- simulate_fixed_location_scale()
  fit_drm <- drmTMB(
    bf(y ~ sex * treatment, sigma ~ sex * treatment),
    family = gaussian(),
    data = dat
  )
  fit_glmm <- suppressWarnings(glmmTMB::glmmTMB(
    y ~ sex * treatment,
    dispformula = ~ sex * treatment,
    family = gaussian(),
    data = dat
  ))
  summarize_comparison("fixed_location_scale", fit_drm, fit_glmm)
}

compare_random_case <- function() {
  dat <- simulate_random_intercept_location_scale()
  fit_drm <- drmTMB(
    bf(y ~ rank + (1 | nest), sigma ~ rank),
    family = gaussian(),
    data = dat
  )
  fit_glmm <- suppressWarnings(glmmTMB::glmmTMB(
    y ~ rank + (1 | nest),
    dispformula = ~rank,
    family = gaussian(),
    data = dat
  ))
  summarize_comparison("random_intercept_location_scale", fit_drm, fit_glmm)
}

summarize_comparison <- function(case, fit_drm, fit_glmm) {
  vc <- glmmTMB::VarCorr(fit_glmm)$cond
  sd_diff <- NA_real_
  if (length(vc) > 0L && length(fit_drm$sdpars$mu) > 0L) {
    sd_diff <- max(abs(
      unname(fit_drm$sdpars$mu) -
        unname(unlist(lapply(vc, attr, "stddev")))
    ))
  }
  data.frame(
    case = case,
    max_abs_mu_coef_diff = max(abs(
      unname(coef(fit_drm, "mu")) -
        unname(glmmTMB::fixef(fit_glmm)$cond)
    )),
    max_abs_sigma_coef_diff = max(abs(
      unname(coef(fit_drm, "sigma")) -
        unname(glmmTMB::fixef(fit_glmm)$disp)
    )),
    max_abs_mu_sd_diff = sd_diff,
    abs_loglik_diff = abs(
      as.numeric(stats::logLik(fit_drm)) -
        as.numeric(stats::logLik(fit_glmm))
    ),
    stringsAsFactors = FALSE
  )
}

main <- function(tolerance = 1e-4) {
  load_drmTMB()
  require_glmmTMB()
  out <- rbind(compare_fixed_case(), compare_random_case())
  out$passed <- with(
    out,
    max_abs_mu_coef_diff < tolerance &
      max_abs_sigma_coef_diff < tolerance &
      (is.na(max_abs_mu_sd_diff) | max_abs_mu_sd_diff < tolerance) &
      abs_loglik_diff < tolerance
  )
  print(out, row.names = FALSE)
  if (!all(out$passed)) {
    stop(
      "One or more Gaussian location-scale comparator checks failed.",
      call. = FALSE
    )
  }
  invisible(out)
}

if (identical(environment(), globalenv())) {
  main()
}
