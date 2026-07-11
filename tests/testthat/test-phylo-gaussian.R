balanced_ultrametric_tree <- function(n_tip = 16L) {
  stopifnot(n_tip >= 2L, log2(n_tip) == floor(log2(n_tip)))
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L

  build <- function(tips) {
    if (length(tips) == 1L) {
      return(tips)
    }
    node <- next_node
    next_node <<- next_node + 1L
    mid <- length(tips) / 2L
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    edges <<- rbind(edges, c(node, left), c(node, right))
    edge_lengths <<- c(edge_lengths, 1, 1)
    node
  }

  build(seq_len(n_tip))
  structure(
    list(
      edge = edges,
      edge.length = edge_lengths,
      tip.label = paste0("sp_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

new_phylo_gaussian_data <- function(
  seed = 20260547,
  n_tip = 16L,
  n_each = 8L,
  sd_phylo = 0.7,
  sigma = 0.25
) {
  set.seed(seed)
  tree <- balanced_ultrametric_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  phylo_effect <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip, sd = sd_phylo))
  names(phylo_effect) <- tree$tip.label
  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  beta_mu <- c(`(Intercept)` = 0.4, x = -0.35)
  y <- beta_mu[[1L]] +
    beta_mu[[2L]] * x +
    phylo_effect[species] +
    stats::rnorm(length(species), sd = sigma)

  list(
    data = data.frame(
      y = unname(y),
      x = x,
      species = species
    ),
    tree = tree,
    beta_mu = beta_mu,
    sd_phylo = sd_phylo,
    sigma = sigma
  )
}

new_phylo_location_scale_gaussian_data <- function(
  seed = 20260614,
  n_tip = 8L,
  n_each = 8L,
  sd_phylo = c(mu = 0.40, sigma = 0.18),
  rho_phylo = 0.25
) {
  set.seed(seed)
  tree <- balanced_ultrametric_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_mu <- stats::rnorm(n_tip)
  z_sigma <- rho_phylo * z_mu + sqrt(1 - rho_phylo^2) * stats::rnorm(n_tip)
  phylo_mu <- as.vector(t(chol(A)) %*% z_mu) * sd_phylo[["mu"]]
  phylo_sigma <- as.vector(t(chol(A)) %*% z_sigma) *
    sd_phylo[["sigma"]]
  names(phylo_mu) <- tree$tip.label
  names(phylo_sigma) <- tree$tip.label

  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  beta_mu <- c(`(Intercept)` = 0.4, x = 0.30)
  beta_sigma <- c(`(Intercept)` = -1.20)
  log_sigma <- beta_sigma[[1L]] + phylo_sigma[species]
  y <- beta_mu[[1L]] +
    beta_mu[["x"]] * x +
    phylo_mu[species] +
    exp(log_sigma) * stats::rnorm(length(species))

  list(
    data = data.frame(y = unname(y), x = x, species = species),
    tree = tree,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_phylo = sd_phylo,
    rho_phylo = rho_phylo
  )
}

new_sigma_only_phylo_gaussian_data <- function(
  seed = 20260627,
  n_tip = 8L,
  n_each = 18L,
  sd_phylo = 0.45,
  beta_mu = c(`(Intercept)` = 0.20, x = 0.35),
  beta_sigma = c(`(Intercept)` = -1.00)
) {
  set.seed(seed)
  tree <- balanced_ultrametric_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_sigma <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip))
  phylo_sigma <- z_sigma * sd_phylo
  names(phylo_sigma) <- tree$tip.label

  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  log_sigma <- beta_sigma[[1L]] + phylo_sigma[species]
  y <- beta_mu[[1L]] +
    beta_mu[["x"]] * x +
    exp(log_sigma) * stats::rnorm(length(species))

  list(
    data = data.frame(y = unname(y), x = x, species = species),
    tree = tree,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_phylo = sd_phylo
  )
}

new_sigma_only_phylo_gaussian_slope_data <- function(
  seed = 20260634,
  n_tip = 16L,
  n_each = 12L,
  beta_mu = c(`(Intercept)` = 0.35, x = -0.20),
  beta_sigma = c(`(Intercept)` = -1.05),
  sd_phylo = c(`(Intercept)` = 0.30, x = 0.18)
) {
  set.seed(seed)
  tree <- balanced_ultrametric_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  phylo_intercept <- as.vector(
    t(chol(A)) %*% stats::rnorm(n_tip, sd = sd_phylo[["(Intercept)"]])
  )
  phylo_slope <- as.vector(
    t(chol(A)) %*% stats::rnorm(n_tip, sd = sd_phylo[["x"]])
  )
  names(phylo_intercept) <- tree$tip.label
  names(phylo_slope) <- tree$tip.label

  species <- rep(tree$tip.label, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), times = n_tip)
  log_sigma <- beta_sigma[[1L]] +
    phylo_intercept[species] +
    phylo_slope[species] * x
  y <- beta_mu[[1L]] +
    beta_mu[["x"]] * x +
    exp(log_sigma) * stats::rnorm(length(species))

  list(
    data = data.frame(y = unname(y), x = x, species = species),
    tree = tree,
    beta_mu = beta_mu,
    beta_sigma = beta_sigma,
    sd_phylo = sd_phylo
  )
}

new_phylo_gaussian_slope_data <- function(
  seed = 20260573,
  n_tip = 16L,
  n_each = 8L,
  sd_intercept = 0.55,
  sd_slope = 0.32,
  sigma = 0.22
) {
  set.seed(seed)
  tree <- balanced_ultrametric_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  phylo_intercept <- as.vector(
    t(chol(A)) %*% stats::rnorm(n_tip, sd = sd_intercept)
  )
  phylo_slope <- as.vector(
    t(chol(A)) %*% stats::rnorm(n_tip, sd = sd_slope)
  )
  names(phylo_intercept) <- tree$tip.label
  names(phylo_slope) <- tree$tip.label

  species <- rep(tree$tip.label, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), times = n_tip)
  beta_mu <- c(`(Intercept)` = 0.4, x = -0.25)
  y <- beta_mu[[1L]] +
    beta_mu[[2L]] * x +
    phylo_intercept[species] +
    phylo_slope[species] * x +
    stats::rnorm(length(species), sd = sigma)

  list(
    data = data.frame(y = unname(y), x = x, species = species),
    tree = tree,
    beta_mu = beta_mu,
    sd_intercept = sd_intercept,
    sd_slope = sd_slope,
    sigma = sigma
  )
}

new_sd_phylo_gaussian_data <- function(
  seed = 20260821,
  n_tip = 16L,
  n_each = 10L,
  alpha_sd_phylo = c(`(Intercept)` = log(0.55), z_species = 0.70),
  sigma = 0.22
) {
  set.seed(seed)
  tree <- balanced_ultrametric_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_species <- seq(-1, 1, length.out = n_tip)
  tau <- exp(
    alpha_sd_phylo[["(Intercept)"]] +
      alpha_sd_phylo[["z_species"]] * z_species
  )
  names(tau) <- tree$tip.label
  base_phylo <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip))
  names(base_phylo) <- tree$tip.label
  phylo_effect <- tau * base_phylo

  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  beta_mu <- c(`(Intercept)` = 0.4, x = -0.25)
  y <- beta_mu[[1L]] +
    beta_mu[[2L]] * x +
    phylo_effect[species] +
    stats::rnorm(length(species), sd = sigma)

  list(
    data = data.frame(
      y = unname(y),
      x = x,
      species = species,
      z_species = z_species[match(species, tree$tip.label)]
    ),
    tree = tree,
    beta_mu = beta_mu,
    alpha_sd_phylo = alpha_sd_phylo,
    tau = tau,
    sigma = sigma
  )
}

new_biv_phylo_gaussian_data <- function(
  seed = 20260550,
  n_tip = 8L,
  n_each = 5L,
  sd_phylo = c(0.55, 0.45),
  rho_phylo = 0.35,
  sigma = c(0.25, 0.30),
  rho12 = -0.20
) {
  set.seed(seed)
  tree <- balanced_ultrametric_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  z1 <- stats::rnorm(n_tip)
  z2 <- rho_phylo * z1 + sqrt(1 - rho_phylo^2) * stats::rnorm(n_tip)
  phylo1 <- as.vector(t(chol(A)) %*% z1) * sd_phylo[[1L]]
  phylo2 <- as.vector(t(chol(A)) %*% z2) * sd_phylo[[2L]]
  names(phylo1) <- tree$tip.label
  names(phylo2) <- tree$tip.label

  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  beta_mu1 <- c(`(Intercept)` = 0.35, x = 0.25)
  beta_mu2 <- c(`(Intercept)` = -0.20, x = -0.30)
  e1 <- stats::rnorm(length(species))
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(length(species))

  list(
    data = data.frame(
      y1 = beta_mu1[[1L]] +
        beta_mu1[[2L]] * x +
        phylo1[species] +
        sigma[[1L]] * e1,
      y2 = beta_mu2[[1L]] +
        beta_mu2[[2L]] * x +
        phylo2[species] +
        sigma[[2L]] * e2,
      x = x,
      species = species
    ),
    tree = tree,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    sd_phylo = sd_phylo,
    rho_phylo = rho_phylo,
    sigma = sigma,
    rho12 = rho12
  )
}

new_biv_phylo_corpair_gaussian_data <- function(
  seed = 20260903,
  n_tip = 8L,
  n_each = 8L,
  sd_phylo = c(0.60, 0.50),
  alpha_cor = c(`(Intercept)` = 0.05, z_species = 0.65),
  sigma = c(0.18, 0.20),
  rho12 = 0.05
) {
  set.seed(seed)
  tree <- balanced_ultrametric_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_species <- seq(-1, 1, length.out = n_tip)
  eta_cor <- alpha_cor[["(Intercept)"]] +
    alpha_cor[["z_species"]] * z_species
  rho_phylo <- 0.999999 * tanh(eta_cor)
  c_load <- sqrt((1 + rho_phylo) / 2)
  d_load <- sqrt((1 - rho_phylo) / 2)
  z1 <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip))
  z2 <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip))
  phylo1 <- sd_phylo[[1L]] * (c_load * z1 + d_load * z2)
  phylo2 <- sd_phylo[[2L]] * (c_load * z1 - d_load * z2)
  names(phylo1) <- tree$tip.label
  names(phylo2) <- tree$tip.label
  names(z_species) <- tree$tip.label

  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  beta_mu1 <- c(`(Intercept)` = 0.20, x = 0.25)
  beta_mu2 <- c(`(Intercept)` = -0.15, x = -0.20)
  e1 <- stats::rnorm(length(species))
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(length(species))

  list(
    data = data.frame(
      y1 = beta_mu1[[1L]] +
        beta_mu1[[2L]] * x +
        phylo1[species] +
        sigma[[1L]] * e1,
      y2 = beta_mu2[[1L]] +
        beta_mu2[[2L]] * x +
        phylo2[species] +
        sigma[[2L]] * e2,
      x = x,
      species = species,
      z_species = z_species[species]
    ),
    tree = tree,
    alpha_cor = alpha_cor,
    rho_phylo = rho_phylo,
    sd_phylo = sd_phylo,
    sigma = sigma,
    rho12 = rho12
  )
}

new_biv_sd_phylo_gaussian_data <- function(
  seed = 20260823,
  n_tip = 16L,
  n_each = 8L,
  alpha1 = c(`(Intercept)` = log(0.55), z_species = 0.60),
  alpha2 = c(`(Intercept)` = log(0.45), z_species = -0.50),
  rho_phylo = 0.30,
  sigma = c(0.20, 0.22),
  rho12 = 0.05
) {
  set.seed(seed)
  tree <- balanced_ultrametric_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_species <- seq(-1, 1, length.out = n_tip)
  tau1 <- exp(alpha1[["(Intercept)"]] + alpha1[["z_species"]] * z_species)
  tau2 <- exp(alpha2[["(Intercept)"]] + alpha2[["z_species"]] * z_species)
  names(tau1) <- tree$tip.label
  names(tau2) <- tree$tip.label
  z1 <- stats::rnorm(n_tip)
  z2 <- rho_phylo * z1 + sqrt(1 - rho_phylo^2) * stats::rnorm(n_tip)
  base1 <- as.vector(t(chol(A)) %*% z1)
  base2 <- as.vector(t(chol(A)) %*% z2)
  names(base1) <- tree$tip.label
  names(base2) <- tree$tip.label
  phylo1 <- tau1 * base1
  phylo2 <- tau2 * base2

  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  beta_mu1 <- c(`(Intercept)` = 0.25, x = 0.30)
  beta_mu2 <- c(`(Intercept)` = -0.15, x = -0.25)
  e1 <- stats::rnorm(length(species))
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(length(species))

  list(
    data = data.frame(
      y1 = beta_mu1[[1L]] +
        beta_mu1[[2L]] * x +
        phylo1[species] +
        sigma[[1L]] * e1,
      y2 = beta_mu2[[1L]] +
        beta_mu2[[2L]] * x +
        phylo2[species] +
        sigma[[2L]] * e2,
      x = x,
      species = species,
      z_species = z_species[match(species, tree$tip.label)]
    ),
    tree = tree,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    alpha1 = alpha1,
    alpha2 = alpha2,
    tau1 = tau1,
    tau2 = tau2,
    rho_phylo = rho_phylo,
    sigma = sigma,
    rho12 = rho12
  )
}

new_biv_phylo_q4_gaussian_data <- function(
  seed = 20260802,
  n_tip = 32L,
  n_each = 6L,
  sd_phylo = c(mu1 = 0.60, mu2 = 0.50, sigma1 = 0.18, sigma2 = 0.16),
  rho12 = 0.15
) {
  set.seed(seed)
  tree <- balanced_ultrametric_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  corr <- matrix(
    c(
      1.00,
      0.50,
      0.10,
      0.05,
      0.50,
      1.00,
      0.05,
      0.10,
      0.10,
      0.05,
      1.00,
      0.25,
      0.05,
      0.10,
      0.25,
      1.00
    ),
    nrow = 4L,
    byrow = TRUE,
    dimnames = list(names(sd_phylo), names(sd_phylo))
  )
  covariance <- diag(sd_phylo) %*% corr %*% diag(sd_phylo)
  z_phylo <- matrix(stats::rnorm(n_tip * 4L), n_tip, 4L)
  phylo_effect <- t(chol(A)) %*% z_phylo %*% chol(covariance)
  dimnames(phylo_effect) <- list(tree$tip.label, names(sd_phylo))

  species <- rep(tree$tip.label, each = n_each)
  n <- length(species)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  beta_mu1 <- c(`(Intercept)` = 0.35, x = 0.30)
  beta_mu2 <- c(`(Intercept)` = -0.20, x = -0.25)
  beta_sigma1 <- c(`(Intercept)` = -1.15, z = 0.20)
  beta_sigma2 <- c(`(Intercept)` = -1.05, z = -0.15)

  eta_mu1 <- beta_mu1[[1L]] +
    beta_mu1[[2L]] * x +
    phylo_effect[species, "mu1"]
  eta_mu2 <- beta_mu2[[1L]] +
    beta_mu2[[2L]] * x +
    phylo_effect[species, "mu2"]
  log_sigma1 <- beta_sigma1[[1L]] +
    beta_sigma1[[2L]] * z +
    phylo_effect[species, "sigma1"]
  log_sigma2 <- beta_sigma2[[1L]] +
    beta_sigma2[[2L]] * z +
    phylo_effect[species, "sigma2"]
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)

  list(
    data = data.frame(
      y1 = eta_mu1 + exp(log_sigma1) * e1,
      y2 = eta_mu2 + exp(log_sigma2) * e2,
      x = x,
      z = z,
      species = species
    ),
    tree = tree,
    beta_mu1 = beta_mu1,
    beta_mu2 = beta_mu2,
    beta_sigma1 = beta_sigma1,
    beta_sigma2 = beta_sigma2,
    sd_phylo = sd_phylo,
    corr_phylo = corr,
    rho12 = rho12
  )
}

dense_gaussian_nll <- function(y, mu, covariance) {
  chol_covariance <- chol(covariance)
  residual <- y - mu
  standardized <- backsolve(chol_covariance, residual, transpose = TRUE)
  0.5 *
    (length(y) *
      log(2 * pi) +
      2 * sum(log(diag(chol_covariance))) +
      sum(standardized^2))
}

dense_phylo_gaussian_nll <- function(y, mu, sigma, sd_phylo, A) {
  dense_gaussian_nll(
    y = y,
    mu = mu,
    covariance = sigma^2 * diag(length(y)) + sd_phylo^2 * A
  )
}

dense_biv_phylo_gaussian_nll <- function(
  y1,
  y2,
  mu1,
  mu2,
  sigma1,
  sigma2,
  rho12,
  sd_phylo,
  rho_phylo,
  A
) {
  n <- length(y1)
  i1 <- seq.int(1L, by = 2L, length.out = n)
  i2 <- seq.int(2L, by = 2L, length.out = n)
  covariance <- matrix(0, nrow = 2L * n, ncol = 2L * n)
  covariance[i1, i1] <- sd_phylo[[1L]]^2 * A
  covariance[i2, i2] <- sd_phylo[[2L]]^2 * A
  covariance[i1, i2] <- rho_phylo * sd_phylo[[1L]] * sd_phylo[[2L]] * A
  covariance[i2, i1] <- t(covariance[i1, i2])
  covariance[cbind(i1, i1)] <- covariance[cbind(i1, i1)] + sigma1^2
  covariance[cbind(i2, i2)] <- covariance[cbind(i2, i2)] + sigma2^2
  residual_cov <- rho12 * sigma1 * sigma2
  covariance[cbind(i1, i2)] <- covariance[cbind(i1, i2)] + residual_cov
  covariance[cbind(i2, i1)] <- covariance[cbind(i2, i1)] + residual_cov

  y <- as.vector(rbind(y1, y2))
  mu <- as.vector(rbind(mu1, mu2))
  dense_gaussian_nll(y, mu, covariance)
}

test_that("Gaussian mu supports phylogenetic random intercepts", {
  sim <- new_phylo_gaussian_data()
  dat <- sim$data
  tree <- sim$tree

  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$opt$convergence, 0)
  expect_named(fit$sdpars$mu, "phylo(1 | species)")
  expect_equal(length(fit$random_effects$phylo_mu$values), 2 * 16 - 2)
  expect_equal(ranef(fit, "phylo_mu"), fit$random_effects$phylo_mu)
  expect_lt(max(abs(unname(coef(fit, "mu")) - unname(sim$beta_mu))), 0.35)
  expect_lt(abs(unname(fit$sdpars$mu) - sim$sd_phylo), 0.45)
  expect_lt(abs(stats::sigma(fit)[[1L]] - sim$sigma), 0.10)

  targets <- profile_targets(fit)
  mu_target <- targets[
    targets$parm == "sd:mu:phylo(1 | species)",
    ,
    drop = FALSE
  ]
  expect_equal(nrow(mu_target), 1L)
  expect_equal(mu_target$target_type, "direct")
  expect_equal(mu_target$profile_ready, TRUE)
  expect_equal(mu_target$profile_note, "ready")
  expect_true(is.finite(as.numeric(stats::logLik(fit))))
})

test_that("Gaussian mu supports sd_phylo(species) direct-SD models", {
  sim <- new_sd_phylo_gaussian_data()
  dat <- sim$data
  tree <- sim$tree

  fit <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sigma ~ 1,
      sd_phylo(species) ~ z_species
    ),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 1000, iter.max = 1000)
  )

  sd_hat <- predict(fit, dpar = "sd_phylo(species)")
  sd_link <- predict(fit, dpar = "sd_phylo(species)", type = "link")
  profile <- profile_targets(fit)
  sd_coef_rows <- profile[
    grepl("^fixef:sd_phylo\\(species\\):", profile$parm),
    ,
    drop = FALSE
  ]

  expect_equal(fit$opt$convergence, 0)
  expect_named(coef(fit, "sd_phylo(species)"), names(sim$alpha_sd_phylo))
  expect_named(fit$sdpars, "sd_phylo(species)")
  expect_equal(exp(sd_link), sd_hat, tolerance = 1e-10)
  expect_gt(
    stats::cor(log(sd_hat), log(sim$tau[names(sd_hat)])),
    0.90
  )
  expect_gt(coef(fit, "sd_phylo(species)")[["z_species"]], 0)
  expect_lt(
    max(abs(coef(fit, "mu") - sim$beta_mu)),
    0.35
  )
  expect_lt(abs(stats::sigma(fit)[[1L]] - sim$sigma), 0.15)
  expect_equal(sd_coef_rows$tmb_parameter, rep("beta_sd_mu", 2L))
  expect_equal(sd_coef_rows$index, c(1L, 2L))
  expect_true(all(sd_coef_rows$profile_ready))
})

test_that("sd_phylo(species) intercept-only matches scalar phylo SD likelihood", {
  sim <- new_phylo_gaussian_data(seed = 20260822, n_tip = 8L, n_each = 6L)
  dat <- sim$data
  tree <- sim$tree

  fit_scalar <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 500, iter.max = 500)
  )
  fit_sd_phylo <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sigma ~ 1,
      sd_phylo(species) ~ 1
    ),
    family = gaussian(),
    data = dat,
    control = list(eval.max = 500, iter.max = 500)
  )

  expect_equal(fit_scalar$opt$convergence, 0)
  expect_equal(fit_sd_phylo$opt$convergence, 0)
  expect_equal(
    as.numeric(stats::logLik(fit_sd_phylo)),
    as.numeric(stats::logLik(fit_scalar)),
    tolerance = 1e-5
  )
  expect_equal(
    unname(coef(fit_sd_phylo, "sd_phylo(species)")[[1L]]),
    log(unname(fit_scalar$sdpars$mu[["phylo(1 | species)"]])),
    tolerance = 1e-5
  )
})

test_that("fitted phylogenetic mu objective matches dense marginal likelihood", {
  tree <- balanced_ultrametric_tree(n_tip = 4L)
  species <- rep(tree$tip.label, each = 3L)
  x <- rep(c(-0.7, 0.1, 0.8), times = 4L)
  phylo_signal <- c(sp_1 = -0.45, sp_2 = -0.2, sp_3 = 0.25, sp_4 = 0.55)
  dat <- data.frame(
    y = 0.3 +
      0.6 * x +
      phylo_signal[species] +
      rep(c(-0.1, 0.05, 0.12), times = 4L),
    x = x,
    species = species
  )

  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  X_mu <- stats::model.matrix(~x, dat)
  mu <- as.vector(X_mu %*% coef(fit, "mu"))
  A_tip <- drmTMB:::drm_phylo_tip_covariance(tree)
  A_obs <- A_tip[dat$species, dat$species]
  dense_nll <- dense_phylo_gaussian_nll(
    y = dat$y,
    mu = mu,
    sigma = stats::sigma(fit)[[1L]],
    sd_phylo = unname(fit$sdpars$mu),
    A = A_obs
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$opt$objective, dense_nll, tolerance = 1e-4)
})

test_that("bivariate Gaussian mu supports correlated phylogenetic random intercepts", {
  sim <- new_biv_phylo_gaussian_data()
  dat <- sim$data
  tree <- sim$tree

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 300, iter.max = 300)
  )

  fixed_mu1 <- as.vector(stats::model.matrix(~x, dat) %*% coef(fit, "mu1"))
  fixed_mu2 <- as.vector(stats::model.matrix(~x, dat) %*% coef(fit, "mu2"))
  A_tip <- drmTMB:::drm_phylo_tip_covariance(tree)
  A_obs <- A_tip[dat$species, dat$species]
  dense_nll <- dense_biv_phylo_gaussian_nll(
    y1 = dat$y1,
    y2 = dat$y2,
    mu1 = fixed_mu1,
    mu2 = fixed_mu2,
    sigma1 = stats::sigma(fit)$sigma1[[1L]],
    sigma2 = stats::sigma(fit)$sigma2[[1L]],
    rho12 = rho12(fit)[[1L]],
    sd_phylo = unname(fit$sdpars$mu),
    rho_phylo = unname(fit$corpars$phylo),
    A = A_obs
  )
  phylo_mu1 <- fit$random_effects$phylo_mu$values[
    fit$model$structured$phylo_mu$observation_node_index
  ]
  phylo_mu2 <- fit$random_effects$phylo_mu$values[
    fit$model$structured$phylo_mu$n_re +
      fit$model$structured$phylo_mu$observation_node_index
  ]
  covariance <- summary(fit)$covariance

  expect_equal(fit$opt$convergence, 0)
  expect_named(
    fit$sdpars$mu,
    c("mu1:phylo(1 | p | species)", "mu2:phylo(1 | p | species)")
  )
  expect_named(
    fit$corpars$phylo,
    "cor(mu1:(Intercept),mu2:(Intercept) | p | species)"
  )
  targets <- profile_targets(fit)
  phylo_profile_names <- c(
    "sd:mu:mu1:phylo(1 | p | species)",
    "sd:mu:mu2:phylo(1 | p | species)",
    "cor:phylo:cor(mu1:(Intercept),mu2:(Intercept) | p | species)"
  )
  phylo_profile <- targets[
    match(phylo_profile_names, targets$parm),
    ,
    drop = FALSE
  ]
  expect_equal(phylo_profile$parm, phylo_profile_names)
  expect_equal(
    phylo_profile$tmb_parameter,
    c("log_sd_phylo", "log_sd_phylo", "eta_cor_phylo")
  )
  expect_equal(phylo_profile$index, c(1L, 2L, 1L))
  expect_equal(phylo_profile$target_type, rep("direct", 3L))
  expect_equal(length(fit$random_effects$phylo_mu$values), 2L * (2L * 8L - 2L))
  expect_equal(fit$opt$objective, dense_nll, tolerance = 1e-4)
  expect_equal(
    predict(fit, dpar = "mu1"),
    fixed_mu1 + unname(phylo_mu1),
    tolerance = 1e-10
  )
  expect_equal(
    predict(fit, dpar = "mu2"),
    fixed_mu2 + unname(phylo_mu2),
    tolerance = 1e-10
  )
  expect_equal(
    predict(fit, newdata = dat[1:3, ], dpar = "mu1"),
    fixed_mu1[1:3],
    tolerance = 1e-10
  )

  sims <- simulate(fit, nsim = 2, seed = 20260631)
  expect_named(sims, c("sim_1_y1", "sim_1_y2", "sim_2_y1", "sim_2_y2"))
  expect_equal(nrow(sims), nrow(dat))
  expect_true(all(vapply(sims, is.numeric, logical(1L))))
  expect_true(all(is.finite(as.matrix(sims))))
  expect_equal(sims, simulate(fit, nsim = 2, seed = 20260631))
})

test_that("bivariate Gaussian mu supports phylogenetic q2 slope-only covariance", {
  sim <- new_biv_phylo_gaussian_data(n_tip = 8L, n_each = 4L)
  dat <- sim$data
  tree <- sim$tree

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(0 + x | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(0 + x | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 300, iter.max = 300)
    )
  )

  fixed_mu1 <- as.vector(stats::model.matrix(~x, dat) %*% coef(fit, "mu1"))
  fixed_mu2 <- as.vector(stats::model.matrix(~x, dat) %*% coef(fit, "mu2"))
  structured <- fit$model$structured$phylo_mu
  pair <- corpairs(fit, level = "phylogenetic")
  covariance <- summary(fit)$covariance
  targets <- profile_targets(fit)
  profile_names <- c(
    "sd:mu:mu1:phylo(0 + x | p | species)",
    "sd:mu:mu2:phylo(0 + x | p | species)",
    "cor:phylo:cor(mu1:x,mu2:x | p | species)"
  )
  profile <- targets[match(profile_names, targets$parm), , drop = FALSE]
  structured_row <- structured_effects(fit)

  expect_equal(fit$opt$convergence, 0)
  expect_equal(structured$q, 2L)
  expect_equal(structured$coef_names, c("x", "x"))
  expect_equal(structured$dpars, c("mu1", "mu2"))
  expect_named(
    fit$sdpars$mu,
    c(
      "mu1:phylo(0 + x | p | species)",
      "mu2:phylo(0 + x | p | species)"
    )
  )
  expect_named(fit$corpars$phylo, "cor(mu1:x,mu2:x | p | species)")
  expect_equal(nrow(pair), 1L)
  expect_equal(pair$from_coef, "x")
  expect_equal(pair$to_coef, "x")
  expect_equal(pair$class, "slope-slope")
  expect_equal(pair$parameter, names(fit$corpars$phylo))
  expect_equal(nrow(covariance), 1L)
  expect_equal(covariance$from_coef, "x")
  expect_equal(covariance$to_coef, "x")
  expect_equal(covariance$class, "slope-slope")
  expect_equal(covariance$parameter, names(fit$corpars$phylo))
  expect_equal(profile$parm, profile_names)
  expect_equal(
    profile$tmb_parameter,
    c("log_sd_phylo", "log_sd_phylo", "eta_cor_phylo")
  )
  expect_equal(profile$index, c(1L, 2L, 1L))
  expect_equal(profile$target_type, rep("direct", 3L))
  expect_equal(profile$profile_ready, rep(TRUE, 3L))
  expect_equal(structured_row$endpoint_set, "mu1+mu2")
  expect_equal(structured_row$coefficient_set, "x+x")
  expect_equal(structured_row$endpoint_member_set, "mu1:x+mu2:x")
  expect_equal(structured_row$endpoint_member_count, 2L)
  expect_equal(structured_row$covariance_layout, "scalar")
  manual_mu1 <- fit$random_effects$phylo_mu$values[
    structured$observation_node_index
  ] *
    structured$value[, 1L]
  manual_mu2 <- fit$random_effects$phylo_mu$values[
    structured$observation_node_index + structured$n_re
  ] *
    structured$value[, 2L]
  expect_equal(
    drmTMB:::phylo_mu_contribution(fit, dpar = "mu1"),
    unname(manual_mu1),
    tolerance = 1e-10
  )
  expect_equal(
    drmTMB:::phylo_mu_contribution(fit, dpar = "mu2"),
    unname(manual_mu2),
    tolerance = 1e-10
  )
  expect_equal(
    predict(fit, dpar = "mu1"),
    fixed_mu1 + drmTMB:::phylo_mu_contribution(fit, dpar = "mu1"),
    tolerance = 1e-10
  )
  expect_equal(
    predict(fit, dpar = "mu2"),
    fixed_mu2 + drmTMB:::phylo_mu_contribution(fit, dpar = "mu2"),
    tolerance = 1e-10
  )
})

test_that("namespaced phylo markers are accepted in bivariate formulas", {
  tree <- balanced_ultrametric_tree(n_tip = 4L)
  dat <- data.frame(
    y1 = seq(-0.2, 0.5, length.out = 8L),
    y2 = seq(0.3, -0.4, length.out = 8L),
    x = rep(c(-1, 1), 4L),
    species = rep(tree$tip.label, each = 2L)
  )

  fit <- suppressWarnings(drmTMB(
    bf(
      mu1 = y1 ~ x + drmTMB::phylo(1 | p | species, tree = tree),
      mu2 = y2 ~ x + drmTMB::phylo(1 | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 80L, iter.max = 80L)
    )
  ))

  expect_s3_class(fit, "drmTMB")
  expect_named(
    fit$sdpars$mu,
    c("mu1:phylo(1 | p | species)", "mu2:phylo(1 | p | species)")
  )
  expect_equal(fit$model$structured$phylo_mu$block, "p")
  expect_equal(fit$model$structured$phylo_mu$type, "phylo")
})

test_that("bivariate phylogenetic mean correlation recovers simulated signal", {
  sim <- new_biv_phylo_gaussian_data(
    seed = 20260632,
    n_tip = 32L,
    n_each = 6L,
    sd_phylo = c(0.90, 0.80),
    rho_phylo = 0.55,
    sigma = c(0.18, 0.20),
    rho12 = 0.10
  )
  dat <- sim$data
  tree <- sim$tree

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 500, iter.max = 500)
  )

  phylo_pair <- corpairs(fit, level = "phylogenetic")

  expect_equal(fit$opt$convergence, 0)
  expect_gt(unname(fit$corpars$phylo), 0.35)
  expect_lt(abs(unname(fit$corpars$phylo) - sim$rho_phylo), 0.20)
  expect_lt(max(abs(unname(fit$sdpars$mu) - sim$sd_phylo)), 0.25)
  expect_lt(
    max(abs(
      c(
        unique(stats::sigma(fit)$sigma1),
        unique(stats::sigma(fit)$sigma2)
      ) -
        sim$sigma
    )),
    0.08
  )
  expect_lt(abs(unique(rho12(fit)) - sim$rho12), 0.20)
  expect_equal(nrow(phylo_pair), 1L)
  expect_equal(phylo_pair$estimate, unname(fit$corpars$phylo))
})

test_that("bivariate phylogenetic corpair regression reports q2 location correlation", {
  sim <- new_biv_phylo_corpair_gaussian_data()
  dat <- sim$data
  tree <- sim$tree

  # CRAN-safe smoke check for plumbing and reporting; broader recovery belongs
  # in a larger non-CRAN Slice 31 simulation because this tiny design is weak.
  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1,
      corpair(
        species,
        level = "phylogenetic",
        block = "p",
        from = "mu1",
        to = "mu2"
      ) ~ z_species
    ),
    family = c(gaussian(), gaussian()),
    data = dat,
    control = list(eval.max = 300, iter.max = 300)
  )
  cor_dpar <- grep("^corpair\\(", names(fit$coefficients), value = TRUE)
  pair <- corpairs(fit, level = "phylogenetic")
  pair_ci <- corpairs(fit, level = "phylogenetic", conf.int = TRUE)
  targets <- profile_targets(fit)
  ci_newdata <- data.frame(z_species = 0.10)
  row.names(ci_newdata) <- "typical_species"
  cor_ci <- stats::confint(
    fit,
    parm = cor_dpar,
    level = 0.70,
    method = "profile",
    newdata = ci_newdata,
    trace = FALSE,
    ystep = 0.45
  )
  cor_at_newdata <- predict(fit, newdata = ci_newdata, dpar = cor_dpar)

  expect_equal(fit$opt$convergence, 0)
  expect_true(is.finite(fit$opt$objective))
  expect_length(cor_dpar, 1L)
  expect_named(fit$coefficients[[cor_dpar]], c("(Intercept)", "z_species"))
  expect_true(all(is.finite(fit$coefficients[[cor_dpar]])))
  expect_equal(sum(names(fit$opt$par) == "beta_cor_mu"), 2L)
  expect_false("eta_cor_phylo" %in% names(fit$opt$par))
  expect_equal(nrow(pair), 1L)
  expect_true(pair$modelled)
  expect_equal(pair$conf.status, "not_requested")
  expect_equal(pair$interval_source, "not_available")
  expect_equal(pair$n_values, length(unique(dat$species)))
  expect_lt(pair$min, pair$max)
  expect_equal(
    pair$estimate,
    mean(predict(fit, dpar = cor_dpar, type = "response"))
  )
  expect_equal(
    predict(fit, dpar = cor_dpar, type = "response"),
    drmTMB:::rho_response(
      predict(fit, dpar = cor_dpar, type = "link"),
      guard = 0.999999
    )
  )
  expect_equal(pair_ci$conf.status, "newdata_required")
  expect_equal(pair_ci$interval_source, "not_available")
  expect_equal(cor_ci$parm, paste0(cor_dpar, "[typical_species]"))
  expect_equal(cor_ci$scale, "response")
  expect_equal(cor_ci$transformation, "random_effect_correlation_tanh")
  expect_equal(cor_ci$tmb_parameter, "beta_cor_mu")
  expect_true(is.na(cor_ci$index))
  expect_lt(cor_ci$lower, cor_at_newdata)
  expect_gt(cor_ci$upper, cor_at_newdata)
  expect_true(any(
    targets$parm == paste0("fixef:", cor_dpar, ":z_species") &
      targets$tmb_parameter == "beta_cor_mu" &
      targets$profile_ready
  ))
})

test_that("bivariate phylogenetic corpair regression recovers broad correlation trend", {
  sim <- new_biv_phylo_corpair_gaussian_data(
    seed = 20260931,
    n_tip = 16L,
    n_each = 10L,
    sd_phylo = c(0.80, 0.75),
    sigma = c(0.12, 0.12),
    alpha_cor = c(`(Intercept)` = 0, z_species = 0.40)
  )
  dat <- sim$data
  tree <- sim$tree

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1,
      corpair(
        species,
        level = "phylogenetic",
        block = "p",
        from = "mu1",
        to = "mu2"
      ) ~ z_species
    ),
    family = c(gaussian(), gaussian()),
    data = dat,
    control = list(eval.max = 800, iter.max = 800)
  )
  cor_dpar <- grep("^corpair\\(", names(fit$coefficients), value = TRUE)
  rho_hat <- predict(fit, dpar = cor_dpar, type = "response")

  expect_equal(fit$opt$convergence, 0)
  expect_equal(length(rho_hat), length(sim$rho_phylo))
  expect_gt(fit$coefficients[[cor_dpar]][["z_species"]], 0.10)
  expect_lt(fit$coefficients[[cor_dpar]][["z_species"]], 1.25)
  expect_gt(stats::cor(rho_hat, sim$rho_phylo), 0.95)
  expect_lt(max(abs(rho_hat)), 0.85)
})

test_that("bivariate phylogenetic location supports sd_phylo1 and sd_phylo2", {
  sim <- new_biv_sd_phylo_gaussian_data()
  dat <- sim$data
  tree <- sim$tree

  fit <- drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1,
      sd_phylo1(species) ~ z_species,
      sd_phylo2(species) ~ z_species
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 700, iter.max = 700)
  )

  sd1_hat <- predict(fit, dpar = "sd_phylo1(species)")
  sd2_hat <- predict(fit, dpar = "sd_phylo2(species)")
  fixed_mu1 <- as.vector(stats::model.matrix(~x, dat) %*% coef(fit, "mu1"))
  fixed_mu2 <- as.vector(stats::model.matrix(~x, dat) %*% coef(fit, "mu2"))
  phylo_mu1 <- fit$random_effects$phylo_mu$values[
    fit$model$structured$phylo_mu$observation_node_index
  ]
  phylo_mu2 <- fit$random_effects$phylo_mu$values[
    fit$model$structured$phylo_mu$n_re +
      fit$model$structured$phylo_mu$observation_node_index
  ]
  covariance <- summary(fit)$covariance

  expect_equal(fit$opt$convergence, 0)
  expect_named(
    fit$coefficients,
    c(
      "mu1",
      "mu2",
      "sigma1",
      "sigma2",
      "rho12",
      "sd_phylo1(species)",
      "sd_phylo2(species)"
    )
  )
  expect_named(
    fit$sdpars,
    c("sd_phylo1(species)", "sd_phylo2(species)")
  )
  expect_true(all(sd1_hat > 0))
  expect_true(all(sd2_hat > 0))
  expect_gt(stats::cor(log(sd1_hat), log(sim$tau1[names(sd1_hat)])), 0.40)
  expect_gt(stats::cor(log(sd2_hat), log(sim$tau2[names(sd2_hat)])), 0.40)
  expect_true(is.finite(unname(fit$corpars$phylo)))
  expect_lt(abs(unname(fit$corpars$phylo)), 1)
  expect_equal(
    predict(fit, dpar = "mu1"),
    fixed_mu1 + unname(phylo_mu1),
    tolerance = 1e-10
  )
  expect_equal(
    predict(fit, dpar = "mu2"),
    fixed_mu2 + unname(phylo_mu2),
    tolerance = 1e-10
  )
  expect_true(all(fit$model$random_scale$phylo$node_sd_row0 >= -1L))
  expect_equal(covariance$from_sd_parameter, "sd_phylo1(species):median")
  expect_equal(covariance$to_sd_parameter, "sd_phylo2(species):median")
  expect_equal(
    covariance$from_sd,
    stats::median(unname(fit$sdpars[["sd_phylo1(species)"]])),
    tolerance = 1e-12
  )
  expect_equal(
    covariance$to_sd,
    stats::median(unname(fit$sdpars[["sd_phylo2(species)"]])),
    tolerance = 1e-12
  )
  expect_true(all(is.finite(covariance$covariance)))
  expect_equal(nrow(corpairs(fit, level = "phylogenetic")), 1L)
})

test_that("bivariate phylogenetic location allows one-sided sd_phylo direct SD", {
  sim <- new_biv_sd_phylo_gaussian_data(n_tip = 8L, n_each = 5L)
  dat <- sim$data
  tree <- sim$tree

  fit_sd1 <- drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1,
      sd_phylo1(species) ~ z_species
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 600, iter.max = 600)
  )
  fit_sd2 <- drmTMB(
    bf(
      mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
      mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1,
      sd_phylo2(species) ~ z_species
    ),
    family = biv_gaussian(),
    data = dat,
    control = list(eval.max = 600, iter.max = 600)
  )

  cov_sd1 <- summary(fit_sd1)$covariance
  cov_sd2 <- summary(fit_sd2)$covariance

  expect_equal(fit_sd1$opt$convergence, 0)
  expect_equal(fit_sd2$opt$convergence, 0)
  expect_named(fit_sd1$sdpars, c("sd_phylo1(species)", "mu"))
  expect_named(fit_sd2$sdpars, c("sd_phylo2(species)", "mu"))
  expect_true(all(predict(fit_sd1, dpar = "sd_phylo1(species)") > 0))
  expect_true(all(predict(fit_sd2, dpar = "sd_phylo2(species)") > 0))
  expect_equal(cov_sd1$from_sd_parameter, "sd_phylo1(species):median")
  expect_equal(cov_sd1$to_sd_parameter, "mu2:phylo(1 | p | species)")
  expect_equal(cov_sd2$from_sd_parameter, "mu1:phylo(1 | p | species)")
  expect_equal(cov_sd2$to_sd_parameter, "sd_phylo2(species):median")
  expect_true(all(is.finite(c(cov_sd1$covariance, cov_sd2$covariance))))
})

test_that("bivariate phylogenetic q4 block is fitted with clear boundaries", {
  tree <- balanced_ultrametric_tree(n_tip = 4L)
  dat <- data.frame(
    y1 = seq(-0.2, 0.5, length.out = 8L),
    y2 = seq(0.3, -0.4, length.out = 8L),
    x = rep(c(-1, 1), 4L),
    z = rep(c(0, 1), each = 4L),
    species = rep(tree$tip.label, each = 2L)
  )

  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
        sigma1 = ~ z + phylo(1 | p | species, tree = tree),
        sigma2 = ~ z + phylo(1 | p | species, tree = tree),
        rho12 = ~1,
        sd_phylo1(species) ~ z
      ),
      family = c(gaussian(), gaussian()),
      data = dat
    ),
    "Do not combine bivariate"
  )

  fit_q4 <- suppressWarnings(
    drmTMB(
      bf(
        mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
        sigma1 = ~ z + phylo(1 | p | species, tree = tree),
        sigma2 = ~ z + phylo(1 | p | species, tree = tree),
        rho12 = ~1
      ),
      family = c(gaussian(), gaussian()),
      data = dat,
      control = list(eval.max = 100, iter.max = 100)
    )
  )
  q4_pairs <- corpairs(fit_q4, level = "phylogenetic")
  q4_pairs_ci <- corpairs(fit_q4, level = "phylogenetic", conf.int = TRUE)
  q4_cov <- summary(fit_q4)$covariance
  q4_targets <- profile_targets(fit_q4)
  q4_cor_targets <- q4_targets[
    startsWith(q4_targets$parm, "cor:phylo:"),
    ,
    drop = FALSE
  ]

  expect_true(is.finite(fit_q4$opt$objective))
  expect_named(
    fit_q4$sdpars$mu,
    c(
      "mu1:phylo(1 | p | species)",
      "mu2:phylo(1 | p | species)",
      "sigma1:phylo(1 | p | species)",
      "sigma2:phylo(1 | p | species)"
    )
  )
  expect_equal(sum(names(fit_q4$opt$par) == "theta_phylo"), 6L)
  expect_equal(nrow(q4_pairs), 6L)
  expect_equal(nrow(q4_pairs_ci), 6L)
  expect_equal(nrow(q4_cov), 6L)
  q4_class_counts <- table(q4_pairs$class)
  expect_equal(
    as.integer(q4_class_counts[c("mean-mean", "mean-scale", "scale-scale")]),
    c(1L, 4L, 1L)
  )
  expect_equal(
    q4_pairs$parameter,
    names(fit_q4$corpars$phylo)
  )
  expect_equal(q4_pairs$conf.status, rep("not_requested", 6L))
  expect_equal(q4_pairs$interval_source, rep("not_available", 6L))
  expect_equal(nrow(corpairs(fit_q4, class = "location-scale")), 4L)
  expect_equal(nrow(corpairs(fit_q4, block = "p")), 6L)
  expect_equal(q4_cov$parameter, q4_pairs$parameter)
  expect_true(all(is.finite(predict(fit_q4, dpar = "sigma1", type = "link"))))
  expect_equal(nrow(q4_cor_targets), 6L)
  expect_equal(q4_cor_targets$tmb_parameter, rep("theta_phylo", 6L))
  expect_equal(q4_cor_targets$target_type, rep("derived", 6L))
  expect_false(any(q4_cor_targets$profile_ready))
  expect_equal(
    q4_cor_targets$profile_note,
    rep("derived_unstructured_correlation", 6L)
  )
  expect_equal(q4_pairs_ci$profile_target, q4_cor_targets$parm)
  expect_equal(
    q4_pairs_ci$conf.status,
    rep("derived_interval_unavailable", 6L)
  )
  expect_equal(q4_pairs_ci$interval_source, rep("not_available", 6L))
  expect_true(all(is.na(q4_pairs_ci$conf.low)))
  expect_equal(q4_cov$covariance_conf.status, rep("not_requested", 6L))

  fit_block <- suppressWarnings(
    drmTMB(
      bf(
        mu1 = y1 ~ x + phylo(1 | pl | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 | pl | species, tree = tree),
        sigma1 = ~ z + phylo(1 | ps | species, tree = tree),
        sigma2 = ~ z + phylo(1 | ps | species, tree = tree),
        rho12 = ~1
      ),
      family = c(gaussian(), gaussian()),
      data = dat,
      control = drm_control(
        se = FALSE,
        optimizer = list(eval.max = 100, iter.max = 100)
      )
    )
  )
  block_pairs <- corpairs(fit_block, level = "phylogenetic")
  block_targets <- profile_targets(fit_block)
  block_cor_targets <- block_targets[
    startsWith(block_targets$parm, "cor:phylo:"),
    ,
    drop = FALSE
  ]

  expect_equal(
    fit_block$model$structured$phylo_mu$covariance_mode,
    "block_diagonal"
  )
  expect_equal(fit_block$model$structured$phylo_mu$block_ids, c(1L, 1L, 2L, 2L))
  expect_equal(sum(names(fit_block$opt$par) == "theta_phylo"), 2L)
  expect_equal(nrow(block_pairs), 2L)
  expect_equal(block_pairs$block, c("pl", "ps"))
  expect_equal(block_pairs$class, c("mean-mean", "scale-scale"))
  expect_equal(block_pairs$conf.status, rep("not_requested", 2L))
  expect_equal(block_pairs$interval_source, rep("not_available", 2L))
  expect_equal(nrow(corpairs(fit_block, class = "location-scale")), 0L)
  expect_equal(nrow(corpairs(fit_block, block = "pl")), 1L)
  expect_equal(nrow(corpairs(fit_block, block = "ps")), 1L)
  expect_equal(block_cor_targets$tmb_parameter, rep("theta_phylo", 2L))
  expect_equal(block_cor_targets$target_type, rep("direct", 2L))
  expect_equal(block_cor_targets$transformation, rep("tanh", 2L))

  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
        sigma1 = ~ z + phylo(1 | p | species, tree = tree),
        sigma2 = ~z,
        rho12 = ~1
      ),
      family = c(gaussian(), gaussian()),
      data = dat
    ),
    "Partial phylogenetic location-scale blocks"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + phylo(1 | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 | species, tree = tree),
        sigma1 = ~ z + phylo(1 | species, tree = tree),
        sigma2 = ~ z + phylo(1 | species, tree = tree),
        rho12 = ~1
      ),
      family = c(gaussian(), gaussian()),
      data = dat
    ),
    "require an explicit covariance-block label"
  )
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 | q | species, tree = tree),
        sigma1 = ~z,
        sigma2 = ~z,
        rho12 = ~1
      ),
      family = c(gaussian(), gaussian()),
      data = dat
    ),
    "same covariance-block label"
  )
})

test_that("bivariate phylogenetic q4 all-four one-slope block exposes q8 members", {
  tree <- balanced_ultrametric_tree(n_tip = 4L)
  dat <- data.frame(
    y1 = seq(-0.2, 0.5, length.out = 8L),
    y2 = seq(0.3, -0.4, length.out = 8L),
    x = rep(c(-1, 1), 4L),
    z = rep(c(0, 1), each = 4L),
    species = rep(tree$tip.label, each = 2L)
  )

  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + phylo(1 + x | pl | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 + x | pl | species, tree = tree),
        sigma1 = ~ z + phylo(1 + x | ps | species, tree = tree),
        sigma2 = ~ z + phylo(1 + x | ps | species, tree = tree),
        rho12 = ~1
      ),
      family = c(gaussian(), gaussian()),
      data = dat
    ),
    "require one shared covariance label"
  )

  fit <- suppressWarnings(
    drmTMB(
      bf(
        mu1 = y1 ~ x + phylo(1 + x | p | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 + x | p | species, tree = tree),
        sigma1 = ~ z + phylo(1 + x | p | species, tree = tree),
        sigma2 = ~ z + phylo(1 + x | p | species, tree = tree),
        rho12 = ~1
      ),
      family = c(gaussian(), gaussian()),
      data = dat,
      control = drm_control(
        se = FALSE,
        optimizer = list(eval.max = 120, iter.max = 120)
      )
    )
  )

  q8_dpars <- rep(c("mu1", "mu2", "sigma1", "sigma2"), each = 2L)
  q8_coef <- rep(c("(Intercept)", "x"), times = 4L)
  q8_members <- paste0(q8_dpars, ":", q8_coef)
  sd_names <- paste0(
    q8_dpars,
    ":phylo(",
    ifelse(q8_coef == "(Intercept)", "1", "0 + x"),
    " | p | species)"
  )

  structured <- fit$model$structured$phylo_mu
  structured_row <- structured_effects(fit)
  q8_pairs <- corpairs(fit, level = "phylogenetic")
  q8_pairs_ci <- corpairs(fit, level = "phylogenetic", conf.int = TRUE)
  q8_targets <- profile_targets(fit)
  q8_cor_targets <- q8_targets[
    startsWith(q8_targets$parm, "cor:phylo:"),
    ,
    drop = FALSE
  ]
  q8_sd_targets <- q8_targets[
    match(paste0("sd:mu:", sd_names), q8_targets$parm),
    ,
    drop = FALSE
  ]

  expect_true(is.finite(fit$opt$objective))
  expect_equal(structured$q, 8L)
  expect_equal(structured$dpars, q8_dpars)
  expect_equal(structured$coef_names, q8_coef)
  expect_equal(structured$covariance_mode, "unstructured")
  expect_equal(structured$block_ids, rep(1L, 8L))
  expect_equal(
    structured_row$endpoint_member_set,
    paste(q8_members, collapse = "+")
  )
  expect_equal(structured_row$endpoint_member_count, 8L)
  expect_named(fit$sdpars$mu, sd_names)
  expect_equal(sum(names(fit$opt$par) == "theta_phylo"), 28L)
  expect_equal(length(fit$corpars$phylo), 28L)
  expect_equal(nrow(q8_pairs), 28L)
  expect_equal(q8_pairs$parameter, names(fit$corpars$phylo))
  expect_equal(nrow(q8_pairs_ci), 28L)
  expect_equal(nrow(q8_cor_targets), 28L)
  expect_equal(q8_cor_targets$tmb_parameter, rep("theta_phylo", 28L))
  expect_equal(q8_cor_targets$target_type, rep("derived", 28L))
  expect_false(any(q8_cor_targets$profile_ready))
  expect_equal(
    q8_cor_targets$profile_note,
    rep("derived_unstructured_correlation", 28L)
  )
  expect_equal(q8_pairs_ci$profile_target, q8_cor_targets$parm)
  expect_equal(
    q8_pairs_ci$conf.status,
    rep("derived_interval_unavailable", 28L)
  )
  expect_equal(q8_pairs_ci$interval_source, rep("not_available", 28L))
  expect_true(all(is.na(q8_pairs_ci$conf.low)))

  expect_equal(q8_sd_targets$parm, paste0("sd:mu:", sd_names))
  expect_equal(q8_sd_targets$tmb_parameter, rep("log_sd_phylo", 8L))
  expect_equal(q8_sd_targets$index, seq_len(8L))
  expect_equal(q8_sd_targets$target_type, rep("direct", 8L))

  fixed_mu1 <- as.vector(fit$model$X$mu1 %*% coef(fit, "mu1"))
  fixed_sigma2 <- as.vector(fit$model$X$sigma2 %*% coef(fit, "sigma2"))
  expect_equal(
    unname(predict(fit, dpar = "mu1", type = "link")),
    fixed_mu1 + drmTMB:::phylo_mu_contribution(fit, dpar = "mu1"),
    tolerance = 1e-8
  )
  expect_equal(
    unname(predict(fit, dpar = "sigma2", type = "link")),
    fixed_sigma2 + drmTMB:::phylo_mu_contribution(fit, dpar = "sigma2"),
    tolerance = 1e-8
  )
})

test_that("bivariate phylogenetic labelled one-slope location blocks expose partial q4 members", {
  tree <- balanced_ultrametric_tree(n_tip = 4L)
  dat <- data.frame(
    y1 = seq(-0.2, 0.5, length.out = 8L),
    y2 = seq(0.3, -0.4, length.out = 8L),
    x = rep(c(-1, 1), 4L),
    z = rep(c(0, 1), each = 4L),
    species = rep(tree$tip.label, each = 2L)
  )

  fit <- suppressWarnings(
    drmTMB(
      bf(
        mu1 = y1 ~ x + phylo(1 + x | p | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 + x | p | species, tree = tree),
        sigma1 = ~z,
        sigma2 = ~z,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      control = drm_control(
        se = FALSE,
        optimizer = list(eval.max = 120, iter.max = 120)
      )
    )
  )

  q4_dpars <- rep(c("mu1", "mu2"), each = 2L)
  q4_coef <- rep(c("(Intercept)", "x"), times = 2L)
  q4_members <- paste0(q4_dpars, ":", q4_coef)
  sd_names <- paste0(
    q4_dpars,
    ":phylo(",
    ifelse(q4_coef == "(Intercept)", "1", "0 + x"),
    " | p | species)"
  )
  structured <- fit$model$structured$phylo_mu
  structured_row <- structured_effects(fit)
  pairs <- corpairs(fit, level = "phylogenetic")
  targets <- profile_targets(fit)
  cor_targets <- targets[
    startsWith(targets$parm, "cor:phylo:"),
    ,
    drop = FALSE
  ]

  expect_true(is.finite(fit$opt$objective))
  expect_equal(structured$q, 4L)
  expect_equal(structured$dpars, q4_dpars)
  expect_equal(structured$coef_names, q4_coef)
  expect_equal(structured$covariance_mode, "unstructured")
  expect_equal(structured$block_ids, rep(1L, 4L))
  expect_equal(
    structured_row$endpoint_member_set,
    paste(q4_members, collapse = "+")
  )
  expect_equal(structured_row$endpoint_member_count, 4L)
  expect_named(fit$sdpars$mu, sd_names)
  expect_equal(sum(names(fit$opt$par) == "theta_phylo"), 6L)
  expect_equal(length(fit$corpars$phylo), 6L)
  expect_equal(nrow(pairs), 6L)
  expect_equal(
    nrow(corpairs(fit, level = "phylogenetic", class = "location-scale")),
    0L
  )
  expect_equal(nrow(cor_targets), 6L)
  expect_equal(cor_targets$tmb_parameter, rep("theta_phylo", 6L))
  expect_equal(cor_targets$target_type, rep("derived", 6L))
  expect_false(any(cor_targets$profile_ready))
  fixed_mu1 <- as.vector(fit$model$X$mu1 %*% coef(fit, "mu1"))
  fixed_mu2 <- as.vector(fit$model$X$mu2 %*% coef(fit, "mu2"))
  expect_equal(
    unname(predict(fit, dpar = "mu1", type = "link")),
    fixed_mu1 + drmTMB:::phylo_mu_contribution(fit, dpar = "mu1"),
    tolerance = 1e-8
  )
  expect_equal(
    unname(predict(fit, dpar = "mu2", type = "link")),
    fixed_mu2 + drmTMB:::phylo_mu_contribution(fit, dpar = "mu2"),
    tolerance = 1e-8
  )
})

test_that("bivariate phylogenetic q4 recovers broad simulation targets", {
  # Near-boundary bivariate-Gaussian q4 phylogenetic recovery fit whose q4
  # diagnostic-message classification is not reproducible across BLAS/LAPACK
  # builds (same fragile class as the spatial q4 block; shared check.R q4
  # location-scale path). Skip on CRAN; runs in the full tag-CI matrix + locally.
  skip_on_cran()
  sim <- new_biv_phylo_q4_gaussian_data()
  dat <- sim$data
  tree <- sim$tree

  fit <- suppressWarnings(
    drmTMB(
      bf(
        mu1 = y1 ~ x + phylo(1 | p | species, tree = tree),
        mu2 = y2 ~ x + phylo(1 | p | species, tree = tree),
        sigma1 = ~ z + phylo(1 | p | species, tree = tree),
        sigma2 = ~ z + phylo(1 | p | species, tree = tree),
        rho12 = ~1
      ),
      family = c(gaussian(), gaussian()),
      data = dat,
      control = list(eval.max = 1000, iter.max = 1000)
    )
  )

  phylo_sd <- fit$sdpars$mu[
    c(
      "mu1:phylo(1 | p | species)",
      "mu2:phylo(1 | p | species)",
      "sigma1:phylo(1 | p | species)",
      "sigma2:phylo(1 | p | species)"
    )
  ]
  phylo_pairs <- corpairs(fit, level = "phylogenetic")
  phylo_cor <- fit$corpars$phylo
  diagnostics <- check_drm(fit)
  q4_diagnostic <- diagnostics[
    diagnostics$check == "biv_phylo_q4_covariance",
  ]
  max_gradient <- max(abs(fit$obj$gr(fit$opt$par)))

  expect_lt(max_gradient, 1e-3)
  expect_equal(nrow(phylo_pairs), 6L)
  expect_equal(nrow(q4_diagnostic), 1L)
  expect_equal(
    nrow(diagnostics[diagnostics$check == "biv_phylo_mu_covariance", ]),
    0L
  )
  expect_match(q4_diagnostic$value, "q=4")
  expect_match(q4_diagnostic$value, "max_abs_cor=")
  expect_match(q4_diagnostic$message, "Phylogenetic q4 location-scale")
  expect_lt(max(abs(coef(fit, "mu1") - sim$beta_mu1)), 0.35)
  expect_lt(max(abs(coef(fit, "mu2") - sim$beta_mu2)), 0.35)
  expect_lt(max(abs(coef(fit, "sigma1") - sim$beta_sigma1)), 0.35)
  expect_lt(max(abs(coef(fit, "sigma2") - sim$beta_sigma2)), 0.35)
  expect_lt(abs(unique(rho12(fit)) - sim$rho12), 0.25)
  expect_lt(
    max(abs(log(unname(phylo_sd)) - log(unname(sim$sd_phylo)))),
    log(3)
  )
  expect_gt(
    unname(phylo_cor["cor(mu1:(Intercept),mu2:(Intercept) | p | species)"]),
    0.25
  )
  expect_gt(
    unname(phylo_cor[
      "cor(sigma1:(Intercept),sigma2:(Intercept) | p | species)"
    ]),
    0
  )
})

test_that("ordinary and phylogenetic species intercepts match dense marginal likelihood", {
  tree <- balanced_ultrametric_tree(n_tip = 4L)
  species <- rep(tree$tip.label, each = 4L)
  x <- rep(c(-0.8, -0.2, 0.3, 0.9), times = 4L)
  phylo_signal <- c(sp_1 = -0.35, sp_2 = -0.25, sp_3 = 0.3, sp_4 = 0.45)
  species_signal <- c(sp_1 = 0.25, sp_2 = -0.15, sp_3 = -0.2, sp_4 = 0.1)
  dat <- data.frame(
    y = -0.1 +
      0.4 * x +
      phylo_signal[species] +
      species_signal[species] +
      rep(c(-0.08, 0.02, 0.06, 0.12), times = 4L),
    x = x,
    species = species
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | species) + phylo(1 | species, tree = tree), sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  X_mu <- stats::model.matrix(~x, dat)
  mu <- as.vector(X_mu %*% coef(fit, "mu"))
  A_tip <- drmTMB:::drm_phylo_tip_covariance(tree)
  A_obs <- A_tip[dat$species, dat$species]
  species_obs <- outer(dat$species, dat$species, `==`) + 0
  sd_species <- unname(fit$sdpars$mu["(1 | species)"])
  sd_phylo <- unname(fit$sdpars$mu["phylo(1 | species)"])
  covariance <- stats::sigma(fit)[[1L]]^2 *
    diag(nrow(dat)) +
    sd_species^2 * species_obs +
    sd_phylo^2 * A_obs

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    fit$opt$objective,
    dense_gaussian_nll(dat$y, mu, covariance),
    tolerance = 1e-4
  )
})

test_that("phylogenetic meta-analysis objective matches dense known-V likelihood", {
  tree <- balanced_ultrametric_tree(n_tip = 4L)
  species <- rep(tree$tip.label, each = 3L)
  x <- rep(c(-0.6, 0.0, 0.6), times = 4L)
  vi <- rep(c(0.02, 0.03, 0.04), times = 4L)
  phylo_signal <- c(sp_1 = -0.25, sp_2 = -0.2, sp_3 = 0.25, sp_4 = 0.35)
  dat <- data.frame(
    yi = 0.2 +
      0.5 * x +
      phylo_signal[species] +
      rep(c(-0.04, 0.01, 0.05), times = 4L),
    x = x,
    vi = vi,
    species = species
  )

  fit <- drmTMB(
    bf(
      yi ~ x + meta_V(V = vi) + phylo(1 | species, tree = tree),
      sigma ~ 1
    ),
    family = gaussian(),
    data = dat
  )

  X_mu <- stats::model.matrix(~x, dat)
  mu <- as.vector(X_mu %*% coef(fit, "mu"))
  A_tip <- drmTMB:::drm_phylo_tip_covariance(tree)
  A_obs <- A_tip[dat$species, dat$species]
  covariance <- diag(dat$vi + stats::sigma(fit)[[1L]]^2) +
    unname(fit$sdpars$mu)^2 * A_obs

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    fit$opt$objective,
    dense_gaussian_nll(dat$yi, mu, covariance),
    tolerance = 1e-4
  )
})

test_that("phylogenetic meta-analysis accepts dense known V", {
  tree <- balanced_ultrametric_tree(n_tip = 4L)
  species <- rep(tree$tip.label, each = 3L)
  x <- rep(c(-0.5, 0.1, 0.7), times = 4L)
  n <- length(x)
  V <- 0.012 * outer(seq_len(n), seq_len(n), function(i, j) 0.45^abs(i - j))
  diag(V) <- diag(V) + 0.01
  phylo_signal <- c(sp_1 = -0.28, sp_2 = -0.12, sp_3 = 0.18, sp_4 = 0.32)
  dat <- data.frame(
    yi = -0.1 +
      0.45 * x +
      phylo_signal[species] +
      rep(c(-0.03, 0.02, 0.04), times = 4L),
    x = x,
    species = species
  )

  fit <- drmTMB(
    bf(
      yi ~ x + meta_V(V = V) + phylo(1 | species, tree = tree),
      sigma ~ 1
    ),
    family = gaussian(),
    data = dat
  )

  X_mu <- stats::model.matrix(~x, dat)
  mu <- as.vector(X_mu %*% coef(fit, "mu"))
  A_tip <- drmTMB:::drm_phylo_tip_covariance(tree)
  A_obs <- A_tip[dat$species, dat$species]
  covariance <- V +
    stats::sigma(fit)[[1L]]^2 * diag(n) +
    unname(fit$sdpars$mu)^2 * A_obs

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$model$V_known_type, "matrix")
  expect_equal(fit$model$V_known, V)
  expect_equal(
    fit$opt$objective,
    dense_gaussian_nll(dat$yi, mu, covariance),
    tolerance = 1e-4
  )
})

test_that("phylogenetic meta-analysis composes dense V and study intercepts", {
  tree <- balanced_ultrametric_tree(n_tip = 4L)
  species <- rep(tree$tip.label, each = 3L)
  study <- factor(rep(seq_len(6L), each = 2L))
  x <- rep(c(-0.4, 0.2, 0.8), times = 4L)
  n <- length(x)
  V <- 0.01 * outer(seq_len(n), seq_len(n), function(i, j) 0.35^abs(i - j))
  diag(V) <- diag(V) + 0.015
  phylo_signal <- c(sp_1 = -0.22, sp_2 = -0.1, sp_3 = 0.14, sp_4 = 0.28)
  study_signal <- c(-0.08, 0.06, -0.03, 0.04, -0.02, 0.05)
  dat <- data.frame(
    yi = 0.15 +
      0.35 * x +
      phylo_signal[species] +
      study_signal[study] +
      rep(c(-0.02, 0.03, 0.04), times = 4L),
    x = x,
    species = species,
    study = study
  )

  fit <- drmTMB(
    bf(
      yi ~ x +
        (1 | study) +
        meta_V(V = V) +
        phylo(1 | species, tree = tree),
      sigma ~ 1
    ),
    family = gaussian(),
    data = dat
  )

  X_mu <- stats::model.matrix(~x, dat)
  mu <- as.vector(X_mu %*% coef(fit, "mu"))
  A_tip <- drmTMB:::drm_phylo_tip_covariance(tree)
  A_obs <- A_tip[dat$species, dat$species]
  study_obs <- outer(dat$study, dat$study, `==`) + 0
  covariance <- V +
    stats::sigma(fit)[[1L]]^2 * diag(n) +
    unname(fit$sdpars$mu["(1 | study)"])^2 * study_obs +
    unname(fit$sdpars$mu["phylo(1 | species)"])^2 * A_obs

  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$model$V_known_type, "matrix")
  expect_equal(
    fit$opt$objective,
    dense_gaussian_nll(dat$yi, mu, covariance),
    tolerance = 1e-4
  )
})

test_that("conditional predictions include phylogenetic mu effects", {
  sim <- new_phylo_gaussian_data(seed = 20260548)
  dat <- sim$data
  tree <- sim$tree

  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    family = gaussian(),
    data = dat
  )
  fixed_mu <- as.vector(stats::model.matrix(~x, dat) %*% coef(fit, "mu"))
  phylo_mu <- fit$random_effects$phylo_mu$values[
    fit$model$structured$phylo_mu$observation_node_index
  ]

  expect_equal(
    predict(fit, dpar = "mu"),
    fixed_mu + unname(phylo_mu),
    tolerance = 1e-10
  )
  expect_equal(
    predict(fit, newdata = data.frame(x = c(-1, 1)), dpar = "mu"),
    as.vector(
      stats::model.matrix(~x, data.frame(x = c(-1, 1))) %*% coef(fit, "mu")
    ),
    tolerance = 1e-10
  )
})

test_that("phylogenetic mu terms participate in missingness and validation", {
  sim <- new_phylo_gaussian_data(seed = 20260549, n_tip = 8L, n_each = 5L)
  dat <- sim$data
  tree <- sim$tree
  dat$z <- stats::rnorm(nrow(dat))
  dat$species[[1L]] <- NA_character_
  dat$y[[2L]] <- NA_real_

  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  expect_equal(fit$nobs, nrow(dat) - 2L)
  expect_error(
    drmTMB(
      bf(y ~ x + phylo(1 | species, tree = missing_tree), sigma ~ 1),
      family = gaussian(),
      data = sim$data
    ),
    "Could not find phylogeny object"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ x + phylo(1 + x | species, tree = tree),
        sd_phylo(species) ~ x
      ),
      family = gaussian(),
      data = sim$data
    ),
    "scale formulas with structured slopes"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + phylo(1 + x + z | species, tree = tree), sigma ~ 1),
      family = gaussian(),
      data = dat
    ),
    "one-slope structured terms"
  )
  expect_error(
    drmTMB(
      bf(y ~ x + phylo(1 + x | p | species, tree = tree), sigma ~ 1),
      family = gaussian(),
      data = dat
    ),
    "all-four bivariate Gaussian block"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ phylo(1 + x + z | species, tree = tree)),
      family = gaussian(),
      data = dat
    ),
    "reserves only intercept and one-slope structured terms"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ x + phylo(1 + x | species, tree = tree),
        sigma ~ phylo(1 | species, tree = tree)
      ),
      family = gaussian(),
      data = dat
    ),
    "matching intercept-only or one-slope structured terms"
  )
})

test_that("Gaussian supports phylogenetic residual-scale structured effects", {
  sim <- new_phylo_location_scale_gaussian_data()
  tree <- sim$tree

  fit <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sigma ~ phylo(1 | species, tree = tree)
    ),
    family = gaussian(),
    data = sim$data,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 500, iter.max = 500)
    )
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    drmTMB:::phylo_mu_dpars(fit$model$structured$phylo_mu),
    c("mu", "sigma")
  )
  expect_named(fit$sdpars$mu, "mu:phylo(1 | species)")
  expect_named(fit$sdpars$sigma, "sigma:phylo(1 | species)")
  expect_true(all(unname(fit$sdpars$mu) > 0))
  expect_true(all(unname(fit$sdpars$sigma) > 0))
  expect_named(
    fit$corpars$phylo,
    "cor(mu:(Intercept),sigma:(Intercept) | phylo | species)"
  )
  expect_lt(abs(unname(fit$corpars$phylo)), 1)

  fixed_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  conditional_sigma <- predict(fit, dpar = "sigma", type = "link")
  expect_equal(
    unname(conditional_sigma),
    fixed_sigma + drmTMB:::phylo_mu_contribution(fit, dpar = "sigma"),
    tolerance = 1e-8
  )

  targets <- profile_targets(fit)
  matched_target_names <- c(
    "sd:mu:mu:phylo(1 | species)",
    "sd:sigma:sigma:phylo(1 | species)",
    "cor:phylo:cor(mu:(Intercept),sigma:(Intercept) | phylo | species)"
  )
  matched_targets <- targets[
    match(matched_target_names, targets$parm),
    ,
    drop = FALSE
  ]
  expect_equal(matched_targets$parm, matched_target_names)
  expect_equal(matched_targets$target_type, rep("direct", 3L))
  expect_equal(matched_targets$profile_ready, rep(TRUE, 3L))
  expect_equal(matched_targets$profile_note, rep("ready", 3L))
  pair <- corpairs(fit, level = "phylogenetic")
  expect_equal(pair$class, "mean-scale")
  expect_equal(pair$estimate, unname(fit$corpars$phylo))
})

test_that("matched univariate phylogenetic location-scale terms reject mismatches early", {
  sim <- new_phylo_location_scale_gaussian_data(n_tip = 4L, n_each = 4L)
  tree <- sim$tree
  dat <- transform(sim$data, species2 = species)
  tree2 <- tree
  tree2$tip.label <- rev(tree2$tip.label)

  expect_error(
    drmTMB(
      bf(
        y ~ x + phylo(1 | species, tree = tree),
        sigma ~ phylo(1 | species2, tree = tree)
      ),
      family = gaussian(),
      data = dat
    ),
    "same structured source"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ x + phylo(1 | species, tree = tree),
        sigma ~ phylo(1 | species, tree = tree2)
      ),
      family = gaussian(),
      data = sim$data
    ),
    "same structured source"
  )
  expect_error(
    drmTMB(
      bf(
        y ~ x + phylo(1 | p | species, tree = tree),
        sigma ~ phylo(1 | q | species, tree = tree)
      ),
      family = gaussian(),
      data = sim$data
    ),
    "same covariance-block label"
  )
})

test_that("native ML univariate phylo bootstrap records refit accounting", {
  skip_on_cran()

  sim_mu <- new_phylo_gaussian_data(
    seed = 20260623,
    n_tip = 8L,
    n_each = 8L,
    sd_phylo = 0.55,
    sigma = 0.15
  )
  tree_mu <- sim_mu$tree
  fit_mu <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree_mu), sigma ~ 1),
    family = gaussian(),
    data = sim_mu$data,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 180, iter.max = 180)
    )
  )

  ci_mu <- confint(
    fit_mu,
    parm = "sd:mu:phylo(1 | species)",
    method = "bootstrap",
    R = 2,
    seed = 20260624,
    trace = FALSE,
    refit_control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 160, iter.max = 160)
    )
  )
  diag_mu <- attr(ci_mu, "bootstrap.diagnostics")

  expect_equal(fit_mu$opt$convergence, 0)
  expect_equal(ci_mu$conf.status, "bootstrap")
  expect_equal(ci_mu$bootstrap.n, 2L)
  expect_equal(ci_mu$bootstrap.failed, 0L)
  expect_equal(nrow(diag_mu), 2L)
  expect_equal(diag_mu$refit_status, rep("ok", 2L))
  expect_equal(diag_mu$target_available, rep(TRUE, 2L))
  expect_equal(diag_mu$draw_used, rep(TRUE, 2L))

  sim_sigma <- new_phylo_location_scale_gaussian_data(
    seed = 20260625,
    n_tip = 8L,
    n_each = 8L
  )
  tree_sigma <- sim_sigma$tree
  fit_sigma <- drmTMB(
    bf(y ~ x, sigma ~ phylo(1 | species, tree = tree_sigma)),
    family = gaussian(),
    data = sim_sigma$data,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 180, iter.max = 180)
    )
  )

  ci_sigma <- confint(
    fit_sigma,
    parm = "sd:sigma:phylo(1 | species)",
    method = "bootstrap",
    R = 2,
    seed = 20260626,
    trace = FALSE,
    refit_control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 160, iter.max = 160)
    )
  )
  diag_sigma <- attr(ci_sigma, "bootstrap.diagnostics")

  expect_equal(fit_sigma$opt$convergence, 0)
  expect_equal(ci_sigma$conf.status, "bootstrap")
  expect_equal(ci_sigma$bootstrap.n, 2L)
  expect_equal(ci_sigma$bootstrap.failed, 0L)
  expect_equal(nrow(diag_sigma), 2L)
  expect_equal(diag_sigma$refit_status, rep("ok", 2L))
  expect_equal(diag_sigma$target_available, rep(TRUE, 2L))
  expect_equal(diag_sigma$draw_used, rep(TRUE, 2L))
})

test_that("sigma-only phylogenetic ML recovers broad scale signal", {
  sim <- new_sigma_only_phylo_gaussian_data()
  tree <- sim$tree

  fit <- drmTMB(
    bf(y ~ x, sigma ~ phylo(1 | species, tree = tree)),
    family = gaussian(),
    data = sim$data,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 500, iter.max = 500)
    )
  )

  expect_equal(fit$opt$convergence, 0)
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.25)
  expect_lt(
    abs(log(unname(fit$sdpars$sigma[["phylo(1 | species)"]]) / sim$sd_phylo)),
    log(2)
  )
  expect_lt(
    abs(coef(fit, "sigma")[["(Intercept)"]] - sim$beta_sigma[[1L]]),
    0.35
  )
})

test_that("matched phylogenetic location-scale ML recovers broad native balance signal", {
  sim <- new_phylo_location_scale_gaussian_data(
    seed = 20260628,
    n_tip = 8L,
    n_each = 18L,
    sd_phylo = c(mu = 0.55, sigma = 0.35),
    rho_phylo = 0.35
  )
  tree <- sim$tree

  fit <- drmTMB(
    bf(
      y ~ x + phylo(1 | species, tree = tree),
      sigma ~ phylo(1 | species, tree = tree)
    ),
    family = gaussian(),
    data = sim$data,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 700, iter.max = 700)
    )
  )

  expect_equal(fit$opt$convergence, 0)
  expect_lt(max(abs(coef(fit, "mu") - sim$beta_mu)), 0.25)
  expect_lt(
    max(abs(log(unname(c(fit$sdpars$mu, fit$sdpars$sigma)) / sim$sd_phylo))),
    log(3)
  )
  expect_gt(unname(fit$corpars$phylo), 0)
})

test_that("Gaussian supports sigma-only phylogenetic residual-scale structured effects", {
  sim <- new_phylo_location_scale_gaussian_data(seed = 20260615)
  tree <- sim$tree

  fit <- drmTMB(
    bf(
      y ~ x,
      sigma ~ phylo(1 | species, tree = tree)
    ),
    family = gaussian(),
    data = sim$data,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 500, iter.max = 500)
    )
  )

  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    drmTMB:::phylo_mu_dpars(fit$model$structured$phylo_mu),
    "sigma"
  )
  expect_equal(fit$model$structured$phylo_mu$q, 1L)
  expect_null(fit$sdpars$mu)
  expect_named(fit$sdpars$sigma, "phylo(1 | species)")
  expect_true(all(unname(fit$sdpars$sigma) > 0))
  expect_equal(fit$corpars, list())

  fixed_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  conditional_sigma <- predict(fit, dpar = "sigma", type = "link")
  expect_equal(
    unname(conditional_sigma),
    fixed_sigma + drmTMB:::phylo_mu_contribution(fit, dpar = "sigma"),
    tolerance = 1e-8
  )

  targets <- profile_targets(fit)
  sigma_target <- targets[
    targets$parm == "sd:sigma:phylo(1 | species)",
    ,
    drop = FALSE
  ]
  expect_true(is.finite(as.numeric(stats::logLik(fit))))
  expect_equal(nrow(sigma_target), 1L)
  expect_equal(sigma_target$target_type, "direct")
  expect_true(sigma_target$profile_ready)
  expect_equal(sigma_target$profile_note, "ready")
})

test_that("Gaussian supports sigma-only one-slope phylogenetic residual-scale fields", {
  sim <- new_sigma_only_phylo_gaussian_slope_data()
  tree <- sim$tree

  fit <- drmTMB(
    bf(
      y ~ x,
      sigma ~ phylo(1 + x | species, tree = tree)
    ),
    family = gaussian(),
    data = sim$data,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 600, iter.max = 600)
    )
  )

  sd_names <- c("phylo(1 | species)", "phylo(0 + x | species)")
  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    drmTMB:::phylo_mu_dpars(fit$model$structured$phylo_mu),
    "sigma"
  )
  expect_equal(fit$model$structured$phylo_mu$q, 2L)
  expect_equal(
    fit$model$structured$phylo_mu$coef_names,
    c("(Intercept)", "x")
  )
  expect_null(fit$sdpars$mu)
  expect_named(fit$sdpars$sigma, sd_names)
  expect_true(all(unname(fit$sdpars$sigma[sd_names]) > 0))
  expect_equal(fit$corpars, list())

  structured_re <- ranef(fit, "phylo_mu")
  expect_equal(structured_re, fit$random_effects$phylo_mu)
  expect_named(structured_re$terms, sd_names)
  expect_length(
    structured_re$values,
    2L * fit$model$structured$phylo_mu$n_re
  )

  fixed_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  conditional_sigma <- predict(fit, dpar = "sigma", type = "link")
  expect_equal(
    unname(conditional_sigma),
    fixed_sigma + drmTMB:::phylo_mu_contribution(fit, dpar = "sigma"),
    tolerance = 1e-8
  )

  targets <- profile_targets(fit)
  sd_targets <- targets[
    targets$parm %in% paste0("sd:sigma:", sd_names),
  ]
  sd_targets <- sd_targets[
    match(paste0("sd:sigma:", sd_names), sd_targets$parm),
  ]
  expect_equal(sd_targets$parm, paste0("sd:sigma:", sd_names))
  expect_equal(sd_targets$tmb_parameter, rep("log_sd_phylo", 2L))
  expect_equal(sd_targets$index, 1:2)
  expect_equal(sd_targets$target_type, rep("direct", 2L))
  expect_true(all(sd_targets$profile_ready))
  expect_true(is.finite(as.numeric(stats::logLik(fit))))
})

test_that("Gaussian supports matched one-slope phylogenetic location-scale fields", {
  sim <- new_sigma_only_phylo_gaussian_slope_data(
    seed = 20260644,
    n_tip = 16L,
    n_each = 8L
  )
  tree <- sim$tree

  fit <- drmTMB(
    bf(
      y ~ x + phylo(1 + x | species, tree = tree),
      sigma ~ phylo(1 + x | species, tree = tree)
    ),
    family = gaussian(),
    data = sim$data,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 800, iter.max = 800)
    )
  )

  mu_names <- c("mu:phylo(1 | species)", "mu:phylo(0 + x | species)")
  sigma_names <- c(
    "sigma:phylo(1 | species)",
    "sigma:phylo(0 + x | species)"
  )
  expect_equal(fit$opt$convergence, 0)
  expect_equal(
    drmTMB:::phylo_mu_dpars(fit$model$structured$phylo_mu),
    c("mu", "mu", "sigma", "sigma")
  )
  expect_equal(fit$model$structured$phylo_mu$q, 4L)
  expect_equal(
    fit$model$structured$phylo_mu$coef_names,
    c("(Intercept)", "x", "(Intercept)", "x")
  )
  expect_named(fit$sdpars$mu, mu_names)
  expect_named(fit$sdpars$sigma, sigma_names)
  expect_equal(fit$corpars, list())

  structured <- structured_effects(fit)
  expect_equal(
    structured$endpoint_member_set,
    "mu:(Intercept)+mu:x+sigma:(Intercept)+sigma:x"
  )

  phylo_re <- ranef(fit, "phylo_mu")
  expect_named(phylo_re$terms, c(mu_names, sigma_names))
  expect_length(
    phylo_re$values,
    4L * fit$model$structured$phylo_mu$n_re
  )

  fixed_sigma <- as.vector(fit$model$X$sigma %*% coef(fit, "sigma"))
  conditional_sigma <- predict(fit, dpar = "sigma", type = "link")
  expect_equal(
    unname(conditional_sigma),
    fixed_sigma + drmTMB:::phylo_mu_contribution(fit, dpar = "sigma"),
    tolerance = 1e-8
  )

  targets <- profile_targets(fit)
  target_names <- c(
    paste0("sd:mu:", mu_names),
    paste0("sd:sigma:", sigma_names)
  )
  matched_targets <- targets[match(target_names, targets$parm), , drop = FALSE]
  expect_equal(matched_targets$parm, target_names)
  expect_equal(matched_targets$tmb_parameter, rep("log_sd_phylo", 4L))
  expect_equal(matched_targets$index, 1:4)
  expect_equal(matched_targets$target_type, rep("direct", 4L))
  expect_true(all(matched_targets$profile_ready))
  expect_true(is.finite(as.numeric(stats::logLik(fit))))
})

test_that("Gaussian mu supports one-slope phylogenetic fields", {
  sim <- new_phylo_gaussian_slope_data()
  tree <- sim$tree

  fit <- drmTMB(
    bf(y ~ x + phylo(1 + x | species, tree = tree), sigma ~ 1),
    family = gaussian(),
    data = sim$data
  )

  sd_names <- c("phylo(1 | species)", "phylo(0 + x | species)")
  expect_equal(fit$opt$convergence, 0)
  expect_equal(fit$model$structured$phylo_mu$type, "phylo")
  expect_equal(fit$model$structured$phylo_mu$q, 2L)
  expect_equal(
    fit$model$structured$phylo_mu$coef_names,
    c("(Intercept)", "x")
  )
  expect_named(fit$sdpars$mu, sd_names)
  expect_true(all(is.finite(fit$sdpars$mu[sd_names])))
  expect_true(all(unname(fit$sdpars$mu[sd_names]) > 0.02))
  expect_equal(fit$corpars, list())

  phylo_re <- ranef(fit, "phylo_mu")
  expect_equal(phylo_re, fit$random_effects$phylo_mu)
  expect_named(phylo_re$terms, sd_names)
  expect_length(phylo_re$values, 2L * fit$model$structured$phylo_mu$n_re)

  targets <- profile_targets(fit)
  phylo_targets <- targets[
    targets$parm %in% paste0("sd:mu:", sd_names),
  ]
  phylo_targets <- phylo_targets[
    match(paste0("sd:mu:", sd_names), phylo_targets$parm),
  ]
  expect_equal(phylo_targets$parm, paste0("sd:mu:", sd_names))
  expect_equal(phylo_targets$tmb_parameter, rep("log_sd_phylo", 2L))
  expect_equal(phylo_targets$index, 1:2)
  expect_equal(phylo_targets$target_type, rep("direct", 2L))
  expect_true(all(phylo_targets$profile_ready))

  conditional_mu <- predict(fit, dpar = "mu", type = "link")
  fixed_mu <- as.vector(fit$model$X$mu %*% fit$coefficients$mu)
  expect_equal(
    unname(conditional_mu),
    fixed_mu + drmTMB:::phylo_mu_contribution(fit),
    tolerance = 1e-8
  )

  chk <- check_drm(fit)
  phylo_check <- chk[chk$check == "phylo_mu_diagnostics", ]
  expect_equal(nrow(phylo_check), 1L)
  expect_match(phylo_check$value, "n_coef=2", fixed = TRUE)
  expect_match(phylo_check$value, "min_phylo_sd=", fixed = TRUE)
  expect_match(phylo_check$value, "min_sd_ratio=", fixed = TRUE)
})
