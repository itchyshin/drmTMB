# Margin blocks in R/associate-pairs-sandwich-nbinom2-nbinom2.R.

test_that("drm_pair_nbinom2_nbinom2_sandwich_margin_block() builds score and bread matrices", {
  n <- 9L
  y <- stats::rnbinom(n, size = 3, mu = 2)
  mu <- rep(2.2, n)
  sigma <- rep(0.7, n)
  x <- cbind(`(Intercept)` = 1, x = stats::rnorm(n))
  z <- cbind(`(Intercept)` = 1, s = 0.1 * seq_len(n))

  block <- drmTMB:::drm_pair_nbinom2_nbinom2_sandwich_margin_block(y, mu, sigma, x, z)
  expect_named(
    block,
    c("score_mu", "score_sigma", "bread_mu_mu", "bread_mu_sigma", "bread_sigma_sigma")
  )
  expect_equal(dim(block$score_mu), c(n, ncol(x)))
  expect_equal(dim(block$score_sigma), c(n, ncol(z)))
  expect_true(all(is.finite(block$score_mu)))
  expect_true(all(is.finite(block$score_sigma)))
  expect_equal(dim(block$bread_mu_mu), c(ncol(x), ncol(x)))
  expect_equal(dim(block$bread_sigma_sigma), c(ncol(z), ncol(z)))
})

test_that("drm_pair_nbinom2_nbinom2_sandwich_bread() assembles a symmetric block matrix", {
  n <- 3L
  x <- cbind(`(Intercept)` = rep(1, n), x = c(0.1, 0.2, 0.3))
  z <- matrix(1, n, 1)
  y <- c(1L, 2L, 0L)
  block <- drmTMB:::drm_pair_nbinom2_nbinom2_sandwich_margin_block(
    y, rep(1.5, n), rep(0.9, n), x, z
  )
  bread <- drmTMB:::drm_pair_nbinom2_nbinom2_sandwich_bread(block)
  expect_equal(nrow(bread), ncol(x) + ncol(z))
  expect_equal(ncol(bread), ncol(x) + ncol(z))
  expect_equal(bread, t(bread), tolerance = 1e-12)
  expect_true(all(is.finite(bread)))
})

test_that("drm_pair_nbinom2_nbinom2_sandwich() guards pair class", {
  expect_error(
    drmTMB:::drm_pair_nbinom2_nbinom2_sandwich(
      list(), list(),
      structure(list(components = list(pair_class = "gaussian_nbinom2")), class = "drm_pair_association")
    ),
    "ordinary-NB2 x ordinary-NB2"
  )
})

test_that("drm_pair_nbinom2_nbinom2_sandwich() is unavailable when association is not interior", {
  stub <- structure(
    list(
      components = list(pair_class = "nbinom2_nbinom2"),
      status = "failed"
    ),
    class = "drm_pair_association"
  )
  out <- drmTMB:::drm_pair_nbinom2_nbinom2_sandwich(list(), list(), stub)
  expect_equal(out$status, "unavailable")
  expect_equal(out$reason, "association_unresolved")
})