test_that("Gamma phylogenetic SD parity retains non-unit branch-length scale", {
  skip_if_not_installed("ape")
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  set.seed(20261029L)
  n_tip <- 24L
  n_each <- 16L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("sp_", seq_len(n_tip))
  tree$edge.length <- 2 * tree$edge.length
  tree_height <- max(ape::node.depth.edgelength(tree)[seq_len(n_tip)])
  expect_gt(tree_height, 1)

  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  z_tip <- as.numeric(scale(stats::rnorm(n_tip)))
  names(z_tip) <- tree$tip.label
  alpha <- c(`(Intercept)` = log(0.45), z = 0.35)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z_tip)
  field <- as.vector(t(chol(K)) %*% stats::rnorm(n_tip))
  tip_index <- rep(seq_len(n_tip), each = n_each)
  x <- stats::rnorm(length(tip_index))
  mu <- exp(0.3 + 0.2 * x + tau[tip_index] * field[tip_index])
  sigma <- 0.4
  shape <- sigma^-2
  dat <- data.frame(
    y = stats::rgamma(length(mu), shape = shape, rate = shape / mu),
    x = x,
    species = factor(tree$tip.label[tip_index], levels = tree$tip.label),
    z = z_tip[tip_index]
  )
  form <- bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ 1,
    sd(species, level = "phylogenetic") ~ z
  )

  fit_tmb <- drmTMB(
    form, family = Gamma(link = "log"), data = dat, engine = "tmb",
    control = drm_control(se = FALSE)
  )
  fit_julia <- drmTMB(
    form, family = Gamma(link = "log"), data = dat, engine = "julia"
  )
  dpar <- "sd_phylo(species)"

  expect_true(is_converged(fit_tmb))
  expect_true(is_converged(fit_julia))
  expect_named(coef(fit_tmb, dpar), names(alpha))
  expect_named(coef(fit_julia, dpar), names(alpha))
  expect_equal(coef(fit_julia, dpar), coef(fit_tmb, dpar), tolerance = 1e-3)
  expect_equal(
    unname(predict(fit_julia, dpar = dpar)),
    unname(predict(fit_tmb, dpar = dpar)),
    tolerance = 1e-3
  )
})
