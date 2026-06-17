# Wave 1 honesty guard 2: AIC()/BIC() must not silently return a meaningless
# number on a REML or penalized (MAP) fit. stats::AIC.default reads the logLik
# value and ignores the estimator/REML attributes, so drmTMB needs its own
# methods that compute the value AND warn when the comparison is invalid.
#
# The warning logic is tested with lightweight synthetic fits (deterministic);
# one real ML fit confirms end-to-end dispatch and the numeric value.

ml_fit_stub <- function(logLik = -100, df = 4L, nobs = 80L) {
  structure(
    list(estimator = "ML", logLik = logLik, df = df, nobs = nobs),
    class = "drmTMB"
  )
}

test_that("AIC/BIC compute the textbook value silently for an ML fit", {
  obj <- ml_fit_stub(logLik = -100, df = 4L, nobs = 80L)
  expect_no_warning(a <- AIC(obj))
  expect_equal(a, -2 * -100 + 2 * 4)
  expect_no_warning(a3 <- AIC(obj, k = 3))
  expect_equal(a3, -2 * -100 + 3 * 4)
  expect_no_warning(b <- BIC(obj))
  expect_equal(b, -2 * -100 + log(80) * 4)
})

test_that("AIC/BIC warn on a REML fit about identical fixed effects", {
  obj <- structure(
    list(estimator = "REML", REML = TRUE, logLik = -50, df = 3L, nobs = 60L),
    class = "drmTMB"
  )
  expect_warning(AIC(obj), "identical fixed effects")
  expect_warning(BIC(obj), "identical fixed effects")
})

test_that("AIC/BIC warn on a penalized (MAP) fit", {
  obj <- structure(
    list(estimator = "MAP", logLik = -30, df = 2L, nobs = 40L),
    class = "drmTMB"
  )
  expect_warning(AIC(obj), "penalized")
  expect_warning(BIC(obj), "penalized")
})

test_that("AIC compares multiple fits and warns once when any is REML", {
  ml <- ml_fit_stub(logLik = -100, df = 4L, nobs = 80L)
  reml <- structure(
    list(estimator = "REML", REML = TRUE, logLik = -90, df = 4L, nobs = 80L),
    class = "drmTMB"
  )
  # expect_warning() returns the condition, not the value, so assign inside it.
  res <- NULL
  expect_warning(res <- AIC(ml, reml), "identical fixed effects")
  expect_s3_class(res, "data.frame")
  expect_equal(nrow(res), 2L)
  expect_equal(res$AIC, c(-2 * -100 + 2 * 4, -2 * -90 + 2 * 4))
})

test_that("AIC on a real ML fit matches the logLik-based value and is silent", {
  set.seed(1)
  n <- 60
  x <- stats::rnorm(n)
  dat <- data.frame(y = 1 + 0.5 * x + stats::rnorm(n, 0, 0.5), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  expect_no_warning(a <- AIC(fit))
  expect_equal(a, as.numeric(-2 * fit$logLik + 2 * fit$df))
})
