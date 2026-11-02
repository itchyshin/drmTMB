new_phylo_sd_clamp_fixture <- function(family, n_tip = 16L, n_each = 8L) {
  set.seed(20261020L + match(family, c("gaussian", "beta")))
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("tip_", seq_len(n_tip))
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_tip <- as.numeric(scale(stats::rnorm(n_tip)))
  names(z_tip) <- tree$tip.label
  tau <- exp(log(0.4) + 0.3 * z_tip)
  field <- as.vector(t(chol(K)) %*% stats::rnorm(n_tip))
  species_index <- rep(seq_len(n_tip), each = n_each)
  species <- factor(tree$tip.label[species_index], levels = tree$tip.label)
  z <- z_tip[species_index]
  x <- stats::rnorm(length(species))
  eta <- 0.2 + 0.25 * x + tau[species_index] * field[species_index]
  y <- if (identical(family, "gaussian")) {
    eta + stats::rnorm(length(eta), sd = 0.35)
  } else {
    mu <- stats::plogis(eta)
    stats::rbeta(length(mu), shape1 = 4 * mu, shape2 = 4 * (1 - mu))
  }
  list(
    data = data.frame(y, x, species, z),
    tree = tree,
    n_tip = n_tip
  )
}

fit_phylo_sd_clamp_fixture <- function(fixture, family) {
  tree <- fixture$tree
  drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sigma ~ 1,
      sd(species, level = "phylogenetic") ~ z
    ),
    family = if (identical(family, "gaussian")) {
      stats::gaussian()
    } else {
      beta_family()
    },
    data = fixture$data,
    control = drm_control(se = FALSE, logsigma_clamp = c(-2, 2))
  )
}

expect_phylo_sd_clamp_reports <- function(fit, n_tip) {
  dpar <- "sd_phylo(species)"
  perturbed <- fit$tmb_state$last.par.best
  beta_sd_idx <- which(names(perturbed) == "beta_sd_mu")
  expect_length(beta_sd_idx, 2L)
  perturbed[beta_sd_idx] <- c(4, 0)
  report <- fit$obj$report(perturbed)
  expected <- 2 + 3 * tanh((4 - 2) / 3)
  # G1 C4: log_sd_phylo_group is the RAW linear predictor (so the clamp-hit
  # check can see it); the clamp is applied where sd_phylo_group is formed.
  expect_equal(
    report$log_sd_phylo_group,
    rep(4, n_tip),
    tolerance = 1e-10
  )
  expect_equal(
    log(report$sd_phylo_group),
    rep(expected, n_tip),
    tolerance = 1e-10
  )

  fit_perturbed <- fit
  fit_perturbed$coefficients[[dpar]] <- c(`(Intercept)` = 4, z = 0)
  expect_equal(
    unname(predict(fit_perturbed, dpar = dpar, type = "link")),
    unname(log(report$sd_phylo_group)),
    tolerance = 1e-10
  )
}

test_that("Gaussian phylogenetic SD reports use the effective clamped scale", {
  skip_if_not_installed("ape")
  fixture <- new_phylo_sd_clamp_fixture("gaussian")
  fit <- fit_phylo_sd_clamp_fixture(fixture, "gaussian")

  expect_equal(fit$opt$convergence, 0L)
  expect_phylo_sd_clamp_reports(fit, fixture$n_tip)
})

test_that("Beta phylogenetic SD reports use the effective clamped scale", {
  skip_if_not_installed("ape")
  fixture <- new_phylo_sd_clamp_fixture("beta")
  fit <- fit_phylo_sd_clamp_fixture(fixture, "beta")

  expect_equal(fit$opt$convergence, 0L)
  expect_phylo_sd_clamp_reports(fit, fixture$n_tip)
})

test_that("bivariate phylogenetic SD reports use the effective clamped scale", {
  skip_if_not_installed("ape")
  set.seed(2026102029L)
  n_tip <- 12L
  n_each <- 8L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("tip_", seq_len(n_tip))
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_tip <- as.numeric(scale(stats::rnorm(n_tip)))
  names(z_tip) <- tree$tip.label
  species_index <- rep(seq_len(n_tip), each = n_each)
  species <- factor(tree$tip.label[species_index], levels = tree$tip.label)
  z <- z_tip[species_index]
  x <- stats::rnorm(length(species))
  field1 <- as.vector(t(chol(K)) %*% stats::rnorm(n_tip))
  field2 <- as.vector(t(chol(K)) %*% stats::rnorm(n_tip))
  eta1 <- 0.2 + 0.25 * x + exp(log(0.4) + 0.3 * z_tip)[species_index] *
    field1[species_index]
  eta2 <- -0.1 + 0.2 * x + exp(log(0.35) + 0.2 * z_tip)[species_index] *
    field2[species_index]
  dat <- data.frame(
    y1 = eta1 + stats::rnorm(length(eta1), sd = 0.35),
    y2 = eta2 + stats::rnorm(length(eta2), sd = 0.4),
    x,
    species,
    z
  )
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1,
      sd1(species, level = "phylogenetic") ~ z,
      sd2(species, level = "phylogenetic") ~ z
    ),
    family = biv_gaussian(),
    data = dat,
    control = drm_control(se = FALSE, logsigma_clamp = c(-2, 2))
  )

  perturbed <- fit$tmb_state$last.par.best
  beta_sd_idx <- which(names(perturbed) == "beta_sd_mu")
  expect_length(beta_sd_idx, 4L)
  perturbed[beta_sd_idx] <- c(4, 0, 4, 0)
  report <- fit$obj$report(perturbed)
  expected <- 2 + 3 * tanh((4 - 2) / 3)
  # G1 C4: raw log_sd_phylo_group, clamp applied in sd_phylo_group.
  expect_equal(
    report$log_sd_phylo_group,
    rep(4, length(report$log_sd_phylo_group)),
    tolerance = 1e-10
  )
  expect_equal(
    log(report$sd_phylo_group),
    rep(expected, length(report$log_sd_phylo_group)),
    tolerance = 1e-10
  )
  fit_perturbed <- fit
  fit_perturbed$coefficients[["sd_phylo1(species)"]] <-
    c(`(Intercept)` = 4, z = 0)
  fit_perturbed$coefficients[["sd_phylo2(species)"]] <-
    c(`(Intercept)` = 4, z = 0)
  expect_equal(
    unname(predict(fit_perturbed, dpar = "sd_phylo1(species)", type = "link")),
    rep(expected, n_tip),
    tolerance = 1e-10
  )
  expect_equal(
    unname(predict(fit_perturbed, dpar = "sd_phylo2(species)", type = "link")),
    rep(expected, n_tip),
    tolerance = 1e-10
  )
})
