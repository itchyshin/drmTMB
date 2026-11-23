nsim_invalid <- c(Inf, NaN, NA)

minimal_gaussian_fit <- function() {
  dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
  drmTMB(bf(y ~ x, sigma ~ 1), data = dat, family = gaussian())
}

minimal_pair_association <- function() {
  structure(list(
    status = "interior",
    eta_internal = 0.2,
    components = list(
      pair_class = "bernoulli_bernoulli",
      binary_1_p = c(0.2, 0.7),
      binary_2_p = c(0.4, 0.8)
    ),
    response_names = c("y1", "y2")
  ), class = "drm_pair_association")
}

expect_nsim_guard <- function(expr) {
  expect_error(expr, "one positive whole number", class = "rlang_error")
}

test_that("count guard #1719: drm_quantile_residuals rejects non-finite nsim", {
  fit <- minimal_gaussian_fit()
  for (bad in nsim_invalid) {
    expect_nsim_guard(drmTMB:::drm_quantile_residuals(fit, nsim = bad))
  }
})

test_that("count guard #1719: simulate.drm_pair_association rejects non-finite nsim", {
  fit <- minimal_pair_association()
  for (bad in nsim_invalid) {
    expect_nsim_guard(simulate(fit, nsim = bad))
  }
})

test_that("count guard #1719: shared helper matches Julia simulate entry checks", {
  for (bad in nsim_invalid) {
    expect_nsim_guard(drmTMB:::drm_abort_unless_positive_finite_whole(bad))
  }
  expect_identical(drmTMB:::drm_abort_unless_positive_finite_whole(2), 2L)
})