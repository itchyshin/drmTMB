test_that("SkewNormal Julia bridge admits only a matching scalar mu SD route", {
  slope <- bf(
    y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
    sd(id, dpar = "mu", coef = "x") ~ w
  )

  expect_true(drmTMB:::drm_julia_skew_normal_scalar_sd_route_admitted(
    slope, data = data.frame(x = c(-1, 1), w = c(-1, 1))
  ))
  expect_no_error(
    drmTMB:::drm_julia_refuse_fe_only_random_effects(
      slope, "skew_normal", data = data.frame(x = c(-1, 1), w = c(-1, 1))
    )
  )

  intercept <- bf(y ~ x + (1 | id), sigma ~ 1, nu ~ 1, sd(id) ~ w)
  expect_true(drmTMB:::drm_julia_skew_normal_scalar_sd_route_admitted(
    intercept
  ))
  expect_no_error(drmTMB:::drm_julia_refuse_fe_only_random_effects(
    intercept, "skew_normal"
  ))

  expect_false(drmTMB:::drm_julia_skew_normal_scalar_sd_route_admitted(
    bf(y ~ x + (1 + x | id), sigma ~ 1, nu ~ 1,
       sd(id, coef = "x") ~ w)
  ))
  expect_false(drmTMB:::drm_julia_skew_normal_scalar_sd_route_admitted(
    bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ z,
       sd(id, coef = "x") ~ w)
  ))
  expect_false(drmTMB:::drm_julia_skew_normal_scalar_sd_route_admitted(
    bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
       sd(other, coef = "x") ~ w)
  ))
  expect_false(drmTMB:::drm_julia_skew_normal_scalar_sd_route_admitted(
    bf(y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
       sd(id, coef = "other") ~ w)
  ))
  categorical_slope <- bf(
    y ~ treatment + (0 + treatment | id), sigma ~ 1, nu ~ 1,
    sd(id, coef = "treatment") ~ w
  )
  categorical_data <- data.frame(
    treatment = factor(c("a", "b", "a", "b")),
    w = c(-1, -1, 1, 1), id = factor(c(1, 1, 2, 2))
  )
  expect_false(drmTMB:::drm_julia_skew_normal_scalar_sd_route_admitted(
    categorical_slope, data = categorical_data
  ))
})

test_that("SkewNormal independent-slope SD regression fits through both engines", {
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(202610251L)
  groups <- 48L
  repeats <- 10L
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_index)
  w_group <- seq(-1, 1, length.out = groups)
  w <- w_group[id_index]
  x <- rep(seq(-1, 1, length.out = repeats), times = groups)
  alpha <- c("(Intercept)" = -0.8, w = 0.45)
  slope <- exp(alpha[["(Intercept)"]] + alpha[["w"]] * w_group) *
    stats::rnorm(groups)
  mu <- 0.35 + 0.3 * x + slope[id_index] * x
  sigma <- 0.75
  nu <- 1.1
  delta <- nu / sqrt(1 + nu^2)
  mean_shift <- delta * sqrt(2 / pi)
  omega <- sigma / sqrt(1 - mean_shift^2)
  xi <- mu - omega * mean_shift
  y <- xi + omega * (
    delta * abs(stats::rnorm(length(mu))) +
      sqrt(1 - delta^2) * stats::rnorm(length(mu))
  )
  dat <- data.frame(y, x, w, id)
  target <- 'sd(id, dpar = "mu", coef = "x")'
  formula <- bf(
    y ~ x + (0 + x | id), sigma ~ 1, nu ~ 1,
    sd(id, dpar = "mu", coef = "x") ~ w
  )

  fit_tmb <- drmTMB(
    formula, family = skew_normal(), data = dat, engine = "tmb",
    control = drm_control(optimizer_preset = "careful")
  )
  fit_julia <- drmTMB(
    formula, family = skew_normal(), data = dat, engine = "julia"
  )

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  tmb_sd <- coef(fit_tmb, dpar = target)
  julia_sd <- coef(fit_julia, dpar = target)
  expect_named(tmb_sd, c("(Intercept)", "w"))
  expect_named(julia_sd, names(tmb_sd))
  expect_gt(unname(tmb_sd[["w"]]), 0)
  expect_gt(unname(julia_sd[["w"]]), 0)

  tmb_group_sd <- predict(fit_tmb, dpar = target)
  julia_group_sd <- predict(fit_julia, dpar = target)
  expect_length(tmb_group_sd, groups)
  expect_length(julia_group_sd, groups)
  expect_equal(unname(julia_group_sd), unname(tmb_group_sd), tolerance = 0.4)
  row_sd <- predict(fit_julia, newdata = dat[c(4L, 1L, 8L, 2L), ], dpar = target)
  expect_equal(
    unname(row_sd),
    unname(julia_group_sd)[id_index[c(4L, 1L, 8L, 2L)]],
    tolerance = 1e-10
  )
})
