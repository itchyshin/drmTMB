test_that("Binomial iid plus relmat SD fits agree for K and Q under non-logit links", {
  set.seed(2026102711L)
  n_group <- 36L
  n_population <- 32L
  n_replicate <- 3L
  group_levels <- paste0("group_", seq_len(n_group))
  population_levels <- paste0("population_", seq_len(n_population))
  group_predictor <- stats::rnorm(n_group)
  population_predictor <- stats::rnorm(n_population)
  names(group_predictor) <- group_levels
  names(population_predictor) <- population_levels
  alpha_group <- c(`(Intercept)` = log(0.45), z_group = 0.35)
  alpha_population <- c(`(Intercept)` = log(0.50), z_population = -0.40)
  group_sd <- exp(alpha_group[[1L]] + alpha_group[[2L]] * group_predictor)
  population_sd <- exp(
    alpha_population[[1L]] + alpha_population[[2L]] * population_predictor
  )

  population_order <- rev(seq_len(n_population))
  K <- outer(population_order, population_order, function(i, j) 0.55^abs(i - j))
  dimnames(K) <- list(
    population_levels[population_order], population_levels[population_order]
  )
  Q <- solve(K)
  group_effect <- stats::rnorm(n_group) * group_sd
  names(group_effect) <- group_levels
  population_field_order <- as.vector(t(chol(K)) %*% stats::rnorm(n_population))
  population_field_order <- population_field_order *
    population_sd[population_levels[population_order]]
  names(population_field_order) <- population_levels[population_order]
  population_effect <- population_field_order[population_levels]

  design <- expand.grid(
    replicate = seq_len(n_replicate),
    group_index = seq_len(n_group),
    population_index = seq_len(n_population)
  )
  x <- stats::rnorm(nrow(design))
  eta <- -0.15 + 0.25 * x +
    group_effect[group_levels[design$group_index]] +
    population_effect[population_levels[design$population_index]]
  dat <- data.frame(
    x = x,
    group = factor(group_levels[design$group_index], levels = group_levels),
    population = factor(
      population_levels[design$population_index], levels = population_levels
    ),
    z_group = unname(group_predictor[group_levels[design$group_index]]),
    z_population = unname(population_predictor[population_levels[design$population_index]])
  )

  fit_model <- function(y, link, input) {
    link_data <- dat
    link_data$y <- y
    formula <- switch(
      input,
      K = bf(
        y ~ x + (1 | group) + relmat(1 | population, K = K),
        sd(group) ~ z_group,
        sd(population, level = "relmat") ~ z_population
      ),
      Q = bf(
        y ~ x + (1 | group) + relmat(1 | population, Q = Q),
        sd(group) ~ z_group,
        sd(population, level = "relmat") ~ z_population
      )
    )
    drmTMB(
      formula, family = stats::binomial(link = link), data = link_data,
      control = drm_control(se = FALSE)
    )
  }
  inverse_link <- list(
    probit = stats::pnorm,
    cloglog = function(value) -expm1(-exp(value))
  )
  for (link in names(inverse_link)) {
    set.seed(2026102712L + match(link, names(inverse_link)))
    y <- stats::rbinom(nrow(dat), 1L, inverse_link[[link]](eta))
    fit_k <- fit_model(y, link, "K")
    fit_q <- fit_model(y, link, "Q")

    expect_identical(fit_k$opt$convergence, 0L, info = paste(link, "K"))
    expect_identical(fit_q$opt$convergence, 0L, info = paste(link, "Q"))
    group_sd_coef <- coef(fit_k, "sd(group)")
    relmat_sd_coef <- coef(fit_k, "sd_relmat(population)")
    expect_true(group_sd_coef[["z_group"]] > 0, info = paste(link, "iid SD slope"))
    expect_lt(abs(group_sd_coef[["z_group"]] - alpha_group[["z_group"]]), 0.45)
    expect_true(relmat_sd_coef[["z_population"]] < 0,
                info = paste(link, "relmat SD slope"))
    expect_lt(abs(relmat_sd_coef[["z_population"]] - alpha_population[["z_population"]]), 0.50)
    expect_equal(as.numeric(logLik(fit_q)), as.numeric(logLik(fit_k)), tolerance = 1e-5)
    expect_equal(coef(fit_q, "sd(group)"), coef(fit_k, "sd(group)"), tolerance = 2e-4)
    expect_equal(
      coef(fit_q, "sd_relmat(population)"),
      coef(fit_k, "sd_relmat(population)"), tolerance = 2e-4
    )
    expect_equal(
      unname(predict(fit_q, dpar = "sd(group)")[group_levels]),
      unname(predict(fit_k, dpar = "sd(group)")[group_levels]), tolerance = 2e-4
    )
    expect_equal(
      unname(predict(fit_q, dpar = "sd_relmat(population)")[population_levels]),
      unname(predict(fit_k, dpar = "sd_relmat(population)")[population_levels]),
      tolerance = 2e-4
    )
  }
})
