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
