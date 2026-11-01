binomial_relmat_precision_sd_fixture <- function(
  seed = 6201020L,
  n_id = 192L,
  n_each = 20L
) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  kernel_order <- rev(seq_len(n_id))
  K <- outer(kernel_order, kernel_order, function(i, j) 0.45^abs(i - j))
  dimnames(K) <- list(id_levels[kernel_order], id_levels[kernel_order])
  z_id <- rep(c(-0.5, 0.5), length.out = n_id)
  alpha <- c(`(Intercept)` = log(0.45), z = 0.45)
  latent_sd <- exp(alpha[[1L]] + alpha[[2L]] * z_id)
  effect_in_kernel_order <- as.vector(t(chol(K)) %*% stats::rnorm(n_id)) *
    latent_sd[kernel_order]
  names(effect_in_kernel_order) <- id_levels[kernel_order]
  effect <- effect_in_kernel_order[id_levels]

  id <- rep(id_levels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  z <- rep(z_id, each = n_each)
  eta <- -0.2 + 0.55 * x + effect[id]
  y <- stats::rbinom(length(id), size = 1L, prob = stats::plogis(eta))

  precision_order <- c(seq.int(2L, n_id, by = 2L), seq.int(1L, n_id, by = 2L))
  Q <- solve(K[precision_order, precision_order, drop = FALSE])
  list(
    data = data.frame(id = factor(id, levels = id_levels), x = x, z = z, y = y),
    K = K,
    Q = Q,
    alpha = alpha,
    latent_sd = stats::setNames(latent_sd, id_levels)
  )
}

test_that("binomial relmat SD regression gives equivalent covariance and precision fits", {
  skip_on_cran()
  fx <- binomial_relmat_precision_sd_fixture()
  K <- fx$K
  Q <- fx$Q
  expect_false(identical(rownames(K), rownames(Q)))
  expect_identical(rownames(Q), colnames(Q))

  fit_K <- drmTMB(
    bf(
      y ~ x + relmat(1 | id, K = K),
      sd(id, level = "relmat") ~ z
    ),
    family = stats::binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  fit_Q <- drmTMB(
    bf(
      y ~ x + relmat(1 | id, Q = Q),
      sd(id, level = "relmat") ~ z
    ),
    family = stats::binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit_K$opt$convergence, 0L)
  expect_equal(fit_Q$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(fit_Q)), as.numeric(logLik(fit_K)), tolerance = 2e-6)
  expect_equal(
    coef(fit_Q, "sd_relmat(id)"),
    coef(fit_K, "sd_relmat(id)"),
    tolerance = 2e-6
  )
  expect_lt(
    abs(coef(fit_Q, "sd_relmat(id)")[["z"]] - fx$alpha[["z"]]),
    0.2
  )
  pred_K <- predict(fit_K, dpar = "sd_relmat(id)")
  pred_Q <- predict(fit_Q, dpar = "sd_relmat(id)")
  expect_false(identical(names(pred_K), names(pred_Q)))
  expect_equal(
    unname(pred_Q[names(pred_K)]),
    unname(pred_K),
    tolerance = 2e-6
  )
})
