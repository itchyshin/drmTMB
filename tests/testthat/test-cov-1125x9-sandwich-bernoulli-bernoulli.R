# Analytic blocks in R/associate-pairs-sandwich-bernoulli-bernoulli.R (not gaussian-bernoulli).

test_that("drm_pair_bernoulli_bernoulli_sandwich_margin_blocks() shapes scores and breads", {
  n <- 8L
  y_l <- sample(0:1, n, replace = TRUE)
  y_r <- sample(0:1, n, replace = TRUE)
  x_l <- cbind(`(Intercept)` = 1, x = seq_len(n) / n)
  x_r <- cbind(`(Intercept)` = 1, z = (seq_len(n) - 4) / 4)
  p_l <- stats::plogis(x_l %*% c(0.2, -0.3))
  p_r <- stats::plogis(x_r %*% c(-0.1, 0.4))

  blocks <- drmTMB:::drm_pair_bernoulli_bernoulli_sandwich_margin_blocks(
    y_l, y_r, p_l, p_r, x_l, x_r
  )
  expect_named(blocks, c("score_l", "score_r", "bread_l", "bread_r"))
  expect_equal(dim(blocks$score_l), c(n, ncol(x_l)))
  expect_equal(dim(blocks$score_r), c(n, ncol(x_r)))
  expect_equal(dim(blocks$bread_l), c(ncol(x_l), ncol(x_l)))
  expect_equal(dim(blocks$bread_r), c(ncol(x_r), ncol(x_r)))
  expect_true(all(is.finite(blocks$score_l)))
  expect_true(all(is.finite(blocks$score_r)))
  expect_true(all(is.finite(blocks$bread_l)))
  expect_true(all(is.finite(blocks$bread_r)))
  expect_equal(blocks$score_l[1, 1], x_l[1, 1] * (y_l[1] - p_l[1]))
  expect_equal(blocks$score_r[2, 2], x_r[2, 2] * (y_r[2] - p_r[2]))
})

test_that("drm_pair_bernoulli_bernoulli_sandwich_association_blocks() returns ok for interior data", {
  n <- 12L
  set.seed(11250901L)
  y_l <- sample(0:1, n, replace = TRUE)
  y_r <- sample(0:1, n, replace = TRUE)
  x_l <- cbind(1, rnorm(n))
  x_r <- cbind(1, rnorm(n))
  x_a <- cbind(1, rnorm(n))
  lambda_l <- c(0.1, -0.05) %*% t(x_l)
  lambda_r <- c(-0.2, 0.08) %*% t(x_r)
  a <- rep(0.05, n)
  assoc <- drmTMB:::drm_pair_bernoulli_bernoulli_sandwich_association_blocks(
    y_l, y_r, as.vector(lambda_l), as.vector(lambda_r), a,
    x_l, x_r, x_a, drmTMB:::drm_pair_sandwich_control()
  )
  expect_equal(assoc$status, "ok")
  expect_equal(nrow(assoc$score_a), n)
  expect_equal(ncol(assoc$score_a), ncol(x_a))
  expect_equal(dim(assoc$bread_aa), c(ncol(x_a), ncol(x_a)))
  expect_equal(dim(assoc$bread_al), c(ncol(x_a), ncol(x_l)))
  expect_equal(dim(assoc$bread_ar), c(ncol(x_a), ncol(x_r)))
  expect_type(assoc$derivative_diagnostics, "list")
  expect_length(assoc$derivative_diagnostics, n)
})

test_that("drm_pair_bernoulli_bernoulli_sandwich_row_logprob() matches rectangle log density", {
  lp <- drmTMB:::drm_pair_bernoulli_bernoulli_sandwich_row_logprob(
    y_l = 1L, y_r = 0L, lambda_l = 0.2, lambda_r = -0.1, a = 0.15
  )
  expect_type(lp, "double")
  expect_length(lp, 1L)
  expect_true(is.finite(lp))
  expect_lt(lp, 0)
  expect_true(lp <= 0)
})

test_that("drm_pair_bernoulli_bernoulli_sandwich() aborts on wrong pair class", {
  expect_error(
    drmTMB:::drm_pair_bernoulli_bernoulli_sandwich(
      list(), list(),
      structure(list(components = list(pair_class = "gaussian_bernoulli")), class = "drm_pair_association")
    ),
    "Bernoulli x Bernoulli"
  )
})

test_that("drm_pair_bernoulli_bernoulli_sandwich() is unavailable when association fails", {
  stub <- structure(
    list(
      components = list(pair_class = "bernoulli_bernoulli"),
      status = "failed"
    ),
    class = "drm_pair_association"
  )
  out <- drmTMB:::drm_pair_bernoulli_bernoulli_sandwich(list(), list(), stub)
  expect_equal(out$status, "unavailable")
  expect_equal(out$reason, "association_unresolved")
})