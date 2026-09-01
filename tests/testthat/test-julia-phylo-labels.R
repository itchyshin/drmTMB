test_that("Julia Newick serializer escapes and preserves non-simple tip labels", {
  skip_if_not_installed("ape")
  tree <- ape::read.tree(text = "((a:1,b:1):1,c:2,d:2);")
  labels <- c("Homo sapiens", "A,B: C(D)[E];", "O'Brien", "Δ_日本")
  tree$tip.label <- labels
  original <- ape::vcv(tree)

  payload <- drm_julia_phylo_newick(tree)
  expect_identical(payload$tip_order, labels)
  expect_identical(
    payload$newick,
    "(('Homo sapiens':1,'A,B: C(D)[E];':1):1,'O''Brien':2,'Δ_日本':2);"
  )

  # ape documents quoted-label handling as evolving, so it is not the decoder
  # oracle. The Julia parser test consumes this Newick; retain the native
  # named covariance as an independent row-identity invariant here.
  expect_equal(
    ape::vcv(tree)[labels, labels],
    original[labels, labels],
    tolerance = 1e-12
  )
})

test_that("Julia Newick serialization preserves row identity after edge reordering", {
  skip_if_not_installed("ape")
  tree <- ape::read.tree(text = "((a:1,b:1):1,c:2,d:2);")
  labels <- c("a b", "comma,colon:", "O'Brien", "日本語")
  tree$tip.label <- labels
  original <- ape::vcv(tree)
  order <- rev(seq_len(nrow(tree$edge)))
  tree$edge <- tree$edge[order, , drop = FALSE]
  tree$edge.length <- tree$edge.length[order]

  payload <- drm_julia_phylo_newick(tree)
  expect_identical(payload$tip_order, labels[c(4L, 3L, 2L, 1L)])
  expect_identical(
    payload$newick,
    "('日本語':2,'O''Brien':2,('comma,colon:':1,'a b':1):1);"
  )
  expect_equal(
    ape::vcv(tree)[labels, labels],
    original[labels, labels],
    tolerance = 1e-12
  )
})

test_that("Julia Newick serializer keeps accepted control whitespace literally", {
  skip_if_not_installed("ape")
  tree <- ape::read.tree(text = "(a:1,b:1,c:1);")
  labels <- c("tab\tlabel", "line\nbreak", "plain")
  tree$tip.label <- labels

  payload <- drm_julia_phylo_newick(tree)
  expect_identical(payload$tip_order, labels)
  expect_true(grepl(paste0("'", labels[[1L]], "'"), payload$newick, fixed = TRUE))
  expect_true(grepl(paste0("'", labels[[2L]], "'"), payload$newick, fixed = TRUE))
})

test_that("Julia Newick serializer keeps collision-prone spaces and old simple labels distinct", {
  skip_if_not_installed("ape")
  simple <- ape::read.tree(text = "(under_score:1,plain-2:1,dot.name:1);")
  expect_identical(
    drm_julia_phylo_newick(simple)$newick,
    "(under_score:1,plain-2:1,dot.name:1);"
  )

  tree <- ape::read.tree(text = "(a:1,b:1,c:1,d:1,e:1);")
  labels <- c("A B", "AB", "A_B", " leading", "trailing ")
  tree$tip.label <- labels
  payload <- drm_julia_phylo_newick(tree)
  expect_identical(payload$tip_order, labels)
  expect_identical(
    payload$newick,
    "('A B':1,AB:1,A_B:1,' leading':1,'trailing ':1);"
  )
})

test_that("Julia Newick serializer preserves native tree-label rejections", {
  skip_if_not_installed("ape")
  simple <- ape::read.tree(text = "(under_score:1,plain-2:1,dot.name:1);")

  empty <- simple
  empty$tip.label[[1L]] <- ""
  expect_error(drm_julia_phylo_newick(empty), "non-missing|nonempty")
  missing_label <- simple
  missing_label$tip.label[[1L]] <- NA_character_
  expect_error(drm_julia_phylo_newick(missing_label), "non-missing")
})

cat("JULIA_PHYLO_LABELS_TEST_READY\n")
