# Independent-oracle companion for the Julia Binomial phylo_interaction
# intercept SD route under logit, probit and cloglog. The pair covariance is
# built by hand as K1[host, host'] * K2[pollinator, pollinator'] from
# cov2cor(ape::vcv) of each tree (the package tip covariances are compared with
# those), and the dense Laplace oracle in helper-b31jb-oracle.R is evaluated at
# the live Julia estimates. Agreement is asserted to 1e-3 absolute; each
# emulated bug (swapped selector sets, sign-flipped SD slope, reversed SD
# vector, K x 2, raw vcv, one tree ignored (identity) in turn, kernel read
# by position) must move the oracle by more than 20 times that.
# Claim scope: one fixture per route; no calibration, coverage or broad parity.

b31jb_pint_fixture <- function(link, seed, n_each = 25L) {
  set.seed(seed)
  tree1 <- ape::rcoal(8L); tree1$tip.label <- paste0("h", 1:8)
  tree2 <- ape::rcoal(6L); tree2$tip.label <- paste0("p", 1:6)
  V1 <- ape::vcv(tree1); V2 <- ape::vcv(tree2)
  K1 <- stats::cov2cor(V1); K2 <- stats::cov2cor(V2)
  grid <- expand.grid(host = tree1$tip.label, pollinator = tree2$tip.label,
                      KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  grid$pair <- paste(grid$host, grid$pollinator, sep = ":")
  n_pair <- nrow(grid)
  hi <- match(grid$host, rownames(K1)); pi_ <- match(grid$pollinator, rownames(K2))
  pair_K <- function(A, B) {
    out <- A[hi, hi] * B[pi_, pi_]
    dimnames(out) <- list(grid$pair, grid$pair)
    out
  }
  K <- pair_K(K1, K2)
  z_level <- (seq_len(n_pair) / n_pair)^1.5 * 2 - 1
  alpha <- c(log(1.2), 1.2)
  u <- drop(t(chol(K)) %*% stats::rnorm(n_pair))
  idx <- rep(seq_len(n_pair), each = n_each)
  x <- 1.3 * stats::rnorm(length(idx))
  eta <- 0.1 + 0.4 * x + (b31jb_sd(alpha, z_level) * u)[idx]
  y <- stats::rbinom(length(idx), 1L, b31jb_linkinv(link, eta))
  dat <- data.frame(y = y, x = x, host = grid$host[idx],
                    pollinator = grid$pollinator[idx], pair = grid$pair[idx],
                    z = z_level[idx])
  dat <- dat[sample.int(nrow(dat)), , drop = FALSE]
  rv <- rev(seq_len(n_pair))
  K_pos <- K[rv, rv]  # kernel rows/columns in the wrong (reversed) level order
  list(data = dat, tree1 = tree1, tree2 = tree2, K1 = K1, K2 = K2, K = K,
       levels = grid$pair, z_level = z_level,
       K_bugs = list(
         raw_vcv_not_correlation = pair_K(V1, V2),
         pollinator_tree_ignored = pair_K(K1, diag(6L)),
         host_tree_ignored = pair_K(diag(8L), K2),
         K_by_position = K_pos
       ))
}

test_that("Julia Binomial phylo_interaction intercept SD matches an independent Laplace oracle for each link", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  skip_if_not_installed("ape")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path), "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  for (link in c("logit", "probit", "cloglog")) {
    fx <- b31jb_pint_fixture(link, 20261106L)
    tree1 <- fx$tree1
    tree2 <- fx$tree2
    # Package tip covariances equal the hand cov2cor(ape::vcv) correlations.
    expect_equal(drmTMB:::drm_phylo_tip_covariance(tree1)[rownames(fx$K1), colnames(fx$K1)],
                 fx$K1, tolerance = 1e-10, ignore_attr = TRUE)
    expect_equal(drmTMB:::drm_phylo_tip_covariance(tree2)[rownames(fx$K2), colnames(fx$K2)],
                 fx$K2, tolerance = 1e-10, ignore_attr = TRUE)
    fit <- drmTMB(
      bf(y ~ x + phylo_interaction(1 | host:pollinator, tree1 = tree1,
                                   tree2 = tree2),
         sd(pair, level = "phylogenetic_interaction") ~ z),
      family = stats::binomial(link = link), data = fx$data, engine = "julia"
    )
    expect_true(fit$opt$convergence == 0L, info = link)
    idx <- match(fx$data$pair, fx$levels)
    res <- b31jb_struct_run(fit, fx$data, link, "sd_phylo(pair)", fx$levels,
                            idx, fx$K, fx$z_level, K_bugs = fx$K_bugs)
    message(b31jb_check(res$ll, res$base, res$gaps,
                        paste("phylo_interaction", link)))
    b31jb_check_optimum(
      function(beta = res$beta, alphas = list(res$alpha)) {
        res$oracle(beta = beta, alphas = alphas)
      }, res$beta, list(res$alpha), res$base)
  }
})
