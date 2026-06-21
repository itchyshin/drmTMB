test_that("optimizer presets expand to explicit nlminb controls", {
  default <- drm_control()
  expect_equal(default$optimizer_preset, "default")
  expect_equal(default$optimizer, list())

  careful <- drm_control(optimizer_preset = "careful")
  expect_equal(careful$optimizer, list(iter.max = 1000L, eval.max = 1000L))

  robust <- drm_control(
    optimizer_preset = "robust",
    optimizer = list(eval.max = 8000L, trace = 1L)
  )
  expect_equal(
    robust$optimizer,
    list(iter.max = 5000L, eval.max = 8000L, trace = 1L)
  )

  expect_error(drm_control(optimizer_preset = "wide"), "should be one of")
})

test_that("optimizer presets are recorded on fitted objects", {
  dat <- data.frame(y = c(-0.2, 0.0, 0.3, 0.6), x = c(-1, 0, 1, 2))

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(optimizer_preset = "careful", se = FALSE)
  )

  expect_equal(fit$control$optimizer_preset, "careful")
  expect_equal(fit$control$optimizer$iter.max, 1000L)
  expect_equal(fit$control$optimizer$eval.max, 1000L)
  expect_equal(fit$uncertainty$status, "skipped")
})

test_that("future optimizer contract names are reserved in plain control lists", {
  dat <- data.frame(y = c(-0.2, 0.0, 0.3, 0.6), x = c(-1, 0, 1, 2))
  reserved <- c(
    "optimizer_preset",
    "start",
    "starts",
    "start_from",
    "warm_start",
    "warm_starts",
    "warm_start_from",
    "map",
    "fixed",
    "fallback_optimizer",
    "fallback_optimizers",
    "optimizer_fallback",
    "optimizer_fallbacks",
    "multi_start",
    "multistart"
  )

  for (name in reserved) {
    control <- stats::setNames(list(TRUE), name)
    expect_error(
      drmTMB(
        bf(y ~ x, sigma ~ 1),
        data = dat,
        control = control
      ),
      "reserved"
    )
    expect_error(
      drm_control(optimizer = control),
      "reserved"
    )
  }

  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      control = list(start = TRUE, map = TRUE)
    ),
    "start"
  )
})

test_that("internal start override preserves no-op specs", {
  spec <- list(
    start = list(
      beta_mu = c(`(Intercept)` = 0, x = 1),
      beta_sigma = c(`(Intercept)` = -0.2)
    ),
    map = list(beta_sigma = factor(NA)),
    random_names = "u_mu"
  )

  expect_equal(drmTMB:::drm_apply_start_override(spec), spec)
})

test_that("internal start override validates names and respects mapped slots", {
  spec <- list(
    start = list(
      beta_mu = c(`(Intercept)` = 0, x = 1),
      beta_nu = c(`(Intercept)` = 0),
      theta_re_cov = c(`mu1:mu2` = 0, `mu1:sigma1` = 0, `mu2:sigma1` = 0)
    ),
    map = list(
      beta_nu = factor(NA),
      theta_re_cov = factor(c(1, NA, 2))
    ),
    random_names = "u_re_cov"
  )

  out <- drmTMB:::drm_apply_start_override(
    spec,
    override = list(
      beta_mu = c(`(Intercept)` = 0.4, x = 1.3),
      beta_nu = c(`(Intercept)` = 2),
      theta_re_cov = c(`mu1:mu2` = 0.1, `mu1:sigma1` = 0.2, `mu2:sigma1` = 0.3)
    ),
    provenance = list(strategy = "unit-test")
  )

  expect_equal(out$start$beta_mu, c(`(Intercept)` = 0.4, x = 1.3))
  expect_equal(out$start$beta_nu, spec$start$beta_nu)
  expect_equal(
    out$start$theta_re_cov,
    c(`mu1:mu2` = 0.1, `mu1:sigma1` = 0, `mu2:sigma1` = 0.3)
  )
  expect_equal(out$map, spec$map)
  expect_equal(out$random_names, spec$random_names)
  expect_equal(out$start_override$provenance$strategy, "unit-test")
  expect_equal(
    out$start_override$applied$n_applied,
    c(2L, 0L, 2L)
  )
  expect_equal(
    out$start_override$applied$n_fixed,
    c(0L, 1L, 1L)
  )
})

test_that("internal start override rejects invalid override shapes", {
  spec <- list(
    start = list(beta_mu = c(`(Intercept)` = 0, x = 1)),
    map = list()
  )

  expect_error(
    drmTMB:::drm_apply_start_override(spec, override = c(beta_mu = 1)),
    "named list"
  )
  expect_error(
    drmTMB:::drm_apply_start_override(spec, override = list(beta_sigma = 1)),
    "unknown parameter"
  )
  expect_error(
    drmTMB:::drm_apply_start_override(spec, override = list(beta_mu = 1)),
    "wrong length"
  )
  expect_error(
    drmTMB:::drm_apply_start_override(
      spec,
      override = list(beta_mu = c(1, NA))
    ),
    "finite numeric"
  )
  expect_error(
    drmTMB:::drm_apply_start_override(
      spec,
      override = structure(
        list(c(1, 2), c(3, 4)),
        names = c("beta_mu", "beta_mu")
      )
    ),
    "unique"
  )
})

test_that("q>2 staged start override maps fixed effects and endpoint SDs by keys", {
  dat <- data.frame(
    id = factor(rep(seq_len(8L), each = 4L)),
    x = rep(seq(-1, 1, length.out = 4L), times = 8L)
  )
  dat$y1 <- 0.2 + 0.4 * dat$x + rep(seq(-0.2, 0.2, length.out = 8L), each = 4L)
  dat$y2 <- -0.1 -
    0.3 * dat$x +
    rep(seq(0.15, -0.15, length.out = 8L), each = 4L)

  source_spec <- drmTMB:::drm_build_biv_gaussian_spec(
    bf(
      mu1 = y1 ~ x + (1 | p | id),
      mu2 = y2 ~ x + (1 | p | id),
      sigma1 = ~ x + (1 | p | id),
      sigma2 = ~ x + (1 | p | id),
      rho12 = ~1
    ),
    data = dat
  )
  target_spec <- drmTMB:::drm_build_biv_gaussian_spec(
    bf(
      mu1 = y1 ~ x + (1 + x | p | id),
      mu2 = y2 ~ x + (1 + x | p | id),
      sigma1 = ~ x + (1 + x | p | id),
      sigma2 = ~ x + (1 + x | p | id),
      rho12 = ~1
    ),
    data = dat
  )

  source_members <- drmTMB:::qgt2_covariance_members(
    source_spec$random$covariance_blocks
  )
  source_sd <- stats::setNames(
    c(0.31, 0.35, 0.18, 0.22),
    source_members$label
  )
  source_fit <- list(
    model = source_spec,
    coefficients = list(
      mu1 = c(`(Intercept)` = 0.11, x = 0.41),
      mu2 = c(`(Intercept)` = -0.12, x = -0.31),
      sigma1 = c(`(Intercept)` = -0.71),
      sigma2 = c(`(Intercept)` = -0.62),
      rho12 = c(`(Intercept)` = 0.08)
    ),
    sdpars = list(
      mu = source_sd[source_members$component == "mu"],
      sigma = source_sd[source_members$component == "sigma"]
    ),
    corpars = list(
      re_cov = stats::setNames(
        c(0.24, -0.18, 0.12, 0.08, -0.10, 0.20),
        source_spec$random$covariance_blocks$pairs$parameter
      )
    )
  )

  mapped <- drmTMB:::drm_qgt2_staged_start_override(source_fit, target_spec)
  target_members <- drmTMB:::qgt2_covariance_members(
    target_spec$random$covariance_blocks
  )
  sd_matches <- mapped$provenance$qgt2_sd_matches
  matched_rows <- which(sd_matches$source_matched)

  expect_named(
    mapped$override,
    c(
      "beta_mu1",
      "beta_mu2",
      "beta_sigma1",
      "beta_sigma2",
      "beta_rho12",
      "log_sd_re_cov"
    )
  )
  expect_equal(unname(mapped$override$beta_mu1), c(0.11, 0.41))
  expect_equal(unname(mapped$override$beta_mu2), c(-0.12, -0.31))
  expect_equal(mapped$override$beta_sigma1[[1L]], -0.71)
  expect_equal(
    mapped$override$beta_sigma1[[2L]],
    target_spec$start$beta_sigma1[[2L]]
  )
  expect_equal(mapped$override$beta_sigma2[[1L]], -0.62)
  expect_equal(
    mapped$override$beta_sigma2[[2L]],
    target_spec$start$beta_sigma2[[2L]]
  )
  expect_equal(unname(mapped$override$beta_rho12), 0.08)
  expect_equal(sum(sd_matches$source_matched), 4L)
  expect_equal(target_members$coef[matched_rows], rep("(Intercept)", 4L))
  expect_equal(
    exp(unname(mapped$override$log_sd_re_cov[matched_rows])),
    unname(source_sd),
    tolerance = 1e-12
  )
  expect_equal(
    mapped$override$log_sd_re_cov[!sd_matches$source_matched],
    target_spec$start$log_sd_re_cov[!sd_matches$source_matched]
  )
  expect_false("theta_re_cov" %in% names(mapped$override))
  expect_equal(
    mapped$provenance$theta_re_cov,
    "not_requested"
  )

  applied <- drmTMB:::drm_apply_start_override(
    target_spec,
    override = mapped$override,
    provenance = mapped$provenance
  )
  expect_equal(applied$start$theta_re_cov, target_spec$start$theta_re_cov)
  expect_equal(
    applied$start_override$applied$parameter,
    names(mapped$override)
  )
})

test_that("q>2 staged start override copies theta starts by pair key", {
  dat <- data.frame(
    id = factor(rep(seq_len(8L), each = 4L)),
    x = rep(seq(-1, 1, length.out = 4L), times = 8L)
  )
  dat$y1 <- 0.2 + 0.4 * dat$x + rep(seq(-0.2, 0.2, length.out = 8L), each = 4L)
  dat$y2 <- -0.1 -
    0.3 * dat$x +
    rep(seq(0.15, -0.15, length.out = 8L), each = 4L)
  source_spec <- drmTMB:::drm_build_biv_gaussian_spec(
    bf(
      mu1 = y1 ~ x + (1 | p | id),
      mu2 = y2 ~ x + (1 | p | id),
      sigma1 = ~ x + (1 | p | id),
      sigma2 = ~ x + (1 | p | id),
      rho12 = ~1
    ),
    data = dat
  )
  target_spec <- drmTMB:::drm_build_biv_gaussian_spec(
    bf(
      mu1 = y1 ~ x + (1 + x | p | id),
      mu2 = y2 ~ x + (1 + x | p | id),
      sigma1 = ~ x + (1 + x | p | id),
      sigma2 = ~ x + (1 + x | p | id),
      rho12 = ~1
    ),
    data = dat
  )
  source_fit <- list(
    model = source_spec,
    coefficients = list(),
    sdpars = list(),
    corpars = list(
      re_cov = stats::setNames(
        c(0.24, -0.18, 0.12, 0.08, -0.10, 0.20),
        source_spec$random$covariance_blocks$pairs$parameter
      )
    )
  )

  mapped <- drmTMB:::drm_qgt2_staged_start_override(
    source_fit,
    target_spec,
    copy_theta_re_cov = TRUE,
    theta_re_cov_shrink = 0.5
  )
  target_pairs <- target_spec$random$covariance_blocks$pairs
  theta <- mapped$override$theta_re_cov
  corr <- drmTMB:::tmb_unstructured_corr_matrix(theta)
  copied <- target_pairs$parameter %in% names(source_fit$corpars$re_cov)

  expect_true("theta_re_cov" %in% names(mapped$override))
  expect_equal(mapped$provenance$theta_re_cov, "copied_by_pair_key")
  expect_equal(sum(mapped$provenance$qgt2_theta_matches$source_matched), 6L)
  for (i in seq_len(nrow(target_pairs))) {
    from <- target_pairs$from_member_id0[[i]] + 1L
    to <- target_pairs$to_member_id0[[i]] + 1L
    if (copied[[i]]) {
      expect_equal(
        corr[from, to],
        0.5 * source_fit$corpars$re_cov[[target_pairs$parameter[[i]]]],
        tolerance = 1e-10
      )
    } else {
      expect_equal(corr[from, to], 0, tolerance = 1e-10)
    }
  }

  applied <- drmTMB:::drm_apply_start_override(
    target_spec,
    override = mapped$override,
    provenance = mapped$provenance
  )
  expect_equal(applied$start$theta_re_cov, theta)
})

test_that("q>2 staged start override validates theta shrink", {
  expect_error(
    drmTMB:::drm_qgt2_staged_start_override(
      list(model = list()),
      list(start = list()),
      copy_theta_re_cov = TRUE,
      theta_re_cov_shrink = 1.5
    ),
    "theta_re_cov_shrink"
  )
})

test_that("unstructured correlation theta inverse reconstructs target matrices", {
  corr <- matrix(
    c(
      1.00, 0.20, -0.15, 0.05,
      0.20, 1.00, 0.18, -0.10,
      -0.15, 0.18, 1.00, 0.25,
      0.05, -0.10, 0.25, 1.00
    ),
    nrow = 4L,
    byrow = TRUE
  )
  theta <- drmTMB:::correlation_matrix_to_tmb_unstructured_theta(corr)

  expect_equal(
    drmTMB:::tmb_unstructured_corr_matrix(theta),
    corr,
    tolerance = 1e-10
  )
})

test_that("Gaussian fixed-effect starts use OLS mean and residual scale", {
  dat <- data.frame(
    x = seq(-1.5, 1.5, length.out = 10),
    z = rep(c(-0.5, 0.25), length.out = 10)
  )
  dat$y <- 0.6 +
    0.8 * dat$x +
    c(-0.15, 0.12, -0.05, 0.22, -0.18, 0.08, 0.16, -0.12, 0.04, -0.02)

  fit <- drmTMB(
    bf(y ~ x, sigma ~ z),
    data = dat,
    control = drm_control(se = FALSE)
  )

  X_mu <- stats::model.matrix(~x, dat)
  X_sigma <- stats::model.matrix(~z, dat)
  expected_mu <- stats::lm.fit(x = X_mu, y = dat$y)$coefficients
  expected_mu[is.na(expected_mu)] <- 0
  resid <- dat$y - as.vector(X_mu %*% expected_mu)
  y_scale <- stats::sd(dat$y)
  sigma_floor <- max(1e-4, 0.05 * y_scale)
  expected_sigma0 <- sqrt(max(stats::var(resid), sigma_floor^2))
  expected_sigma <- numeric(ncol(X_sigma))
  expected_sigma[[1L]] <- log(expected_sigma0)

  expect_equal(unname(fit$model$start$beta_mu), unname(expected_mu))
  expect_equal(unname(fit$model$start$beta_sigma), unname(expected_sigma))
  expect_equal(fit$uncertainty$status, "skipped")
})

test_that("bivariate Gaussian starts use response-specific OLS and Fisher-z rho12", {
  dat <- data.frame(x = seq(-1.5, 1.5, length.out = 12))
  e1 <- c(
    -0.25,
    -0.05,
    0.16,
    0.22,
    -0.14,
    0.08,
    0.18,
    -0.16,
    0.06,
    -0.03,
    0.12,
    -0.19
  )
  e2 <- 0.35 *
    e1 +
    c(
      0.08,
      -0.14,
      0.04,
      -0.07,
      0.13,
      -0.03,
      0.10,
      -0.11,
      0.05,
      -0.06,
      0.02,
      -0.01
    )
  dat$y1 <- 0.4 + 0.7 * dat$x + e1
  dat$y2 <- -0.2 + 0.45 * dat$x + e2

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  X <- stats::model.matrix(~x, dat)
  expected_mu1 <- stats::lm.fit(x = X, y = dat$y1)$coefficients
  expected_mu2 <- stats::lm.fit(x = X, y = dat$y2)$coefficients
  expected_mu1[is.na(expected_mu1)] <- 0
  expected_mu2[is.na(expected_mu2)] <- 0
  resid1 <- dat$y1 - as.vector(X %*% expected_mu1)
  resid2 <- dat$y2 - as.vector(X %*% expected_mu2)
  expected_sigma1 <- sqrt(max(stats::var(resid1), 1e-4^2))
  expected_sigma2 <- sqrt(max(stats::var(resid2), 1e-4^2))
  expected_rho <- max(min(stats::cor(resid1, resid2), 0.8), -0.8)

  expect_equal(unname(fit$model$start$beta_mu1), unname(expected_mu1))
  expect_equal(unname(fit$model$start$beta_mu2), unname(expected_mu2))
  expect_equal(unname(fit$model$start$beta_sigma1), log(expected_sigma1))
  expect_equal(unname(fit$model$start$beta_sigma2), log(expected_sigma2))
  expect_equal(unname(fit$model$start$beta_rho12), atanh(expected_rho))
  expect_equal(fit$uncertainty$status, "skipped")
})

test_that("Gaussian constant sigma remains an optimized parameter", {
  dat <- data.frame(
    y = c(-0.22, -0.04, 0.19, 0.43, 0.73, 0.96, 1.20),
    x = seq(-1.5, 1.5, length.out = 7)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_null(fit$model$map$beta_sigma)
  expect_equal(sum(names(fit$opt$par) == "beta_sigma"), 1L)
  expect_equal(
    length(fit$opt$par),
    ncol(fit$model$X$mu) + ncol(fit$model$X$sigma)
  )
  expect_equal(fit$df, length(fit$opt$par))
})

test_that("bivariate Gaussian constant sigmas remain optimized parameters", {
  dat <- data.frame(x = seq(-1, 1, length.out = 10))
  e1 <- c(-0.12, 0.03, 0.09, -0.06, 0.15, -0.08, 0.04, 0.11, -0.05, 0.02)
  e2 <- c(0.05, -0.10, 0.07, 0.02, -0.04, 0.09, -0.03, 0.06, -0.08, 0.01)
  dat$y1 <- 0.15 + 0.55 * dat$x + e1
  dat$y2 <- -0.20 + 0.35 * dat$x + e2

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x,
      mu2 = y2 ~ x,
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_null(fit$model$map$beta_sigma1)
  expect_null(fit$model$map$beta_sigma2)
  expect_equal(sum(names(fit$opt$par) == "beta_sigma1"), 1L)
  expect_equal(sum(names(fit$opt$par) == "beta_sigma2"), 1L)
  expect_equal(
    length(fit$opt$par),
    ncol(fit$model$X$mu1) +
      ncol(fit$model$X$mu2) +
      ncol(fit$model$X$sigma1) +
      ncol(fit$model$X$sigma2) +
      ncol(fit$model$X$rho12)
  )
  expect_equal(fit$df, length(fit$opt$par))
})

test_that("reported parameters are split from the selected optimum", {
  dat <- data.frame(
    y = c(-0.2, 0.0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )

  par_list <- fit$obj$env$parList(fit$opt$par)
  expect_equal(
    fit$coefficients,
    drmTMB:::split_tmb_parameters(
      par_list,
      fit$model
    )
  )
  expect_equal(fit$sdpars, drmTMB:::split_tmb_sdpars(par_list, fit$model))
  expect_equal(fit$corpars, drmTMB:::split_tmb_corpars(par_list, fit$model))
  expect_equal(fit$uncertainty$status, "ok")
})

test_that("profile intervals re-pin the TMB object to the selected optimum", {
  dat <- data.frame(
    y = c(-0.2, 0.0, 0.3, 0.6, 0.8, 1.2),
    x = c(-1, -0.5, 0, 0.5, 1, 1.5)
  )

  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  bad_par <- fit$opt$par + seq_along(fit$opt$par)
  fit$obj$env$last.par <- bad_par
  fit$obj$env$last.par.best <- bad_par

  drmTMB:::drm_pin_tmb_object_to_optimum(fit$obj, fit$opt, fit$tmb_state)
  expect_equal(unname(fit$obj$env$last.par), unname(fit$opt$par))
  expect_equal(unname(fit$obj$env$last.par.best), unname(fit$opt$par))

  fit$obj$env$last.par <- bad_par
  fit$obj$env$last.par.best <- bad_par
  ci <- stats::confint(
    fit,
    parm = "fixef:mu:(Intercept)",
    method = "profile",
    trace = FALSE
  )
  expect_equal(ci$conf.status, "profile")
  expect_lt(ci$lower, unname(fit$coefficients$mu[["(Intercept)"]]))
  expect_gt(ci$upper, unname(fit$coefficients$mu[["(Intercept)"]]))
})

test_that("pinning preserves random-effect slots in the TMB object", {
  set.seed(20260515)
  id <- factor(rep(seq_len(8), each = 5))
  x <- rep(seq(-1, 1, length.out = 5), times = 8)
  u <- stats::rnorm(8, sd = 0.4)
  dat <- data.frame(
    y = 0.2 + 0.5 * x + u[id] + stats::rnorm(length(id), sd = 0.35),
    x = x,
    id = id
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1),
    data = dat,
    control = list(eval.max = 100, iter.max = 100)
  )
  original_last <- fit$obj$env$last.par
  fit$obj$env$last.par <- original_last + seq_along(original_last)
  fit$obj$env$last.par.best <- fit$obj$env$last.par.best +
    seq_along(fit$obj$env$last.par.best)

  drmTMB:::drm_pin_tmb_object_to_optimum(fit$obj, fit$opt, fit$tmb_state)
  fixed <- fit$obj$env$lfixed()
  expect_equal(length(fit$obj$env$last.par), length(fit$tmb_state$last.par))
  expect_equal(unname(fit$obj$env$last.par[fixed]), unname(fit$opt$par))
  expect_equal(
    unname(fit$obj$env$last.par[!fixed]),
    unname(fit$tmb_state$last.par[!fixed])
  )
  expect_equal(
    unname(fit$obj$env$last.par.best),
    unname(fit$tmb_state$last.par.best)
  )
  expect_true(all(is.finite(ranef(fit)$mu$values)))
})
