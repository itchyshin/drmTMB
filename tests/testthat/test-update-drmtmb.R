test_that("update.drmTMB refits with a new formula (#1241)", {
  set.seed(1)
  n <- 40
  dat <- data.frame(y = rnorm(n), x = rnorm(n))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  fit2 <- update(fit, bf(y ~ 1, sigma ~ 1))
  expect_s3_class(fit2, "drmTMB")
  direct <- drmTMB(bf(y ~ 1, sigma ~ 1), family = gaussian(), data = dat)
  expect_equal(as.numeric(logLik(fit2)), as.numeric(logLik(direct)),
               tolerance = 1e-8)
  expect_lt(as.numeric(logLik(fit2)), as.numeric(logLik(fit)) + 1e-8)
})

test_that("update.drmTMB replaces other arguments and can return the call", {
  set.seed(2)
  dat <- data.frame(y = rnorm(30), x = rnorm(30))
  dat2 <- dat[1:20, ]
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  fit_small <- update(fit, data = dat2)
  expect_equal(nobs(fit_small), 20L)
  cl <- update(fit, REML = TRUE, evaluate = FALSE)
  expect_true(is.call(cl))
  expect_true(isTRUE(cl$REML))
  expect_identical(cl[[1]], quote(drmTMB))
})

test_that("update.drmTMB gives clear errors", {
  set.seed(3)
  dat <- data.frame(y = rnorm(20), x = rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  expect_error(update(fit, y ~ 1), "bf")
  expect_error(update(fit, bf(y ~ 1), 5), "named")
  fit$call <- NULL
  expect_error(update(fit, bf(y ~ 1)), "no stored call")
})
