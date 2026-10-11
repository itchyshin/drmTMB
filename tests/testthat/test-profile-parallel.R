# Issue #1247: profile() accepts the same parallel = "none" | "multicore"
# contract as confint(). Multicore curves must equal the serial curves apart
# from the per-target elapsed time.

test_that("profile() multicore curves are identical to the serial curves", {
  testthat::skip_on_os("windows")
  set.seed(20261011)
  n <- 40
  x <- stats::rnorm(n)
  dat <- data.frame(y = 0.2 + 0.5 * x + stats::rnorm(n, sd = 0.7), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  parm <- c("fixef:mu:(Intercept)", "fixef:mu:x", "sigma")

  serial <- profile(fit, parm = parm, profile_precision = "fast")
  multicore <- profile(
    fit,
    parm = parm,
    profile_precision = "fast",
    parallel = "multicore",
    workers = 2
  )
  serial$elapsed <- NULL
  multicore$elapsed <- NULL
  expect_identical(multicore, serial)
})

test_that("profile() validates its parallel arguments", {
  dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4, 0.9), x = c(-1, 0, 1, 2, 3))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), data = dat)
  expect_error(
    profile(fit, parm = "sigma", parallel = "cluster"),
    "should be one of"
  )
  expect_error(
    profile(fit, parm = "sigma", parallel = "multicore", workers = 0),
    "workers"
  )
})

test_that("multicore worker errors abort like the serial path", {
  testthat::skip_on_os("windows")
  plan <- list(backend = "multicore", workers = 2L)
  worker <- function(i) {
    if (i == 2L) stop("boom in worker ", i)
    i
  }
  expect_error(
    suppressWarnings(drmTMB:::profile_lapply(1:3, worker, plan)),
    "boom in worker 2"
  )
  expect_equal(drmTMB:::profile_lapply(1:3, function(i) i * 2, plan), list(2, 4, 6))
})
