binomial_animal_ainv_sd_fixture <- function(
  seed = 6201026L,
  n_id = 128L,
  n_each = 20L
) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  matrix_order <- rev(seq_len(n_id))
  A <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.4^abs(i - j))
  dimnames(A) <- list(id_levels, id_levels)
  A_ordered <- A[matrix_order, matrix_order, drop = FALSE]
  Ainv <- solve(A_ordered)
  dimnames(Ainv) <- list(id_levels[matrix_order], id_levels[matrix_order])

  z_id <- setNames(rep(c(-0.5, 0.5), length.out = n_id), id_levels)
  alpha <- c(`(Intercept)` = log(0.45), z = 0.4)
  group_sd <- exp(alpha[["(Intercept)"]] + alpha[["z"]] * z_id)
  latent_ordered <- as.vector(
    t(chol(A_ordered)) %*% stats::rnorm(n_id)
  ) * group_sd[id_levels[matrix_order]]
  names(latent_ordered) <- id_levels[matrix_order]
  latent <- latent_ordered[id_levels]

  id_index <- rep(seq_len(n_id), each = n_each)
  id <- factor(id_levels[id_index], levels = id_levels)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  z <- unname(z_id[as.character(id)])
  eta <- -0.2 + 0.55 * x + latent[as.character(id)]
  data <- data.frame(
    y = stats::rbinom(length(eta), size = 1L, prob = stats::plogis(eta)),
    id = id,
    x = x,
    z = z
  )

  list(data = data, A = A, Ainv = Ainv, alpha = alpha, z_id = z_id)
}

test_that("Binomial animal Ainv precision supports predictor-dependent SDs", {
  skip_on_cran()
  fx <- binomial_animal_ainv_sd_fixture()
  Ainv <- fx$Ainv
  expect_false(identical(levels(fx$data$id), rownames(Ainv)))
  expect_equal(
    Ainv,
    solve(fx$A[rownames(Ainv), rownames(Ainv), drop = FALSE]),
    tolerance = 1e-10
  )

  fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, Ainv = Ainv),
      sd(id, level = "animal") ~ z
    ),
    family = stats::binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd_animal(id)"), c("(Intercept)", "z"))
  expect_lt(abs(coef(fit, "sd_animal(id)")[["z"]] - fx$alpha[["z"]]), 0.3)
  sd_prediction <- predict(fit, dpar = "sd_animal(id)")
  expect_setequal(names(sd_prediction), levels(fx$data$id))
  expected_sd <- exp(
    coef(fit, "sd_animal(id)")[["(Intercept)"]] +
      coef(fit, "sd_animal(id)")[["z"]] * fx$z_id[names(sd_prediction)]
  )
  expect_equal(unname(sd_prediction), unname(expected_sd), tolerance = 1e-10)
  expect_length(simulate(fit, nsim = 1L, seed = 20261021L)[[1L]], nrow(fx$data))

  base_fit <- drmTMB(
    bf(y ~ x + animal(1 | id, Ainv = Ainv)),
    family = stats::binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, Ainv = Ainv),
      sd(id, level = "animal") ~ 1
    ),
    family = stats::binomial(),
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
