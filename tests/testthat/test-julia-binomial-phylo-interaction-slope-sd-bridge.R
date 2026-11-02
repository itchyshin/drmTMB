binomial_phylo_interaction_slope_tree <- function(prefix) {
  edges <- matrix(integer(), ncol = 2L)
  lengths <- numeric()
  next_node <- 9L
  build <- function(tips) {
    if (length(tips) == 1L) return(tips)
    node <- next_node
    next_node <<- next_node + 1L
    mid <- length(tips) / 2L
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    edges <<- rbind(edges, c(node, left), c(node, right))
    lengths <<- c(lengths, 1, 1)
    node
  }
  build(seq_len(8L))
  structure(list(
    edge = edges, edge.length = lengths,
    tip.label = paste0(prefix, seq_len(8L)), Nnode = 7L
  ), class = "phylo")
}

binomial_phylo_interaction_slope_fixture <- function(seed = 202610281L) {
  set.seed(seed)
  tree1 <- binomial_phylo_interaction_slope_tree("plant_")
  tree2 <- binomial_phylo_interaction_slope_tree("poll_")
  A1 <- drmTMB:::drm_phylo_tip_covariance(tree1)
  A2 <- drmTMB:::drm_phylo_tip_covariance(tree2)
  pair_cov <- kronecker(A2, A1)
  pairs <- expand.grid(
    plant = tree1$tip.label, pollinator = tree2$tip.label,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  pairs$pair <- paste(pairs$plant, pairs$pollinator, sep = ":")
  z <- as.numeric(scale(stats::rnorm(nrow(pairs))))
  alpha <- c(`(Intercept)` = log(0.45), z = 0.55)
  pair_sd <- exp(alpha[[1L]] + alpha[[2L]] * z)
  unit <- as.vector(t(chol(pair_cov)) %*% stats::rnorm(nrow(pairs)))
  pair_slope <- pair_sd * unit
  n_each <- 24L
  index <- rep(seq_len(nrow(pairs)), each = n_each)
  dat <- pairs[index, , drop = FALSE]
  dat$z <- z[index]
  dat$x <- rep(seq(-1.5, 1.5, length.out = n_each), times = nrow(pairs))
  dat$y <- stats::rbinom(
    nrow(dat), 1L,
    stats::plogis(-0.1 + 0.45 * dat$x + dat$x * pair_slope[index])
  )
  dat <- dat[sample.int(nrow(dat)), , drop = FALSE]
  list(data = dat, tree1 = tree1, tree2 = tree2, alpha = alpha)
}

binomial_phylo_interaction_slope_formula <- function(tree1, tree2) {
  bf(
    y ~ x + phylo_interaction(
      0 + x | plant:pollinator, tree1 = tree1, tree2 = tree2
    ),
    sd(pair, level = "phylogenetic_interaction", coef = "x") ~ z
  )
}

test_that("Julia bridge maps interaction slope SDs to matching relmat terms", {
  skip_if_not_installed("ape")
  fixture <- binomial_phylo_interaction_slope_fixture()
  tree1 <- fixture$tree1
  tree2 <- fixture$tree2
  formula <- binomial_phylo_interaction_slope_formula(
    tree1, tree2
  )
  expect_true(drm_julia_binomial_phylo_interaction_sd_route_admitted(formula))
  payload <- drm_julia_binomial_phylo_interaction_sd_payload(
    formula, fixture$data, environment()
  )
  expect_match(payload$formula[["mu"]], "relmat\\(0 \\+ x \\| pair\\)")
  expect_match(payload$formula[[2L]], "sd\\(pair, relmat, coef\\(x\\)\\) ~ z")
  expect_identical(payload$kwarg, "K")
  expect_identical(dim(payload$matrix), c(64L, 64L))

  wrong_target <- bf(
    y ~ x + phylo_interaction(
      0 + x | plant:pollinator,
      tree1 = tree1, tree2 = tree2
    ),
    sd(pair, level = "phylogenetic_interaction", coef = "other") ~ z
  )
  expect_false(drm_julia_binomial_phylo_interaction_sd_route_admitted(
    wrong_target
  ))
})

test_that("Binomial phylogenetic-interaction slope SD matches across engines", {
  skip_on_cran()
  drm_skip_live_julia()
  skip_if_not_installed("JuliaCall")
  fixture <- binomial_phylo_interaction_slope_fixture()
  formula <- binomial_phylo_interaction_slope_formula(
    fixture$tree1, fixture$tree2
  )
  fit_julia <- drmTMB(
    formula, family = stats::binomial(), data = fixture$data,
    engine = "julia"
  )
  fit_tmb <- drmTMB(
    formula, family = stats::binomial(), data = fixture$data,
    engine = "tmb", control = drm_control(se = FALSE)
  )
  expect_equal(fit_julia$opt$convergence, 0L)
  expect_equal(fit_tmb$opt$convergence, 0L)
  sd_dpar <- 'sd_phylo(pair, coef = "x")'
  expect_equal(
    unname(coef(fit_julia, sd_dpar)),
    unname(coef(fit_tmb, "sd_phylo(pair)")), tolerance = 0.2
  )
  expect_equal(as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
               tolerance = 0.3)
  expect_identical(
    simulate(fit_julia, nsim = 1L, seed = 202610282L)$sim_1,
    simulate(fit_julia, nsim = 1L, seed = 202610282L)$sim_1
  )
})
