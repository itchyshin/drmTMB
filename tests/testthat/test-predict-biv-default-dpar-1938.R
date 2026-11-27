# Issue #1938: default predict() on biv_gaussian returns mu1-only vector;
# fitted() is n x 2. Pins today's shape contract and the proposed one-time hint.

test_that("biv_gaussian #1938: one-time hint when dpar is omitted (pending owner decision)", {
  set.seed(1127)
  n <- 12L
  dat <- data.frame(
    y1 = stats::rnorm(n),
    y2 = stats::rnorm(n),
    x = stats::rnorm(n)
  )
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ 1),
    data = dat,
    family = biv_gaussian()
  )

  expect_message(
    predict(fit),
    "returns only mu1|first fitted location"
  )
})

test_that("biv_gaussian #1938: default predict() matches mu1 only; fitted() is n x 2", {
  set.seed(1127)
  n <- 40L
  dat <- data.frame(
    y1 = stats::rnorm(n),
    y2 = stats::rnorm(n),
    x = stats::rnorm(n)
  )
  fit <- drmTMB(
    bf(mu1 = y1 ~ x, mu2 = y2 ~ x, rho12 = ~ 1),
    data = dat,
    family = biv_gaussian()
  )

  ff <- fitted(fit)
  expect_equal(dim(ff), c(n, 2L))
  expect_equal(colnames(ff), c("mu1", "mu2"))

  pr <- suppressMessages(predict(fit))
  expect_length(pr, n)
  expect_true(isTRUE(all.equal(pr, ff[, "mu1"])))
  expect_false(isTRUE(all.equal(pr, ff[, "mu2"])))

  expect_equal(suppressMessages(predict(fit, type = "response")), pr)
  expect_equal(suppressMessages(predict(fit, dpar = "mu2")), ff[, "mu2"])
})