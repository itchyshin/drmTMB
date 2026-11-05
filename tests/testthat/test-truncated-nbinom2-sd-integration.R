truncated_nbinom2_sd_data <- function(
  groups = 180L,
  repeats = 20L,
  sd_coef = c("(Intercept)" = -0.7, w = 0.35),
  seed = 20261025L
) {
  set.seed(seed)
  group <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[group]
  x <- stats::rnorm(length(group))
  tau <- exp(sd_coef[["(Intercept)"]] + sd_coef[["w"]] * w_group)
  b <- stats::rnorm(groups, sd = tau)
  mu <- exp(0.25 + 0.30 * x + b[group])
  sigma <- 0.55
  size <- 1 / sigma^2
  p0 <- stats::dnbinom(0, size = size, mu = mu)
  count <- as.integer(stats::qnbinom(
    p0 + stats::runif(length(group)) * (1 - p0),
    size = size,
    mu = mu
  ))
  count[count < 1L] <- 1L
  data.frame(count, x, w, id = factor(group))
}

truncated_nbinom2_sd_quadrature_loglik <- function(
  fit,
  data,
  reverse_sd = FALSE
) {
  beta_mu <- stats::coef(fit, dpar = "mu")
  beta_sigma <- stats::coef(fit, dpar = "sigma")
  beta_sd <- stats::coef(fit, dpar = "sd(id)")
  w_group <- vapply(levels(data$id), function(level) {
    unique(data$w[data$id == level])[[1L]]
  }, numeric(1L))
  tau <- exp(beta_sd[["(Intercept)"]] + beta_sd[["w"]] * w_group)
  if (reverse_sd) tau <- rev(tau)
  groups <- split(seq_len(nrow(data)), data$id, drop = TRUE)
  vapply(seq_along(groups), function(g) {
    index <- groups[[g]]
    y <- data$count[index]
    eta_fixed <- beta_mu[["(Intercept)"]] + beta_mu[["x"]] * data$x[index]
    log_integrand <- function(u) {
      eta <- eta_fixed + tau[[g]] * u
      mu <- exp(eta)
      size <- exp(-2 * beta_sigma[["(Intercept)"]])
      log_p0 <- stats::dnbinom(0, size = size, mu = mu, log = TRUE)
      log_trunc_prob <- ifelse(
        log_p0 < -log(2),
        log1p(-exp(log_p0)),
        log(-expm1(log_p0))
      )
      sum(stats::dnbinom(y, size = size, mu = mu, log = TRUE) -
            log_trunc_prob) + stats::dnorm(u, log = TRUE)
    }
    mode <- stats::optimize(
      function(u) -log_integrand(u),
      interval = c(-8, 8)
    )$minimum
    shift <- log_integrand(mode)
    area <- stats::integrate(
      function(u) exp(vapply(u, log_integrand, numeric(1L)) - shift),
      lower = -8,
      upper = 8,
      rel.tol = 1e-8,
      subdivisions = 300L
    )$value
    shift + log(area)
  }, numeric(1L))
}

truncated_nbinom2_slope_sd_data <- function(
  groups = 70L,
  repeats = 12L,
  sd_coef = c("(Intercept)" = -0.55, w = 0.55),
  seed = 20261027L
) {
  set.seed(seed)
  group <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[group]
  x <- stats::rnorm(length(group))
  tau <- exp(sd_coef[["(Intercept)"]] + sd_coef[["w"]] * w_group)
  b <- stats::rnorm(groups, sd = tau)
  mu <- exp(0.25 + 0.4 * x + b[group] * x)
  sigma <- 0.5
  size <- 1 / sigma^2
  p0 <- stats::dnbinom(0, size = size, mu = mu)
  count <- as.integer(stats::qnbinom(
    p0 + stats::runif(length(group)) * (1 - p0),
    size = size,
    mu = mu
  ))
  count[count < 1L] <- 1L
  data.frame(count, x, w, id = factor(group))
}

truncated_nbinom2_slope_sd_quadrature_loglik <- function(
  fit,
  data,
  reverse_sd = FALSE
) {
  beta_mu <- stats::coef(fit, dpar = "mu")
  beta_sigma <- stats::coef(fit, dpar = "sigma")
  beta_sd <- stats::coef(fit, dpar = 'sd(id, coef = "x")')
  w_group <- vapply(levels(data$id), function(level) {
    unique(data$w[data$id == level])[[1L]]
  }, numeric(1L))
  tau <- exp(beta_sd[["(Intercept)"]] + beta_sd[["w"]] * w_group)
  if (reverse_sd) tau <- rev(tau)
  groups <- split(seq_len(nrow(data)), data$id, drop = TRUE)
  vapply(seq_along(groups), function(g) {
    index <- groups[[g]]
    y <- data$count[index]
    x <- data$x[index]
    eta_fixed <- beta_mu[["(Intercept)"]] + beta_mu[["x"]] * x
    log_integrand <- function(u) {
      mu <- exp(eta_fixed + tau[[g]] * x * u)
      size <- exp(-2 * beta_sigma[["(Intercept)"]])
      log_p0 <- stats::dnbinom(0, size = size, mu = mu, log = TRUE)
      log_trunc_prob <- ifelse(
        log_p0 < -log(2),
        log1p(-exp(log_p0)),
        log(-expm1(log_p0))
      )
      sum(stats::dnbinom(y, size = size, mu = mu, log = TRUE) -
            log_trunc_prob) + stats::dnorm(u, log = TRUE)
    }
    mode <- stats::optimize(
      function(u) -log_integrand(u),
      interval = c(-8, 8)
    )$minimum
    shift <- log_integrand(mode)
    area <- stats::integrate(
      function(u) exp(vapply(u, log_integrand, numeric(1L)) - shift),
      lower = -8,
      upper = 8,
      rel.tol = 1e-8,
      subdivisions = 300L
    )$value
    shift + log(area)
  }, numeric(1L))
}

test_that("truncated NB2 SD regression recovers and preserves target outputs", {
  dat <- truncated_nbinom2_sd_data()
  control <- drm_control(se = FALSE)
  fit <- drmTMB(
    bf(count ~ 1 + x + (1 | id), sigma ~ 1, sd(id) ~ w),
    family = truncated_nbinom2(),
    data = dat,
    control = control
  )

  expect_true(is_converged(fit))
  expect_identical(fit$model$random_scale$mu$target_identity[["sd(id)"]]$group,
                   "id")
  estimate <- stats::coef(fit, dpar = "sd(id)")
  expect_lt(abs(estimate[["w"]] - 0.35), 0.25)
  predicted_sd <- stats::predict(
    fit,
    newdata = data.frame(
      w = c(-1, 0, 1),
      id = factor(levels(dat$id)[1L], levels = levels(dat$id))
    ),
    dpar = "sd(id)"
  )
  expect_true(all(diff(as.numeric(predicted_sd)) > 0))

  quadrature <- truncated_nbinom2_sd_quadrature_loglik(fit, dat)
  expect_lt(abs(sum(quadrature) - as.numeric(stats::logLik(fit))), 3)
  wrong_index <- truncated_nbinom2_sd_quadrature_loglik(
    fit,
    dat,
    reverse_sd = TRUE
  )
  expect_gt(abs(sum(wrong_index) - sum(quadrature)), 1)

  constant <- drmTMB(
    bf(count ~ 1 + x + (1 | id), sigma ~ 1, sd(id) ~ 1),
    family = truncated_nbinom2(),
    data = dat,
    control = control
  )
  baseline <- drmTMB(
    bf(count ~ 1 + x + (1 | id), sigma ~ 1),
    family = truncated_nbinom2(),
    data = dat,
    control = control
  )
  expect_equal(
    as.numeric(stats::logLik(constant)),
    as.numeric(stats::logLik(baseline)),
    tolerance = 1e-6
  )

  simulated <- stats::simulate(fit, nsim = 1L, seed = 20261026L)
  expect_length(simulated[[1L]], nrow(dat))
  restored_path <- tempfile(fileext = ".rds")
  saveRDS(fit, restored_path)
  restored <- readRDS(restored_path)
  expect_identical(
    restored$model$random_scale$mu$target_identity,
    fit$model$random_scale$mu$target_identity
  )
  expect_equal(
    stats::predict(restored, dpar = "sd(id)"),
    stats::predict(fit, dpar = "sd(id)")
  )
})

test_that("truncated NB2 independent-slope SD regression recovers and matches quadrature", {
  dat <- truncated_nbinom2_slope_sd_data()
  control <- drm_control(se = FALSE)
  sd_dpar <- 'sd(id, coef = "x")'
  fit <- drmTMB(
    bf(
      count ~ 1 + x + (0 + x | id),
      sigma ~ 1,
      sd(id, coef = "x") ~ w
    ),
    family = truncated_nbinom2(),
    data = dat,
    control = control
  )

  expect_true(is_converged(fit))
  estimate <- stats::coef(fit, dpar = sd_dpar)
  expect_lt(abs(estimate[["w"]] - 0.55), 0.4)
  predicted_sd <- stats::predict(
    fit,
    newdata = data.frame(
      w = c(-1, 0, 1),
      id = factor(levels(dat$id)[1L], levels = levels(dat$id))
    ),
    dpar = sd_dpar
  )
  expect_true(all(diff(as.numeric(predicted_sd)) > 0))

  quadrature <- truncated_nbinom2_slope_sd_quadrature_loglik(fit, dat)
  expect_lt(abs(sum(quadrature) - as.numeric(stats::logLik(fit))), 5)
  wrong_index <- truncated_nbinom2_slope_sd_quadrature_loglik(
    fit,
    dat,
    reverse_sd = TRUE
  )
  expect_gt(abs(sum(wrong_index) - sum(quadrature)), 1)

  constant <- drmTMB(
    bf(count ~ 1 + x + (0 + x | id), sigma ~ 1, sd(id, coef = "x") ~ 1),
    family = truncated_nbinom2(),
    data = dat,
    control = control
  )
  baseline <- drmTMB(
    bf(count ~ 1 + x + (0 + x | id), sigma ~ 1),
    family = truncated_nbinom2(),
    data = dat,
    control = control
  )
  expect_equal(
    as.numeric(stats::logLik(constant)),
    as.numeric(stats::logLik(baseline)),
    tolerance = 1e-6
  )
})
