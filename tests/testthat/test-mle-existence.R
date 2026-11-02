# FX3: MLE-nonexistence must not report is_converged() = TRUE silently.
# Recipes are the sweep-oct16 t4 cells named in #1553, #1270, and #1469.

t4_r_seed <- function(k, r) {
  as.integer((20261016400 + 100 * (k - 1) + (r - 1)) %% 2^31)
}

t4_rng <- function(k, r) {
  RNGkind("Mersenne-Twister", "Inversion", "Rejection")
  set.seed(t4_r_seed(k, r))
}

test_that("LP screen: complete, quasi-complete, overlapping, Poisson ray", {
  X <- cbind(1, c(-3, -2, -1, 1, 2, 3))
  d <- drmTMB:::drm_detect_separation(X, c(0, 0, 0, 1, 1, 1), c(1, 1, 1, 0, 0, 0))
  expect_true(d$separated)
  expect_identical(d$flagged, c(1L, 2L))
  expect_true(d$conclusive)

  xq <- c(-2, -1, 0, 0, 1, 2)
  dq <- drmTMB:::drm_detect_separation(
    cbind(1, xq), c(0, 0, 0, 1, 1, 1), c(1, 1, 1, 0, 0, 0)
  )
  expect_true(dq$separated)
  expect_identical(dq$flagged, 2L)

  xo <- c(-3, -2, -1, 1, 2, 3)
  yo <- c(0, 1, 0, 1, 0, 1)
  do <- drmTMB:::drm_detect_separation(cbind(1, xo), yo, 1 - yo)
  expect_false(do$separated)

  # Poisson all-zero: s = 0, ntr = 1 on every row
  y0 <- rep(0, 6)
  sf <- drmTMB:::drm_count_family_success_failure(y0)
  d0 <- drmTMB:::drm_detect_separation(cbind(1, xo), sf$successes, sf$failures)
  expect_true(d0$separated)

  # Poisson positives only at max(x)
  yp <- c(0, 0, 0, 0, 0, 2)
  sf <- drmTMB:::drm_count_family_success_failure(yp)
  dp <- drmTMB:::drm_detect_separation(cbind(1, xo), sf$successes, sf$failures)
  expect_true(dp$separated)

  # Ordinary Poisson overlap
  yok <- c(0, 1, 0, 2, 1, 3)
  sf <- drmTMB:::drm_count_family_success_failure(yok)
  dok <- drmTMB:::drm_detect_separation(cbind(1, xo), sf$successes, sf$failures)
  expect_false(dok$separated)
})

test_that("bin_complete r01 is degenerate and check_drm is not ok (#1270)", {
  t4_rng(7, 1)
  x <- rnorm(50)
  d <- data.frame(y = as.integer(x > 0), x = x)
  fit <- drmTMB(bf(y ~ x), family = binomial(), data = d)
  expect_false(is_converged(fit))
  expect_identical(convergence_status(fit), "degenerate")
  chk <- check_drm(fit)
  expect_false(isTRUE(attr(chk, "ok")))
  row <- chk[chk$check == "mle_existence", ]
  expect_identical(row$status, "warning")
  expect_identical(row$value, "binomial_separation")
})

test_that("overlapping binomial control stays converged", {
  set.seed(20261016)
  x <- seq(-2, 2, length.out = 40)
  y <- rbinom(40, 1, plogis(-0.2 + 0.8 * x))
  # guarantee overlap
  y[c(1, 3, 5)] <- 1L
  y[c(36, 38, 40)] <- 0L
  fit <- drmTMB(bf(y ~ x), family = binomial(), data = data.frame(y, x))
  expect_true(is_converged(fit))
  expect_identical(convergence_status(fit), "converged")
  chk <- check_drm(fit)
  row <- chk[chk$check == "mle_existence", ]
  expect_identical(row$status, "ok")
})

test_that("pois_n8_lowmean all-zero and extreme-x are degenerate (#1553)", {
  t4_rng(15, 3)
  x <- rnorm(8)
  d3 <- data.frame(y = rpois(8, exp(-1.5 + 0.5 * x)), x = x)
  expect_true(all(d3$y == 0))
  f3 <- drmTMB(bf(y ~ x), family = poisson(), data = d3)
  expect_false(is_converged(f3))
  expect_identical(convergence_status(f3), "degenerate")
  chk3 <- check_drm(f3)
  expect_false(isTRUE(attr(chk3, "ok")))
  expect_identical(chk3$check[chk3$check == "mle_existence"][1], "mle_existence")
  expect_identical(chk3$status[chk3$check == "mle_existence"], "warning")

  t4_rng(15, 25)
  x <- rnorm(8)
  d25 <- data.frame(y = rpois(8, exp(-1.5 + 0.5 * x)), x = x)
  expect_true(sum(d25$y > 0) >= 1)
  expect_true(max(d25$x[d25$y > 0]) == max(d25$x))
  f25 <- drmTMB(bf(y ~ x), family = poisson(), data = d25)
  expect_false(is_converged(f25))
  expect_identical(convergence_status(f25), "degenerate")
})

test_that("ordinary Poisson n=20 stays converged (sibling of #1553)", {
  t4_rng(6, 1)
  x <- rnorm(20)
  d <- data.frame(y = rpois(20, exp(0.5 + 0.5 * x)), x = x)
  fit <- drmTMB(bf(y ~ x), family = poisson(), data = d)
  expect_true(is_converged(fit))
  expect_identical(convergence_status(fit), "converged")
})

test_that("nbinom2 all-zero is degenerate (sibling count family)", {
  d <- data.frame(y = rep(0, 12), x = seq(-1, 1, length.out = 12))
  fit <- suppressWarnings(drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = d))
  expect_false(is_converged(fit))
  expect_identical(convergence_status(fit), "degenerate")
})

test_that("gauss_n8 r06 unbounded location-scale is degenerate (#1469)", {
  t4_rng(1, 6)
  x <- rnorm(8)
  d <- data.frame(y = 1 + 0.5 * x + exp(-0.4 + 0.3 * x) * rnorm(8), x = x)
  fit <- suppressWarnings(drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = d))
  expect_false(is_converged(fit))
  expect_identical(convergence_status(fit), "degenerate")
  chk <- check_drm(fit)
  row <- chk[chk$check == "mle_existence", ]
  expect_identical(row$status, "warning")
  expect_identical(row$value, "unbounded_location_scale")
})

test_that("healthy Gaussian location-scale is not flagged", {
  set.seed(20261016)
  n <- 40
  x <- rnorm(n)
  d <- data.frame(y = 1 + 0.5 * x + exp(-0.4 + 0.3 * x) * rnorm(n), x = x)
  fit <- drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = d)
  expect_true(is_converged(fit))
  expect_identical(convergence_status(fit), "converged")
  chk <- check_drm(fit)
  row <- chk[chk$check == "mle_existence", ]
  expect_identical(row$status, "ok")
})

test_that("unbounded-scale screen covers the continuous sibling families", {
  expect_identical(
    drmTMB:::drm_unbounded_scale_families(),
    c("gaussian", "lognormal", "student", "skew_normal", "gamma")
  )
})
