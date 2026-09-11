test_that("stationary phylogenetic OU covariance matches ape::corMartins", {
  skip_if_not_installed("ape")
  set.seed(2026091103)
  tree <- ape::rcoal(5)
  tree$tip.label <- paste0("sp", seq_len(5))
  decay <- 0.7

  expected <- nlme::corMatrix(
    ape::corMartins(decay, tree), covariate = tree$tip.label
  )
  actual <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = decay)

  expect_equal(actual, expected, tolerance = 1e-12)
})

test_that("stationary phylogenetic OU layout retains the root and every tree edge", {
  skip_if_not_installed("ape")
  set.seed(2026091104)
  tree <- ape::rcoal(4)
  tree$tip.label <- paste0("sp", seq_len(4))
  layout <- drmTMB:::drm_phylo_ou_augmented_layout(
    tree, species = rep(tree$tip.label, each = 2)
  )

  expect_equal(layout$n_re, length(tree$tip.label) + tree$Nnode)
  expect_equal(length(layout$edge_parent_index0), nrow(tree$edge))
  expect_equal(length(layout$edge_child_index0), nrow(tree$edge))
  expect_equal(length(layout$edge_length), nrow(tree$edge))
  expect_equal(layout$observation_node_index0,
    rep(seq_along(tree$tip.label) - 1L, each = 2)
  )
  expect_true(layout$root_index0 %in% (seq_len(layout$n_re) - 1L))
})

test_that("Gaussian phylogenetic OU fits a native stationary tree provider", {
  skip_if_not_installed("ape")
  set.seed(2026091105)
  tree <- ape::rcoal(5)
  tree$tip.label <- paste0("sp", seq_len(5))
  species <- rep(tree$tip.label, each = 5)
  x <- rep(c(-0.5, 0.5), length.out = length(species))
  y <- 0.2 + 0.4 * x + stats::rnorm(length(species), sd = 0.35)
  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree, model = "ou"), sigma ~ 1),
    data = data.frame(y, x, species), family = gaussian()
  )

  expect_true(is.finite(as.numeric(logLik(fit))))
  expect_true("log_decay_phylo" %in% names(fit$tmb_state$opt.par))
  expect_true(is.finite(unname(fit$tmb_state$opt.par[["log_decay_phylo"]])))
})

test_that("native OU-tree marginal likelihood matches the independent dense covariance", {
  skip_if_not_installed("ape")
  set.seed(2026091106)
  tree <- ape::rcoal(5)
  tree$tip.label <- paste0("sp", seq_len(5))
  species <- rep(tree$tip.label, each = 5)
  x <- rep(c(-0.5, 0.5), length.out = length(species))
  y <- -0.1 + 0.5 * x + stats::rnorm(length(species), sd = 0.3)
  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree, model = "ou"), sigma ~ 1),
    data = data.frame(y, x, species), family = gaussian()
  )
  decay <- exp(unname(fit$tmb_state$opt.par[["log_decay_phylo"]]))
  sd_phylo <- unname(fit$sdpars$mu[["phylo(1 | species)"]])
  sigma <- exp(unname(fit$par$sigma[["(Intercept)"]]))
  tip_correlation <- drmTMB:::drm_phylo_ou_tip_covariance(
    tree, species = species, decay = decay
  )
  observation_correlation <- tip_correlation[
    match(species, rownames(tip_correlation)),
    match(species, colnames(tip_correlation))
  ]
  covariance <- sd_phylo^2 * observation_correlation +
    diag(sigma^2, length(y))
  residual <- y - as.vector(cbind(`(Intercept)` = 1, x = x) %*% fit$par$mu)
  dense_nll <- 0.5 * (
    length(y) * log(2 * pi) +
      as.numeric(determinant(covariance, logarithm = TRUE)$modulus) +
      drop(crossprod(residual, solve(covariance, residual)))
  )

  expect_equal(-as.numeric(logLik(fit)), dense_nll, tolerance = 1e-7)
})

phylo_ou_dense_nll_at <- function(fit, par, tree) {
  parameter_names <- names(par)
  beta <- unname(par[parameter_names == "beta_mu"])
  sigma <- exp(unname(par[match("beta_sigma", parameter_names)]))
  sd_phylo <- exp(unname(par[match("log_sd_phylo", parameter_names)]))
  decay <- exp(unname(par[match("log_decay_phylo", parameter_names)]))
  phylo <- fit$model$structured$phylo_mu
  species <- as.character(fit$data[[phylo$group]])
  tip_correlation <- drmTMB:::drm_phylo_ou_tip_covariance(
    tree, species = species, decay = decay
  )
  observation_correlation <- tip_correlation[
    match(species, rownames(tip_correlation)),
    match(species, colnames(tip_correlation))
  ]
  covariance <- sd_phylo^2 * observation_correlation +
    diag(sigma^2, length(species))
  root <- chol(covariance)
  residual <- fit$model$y - as.vector(fit$model$X$mu %*% beta)
  0.5 * (
    length(species) * log(2 * pi) +
      2 * sum(log(diag(root))) +
      sum(forwardsolve(t(root), residual)^2)
  )
}

test_that("OU-tree score and observed Hessian match the dense covariance oracle", {
  skip_if_not_installed("ape")
  skip_if_not_installed("numDeriv")
  set.seed(2026091107)
  tree <- ape::rcoal(15)
  tree$tip.label <- paste0("sp", seq_len(15))
  species <- rep(tree$tip.label, each = 8)
  x <- rep(c(-0.75, -0.25, 0.25, 0.75, 0, 0.5, -0.5, 0.1),
    length.out = length(species)
  )
  truth_correlation <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = 0.8)
  phylo_effect <- as.vector(t(chol(truth_correlation)) %*%
    stats::rnorm(length(tree$tip.label))) * 0.8
  y <- 0.15 + 0.45 * x + phylo_effect[match(species, tree$tip.label)] +
    stats::rnorm(length(species), sd = 0.25)
  fit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree, model = "ou"), sigma ~ 1),
    data = data.frame(y, x, species), family = gaussian()
  )
  expect_true(isTRUE(fit$sdr$pdHess))
  objective <- function(par) phylo_ou_dense_nll_at(fit, par, tree)
  opt_par <- fit$opt$par
  score <- numDeriv::grad(objective, opt_par, method.args = list(eps = 1e-6))
  hessian_1 <- numDeriv::hessian(objective, opt_par, method.args = list(eps = 1e-4))
  hessian_2 <- numDeriv::hessian(objective, opt_par, method.args = list(eps = 1e-5))
  observed_hessian <- solve(fit$sdr$cov.fixed)

  expect_equal(unname(fit$obj$gr(opt_par)), score, tolerance = 1e-5)
  expect_equal(hessian_1, hessian_2, tolerance = 1e-4)
  expect_equal(unname(observed_hessian), unname(hessian_1), tolerance = 1e-4)
})

phylo_ou_markov_nll <- function(layout, state, sd, decay,
                                include_root = TRUE,
                                edge_length = layout$edge_length,
                                transition_variance = c("stationary", "wrong")) {
  transition_variance <- match.arg(transition_variance)
  out <- 0
  if (include_root) {
    out <- out - stats::dnorm(state[[layout$root_index0 + 1L]], 0, sd, log = TRUE)
  }
  for (edge_id in seq_along(edge_length)) {
    rho <- exp(-decay * edge_length[[edge_id]])
    variance_factor <- if (identical(transition_variance, "stationary")) {
      1 - rho^2
    } else {
      1 - rho
    }
    parent <- state[[layout$edge_parent_index0[[edge_id]] + 1L]]
    child <- state[[layout$edge_child_index0[[edge_id]] + 1L]]
    out <- out - stats::dnorm(child, rho * parent, sd * sqrt(variance_factor),
      log = TRUE
    )
  }
  out
}

phylo_ou_all_node_correlation <- function(tree, decay) {
  info <- drmTMB:::validate_phylo_tree(tree)
  edge <- tree$edge
  n_node <- info$n_tip + info$n_node
  parent <- integer(n_node)
  parent[edge[, 2L]] <- edge[, 1L]
  ancestor <- lapply(seq_len(n_node), drmTMB:::phylo_node_ancestors,
    parent = parent
  )
  out <- matrix(0, n_node, n_node)
  for (i in seq_len(n_node)) for (j in seq_len(n_node)) {
    mrca_depth <- max(info$node_depth[intersect(ancestor[[i]], ancestor[[j]])])
    distance <- info$node_depth[[i]] + info$node_depth[[j]] - 2 * mrca_depth
    out[i, j] <- exp(-decay * distance)
  }
  out
}

test_that("OU-tree reductions and mutations expose the intended mechanisms", {
  skip_if_not_installed("ape")
  set.seed(2026091108)
  tree <- ape::rcoal(6)
  tree$tip.label <- paste0("sp", seq_len(6))
  layout <- drmTMB:::drm_phylo_ou_augmented_layout(tree)
  decay <- 0.7
  sd <- 0.65
  state <- stats::rnorm(layout$n_re)
  correlation <- phylo_ou_all_node_correlation(tree, decay)
  covariance <- sd^2 * correlation
  root <- chol(covariance)
  dense_nll <- 0.5 * (
    length(state) * log(2 * pi) + 2 * sum(log(diag(root))) +
      sum(forwardsolve(t(root), state)^2)
  )
  correct <- phylo_ou_markov_nll(layout, state, sd, decay)
  missing_root <- phylo_ou_markov_nll(layout, state, sd, decay,
    include_root = FALSE
  )
  wrong_variance <- phylo_ou_markov_nll(layout, state, sd, decay,
    transition_variance = "wrong"
  )
  compressed <- phylo_ou_markov_nll(layout, state, sd, decay,
    edge_length = rep(mean(layout$edge_length), length(layout$edge_length))
  )
  tip_ou <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = decay)
  tip_bm <- drmTMB:::drm_phylo_tip_covariance(tree)
  large_decay <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = 100)
  small_decay <- drmTMB:::drm_phylo_ou_tip_covariance(tree, decay = 1e-8)
  temporal_kernel <- exp(-decay * abs(outer(seq_len(nrow(tip_ou)),
    seq_len(nrow(tip_ou)), "-"
  )))
  independent_trees <- Matrix::bdiag(tip_ou, tip_ou)
  shared_tree_state <- rbind(cbind(tip_ou, tip_ou), cbind(tip_ou, tip_ou))

  expect_equal(correct, dense_nll, tolerance = 1e-10)
  expect_false(isTRUE(all.equal(missing_root, dense_nll)))
  expect_false(isTRUE(all.equal(wrong_variance, dense_nll)))
  expect_false(isTRUE(all.equal(compressed, dense_nll)))
  expect_false(isTRUE(all.equal(tip_ou, tip_bm)))
  expect_false(isTRUE(all.equal(tip_ou, temporal_kernel)))
  expect_false(isTRUE(all.equal(as.matrix(independent_trees), shared_tree_state)))
  expect_lt(max(large_decay[row(large_decay) != col(large_decay)]), 1e-6)
  expect_equal(unname(small_decay), matrix(1, nrow(small_decay), ncol(small_decay)),
    tolerance = 1e-7
  )
})
