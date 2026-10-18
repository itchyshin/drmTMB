# Unused arguments must not be dropped silently (#1536).
#
# `simulate(fit, newdata = nd)` used to push `newdata` into `...`, ignore it,
# and return one row per training observation. `predict(fit, typo = 1)` used to
# drop any unused name in `...` the same way. Both now refuse.

new_unused_args_fit <- function() {
  dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
  list(fit = fit, nd = data.frame(x = c(0, 1)))
}

test_that("simulate() has a newdata formal and refuses it instead of ignoring it", {
  z <- new_unused_args_fit()
  expect_true("newdata" %in% names(formals(simulate.drmTMB)))
  expect_error(
    simulate(z$fit, nsim = 1, seed = 1, newdata = z$nd),
    "newdata"
  )
  expect_error(
    simulate(z$fit, nsim = 1, seed = 1, newdata = z$nd),
    "predict_parameters|training"
  )
  expect_equal(nrow(simulate(z$fit, nsim = 1, seed = 1, newdata = NULL)), 4L)
})

test_that("simulate() refuses unused arguments in ...", {
  z <- new_unused_args_fit()
  expect_error(simulate(z$fit, nsim = 1, not_an_arg = 1), "reserved for future")
})

test_that("predict() refuses unused arguments in ...", {
  z <- new_unused_args_fit()
  expect_error(
    predict(z$fit, newdata = z$nd, dpar = "mu", not_an_arg = 1),
    "reserved for future"
  )
  expect_error(
    predict(z$fit, newdata = z$nd, dpar = "mu", se.fit = TRUE),
    "reserved for future"
  )
  expect_length(predict(z$fit, newdata = z$nd, dpar = "mu"), 2L)
})

test_that("predict() on a Julia-bridge fit refuses unused arguments in ...", {
  fake <- structure(list(), class = c("drmTMB_julia", "drmTMB"))
  expect_error(
    predict(fake, newdata = data.frame(x = 1), se.fit = TRUE),
    "reserved for future"
  )
})
