paired_phylo_temporal_ou_fit <- function(seed = 202609097L) {
  fixture <- phylo_temporal_ou_oracle_fixture(seed = seed)
  tree <- fixture$tree
  suppressWarnings(drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree) +
         temporal(1 | species, time = elapsed, structure = "ou"), sigma ~ 1),
    data = fixture$data, family = gaussian(), REML = FALSE
  ))
}

test_that("paired phylogenetic-OU modes retain distinct labelled components", {
  fit <- paired_phylo_temporal_ou_fit()
  temporal <- fit$model$structured$temporal_mu
  phylo <- fit$model$structured$phylo_mu

  expect_named(fit$sdpars$mu, c("sd_temporal", "sd_phylo_stable"))
  expect_named(fit$decaypars$temporal, "decay_temporal")
  expect_equal(
    unname(fit$decaypars$temporal[[temporal_mu_decay_label(temporal)]]),
    unname(fit$decaypars$temporal[["decay_temporal"]])
  )
  expect_true(isTRUE(phylo$paired_temporal_ou))
  expect_setequal(names(fit$random_effects), c("phylo_mu", "temporal"))
  expect_named(fit$random_effects$temporal, c("values", "latent", "terms"))
  expect_named(fit$random_effects$phylo_mu, c("values", "latent", "terms"))
  expect_named(fit$random_effects$temporal$terms, "ou")
  phylo_sd_label <- phylo_mu_sd_labels(phylo, fit$model$model_type)
  expect_named(fit$random_effects$phylo_mu$terms, phylo_sd_label)
  expect_equal(
    fit$random_effects$temporal$terms$ou,
    fit$random_effects$temporal$values
  )
  expect_equal(
    fit$random_effects$phylo_mu$terms[[phylo_sd_label]],
    fit$random_effects$phylo_mu$values
  )
  expect_equal(
    unname(temporal_mu_contribution(fit)),
    unname(fit$random_effects$temporal$values[temporal$observation_node_index])
  )
  expect_equal(
    unname(phylo_mu_contribution(fit, dpar = "mu")),
    unname(fit$random_effects$phylo_mu$values[phylo$observation_node_index])
  )
})

test_that("paired phylogenetic-OU fitted values and residuals use both modes", {
  fit <- paired_phylo_temporal_ou_fit()
  fixed_mu <- as.vector(fit$model$X$mu %*% fit$coefficients$mu)
  phylo_mu <- phylo_mu_contribution(fit, dpar = "mu")
  temporal_mu <- temporal_mu_contribution(fit)
  conditional_mu <- fixed_mu + phylo_mu + temporal_mu

  expect_equal(stats::fitted(fit), conditional_mu, tolerance = 1e-10)
  expect_equal(stats::residuals(fit), fit$model$y - conditional_mu, tolerance = 1e-10)
  expect_false(isTRUE(all.equal(stats::fitted(fit), fixed_mu + phylo_mu)))
  expect_false(isTRUE(all.equal(stats::fitted(fit), fixed_mu + temporal_mu)))
})

test_that("paired phylogenetic-OU conditional and fresh simulations match components", {
  fit <- paired_phylo_temporal_ou_fit()
  n <- nrow(fit$data)
  fixed_mu <- as.vector(fit$model$X$mu %*% fit$coefficients$mu)
  conditional_mu <- fixed_mu +
    phylo_mu_contribution(fit, dpar = "mu") +
    temporal_mu_contribution(fit)

  set.seed(202609095L)
  expected_conditional <- conditional_mu + stats::rnorm(n, sd = observation_sigma(fit))
  expect_equal(
    unname(stats::simulate(fit, nsim = 1L, seed = 202609095L, re.form = NA)[[1L]]),
    expected_conditional,
    tolerance = 1e-10
  )

  set.seed(202609096L)
  fresh_phylo <- drm_structured_mu_random_effect_draws(fit)$mu
  fresh_temporal <- drm_fresh_temporal_mu_values(fit)
  expected_fresh <- stats::rnorm(
    n,
    mean = fixed_mu + fresh_phylo + fresh_temporal,
    sd = observation_sigma(fit)
  )
  fresh <- stats::simulate(fit, nsim = 1L, seed = 202609096L)
  conditional <- stats::simulate(fit, nsim = 2L, seed = 202609097L, re.form = NA)

  expect_equal(unname(fresh[[1L]]), expected_fresh, tolerance = 1e-10)
  expect_identical(dim(fresh), c(n, 1L))
  expect_identical(dim(conditional), c(n, 2L))
  expect_false(isTRUE(all.equal(
    stats::simulate(fit, nsim = 1L, seed = 202609096L)[[1L]],
    stats::simulate(fit, nsim = 1L, seed = 202609096L, re.form = NA)[[1L]]
  )))
})

test_that("paired phylogenetic-OU inference surface exposes only profile-ready means", {
  fit <- paired_phylo_temporal_ou_fit()
  targets <- profile_targets(fit)
  fixed <- targets[
    targets$target_class == "fixed-effect" & targets$dpar == "mu",
    , drop = FALSE
  ]
  nonmean <- targets[targets$target_class != "fixed-effect", , drop = FALSE]
  temporal <- fit$model$structured$temporal_mu

  expect_true(nrow(fixed) >= 2L)
  expect_true(all(fixed$profile_ready))
  expect_true(any(nonmean$profile_note == "temporal_nonmean_intervals_deferred"))
  expect_true(any(nonmean$profile_note == "temporal_decay_intervals_deferred"))
  expect_error(stats::vcov(fit), "OU coefficient covariance is not yet qualified")
  expect_error(
    stats::predict(fit, newdata = fit$data[1L, , drop = FALSE]),
    "fitted observations"
  )
  expect_identical(temporal$structure, "ou")
})

test_that("a paired fit whose residual SD collapses is reported as a boundary fit", {
  skip_if_not_installed("ape")
  # The article's generator (set.seed(20260909)) with 16 species: sigma runs
  # to ~3e-5 while the optimizer, Hessian and SEs look regular.
  set.seed(20260909)
  n_species <- 16L
  elapsed_values <- c(0, 0.5, 2.5, 5)
  tree <- ape::rcoal(n_species, tip.label = paste0("sp", seq_len(n_species)))
  A <- drm_phylo_tip_covariance(tree)
  stable <- drop(t(chol(A)) %*% stats::rnorm(n_species, sd = 0.45))
  names(stable) <- tree$tip.label
  R_ou <- exp(-0.45 * abs(outer(elapsed_values, elapsed_values, "-")))
  ou_by_species <- lapply(tree$tip.label, function(species) {
    drop(t(chol(R_ou)) %*% stats::rnorm(length(elapsed_values), sd = 0.55))
  })
  names(ou_by_species) <- tree$tip.label
  dat <- do.call(rbind, lapply(tree$tip.label, function(species) {
    treatment <- rep(c(-0.5, 0.5), length.out = length(elapsed_values))
    data.frame(
      species = species, elapsed_days = elapsed_values, treatment = treatment,
      y = 1 + 0.4 * treatment + stable[[species]] + ou_by_species[[species]] +
        stats::rnorm(length(elapsed_values), sd = 0.35)
    )
  }))
  dat$species <- factor(dat$species, levels = tree$tip.label)
  fit <- suppressWarnings(drmTMB(
    bf(y ~ treatment + phylo(1 | species, tree = tree) +
         temporal(1 | species, time = elapsed_days, structure = "ou"),
       sigma ~ 1),
    data = dat, family = gaussian(), REML = FALSE
  ))
  expect_identical(as.integer(fit$opt$convergence), 0L)
  expect_lt(unname(stats::sigma(fit)[[1L]]), 1e-3)
  rows <- check_drm(fit)
  boundary <- rows[rows$check == "temporal_boundary", , drop = FALSE]
  expect_identical(boundary$status, "warning")
  expect_match(boundary$value, "sigma_ratio=")
  # convergence_status() ranks "degenerate" above "boundary". On the reference
  # optimizer path (Totoro) the Hessian and standard errors stay regular, so only
  # the temporal_boundary row can flag the fit; on Linux CI the same collapse
  # can also leave the Hessian or standard errors irregular (run 37087762781).
  irregular <- drmTMB:::drm_inference_degenerate(fit) ||
    drmTMB:::drm_fixed_effect_rank_deficient(fit) ||
    drmTMB:::drm_standard_errors_pathological(fit)
  expect_identical(convergence_status(fit), if (irregular) "degenerate" else "boundary")
  expect_false(identical(convergence_status(fit), "converged"))
})
