test_that("LogNormal Julia SD admission is limited to one ordinary mean target", {
  intercept <- bf(y ~ x + (1 | id), sigma ~ 1, sd(id) ~ w)
  dat <- data.frame(
    y = c(1, 2, 1, 2), x = c(-1, 1, -1, 1),
    w = c(-1, -1, 1, 1), id = factor(c(1, 1, 2, 2))
  )
  expect_true(drm_julia_lognormal_scalar_sd_route_admitted(intercept, dat))
  expect_no_error(drm_julia_refuse_fe_only_random_effects(
    intercept, "lognormal", data = dat
  ))

  default_sigma <- bf(y ~ x + (1 | id), sd(id) ~ w)
  expect_true(drm_julia_lognormal_scalar_sd_route_admitted(
    default_sigma, dat
  ))

  slope <- bf(
    y ~ x + (0 + x | id), sigma ~ 1,
    sd(id, coef = "x") ~ w
  )
  expect_true(drm_julia_lognormal_scalar_sd_route_admitted(slope, dat))
  expect_no_error(drm_julia_refuse_fe_only_random_effects(
    slope, "lognormal", data = dat
  ))

  no_sd <- bf(y ~ x + (1 | id), sigma ~ 1)
  expect_false(drm_julia_lognormal_scalar_sd_route_admitted(no_sd, dat))
  expect_error(
    drm_julia_refuse_fe_only_random_effects(no_sd, "lognormal", data = dat),
    "fixed-effect"
  )

  wrong_group <- bf(
    y ~ x + (0 + x | id), sigma ~ 1,
    sd(other, coef = "x") ~ w
  )
  expect_false(drm_julia_lognormal_scalar_sd_route_admitted(wrong_group, dat))

  wrong_coefficient <- bf(
    y ~ x + (0 + x | id), sigma ~ 1,
    sd(id, coef = "other") ~ w
  )
  expect_false(drm_julia_lognormal_scalar_sd_route_admitted(
    wrong_coefficient, dat
  ))

  correlated <- bf(
    y ~ x + (1 + x | id), sigma ~ 1,
    sd(id, coef = "x") ~ w
  )
  expect_false(drm_julia_lognormal_scalar_sd_route_admitted(correlated, dat))

  multiple_terms <- bf(
    y ~ x + (1 | id) + (0 + x | id), sigma ~ 1,
    sd(id, coef = "x") ~ w
  )
  expect_false(drm_julia_lognormal_scalar_sd_route_admitted(
    multiple_terms, dat
  ))

  predictor_sigma <- bf(
    y ~ x + (1 | id), sigma ~ w, sd(id) ~ w
  )
  expect_false(drm_julia_lognormal_scalar_sd_route_admitted(
    predictor_sigma, dat
  ))

  random_sigma <- bf(
    y ~ x + (1 | id), sigma ~ (1 | id), sd(id) ~ w
  )
  expect_false(drm_julia_lognormal_scalar_sd_route_admitted(
    random_sigma, dat
  ))

  random_sd_rhs <- bf(
    y ~ x + (0 + x | id), sigma ~ 1,
    sd(id, coef = "x") ~ w + (1 | other)
  )
  expect_false(drm_julia_lognormal_scalar_sd_route_admitted(
    random_sd_rhs, dat
  ))

  categorical_slope <- bf(
    y ~ x + (0 + treatment | id), sigma ~ 1,
    sd(id, coef = "treatment") ~ w
  )
  categorical_dat <- transform(dat, treatment = factor(c("a", "b", "a", "b")))
  expect_false(drm_julia_lognormal_scalar_sd_route_admitted(
    categorical_slope, categorical_dat
  ))
  expect_error(drm_julia_refuse_fe_only_random_effects(
    categorical_slope, "lognormal", data = categorical_dat
  ), "fixed-effect")
})
