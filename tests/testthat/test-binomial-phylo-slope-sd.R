test_that("Binomial phylogenetic random slopes support predictor-dependent SDs", {
  skip_on_cran()
  skip_if_not_installed("ape")

  set.seed(20261027L)
  n_tip <- 80L
  n_each <- 24L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("species_", seq_len(n_tip))
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_species <- as.numeric(scale(stats::rnorm(n_tip)))
  alpha_sd <- c(`(Intercept)` = log(0.4), z_species = 0.5)
  tau <- exp(alpha_sd[[1L]] + alpha_sd[[2L]] * z_species)
  unit_slope <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip))
  species_index <- rep(seq_len(n_tip), each = n_each)
  species <- factor(tree$tip.label[species_index], levels = tree$tip.label)
  x <- rep(seq(-1.5, 1.5, length.out = n_each), times = n_tip)
  slope <- tau * unit_slope
  eta <- -0.1 + 0.45 * x + x * slope[species_index]
  y <- stats::rbinom(length(eta), size = 1L, prob = stats::plogis(eta))
  dat <- data.frame(
    y, x, species,
    z_species = unname(z_species[species_index])
  )

  fit <- drmTMB(
    bf(
      y ~ x + phylo(0 + x | species, tree = tree),
      sd(species, level = "phylogenetic") ~ z_species
    ),
    family = stats::binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  scale_coef <- coef(fit, "sd_phylo(species)")
  sd_hat <- predict(fit, dpar = "sd_phylo(species)")
  tip_rows <- dat[!duplicated(dat$species), , drop = FALSE]
  expected_sd <- exp(as.vector(
    stats::model.matrix(~z_species, tip_rows) %*% scale_coef
  ))

  expect_s3_class(fit, "drmTMB")
  expect_true(is_converged(fit))
  expect_named(scale_coef, names(alpha_sd))
  expect_equal(unname(sd_hat), expected_sd, tolerance = 1e-10)
  expect_length(sd_hat, n_tip)
  expect_gt(scale_coef[["z_species"]], 0)
  expect_lt(abs(scale_coef[["z_species"]] - alpha_sd[["z_species"]]), 0.35)

  simulated <- simulate(fit, nsim = 2L, seed = 202610271)
  expect_equal(dim(simulated), c(nrow(dat), 2L))
  expect_true(all(as.matrix(simulated) %in% c(0L, 1L)))

  fit_path <- tempfile(fileext = ".rds")
  on.exit(unlink(fit_path), add = TRUE)
  saveRDS(fit, fit_path)
  restored <- readRDS(fit_path)
  expect_equal(
    predict(restored, dpar = "sd_phylo(species)"),
    sd_hat,
    tolerance = 1e-12
  )
  expect_identical(
    simulate(restored, nsim = 2L, seed = 202610271),
    simulated
  )

  eta_slope <- -0.1 + 0.45 * x + x * slope[species_index]
  for (link in c("probit", "cloglog")) {
    probability <- if (link == "probit") {
      stats::pnorm(eta_slope)
    } else {
      -expm1(-exp(eta_slope))
    }
    dat_link <- dat
    dat_link$y <- stats::rbinom(length(eta_slope), 1L, probability)
    fit_link <- drmTMB(
      bf(
        y ~ x + phylo(0 + x | species, tree = tree),
        sd(species, level = "phylogenetic") ~ z_species
      ),
      family = stats::binomial(link = link),
      data = dat_link,
      control = drm_control(se = FALSE)
    )
    link_sd <- coef(fit_link, "sd_phylo(species)")
    expect_true(is_converged(fit_link), info = paste("link:", link))
    expect_true(all(is.finite(link_sd)), info = paste("link:", link))
    expect_true(
      abs(link_sd[["z_species"]] - alpha_sd[["z_species"]]) < 0.4,
      info = paste("link:", link)
    )
  }
})
