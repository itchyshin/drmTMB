test_that("Poisson phylogenetic SD regression scales extracted effects", {
  skip_if_not_installed("ape")

  set.seed(2026102026L)
  n_species <- 24L
  n_each <- 12L
  tree <- ape::rcoal(n_species)
  tree$tip.label <- paste0("species_", seq_len(n_species))
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_species <- seq(-1, 1, length.out = n_species)
  latent <- as.vector(t(chol(K)) %*% stats::rnorm(n_species))
  alpha <- c("(Intercept)" = log(0.55), z = 0.4)
  sd_species <- exp(alpha[[1L]] + alpha[["z"]] * z_species)
  phylo_effect <- sd_species * latent
  species_index <- rep(seq_len(n_species), each = n_each)
  species <- factor(tree$tip.label[species_index], levels = tree$tip.label)
  z <- z_species[species_index]
  x <- stats::rnorm(length(species))
  mu <- exp(0.5 + 0.25 * x + phylo_effect[species_index])
  dat <- data.frame(
    count = stats::rpois(length(mu), mu),
    x = x,
    species = species,
    z = z
  )

  fit <- drmTMB(
    bf(
      count ~ x + phylo(1 | species, tree = tree),
      sd(species, level = "phylogenetic") ~ z
    ),
    family = stats::poisson(link = "log"),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd_phylo(species)"), names(alpha))
  expect_true(all(is.finite(coef(fit, "sd_phylo(species)"))))
  expect_length(predict(fit, dpar = "sd_phylo(species)"), n_species)

  extracted <- ranef(fit, "phylo_mu")
  extracted_term <- extracted$terms[["phylo(1 | species)"]]
  fitted_node_sd <- fit$sdpars[["sd_phylo(species)"]]
  node_sd_row <- fit$model$random_scale$phylo$node_sd_row0
  aligned_node_sd <- rep(NA_real_, length(extracted$latent))
  has_sd <- node_sd_row >= 0L
  aligned_node_sd[has_sd] <- fitted_node_sd[node_sd_row[has_sd] + 1L]
  expect_equal(
    unname(extracted_term),
    unname(extracted$latent * aligned_node_sd),
    tolerance = 1e-8
  )

  expected_link <- as.vector(fit$model$X$mu %*% fit$coefficients$mu) +
    drmTMB:::phylo_mu_contribution(fit)
  expect_equal(
    unname(predict(fit, dpar = "mu", type = "link")),
    unname(expected_link),
    tolerance = 1e-8
  )
})
