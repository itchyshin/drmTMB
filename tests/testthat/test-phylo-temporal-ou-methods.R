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

  expect_setequal(names(fit$random_effects), c("phylo_mu", "temporal"))
  expect_named(fit$random_effects$temporal, c("values", "latent", "terms"))
  expect_named(fit$random_effects$phylo_mu, c("values", "latent", "terms"))
  expect_named(fit$random_effects$temporal$terms, "ou")
  expect_named(fit$random_effects$phylo_mu$terms, phylo$label)
  expect_equal(
    fit$random_effects$temporal$terms$ou,
    fit$random_effects$temporal$values
  )
  expect_equal(
    fit$random_effects$phylo_mu$terms[[phylo$label]],
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
