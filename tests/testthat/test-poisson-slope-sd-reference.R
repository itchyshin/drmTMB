# Independent reference contract: eta_i = beta0 + beta1*x_i + x_i*b_g,
# b_g ~ N(0, tau_g^2), log(tau_g) = alpha0 + a*w_g. No drmTMB fit is used.
helper_path <- if (file.exists("helper-poisson-slope-sd-reference.R")) {
  "helper-poisson-slope-sd-reference.R"
} else {
  "tests/testthat/helper-poisson-slope-sd-reference.R"
}
source(helper_path, local = TRUE)

testthat::test_that("slope fixture obeys the symbolic model", {
  fixture <- poisson_slope_sd_reference_fixture(seed = 41L)
  d <- fixture$data
  testthat::expect_true(all(is.finite(d$y) & d$y >= 0 & d$y == floor(d$y)))
  testthat::expect_true(all(is.finite(fixture$lambda) & fixture$lambda > 0))
  testthat::expect_true(all(vapply(split(d$x, d$id), function(z) length(unique(z)) > 1L, logical(1))))
  testthat::expect_true(all(vapply(split(d$w, d$id), function(z) length(unique(z)) == 1L, logical(1))))
  testthat::expect_equal(fixture$tau_by_group,
                         exp(fixture$alpha[1L] + fixture$alpha[2L] * fixture$w_by_group),
                         ignore_attr = TRUE)
  testthat::expect_equal(fixture$lambda,
                         exp(fixture$beta[1L] + fixture$beta[2L] * d$x +
                               d$x * fixture$tau_by_group[as.character(d$id)] *
                               fixture$u_by_group[as.character(d$id)]),
                         ignore_attr = TRUE)
})

testthat::test_that("scalar slope integral is finite and invariant to row order", {
  fixture <- poisson_slope_sd_reference_fixture(seed = 42L)
  d <- fixture$data[fixture$data$id == levels(fixture$data$id)[1L], ]
  eta <- fixture$beta[1L] + fixture$beta[2L] * d$x
  tau <- unname(fixture$tau_by_group[as.character(d$id[1L])])
  for (method in c("laplace", "adaptive")) {
    got <- poisson_slope_sd_scalar_log_marginal(d$y, eta, d$x, tau, method)
    testthat::expect_true(is.finite(got) && exp(got) > 0)
    o <- rev(seq_len(nrow(d)))
    testthat::expect_equal(
      poisson_slope_sd_scalar_log_marginal(d$y[o], eta[o], d$x[o], tau, method),
      got, tolerance = 1e-8
    )
  }
})

testthat::test_that("zero slope design removes the random effect", {
  y <- c(0L, 2L, 1L, 4L)
  eta <- c(-0.4, 0.1, 0.7, 1.1)
  exact <- sum(stats::dpois(y, lambda = exp(eta), log = TRUE))
  for (tau in c(0.2, 1.8)) {
    for (method in c("laplace", "adaptive")) {
      testthat::expect_equal(
        poisson_slope_sd_scalar_log_marginal(y, eta, rep(0, length(y)), tau, method),
        exact, tolerance = 1e-8
      )
    }
  }
})

testthat::test_that("slope and SD inverse scaling preserves the marginal model", {
  fixture <- poisson_slope_sd_reference_fixture(seed = 43L)
  d <- fixture$data[fixture$data$id == levels(fixture$data$id)[2L], ]
  eta <- fixture$beta[1L] + fixture$beta[2L] * d$x
  tau <- unname(fixture$tau_by_group[as.character(d$id[1L])])
  for (method in c("laplace", "adaptive")) {
    baseline <- poisson_slope_sd_scalar_log_marginal(d$y, eta, d$x, tau, method)
    rescaled <- poisson_slope_sd_scalar_log_marginal(d$y, eta, 2.7 * d$x, tau / 2.7, method)
    testthat::expect_equal(rescaled, baseline, tolerance = 1e-7)
  }
})

testthat::test_that("group-index and random-slope design mistakes change the answer", {
  fixture <- poisson_slope_sd_reference_fixture(seed = 44L)
  d <- fixture$data
  correct <- poisson_slope_sd_group_log_marginal(d, fixture$beta, fixture$alpha)
  perm <- rev(seq_len(nrow(d)))
  testthat::expect_equal(
    poisson_slope_sd_group_log_marginal(d[perm, ], fixture$beta, fixture$alpha),
    correct, tolerance = 1e-8
  )
  wrong_w <- rev(fixture$w_by_group)
  names(wrong_w) <- names(fixture$w_by_group)
  testthat::expect_gt(abs(poisson_slope_sd_group_log_marginal(
    d, fixture$beta, fixture$alpha, w_by_group = wrong_w
  ) - correct), 1e-5)
  wrong_slope_x <- rev(d$x)
  testthat::expect_gt(abs(poisson_slope_sd_group_log_marginal(
    d, fixture$beta, fixture$alpha, slope_x = wrong_slope_x
  ) - correct), 1e-5)
})

testthat::test_that("unit slope design agrees with the existing intercept oracle", {
  old_path <- if (file.exists("helper-poisson-sd-regression.R")) {
    "helper-poisson-sd-regression.R"
  } else {
    "tests/testthat/helper-poisson-sd-regression.R"
  }
  source(old_path, local = TRUE)
  y <- c(0L, 3L, 2L, 1L, 4L)
  eta <- c(-0.3, 0.1, 0.6, -0.1, 0.9)
  for (method in c("laplace", "adaptive")) {
    testthat::expect_equal(
      poisson_slope_sd_scalar_log_marginal(y, eta, rep(1, length(y)), 0.7, method),
      poisson_sd_scalar_log_marginal(y, eta, 0.7, method),
      tolerance = 1e-7
    )
  }
})

testthat::test_that("invalid inputs fail before numerical integration", {
  testthat::expect_error(poisson_slope_sd_scalar_log_marginal(1, 0, 1, 0), "tau")
  testthat::expect_error(poisson_slope_sd_scalar_log_marginal(1, 0, c(1, 2), 1), "length")
  testthat::expect_error(poisson_slope_sd_scalar_log_marginal(-1, 0, 1, 1), "counts")
})
