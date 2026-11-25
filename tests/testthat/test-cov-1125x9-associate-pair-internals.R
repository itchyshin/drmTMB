# Deeper R/associate-pairs.R internals not covered by cov-1125w helper shard.

test_that("drm_pair_bernoulli_rectangle_probability() stays in [0, 1] for symmetric margins", {
  f <- drmTMB:::drm_pair_bernoulli_rectangle_probability
  p <- 0.4
  for (eta in c(0, 0.3, -0.25)) {
    val <- f(1L, p, 1L, p, eta)
    expect_true(is.na(val) || (val >= 0 && val <= 1))
    val00 <- f(0L, p, 0L, p, eta)
    expect_true(is.na(val00) || (val00 >= 0 && val00 <= 1))
  }
})

test_that("drm_pair_logdiffexp() is stable across magnitude gaps", {
  f <- drmTMB:::drm_pair_logdiffexp
  expect_equal(f(0, log(0.25)), 0 + log1p(-exp(log(0.25))))
  expect_equal(f(log(0.2), 0), -Inf)
  expect_equal(f(-5, -4), -Inf)
  expect_equal(f(1, 0.5), 1 + log1p(-exp(0.5 - 1)), tolerance = 1e-10)
})

test_that("drm_pair_nbinom2_endpoints() resolves ordinary counts", {
  y <- c(0L, 3L, 10L)
  mu <- c(2, 4, 8)
  sigma <- rep(1, 3)
  ep <- drmTMB:::drm_pair_nbinom2_endpoints(y, mu, sigma)
  expect_named(ep, c("lower", "upper", "upper_representation", "lower_representation", "complement_error_max"))
  expect_length(ep$lower, 3L)
  expect_length(ep$upper, 3L)
  expect_true(all(ep$lower[-1] < ep$upper[-1]))
  expect_equal(ep$lower[1], -Inf)
  expect_true(all(is.finite(ep$upper)))
  expect_true(ep$complement_error_max < 1e-6)
})

test_that("drm_pair_normal_quantile_from_log_tails() inverts moderate probabilities", {
  log_p <- log(c(0.2, 0.8))
  log_s <- log(1 - c(0.2, 0.8))
  z <- drmTMB:::drm_pair_normal_quantile_from_log_tails(log_p, log_s)
  expect_length(z, 2L)
  expect_equal(stats::pnorm(z[1]), 0.2, tolerance = 1e-6)
  expect_equal(stats::pnorm(z[2]), 0.8, tolerance = 1e-6)
})

test_that("drm_pair_validate_fit() and drm_pair_analysis_rows() gate margin fits", {
  expect_error(drmTMB:::drm_pair_validate_fit(list(foo = 1), "test"), "drmTMB")
  fit <- structure(
    list(
      family = list(link = "logit"),
      model = list(dpars = c("mu")),
      data = data.frame(y = 1:3)
    ),
    class = "drmTMB"
  )
  expect_error(drmTMB:::drm_pair_validate_gaussian(fit), "Gaussian")
  rows <- drmTMB:::drm_pair_analysis_rows(
    structure(
      list(model = list(y = 1:5), data = data.frame(y = 1:5), nobs = 5L),
      class = "drmTMB"
    )
  )
  expect_equal(rows, seq_len(5))
})

test_that("drm_pair_component_n() counts rows consistently", {
  comp <- list(gaussian_y = 1:4, nbinom2_y = 1:4, binary_1_y = 1:4)
  expect_equal(drmTMB:::drm_pair_component_n(comp), 4L)
})

test_that("drm_pair_fingerprint() hashes key fit fields", {
  fit <- list(
    coefficients = list(mu = c(1, 2)),
    model = list(y = 1:3, model_type = "gaussian"),
    nobs = 3L
  )
  fp1 <- drmTMB:::drm_pair_fingerprint(fit)
  fp2 <- drmTMB:::drm_pair_fingerprint(fit)
  expect_identical(fp1, fp2)
  expect_type(fp1, "character")
  expect_length(fp1, 1L)
})