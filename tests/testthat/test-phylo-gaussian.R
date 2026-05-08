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

new_phylo_gaussian_data <- function(seed = 20260547, n_tip = 16L,
                                    n_each = 8L, sd_phylo = 0.7,
                                    sigma = 0.25) {
  set.seed(seed)
  tree <- balanced_ultrametric_tree(n_tip)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  phylo_effect <- as.vector(t(chol(A)) %*% stats::rnorm(n_tip, sd = sd_phylo))
  names(phylo_effect) <- tree$tip.label
  species <- rep(tree$tip.label, each = n_each)
  x <- stats::rnorm(length(species))
  beta_mu <- c(`(Intercept)` = 0.4, x = -0.35)
  y <- beta_mu[[1L]] + beta_mu[[2L]] * x +
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

dense_gaussian_nll <- function(y, mu, covariance) {
  chol_covariance <- chol(covariance)
  residual <- y - mu
  standardized <- backsolve(chol_covariance, residual, transpose = TRUE)
  0.5 * (
    length(y) * log(2 * pi) +
      2 * sum(log(diag(chol_covariance))) +
      sum(standardized^2)
  )
}

dense_phylo_gaussian_nll <- function(y, mu, sigma, sd_phylo, A) {
  dense_gaussian_nll(
    y = y,
    mu = mu,
    covariance = sigma^2 * diag(length(y)) + sd_phylo^2 * A
  )
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
  expect_lt(max(abs(unname(coef(fit, "mu")) - unname(sim$beta_mu))), 0.35)
  expect_lt(abs(unname(fit$sdpars$mu) - sim$sd_phylo), 0.45)
  expect_lt(abs(stats::sigma(fit)[[1L]] - sim$sigma), 0.10)
})

test_that("fitted phylogenetic mu objective matches dense marginal likelihood", {
  tree <- balanced_ultrametric_tree(n_tip = 4L)
  species <- rep(tree$tip.label, each = 3L)
  x <- rep(c(-0.7, 0.1, 0.8), times = 4L)
  phylo_signal <- c(sp_1 = -0.45, sp_2 = -0.2, sp_3 = 0.25, sp_4 = 0.55)
  dat <- data.frame(
    y = 0.3 + 0.6 * x + phylo_signal[species] +
      rep(c(-0.1, 0.05, 0.12), times = 4L),
    x = x,
    species = species
  )

  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  X_mu <- stats::model.matrix(~ x, dat)
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

test_that("ordinary and phylogenetic species intercepts match dense marginal likelihood", {
  tree <- balanced_ultrametric_tree(n_tip = 4L)
  species <- rep(tree$tip.label, each = 4L)
  x <- rep(c(-0.8, -0.2, 0.3, 0.9), times = 4L)
  phylo_signal <- c(sp_1 = -0.35, sp_2 = -0.25, sp_3 = 0.3, sp_4 = 0.45)
  species_signal <- c(sp_1 = 0.25, sp_2 = -0.15, sp_3 = -0.2, sp_4 = 0.1)
  dat <- data.frame(
    y = -0.1 + 0.4 * x + phylo_signal[species] + species_signal[species] +
      rep(c(-0.08, 0.02, 0.06, 0.12), times = 4L),
    x = x,
    species = species
  )

  fit <- drmTMB(
    bf(y ~ x + (1 | species) + phylo(1 | species, tree = tree), sigma ~ 1),
    family = gaussian(),
    data = dat
  )

  X_mu <- stats::model.matrix(~ x, dat)
  mu <- as.vector(X_mu %*% coef(fit, "mu"))
  A_tip <- drmTMB:::drm_phylo_tip_covariance(tree)
  A_obs <- A_tip[dat$species, dat$species]
  species_obs <- outer(dat$species, dat$species, `==`) + 0
  sd_species <- unname(fit$sdpars$mu["(1 | species)"])
  sd_phylo <- unname(fit$sdpars$mu["phylo(1 | species)"])
  covariance <- stats::sigma(fit)[[1L]]^2 * diag(nrow(dat)) +
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
    yi = 0.2 + 0.5 * x + phylo_signal[species] +
      rep(c(-0.04, 0.01, 0.05), times = 4L),
    x = x,
    vi = vi,
    species = species
  )

  fit <- drmTMB(
    bf(
      yi ~ x + meta_known_V(V = vi) + phylo(1 | species, tree = tree),
      sigma ~ 1
    ),
    family = gaussian(),
    data = dat
  )

  X_mu <- stats::model.matrix(~ x, dat)
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
    yi = -0.1 + 0.45 * x + phylo_signal[species] +
      rep(c(-0.03, 0.02, 0.04), times = 4L),
    x = x,
    species = species
  )

  fit <- drmTMB(
    bf(
      yi ~ x + meta_known_V(V = V) + phylo(1 | species, tree = tree),
      sigma ~ 1
    ),
    family = gaussian(),
    data = dat
  )

  X_mu <- stats::model.matrix(~ x, dat)
  mu <- as.vector(X_mu %*% coef(fit, "mu"))
  A_tip <- drmTMB:::drm_phylo_tip_covariance(tree)
  A_obs <- A_tip[dat$species, dat$species]
  covariance <- V + stats::sigma(fit)[[1L]]^2 * diag(n) +
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
    yi = 0.15 + 0.35 * x + phylo_signal[species] + study_signal[study] +
      rep(c(-0.02, 0.03, 0.04), times = 4L),
    x = x,
    species = species,
    study = study
  )

  fit <- drmTMB(
    bf(
      yi ~ x + (1 | study) + meta_known_V(V = V) +
        phylo(1 | species, tree = tree),
      sigma ~ 1
    ),
    family = gaussian(),
    data = dat
  )

  X_mu <- stats::model.matrix(~ x, dat)
  mu <- as.vector(X_mu %*% coef(fit, "mu"))
  A_tip <- drmTMB:::drm_phylo_tip_covariance(tree)
  A_obs <- A_tip[dat$species, dat$species]
  study_obs <- outer(dat$study, dat$study, `==`) + 0
  covariance <- V + stats::sigma(fit)[[1L]]^2 * diag(n) +
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
  fixed_mu <- as.vector(stats::model.matrix(~ x, dat) %*% coef(fit, "mu"))
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
    as.vector(stats::model.matrix(~ x, data.frame(x = c(-1, 1))) %*% coef(fit, "mu")),
    tolerance = 1e-10
  )
})

test_that("phylogenetic mu terms participate in missingness and validation", {
  sim <- new_phylo_gaussian_data(seed = 20260549, n_tip = 8L, n_each = 5L)
  dat <- sim$data
  tree <- sim$tree
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
      bf(y ~ x + phylo(1 + x | species, tree = tree), sigma ~ 1),
      family = gaussian(),
      data = sim$data
    ),
    "intercept-only phylogenetic"
  )
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
      bf(y ~ x, sigma ~ phylo(1 | species, tree = tree)),
      family = gaussian(),
      data = sim$data
    ),
    "planned, not implemented"
  )
})
