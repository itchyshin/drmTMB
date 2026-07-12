# Arc 2a DG2 sentinels: an ordinary `mu` random intercept `(1 | id)` for the five
# families that previously rejected all random effects. tweedie's sentinel lives
# in test-tweedie-location-scale.R; the other four are here.

expect_mu_random_intercept_recovered <- function(fit, model_type, u_id, sd_id,
                                                  sd_tol = 0.30, cor_min = 0.45) {
  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$model$model_type, model_type)
  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_equal(fit$model$random$mu$n_terms, 1L)
  expect_equal(fit$model$random$mu$labels, "(1 | id)")
  expect_named(fit$sdpars$mu, "(1 | id)")
  expect_gt(unname(fit$sdpars$mu[["(1 | id)"]]), 0.05)
  expect_lt(abs(unname(fit$sdpars$mu[["(1 | id)"]]) - sd_id), sd_tol)

  id_effects <- fit$random_effects$mu$terms[["(1 | id)"]]
  expect_equal(length(id_effects), length(u_id))
  expect_gt(stats::cor(id_effects, u_id), cor_min)
  expect_true(drmTMB:::has_ordinary_mu_random_effects(fit))
  expect_equal(drmTMB:::n_mu_random_effect_terms(fit), 1L)
  expect_equal(
    predict(fit, dpar = "mu", type = "link"),
    as.vector(fit$model$X$mu %*% coef(fit, "mu")) +
      drmTMB:::mu_random_effect_contribution(fit),
    tolerance = 1e-8
  )

  targets <- profile_targets(fit)
  sd_target <- targets[targets$parm == "sd:mu:(1 | id)", , drop = FALSE]
  expect_equal(nrow(sd_target), 1L)
  expect_equal(sd_target$tmb_parameter, "log_sd_mu")
  expect_true(sd_target$profile_ready)

  chk <- check_drm(fit)
  replication <- chk[chk$check == "mu_random_effect_replication", ]
  expect_equal(replication$status, "ok")
}

test_that("skew_normal mu supports an ordinary random intercept", {
  set.seed(20260712)
  n_id <- 40L; n_each <- 14L
  id <- factor(rep(seq_len(n_id), each = n_each)); n <- length(id)
  dat <- data.frame(id = id, x = stats::rnorm(n), z = stats::rnorm(n))
  sd_id <- 0.7; u_id <- stats::rnorm(n_id, sd = sd_id); u_id <- u_id - mean(u_id)
  mu <- 0.2 + 0.6 * dat$x + u_id[id]
  sigma <- exp(-0.3 + 0.15 * dat$z); nu <- 1.6
  delta <- nu / sqrt(1 + nu^2); ms <- sqrt(2 / pi) * delta
  omega <- sigma / sqrt(1 - ms^2); xi <- mu - omega * ms
  dat$y <- xi + omega * (delta * abs(stats::rnorm(n)) + sqrt(1 - delta^2) * stats::rnorm(n))

  fit <- drmTMB(bf(y ~ x + (1 | id), sigma ~ z, nu ~ 1), family = skew_normal(), data = dat)
  expect_mu_random_intercept_recovered(fit, "skew_normal", u_id, sd_id)
  expect_error(
    drmTMB(bf(y ~ x + (1 + x | id), sigma ~ z, nu ~ 1), family = skew_normal(), data = dat),
    "random intercept"
  )
})

test_that("binomial mu supports an ordinary random intercept", {
  set.seed(55)
  n_id <- 50L; n_each <- 12L
  id <- factor(rep(seq_len(n_id), each = n_each)); n <- length(id)
  dat <- data.frame(id = id, x = stats::rnorm(n))
  sd_id <- 0.8; u_id <- stats::rnorm(n_id, sd = sd_id); u_id <- u_id - mean(u_id)
  p <- stats::plogis(-0.2 + 0.7 * dat$x + u_id[id]); trials <- stats::rpois(n, 8) + 3
  dat$succ <- stats::rbinom(n, trials, p); dat$fail <- trials - dat$succ

  fit <- drmTMB(bf(cbind(succ, fail) ~ x + (1 | id)), family = binomial(), data = dat)
  expect_mu_random_intercept_recovered(fit, "binomial", u_id, sd_id)
  expect_lt(max(abs(coef(fit, "mu") - c(-0.2, 0.7))), 0.30)
  expect_error(
    drmTMB(bf(cbind(succ, fail) ~ x + (1 + x | id)), family = binomial(), data = dat),
    "random intercept"
  )
})

test_that("zero_one_beta mu supports an ordinary random intercept", {
  set.seed(7)
  n_id <- 45L; n_each <- 16L
  id <- factor(rep(seq_len(n_id), each = n_each)); n <- length(id)
  dat <- data.frame(id = id, x = stats::rnorm(n))
  sd_id <- 0.6; u_id <- stats::rnorm(n_id, sd = sd_id); u_id <- u_id - mean(u_id)
  mu <- stats::plogis(0.3 + 0.7 * dat$x + u_id[id]); phi <- 1 / 0.4^2
  y <- stats::rbeta(n, mu * phi, (1 - mu) * phi)
  bound <- stats::runif(n) < 0.15
  y[bound] <- ifelse(stats::runif(sum(bound)) < 0.5, 1, 0); dat$y <- y

  fit <- drmTMB(bf(y ~ x + (1 | id)), family = zero_one_beta(), data = dat)
  expect_mu_random_intercept_recovered(fit, "zero_one_beta", u_id, sd_id)
  expect_error(
    drmTMB(bf(y ~ x + (1 + x | id)), family = zero_one_beta(), data = dat),
    "random intercept"
  )
})

test_that("cumulative_logit mu supports an ordinary random intercept", {
  set.seed(9)
  n_id <- 45L; n_each <- 18L
  id <- factor(rep(seq_len(n_id), each = n_each)); n <- length(id)
  dat <- data.frame(id = id, x = stats::rnorm(n))
  sd_id <- 0.7; u_id <- stats::rnorm(n_id, sd = sd_id); u_id <- u_id - mean(u_id)
  cut <- c(-1, 0, 1)
  lat <- 0.8 * dat$x + u_id[id] + stats::rlogis(n)
  dat$y <- ordered(findInterval(lat, cut) + 1L, levels = 1:4)

  fit <- drmTMB(bf(y ~ x + (1 | id)), family = cumulative_logit(), data = dat)
  expect_mu_random_intercept_recovered(fit, "cumulative_logit", u_id, sd_id, cor_min = 0.40)
  expect_error(
    drmTMB(bf(y ~ x + (1 + x | id)), family = cumulative_logit(), data = dat),
    "random intercept"
  )
})
