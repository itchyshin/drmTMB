# Composite MSPL kernels in R/mspl.R (Jeffreys, Cholesky maps, penalties, diagnostics).

test_that("mspl_c_n validates scaling inputs", {
  f <- drmTMB:::mspl_c_n
  ok <- f(2L, 100)
  expect_s3_class(ok, "drm_mspl_scaling")
  expect_true(ok$ok)
  expect_identical(ok$p, 2L)
  expect_equal(ok$c_n, 2 * sqrt(2 / 100))

  bad <- list(
    f(0, 10),
    f(-1, 10),
    f(1.5, 10),
    f(2, 0),
    f(2, -1),
    f(2, NA),
    f(NA, 10)
  )
  for (r in bad) {
    expect_s3_class(r, "drm_mspl_numerical_failure")
    expect_identical(r$code, "invalid_scaling")
  }
})

test_that("mspl_log_weight is finite for standard links", {
  eta <- c(-2, 0, 2, 5)
  n <- rep(10, length(eta))
  for (link in c("logit", "probit", "cloglog")) {
    lw <- drmTMB:::mspl_log_weight(eta, n, link)
    expect_length(lw, length(eta))
    expect_true(all(is.finite(lw)))
    expect_true(all(lw <= log(n) + 1e-8))
  }
  expect_error(drmTMB:::mspl_log_weight(0, 1, "badlink"), "Unsupported link")
})

test_that("mspl_negative_huber and mspl_huber_cost sign conventions", {
  x <- c(-2, -0.5, 0, 0.5, 2)
  nh <- drmTMB:::mspl_negative_huber(x)
  expect_equal(nh, ifelse(abs(x) <= 1, -0.5 * x^2, -abs(x) + 0.5))
  grad <- drmTMB:::mspl_negative_huber(x, gradient = TRUE)
  expect_named(grad, c("value", "gradient"))
  expect_equal(grad$value, nh)
  expect_equal(grad$gradient, ifelse(abs(x) <= 1, -x, -sign(x)))

  cost <- drmTMB:::mspl_huber_cost(x)
  expect_equal(cost, -nh)
  cost_g <- drmTMB:::mspl_huber_cost(x, gradient = TRUE)
  expect_equal(cost_g$value, -nh)
  expect_equal(cost_g$gradient, -grad$gradient)
  expect_error(drmTMB:::mspl_negative_huber(c(NA, 1)), "finite numeric")
})

test_that("mspl_cholesky_q1 reconstructs variance and jacobian", {
  r <- drmTMB:::mspl_cholesky_q1(0)
  expect_s3_class(r, "drm_mspl_cholesky")
  expect_true(r$ok)
  expect_identical(r$q, 1L)
  expect_equal(r$cholesky[[1, 1]], 1)
  expect_equal(r$covariance[[1, 1]], 1)
  expect_equal(r$correlation[[1, 1]], 1)
  expect_equal(r$jacobian_covariance[[1, 1]], 2)

  bad <- drmTMB:::mspl_cholesky_q1(c(0, 1))
  expect_false(bad$ok)
  expect_identical(bad$code, "invalid_cholesky_coordinate")
})

test_that("mspl_cholesky_q2 matches hand-built 2x2 covariance", {
  psi <- c(log_sd_1 = 0, log_sd_2 = log(2), eta_rho = atanh(0.3))
  r <- drmTMB:::mspl_cholesky_q2(psi)
  expect_true(r$ok)
  expect_identical(r$q, 2L)
  expect_equal(unname(r$correlation[1, 2]), 0.3, tolerance = 1e-12)
  expect_equal(r$cholesky[2, 1], 2 * 0.3, tolerance = 1e-12)
  expect_true(all(is.finite(r$jacobian_covariance)))
  expect_equal(nrow(r$jacobian_covariance), 3L)
  expect_equal(ncol(r$jacobian_covariance), 3L)

  fail <- drmTMB:::mspl_cholesky_q2(c(0, 0))
  expect_identical(fail$code, "invalid_cholesky_coordinate")
})

test_that("mspl_jeffreys returns a ranked information matrix on tiny design", {
  set.seed(11258)
  n <- 20L
  X <- cbind(1, stats::rnorm(n))
  beta <- c(0.2, -0.1)
  for (link in c("logit", "probit", "cloglog")) {
    out <- drmTMB:::mspl_jeffreys(
      X, beta, trials = 1L, frequency = 1L, link = link
    )
    expect_s3_class(out, "drm_mspl_jeffreys")
    expect_true(out$ok)
    expect_identical(out$p, ncol(X))
    expect_equal(out$n_eff, n)
    expect_true(is.finite(out$half_logdet))
    expect_true(out$diagnostics$full_rank)
    expect_equal(nrow(out$information_scaled), ncol(X))
  }

  dupX <- cbind(1, 1, 1)
  rank_bad <- drmTMB:::mspl_jeffreys(dupX, c(0, 0, 0), rank_tol = 1e-10)
  expect_false(rank_bad$ok)
  expect_identical(rank_bad$code, "rank_deficient_information")

  empty <- drmTMB:::mspl_jeffreys(matrix(numeric(0), 0, 0), numeric(0))
  expect_identical(empty$code, "invalid_design")
})

test_that("mspl_penalty_components threads link into Jeffreys", {
  X <- cbind(1, stats::rnorm(12))
  beta <- c(0, 0.1)
  q1 <- drmTMB:::mspl_cholesky_q1(0)
  pen <- drmTMB:::mspl_penalty_components(
    X, beta, variance = q1, link = "probit"
  )
  expect_s3_class(pen, "drm_mspl_penalty")
  expect_true(pen$ok)
  expect_true(is.finite(pen$log_objective_bonus))
  expect_true(pen$jeffreys$ok)
  expect_equal(pen$jeffreys$mu, drmTMB:::mspl_link_mu(pen$jeffreys$eta, "probit"))

  q2psi <- c(0, log(2), atanh(0.2))
  pen2 <- drmTMB:::mspl_penalty_components(X, beta, variance = q2psi, q = 2L)
  expect_true(pen2$ok)
  expect_identical(pen2$variance_map$q, 2L)
  expect_length(pen2$variance_gradient_cholesky, 3L)

  mismatch <- drmTMB:::mspl_penalty_components(
    X, beta, variance = q1, q = 2L
  )
  expect_identical(mismatch$code, "incompatible_q")
})

test_that("mspl_numerical_diagnostics classifies information matrices", {
  d <- drmTMB:::mspl_numerical_diagnostics
  I2 <- diag(2)
  ok <- d(I2)
  expect_identical(ok$status, "ok")
  expect_true(ok$full_rank)
  expect_equal(ok$rank, 2L)
  expect_true(ok$condition_number >= 1)

  asym <- matrix(c(1, 0.1, 0, 1), 2)
  bad_sym <- d(asym)
  expect_false(bad_sym$symmetric)
  expect_identical(bad_sym$status, "non_symmetric_information")

  singular <- matrix(c(1, 1, 1, 1), 2)
  rank <- d(singular, rank_tol = 1e-10)
  expect_false(rank$full_rank)
  expect_identical(rank$status, "rank_deficient")

  invalid <- d(c(1, 2, 3))
  expect_identical(invalid$status, "invalid_information")
})

test_that("mspl_logsech and penalty_coordinates stay finite", {
  x <- c(-2, 0, 2)
  ls <- drmTMB:::mspl_logsech(x)
  expect_equal(ls, log(drmTMB:::mspl_sech(x)), tolerance = 1e-12)
  expect_true(all(is.finite(ls)))

  q2 <- drmTMB:::mspl_cholesky_q2(c(0, 0, atanh(0.25)))
  pen_coords <- q2$penalty_coordinates
  expect_named(pen_coords, c("log_l11", "log_l22", "l21"))
  expect_true(all(is.finite(unlist(pen_coords))))
  expect_equal(pen_coords[["l21"]], q2$cholesky[2, 1], tolerance = 1e-12)

  hub <- drmTMB:::mspl_negative_huber(c(-3, 0, 3), gradient = TRUE)
  expect_equal(length(hub$gradient), 3L)
  expect_equal(unname(hub$gradient), c(1, 0, -1))
})