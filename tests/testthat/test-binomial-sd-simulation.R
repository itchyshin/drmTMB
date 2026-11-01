test_that("Bernoulli SD models allow marginal simulation", {
  sim <- binomial_sd_fixture(groups = 36L, repeats = 8L)
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sd(id) ~ w),
    family = binomial(),
    data = sim$data
  )

  marginal <- stats::simulate(fit, nsim = 2L, seed = 2026101702L)
  conditional <- suppressMessages(stats::simulate(
    fit, nsim = 2L, seed = 2026101702L, re.form = NULL
  ))
  expect_s3_class(marginal, "data.frame")
  expect_s3_class(conditional, "data.frame")
  expect_equal(dim(marginal), c(nrow(sim$data), 2L))
  expect_equal(dim(conditional), dim(marginal))

  group_rows <- split(seq_len(nrow(sim$data)), sim$data$id)
  scale_prediction <- predict(fit, dpar = "sd(id)")
  selected_groups <- c(names(group_rows)[[1L]], names(group_rows)[[36L]])
  selected_rows <- vapply(group_rows[selected_groups], `[[`, integer(1), 1L)
  set.seed(2026101704L)
  latent_draws <- replicate(1200L, {
    fresh <- drm_ordinary_random_effect_draws(fit)$mu
    fresh[selected_rows]
  })
  empirical_variance_ratio <- stats::var(latent_draws[2L, ]) /
    stats::var(latent_draws[1L, ])
  expected_variance_ratio <-
    (scale_prediction[[selected_groups[[2L]]]] /
      scale_prediction[[selected_groups[[1L]]]])^2
  expect_equal(empirical_variance_ratio, expected_variance_ratio,
               tolerance = 0.15)

  boot <- suppressMessages(confint(
    fit,
    parm = "sd(id):w",
    method = "bootstrap",
    R = 2L,
    seed = 2026101703L
  ))
  diagnostics <- attr(boot, "bootstrap.diagnostics", exact = TRUE)
  expect_equal(nrow(diagnostics), 2L)
  expect_true(any(diagnostics$refit_status == "ok"))
})

test_that("marginal simulation admits ordinary SDs and keeps structured scales closed", {
  base_object <- list(
    model = list(
      model_type = "binomial",
      random = list(mu = list(cor_model = list(n_models = 0L))),
      random_scale = list(
        mu = list(n_models = 0L),
        phylo = list(n_models = 1L)
      ),
      structured = list(phylo_mu = list(has = FALSE))
    ),
    random_effects = list(
      mu = list(values = numeric()),
      covariance_blocks = list(contribution = matrix(numeric(), 0L, 0L))
    )
  )
  expect_match(
    drm_simulate_marginal_unsupported(base_object),
    "modelled.*random-effect scale"
  )

  base_object$model$random_scale$phylo$n_models <- 0L
  base_object$model$random_scale$mu$n_models <- 1L
  expect_null(drm_simulate_marginal_unsupported(base_object))
  base_object$model$model_type <- "gaussian"
  expect_null(drm_simulate_marginal_unsupported(base_object))
})

test_that("binomial SD registry rows map to per-effect scales", {
  dpar <- "sd(id)"
  X <- matrix(c(1, -1, 1, 0, 1, 1), ncol = 2L, byrow = TRUE,
              dimnames = list(c("g1", "g2", "g3"), c("(Intercept)", "w")))
  sd_model <- list(
    n_models = 1L,
    dpars = dpar,
    re_sd_row0 = 0:2,
    X = X,
    X_list = stats::setNames(list(X), dpar),
    row_index = stats::setNames(list(1:3), dpar),
    group_levels_list = stats::setNames(list(rownames(X)), dpar),
    group_levels = rownames(X)
  )
  object <- list(
    model = list(
      model_type = "binomial",
      random_scale = list(mu = sd_model),
      tmb_data = list(use_logsigma_clamp = 0L)
    ),
    coefficients = stats::setNames(
      list(c("(Intercept)" = log(0.8), w = 0.5)), dpar
    )
  )
  mapped <- drm_binomial_sd_effect_override(object, list(n_re = 3L))
  expect_equal(unname(mapped), exp(as.vector(X %*% object$coefficients[[dpar]])))

  # The scale prediction and marginal-draw paths must use the same soft clamp
  # when the fitted log-SD predictor leaves the configured band.
  X_clamped <- cbind("(Intercept)" = 1, w = c(-5, 0, 5))
  rownames(X_clamped) <- c("low", "middle", "high")
  sd_model$X <- X_clamped
  sd_model$X_list[[dpar]] <- X_clamped
  sd_model$group_levels_list[[dpar]] <- rownames(X_clamped)
  sd_model$group_levels <- rownames(X_clamped)
  sd_model$row_index[[dpar]] <- 1:3
  object$model$random_scale$mu <- sd_model
  object$model$tmb_data <- list(
    use_logsigma_clamp = 1L,
    logsigma_clamp = c(-1, 1, 0.5)
  )
  object$coefficients[[dpar]] <- c("(Intercept)" = 0.5, w = 1)
  mapped_clamped <- drm_binomial_sd_effect_override(object, list(n_re = 3L))
  reference_clamped <- sd_mu_group_values(
    list(beta_sd_mu = object$coefficients[[dpar]]),
    sd_model,
    dpar = dpar,
    tmb_data = object$model$tmb_data
  )
  expect_equal(unname(mapped_clamped), unname(reference_clamped))
  expect_equal(log(mapped_clamped[c(1L, 3L)]), c(-1.5, 1.5), tolerance = 1e-5)
})

test_that("marginal ordinary-effect draws use per-coefficient scales", {
  re <- list(
    n_re = 4L,
    n_terms = 2L,
    labels = c("(1 | id)", "(1 | other)"),
    n_cors = 0L,
    cor_labels = character(),
    term_id0 = c(0L, 0L, 0L, 1L),
    re_cor_id0 = rep.int(-1L, 4L),
    re_pos0 = rep.int(0L, 4L),
    re_pair_index0 = rep.int(-1L, 4L),
    index = matrix(rep(1:4, each = 2L), ncol = 1L),
    value = matrix(1, nrow = 8L, ncol = 1L),
    dpars = "mu"
  )
  scales <- c(0.3, 0.6, 1.2, NA_real_)
  expected_scales <- c(scales[1:3], 2.4)
  set.seed(717L)
  expected_latent <- stats::rnorm(4L)
  set.seed(717L)
  draw <- drm_fresh_ordinary_random_effect_values(
    re, sd_lookup = c("(1 | other)" = 2.4), rho_lookup = NULL,
    sd_by_effect_override = scales
  )
  expect_equal(draw$values, expected_latent * expected_scales)
  contribution <- drm_random_effect_contribution_from_values(
    draw$values, re, "mu"
  )
  expect_equal(contribution, rep(draw$values, each = 2L))
})
