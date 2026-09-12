test_that("phylo covariance model defaults to Brownian motion and accepts OU", {
  bm <- drmTMB:::parse_structured_marker_call(
    quote(phylo(1 | species, tree = tree)), "phylo", "mu"
  )
  ou <- drmTMB:::parse_structured_marker_call(
    quote(phylo(1 | species, tree = tree, model = "ou")), "phylo", "mu"
  )
  expect_identical(bm$model, "bm")
  expect_identical(ou$model, "ou")
  expect_identical(ou$tree, "tree")
})

test_that("phylo covariance model rejects malformed choices before fitting", {
  expect_error(
    drmTMB:::parse_structured_marker_call(
      quote(phylo(1 | species, tree = tree, model = "ar1")), "phylo", "mu"
    ),
    "bm.*ou"
  )
  expect_error(
    drmTMB:::parse_structured_marker_call(
      quote(phylo(1 | species, tree = tree, model = model_name)), "phylo", "mu"
    ),
    "must be"
  )
})

test_that("phylogenetic OU rejects unsupported model combinations before fitting", {
  skip_if_not_installed("ape")
  set.seed(2026091101)
  tree <- ape::rcoal(3)
  tree$tip.label <- paste0("sp", seq_len(3))
  dat <- data.frame(
    y = stats::rnorm(9),
    species = rep(tree$tip.label, each = 3)
  )
  expect_error(
    drmTMB(
      bf(y ~ (1 | species) + phylo(1 | species, tree = tree, model = "ou"), sigma ~ 1),
      data = dat, family = gaussian()
    ),
    "univariate Gaussian location intercept"
  )
})

test_that("explicit Brownian model reproduces the omitted-model fit", {
  skip_if_not_installed("ape")
  set.seed(2026091102)
  tree <- ape::rcoal(4)
  tree$tip.label <- paste0("sp", seq_len(4))
  dat <- data.frame(
    y = stats::rnorm(16),
    x = rep(c(-0.5, 0.5), length.out = 16),
    species = rep(tree$tip.label, each = 4)
  )
  implicit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
    data = dat, family = gaussian()
  )
  explicit <- drmTMB(
    bf(y ~ x + phylo(1 | species, tree = tree, model = "bm"), sigma ~ 1),
    data = dat, family = gaussian()
  )
  expect_equal(as.numeric(logLik(explicit)), as.numeric(logLik(implicit)), tolerance = 1e-8)
  expect_equal(coef(explicit, "mu"), coef(implicit, "mu"), tolerance = 1e-8)
})
