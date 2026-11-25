# Analytic sandwich blocks in R/associate-pairs-sandwich-gaussian-bernoulli.R.

test_that("drm_pair_gaussian_bernoulli_sandwich_margin_blocks shapes scores and breads", {
  n <- 6L
  gaussian_y <- stats::rnorm(n)
  binary_y <- sample(0:1, n, replace = TRUE)
  gaussian_mu <- rep(0, n)
  gaussian_sigma <- rep(1, n)
  binary_p <- rep(0.4, n)
  x_g <- cbind(1, seq_len(n) / n)
  z_g <- matrix(1, n, 1)
  x_b <- cbind(1, (seq_len(n) - 3) / 2)

  blocks <- drmTMB:::drm_pair_gaussian_bernoulli_sandwich_margin_blocks(
    gaussian_y, binary_y, gaussian_mu, gaussian_sigma, binary_p, x_g, z_g, x_b
  )
  expect_named(
    blocks,
    c(
      "score_g_mu", "score_g_sigma", "score_b",
      "bread_g_mm", "bread_g_ms", "bread_g_ss", "bread_b"
    )
  )
  expect_equal(nrow(blocks$score_g_mu), n)
  expect_equal(ncol(blocks$score_g_mu), ncol(x_g))
  expect_equal(dim(blocks$bread_b), c(ncol(x_b), ncol(x_b)))
  expect_true(all(is.finite(blocks$score_b)))
  expect_true(all(is.finite(blocks$bread_g_mm)))
})

test_that("drm_pair_gaussian_bernoulli_sandwich_row_logprob delegates to loglik", {
  y_g <- 0.5
  y_b <- 1L
  m <- 0.2
  tau <- log(0.8)
  lambda <- 0
  a <- 0.1
  lp <- drmTMB:::drm_pair_gaussian_bernoulli_sandwich_row_logprob(
    y_g, y_b, m, tau, lambda, a
  )
  expect_type(lp, "double")
  expect_length(lp, 1L)
  expect_true(is.finite(lp))
})

test_that("drm_pair_gaussian_bernoulli_eta_sandwich refuses non-association fits", {
  fake_fit <- list(model = list(model_type = "gaussian"))
  expect_error(
    drmTMB:::drm_pair_gaussian_bernoulli_eta_sandwich(
      fake_fit, fake_fit, list(components = list(pair_class = "other"))
    ),
    "Gaussian x literal-Bernoulli"
  )
})

test_that("drm_pair_gaussian_bernoulli_eta_sandwich is unavailable for unresolved association", {
  stub_assoc <- structure(
    list(
      components = list(pair_class = "gaussian_bernoulli"),
      status = "failed"
    ),
    class = "drm_pair_association"
  )
  out <- drmTMB:::drm_pair_gaussian_bernoulli_eta_sandwich(
    list(), list(), stub_assoc
  )
  expect_type(out, "list")
  expect_equal(out$status, "unavailable")
  expect_equal(out$reason, "association_unresolved")
})