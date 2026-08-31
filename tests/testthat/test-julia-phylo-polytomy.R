test_that("Julia serialization retains polytomies, lengths and traversal order", {
  skip_if_not_installed("ape")
  for (newick in c("(a:1,b:1,c:1);", "((a:1,b:1,c:1):2,d:3,e:3);",
                   "((a:1,b:1):2,(c:1,d:1):2);")) {
    tree <- ape::read.tree(text = newick)
    for (permute in c(FALSE, TRUE)) {
      if (permute) {
        order <- rev(seq_len(nrow(tree$edge)))
        tree$edge <- tree$edge[order, , drop = FALSE]
        tree$edge.length <- tree$edge.length[order]
      }
      payload <- drm_julia_phylo_newick(tree)
      replay <- ape::read.tree(text = payload$newick)
      expect_identical(payload$tip_order, replay$tip.label)
      expect_equal(replay$Nnode, tree$Nnode)
      expect_equal(sort(replay$edge.length), sort(tree$edge.length), tolerance = 1e-14)
      original <- ape::vcv(tree)
      expect_equal(ape::vcv(replay)[tree$tip.label, tree$tip.label], original,
                   tolerance = 1e-12)
      expect_equal(drm_julia_phylo_sd_scale(tree), unname(sqrt(diag(original)[1])),
                   tolerance = 1e-12)
    }
  }
})

test_that("Julia serializer keeps other explicit tree refusal boundaries", {
  skip_if_not_installed("ape")
  expect_error(drm_julia_phylo_newick(ape::read.tree(text = "((a:1):1,b:2);")),
               "unary|at least two")
  expect_error(drm_julia_phylo_newick(ape::read.tree(text = "(a:0,b:1,c:1);")),
               "ultrametric|positive")
  tree <- ape::read.tree(text = "(a:1,b:1,c:1);")
  tree$tip.label[1] <- "not simple"
  expect_error(drm_julia_phylo_newick(tree), "simple")
})
