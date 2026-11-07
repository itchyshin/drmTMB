tweedie_relmat_sd_data <- function(seed = 20261022L, groups = 32L, repeats = 8L) {
  set.seed(seed)
  id_levels <- paste0("id_", seq_len(groups))
  id_index <- rep(seq_len(groups), each = repeats)
  id <- factor(id_levels[id_index], levels = id_levels)
  order <- sample.int(groups)
  correlation <- outer(order, order, function(i, j) 0.4^abs(i - j))
  kernel_scale <- rep(c(1, 1.5), length.out = groups)
  K <- diag(kernel_scale) %*% correlation %*% diag(kernel_scale)
  dimnames(K) <- list(id_levels[order], id_levels[order])

  z_group <- setNames(sample(rep(c(-1, 1), length.out = groups)), id_levels)
  z <- z_group[id_index]
  x <- stats::runif(length(id), -1, 1)
  alpha <- c("(Intercept)" = log(0.45), z = 0.45)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z_group)
  latent_unit <- setNames(
    as.vector(t(chol(K)) %*% stats::rnorm(groups)), id_levels[order]
  )
  latent <- tau[names(latent_unit)] * latent_unit
  mu <- exp(0.25 + 0.2 * x + latent[id_levels[id_index]])
  sigma <- 0.7
  nu <- 1.4
  y <- drmTMB:::rtweedie_compound(
    length(mu), mu = mu, phi = sigma^2, power = nu
  )

  list(
    data = data.frame(y = y, x = x, z = z, z_constant = 1, id = id),
    K = K,
    z_group = z_group,
    alpha = alpha
  )
}

test_that("Tweedie relmat SD regression recovers group-level scale effects", {
  sim <- tweedie_relmat_sd_data()
  K <- sim$K
  fit <- drmTMB(
    bf(
      y ~ x + relmat(1 | id, K = K),
      sigma ~ 1,
      nu ~ 1,
      sd(id, level = "relmat") ~ z
    ),
    family = tweedie(),
    data = sim$data,
    control = drm_control(se = FALSE)
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd_relmat(id)"), names(sim$alpha))
  expect_gt(coef(fit, "sd_relmat(id)")[["z"]], 0)
  expect_lt(abs(coef(fit, "sd_relmat(id)")[["z"]] - sim$alpha[["z"]]), 0.5)
  sd_prediction <- predict(fit, dpar = "sd_relmat(id)")
  expect_setequal(names(sd_prediction), names(sim$z_group))
  beta_hat <- coef(fit, "sd_relmat(id)")
  expected_sd <- exp(beta_hat[["(Intercept)"]] + beta_hat[["z"]] * sim$z_group)
  expect_equal(
    unname(sd_prediction[names(expected_sd)]),
    unname(expected_sd),
    tolerance = 1e-10
  )
  parameter_prediction <- predict_parameters(fit, dpar = "sd_relmat(id)")
  expect_true(all(parameter_prediction$dpar == "sd_relmat(id)"))
  expect_equal(nrow(parameter_prediction), length(sim$z_group))
})

test_that("Tweedie relmat constant-SD formula has equivalent coding", {
  sim <- tweedie_relmat_sd_data(seed = 20261023L)
  K <- sim$K
  fit_intercept <- drmTMB(
    bf(
      y ~ x + relmat(1 | id, K = K),
      sigma ~ 1,
      nu ~ 1,
      sd(id, level = "relmat") ~ 1
    ),
    family = tweedie(),
    data = sim$data,
    control = drm_control(se = FALSE)
  )
  fit_unit_column <- drmTMB(
    bf(
      y ~ x + relmat(1 | id, K = K),
      sigma ~ 1,
      nu ~ 1,
      sd(id, level = "relmat") ~ 0 + z_constant
    ),
    family = tweedie(),
    data = sim$data,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit_unit_column$opt$convergence, 0L)
  expect_equal(
    as.numeric(stats::logLik(fit_unit_column)),
    as.numeric(stats::logLik(fit_intercept)),
    tolerance = 2e-5
  )
  expect_equal(
    coef(fit_unit_column, "sd_relmat(id)"),
    setNames(coef(fit_intercept, "sd_relmat(id)")[["(Intercept)"]], "z_constant"),
    tolerance = 1e-4
  )
})
