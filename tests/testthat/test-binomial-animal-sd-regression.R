binomial_animal_sd_fixture <- function(seed = 6201026L, n_id = 128L, n_each = 20L) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  kernel_order <- rev(seq_len(n_id))
  A <- outer(kernel_order, kernel_order, function(i, j) 0.4^abs(i - j))
  dimnames(A) <- list(id_levels[kernel_order], id_levels[kernel_order])
  z_id <- rep(c(-0.5, 0.5), length.out = n_id)
  alpha <- c(`(Intercept)` = log(0.45), z = 0.4)
  latent_sd <- exp(alpha[[1L]] + alpha[[2L]] * z_id)
  effect_kernel <- as.vector(t(chol(A)) %*% stats::rnorm(n_id)) *
    latent_sd[kernel_order]
  names(effect_kernel) <- id_levels[kernel_order]
  effect <- effect_kernel[id_levels]
  id_index <- rep(seq_len(n_id), each = n_each)
  id <- factor(id_levels[id_index], levels = id_levels)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  z <- z_id[id_index]
  eta <- -0.2 + 0.55 * x + effect[id]
  data <- data.frame(
    y = stats::rbinom(length(id), size = 1L, prob = stats::plogis(eta)),
    id = id,
    x = x,
    z = z
  )
  list(data = data, A = A, alpha = alpha, latent_sd = stats::setNames(latent_sd, id_levels))
}

test_that("Binomial animal intercepts support predictor-dependent SDs", {
  skip_on_cran()
  fx <- binomial_animal_sd_fixture()
  A <- fx$A
  fit <- drmTMB(
    bf(
      y ~ x + animal(1 | id, A = A),
      sd(id, level = "animal") ~ z
    ),
    family = stats::binomial(),
    data = fx$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_named(fit$coefficients, c("mu", "sd_animal(id)"))
  expect_named(fit$coefficients[["sd_animal(id)"]], c("(Intercept)", "z"))
  expect_setequal(
    names(fit$sdpars[["sd_animal(id)"]]),
    paste0("sd_animal(id):", levels(fx$data$id))
  )
  expect_lt(abs(fit$coefficients[["sd_animal(id)"]][["z"]] - fx$alpha[["z"]]), 0.25)
  expect_equal(
    unname(predict(fit, dpar = "sd_animal(id)")),
    unname(fit$sdpars[["sd_animal(id)"]]),
    tolerance = 1e-10
  )
  targets <- profile_targets(fit)
  expect_true("fixef:sd_animal(id):z" %in% targets$parm)
  save_file <- tempfile(fileext = ".rds")
  on.exit(unlink(save_file), add = TRUE)
  saveRDS(fit, save_file)
  reloaded <- readRDS(save_file)
  expect_equal(coef(reloaded, "sd_animal(id)"), coef(fit, "sd_animal(id)"))
  expect_equal(
    predict(reloaded, dpar = "sd_animal(id)"),
    predict(fit, dpar = "sd_animal(id)")
  )
  expect_length(simulate(fit, nsim = 1L, seed = 6201027L)[[1L]], nrow(fx$data))

  base_fit <- drmTMB(
    bf(y ~ x + animal(1 | id, A = A)),
    family = stats::binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(y ~ x + animal(1 | id, A = A), sd(id, level = "animal") ~ 1),
    family = stats::binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)), tolerance = 2e-5)

  inconsistent <- fx$data
  inconsistent$z[[1L]] <- inconsistent$z[[1L]] + 1
  expect_error(
    drmTMB(
      bf(
        y ~ x + animal(1 | id, A = A),
        sd(id, level = "animal") ~ z
      ),
      family = stats::binomial(),
      data = inconsistent
    ),
    "constant within"
  )
})
