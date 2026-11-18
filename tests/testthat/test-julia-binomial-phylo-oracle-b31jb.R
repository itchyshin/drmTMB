# Independent-oracle companion for the Julia Binomial phylo intercept and phylo
# numeric-slope SD routes under logit, probit and cloglog. The oracle is the
# base-R dense Laplace in helper-b31jb-oracle.R evaluated at the live Julia
# estimates, with K = cov2cor(ape::vcv(tree)) built by hand and compared with
# the package tip covariance. Agreement is asserted to 1e-3 absolute; every
# emulated bug (swapped selector sets, sign-flipped SD slope, reversed SD
# vector, K x 2, raw vcv instead of its correlation, kernel read by
# position instead of by name) must move the oracle by more than 20 times that.
# Claim scope: one fixture per route; no calibration, coverage or broad parity.

b31jb_phylo_fixture <- function(link, kind, seed, n_tip = 40L, n_each = 30L) {
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- sprintf("sp%02d", seq_len(n_tip))
  height <- max(ape::node.depth.edgelength(tree)[seq_len(n_tip)])
  tree$edge.length <- tree$edge.length / height * 2.5
  V <- ape::vcv(tree)
  K_tree <- stats::cov2cor(V)
  # Data factor levels are a fixed permutation of the tree tip order so that a
  # kernel read by position differs from the kernel read by name.
  levels_sp <- tree$tip.label[sample.int(n_tip)]
  z_level <- (seq_len(n_tip) / n_tip)^1.5 * 2 - 1
  names(z_level) <- levels_sp
  alpha <- c(log(1.2), 0.9)
  K <- K_tree[levels_sp, levels_sp]
  u <- drop(t(chol(K)) %*% stats::rnorm(n_tip))
  idx <- rep(seq_len(n_tip), each = n_each)
  x <- 1.3 * stats::rnorm(length(idx))
  field <- (b31jb_sd(alpha, z_level) * u)[idx]
  eta <- 0.1 + 0.4 * x + if (kind == "intercept") field else x * field
  y <- stats::rbinom(length(idx), 1L, b31jb_linkinv(link, eta))
  dat <- data.frame(y = y, x = x, z = z_level[idx],
                    species = factor(levels_sp[idx], levels = levels_sp))
  dat <- dat[sample.int(nrow(dat)), , drop = FALSE]
  list(data = dat, tree = tree, V = V, K_tree = K_tree, levels = levels_sp,
       z_level = z_level, K = K, height = 2.5)
}

b31jb_phylo_case <- function(link, kind, seed) {
  fx <- b31jb_phylo_fixture(link, kind, seed)
  tree <- fx$tree
  dat <- fx$data
  # The package tip covariance is the hand cov2cor(ape::vcv) correlation.
  pkg_K <- drmTMB:::drm_phylo_tip_covariance(tree)
  expect_equal(pkg_K[rownames(fx$K_tree), colnames(fx$K_tree)], fx$K_tree,
               tolerance = 1e-10, ignore_attr = TRUE)
  form <- if (kind == "intercept") {
    bf(y ~ x + phylo(1 | species, tree = tree),
       sd(species, level = "phylogenetic") ~ z)
  } else {
    bf(y ~ x + phylo(0 + x | species, tree = tree),
       sd(species, level = "phylogenetic") ~ z)
  }
  fit <- drmTMB(form, family = stats::binomial(link = link), data = dat,
                engine = "julia")
  idx <- match(as.character(dat$species), fx$levels)
  K_pos <- fx$K_tree
  dimnames(K_pos) <- list(fx$levels, fx$levels)
  K_bugs <- list(
    raw_vcv_not_correlation = fx$V[fx$levels, fx$levels],
    K_by_position = K_pos
  )
  b31jb_struct_run(fit, dat, link, "sd_phylo(species)", fx$levels, idx, fx$K,
                   fx$z_level, mult = if (kind == "intercept") NULL else dat$x,
                   K_bugs = K_bugs) |> c(list(fit = fit))
}

for (kind_case in c("intercept", "slope")) local({
  kind <- kind_case
  test_that(paste("Julia Binomial phylo", kind, "SD matches an independent Laplace oracle for each link"), {
    skip_on_cran()
    skip_if_not_installed("JuliaCall")
    skip_if_not_installed("ape")
    drm_skip_live_julia()
    jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
    skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
    drm_test_local_drmjl_path(jl_path)
    drm_test_local_julia_home()

    for (link in c("logit", "probit", "cloglog")) {
      res <- b31jb_phylo_case(link, kind, if (kind == "intercept") 20261104L else 20261105L)
      expect_true(res$fit$opt$convergence == 0L, info = link)
      message(b31jb_check(res$ll, res$base, res$gaps,
                          paste("phylo", kind, link)))
      b31jb_check_optimum(
        function(beta = res$beta, alphas = list(res$alpha)) {
          res$oracle(beta = beta, alphas = alphas)
        }, res$beta, list(res$alpha), res$base)
    }
  })
})
