# #1708: engine = "julia" must apply the #1697 finite-value check before any
# hand-off to Julia (pure R side; no Julia needed).
test_that("julia #1708: Inf in y aborts with the drmTMB finite-response error", {
  set.seed(1)
  d <- data.frame(y = rnorm(20), x = rnorm(20))
  d$y[1] <- Inf
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = d, engine = "julia"),
    regexp = "finite observed response",
    class = "rlang_error"
  )
})

test_that("julia #1708: Inf in a predictor aborts and names the design column", {
  set.seed(1)
  d <- data.frame(y = rnorm(20), x = rnorm(20))
  d$x[1] <- Inf
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = d, engine = "julia"),
    regexp = "\\bx\\b",
    class = "rlang_error"
  )
  d2 <- data.frame(y = rnorm(20), z = rnorm(20))
  d2$z[2] <- -Inf
  expect_error(
    drmTMB(bf(y ~ 1, sigma ~ z), family = gaussian(), data = d2, engine = "julia"),
    regexp = "\\bz\\b",
    class = "rlang_error"
  )
})

test_that("julia #1708: the pre-handoff check leaves NA and NaN alone", {
  set.seed(1)
  d <- data.frame(y = rnorm(20), x = rnorm(20))
  d$y[1] <- NaN
  d$y[2] <- NA_real_
  expect_silent(drmTMB:::drm_julia_abort_if_nonfinite_gaussian(
    bf(y ~ x, sigma ~ 1), d, globalenv()
  ))
})
