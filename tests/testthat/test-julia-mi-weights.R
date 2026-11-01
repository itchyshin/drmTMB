# Julia mi() + non-unit weights: classed refusal, no live Julia process.
# DRModels.jl ignores observation weights on both the response and the prior.

julia_mi_weight_data <- function() {
  data.frame(
    y = c(0.4, 0.7, 1.0, 1.3, 1.6, 1.9),
    x = c(-0.6, NA, 0.1, 0.5, 0.8, 1.1),
    z = c(-1.0, -0.7, -0.4, -0.1, 0.2, 0.5)
  )
}

test_that("engine='julia' mi() plus non-unit weights is a classed refusal", {
  dat <- julia_mi_weight_data()
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = dat,
      impute = list(x = x ~ z),
      missing = miss_control(predictor = "model"),
      engine = "julia",
      weights = rep(2, nrow(dat))
    ),
    class = "drmTMB_julia_mi_weights_unsupported"
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = dat,
      impute = list(x = x ~ z),
      missing = miss_control(predictor = "model"),
      engine = "julia",
      weights = c(1, 1, 2, 1, 1, 1)
    ),
    class = "drmTMB_julia_mi_weights_unsupported"
  )
})

test_that("joint prepare still classes a weights_missing that is not TRUE", {
  dat <- julia_mi_weight_data()
  expect_error(
    drmTMB:::drm_julia_joint_prepare(
      bf(y ~ z + mi(x), sigma ~ 1),
      family = gaussian(),
      data = dat,
      env = environment(),
      weights_missing = FALSE,
      control = drm_control(),
      impute = list(x = x ~ z),
      missing = miss_control(predictor = "model")
    ),
    class = "drmTMB_julia_mi_weights_unsupported"
  )
  expect_error(
    drmTMB:::drm_julia_joint_prepare(
      bf(y ~ z + mi(x), sigma ~ 1),
      family = gaussian(),
      data = dat,
      env = environment(),
      weights_missing = rep(1, nrow(dat)),
      control = drm_control(),
      impute = list(x = x ~ z),
      missing = miss_control(predictor = "model")
    ),
    class = "drmTMB_julia_mi_weights_unsupported"
  )
})

test_that("Julia mi() unit weights are not refused by the classed mi() gate", {
  expect_false(drmTMB:::drm_abort_julia_mi_nonunit_weights(NULL))
  expect_false(drmTMB:::drm_abort_julia_mi_nonunit_weights(rep(1, 4)))
  expect_error(
    drmTMB:::drm_abort_julia_mi_nonunit_weights(rep(2, 4)),
    class = "drmTMB_julia_mi_weights_unsupported"
  )
})

test_that("joint prepare classes weights before the family check", {
  dat <- data.frame(
    y = c(0.20, 0.35, 0.50, 0.62, 0.74, 0.85),
    x = c(0.18, NA_real_, 0.42, 0.55, 0.67, 0.80),
    z = c(-1.0, -0.6, -0.2, 0.2, 0.6, 1.0)
  )
  expect_error(
    drmTMB:::drm_julia_joint_prepare(
      bf(y ~ z + mi(x), sigma ~ 1),
      family = beta_family(),
      data = dat,
      env = environment(),
      weights_missing = FALSE,
      control = drm_control(),
      impute = list(x = impute_model(x ~ z, family = beta_family())),
      missing = miss_control(predictor = "model")
    ),
    class = "drmTMB_julia_mi_weights_unsupported"
  )
})

test_that("engine='julia' Beta mi() plus weights = 2 is still a classed refusal", {
  dat <- data.frame(
    y = c(0.20, 0.35, 0.50, 0.62, 0.74, 0.85),
    x = c(0.18, NA_real_, 0.42, 0.55, 0.67, 0.80),
    z = c(-1.0, -0.6, -0.2, 0.2, 0.6, 1.0)
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = dat,
      impute = list(x = impute_model(x ~ z, family = beta_family())),
      missing = miss_control(predictor = "model"),
      engine = "julia",
      weights = 2
    ),
    class = "drmTMB_julia_mi_weights_unsupported"
  )
})

test_that("engine='julia' Gamma mi() plus weights = 2 is a classed refusal (#1513)", {
  dat <- data.frame(
    y = c(1.0, 1.4, 2.1, 2.4, 3.0, 3.1, 3.7, 4.2),
    x = c(2.1, NA_real_, 4.4, 6.0, 8.5, 9.9, 12.0, 15.0),
    z = c(-1.0, -0.6, -0.3, -0.1, 0.1, 0.3, 0.6, 1.0)
  )
  expect_error(
    drmTMB(
      bf(y ~ z + mi(x), sigma ~ 1),
      data = dat,
      impute = list(x = impute_model(x ~ z, family = Gamma(link = "log"))),
      missing = miss_control(predictor = "model"),
      engine = "julia",
      weights = 2
    ),
    class = "drmTMB_julia_mi_weights_unsupported"
  )
})

test_that("engine='julia' refuses Beta and Gamma mi() with unit or no weights (#1513)", {
  # The quadrature change is R/TMB only. The Julia joint route supports
  # Gaussian responses with Gaussian/Bernoulli/ordinal/categorical
  # predictors, so a Beta or Gamma predictor model is refused before Julia
  # boots, whatever the weights.
  beta_dat <- data.frame(
    y = c(0.20, 0.35, 0.50, 0.62, 0.74, 0.85),
    x = c(0.18, NA_real_, 0.42, 0.55, 0.67, 0.80),
    z = c(-1.0, -0.6, -0.2, 0.2, 0.6, 1.0)
  )
  gamma_dat <- data.frame(
    y = c(1.0, 1.4, 2.1, 2.4, 3.0, 3.1),
    x = c(2.1, NA_real_, 4.4, 6.0, 8.5, 9.9),
    z = c(-1.0, -0.6, -0.3, -0.1, 0.1, 0.3)
  )
  cases <- list(
    list(beta_dat, beta_family()),
    list(gamma_dat, Gamma(link = "log"))
  )
  for (case in cases) {
    for (w in list(NULL, rep(1, nrow(case[[1L]])))) {
      expect_error(
        drmTMB(
          bf(y ~ z + mi(x), sigma ~ 1),
          data = case[[1L]],
          impute = list(x = impute_model(x ~ z, family = case[[2L]])),
          missing = miss_control(predictor = "model"),
          engine = "julia",
          weights = w
        ),
        "Could not prepare the Julia joint missing-predictor model"
      )
    }
  }
})
