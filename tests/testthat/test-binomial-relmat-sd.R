binomial_relmat_sd_fixture <- function(seed = 6201020L, n_id = 192L, n_each = 20L,
                                      link = "logit") {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  kernel_order <- rev(seq_len(n_id))
  K <- outer(kernel_order, kernel_order, function(i, j) 0.45^abs(i - j))
  dimnames(K) <- list(id_levels[kernel_order], id_levels[kernel_order])
  z_id <- if (link == "logit") {
    rep(c(-0.5, 0.5), length.out = n_id)
  } else {
    sample(rep(c(-1, 1), length.out = n_id))
  }
  alpha <- c(`(Intercept)` = log(0.45), z = 0.45)
  latent_sd <- exp(alpha[[1L]] + alpha[[2L]] * z_id)
  effect_in_kernel_order <- as.vector(t(chol(K)) %*% stats::rnorm(n_id)) *
    latent_sd[kernel_order]
  names(effect_in_kernel_order) <- id_levels[kernel_order]
  effect <- effect_in_kernel_order[id_levels]

  id <- rep(id_levels, each = n_each)
  x <- if (link == "logit") {
    rep(seq(-1, 1, length.out = n_each), n_id)
  } else {
    stats::rnorm(length(id))
  }
  z <- rep(z_id, each = n_each)
  eta <- -0.2 + 0.55 * x + effect[id]
  probability <- switch(
    link,
    logit = stats::plogis(eta),
    probit = stats::pnorm(eta),
    cloglog = -expm1(-exp(eta)),
    stop("Unsupported fixture link: ", link)
  )
  y <- stats::rbinom(length(id), size = 1L, prob = probability)
  list(
    data = data.frame(id = factor(id, levels = id_levels), x = x, z = z, y = y),
    K = K,
    alpha = alpha,
    latent_sd = stats::setNames(latent_sd, id_levels)
  )
}

test_that("binomial relmat SD regression fits and returns target-specific SDs", {
  skip_on_cran()
  fx <- binomial_relmat_sd_fixture()
  K <- fx$K
  fit <- drmTMB(
    bf(
      y ~ x + relmat(1 | id, K = K),
      sd(id, level = "relmat", dpar = "mu", coef = "(Intercept)") ~ z
    ),
    family = stats::binomial(),
    data = fx$data
  )

  expect_s3_class(fit, "drmTMB")
  expect_equal(fit$opt$convergence, 0)
  expect_true(is.finite(as.numeric(fit$logLik)))
  expect_named(fit$coefficients, c("mu", "sd_relmat(id)"))
  expect_named(fit$coefficients[["sd_relmat(id)"]], c("(Intercept)", "z"))
  fit_sd <- fit$sdpars[["sd_relmat(id)"]]
  fit_sd_group <- sub("^sd_relmat\\(id\\):", "", names(fit_sd))
  names(fit_sd) <- fit_sd_group
  expect_setequal(names(fit_sd), levels(fx$data$id))
  expect_lt(
    abs(
      fit$coefficients[["sd_relmat(id)"]][["(Intercept)"]] -
        fx$alpha[["(Intercept)"]]
    ),
    0.2
  )
  expect_lt(
    abs(fit$coefficients[["sd_relmat(id)"]][["z"]] - fx$alpha[["z"]]),
    0.2
  )
  expect_lt(
    max(abs(log(fit_sd[names(fx$latent_sd)]) - log(fx$latent_sd))),
    0.2
  )
  sd_prediction <- predict(fit, dpar = "sd_relmat(id)")
  expect_setequal(names(sd_prediction), levels(fx$data$id))
  expect_equal(
    unname(sd_prediction[names(fit_sd)]),
    unname(fit_sd),
    tolerance = 1e-10
  )
  phylo_mu <- fit$model$structured$phylo_mu
  random_effect_key <- structured_mu_random_effect_key(
    phylo_mu,
    fit$model$model_type
  )
  random_effects <- ranef(fit, random_effect_key)
  node_sd_row <- fit$model$random_scale$phylo$node_sd_row0
  expected_node_sd <- rep(1, length(node_sd_row))
  modeled_node <- node_sd_row >= 0L
  expected_node_sd[modeled_node] <- sd_prediction[node_sd_row[modeled_node] + 1L]
  expect_equal(
    unname(random_effects$values),
    unname(random_effects$latent * expected_node_sd),
    tolerance = 1e-10
  )
  sd_registry <- fit$model$random_scale$phylo
  set.seed(6201022L)
  actual_contribution <- drm_structured_mu_random_effect_draws(fit)$mu
  set.seed(6201022L)
  expected_values <- backsolve(
    chol(as.matrix(phylo_mu$precision$precision)),
    stats::rnorm(phylo_mu$n_re)
  ) * expected_node_sd
  expected_fit <- fit
  expected_fit$random_effects[[random_effect_key]]$values <- expected_values
  expected_contribution <- phylo_mu_contribution(expected_fit, dpar = "mu")
  expect_equal(actual_contribution, expected_contribution, tolerance = 1e-12)
  parameter_prediction <- predict_parameters(fit, dpar = "sd_relmat(id)")
  expect_true(all(parameter_prediction$dpar == "sd_relmat(id)"))
  expect_equal(nrow(parameter_prediction), nlevels(fx$data$id))
  simulated <- simulate(fit, nsim = 1L, seed = 6201021L)
  expect_named(simulated, "sim_1")
  expect_length(simulated[[1L]], nrow(fx$data))
  expect_true(all(simulated[[1L]] %in% 0:1))

  base_fit <- drmTMB(
    bf(y ~ x + relmat(1 | id, K = K)),
    family = stats::binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(
      y ~ x + relmat(1 | id, K = K),
      sd(id, level = "relmat") ~ 1
    ),
    family = stats::binomial(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(base_fit$opt$convergence, 0)
  expect_equal(constant_fit$opt$convergence, 0)
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

test_that("Binomial relmat SD regression supports probit and cloglog links", {
  skip_on_cran()
  for (link in c("probit", "cloglog")) {
    fx <- binomial_relmat_sd_fixture(
      seed = if (link == "probit") 6201030L else 6201031L,
      n_id = 128L,
      n_each = 48L,
      link = link
    )
    K <- fx$K
    fit <- drmTMB(
      bf(
        y ~ x + relmat(1 | id, K = K),
        sd(id, level = "relmat") ~ z
      ),
      family = stats::binomial(link = link),
      data = fx$data,
      control = drm_control(se = FALSE)
    )

    expect_equal(fit$opt$convergence, 0)
    expect_true(is.finite(as.numeric(fit$logLik)))
    expect_true(fit$coefficients[["sd_relmat(id)"]][["z"]] > 0)
    expect_lt(
      abs(fit$coefficients[["sd_relmat(id)"]][["z"]] - fx$alpha[["z"]]),
      0.35
    )
    sd_prediction <- predict_parameters(fit, dpar = "sd_relmat(id)")
    expect_true(all(sd_prediction$dpar == "sd_relmat(id)"))
    expect_setequal(sd_prediction$row_label, levels(fx$data$id))
    expect_true(all(is.finite(sd_prediction$estimate)))
    simulated <- simulate(fit, nsim = 1L, seed = 6201032L)
    expect_true(all(simulated[[1L]] %in% 0:1))

    julia_fit <- drmTMB(
      bf(
        y ~ x + relmat(1 | id, K = K),
        sd(id, level = "relmat") ~ z
      ),
      family = stats::binomial(link = link),
      data = fx$data,
      engine = "julia"
    )
    expect_equal(julia_fit$opt$convergence, 0)
    julia_coef <- coef(julia_fit, dpar = "sd_relmat(id)")
    native_coef <- coef(fit, dpar = "sd_relmat(id)")
    expect_named(julia_coef, names(native_coef))
    expect_equal(unname(julia_coef), unname(native_coef), tolerance = 0.15)
    julia_sd <- predict(julia_fit, dpar = "sd_relmat(id)")
    native_sd <- predict(fit, dpar = "sd_relmat(id)")
    names(julia_sd) <- sub("^sd_relmat\\(id\\):", "", names(julia_sd))
    names(native_sd) <- sub("^sd_relmat\\(id\\):", "", names(native_sd))
    expect_setequal(names(julia_sd), names(native_sd))
    expect_equal(unname(julia_sd[names(native_sd)]), unname(native_sd),
                 tolerance = 0.15)
  }
})
