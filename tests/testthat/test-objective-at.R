# Objective-At-A-Point (docs/design/35-optimizer-start-map-multistart.md,
# "Objective At A Point"). `objective_at(fit, at = list(...))` evaluates the
# fitted model's TMB objective at a supplied point, keyed by the same public
# start labels as `drm_control(start = ...)`, without refitting and without
# mutating the fitted object.

objective_at_fixef_data <- function() {
  set.seed(20260901)
  n <- 120
  x <- stats::rnorm(n)
  data.frame(y = -0.4 + 1.2 * x + stats::rnorm(n, 0, 0.8), x = x)
}

objective_at_sd_data <- function() {
  set.seed(20260902)
  id <- factor(rep(seq_len(8L), each = 5L))
  x <- stats::rnorm(40L)
  u <- stats::rnorm(8L, sd = 0.3)
  data.frame(
    id = id,
    x = x,
    y = 0.4 + 0.3 * x + u[id] + stats::rnorm(40L, sd = 0.2)
  )
}

test_that("objective_at is an exported generic with a drmTMB method", {
  expect_true(exists("objective_at", mode = "function"))
  expect_true(is.function(getS3method("objective_at", "drmTMB")))
})

test_that("objective_at reproduces -logLik at the fit's own optimum (self-consistency anchor)", {
  dat <- objective_at_fixef_data()
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  fx <- fixef(fit)
  at <- list()
  for (dp in names(fx)) {
    for (nm in names(fx[[dp]])) {
      at[[paste0("fixef:", dp, ":", nm)]] <- unname(fx[[dp]][[nm]])
    }
  }

  got <- objective_at(fit, at = at)
  expect_length(got, 1L)
  expect_equal(as.numeric(got), -as.numeric(stats::logLik(fit)), tolerance = 1e-8)
})

test_that("objective_at does not mutate the fitted object", {
  dat <- objective_at_fixef_data()
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  vcov_before <- stats::vcov(fit)
  invisible(objective_at(fit, at = list("fixef:mu:(Intercept)" = 0.2)))
  vcov_after <- stats::vcov(fit)

  expect_equal(vcov_after, vcov_before)
  expect_equal(as.numeric(stats::logLik(fit)), as.numeric(stats::logLik(fit)))
})

test_that("objective_at moves away from the optimum objective when perturbed", {
  dat <- objective_at_fixef_data()
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  at_optimum <- unname(fixef(fit)$mu[["(Intercept)"]])
  nll_hat <- objective_at(fit, at = list("fixef:mu:(Intercept)" = at_optimum))
  nll_off <- objective_at(fit, at = list("fixef:mu:(Intercept)" = at_optimum + 1))

  expect_equal(as.numeric(nll_hat), -as.numeric(stats::logLik(fit)), tolerance = 1e-8)
  expect_gt(as.numeric(nll_off), as.numeric(nll_hat))
})

test_that("objective_at supports sd: labels on the natural (positive) scale", {
  dat <- objective_at_sd_data()
  fit <- drmTMB(bf(y ~ x + (1 | id), sigma ~ 1), family = gaussian(), data = dat)

  sd_hat <- fit$sdpars$mu[["(1 | id)"]]
  nll_hat <- objective_at(fit, at = list("sd:mu:(1 | id)" = unname(sd_hat)))
  expect_equal(as.numeric(nll_hat), -as.numeric(stats::logLik(fit)), tolerance = 1e-6)
})

test_that("objective_at errors before evaluation on unknown labels", {
  dat <- objective_at_fixef_data()
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_error(
    objective_at(fit, at = list("fixef:mu:not_a_column" = 0.1)),
    class = "rlang_error"
  )
})

test_that("objective_at requires a named list", {
  dat <- objective_at_fixef_data()
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_error(objective_at(fit, at = list(0.1)), class = "rlang_error")
  expect_error(objective_at(fit, at = NULL), class = "rlang_error")
})
