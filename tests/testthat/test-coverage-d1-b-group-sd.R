# Ordinary random-intercept group-SD ADREPORT bodies. See
# test-coverage-d1-a-group-sd.R for the transform each value is checked against.

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

d1_expect_mu <- function(fit) {
  eta <- drmTMB:::sd_mu_group_log_values(
    list(beta_sd_mu = as.numeric(fit$obj$report()$beta_sd_mu)),
    fit$model$random_scale$mu
  )
  d1_expect_group_sd(fit, "log_sd_mu_group", "sd_mu_group", eta)
}

d1_expect_sigma <- function(fit) {
  eta <- drmTMB:::sd_sigma_group_log_values(
    list(beta_sd_sigma = as.numeric(fit$obj$report()$beta_sd_sigma)),
    fit$model
  )
  d1_expect_group_sd(fit, "log_sd_sigma_group", "sd_sigma_group", eta)
}

test_that("skew-normal mu group-SD ADREPORT matches the R log-SD transform", {
  dat <- d1_re_frame(3L)
  dat$y <- 0.2 + 0.4 * dat$x +
    rep(c(-0.6, -0.2, 0.3, 0.7), each = 6L) +
    rnorm(nrow(dat), sd = 0.2)
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ w),
    family = skew_normal(),
    data = dat,
    control = d1_group_sd_control()
  )
  d1_expect_mu(fit)
})

test_that("lognormal mu group-SD ADREPORT matches the R log-SD transform", {
  dat <- d1_re_frame(12L)
  dat$y <- exp(
    0.1 + 0.2 * dat$x +
      rep(c(-0.4, -0.1, 0.2, 0.5), each = 6L) +
      rnorm(nrow(dat), sd = 0.15)
  )
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ w),
    family = lognormal(),
    data = dat,
    control = d1_group_sd_control()
  )
  d1_expect_mu(fit)
})

test_that("lognormal sigma group-SD ADREPORT matches the R log-SD transform", {
  dat <- d1_re_frame(4L)
  dat$y <- exp(0.1 + 0.2 * dat$x + rnorm(nrow(dat), sd = 0.2))
  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1 + (1 | id), sd(id, dpar = "sigma") ~ w),
    family = lognormal(),
    data = dat,
    control = d1_group_sd_control()
  )
  d1_expect_sigma(fit)
})

test_that("beta mu group-SD ADREPORT matches the R log-SD transform", {
  dat <- d1_re_frame(5L)
  dat$y <- plogis(0.2 + 0.3 * dat$x + rnorm(nrow(dat), sd = 0.2))
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ w),
    family = beta_family(),
    data = dat,
    control = d1_group_sd_control()
  )
  d1_expect_mu(fit)
})

test_that("zero-one-beta mu group-SD ADREPORT matches the R log-SD transform", {
  dat <- d1_re_frame(6L)
  dat$y <- plogis(0.1 * dat$x + rnorm(nrow(dat), sd = 0.15))
  fit <- drmTMB(
    bf(y ~ 1 + (1 | id), sd(id) ~ w),
    family = zero_one_beta(),
    data = dat,
    control = d1_group_sd_control()
  )
  d1_expect_mu(fit)
})

test_that("beta-binomial mu group-SD ADREPORT matches the R log-SD transform", {
  dat <- d1_re_frame(7L)
  dat$s <- rbinom(nrow(dat), 8L, 0.4)
  dat$f <- 8L - dat$s
  fit <- drmTMB(
    bf(cbind(s, f) ~ x + (1 | id), sigma ~ 1, sd(id) ~ w),
    family = beta_binomial(),
    data = dat,
    control = d1_group_sd_control()
  )
  d1_expect_mu(fit)
})

test_that("beta-binomial sigma group-SD ADREPORT matches the R log-SD transform", {
  dat <- d1_re_frame(8L)
  dat$s <- rbinom(nrow(dat), 8L, 0.45)
  dat$f <- 8L - dat$s
  fit <- drmTMB(
    bf(cbind(s, f) ~ 1, sigma ~ 1 + (1 | id), sd(id, dpar = "sigma") ~ 1),
    family = beta_binomial(),
    data = dat,
    control = d1_group_sd_control()
  )
  d1_expect_sigma(fit)
})

test_that("binomial mu group-SD ADREPORT matches the R log-SD transform", {
  dat <- d1_re_frame(9L)
  dat$y <- rbinom(nrow(dat), 1L, plogis(0.2 * dat$x))
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sd(id) ~ w),
    family = binomial(),
    data = dat,
    control = d1_group_sd_control()
  )
  d1_expect_mu(fit)
})

test_that("zero-inflated Poisson group-SD ADREPORT matches the R log-SD transform", {
  dat <- d1_re_frame(10L)
  dat$y <- rpois(nrow(dat), lambda = 2)
  fit <- drmTMB(
    bf(y ~ x + (1 | id), zi ~ 1, sd(id) ~ w),
    family = poisson(),
    data = dat,
    control = d1_group_sd_control()
  )
  d1_expect_mu(fit)
})

test_that("hurdle negative-binomial group-SD ADREPORT matches the R log-SD transform", {
  dat <- d1_re_frame(11L)
  dat$y <- rep(c(1L, 2L, 1L, 3L, 2L, 2L, 2L, 3L, 4L, 2L, 3L, 5L,
                 4L, 5L, 3L, 6L, 4L, 5L, 6L, 7L, 5L, 8L, 6L, 7L))
  fit <- drmTMB(
    bf(y ~ 1 + (1 | id), sigma ~ 1, hu ~ 1, sd(id) ~ 1),
    family = truncated_nbinom2(),
    data = dat,
    control = d1_group_sd_control()
  )
  d1_expect_mu(fit)
})
