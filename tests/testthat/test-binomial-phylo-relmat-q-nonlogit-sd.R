test_that("Binomial non-logit phylo and relmat SDs agree for K and Q", {
  skip_on_cran()
  skip_if_not_installed("ape")

  set.seed(20261065L)
  n_tip <- 30L
  n_population <- 48L
  n_replicates <- 6L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("species_", seq_len(n_tip))
  species_levels <- tree$tip.label
  population_levels <- paste0("population_", seq_len(n_population))
  population_order <- rev(seq_len(n_population))
  K <- outer(population_order, population_order, function(i, j) 0.35^abs(i - j))
  dimnames(K) <- list(
    population_levels[population_order], population_levels[population_order]
  )
  Q <- solve(K)

  phylo_cov <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_tree <- setNames(sample(rep(c(-1, 1), length.out = n_tip)), species_levels)
  z_population <- setNames(
    sample(rep(c(-1, 1), length.out = n_population)), population_levels
  )
  alpha_tree <- c(`(Intercept)` = log(0.35), z_tree = 0.45)
  alpha_population <- c(`(Intercept)` = log(0.30), z_population = 0.55)
  tree_field <- as.vector(t(chol(phylo_cov)) %*% stats::rnorm(n_tip)) *
    exp(alpha_tree[[1L]] + alpha_tree[[2L]] * z_tree)
  names(tree_field) <- species_levels
  population_field_order <- as.vector(
    t(chol(K)) %*% stats::rnorm(n_population)
  ) * exp(
    alpha_population[[1L]] +
      alpha_population[[2L]] * z_population[population_levels[population_order]]
  )
  names(population_field_order) <- population_levels[population_order]
  population_field <- population_field_order[population_levels]

  design <- expand.grid(
    replicate = seq_len(n_replicates),
    population_index = seq_len(n_population),
    tip_index = seq_len(n_tip)
  )
  x <- stats::rnorm(nrow(design))
  eta <- -0.1 + 0.25 * x +
    tree_field[species_levels[design$tip_index]] +
    population_field[population_levels[design$population_index]]
  dat <- data.frame(
    y = 0L,
    x = x,
    species = factor(species_levels[design$tip_index], levels = species_levels),
    population = factor(
      population_levels[design$population_index], levels = rev(population_levels)
    ),
    z_tree = unname(z_tree[species_levels[design$tip_index]]),
    z_population = unname(z_population[population_levels[design$population_index]])
  )

  set.seed(20261066L)
  for (link in c("probit", "cloglog")) {
    family <- stats::binomial(link = link)
    link_data <- dat
    link_data$y <- stats::rbinom(nrow(link_data), 1L, family$linkinv(eta))
    formula_k <- bf(
      y ~ x + phylo(1 | species, tree = tree) + relmat(1 | population, K = K),
      sd(species, level = "phylogenetic") ~ z_tree,
      sd(population, level = "relmat") ~ z_population
    )
    formula_q <- bf(
      y ~ x + phylo(1 | species, tree = tree) + relmat(1 | population, Q = Q),
      sd(species, level = "phylogenetic") ~ z_tree,
      sd(population, level = "relmat") ~ z_population
    )
    fit_k <- drmTMB(
      formula_k,
      family = family,
      data = link_data,
      control = drm_control(se = FALSE)
    )
    fit_q <- drmTMB(
      formula_q,
      family = family,
      data = link_data,
      control = drm_control(se = FALSE)
    )

    expect_identical(fit_k$opt$convergence, 0L, info = link)
    expect_identical(fit_q$opt$convergence, 0L, info = link)
    expect_equal(as.numeric(logLik(fit_q)), as.numeric(logLik(fit_k)), tolerance = 1e-5)
    expect_equal(
      coef(fit_q, "sd_phylo(species)"),
      coef(fit_k, "sd_phylo(species)"), tolerance = 1e-4
    )
    expect_equal(
      coef(fit_q, "sd_relmat(population)"),
      coef(fit_k, "sd_relmat(population)"), tolerance = 1e-4
    )
    expect_equal(
      unname(predict(fit_q, dpar = "sd_relmat(population)")[population_levels]),
      unname(predict(fit_k, dpar = "sd_relmat(population)")[population_levels]),
      tolerance = 1e-4
    )
    expect_setequal(
      names(predict(fit_q, dpar = "sd_phylo(species)")), species_levels
    )
  }
})
