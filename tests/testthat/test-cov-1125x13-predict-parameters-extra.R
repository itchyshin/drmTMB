# R/predict-parameters.R component labels, column ordering, and link derivatives.

test_that("drm_dpar_component() maps public dpar names to reader components", {
  f <- drmTMB:::drm_dpar_component
  expect_identical(f("mu"), "location")
  expect_identical(f("mu2"), "location")
  expect_identical(f("sigma1"), "distributional-scale")
  expect_identical(f("rho12"), "residual-correlation")
  expect_identical(f("nu"), "shape")
  expect_identical(f("zi"), "probability")
  expect_identical(f("sd(id)"), "random-effect-sd-model")
  expect_identical(f("hu"), "probability")
  expect_identical(f("coi"), "probability")
  expect_identical(f("custom"), "distributional-parameter")
})

test_that("predict_parameters_order_columns() keeps preferred columns first", {
  f <- drmTMB:::predict_parameters_order_columns
  raw <- data.frame(
    estimate = 1:2,
    dpar = c("mu", "sigma"),
    extra = 3:4,
    conf.low = c(0.1, 0.2),
    row = 1:2,
    conf.status = c("wald", "wald"),
    stringsAsFactors = FALSE
  )
  out <- f(raw)
  expect_equal(names(out)[1:4], c("row", "dpar", "estimate", "conf.low"))
  expect_true("extra" %in% names(out))
  expect_equal(nrow(out), 2L)
  expect_identical(names(f(data.frame(z = 1))), "z")
})

test_that("predict_parameters_newdata_columns() expands and renames reserved fields", {
  f <- drmTMB:::predict_parameters_newdata_columns
  nd <- data.frame(
    x = c(10, 20),
    type = c("a", "b"),
    row = c(1L, 2L),
    stringsAsFactors = FALSE
  )
  out <- f(nd, n_dpar = 2L)
  expect_equal(nrow(out), 4L)
  expect_true("x" %in% names(out))
  expect_true("newdata_type" %in% names(out))
  expect_true("newdata_row" %in% names(out))
  expect_length(row.names(out), 4L)
  one <- f(data.frame(g = 1), n_dpar = 1L)
  expect_equal(nrow(one), 1L)
})

test_that("predict_parameters_inverse_link_derivative() follows the fitted link map", {
  set.seed(11251301)
  dat <- data.frame(
    y = stats::rnorm(12, mean = 0.2, sd = exp(-0.5)),
    x = stats::rnorm(12)
  )
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  f <- drmTMB:::predict_parameters_inverse_link_derivative
  expect_equal(f(fit, "mu", 0), 1)
  expect_equal(f(fit, "sigma", 0), 1)
  expect_equal(f(fit, "sigma", 0.4), exp(0.4))
  pois <- drmTMB(
    bf(y ~ 1),
    family = poisson(),
    data = data.frame(y = stats::rpois(8, 2)),
    control = drm_control(se = FALSE)
  )
  eta <- 0.2
  expect_equal(f(pois, "mu", eta), exp(eta))
  expect_error(f(fit, "nu", 0), "Internal error")
})