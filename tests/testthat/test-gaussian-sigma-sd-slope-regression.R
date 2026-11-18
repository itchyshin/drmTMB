gaussian_sigma_sd_slope_data <- function(
  n_group = 200L,
  n_each = 24L,
  alpha = c("(Intercept)" = log(0.2), w = 0.4),
  seed = 20261025L
) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_group), each = n_each))
  w_group <- seq(-1, 1, length.out = n_group)
  w <- w_group[as.integer(id)]
  z_group <- rep(seq(-1, 1, length.out = n_each), n_group)
  x <- stats::rnorm(length(id))
  eta_sd <- rep(alpha[["(Intercept)"]], n_group)
  if ("w" %in% names(alpha)) {
    eta_sd <- eta_sd + alpha[["w"]] * w_group
  }
  group_sd <- exp(eta_sd)
  u_group <- stats::rnorm(n_group, sd = group_sd)
  log_sigma <- u_group[as.integer(id)] * z_group

  list(
    data = data.frame(
      y = stats::rnorm(length(id), mean = 0.2 + 0.35 * x,
                       sd = exp(log_sigma)),
      x = x,
      z = z_group,
      w = w,
      id = id
    ),
    alpha = alpha,
    group_sd = group_sd
  )
}

test_that("Gaussian sigma slope SD regression recovers a group-level predictor", {
  sim <- gaussian_sigma_sd_slope_data()
  target <- 'sd(id, dpar = "sigma", coef = "z")'
  formula <- bf(
    y ~ x,
    sigma ~ 1 + (0 + z | id),
    sd(id, dpar = "sigma", coef = "z") ~ w
  )

  fit <- drmTMB(
    formula,
    family = stats::gaussian(),
    data = sim$data,
    control = drm_control(se_group_sd = TRUE, se_report_covariance = FALSE)
  )
  alpha_hat <- stats::coef(fit, dpar = target)
  group_sd_hat <- stats::predict(fit, dpar = target, type = "response")
  scale_contribution <- drmTMB:::sigma_random_effect_contribution(fit)
  expected_link <- as.vector(fit$model$tmb_data$X_sigma %*% coef(fit, "sigma")) +
    scale_contribution

  expect_equal(fit$opt$convergence, 0L)
  expect_true(isTRUE(fit$sdr$pdHess))
  expect_named(alpha_hat, names(sim$alpha))
  expect_equal(unname(alpha_hat), unname(sim$alpha), tolerance = 0.35)
  expect_named(group_sd_hat, levels(sim$data$id))
  expect_equal(unname(group_sd_hat), sim$group_sd, tolerance = 0.25)
  expect_equal(predict(fit, dpar = "sigma", type = "link"),
               expected_link, tolerance = 1e-10)
})

test_that("constant Gaussian sigma slope SD matches the constant-SD model", {
  sim <- gaussian_sigma_sd_slope_data(
    n_group = 60L,
    n_each = 16L,
    alpha = c("(Intercept)" = log(0.2)),
    seed = 20261026L
  )
  base_fit <- drmTMB(
    bf(y ~ x, sigma ~ 1 + (0 + z | id)),
    family = stats::gaussian(),
    data = sim$data
  )
  sd_fit <- drmTMB(
    bf(
      y ~ x,
      sigma ~ 1 + (0 + z | id),
      sd(id, dpar = "sigma", coef = "z") ~ 1
    ),
    family = stats::gaussian(),
    data = sim$data
  )

  expect_equal(as.numeric(stats::logLik(sd_fit)),
               as.numeric(stats::logLik(base_fit)), tolerance = 1e-7)
})

test_that("Gaussian sigma slope SD requires one matching, group-constant target", {
  sim <- gaussian_sigma_sd_slope_data(n_group = 24L, n_each = 8L)
  bad_data <- sim$data
  bad_data$w[[2L]] <- bad_data$w[[2L]] + 0.1

  expect_error(
    drmTMB(
      bf(
        y ~ x,
        sigma ~ 1 + (0 + z | id),
        sd(id, dpar = "sigma", coef = "z") ~ w
      ),
      family = stats::gaussian(),
      data = bad_data
    ),
    "varies within id level"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ x,
        sigma ~ 1 + (0 + z | id),
        sd(id, dpar = "sigma", coef = "x") ~ w
      ),
      family = stats::gaussian(),
      data = sim$data
    ),
    "No ordinary random-effect SD target matches group id"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ x,
        sigma ~ 1 + (0 + z | id) + (0 + x | id),
        sd(id, dpar = "sigma", coef = "z") ~ w
      ),
      family = stats::gaussian(),
      data = sim$data
    ),
    "one independent sigma random intercept or numeric random slope"
  )
})
