poisson_animal_ainv_sd_fixture <- function(seed = 20261027L, n_id = 192L, n_each = 24L) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  matrix_order <- c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L))
  A_base <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
  A <- A_base[matrix_order, matrix_order]
  dimnames(A) <- list(id_levels[matrix_order], id_levels[matrix_order])
  Q <- solve(A)
  z_id <- rep(c(-0.5, 0.5), length.out = n_id)
  alpha <- c(`(Intercept)` = log(0.4), z = 0.35)
  latent_matrix_order <- as.vector(t(chol(A)) %*% stats::rnorm(n_id)) *
    exp(alpha[[1L]] + alpha[[2L]] * z_id[matrix_order])
  names(latent_matrix_order) <- id_levels[matrix_order]
  latent <- latent_matrix_order[id_levels]
  id_index <- rep(seq_len(n_id), each = n_each)
  id <- factor(id_levels[id_index], levels = id_levels)
  z <- z_id[id_index]
  x <- stats::rnorm(length(id))
  mu <- exp(0.3 + 0.2 * x + latent[id])
  data <- data.frame(y = stats::rpois(length(mu), mu), id, x, z)
  list(data = data, Q = Q, alpha = alpha)
}

test_that("Poisson animal intercepts support predictor-dependent SDs with Ainv", {
  skip_on_cran()
  fx <- poisson_animal_ainv_sd_fixture()
  Q <- fx$Q
  expect_false(identical(rownames(Q), levels(fx$data$id)))
  expect_identical(rownames(Q), colnames(Q))
  fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, Ainv = Q),
      sd(id, level = "animal") ~ z
    ),
    family = stats::poisson(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd_animal(id)"), c("(Intercept)", "z"))
  expect_lt(abs(coef(fit, "sd_animal(id)")[["z"]] - fx$alpha[["z"]]), 0.25)
  sd_prediction <- predict(fit, dpar = "sd_animal(id)")
  # Structured coefficient SDs follow the supplied matrix's row order.  Ainv
  # is deliberately permuted in this fixture, so check both complete label
  # coverage and the documented provider order, then verify values by label.
  expect_setequal(names(sd_prediction), levels(fx$data$id))
  expect_named(sd_prediction, rownames(Q))
  expect_equal(length(sd_prediction), nlevels(fx$data$id))
  z_by_id <- as.numeric(tapply(
    fx$data$z,
    fx$data$id,
    function(x) unique(x)[[1L]]
  ))
  names(z_by_id) <- levels(fx$data$id)
  sd_coef <- coef(fit, "sd_animal(id)")
  expect_equal(
    unname(sd_prediction),
    unname(exp(sd_coef[["(Intercept)"]] + sd_coef[["z"]] *
      z_by_id[names(sd_prediction)])),
    tolerance = 1e-10
  )

  base_fit <- drmTMB(
    bf(y ~ x + animal(1 | id, Ainv = Q)),
    family = stats::poisson(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(y ~ x + animal(1 | id, Ainv = Q), sd(id, level = "animal") ~ 1),
    family = stats::poisson(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(constant_fit)),
    as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
})
