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
