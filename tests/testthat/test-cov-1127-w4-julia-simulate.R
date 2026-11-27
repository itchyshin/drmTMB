test_that("simulate.drmTMB_julia rejects native TMB fits", {
  dat <- data.frame(y = stats::rnorm(12), x = stats::rnorm(12))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat, family = gaussian())
  expect_error(
    drmTMB:::simulate.drmTMB_julia(fit, nsim = 1),
    "must be a Julia-engine"
  )
})

test_that("simulate.drmTMB_julia validates nsim on Binomial SD routes", {
  fake <- structure(
    list(
      model = list(model_type = "binomial"),
      formula = list(entries = list(list(dpar = "mu")))
    ),
    class = c("drmTMB_julia", "drmTMB")
  )
  testthat::local_mocked_bindings(
    drm_julia_binomial_sd_simulation_spec = function(object) {
      list(components = list(list(type = "ordinary")))
    },
    .package = "drmTMB"
  )
  expect_error(
    drmTMB:::simulate.drmTMB_julia(fake, nsim = 0),
    "positive whole number"
  )
  expect_error(
    drmTMB:::simulate.drmTMB_julia(fake, nsim = 1.5),
    "positive whole number"
  )
})

test_that("drm_julia_simulation_has_random_terms respects drm formulas", {
  expect_false(drmTMB:::drm_julia_simulation_has_random_terms(bf(y ~ x, sigma ~ 1)))
  dat <- data.frame(
    y = stats::rnorm(16),
    x = stats::rnorm(16),
    g = factor(rep(1:4, each = 4))
  )
  fit <- drmTMB(bf(y ~ x + (1 | g)), data = dat, family = gaussian())
  expect_true(drmTMB:::drm_julia_simulation_has_random_terms(fit$formula))
})

test_that("simulate.drmTMB_julia refuses unsupported Julia random-effect routes", {
  dat <- data.frame(
    y = stats::rnorm(16),
    x = stats::rnorm(16),
    g = factor(rep(1:4, each = 4))
  )
  fit <- drmTMB(bf(y ~ x + (1 | g)), data = dat, family = gaussian())
  fake <- structure(
    list(
      model = list(model_type = "gaussian"),
      formula = fit$formula
    ),
    class = c("drmTMB_julia", "drmTMB")
  )
  expect_error(
    drmTMB:::simulate.drmTMB_julia(fake, nsim = 2, seed = 1L),
    "not implemented for this Julia random-effect model"
  )
})

test_that("simulate.drmTMB_julia refuses conditional draws on Binomial SD fits", {
  dat <- data.frame(
    y = c(0L, 1L, 0L, 1L),
    x = c(-1, 0, 0.5, 1),
    id = factor(c("a", "a", "b", "b"))
  )
  fake <- structure(
    list(
      model = list(model_type = "binomial"),
      formula = structure(
        list(
          entries = list(list(dpar = "mu", structured = list(), rhs = quote(1)))
        ),
        class = "drm_formula"
      )
    ),
    class = c("drmTMB_julia", "drmTMB")
  )
  testthat::local_mocked_bindings(
    drm_julia_binomial_sd_simulation_spec = function(object) {
      list(components = list(list(type = "ordinary")))
    },
    .package = "drmTMB"
  )
  expect_error(
    drmTMB:::simulate.drmTMB_julia(fake, nsim = 1, re.form = NULL),
    "Conditional simulation is unavailable"
  )
})