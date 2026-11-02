test_that("cloglog phylogenetic SD regression recovers tip-level scales", {
  skip_on_cran()
  skip_if_not_installed("ape")

  set.seed(20261026)
  n_tip <- 80L
  n_each <- 24L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("species_", seq_len(n_tip))
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_species <- as.numeric(scale(stats::rnorm(n_tip)))
  names(z_species) <- tree$tip.label
  alpha_sd <- c(`(Intercept)` = log(0.4), z_species = 0.5)
  tau <- exp(alpha_sd[[1L]] + alpha_sd[[2L]] * z_species)
  unit_field <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip))
  species_index <- rep(seq_len(n_tip), each = n_each)
  species <- factor(tree$tip.label[species_index], levels = tree$tip.label)
  x <- stats::rnorm(length(species))
  eta <- 0.15 + 0.3 * x + tau[species_index] * unit_field[species_index]
  p <- stats::binomial(link = "cloglog")$linkinv(eta)
  y <- stats::rbinom(length(eta), size = 1L, prob = p)
  dat <- data.frame(y, x, species, z_species = unname(z_species[species_index]))

  fit <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sd(species, level = "phylogenetic") ~ z_species
    ),
    family = stats::binomial(link = "cloglog"),
    data = dat,
    control = drm_control(se = FALSE)
  )
  fit_constant_sd <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sd(species, level = "phylogenetic") ~ 1
    ),
    family = stats::binomial(link = "cloglog"),
    data = dat,
    control = drm_control(se = FALSE)
  )
  fit_scalar <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree)),
    family = stats::binomial(link = "cloglog"),
    data = dat,
    control = drm_control(se = FALSE)
  )

  scale_coef <- coef(fit, "sd_phylo(species)")
  sd_hat <- predict(fit, dpar = "sd_phylo(species)")
  sd_link <- predict(fit, dpar = "sd_phylo(species)", type = "link")
  species_rows <- dat[!duplicated(dat$species), , drop = FALSE]
  prediction_rows <- species_rows[c(11L, 2L, 65L), , drop = FALSE]
  expected_sd <- exp(as.vector(
    stats::model.matrix(~z_species, species_rows) %*% scale_coef
  ))
  expected_sd_new <- exp(as.vector(
    stats::model.matrix(~z_species, prediction_rows) %*% scale_coef
  ))
  sd_new <- predict(
    fit,
    newdata = prediction_rows,
    dpar = "sd_phylo(species)"
  )

  expect_s3_class(fit, "drmTMB")
  expect_true(fit$opt$convergence == 0L)
  expect_true(fit_constant_sd$opt$convergence == 0L)
  expect_true(fit_scalar$opt$convergence == 0L)
  expect_equal(
    as.numeric(stats::logLik(fit_constant_sd)),
    as.numeric(stats::logLik(fit_scalar)),
    tolerance = 2e-5
  )
  expect_equal(
    unname(coef(fit_constant_sd, "sd_phylo(species)")[["(Intercept)"]]),
    log(unname(fit_scalar$sdpars$mu[["phylo(1 | species)"]])),
    tolerance = 1e-4
  )
  expect_named(scale_coef, names(alpha_sd))
  expect_equal(exp(sd_link), sd_hat, tolerance = 1e-10)
  expect_equal(unname(sd_hat), expected_sd, tolerance = 1e-10)
  expect_equal(unname(sd_new), expected_sd_new, tolerance = 1e-10)
  expect_length(sd_new, nrow(prediction_rows))
  expect_length(sd_hat, n_tip)
  expect_gt(scale_coef[["z_species"]], 0)
  expect_lt(abs(scale_coef[["z_species"]] - alpha_sd[["z_species"]]), 0.35)
})
