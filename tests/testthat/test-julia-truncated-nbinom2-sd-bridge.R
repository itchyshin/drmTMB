truncated_nbinom2_sd_bridge_data <- function(seed = 20261031L) {
  set.seed(seed)
  n_group <- 56L
  n_each <- 24L
  group_index <- rep(seq_len(n_group), each = n_each)
  z_group <- seq(-1, 1, length.out = n_group)
  z <- z_group[group_index]
  x <- stats::rnorm(length(group_index))
  alpha <- c(`(Intercept)` = -0.55, z = 0.55)
  b <- exp(alpha[[1L]] + alpha[[2L]] * z_group) * stats::rnorm(n_group)
  mu <- exp(0.25 + 0.4 * x + b[group_index] * x)
  sigma <- 0.5
  size <- 1 / sigma^2
  p0 <- stats::pnbinom(0, size = size, mu = mu)
  positive_probability <- p0 + stats::runif(length(mu)) * (1 - p0)
  count <- stats::qnbinom(positive_probability, size = size, mu = mu)
  stopifnot(all(is.finite(count)), all(count >= 1))
  list(
    data = data.frame(
      count = count, x = x, z = z, id = factor(group_index)
    ),
    alpha = alpha,
    target = 'sd(id, coef = "x")',
    formula = bf(
      count ~ x + (0 + x | id), sigma ~ 1,
      sd(id, coef = "x") ~ z
    )
  )
}

test_that("zero-truncated NB2 Julia bridge admits only a matching ordinary slope SD route", {
  sim <- truncated_nbinom2_sd_bridge_data()
  expect_invisible(drmTMB:::drm_julia_refuse_fe_only_random_effects(
    sim$formula, "truncated_nbinom2", data = sim$data
  ))

  wrong_target <- bf(
    count ~ x + (0 + x | id), sigma ~ 1,
    sd(other, coef = "x") ~ z
  )
  expect_error(
    drmTMB:::drm_julia_refuse_fe_only_random_effects(
      wrong_target, "truncated_nbinom2", data = sim$data
    ),
    "fixed-effect.*route"
  )

  hurdle <- bf(
    count ~ x + (0 + x | id), sigma ~ 1, hu ~ 1,
    sd(id, coef = "x") ~ z
  )
  expect_false(drmTMB:::drm_julia_truncated_nbinom2_scalar_sd_route_admitted(
    hurdle, data = sim$data
  ))
  expect_invisible(drmTMB:::drm_julia_refuse_fe_only_random_effects(
    hurdle, "truncated_nbinom2", data = sim$data
  ))

  offset_formula <- bf(
    count ~ x + offset(log(exposure)) + (0 + x | id), sigma ~ 1,
    sd(id, coef = "x") ~ z
  )
  expect_false(drmTMB:::drm_julia_truncated_nbinom2_scalar_sd_route_admitted(
    offset_formula, data = sim$data
  ))
  expect_error(
    drmTMB:::drm_julia_refuse_fe_only_random_effects(
      offset_formula, "truncated_nbinom2", data = sim$data
    ),
    "fixed-effect.*route"
  )

  factor_slope_data <- sim$data
  factor_slope_data$x <- factor(ifelse(factor_slope_data$x > 0, "high", "low"))
  expect_error(
    drmTMB:::drm_julia_refuse_fe_only_random_effects(
      sim$formula, "truncated_nbinom2", data = factor_slope_data
    ),
    "fixed-effect.*route"
  )
})

test_that("zero-truncated NB2 selected slope SD bridges to Julia", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  sim <- truncated_nbinom2_sd_bridge_data()
  fit_tmb <- drmTMB(
    sim$formula, family = truncated_nbinom2(), data = sim$data,
    engine = "tmb"
  )
  fit_julia <- drmTMB(
    sim$formula, family = truncated_nbinom2(), data = sim$data,
    engine = "julia"
  )
  tmb_sd <- coef(fit_tmb, dpar = sim$target)
  julia_sd <- coef(fit_julia, dpar = sim$target)

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_identical(fit_julia$model$model_type, "truncated_nbinom2")
  expect_identical(fit_julia$model$dpars, c("mu", "sd", "sigma"))
  expect_named(tmb_sd, c("(Intercept)", "z"))
  expect_named(julia_sd, names(tmb_sd))
  expect_gt(unname(tmb_sd[["z"]]), 0)
  expect_gt(unname(julia_sd[["z"]]), 0)
  expect_lt(abs(unname(tmb_sd[["z"]] - sim$alpha[["z"]])), 0.55)
  expect_lt(abs(unname(julia_sd[["z"]] - sim$alpha[["z"]])), 0.7)
  expect_lt(abs(unname(julia_sd[["z"]] - tmb_sd[["z"]])), 0.7)

  tmb_group_sd <- predict(fit_tmb, dpar = sim$target)
  julia_group_sd <- predict(fit_julia, dpar = sim$target)
  expect_length(tmb_group_sd, nlevels(sim$data$id))
  expect_length(julia_group_sd, nlevels(sim$data$id))
  expect_true(all(is.finite(tmb_group_sd) & tmb_group_sd > 0))
  expect_true(all(is.finite(julia_group_sd) & julia_group_sd > 0))
})
