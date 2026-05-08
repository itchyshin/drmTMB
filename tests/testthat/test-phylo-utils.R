tiny_ultrametric_tree <- function() {
  structure(
    list(
      edge = matrix(
        c(
          5, 4,
          4, 1,
          4, 2,
          5, 3
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
      1, 0.5, 0,
      0.5, 1, 0,
      0, 0, 1
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
      1, 0, 0, -1,
      0, 1, 0, -1,
      0, 0, 0.5, 0,
      -1, -1, 0, 3
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
    drmTMB:::drm_phylo_augmented_precision(tiny_ultrametric_tree(), correlation = NA),
    "correlation"
  )
})
