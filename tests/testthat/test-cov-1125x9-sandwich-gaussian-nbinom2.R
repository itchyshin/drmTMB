# Blocks and guards in R/associate-pairs-sandwich-gaussian-nbinom2.R.

test_that("drm_pair_gaussian_nbinom2_sandwich_margin_blocks() returns finite scores", {
  n <- 7L
  gaussian_y <- stats::rnorm(n)
  nbinom2_y <- stats::rnbinom(n, size = 2, mu = 3)
  gaussian_mu <- rep(0.1, n)
  gaussian_sigma <- rep(1.2, n)
  nbinom2_mu <- rep(2.5, n)
  nbinom2_sigma <- rep(0.8, n)
  x_g <- cbind(1, seq_len(n) / n)
  z_g <- matrix(1, n, 1)
  x_n <- cbind(1, (seq_len(n) - 4) / 3)
  z_n <- cbind(1, 0.1 * seq_len(n))

  blocks <- drmTMB:::drm_pair_gaussian_nbinom2_sandwich_margin_blocks(
    gaussian_y, nbinom2_y, gaussian_mu, gaussian_sigma,
    nbinom2_mu, nbinom2_sigma, x_g, z_g, x_n, z_n
  )
  expect_named(
    blocks,
    c(
      "score_g_mu", "score_g_sigma", "score_n_mu", "score_n_sigma",
      "bread_g_mm", "bread_g_ms", "bread_g_ss",
      "bread_n_mm", "bread_n_ms", "bread_n_ss"
    )
  )
  expect_equal(nrow(blocks$score_g_mu), n)
  expect_equal(ncol(blocks$score_g_mu), ncol(x_g))
  expect_equal(nrow(blocks$score_n_sigma), n)
  expect_true(all(is.finite(blocks$score_g_mu)))
  expect_true(all(is.finite(blocks$score_n_mu)))
  expect_equal(dim(blocks$bread_g_mm), c(ncol(x_g), ncol(x_g)))
  expect_equal(dim(blocks$bread_n_ss), c(ncol(z_n), ncol(z_n)))
})

test_that("drm_pair_gaussian_nbinom2_eta_sandwich() refuses non-association fits", {
  expect_error(
    drmTMB:::drm_pair_gaussian_nbinom2_eta_sandwich(
      list(model = list(model_type = "poisson")),
      list(model = list(model_type = "gaussian")),
      structure(
        list(components = list(pair_class = "other")),
        class = "drm_pair_association"
      )
    ),
    "Gaussian x ordinary-NB2"
  )
})

test_that("drm_pair_gaussian_nbinom2_eta_sandwich() is unavailable for unresolved association", {
  stub <- structure(
    list(
      components = list(pair_class = "gaussian_nbinom2"),
      status = "failed"
    ),
    class = "drm_pair_association"
  )
  out <- drmTMB:::drm_pair_gaussian_nbinom2_eta_sandwich(list(), list(), stub)
  expect_equal(out$status, "unavailable")
  expect_equal(out$reason, "association_unresolved")
})

test_that("drm_pair_gaussian_nbinom2_sandwich_row_logprob() returns a finite scalar", {
  lp <- drmTMB:::drm_pair_gaussian_nbinom2_sandwich_row_logprob(
    gaussian_y = 0.3,
    nbinom2_y = 2L,
    m = 0.1,
    tau_g = log(1.1),
    xi_n = log(2),
    tau_n = log(0.9),
    a = 0.05
  )
  expect_type(lp, "double")
  expect_length(lp, 1L)
  expect_true(is.finite(lp) || is.na(lp))
})