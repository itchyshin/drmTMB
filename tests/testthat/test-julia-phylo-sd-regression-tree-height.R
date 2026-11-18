# Phylogenetic SD regression through engine = "julia" on a tree of height 2.
#
# Native drmTMB standardises the tree covariance to a correlation matrix, so a
# tree of height 1 hides any scale error. DRM.jl's Gaussian phylogenetic
# SD-regression route already reports the SD coefficients on that correlation
# scale, while the Gamma, Binomial and Poisson routes report the raw
# branch-length scale and need the bridge to shift the intercept by
# log(sqrt(height)). Shifting the Gaussian intercept as well counted the tree
# scale twice (bridge minus native was log(sqrt(2)) = 0.3466 before the fix).

phylo_sd_height2_fixture <- function(family_name) {
  set.seed(20261102L)
  ntip <- 40L
  tree <- ape::rcoal(ntip)
  tree$edge.length <- tree$edge.length * 2 /
    max(ape::node.depth.edgelength(tree))
  K <- ape::vcv(tree, corr = TRUE)
  zg <- seq(-1, 1, length.out = ntip)^3
  g <- rep(seq_len(ntip), each = 8L)
  n <- length(g)
  x <- stats::rnorm(n)
  u <- exp(-0.3 + 0.4 * zg) * as.numeric(t(chol(K)) %*% stats::rnorm(ntip))
  eta <- 0.3 + 0.3 * x + u[g]
  y <- switch(
    family_name,
    gaussian = eta + stats::rnorm(n, sd = 0.4),
    gamma = stats::rgamma(n, shape = 4, rate = 4 / exp(eta)),
    binomial = stats::rbinom(n, 1L, stats::plogis(eta)),
    poisson = stats::rpois(n, exp(eta))
  )
  list(
    data = data.frame(y = y, x = x, z = zg[g], species = tree$tip.label[g]),
    tree = tree
  )
}

test_that("phylogenetic SD regression coefficients match native on a height-2 tree", {
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("ape")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  families <- list(
    gaussian = gaussian(),
    gamma = Gamma(link = "log"),
    binomial = binomial(),
    poisson = poisson()
  )
  for (family_name in names(families)) {
    fixture <- phylo_sd_height2_fixture(family_name)
    tree <- fixture$tree
    form <- bf(
      y ~ x + phylo(1 | species, tree = tree),
      sd(species, level = "phylogenetic") ~ z
    )
    native <- drmTMB(form, families[[family_name]], data = fixture$data)
    bridge <- suppressWarnings(drmTMB(
      form, families[[family_name]], data = fixture$data, engine = "julia"
    ))
    native_sd <- coef(native, "sd_phylo(species)")
    bridge_sd <- coef(bridge, "sd_phylo")
    # The fixture tree has height 2, so a double or missing scale shift moves
    # the intercept by log(sqrt(2)) = 0.3466, far beyond this tolerance.
    expect_equal(
      unname(bridge_sd), unname(native_sd),
      tolerance = 1e-3, info = family_name
    )
    expect_equal(
      as.numeric(logLik(bridge)), as.numeric(logLik(native)),
      tolerance = 1e-5, info = family_name
    )
  }
})
