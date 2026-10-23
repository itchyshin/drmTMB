# Fit-free characterisation tests for the pure numeric helpers in R/mspl.R.

test_that("mspl_softplus matches log1p(exp(x)) and survives extreme x", {
  x <- c(-5, 0, 5)
  expect_equal(drmTMB:::mspl_softplus(x), log1p(exp(x)), tolerance = 1e-12)
  expect_equal(drmTMB:::mspl_softplus(0), log(2), tolerance = 1e-12)

  expect_true(is.infinite(log1p(exp(800))))
  expect_true(is.finite(drmTMB:::mspl_softplus(800)))
  expect_equal(drmTMB:::mspl_softplus(800), 800, tolerance = 1e-12)
  expect_equal(drmTMB:::mspl_softplus(-800), 0, tolerance = 1e-12)

  grid <- seq(-3, 3, by = 1)
  expect_length(drmTMB:::mspl_softplus(grid), length(grid))
  h <- 1e-6
  fd <- (drmTMB:::mspl_softplus(grid + h) - drmTMB:::mspl_softplus(grid - h)) /
    (2 * h)
  expect_equal(fd, stats::plogis(grid), tolerance = 1e-8)
})

test_that("mspl_sech is a stable 1/cosh", {
  x <- c(-3, -0.5, 0.5, 3)
  expect_equal(drmTMB:::mspl_sech(x), 1 / cosh(x), tolerance = 1e-12)
  expect_equal(drmTMB:::mspl_sech(2), drmTMB:::mspl_sech(-2))
  expect_equal(drmTMB:::mspl_sech(0), 1)
  expect_equal(drmTMB:::mspl_sech(c(-1000, 1000)), c(0, 0))
})

test_that("mspl_failure builds a classed failure with extra fields", {
  f <- drmTMB:::mspl_failure("some_code", "some message", extra = 3L, tag = "a")
  expect_s3_class(f, "drm_mspl_numerical_failure")
  expect_false(f$ok)
  expect_identical(f$code, "some_code")
  expect_identical(f$message, "some message")
  expect_identical(f$extra, 3L)
  expect_identical(f$tag, "a")
})

test_that("mspl_safe_exp returns exp(x) or a non_finite_cholesky failure", {
  ok <- drmTMB:::mspl_safe_exp(c(-2, 0, 3), "theta")
  expect_s3_class(ok, "drm_mspl_input")
  expect_true(ok$ok)
  expect_equal(ok$value, exp(c(-2, 0, 3)))

  bad <- list(NA_real_, Inf, -Inf, "a", log(.Machine$double.xmax) + 1)
  for (x in bad) {
    r <- drmTMB:::mspl_safe_exp(x, "theta_name")
    expect_s3_class(r, "drm_mspl_numerical_failure")
    expect_false(r$ok)
    expect_identical(r$code, "non_finite_cholesky")
    expect_match(r$message, "theta_name", fixed = TRUE)
  }
})

test_that("mspl_scalar_or_vector validates and recycles", {
  f <- drmTMB:::mspl_scalar_or_vector
  r <- f(2, 4L, "trials")
  expect_s3_class(r, "drm_mspl_input")
  expect_true(r$ok)
  expect_identical(r$value, rep(2, 4))

  r <- f(c(1L, 2L, 3L), 3L, "trials")
  expect_true(r$ok)
  expect_type(r$value, "double")
  expect_identical(r$value, c(1, 2, 3))

  invalid <- list(
    f(c(1, 2), 3L, "x"),
    f(c(1, NA, 3), 3L, "x"),
    f(c(1, Inf, 3), 3L, "x"),
    f(NA_real_, 3L, "x"),
    f("a", 3L, "x"),
    f(numeric(0), 3L, "x")
  )
  for (r in invalid) {
    expect_s3_class(r, "drm_mspl_numerical_failure")
    expect_identical(r$code, "invalid_input")
  }

  expect_true(f(c(0, 2), 2L, "x", integer = TRUE)$ok)
  expect_identical(f(-1, 2L, "x", integer = TRUE)$code, "invalid_input")
  expect_identical(f(1.5, 2L, "x", integer = TRUE)$code, "invalid_input")

  expect_true(f(0.5, 2L, "x", positive = TRUE)$ok)
  expect_identical(f(0, 2L, "x", positive = TRUE)$code, "invalid_input")
  expect_identical(f(c(1, -1), 2L, "x", positive = TRUE)$code, "invalid_input")
})

test_that("mspl_link_mu matches hand-computed inverse links", {
  f <- drmTMB:::mspl_link_mu
  expect_equal(f(0), 0.5)
  expect_equal(f(0, "logit"), 0.5)
  expect_equal(f(log(3), "logit"), 0.75, tolerance = 1e-12)
  expect_equal(f(0, "probit"), 0.5)
  expect_equal(f(c(-1.96, 1.96), "probit"), c(0.0249979, 0.9750021),
               tolerance = 1e-6)
  expect_equal(f(0, "cloglog"), 1 - exp(-1), tolerance = 1e-12)
  expect_equal(f(log(log(2)), "cloglog"), 0.5, tolerance = 1e-12)
  expect_equal(f(-30, "cloglog"), exp(-30), tolerance = 1e-12)
  expect_error(f(0, "cauchit"), "Unsupported link")
})

test_that("mspl_log_cloglog_mu is correct in both tails", {
  f <- drmTMB:::mspl_log_cloglog_mu
  expect_equal(f(0), log(1 - exp(-1)), tolerance = 1e-12)
  expect_equal(f(log(log(2))), log(0.5), tolerance = 1e-12)
  expect_equal(f(5), log(1 - exp(-exp(5))), tolerance = 1e-12)
  # Series branch: log mu -> eta as eta -> -Inf, with no +Inf at eta < -745.
  expect_equal(f(-20), -20 + log1p(-exp(-20) / 2), tolerance = 1e-12)
  expect_equal(f(c(-745, -746, -1000)), c(-745, -746, -1000), tolerance = 1e-9)
  expect_length(f(numeric(0)), 0L)
  expect_equal(f(c(-1, 0, 1)), log(drmTMB:::mspl_link_mu(c(-1, 0, 1), "cloglog")),
               tolerance = 1e-12)
})
