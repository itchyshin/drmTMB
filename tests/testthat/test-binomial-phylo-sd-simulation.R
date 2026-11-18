test_that("marginal simulation uses modeled Bernoulli phylogenetic SDs", {
  skip_on_cran()
  skip_if_not_installed("ape")

  set.seed(20261020)
  n_tip <- 24L
  n_each <- 12L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("species_", seq_len(n_tip))
  root_to_tip <- ape::node.depth.edgelength(tree)[seq_len(n_tip)]
  tree$edge.length <- tree$edge.length * 2.5 / max(root_to_tip)
  expect_equal(
    max(ape::node.depth.edgelength(tree)[seq_len(n_tip)]),
    2.5,
    tolerance = 1e-12
  )
  A <- drmTMB:::drm_phylo_tip_covariance(tree, correlation = TRUE)
  raw_A <- drmTMB:::drm_phylo_tip_covariance(tree, correlation = FALSE)
  expect_gt(max(abs(A - raw_A)), 0.1)
  z_species <- as.numeric(scale(stats::rnorm(n_tip)))
  names(z_species) <- tree$tip.label
  tau <- exp(log(0.35) + 0.5 * z_species)
  unit_field <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip))
  species_index <- rep(seq_len(n_tip), each = n_each)
  species <- factor(tree$tip.label[species_index], levels = tree$tip.label)
  x <- stats::rnorm(length(species))
  eta <- 0.2 + 0.3 * x + tau[species_index] * unit_field[species_index]
  y <- stats::rbinom(length(eta), size = 1L, prob = stats::plogis(eta))
  dat <- data.frame(
    y,
    x,
    species,
    z_species = unname(z_species[species_index])
  )

  fit <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sd(species, level = "phylogenetic") ~ z_species
    ),
    family = stats::binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  phylo_mu <- fit$model$structured$phylo_mu
  fitted_covariance <- solve(as.matrix(phylo_mu$precision$precision))
  tip_rows <- unname(phylo_mu$precision$species_node_index[tree$tip.label])
  expect_equal(
    fitted_covariance[tip_rows, tip_rows, drop = FALSE],
    A[tree$tip.label, tree$tip.label, drop = FALSE],
    tolerance = 1e-8
  )
  expect_gt(
    max(abs(fitted_covariance[tip_rows, tip_rows, drop = FALSE] - raw_A)),
    0.1
  )
  sd_registry <- fit$model$random_scale$phylo
  scale_dpar <- sd_registry$dpars[[1L]]
  scale_values <- drmTMB:::predict_random_scale_dpar(fit, scale_dpar)
  node_sd_row0 <- sd_registry$node_sd_row0[seq_len(phylo_mu$n_re)]
  modeled_rows <- sd_registry$row_index[[scale_dpar]]
  expected_node_sd <- rep(1, phylo_mu$n_re)
  direct <- node_sd_row0 >= 0L
  expected_node_sd[direct] <- unname(scale_values[
    match(node_sd_row0[direct] + 1L, modeled_rows)
  ])
  random_effect_key <- drmTMB:::structured_mu_random_effect_key(
    phylo_mu,
    fit$model$model_type
  )
  set.seed(20261022)
  actual_contribution <- drmTMB:::drm_structured_mu_random_effect_draws(fit)$mu
  set.seed(20261022)
  precision_root <- chol(as.matrix(phylo_mu$precision$precision))
  expected_values <- backsolve(
    precision_root,
    stats::rnorm(phylo_mu$n_re)
  ) * expected_node_sd
  expected_fit <- fit
  expected_fit$random_effects[[random_effect_key]]$values <- expected_values
  expected_contribution <- drmTMB:::phylo_mu_contribution(
    expected_fit,
    dpar = "mu"
  )

  simulated <- simulate(fit, nsim = 3L, seed = 20261021)

  save_path <- tempfile(fileext = ".rds")
  on.exit(unlink(save_path), add = TRUE)
  saveRDS(fit, save_path)
  restored <- readRDS(save_path)
  target <- "sd_phylo(species)"
  expect_equal(
    predict(restored, dpar = target),
    predict(fit, dpar = target),
    tolerance = 1e-12
  )
  expect_identical(
    simulate(restored, nsim = 3L, seed = 20261021),
    simulated
  )

  expect_equal(actual_contribution, expected_contribution, tolerance = 1e-12)
  expect_gt(stats::sd(scale_values), 0)
  expect_equal(dim(simulated), c(nrow(dat), 3L))
  expect_true(all(as.matrix(simulated) %in% c(0L, 1L)))
  expect_true(all(is.finite(as.matrix(simulated))))
})
