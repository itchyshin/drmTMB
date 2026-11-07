# b26 companion for evidence id
#   gaussian-native-structured-direct-sd-providers-20261101-20261101d
# (test-gaussian-structured-direct-sd-providers.R), spatial_coordinate_intercept
# row.
#
# Ledger deficiency addressed: the spatial oracle there simulated from, and
# evaluated the dense likelihood with, solve() of
# drmTMB:::drm_spatial_coords_precision (the helper under test). Here the
# kernel is rebuilt by hand, exp(-d / median positive distance) + 1e-6 I from
# dist(coords); data are simulated from it; the exact Gaussian marginal
#   y ~ N(X beta, sigma^2 I + Z diag(tau) K diag(tau) Z')
# is evaluated in base R at the fitted parameters (tolerance 1e-4 absolute on
# logLik). The package's own implied covariance is also compared to the hand
# kernel (1e-8). Emulated bugs must move the oracle by more than 0.1:
# reversed per-site SD vector, sign-flipped SD predictor, coordinates read by
# row position instead of site name, squared-exponential kernel. Coordinates
# are irregular and passed shuffled. No calibration, coverage or parity claim.

test_that("Gaussian spatial intercept SD regression matches a hand-kernel exact oracle", {
  skip_on_cran()
  set.seed(20261221L)
  n_site <- 40L
  n_each <- 6L
  sites <- sprintf("s%02d", seq_len(n_site))
  coords_nat <- data.frame(east = stats::runif(n_site, 0, 4),
                           north = stats::runif(n_site, 0, 3),
                           row.names = sites)
  K <- sb26_spatial_kernel(coords_nat, sites)
  z <- stats::setNames(as.numeric(scale(stats::rnorm(n_site))), sites)
  tau <- exp(log(0.7) + 0.5 * z)
  u <- tau * drop(t(chol(K)) %*% stats::rnorm(n_site))
  lev <- sample(sites)
  site <- factor(rep(lev, each = n_each), levels = lev)
  x <- stats::rnorm(length(site))
  d <- data.frame(
    y = 0.2 + 0.5 * x + u[as.character(site)] + stats::rnorm(length(site), sd = 0.3),
    x = x, site = site, z = unname(z[as.character(site)])
  )
  coords <- coords_nat[sample(sites), , drop = FALSE]
  expect_false(identical(rownames(coords), lev))

  # The package's implied covariance equals the hand-built kernel by name.
  P <- as.matrix(drmTMB:::drm_spatial_coords_precision(
    coords, site = lev, group = "site"
  )$precision)
  rownames(P) <- colnames(P) <- NULL
  expect_equal(unname(solve(P)), unname(K[lev, lev]), tolerance = 1e-8)

  fit <- drmTMB(
    bf(y ~ x + spatial(1 | site, coords = coords), sd(site, level = "spatial") ~ z),
    family = stats::gaussian(), data = d, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  a <- coef(fit, "sd_spatial(site)")
  expect_named(a, c("(Intercept)", "z"))
  s_hat <- exp(a[[1L]] + a[[2L]] * z[lev])
  names(s_hat) <- lev
  expect_gt(stats::sd(log(s_hat)), 0.1)
  expect_equal(unname(predict(fit, dpar = "sd_spatial(site)")[lev]),
               unname(s_hat), tolerance = 1e-8)

  beta <- coef(fit, "mu")
  mu <- beta[[1L]] + beta[[2L]] * d$x
  idx <- as.integer(d$site)
  oracle <- function(Kmat, s) {
    sb26_gauss_loglik(d$y, mu, unname(sigma(fit)),
                      sb26_Z(idx, n_site, s), Kmat)
  }
  K_by_name <- K[lev, lev]
  ref <- oracle(K_by_name, s_hat)
  expect_lt(abs(as.numeric(logLik(fit)) - ref), 1e-4)

  expect_gt(abs(oracle(K_by_name, sb26_reverse(s_hat)) - ref), 0.1)
  s_flip <- exp(a[[1L]] - a[[2L]] * z[lev])
  expect_gt(abs(oracle(K_by_name, s_flip) - ref), 0.1)
  K_positional <- sb26_spatial_kernel(
    data.frame(east = coords$east, north = coords$north, row.names = lev), lev
  )
  expect_gt(abs(oracle(K_positional, s_hat) - ref), 0.1)
  dm <- as.matrix(stats::dist(as.matrix(coords[lev, 1:2])))
  K_sq <- exp(-(dm / stats::median(dm[upper.tri(dm)]))^2)
  diag(K_sq) <- diag(K_sq) + 1e-6
  expect_gt(abs(oracle(K_sq, s_hat) - ref), 0.1)
})
