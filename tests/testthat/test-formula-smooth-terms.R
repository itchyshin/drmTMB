# drmTMB neither exports nor imports `s`, so an mgcv/gamlss reader used to get
# R's own `could not find function "s"`. Reject the smooth markers by name
# instead, before the model frame is evaluated.

smooth_term_fixture <- function(seed = 2026072102L, n = 40L) {
  set.seed(seed)
  data.frame(
    y = stats::rnorm(n),
    x = stats::rnorm(n),
    g = factor(rep(letters[1:4], length.out = n))
  )
}

test_that("smooth terms are rejected by name, not by a missing-function error", {
  data <- smooth_term_fixture()
  expect_error(
    drmTMB(bf(y ~ s(x)), data = data, family = gaussian()),
    "Smooth terms are not supported"
  )
})

test_that("the smooth rejection names a usable alternative", {
  data <- smooth_term_fixture()
  err <- tryCatch(
    drmTMB(bf(y ~ s(x)), data = data, family = gaussian()),
    error = function(e) conditionMessage(e)
  )
  expect_match(err, "poly")
  expect_match(err, "splines")
})

test_that("every smooth marker is rejected", {
  data <- smooth_term_fixture()
  expect_error(
    drmTMB(bf(y ~ te(x)), data = data, family = gaussian()),
    "Smooth terms are not supported"
  )
  expect_error(
    drmTMB(bf(y ~ ti(x)), data = data, family = gaussian()),
    "Smooth terms are not supported"
  )
  expect_error(
    drmTMB(bf(y ~ t2(x)), data = data, family = gaussian()),
    "Smooth terms are not supported"
  )
})

test_that("a smooth marker on a non-location parameter is rejected too", {
  data <- smooth_term_fixture()
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ s(x)), data = data, family = gaussian()),
    "Smooth terms are not supported"
  )
})

test_that("ordinary bases still fit", {
  skip_on_cran()
  data <- smooth_term_fixture()
  expect_no_error(
    drmTMB(bf(y ~ poly(x, 2)), data = data, family = gaussian())
  )
})
