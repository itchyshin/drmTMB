test_that("Tweedie Julia bridge admits only one matching ordinary mean SD target", {
  intercept <- bf(
    y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ w
  )
  expect_true(drm_julia_tweedie_scalar_sd_route_admitted(intercept))
  expect_no_error(drm_julia_refuse_fe_only_random_effects(intercept, "tweedie"))

  slope <- bf(
    y ~ x + (0 + x | id), sigma ~ z, nu ~ 1,
    sd(id, dpar = "mu", coef = "x") ~ w
  )
  expect_true(drm_julia_tweedie_scalar_sd_route_admitted(slope))
  expect_no_error(drm_julia_refuse_fe_only_random_effects(slope, "tweedie"))

  no_sd <- bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1)
  expect_false(drm_julia_tweedie_scalar_sd_route_admitted(no_sd))
  expect_error(
    drm_julia_refuse_fe_only_random_effects(no_sd, "tweedie"),
    "fixed-effect"
  )

  wrong_group <- bf(
    y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
    sd(other, coef = "x") ~ w
  )
  expect_false(drm_julia_tweedie_scalar_sd_route_admitted(wrong_group))

  wrong_coefficient <- bf(
    y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
    sd(id, coef = "other") ~ w
  )
  expect_false(drm_julia_tweedie_scalar_sd_route_admitted(wrong_coefficient))

  correlated <- bf(
    y ~ x + (1 + x | id), sigma ~ 1, nu ~ 1,
    sd(id, coef = "x") ~ w
  )
  expect_false(drm_julia_tweedie_scalar_sd_route_admitted(correlated))

  multiple_terms <- bf(
    y ~ x + (1 | id) + (0 + x | id), sigma ~ 1, nu ~ 1,
    sd(id, coef = "x") ~ w
  )
  expect_false(drm_julia_tweedie_scalar_sd_route_admitted(multiple_terms))

  random_sigma <- bf(
    y ~ x + (0 + x | id), sigma ~ (1 | id), nu ~ 1,
    sd(id, coef = "x") ~ w
  )
  expect_false(drm_julia_tweedie_scalar_sd_route_admitted(random_sigma))

  predictor_nu <- bf(
    y ~ x + (0 + x | id), sigma ~ 1, nu ~ z,
    sd(id, coef = "x") ~ w
  )
  expect_false(drm_julia_tweedie_scalar_sd_route_admitted(predictor_nu))

  random_sd_rhs <- bf(
    y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
    sd(id, coef = "x") ~ w + (1 | other)
  )
  expect_false(drm_julia_tweedie_scalar_sd_route_admitted(random_sd_rhs))

  structured <- bf(
    y ~ x + (0 + x | id) + phylo(1 | species, tree = tree),
    sigma ~ 1, nu ~ 1, sd(id, coef = "x") ~ w
  )
  expect_false(drm_julia_tweedie_scalar_sd_route_admitted(structured))

  categorical_slope <- bf(
    y ~ treatment + (0 + treatment | id), sigma ~ 1, nu ~ 1,
    sd(id, coef = "treatment") ~ w
  )
  categorical_data <- data.frame(
    y = c(1, 2, 1, 2), treatment = factor(c("a", "b", "a", "b")),
    w = c(-1, -1, 1, 1), id = factor(c(1, 1, 2, 2))
  )
  expect_false(drm_julia_tweedie_scalar_sd_route_admitted(
    categorical_slope, data = categorical_data
  ))
  expect_error(
    drm_julia_refuse_fe_only_random_effects(
      categorical_slope, "tweedie", data = categorical_data
    ),
    "fixed-effect"
  )
})

test_that("Tweedie random-slope SD regression agrees across engines", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(202610221L)
  groups <- 48L
  repeats <- 8L
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_index)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[id_index]
  x <- rep(seq(-1, 1, length.out = repeats), times = groups)
  alpha <- c("(Intercept)" = -0.65, w = 0.45)
  slope <- exp(alpha[["(Intercept)"]] + alpha[["w"]] * w_group) *
    rnorm(groups)
  mu <- exp(0.3 + 0.25 * x + x * slope[id_index])
  y <- drmTMB:::rtweedie_compound(
    length(mu), mu = mu, phi = 0.55^2, power = 1.5
  )
  dat <- data.frame(y, x, w, id)
  formula <- bf(
    y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
    sd(id, coef = "x") ~ w
  )
  dpar <- 'sd(id, coef = "x")'

  fit_tmb <- drmTMB(
    formula, family = tweedie(), data = dat, engine = "tmb",
    control = drm_control(optimizer_preset = "careful")
  )
  fit_julia <- drmTMB(
    formula, family = tweedie(), data = dat, engine = "julia"
  )

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  tmb_sd <- coef(fit_tmb, dpar = dpar)
  julia_sd <- coef(fit_julia, dpar = dpar)
  expect_named(tmb_sd, c("(Intercept)", "w"))
  expect_named(julia_sd, names(tmb_sd))
  expect_gt(unname(tmb_sd[["w"]]), 0)
  expect_gt(unname(julia_sd[["w"]]), 0)
  expect_lt(abs(unname(julia_sd[["w"]] - tmb_sd[["w"]])), 0.35)

  tmb_group_sd <- predict(fit_tmb, dpar = dpar)
  julia_group_sd <- predict(fit_julia, dpar = dpar)
  expect_length(tmb_group_sd, groups)
  expect_equal(length(julia_group_sd), groups)
  expect_equal(unname(julia_group_sd), unname(tmb_group_sd), tolerance = 0.35)
  row_sd <- predict(fit_julia, newdata = dat[c(4L, 1L, 8L, 2L), ], dpar = dpar)
  expect_equal(
    unname(row_sd),
    unname(julia_group_sd)[id_index[c(4L, 1L, 8L, 2L)]],
    tolerance = 1e-10
  )
})

test_that("Tweedie random-intercept SD regression agrees across engines", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(202610222L)
  groups <- 42L
  repeats <- 8L
  id_index <- rep(seq_len(groups), each = repeats)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[id_index]
  x <- stats::rnorm(length(id_index))
  alpha <- c("(Intercept)" = -0.6, w = 0.4)
  intercept <- stats::rnorm(
    groups,
    sd = exp(alpha[["(Intercept)"]] + alpha[["w"]] * w_group)
  )
  mu <- exp(0.25 + 0.25 * x + intercept[id_index])
  y <- drmTMB:::rtweedie_compound(
    length(mu), mu = mu, phi = 0.55^2, power = 1.5
  )
  dat <- data.frame(y, x, w, id = factor(id_index))
  formula <- bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ w)

  fit_tmb <- drmTMB(
    formula, family = tweedie(), data = dat, engine = "tmb",
    control = drm_control(optimizer_preset = "careful")
  )
  fit_julia <- drmTMB(formula, family = tweedie(), data = dat, engine = "julia")

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  tmb_sd <- coef(fit_tmb, dpar = "sd(id)")
  julia_sd <- coef(fit_julia, dpar = "sd(id)")
  expect_named(tmb_sd, c("(Intercept)", "w"))
  expect_named(julia_sd, names(tmb_sd))
  expect_gt(unname(tmb_sd[["w"]]), 0)
  expect_gt(unname(julia_sd[["w"]]), 0)
  expect_lt(abs(unname(julia_sd[["w"]] - tmb_sd[["w"]])), 0.35)

  tmb_group_sd <- predict(fit_tmb, dpar = "sd(id)")
  julia_group_sd <- predict(fit_julia, dpar = "sd(id)")
  expect_length(tmb_group_sd, groups)
  expect_length(julia_group_sd, groups)
  expect_equal(unname(julia_group_sd), unname(tmb_group_sd), tolerance = 0.35)
})
