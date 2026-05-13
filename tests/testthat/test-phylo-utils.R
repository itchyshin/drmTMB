tiny_ultrametric_tree <- function() {
  structure(
    list(
      edge = matrix(
        c(
          5,
          4,
          4,
          1,
          4,
          2,
          5,
          3
        ),
        byrow = TRUE,
        ncol = 2
      ),
      edge.length = c(1, 1, 1, 2),
      tip.label = c("sp_a", "sp_b", "sp_c"),
      Nnode = 2L
    ),
    class = "phylo"
  )
}

phylo_prior_tmb_data <- function(precision) {
  dummy_matrix <- matrix(0, nrow = 1, ncol = 1)
  c(
    list(
      model_type = 99L,
      y = numeric(1),
      trials = numeric(1),
      weights = 1,
      offset_mu = numeric(1),
      V_known = numeric(1),
      V_known_matrix = dummy_matrix,
      V_known_type = 0L,
      y1 = numeric(1),
      y2 = numeric(1),
      X_mu = dummy_matrix,
      X_sigma = dummy_matrix,
      X_nu = dummy_matrix,
      X_zi = dummy_matrix,
      X_sd_mu = dummy_matrix,
      has_sd_mu_model = 0L,
      X_mu1 = dummy_matrix,
      X_mu2 = dummy_matrix,
      X_sigma1 = dummy_matrix,
      X_sigma2 = dummy_matrix,
      X_rho12 = dummy_matrix,
      n_mu_re_terms = 0L,
      n_mu_re_cors = 0L,
      mu_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      mu_re_value = dummy_matrix,
      mu_re_term = 0L,
      mu_re_dpar = 0L,
      mu_re_pos = 0L,
      mu_re_cor_id = -1L,
      mu_re_pair_index = -1L,
      mu_re_sd_row = -1L,
      n_sigma_re_terms = 0L,
      n_sigma_re_cors = 0L,
      n_mu_sigma_re_cors = 0L,
      sigma_re_index = matrix(0L, nrow = 1L, ncol = 1L),
      sigma_re_value = dummy_matrix,
      sigma_re_term = 0L,
      sigma_re_dpar = 0L,
      sigma_re_cor_id = -1L,
      sigma_re_pair_index = -1L,
      sigma_re_cross_cor = 0L,
      sigma_re_cross_mu = 0L,
      has_phylo_mu = 0L,
      phylo_mu_node_index = 0L,
      Q_phylo = precision$precision,
      log_det_Q_phylo = precision$log_det_precision
    ),
    drmTMB:::empty_labelled_covariance_block_tmb_data()
  )
}

phylo_prior_tmb_parameters <- function(effect, log_sd) {
  list(
    beta_mu = 0,
    beta_sigma = 0,
    beta_nu = 0,
    beta_zi = 0,
    theta_ord = 0,
    beta_sd_mu = 0,
    beta_mu1 = 0,
    beta_mu2 = 0,
    beta_sigma1 = 0,
    beta_sigma2 = 0,
    beta_rho12 = 0,
    u_mu = 0,
    log_sd_mu = 0,
    eta_cor_mu = 0,
    eta_cor_mu_sigma = 0,
    eta_cor_sigma = 0,
    u_sigma = 0,
    log_sd_sigma = 0,
    u_phylo = unname(effect),
    u_re_cov_probe = 0,
    log_sd_phylo = log_sd
  )
}

dense_zero_mvn_nll <- function(values, covariance) {
  chol_covariance <- chol(covariance)
  standardized <- backsolve(chol_covariance, values, transpose = TRUE)
  0.5 *
    (length(values) *
      log(2 * pi) +
      2 * sum(log(diag(chol_covariance))) +
      sum(standardized^2))
}

test_that("validate_phylo_tree checks ultrametric trees and observed species", {
  tree <- tiny_ultrametric_tree()

  info <- drmTMB:::validate_phylo_tree(
    tree,
    species = c("sp_b", "sp_a", "sp_b")
  )

  expect_equal(info$n_tip, 3L)
  expect_equal(info$n_node, 2L)
  expect_equal(info$root, 5L)
  expect_equal(info$height, 2)
  expect_equal(info$tip_label, c("sp_a", "sp_b", "sp_c"))
  expect_equal(info$species_levels, c("sp_b", "sp_a"))
  expect_equal(info$species_index, c(2L, 1L))
  expect_equal(info$observation_species_index, c(1L, 2L, 1L))
  expect_equal(info$node_depth[1:5], c(2, 2, 2, 1, 0))
})

test_that("drm_phylo_tip_covariance builds a dense Brownian comparator", {
  tree <- tiny_ultrametric_tree()

  expected_correlation <- matrix(
    c(
      1,
      0.5,
      0,
      0.5,
      1,
      0,
      0,
      0,
      1
    ),
    nrow = 3,
    byrow = TRUE,
    dimnames = list(tree$tip.label, tree$tip.label)
  )

  observed_correlation <- drmTMB:::drm_phylo_tip_covariance(tree)
  observed_covariance <- drmTMB:::drm_phylo_tip_covariance(
    tree,
    species = c("sp_c", "sp_a"),
    correlation = FALSE
  )

  expect_equal(observed_correlation, expected_correlation)
  expect_equal(
    observed_covariance,
    matrix(
      c(2, 0, 0, 2),
      nrow = 2,
      dimnames = list(c("sp_c", "sp_a"), c("sp_c", "sp_a"))
    )
  )
})

test_that("drm_phylo_augmented_precision matches the dense Brownian comparator", {
  tree <- tiny_ultrametric_tree()
  precision <- drmTMB:::drm_phylo_augmented_precision(tree)
  raw_precision <- drmTMB:::drm_phylo_augmented_precision(
    tree,
    correlation = FALSE
  )
  expected_raw_q <- matrix(
    c(
      1,
      0,
      0,
      -1,
      0,
      1,
      0,
      -1,
      0,
      0,
      0.5,
      0,
      -1,
      -1,
      0,
      3
    ),
    nrow = 4,
    byrow = TRUE,
    dimnames = list(
      c("sp_a", "sp_b", "sp_c", "node4"),
      c("sp_a", "sp_b", "sp_c", "node4")
    )
  )
  expected_q <- 2 * expected_raw_q
  covariance <- solve(as.matrix(precision$precision))
  tip_covariance <- covariance[
    precision$tip_node_index,
    precision$tip_node_index
  ]
  raw_covariance <- solve(as.matrix(raw_precision$precision))
  raw_tip_covariance <- raw_covariance[
    raw_precision$tip_node_index,
    raw_precision$tip_node_index
  ]

  expect_s4_class(precision$precision, "dgCMatrix")
  expect_equal(as.matrix(raw_precision$precision), expected_raw_q)
  expect_equal(as.matrix(precision$precision), expected_q)
  expect_equal(raw_precision$log_det_precision, -log(2), tolerance = 1e-12)
  expect_equal(precision$log_det_precision, log(8), tolerance = 1e-12)
  log_det <- as.numeric(
    determinant(as.matrix(precision$precision), logarithm = TRUE)$modulus
  )
  expect_equal(
    precision$log_det_precision,
    log_det,
    tolerance = 1e-10
  )
  expect_equal(
    tip_covariance,
    drmTMB:::drm_phylo_tip_covariance(tree),
    tolerance = 1e-12
  )
  expect_equal(
    raw_tip_covariance,
    drmTMB:::drm_phylo_tip_covariance(tree, correlation = FALSE),
    tolerance = 1e-12
  )
})

test_that("drm_phylo_augmented_precision maps observed species to augmented nodes", {
  tree <- tiny_ultrametric_tree()
  species <- c("sp_c", "sp_a", "sp_c", "sp_b")

  precision <- drmTMB:::drm_phylo_augmented_precision(tree, species = species)

  expect_equal(precision$tip_label, c("sp_a", "sp_b", "sp_c"))
  expect_equal(precision$species_levels, c("sp_c", "sp_a", "sp_b"))
  expect_equal(precision$species_tip_index, c(3L, 1L, 2L))
  expect_equal(
    precision$species_node_index,
    c(sp_c = 3L, sp_a = 1L, sp_b = 2L)
  )
  expect_equal(precision$observation_species_index, c(1L, 2L, 1L, 3L))
})

test_that("drm_phylo_augmented_precision is invariant to edge order", {
  tree <- tiny_ultrametric_tree()
  reordered <- tree
  order <- c(4, 2, 1, 3)
  reordered$edge <- reordered$edge[order, , drop = FALSE]
  reordered$edge.length <- reordered$edge.length[order]

  precision <- drmTMB:::drm_phylo_augmented_precision(tree)
  reordered_precision <- drmTMB:::drm_phylo_augmented_precision(reordered)

  expect_equal(
    as.matrix(reordered_precision$precision)[
      precision$node_labels,
      precision$node_labels
    ],
    as.matrix(precision$precision),
    tolerance = 1e-12
  )
  expect_equal(
    reordered_precision$log_det_precision,
    precision$log_det_precision,
    tolerance = 1e-12
  )
})

test_that("drm_phylo_augmented_precision handles ultrametric polytomies", {
  tree <- structure(
    list(
      edge = matrix(c(4, 1, 4, 2, 4, 3), byrow = TRUE, ncol = 2),
      edge.length = c(1, 1, 1),
      tip.label = c("sp_a", "sp_b", "sp_c"),
      Nnode = 1L
    ),
    class = "phylo"
  )

  precision <- drmTMB:::drm_phylo_augmented_precision(tree)
  expected_precision <- diag(3)
  dimnames(expected_precision) <- list(tree$tip.label, tree$tip.label)

  expect_equal(as.matrix(precision$precision), expected_precision)
  expect_equal(
    solve(as.matrix(precision$precision)),
    drmTMB:::drm_phylo_tip_covariance(tree),
    tolerance = 1e-12
  )
})

test_that("drm_phylo_precision_nll matches the augmented Gaussian density", {
  tree <- tiny_ultrametric_tree()
  precision <- drmTMB:::drm_phylo_augmented_precision(tree)
  effect <- c(sp_a = 0.2, sp_b = -0.1, sp_c = 0.35, node4 = 0.05)
  log_sd <- log(0.7)
  quadratic <- sum(effect * as.numeric(precision$precision %*% effect))
  expected <- 0.5 *
    (length(effect) *
      log(2 * pi) +
      2 * length(effect) * log_sd -
      precision$log_det_precision +
      exp(-2 * log_sd) * quadratic)
  edge_quadratic <- precision$height *
    ((effect[["node4"]] - 0)^2 /
      1 +
      (effect[["sp_a"]] - effect[["node4"]])^2 / 1 +
      (effect[["sp_b"]] - effect[["node4"]])^2 / 1 +
      (effect[["sp_c"]] - 0)^2 / 2)

  expect_equal(quadratic, edge_quadratic, tolerance = 1e-12)
  expect_equal(
    drmTMB:::drm_phylo_precision_nll(effect, precision, log_sd = log_sd),
    expected,
    tolerance = 1e-12
  )
  expect_error(
    drmTMB:::drm_phylo_precision_nll(effect[-1], precision),
    "matching"
  )
  expect_error(
    drmTMB:::drm_phylo_precision_nll(effect, precision, log_sd = NA_real_),
    "finite numeric scalar"
  )
})

test_that("correlated phylogenetic precision algebra handles q=4 states", {
  tree <- tiny_ultrametric_tree()
  precision <- drmTMB:::drm_phylo_augmented_precision(tree)
  effect <- matrix(
    c(
      0.20,
      -0.10,
      0.35,
      0.05,
      -0.15,
      0.12,
      0.28,
      -0.04,
      0.05,
      0.18,
      -0.08,
      0.09,
      0.11,
      -0.07,
      0.16,
      -0.02
    ),
    nrow = nrow(precision$precision),
    dimnames = list(
      rownames(precision$precision),
      c("mu1", "mu2", "sigma1", "sigma2")
    )
  )
  sd_state <- c(0.65, 0.45, 0.30, 0.25)
  correlation <- matrix(
    c(
      1.00,
      0.20,
      -0.10,
      0.12,
      0.20,
      1.00,
      0.15,
      -0.08,
      -0.10,
      0.15,
      1.00,
      0.22,
      0.12,
      -0.08,
      0.22,
      1.00
    ),
    nrow = 4L
  )
  covariance <- diag(sd_state) %*% correlation %*% diag(sd_state)
  dense_covariance <- kronecker(
    covariance,
    solve(as.matrix(precision$precision))
  )

  expect_equal(
    drmTMB:::drm_phylo_correlated_precision_nll(
      effect,
      precision,
      covariance
    ),
    dense_zero_mvn_nll(as.numeric(effect), dense_covariance),
    tolerance = 1e-10
  )

  independent_covariance <- diag(sd_state[1:2]^2)
  expect_equal(
    drmTMB:::drm_phylo_correlated_precision_nll(
      effect[, 1:2],
      precision,
      independent_covariance
    ),
    drmTMB:::drm_phylo_precision_nll(
      effect[, 1],
      precision,
      log_sd = log(sd_state[[1L]])
    ) +
      drmTMB:::drm_phylo_precision_nll(
        effect[, 2],
        precision,
        log_sd = log(sd_state[[2L]])
      ),
    tolerance = 1e-10
  )
  expect_error(
    drmTMB:::drm_phylo_correlated_precision_nll(
      effect[, 1:2],
      precision,
      covariance
    ),
    "matching"
  )
  expect_error(
    drmTMB:::drm_phylo_correlated_precision_nll(
      effect,
      precision,
      diag(c(1, -1, 1, 1))
    ),
    "positive definite"
  )
})

test_that("TMB phylogenetic prior branch matches the R algebra helper", {
  tree <- tiny_ultrametric_tree()
  precision <- drmTMB:::drm_phylo_augmented_precision(tree)
  effect <- c(sp_a = 0.2, sp_b = -0.1, sp_c = 0.35, node4 = 0.05)
  log_sd <- log(0.7)

  obj <- TMB::MakeADFun(
    data = phylo_prior_tmb_data(precision),
    parameters = phylo_prior_tmb_parameters(effect, log_sd),
    DLL = "drmTMB",
    silent = TRUE
  )

  expect_equal(
    obj$fn(obj$par),
    drmTMB:::drm_phylo_precision_nll(effect, precision, log_sd = log_sd),
    tolerance = 1e-10
  )
  expect_true(all(is.finite(obj$gr(obj$par))))
})

test_that("validate_phylo_tree rejects malformed tree inputs", {
  tree <- tiny_ultrametric_tree()
  no_lengths <- tree
  no_lengths$edge.length <- NULL
  non_ultrametric <- tree
  non_ultrametric$edge.length[[2]] <- 0.5
  duplicate_tip <- tree
  duplicate_tip$tip.label[[2]] <- duplicate_tip$tip.label[[1]]
  tip_parent <- tree
  tip_parent$edge[1, 1] <- 1
  duplicate_child <- tree
  duplicate_child$edge[4, 2] <- 1

  expect_error(
    drmTMB:::validate_phylo_tree(unclass(tree)),
    "class"
  )
  expect_error(
    drmTMB:::validate_phylo_tree(no_lengths),
    "branch lengths"
  )
  expect_error(
    drmTMB:::validate_phylo_tree(non_ultrametric),
    "ultrametric"
  )
  expect_error(
    drmTMB:::validate_phylo_tree(duplicate_tip),
    "unique"
  )
  expect_error(
    drmTMB:::validate_phylo_tree(tip_parent),
    "tip nodes cannot be parent"
  )
  expect_error(
    drmTMB:::validate_phylo_tree(duplicate_child),
    "more than one parent"
  )
  expect_error(
    drmTMB:::validate_phylo_tree(tree, species = c("sp_a", NA)),
    "missing or empty"
  )
  expect_error(
    drmTMB:::validate_phylo_tree(tree, species = "sp_missing"),
    "Missing tip"
  )
})

test_that("drm_phylo_augmented_precision requires positive branch lengths", {
  tree <- tiny_ultrametric_tree()
  tree$edge.length <- c(0, 2, 2, 2)

  expect_error(
    drmTMB:::validate_phylo_tree(tree),
    NA
  )
  expect_error(
    drmTMB:::drm_phylo_augmented_precision(tree),
    "positive"
  )
  expect_error(
    drmTMB:::drm_phylo_augmented_precision(
      tiny_ultrametric_tree(),
      correlation = NA
    ),
    "correlation"
  )
})
