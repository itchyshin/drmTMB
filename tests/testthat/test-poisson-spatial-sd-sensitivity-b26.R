# b26 companion for evidence id native-poisson-spatial-sd-20261101
# (test-poisson-spatial-sd-regression.R).
#
# Ledger deficiency addressed: that test has no independent likelihood oracle
# ("no dense reference"; its Laplace comparison was built from the package's
# own spatial precision helper). Here the spatial kernel is built by hand from
# dist(coords) as exp(-d / median positive distance) + 1e-6 I, the data are
# simulated from that kernel, and a dense Laplace marginal in base R (see
# helper-sb26-oracle.R) is evaluated at the fitted parameters for both an
# intercept field spatial(1 | site) and a slope-only field spatial(0 + x | site).
# Tolerance 1e-4 absolute on logLik. Each emulated bug must move the oracle by
# more than 0.1 log-likelihood units. Coordinates are irregular (not a ring,
# so no reflection symmetry hides a misalignment) and passed in a shuffled row
# order. No calibration, coverage or parity claim.

sb26_pois_sp_fixture <- function(kind, seed, n_site = 30L, n_each = 14L) {
  set.seed(seed)
  sites <- sprintf("s%02d", seq_len(n_site))
  coords_nat <- data.frame(east = stats::runif(n_site, 0, 3),
                           north = stats::runif(n_site, 0, 2),
                           row.names = sites)
  K <- sb26_spatial_kernel(coords_nat, sites)
  z <- stats::setNames(as.numeric(scale(stats::rnorm(n_site))), sites)
  tau <- exp(log(0.6) + 0.5 * z)
  field <- tau * drop(t(chol(K)) %*% stats::rnorm(n_site))
  # Data factor levels are not the natural order; coordinate rows are shuffled.
  lev <- sample(sites)
  site <- factor(rep(lev, each = n_each), levels = lev)
  x <- stats::rnorm(length(site))
  u <- field[as.character(site)]
  eta <- 0.2 + 0.3 * x + if (identical(kind, "slope")) 1.6 * x * u else u
  coords <- coords_nat[sample(sites), , drop = FALSE]
  list(
    data = data.frame(y = stats::rpois(length(eta), exp(eta)), x = x, site = site,
                      z = unname(z[as.character(site)])),
    coords = coords, K = K, z = z, sites = sites, lev = lev
  )
}

sb26_pois_sp_check <- function(kind, seed) {
  fx <- sb26_pois_sp_fixture(kind, seed)
  d <- fx$data
  coords <- fx$coords
  term <- if (identical(kind, "slope")) {
    y ~ x + spatial(0 + x | site, coords = coords)
  } else {
    y ~ x + spatial(1 | site, coords = coords)
  }
  fit <- drmTMB(
    bf(term, sd(site, level = "spatial") ~ z),
    family = stats::poisson(), data = d, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  lev <- fx$lev
  a <- coef(fit, "sd_spatial(site)")
  expect_named(a, c("(Intercept)", "z"))
  s_hat <- exp(a[[1L]] + a[[2L]] * fx$z[lev])
  names(s_hat) <- lev
  expect_gt(stats::sd(log(s_hat)), 0.1)
  expect_equal(unname(predict(fit, dpar = "sd_spatial(site)")[lev]),
               unname(s_hat), tolerance = 1e-8)

  beta <- coef(fit, "mu")
  eta_fixed <- beta[[1L]] + beta[[2L]] * d$x
  w <- if (identical(kind, "slope")) d$x else 1
  idx <- as.integer(d$site)
  oracle <- function(K, s) {
    sb26_laplace(sb26_deriv_poisson(d$y), eta_fixed,
                 sb26_Z(idx, length(lev), s, w), K)
  }
  K_by_name <- fx$K[lev, lev]
  ref <- oracle(K_by_name, s_hat)
  expect_lt(abs(as.numeric(logLik(fit)) - ref), 1e-4)

  # Emulated bugs.
  expect_gt(abs(oracle(K_by_name, sb26_reverse(s_hat)) - ref), 0.1)
  s_flip <- exp(a[[1L]] - a[[2L]] * fx$z[lev])
  expect_gt(abs(oracle(K_by_name, s_flip) - ref), 0.1)
  # Coordinates read by row position (the shuffled supplied order) instead of
  # by site name.
  K_positional <- sb26_spatial_kernel(
    data.frame(east = fx$coords$east, north = fx$coords$north,
               row.names = lev),
    lev
  )
  expect_gt(abs(oracle(K_positional, s_hat) - ref), 0.1)
  # Wrong kernel convention: squared-exponential at the same range.
  dm <- as.matrix(stats::dist(as.matrix(fx$coords[lev, 1:2])))
  K_sq <- exp(-(dm / stats::median(dm[upper.tri(dm)]))^2)
  diag(K_sq) <- diag(K_sq) + 1e-6
  expect_gt(abs(oracle(K_sq, s_hat) - ref), 0.1)
  invisible(fit)
}

test_that("Poisson spatial intercept SD regression matches a hand-kernel dense Laplace oracle", {
  skip_on_cran()
  sb26_pois_sp_check("intercept", 20261211L)
})

test_that("Poisson spatial slope-only SD regression matches a hand-kernel dense Laplace oracle", {
  skip_on_cran()
  sb26_pois_sp_check("slope", 20261212L)
})
