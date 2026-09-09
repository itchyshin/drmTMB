temporal_ou_data <- function() {
  set.seed(20260909)
  dat <- expand.grid(
    id = sprintf("site_%02d", seq_len(12L)),
    elapsed = c(0, 0.5, 2.5, 5),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  dat$x <- stats::rnorm(nrow(dat))
  dat$y <- 0.3 + 0.4 * dat$x + stats::rnorm(nrow(dat), sd = 0.6)
  dat[sample.int(nrow(dat)), , drop = FALSE]
}

test_that("Gaussian temporal OU accepts irregular numeric elapsed time", {
  dat <- temporal_ou_data()
  fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1),
    data = dat,
    family = gaussian(),
    REML = FALSE
  )

  expect_s3_class(fit, "drmTMB")
  expect_true(is.finite(stats::logLik(fit)))
  expect_identical(fit$model$structured$temporal_mu$structure, "ou")
  expect_equal(sort(unique(fit$model$structured$temporal_mu$gap)), c(0, 0.5, 2, 2.5))
})

test_that("temporal OU labels and reports a positive decay rate", {
  fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1),
    data = temporal_ou_data(),
    family = gaussian(),
    REML = FALSE
  )

  temporal <- fit$model$structured$temporal_mu
  expect_match(temporal$label, 'structure = "ou"', fixed = TRUE)
  expect_null(fit$corpars$temporal)
  expect_true(is.finite(unname(fit$decaypars$temporal[[temporal$label]])))
  expect_gt(unname(fit$decaypars$temporal[[temporal$label]]), 0)
})

test_that("temporal OU defers Wald intervals until the inherited calibration prerequisite is met", {
  fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1),
    data = temporal_ou_data(),
    family = gaussian(),
    REML = FALSE
  )

  expect_error(
    stats::confint(fit, method = "wald"),
    "OU mean-coefficient Wald intervals are not yet qualified"
  )
  temporal_check <- drmTMB::check_drm(fit)
  temporal_wald <- temporal_check[temporal_check$check == "temporal_mean_wald", , drop = FALSE]
  expect_identical(temporal_wald$status, "note")
  expect_match(temporal_wald$value, "reason=calibration_deferred")
  expect_match(temporal_wald$message, "intentionally unavailable")
  temporal_profile <- temporal_check[temporal_check$check == "temporal_mean_profile", , drop = FALSE]
  expect_identical(temporal_profile$status, "note")
  expect_match(temporal_profile$value, "available_for_this_fit")
  expect_match(temporal_profile$message, "coverage calibration remains unresolved")
})

test_that("temporal OU profiles mean coefficients and rejects deferred targets", {
  fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1),
    data = temporal_ou_data(), family = gaussian(), REML = FALSE
  )
  profile_ci <- stats::confint(fit, parm = "mu:x", method = "profile")
  expect_equal(profile_ci$parm, "fixef:mu:x")
  expect_identical(profile_ci$method, "profile")
  expect_identical(profile_ci$conf.status, "profile")
  expect_true(is.finite(profile_ci$lower))
  expect_true(is.finite(profile_ci$upper))

  irregular <- fit
  irregular$sdr$pdHess <- FALSE
  expect_warning(
    irregular_ci <- stats::confint(irregular, parm = "mu:x", method = "profile"),
    class = "drmTMB_temporal_profile_hessian_warning"
  )
  expect_identical(irregular_ci$conf.status, "profile")
  irregular_check <- drmTMB::check_drm(irregular)
  irregular_profile <- irregular_check[
    irregular_check$check == "temporal_mean_profile",
    ,
    drop = FALSE
  ]
  expect_identical(irregular_profile$status, "warning")
  expect_match(irregular_profile$value, "base_hessian_non_pd")

  summary_fit <- summary(
    fit,
    conf.int = TRUE,
    method = "profile",
    ci_parm = "mu:x"
  )
  x_row <- summary_fit$coefficients["mu:x", , drop = FALSE]
  expect_identical(x_row$conf.method, "profile")
  expect_identical(x_row$conf.status, "profile")
  expect_true(is.finite(x_row$conf.low))
  expect_true(is.finite(x_row$conf.high))

  decay <- drmTMB:::profile_targets(fit)$parm[
    drmTMB:::profile_targets(fit)$target_class == "temporal-decay"
  ]
  expect_error(
    stats::confint(fit, parm = decay, method = "profile"),
    "mean regression coefficients only"
  )
  expect_error(
    stats::confint(fit, method = "bootstrap"),
    "do not support.*bootstrap"
  )
  expect_error(
    stats::confint(
      fit,
      parm = "mu:x",
      method = "profile",
      newdata = temporal_ou_data()[1, , drop = FALSE]
    ),
    "do not support.*newdata"
  )
  expect_error(
    stats::confint(fit, parm = "mu:x", method = "profile", profile_engine = "endpoint"),
    "require.*tmbprofile"
  )
  expect_error(
    stats::confint(fit, parm = "mu:x", method = "profile", profile_endpoint_max_eval = 10L),
    "do not use.*profile_endpoint_max_eval"
  )
})

test_that("temporal OU keeps covariance and decay intervals unavailable", {
  fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1),
    data = temporal_ou_data(), family = gaussian(), REML = FALSE
  )
  temporal <- fit$model$structured$temporal_mu
  expect_error(stats::vcov(fit), "OU coefficient covariance is not yet qualified")
  summary_fit <- summary(fit)
  expect_true(all(is.na(summary_fit$coefficients$std_error)))
  expect_identical(
    summary_fit$coefficients$std_error.status,
    rep("temporal_wald_unqualified", nrow(summary_fit$coefficients))
  )
  targets <- drmTMB:::profile_targets(fit)
  decay <- targets[targets$target_class == "temporal-decay", , drop = FALSE]
  expect_equal(nrow(decay), 1L)
  expect_match(decay$parm, "^decay:temporal:")
  expect_identical(decay$tmb_parameter, "theta_temporal")
  expect_identical(decay$transformation, "exp")
  expect_false(decay$profile_ready)
  expect_identical(decay$profile_note, "temporal_decay_intervals_deferred")
  expect_equal(decay$estimate, unname(fit$decaypars$temporal[[temporal$label]]))
})

test_that("temporal OU has finite objective for extremely small positive decay", {
  fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1),
    data = temporal_ou_data(), family = gaussian(), REML = FALSE
  )
  par <- fit$obj$par
  par[[match("theta_temporal", names(par))]] <- -37
  expect_true(is.finite(fit$obj$fn(par)))
})

test_that("temporal OU uses positive, gap-scaled decay starts", {
  fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1),
    data = temporal_ou_data(), family = gaussian(), REML = FALSE
  )
  starts <- fit$temporal_start_attempts
  expect_true("decay_start" %in% names(starts))
  expect_false("persistence_start" %in% names(starts))
  expect_equal(nrow(starts), 2L)
  expect_true(all(is.finite(starts$decay_start)))
  expect_true(all(starts$decay_start > 0))
})

test_that("temporal OU preserves observation order across in-sample methods", {
  dat <- temporal_ou_data()
  fit <- drmTMB::drmTMB(
    drmTMB::bf(y ~ x + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1),
    data = dat, family = gaussian(), REML = FALSE
  )
  expect_length(stats::fitted(fit), nrow(dat))
  expect_length(stats::residuals(fit), nrow(dat))
  expect_equal(length(fit$random_effects$temporal$values), nrow(dat))
  fresh <- simulate(fit, nsim = 2L)
  conditional <- simulate(fit, nsim = 2L, re.form = NA)
  expect_equal(dim(fresh), c(nrow(dat), 2L))
  expect_equal(dim(conditional), c(nrow(dat), 2L))
  expect_true(all(is.finite(as.matrix(fresh))))
  expect_true(all(is.finite(as.matrix(conditional))))
})

test_that("temporal OU rejects invalid metadata before response omission", {
  dat <- temporal_ou_data()
  duplicate <- dat
  duplicate$elapsed[[2L]] <- duplicate$elapsed[[1L]]
  expect_error(
    drmTMB::drmTMB(drmTMB::bf(y ~ x + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1), data = duplicate, family = gaussian()),
    "keys must be unique"
  )
  missing_time <- dat
  missing_time$elapsed[[1L]] <- NA_real_
  expect_error(
    drmTMB::drmTMB(drmTMB::bf(y ~ x + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1), data = missing_time, family = gaussian()),
    "must be complete"
  )
  non_numeric <- dat
  non_numeric$elapsed <- as.character(non_numeric$elapsed)
  expect_error(
    drmTMB::drmTMB(drmTMB::bf(y ~ x + temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1), data = non_numeric, family = gaussian()),
    "finite numeric"
  )
})
