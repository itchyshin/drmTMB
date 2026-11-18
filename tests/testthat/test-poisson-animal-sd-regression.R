poisson_animal_sd_fixture <- function(seed = 20261027L, n_id = 192L, n_each = 24L) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  kernel_order <- c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L))
  A_base <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
  A <- A_base[kernel_order, kernel_order]
  dimnames(A) <- list(id_levels[kernel_order], id_levels[kernel_order])
  z_id <- rep(c(-0.5, 0.5), length.out = n_id)
  alpha <- c(`(Intercept)` = log(0.4), z = 0.35)
  latent_kernel <- as.vector(t(chol(A)) %*% stats::rnorm(n_id)) *
    exp(alpha[[1L]] + alpha[[2L]] * z_id[kernel_order])
  names(latent_kernel) <- id_levels[kernel_order]
  latent <- latent_kernel[id_levels]
  id_index <- rep(seq_len(n_id), each = n_each)
  id <- factor(id_levels[id_index], levels = id_levels)
  z <- z_id[id_index]
  x <- stats::rnorm(length(id))
  mu <- exp(0.3 + 0.2 * x + latent[id])
  data <- data.frame(y = stats::rpois(length(mu), mu), id, x, z)
  list(data = data, A = A, alpha = alpha)
}

test_that("Poisson animal intercepts support predictor-dependent SDs", {
  skip_on_cran()
  fx <- poisson_animal_sd_fixture()
  A <- fx$A
  fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, A = A),
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
  # Structured predictions follow the provider matrix's group order.
  expect_named(sd_prediction, rownames(A))
  expect_equal(length(sd_prediction), nlevels(fx$data$id))
  expect_equal(
    unname(sd_prediction),
    unname(exp(coef(fit, "sd_animal(id)")[["(Intercept)"]] +
      coef(fit, "sd_animal(id)")[["z"]] *
        fx$data$z[match(names(sd_prediction), as.character(fx$data$id))])),
    tolerance = 1e-10
  )
  simulated <- simulate(fit, nsim = 1L, seed = 20261028L)
  expect_length(simulated[[1L]], nrow(fx$data))
  saved_fit <- tempfile(fileext = ".rds")
  on.exit(unlink(saved_fit), add = TRUE)
  saveRDS(fit, saved_fit)
  reloaded_fit <- readRDS(saved_fit)
  expect_equal(
    predict(reloaded_fit, dpar = "sd_animal(id)"),
    sd_prediction,
    tolerance = 1e-12
  )

  base_fit <- drmTMB(
    bf(y ~ x + animal(1 | id, A = A)),
    family = stats::poisson(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(y ~ x + animal(1 | id, A = A), sd(id, level = "animal") ~ 1),
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
