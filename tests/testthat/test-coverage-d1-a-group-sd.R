# C++ coverage for the opt-in `se_group_sd` ADREPORT bodies.
# `report_group_sd` defaults to 0, so the two-line bodies never ran in the
# suite even though the surrounding `if` was already hit. Each check compares
# the reported group SD with the R transform of its own log predictor, and the
# sdreport ADREPORT with the same transform of the sdreport log predictor.
# sdreport and `report()` can sit at slightly different parameter vectors, so
# the two vectors are not compared with each other.

d1_group_sd_control <- function() {
  drm_control(
    se_group_sd = TRUE,
    se_report_covariance = FALSE,
    optimizer = list(eval.max = 400L, iter.max = 400L)
  )
}

d1_re_frame <- function(seed) {
  set.seed(seed)
  id <- factor(rep(paste0("g", seq_len(4L)), each = 6L))
  data.frame(
    x = seq(-1, 1, length.out = length(id)),
    w = rep(seq(-0.5, 0.5, length.out = 4L), each = 6L),
    id = id
  )
}

d1_expect_group_sd <- function(fit, log_name, sd_name, eta) {
  report <- fit$obj$report()
  log_eta <- as.numeric(report[[log_name]])
  sd_hat <- as.numeric(report[[sd_name]])
  transformed <- drmTMB:::drm_exp_sd_logscale_guarded(
    drmTMB:::drm_softclamp_log_sd(log_eta, fit$model$tmb_data)
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_equal(log_eta, as.numeric(eta), tolerance = 1e-12)
  expect_equal(sd_hat, transformed, tolerance = 1e-12)
  expect_true(all(is.finite(sd_hat) & sd_hat > 0))

  nm <- names(fit$sdr$value)
  log_sdr <- as.numeric(fit$sdr$value[nm == log_name])
  sd_sdr <- as.numeric(fit$sdr$value[nm == sd_name])
  expect_equal(length(log_sdr), length(log_eta))
  expect_equal(length(sd_sdr), length(sd_hat))
  expect_equal(
    sd_sdr,
    drmTMB:::drm_exp_sd_logscale_guarded(
      drmTMB:::drm_softclamp_log_sd(log_sdr, fit$model$tmb_data)
    ),
    tolerance = 1e-12
  )
}

test_that("student group-SD ADREPORT matches the R log-SD transform", {
  dat <- d1_re_frame(1L)
  dat$y <- 0.2 + 0.4 * dat$x +
    rep(c(-0.3, 0.2, 0.4, -0.1), each = 6L) +
    rnorm(nrow(dat), sd = 0.25)
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ w),
    family = student(),
    data = dat,
    control = d1_group_sd_control()
  )
  eta <- drmTMB:::sd_mu_group_log_values(
    list(beta_sd_mu = as.numeric(fit$obj$report()$beta_sd_mu)),
    fit$model$random_scale$mu
  )
  d1_expect_group_sd(fit, "log_sd_mu_group", "sd_mu_group", eta)
})

test_that("Poisson group-SD ADREPORT matches the R log-SD transform", {
  dat <- d1_re_frame(2L)
  dat$y <- rpois(nrow(dat), lambda = 3)
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sd(id) ~ w),
    family = poisson(),
    data = dat,
    control = d1_group_sd_control()
  )
  eta <- drmTMB:::sd_mu_group_log_values(
    list(beta_sd_mu = as.numeric(fit$obj$report()$beta_sd_mu)),
    fit$model$random_scale$mu
  )
  d1_expect_group_sd(fit, "log_sd_mu_group", "sd_mu_group", eta)
})
