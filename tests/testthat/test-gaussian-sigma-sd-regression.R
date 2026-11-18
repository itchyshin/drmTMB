gaussian_sigma_sd_regression_data <- function(
  n_group = 240L,
  n_each = 24L,
  alpha = c("(Intercept)" = log(0.20), w = 0.45),
  seed = 20261022L
) {
  set.seed(seed)
  group <- factor(rep(seq_len(n_group), each = n_each))
  w_group <- seq(-1, 1, length.out = n_group)
  w <- w_group[as.integer(group)]
  x <- stats::rnorm(length(group))
  eta_sd <- rep(alpha[["(Intercept)"]], n_group)
  if ("w" %in% names(alpha)) {
    eta_sd <- eta_sd + alpha[["w"]] * w_group
  }
  group_sd <- exp(eta_sd)
  random_log_sigma <- stats::rnorm(n_group, sd = group_sd)
  sigma <- exp(random_log_sigma[as.integer(group)])
  mu <- 0.2 + 0.5 * x

  list(
    data = data.frame(
      y = stats::rnorm(length(group), mean = mu, sd = sigma),
      x = x,
      w = w,
      id = group
    ),
    alpha = alpha,
    group_sd = group_sd
  )
}

test_that("Gaussian sigma random-intercept SD regression recovers its predictor", {
  sim <- gaussian_sigma_sd_regression_data()
  target <- 'sd(id, dpar = "sigma")'
  formula <- bf(
    y ~ x,
    sigma ~ 1 + (1 | id),
    sd(id, dpar = "sigma") ~ w
  )

  fit <- drmTMB(
    formula,
    family = stats::gaussian(),
    data = sim$data,
    control = drm_control(se_group_sd = TRUE, se_report_covariance = FALSE)
  )
  alpha_hat <- stats::coef(fit, dpar = target)
  group_sd_hat <- stats::predict(fit, dpar = target, type = "response")
  sigma_hat <- stats::predict(fit, dpar = "sigma", type = "response")
  reported_group_sd <- fit$sdr$value[
    grepl("^sd_sigma_group", names(fit$sdr$value))
  ]

  expect_equal(fit$opt$convergence, 0L)
  expect_true(isTRUE(fit$sdr$pdHess))
  expect_named(alpha_hat, names(sim$alpha))
  expect_equal(unname(alpha_hat), unname(sim$alpha), tolerance = 0.30)
  expect_length(group_sd_hat, nlevels(sim$data$id))
  expect_named(group_sd_hat, levels(sim$data$id))
  expect_true(all(is.finite(group_sd_hat) & group_sd_hat > 0))
  expect_equal(unname(group_sd_hat), sim$group_sd, tolerance = 0.20)
  expect_length(sigma_hat, nrow(sim$data))
  expect_true(all(is.finite(sigma_hat) & sigma_hat > 0))
  expect_length(reported_group_sd, nlevels(sim$data$id))
  expect_equal(unname(reported_group_sd), unname(group_sd_hat), tolerance = 1e-8)
})

test_that("constant Gaussian sigma SD regression matches the constant-SD model", {
  sim <- gaussian_sigma_sd_regression_data(
    n_group = 50L,
    n_each = 12L,
    alpha = c("(Intercept)" = log(0.25)),
    seed = 20261023L
  )
  base_fit <- drmTMB(
    bf(y ~ x, sigma ~ 1 + (1 | id)),
    family = stats::gaussian(),
    data = sim$data
  )
  sd_fit <- drmTMB(
    bf(
      y ~ x,
      sigma ~ 1 + (1 | id),
      sd(id, dpar = "sigma") ~ 1
    ),
    family = stats::gaussian(),
    data = sim$data
  )

  expect_equal(as.numeric(stats::logLik(sd_fit)),
               as.numeric(stats::logLik(base_fit)), tolerance = 1e-7)
  expect_equal(
    unname(stats::predict(sd_fit, dpar = 'sd(id, dpar = "sigma")', type = "response")),
    rep(exp(stats::coef(sd_fit, dpar = 'sd(id, dpar = "sigma")')[["(Intercept)"]]),
        nlevels(sim$data$id)),
    tolerance = 1e-8
  )
})

test_that("Gaussian sigma SD predictors must be constant within group", {
  sim <- gaussian_sigma_sd_regression_data(n_group = 24L, n_each = 4L)
  sim$data$w[[2L]] <- sim$data$w[[2L]] + 0.1

  expect_error(
    drmTMB(
      bf(
        y ~ x,
        sigma ~ 1 + (1 | id),
        sd(id, dpar = "sigma") ~ w
      ),
      family = stats::gaussian(),
      data = sim$data
    ),
    "varies within id level"
  )
})
