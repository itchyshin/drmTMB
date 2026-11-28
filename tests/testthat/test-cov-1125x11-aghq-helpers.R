# Coverage: R/aghq-coxreid.R (unit paths not covered by test-aghq-coxreid.R / open PR #1839).

skip_on_cran()

test_that("drm_o3_npar matches family layout", {
  expect_equal(drmTMB:::drm_o3_npar("binomial", 3L, 4L), 3L)
  expect_equal(drmTMB:::drm_o3_npar("cumulative_logit", 2L, 5L), 6L)
  expect_equal(drmTMB:::drm_o3_npar("cumulative_logit", 1L, 3L), 3L)
  expect_equal(drmTMB:::drm_o3_npar("binomial", 1L, 2L), 1L)
})

test_that("drm_o3_split packs and unpacks psi", {
  b <- drmTMB:::drm_o3_split(c(1, 2, 3), "binomial", 3L)
  expect_identical(b$beta, c(1, 2, 3))
  expect_null(b$theta)
  o <- drmTMB:::drm_o3_split(c(0.5, 1.5, -0.2, 0.1), "cumulative_logit", 2L)
  expect_equal(o$beta, c(0.5, 1.5))
  expect_equal(o$theta, c(-0.2, 0.1))
})

test_that("drm_o3_gh returns singleton and symmetric nodes", {
  one <- drmTMB:::drm_o3_gh(1L)
  expect_equal(one$x, 0)
  expect_equal(one$w, sqrt(pi), tolerance = 1e-14)
  five <- drmTMB:::drm_o3_gh(5L)
  expect_length(five$x, 5L)
  expect_length(five$w, 5L)
  expect_true(all(five$w > 0))
  expect_equal(sum(five$w), sqrt(pi), tolerance = 1e-10)
})

test_that("drm_o3_cluster_ll is finite on a one-row binomial cluster", {
  Xm <- matrix(c(1, 0.3), nrow = 1L)
  ll <- drmTMB:::drm_o3_cluster_ll(
    u = 0.2,
    beta = c(-0.1, 0.4),
    theta = NULL,
    family = "binomial",
    Xm = Xm,
    zm = 1,
    ym = 1L,
    trials = 1L
  )
  expect_true(is.finite(ll))
  ll0 <- drmTMB:::drm_o3_cluster_ll(
    u = 0.2,
    beta = c(-0.1, 0.4),
    theta = NULL,
    family = "binomial",
    Xm = Xm,
    zm = 1,
    ym = 0L,
    trials = 1L
  )
  expect_true(is.finite(ll0))
  expect_lt(ll0, ll)
})

test_that("drm_o3_cluster_ll respects cumulative_logit cutpoints", {
  Xm <- matrix(0.5, nrow = 1L)
  theta <- c(0, 0.2)
  y1 <- drmTMB:::drm_o3_cluster_ll(0, c(0.1), theta, "cumulative_logit", Xm, 1, 1L, 1L)
  y3 <- drmTMB:::drm_o3_cluster_ll(0, c(0.1), theta, "cumulative_logit", Xm, 1, 3L, 1L)
  expect_true(is.finite(y1))
  expect_true(is.finite(y3))
  expect_gt(y1, y3)
})

test_that("drm_o3_mode returns uhat and positive tau", {
  Xm <- matrix(c(1, -0.2, 1, 0.5), nrow = 2L, byrow = TRUE)
  zm <- c(1, 1)
  ym <- c(0L, 1L)
  m <- drmTMB:::drm_o3_mode(
    beta = c(0, 0.3),
    theta = NULL,
    sd = 0.6,
    family = "binomial",
    Xm = Xm,
    zm = zm,
    ym = ym,
    trials = rep(1L, 2L)
  )
  expect_true(is.finite(m$uhat))
  expect_gt(m$tau, 0)
  expect_equal(length(m$uhat), 1L)
})

test_that("drm_o3_marginal_ll aggregates two clusters", {
  set.seed(112511L)
  g <- rep(1:2, each = 3L)
  X <- cbind(1, stats::rnorm(6))
  z <- rep(1, 6)
  y <- stats::rbinom(6, 1L, 0.45)
  trials <- rep(1L, 6)
  idx <- split(seq_along(g), g)
  nd <- drmTMB:::drm_o3_gh(3L)
  ll <- drmTMB:::drm_o3_marginal_ll(
    beta = c(0, 0),
    theta = NULL,
    sd = 0.5,
    family = "binomial",
    X = X,
    z = z,
    y = y,
    group_idx = idx,
    trials = trials,
    nodes = nd
  )
  expect_true(is.finite(ll))
  expect_gt(ll, -Inf)
})

test_that("drm_o3_optim_control and drm_o3_check_optim warn on failure", {
  ctl <- drmTMB:::drm_o3_optim_control()
  expect_equal(ctl$reltol, 1e-8)
  expect_equal(ctl$maxit, 400L)
  bad <- list(convergence = 1L, par = 0)
  expect_warning(drmTMB:::drm_o3_check_optim(bad, "unit"), "convergence")
  ok <- list(convergence = 0L, par = 0)
  expect_silent(drmTMB:::drm_o3_check_optim(ok, "unit"))
})

test_that("drm_o3_cr_negll returns profile psi and nonnegative value", {
  set.seed(112512L)
  g <- rep(1:3, each = 4L)
  X <- cbind(1, stats::rnorm(12))
  z <- rep(1, 12)
  y <- stats::rbinom(12, 1L, 0.4)
  trials <- rep(1L, 12)
  idx <- split(seq_along(g), g)
  nd <- drmTMB:::drm_o3_gh(2L)
  psi0 <- c(0, 0)
  out <- drmTMB:::drm_o3_cr_negll(
    sd = 0.4,
    family = "binomial",
    X = X,
    z = z,
    y = y,
    group_idx = idx,
    trials = trials,
    K = 2L,
    nodes = nd,
    psi_start = psi0
  )
  expect_true(is.finite(out$value))
  expect_equal(length(out$psi), 2L)
})

test_that("drm_o3_profile_ci requires llR and respects bounds", {
  fit <- list(
    llR = function(logsd) -((logsd - 0)^2),
    logsd_hat = 0,
    sd = 1,
    sd_bounds = c(1e-3, 2)
  )
  ci <- drmTMB:::drm_o3_profile_ci(fit, level = 0.90)
  expect_true(is.finite(ci$estimate))
  expect_equal(ci$level, 0.90)
  expect_error(drmTMB:::drm_o3_profile_ci(list(sd = 1)), "llR")
})

test_that("drm_o3_fit refuses bad cumulative_logit coding", {
  X <- cbind(1)
  z <- rep(1, 4)
  g <- rep(1:2, each = 2)
  y <- c(1L, 2L, 5L, 2L)
  expect_error(
    drmTMB:::drm_o3_fit(y, X, z, g, family = "cumulative_logit", nodes = 1L, n_categories = 4L),
    "cumulative_logit"
  )
})