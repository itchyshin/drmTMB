# Tree and relatedness guards. No fit is built.

two_tip_phylo <- function(
  edge = cbind(c(3L, 3L), c(1L, 2L)),
  edge_length = c(1, 1),
  n_node = 1L,
  tip_label = c("a", "b")
) {
  structure(
    list(
      edge = edge,
      edge.length = edge_length,
      tip.label = tip_label,
      Nnode = n_node
    ),
    class = "phylo"
  )
}

test_that("validate_phylo_tree rejects a phylogeny that is not a list of edges", {
  expect_error(
    drmTMB:::validate_phylo_tree(structure(5, class = "phylo")),
    "list-like"
  )
  tree <- two_tip_phylo(n_node = 1.5)
  expect_error(
    drmTMB:::validate_phylo_tree(tree),
    "Nnode"
  )
  tree <- two_tip_phylo(edge = c(3, 1))
  expect_error(
    drmTMB:::validate_phylo_tree(tree),
    "two-column numeric matrix"
  )
  tree <- two_tip_phylo(edge = cbind(c(3L, 3L), c(1L, 9L)))
  expect_error(
    drmTMB:::validate_phylo_tree(tree),
    "invalid node indices"
  )
  tree <- two_tip_phylo(edge_length = c(1, -0.2))
  expect_error(
    drmTMB:::validate_phylo_tree(tree),
    "non-negative"
  )
})

test_that("validate_phylo_tree rejects the wrong number of roots and a zero height", {
  two_roots <- two_tip_phylo(
    edge = cbind(c(3L, 4L), c(1L, 2L)),
    n_node = 2L
  )
  expect_error(
    drmTMB:::validate_phylo_tree(two_roots),
    "exactly one root"
  )

  disconnected <- two_tip_phylo(
    edge = cbind(c(3L, 3L), c(1L, 4L)),
    n_node = 2L
  )
  expect_error(
    drmTMB:::validate_phylo_tree(disconnected),
    "connected from a single root"
  )

  flat <- two_tip_phylo(edge_length = c(0, 0))
  expect_error(
    drmTMB:::validate_phylo_tree(flat),
    "positive root-to-tip height"
  )
})

test_that("a valid two-tip tree reports height 1 and species must be tips", {
  info <- drmTMB:::validate_phylo_tree(two_tip_phylo())
  expect_identical(info$n_tip, 2L)
  expect_identical(info$height, 1)
  expect_true(info$is_ultrametric)

  expect_error(
    drmTMB:::validate_phylo_species(character(), c("a", "b")),
    "at least one observed species"
  )
  expect_error(
    drmTMB:::validate_phylo_tree(two_tip_phylo(), species = "c"),
    "represented in"
  )
})

test_that("relatedness helpers reject a non-numeric Matrix and a pedigree cycle", {
  logical_matrix <- Matrix::Matrix(
    c(TRUE, FALSE, FALSE, TRUE),
    nrow = 2L,
    ncol = 2L
  )
  expect_error(
    drmTMB:::drm_standardize_relatedness_matrix(logical_matrix, "relmat", "K"),
    "must be numeric"
  )

  relatedness <- data.frame(
    a = c(1, 0.25),
    b = c(0.25, 1),
    row.names = c("a", "b")
  )
  standardized <- drmTMB:::drm_standardize_relatedness_matrix(
    relatedness,
    "relmat",
    "K"
  )
  expect_identical(dim(standardized), c(2L, 2L))
  expect_equal(unname(standardized["a", "b"]), 0.25)

  cycle <- data.frame(
    id = c("a", "b"),
    dam = c("b", "a"),
    sire = c(NA_character_, NA_character_),
    stringsAsFactors = FALSE
  )
  expect_error(
    drmTMB:::drm_pedigree_topological_order(cycle),
    "parent-offspring cycles"
  )

  expect_error(
    drmTMB:::drm_phylo_precision_nll(c(0, 0), list(precision = diag(2))),
    "drm_phylo_augmented_precision"
  )
})
