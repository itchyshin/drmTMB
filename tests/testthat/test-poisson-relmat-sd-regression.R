test_that("Poisson relmat effects accept a predictor-dependent SD", {
  set.seed(20261021L)
  n_id <- 24L
  n_each <- 10L
  id_levels <- paste0("id_", seq_len(n_id))
  # Keep a non-unit covariance scale so this fixture detects accidental
  # conversion of the supplied covariance to a correlation matrix.
  K <- 1.7 * 0.45 ^ abs(outer(seq_len(n_id), seq_len(n_id), `-`))
  dimnames(K) <- list(id_levels, id_levels)
  z_id <- rep(c(-1, 1), length.out = n_id)
  latent <- as.vector(t(chol(K)) %*% stats::rnorm(n_id))
  sd_id <- exp(log(0.45) + 0.3 * z_id)
  id_index <- rep(seq_len(n_id), each = n_each)
  id <- factor(id_levels[id_index], levels = id_levels)
  z <- z_id[id_index]
  x <- stats::rnorm(length(id))
  mu <- exp(0.4 + 0.2 * x + sd_id[id_index] * latent[id_index])
  dat <- data.frame(y = stats::rpois(length(mu), mu), x, id, z)

  fit <- drmTMB(
    bf(
      y ~ x + relmat(1 | id, K = K),
      sd(id, level = "relmat") ~ z
    ),
    family = stats::poisson(link = "log"),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd_relmat(id)"), c("(Intercept)", "z"))
  expect_true(all(is.finite(coef(fit, "sd_relmat(id)"))))
  expect_lt(
    abs(coef(fit, "sd_relmat(id)")[["(Intercept)"]] - log(0.45)),
    0.35
  )
  expect_lt(
    abs(coef(fit, "sd_relmat(id)")[["z"]] - 0.3),
    0.3
  )
  sd_prediction <- predict(fit, dpar = "sd_relmat(id)")
  expect_named(sd_prediction, id_levels)
  expect_length(sd_prediction, n_id)
  parameter_prediction <- predict_parameters(fit, dpar = "sd_relmat(id)")
  expect_true(all(parameter_prediction$dpar == "sd_relmat(id)"))
  expect_equal(nrow(parameter_prediction), n_id)

  structured <- fit$model$structured$phylo_mu
  random_effect_key <- drmTMB:::structured_mu_random_effect_key(
    structured,
    fit$model$model_type
  )
  random_effects <- ranef(fit, random_effect_key)
  node_sd_row <- fit$model$random_scale$phylo$node_sd_row0
  expected_node_sd <- rep(1, length(node_sd_row))
  modeled_node <- node_sd_row >= 0L
  expected_node_sd[modeled_node] <-
    sd_prediction[node_sd_row[modeled_node] + 1L]
  expect_equal(
    unname(random_effects$values),
    unname(random_effects$latent * expected_node_sd),
    tolerance = 1e-8
  )

  simulated <- simulate(fit, nsim = 1L, seed = 20261022L)
  expect_named(simulated, "sim_1")
  expect_length(simulated[[1L]], nrow(dat))
  expect_true(all(simulated[[1L]] >= 0L))
  expect_true(all(simulated[[1L]] == as.integer(simulated[[1L]])))

  saved_fit <- tempfile(fileext = ".rds")
  saveRDS(fit, saved_fit)
  reloaded_fit <- readRDS(saved_fit)
  expect_equal(
    predict(reloaded_fit, dpar = "sd_relmat(id)"),
    sd_prediction,
    tolerance = 1e-12
  )

  base_fit <- drmTMB(
    bf(y ~ x + relmat(1 | id, K = K)),
    family = stats::poisson(link = "log"),
    data = dat,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(
      y ~ x + relmat(1 | id, K = K),
      sd(id, level = "relmat") ~ 1
    ),
    family = stats::poisson(link = "log"),
    data = dat,
    control = drm_control(se = FALSE)
  )
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(constant_fit)),
    as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
  expect_equal(
    constant_fit$coefficients$mu,
    base_fit$coefficients$mu,
    tolerance = 1e-4
  )
})
