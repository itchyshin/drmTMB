beta_binomial_sd_parity_data <- function(groups = 60L, repeats = 24L,
                                         trials = 12L, seed = 20261024L,
                                         effect = c("slope", "intercept")) {
  effect <- match.arg(effect)
  set.seed(seed)
  group_index <- rep(seq_len(groups), each = repeats)
  group <- factor(group_index)
  z_group <- rep(c(-1, 1), each = groups / 2L)
  z <- z_group[group_index]
  x <- stats::rnorm(length(group_index))
  alpha <- c("(Intercept)" = log(0.35), z = 0.45)
  random_effect <- stats::rnorm(
    groups, sd = exp(alpha[[1L]] + alpha[[2L]] * z_group)
  )
  re_contribution <- if (effect == "intercept") {
    random_effect[group_index]
  } else {
    random_effect[group_index] * x
  }
  mu <- stats::plogis(-0.1 + 0.55 * x + re_contribution)
  sigma <- 0.22
  precision <- 1 / sigma^2
  probability <- stats::rbeta(
    length(mu), shape1 = mu * precision, shape2 = (1 - mu) * precision
  )
  successes <- stats::rbinom(length(mu), size = trials, prob = probability)
  list(
    data = data.frame(
      success = successes,
      failure = trials - successes,
      x = x,
      z = z,
      group = group
    ),
    alpha = alpha,
    groups = groups
  )
}

test_that("Julia beta-binomial SD admission is limited to its implemented shape", {
  sim <- beta_binomial_sd_parity_data()
  admitted <- function(formula) {
    drmTMB:::drm_julia_beta_binomial_scalar_sd_route_admitted(
      formula, data = sim$data
    )
  }
  ordinary_intercept <- bf(
    cbind(success, failure) ~ 1 + x + (1 | group),
    sigma ~ 1,
    sd(group) ~ z
  )
  ordinary_slope <- bf(
    cbind(success, failure) ~ 1 + x + (0 + x | group),
    sigma ~ 1,
    sd(group, coef = "x") ~ z
  )
  expect_true(admitted(ordinary_intercept))
  expect_true(admitted(ordinary_slope))

  no_sd <- bf(cbind(success, failure) ~ 1 + x + (1 | group), sigma ~ 1)
  mismatched_group <- bf(
    cbind(success, failure) ~ 1 + x + (0 + x | group),
    sigma ~ 1,
    sd(other, coef = "x") ~ z
  )
  correlated <- bf(
    cbind(success, failure) ~ 1 + x + (1 + x | group),
    sigma ~ 1,
    sd(group) ~ z
  )
  predictor_sigma <- bf(
    cbind(success, failure) ~ 1 + x + (1 | group),
    sigma ~ z,
    sd(group) ~ z
  )
  random_sigma <- bf(
    cbind(success, failure) ~ 1 + x + (1 | group),
    sigma ~ 1 + (1 | group),
    sd(group) ~ z
  )
  expect_false(admitted(no_sd))
  expect_false(admitted(mismatched_group))
  expect_false(admitted(correlated))
  expect_false(admitted(predictor_sigma))
  expect_false(admitted(random_sigma))
  expect_error(
    drmTMB:::drm_julia_refuse_fe_only_random_effects(
      correlated, "beta_binomial", data = sim$data
    ),
    "only on the.*fixed-effect"
  )
})

test_that("beta-binomial predictor-dependent slope SD agrees across engines", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  sim <- beta_binomial_sd_parity_data()
  formula <- bf(
    cbind(success, failure) ~ 1 + x + (0 + x | group),
    sigma ~ 1,
    sd(group, coef = "x") ~ z
  )
  sd_dpar <- "sd(group, coef = \"x\")"
  fit_tmb <- drmTMB(
    formula,
    family = beta_binomial(),
    data = sim$data,
    engine = "tmb",
    control = drm_control(se = FALSE)
  )
  fit_julia <- drmTMB(
    formula,
    family = beta_binomial(),
    data = sim$data,
    engine = "julia"
  )

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  tmb_coef <- coef(fit_tmb, dpar = sd_dpar)
  julia_coef <- coef(fit_julia, dpar = sd_dpar)
  expect_named(tmb_coef, c("(Intercept)", "z"))
  expect_named(julia_coef, names(tmb_coef))
  expect_gt(tmb_coef[["z"]], 0)
  expect_gt(julia_coef[["z"]], 0)
  expect_lt(abs(tmb_coef[["z"]] - sim$alpha[["z"]]), 0.55)
  expect_lt(abs(julia_coef[["z"]] - sim$alpha[["z"]]), 0.55)
  expect_equal(unname(julia_coef), unname(tmb_coef), tolerance = 0.45)

  tmb_output <- predict_parameters(
    fit_tmb, dpar = sd_dpar, include_newdata = FALSE
  )
  julia_output <- predict_parameters(
    fit_julia, dpar = sd_dpar, include_newdata = FALSE
  )
  expect_identical(unique(tmb_output$dpar), unique(julia_output$dpar))
  expect_identical(unique(tmb_output$component), unique(julia_output$component))
  expect_setequal(tmb_output$row_label, julia_output$row_label)
  tmb_order <- match(julia_output$row_label, tmb_output$row_label)
  expect_false(anyNA(tmb_order))
  expect_equal(
    julia_output$estimate,
    tmb_output$estimate[tmb_order],
    tolerance = 0.45
  )
  expect_length(fit_tmb$sdpars[[sd_dpar]], sim$groups)
  expect_length(fit_julia$sdpars[[sd_dpar]], sim$groups)
  expect_true(all(is.finite(fit_tmb$sdpars[[sd_dpar]]) &
                  fit_tmb$sdpars[[sd_dpar]] > 0))
  expect_true(all(is.finite(fit_julia$sdpars[[sd_dpar]]) &
                  fit_julia$sdpars[[sd_dpar]] > 0))
})

test_that("beta-binomial predictor-dependent intercept SD agrees across engines", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  sim <- beta_binomial_sd_parity_data(effect = "intercept")
  formula <- bf(
    cbind(success, failure) ~ 1 + x + (1 | group),
    sigma ~ 1,
    sd(group) ~ z
  )
  sd_dpar <- "sd(group)"
  fit_tmb <- drmTMB(
    formula,
    family = beta_binomial(),
    data = sim$data,
    engine = "tmb",
    control = drm_control(se = FALSE)
  )
  fit_julia <- drmTMB(formula, family = beta_binomial(), data = sim$data,
                      engine = "julia")

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  tmb_coef <- coef(fit_tmb, dpar = sd_dpar)
  julia_coef <- coef(fit_julia, dpar = sd_dpar)
  expect_named(tmb_coef, c("(Intercept)", "z"))
  expect_equal(unname(julia_coef), unname(tmb_coef), tolerance = 0.45)
  expect_gt(tmb_coef[["z"]], 0)
  expect_gt(julia_coef[["z"]], 0)
  expect_lt(abs(tmb_coef[["z"]] - sim$alpha[["z"]]), 0.55)
  expect_lt(abs(julia_coef[["z"]] - sim$alpha[["z"]]), 0.55)
  tmb_output <- predict_parameters(
    fit_tmb, dpar = sd_dpar, include_newdata = FALSE
  )
  julia_output <- predict_parameters(
    fit_julia, dpar = sd_dpar, include_newdata = FALSE
  )
  expect_setequal(tmb_output$row_label, julia_output$row_label)
  tmb_order <- match(julia_output$row_label, tmb_output$row_label)
  expect_equal(julia_output$estimate, tmb_output$estimate[tmb_order],
               tolerance = 0.45)
  expect_length(fit_tmb$sdpars[[sd_dpar]], sim$groups)
  expect_length(fit_julia$sdpars[[sd_dpar]], sim$groups)
})
