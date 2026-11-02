test_that("Gamma phylogenetic SD regression recovers tip-level scale effects", {
  skip_if_not_installed("ape")

  set.seed(2026102027L)
  n_tip <- 24L
  n_each <- 12L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("species_", seq_len(n_tip))
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_tip <- as.numeric(scale(stats::rnorm(n_tip)))
  names(z_tip) <- tree$tip.label
  alpha_sd <- c(`(Intercept)` = log(0.55), z = 0.4)
  tau <- exp(alpha_sd[[1L]] + alpha_sd[[2L]] * z_tip)
  unit_field <- as.vector(t(chol(K)) %*% stats::rnorm(n_tip))
  species_index <- rep(seq_len(n_tip), each = n_each)
  species <- factor(tree$tip.label[species_index], levels = tree$tip.label)
  z <- z_tip[species_index]
  x <- stats::rnorm(length(species))
  mu <- exp(0.4 + 0.3 * x + tau[species_index] * unit_field[species_index])
  sigma <- 0.5
  shape <- sigma^-2
  dat <- data.frame(
    y = stats::rgamma(length(mu), shape = shape, rate = shape / mu),
    x = x,
    species = species,
    z = z
  )

  fit <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sigma ~ 1,
      sd(species, level = "phylogenetic") ~ z
    ),
    family = Gamma(link = "log"),
    data = dat,
    control = drm_control(se = FALSE, logsigma_clamp = c(-2, 2))
  )
  fit_constant_sd <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sigma ~ 1,
      sd(species, level = "phylogenetic") ~ 1
    ),
    family = Gamma(link = "log"),
    data = dat,
    control = drm_control(se = FALSE)
  )
  fit_scalar <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    family = Gamma(link = "log"),
    data = dat,
    control = drm_control(se = FALSE)
  )

  scale_coef <- coef(fit, "sd_phylo(species)")
  sd_hat <- predict(fit, dpar = "sd_phylo(species)")
  expect_equal(fit$opt$convergence, 0L)
  expect_equal(fit_constant_sd$opt$convergence, 0L)
  expect_equal(fit_scalar$opt$convergence, 0L)
  expect_named(scale_coef, names(alpha_sd))
  expect_named(sd_hat, tree$tip.label)
  expect_length(sd_hat, n_tip)
  expect_true(all(is.finite(sd_hat)))
  expect_gt(scale_coef[["z"]], 0)
  expect_lt(abs(scale_coef[["z"]] - alpha_sd[["z"]]), 0.5)
  expect_equal(
    as.numeric(logLik(fit_constant_sd)),
    as.numeric(logLik(fit_scalar)),
    tolerance = 2e-5
  )
  expect_equal(
    unname(coef(fit_constant_sd, "sd_phylo(species)")[["(Intercept)"]]),
    log(unname(fit_scalar$sdpars$mu[["phylo(1 | species)"]])),
    tolerance = 1e-4
  )

  # The TMB report, response-scale SD and public link prediction must use the
  # same effective value when the raw SD predictor is beyond the clamp band.
  perturbed <- fit$tmb_state$last.par.best
  beta_sd_idx <- which(names(perturbed) == "beta_sd_mu")
  expect_length(beta_sd_idx, 2L)
  perturbed[beta_sd_idx] <- c(4, 0)
  clamp_report <- fit$obj$report(perturbed)
  expected_log_sd <- 2 + 3 * tanh((4 - 2) / 3)
  # G1 C4: log_sd_phylo_group is the raw predictor; sd_phylo_group is clamped.
  expect_equal(
    clamp_report$log_sd_phylo_group,
    rep(4, n_tip),
    tolerance = 1e-10
  )
  expect_equal(
    log(clamp_report$sd_phylo_group),
    rep(expected_log_sd, n_tip),
    tolerance = 1e-10
  )
  fit_perturbed <- fit
  fit_perturbed$coefficients[["sd_phylo(species)"]] <-
    c(`(Intercept)` = 4, z = 0)
  expect_equal(
    unname(predict(
      fit_perturbed,
      dpar = "sd_phylo(species)",
      type = "link"
    )),
    unname(log(clamp_report$sd_phylo_group)),
    tolerance = 1e-10
  )
})
