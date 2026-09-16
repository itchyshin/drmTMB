# Regression tests for Russell Dinnage's arc3 Wave A3 audit items.

test_that("Md-I: REML summaries expose whether the estimator is exact", {
  set.seed(20260915)
  dat <- data.frame(
    y = rnorm(24),
    x = rep(c(-0.5, 0.5), 12),
    g = factor(rep(seq_len(6), each = 4))
  )

  exact <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), gaussian(), dat, REML = TRUE)
  adjusted <- drmTMB(bf(y ~ x + (1 | g), sigma ~ 1 + (1 | g)), gaussian(), dat, REML = TRUE)

  expect_true(exact$estimator_exact)
  expect_false(adjusted$estimator_exact)
  exact_summary <- capture.output(summary(exact), type = "message")
  adjusted_summary <- capture.output(summary(adjusted), type = "message")
  expect_true(any(grepl("exact restricted likelihood", exact_summary)))
  expect_true(any(grepl("Laplace/Cox-Reid adjusted profile", adjusted_summary)))
})

test_that("Mi-6: phylo validation reports extra tips pruned from the data", {
  skip_if_not_installed("ape")
  set.seed(20260915)
  tree <- ape::rcoal(5)
  tree$tip.label <- paste0("sp", seq_len(5))

  expect_message(
    drmTMB:::drm_phylo_tip_covariance(tree, species = tree$tip.label[1:4]),
    "Pruning 1 phylogeny tip"
  )
})

test_that("Mi-10: pair-association simulation restores the caller RNG seed", {
  set.seed(20260915)
  before <- .Random.seed
  fit <- structure(list(
    status = "interior",
    eta_internal = 0.2,
    components = list(
      pair_class = "bernoulli_bernoulli",
      binary_1_p = c(0.2, 0.7),
      binary_2_p = c(0.4, 0.8)
    ),
    response_names = c("y1", "y2")
  ), class = "drm_pair_association")

  simulate(fit, nsim = 2, seed = 99)
  expect_identical(.Random.seed, before)
})

test_that("Mi-12: O3 optimizer controls are shared and non-convergence is reported", {
  ctrl <- drmTMB:::drm_o3_optim_control()
  expect_equal(ctrl$reltol, 1e-8)
  expect_equal(ctrl$maxit, 400)
  expect_warning(
    drmTMB:::drm_o3_check_optim(list(convergence = 1L), "aghq"),
    "non-zero convergence code"
  )
})

test_that("UX-2 and UX-3: summary exposes nobs and redirects empty derived summaries", {
  set.seed(20260915)
  dat <- data.frame(
    y = rnorm(24),
    x = rep(c(-0.5, 0.5), 12),
    g = factor(rep(seq_len(6), each = 4))
  )
  fit <- drmTMB(bf(y ~ 1 + (1 | g), sigma ~ x), gaussian(), dat)
  s <- summary(fit)

  expect_identical(s$nobs, nobs(fit))
  expect_equal(nrow(s$derived), 0L)
  expect_match(
    attr(s$derived, "residual_variance.message"),
    "\\$sdpars"
  )
  expect_message(print(s), "\\$sdpars")
})
