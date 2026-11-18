test_that("Zero-one Beta Julia bridge admits a matching mean-intercept or selected-slope SD route", {
  formula <- bf(
    y ~ x + (1 | id), sigma ~ 1, zoi ~ 1, coi ~ 1, sd(id) ~ z
  )
  expect_true(drm_julia_zero_one_beta_scalar_sd_route_admitted(formula))
  expect_no_error(
    drm_julia_refuse_fe_only_random_effects(formula, "zero_one_beta")
  )

  no_sd <- bf(y ~ x + (1 | id), sigma ~ 1, zoi ~ 1, coi ~ 1)
  expect_false(drm_julia_zero_one_beta_scalar_sd_route_admitted(no_sd))
  expect_error(
    drm_julia_refuse_fe_only_random_effects(no_sd, "zero_one_beta"),
    "fixed-effect"
  )

  random_sigma <- bf(
    y ~ x + (1 | id), sigma ~ (1 | id), zoi ~ 1, coi ~ 1, sd(id) ~ z
  )
  expect_false(
    drm_julia_zero_one_beta_scalar_sd_route_admitted(random_sigma)
  )
  random_zoi <- bf(
    y ~ x + (1 | id), sigma ~ 1, zoi ~ (1 | id), coi ~ 1, sd(id) ~ z
  )
  expect_false(drm_julia_zero_one_beta_scalar_sd_route_admitted(random_zoi))

  slope <- bf(
    y ~ x + (0 + x | id), sigma ~ 1, zoi ~ 1, coi ~ 1,
    sd(id, coef = "x") ~ z
  )
  expect_true(drm_julia_zero_one_beta_scalar_sd_route_admitted(slope))
  expect_no_error(
    drm_julia_refuse_fe_only_random_effects(slope, "zero_one_beta")
  )

  unselected_slope <- bf(
    y ~ x + (0 + x | id), sigma ~ 1, zoi ~ 1, coi ~ 1, sd(id) ~ z
  )
  expect_false(
    drm_julia_zero_one_beta_scalar_sd_route_admitted(unselected_slope)
  )
  wrong_slope <- bf(
    y ~ x + (0 + x | id), sigma ~ 1, zoi ~ 1, coi ~ 1,
    sd(id, coef = "other") ~ z
  )
  expect_false(drm_julia_zero_one_beta_scalar_sd_route_admitted(wrong_slope))

  wrong_group <- bf(
    y ~ x + (1 | id), sigma ~ 1, zoi ~ 1, coi ~ 1, sd(other) ~ z
  )
  expect_false(drm_julia_zero_one_beta_scalar_sd_route_admitted(wrong_group))

  structured <- bf(
    y ~ x + (1 | id) + phylo(1 | species, tree = tree),
    sigma ~ 1, zoi ~ 1, coi ~ 1, sd(id) ~ z
  )
  expect_false(drm_julia_zero_one_beta_scalar_sd_route_admitted(structured))
})

zero_one_beta_sd_bridge_data <- function(groups = 60L, repeats = 15L,
                                         seed = 20261020L) {
  set.seed(seed)
  group_index <- rep(seq_len(groups), each = repeats)
  z_group <- rep(c(-1, 1), each = groups / 2L)
  z <- z_group[group_index]
  x <- stats::rnorm(length(group_index))
  alpha <- c("(Intercept)" = -0.75, z = 0.40)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z_group)
  b <- stats::rnorm(groups, sd = tau)
  mu <- stats::plogis(-0.25 + 0.20 * x + b[group_index])
  sigma <- 0.50
  zoi <- 0.12
  coi <- 0.60
  y <- stats::rbeta(
    length(group_index),
    shape1 = mu / sigma^2,
    shape2 = (1 - mu) / sigma^2
  )
  boundary <- stats::runif(length(group_index)) < zoi
  y[boundary] <- stats::rbinom(sum(boundary), size = 1, prob = coi)
  list(
    data = data.frame(y, x, z, id = factor(group_index)),
    alpha = alpha,
    groups = groups
  )
}

test_that("Zero-one Beta mean-intercept SD regression runs through both engines", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  sim <- zero_one_beta_sd_bridge_data()
  formula <- bf(
    y ~ x + (1 | id), sigma ~ 1, zoi ~ 1, coi ~ 1, sd(id) ~ z
  )
  fit_tmb <- drmTMB(
    formula, family = zero_one_beta(), data = sim$data, engine = "tmb"
  )
  fit_julia <- drmTMB(
    formula, family = zero_one_beta(), data = sim$data, engine = "julia"
  )

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  tmb_sd <- coef(fit_tmb, dpar = "sd(id)")
  julia_sd <- coef(fit_julia, dpar = "sd(id)")
  expect_named(julia_sd, names(tmb_sd))
  expect_lt(abs(unname(julia_sd[["z"]] - sim$alpha[["z"]])), 0.60)
  expect_lt(abs(unname(tmb_sd[["z"]] - sim$alpha[["z"]])), 0.60)
  expect_equal(unname(julia_sd), unname(tmb_sd), tolerance = 0.40)
  expect_length(fit_julia$sdpars[["sd(id)"]], sim$groups)
  expect_equal(
    unname(fit_julia$sdpars[["sd(id)"]]),
    unname(predict(fit_julia, dpar = "sd(id)")),
    tolerance = 1e-10
  )
  rows <- c(7L, 2L, 13L, 1L)
  expect_equal(
    unname(predict(fit_julia, newdata = sim$data[rows, ], dpar = "sd(id)")),
    unname(fit_julia$sdpars[["sd(id)"]])[as.integer(sim$data$id[rows])],
    tolerance = 1e-10
  )

  save_path <- tempfile(fileext = ".rds")
  saveRDS(fit_julia, save_path)
  restored <- readRDS(save_path)
  expect_equal(restored$sdpars[["sd(id)"]], fit_julia$sdpars[["sd(id)"]])
  expect_equal(predict(restored, dpar = "sd(id)"),
               predict(fit_julia, dpar = "sd(id)"))
  unlink(save_path)
})

zero_one_beta_sd_slope_bridge_data <- function(groups = 40L, repeats = 30L,
                                               seed = 20261021L) {
  set.seed(seed)
  group <- rep(seq_len(groups), each = repeats)
  z_group <- rep(c(-1, 1), each = groups / 2L)
  z <- z_group[group]
  x <- stats::rnorm(length(group))
  tau <- exp(-0.55 + 0.35 * z_group)
  b <- stats::rnorm(groups, sd = tau)
  mu <- stats::plogis(0.15 + 0.3 * x + x * b[group])
  sigma <- 0.35
  phi <- 1 / sigma^2
  zoi <- 0.22
  coi <- 0.40
  y <- stats::rbeta(length(group), mu * phi, (1 - mu) * phi)
  boundary <- stats::runif(length(group)) < zoi
  y[boundary] <- stats::rbinom(sum(boundary), size = 1L, prob = coi)
  list(
    data = data.frame(y, x, z, id = factor(group)),
    alpha = c("(Intercept)" = -0.55, z = 0.35),
    groups = groups
  )
}

test_that("Zero-one Beta selected-slope SD fits and predicts through both engines", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  sim <- zero_one_beta_sd_slope_bridge_data()
  target <- 'sd(id, coef = "x")'
  formula <- bf(
    y ~ x + (0 + x | id), sigma ~ 1, zoi ~ 1, coi ~ 1,
    sd(id, coef = "x") ~ z
  )
  fit_tmb <- drmTMB(
    formula, family = zero_one_beta(), data = sim$data, engine = "tmb"
  )
  fit_julia <- drmTMB(
    formula, family = zero_one_beta(), data = sim$data, engine = "julia"
  )

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  tmb_sd <- coef(fit_tmb, dpar = target)
  julia_sd <- coef(fit_julia, dpar = target)
  expect_named(julia_sd, names(tmb_sd))
  expect_true(all(is.finite(julia_sd)))
  expect_true(all(is.finite(tmb_sd)))
  expect_lt(abs(unname(julia_sd[["z"]] - sim$alpha[["z"]])), 0.75)
  expect_lt(abs(unname(tmb_sd[["z"]] - sim$alpha[["z"]])), 0.75)
  expect_equal(unname(julia_sd[["z"]]), unname(tmb_sd[["z"]]), tolerance = 0.75)
  expect_length(fit_julia$sdpars[[target]], sim$groups)
  expect_equal(
    unname(fit_julia$sdpars[[target]]),
    unname(predict(fit_julia, dpar = target)),
    tolerance = 1e-10
  )
  expect_length(fit_tmb$sdpars[[target]], sim$groups)
  expect_true(all(is.finite(fit_tmb$sdpars[[target]])))
})
