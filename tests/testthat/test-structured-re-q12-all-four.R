# Structured q12 = two-slope all-four bivariate Gaussian covariance.
#
# `(1 + x + z | p | id)` on ALL FOUR endpoints (mu1/mu2/sigma1/sigma2) -> twelve
# endpoints (each x {(Intercept), x, z}) -> 12 SD + 66 among-endpoint
# correlations. It is the "broader q8" cell of the Q-Series 104/104 arc (M3): the
# two-slope generalization of the admitted q8 all-four one-slope block, sharing
# one covariance label. These tests fix the admission boundary: the labelled
# two-slope all-four block builds a q=12 covariance, while the block-diagonal and
# partial layouts stay rejected.

q12_test_tree <- function(n_tip = 8L, prefix = "sp") {
  stopifnot(n_tip >= 2L, log2(n_tip) == floor(log2(n_tip)))
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L
  build <- function(tips) {
    if (length(tips) == 1L) {
      return(tips)
    }
    node <- next_node
    next_node <<- next_node + 1L
    mid <- length(tips) / 2L
    left <- build(tips[seq_len(mid)])
    right <- build(tips[seq.int(mid + 1L, length(tips))])
    edges <<- rbind(edges, c(node, left), c(node, right))
    edge_lengths <<- c(edge_lengths, 1, 1)
    node
  }
  build(seq_len(n_tip))
  structure(
    list(
      edge = edges,
      edge.length = edge_lengths,
      tip.label = paste0(prefix, "_", seq_len(n_tip)),
      Nnode = n_tip - 1L
    ),
    class = "phylo"
  )
}

q12_biv_data <- function(chol_cov, group_levels, group_name, n_each,
                         seed = 20260705) {
  set.seed(seed)
  ng <- length(group_levels)
  field <- function(sd) {
    v <- as.vector(chol_cov %*% stats::rnorm(ng, sd = sd))
    names(v) <- group_levels
    v
  }
  grp <- rep(group_levels, each = n_each)
  x <- stats::rnorm(length(grp))
  z <- stats::rnorm(length(grp))
  eta1 <- 0.30 + 0.25 * x - 0.15 * z +
    field(0.45)[grp] + x * field(0.30)[grp] + z * field(0.25)[grp]
  eta2 <- -0.20 - 0.20 * x + 0.10 * z +
    field(0.40)[grp] + x * field(0.28)[grp] + z * field(0.22)[grp]
  ls1 <- -1.00 + 0.15 * z +
    field(0.30)[grp] + x * field(0.20)[grp] + z * field(0.18)[grp]
  ls2 <- -0.95 - 0.10 * z +
    field(0.28)[grp] + x * field(0.18)[grp] + z * field(0.16)[grp]
  e1 <- stats::rnorm(length(grp))
  e2 <- -0.15 * e1 + sqrt(1 - 0.15^2) * stats::rnorm(length(grp))
  dat <- data.frame(
    y1 = eta1 + exp(ls1) * e1, y2 = eta2 + exp(ls2) * e2, x = x, z = z
  )
  dat[[group_name]] <- grp
  dat
}

q12_control <- function() {
  drm_control(se = FALSE, optimizer = list(eval.max = 400, iter.max = 400))
}

test_that("labelled two-slope all-four block builds a q=12 phylo covariance", {
  tree <- q12_test_tree(8L)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  dat <- q12_biv_data(t(chol(A)), tree$tip.label, "species", n_each = 8L)

  fit <- suppressWarnings(drmTMB(
    bf(
      mu1 = y1 ~ x + z + phylo(1 + x + z | p | species, tree = tree),
      mu2 = y2 ~ x + z + phylo(1 + x + z | p | species, tree = tree),
      sigma1 = ~ z + phylo(1 + x + z | p | species, tree = tree),
      sigma2 = ~ z + phylo(1 + x + z | p | species, tree = tree),
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = q12_control()
  ))

  structured <- fit$model$structured$phylo_mu
  expect_equal(structured$type, "phylo")
  expect_equal(structured$q, 12L)
  expect_equal(
    structured$dpars,
    rep(c("mu1", "mu2", "sigma1", "sigma2"), each = 3L)
  )
  expect_equal(
    structured$coef_names,
    rep(c("(Intercept)", "x", "z"), times = 4L)
  )
  expect_equal(structured$covariance_mode, "unstructured")
  expect_length(fit$sdpars$mu, 12L)
  expect_length(fit$corpars$phylo, 66L)
  expect_equal(sum(names(fit$opt$par) == "theta_phylo"), 66L)
  # Extractors surface all 66 among-endpoint correlations plus residual rho12.
  pairs <- corpairs(fit)
  expect_equal(sum(pairs$level != "residual"), 66L)
  expect_equal(nrow(summary(fit)$covariance), 66L)
  targets <- profile_targets(fit)
  sd_rows <- targets[startsWith(targets$parm, "sd:"), ]
  cor_rows <- targets[startsWith(targets$parm, "cor:phylo:"), ]
  expect_equal(nrow(sd_rows), 12L)
  expect_equal(nrow(cor_rows), 66L)
  # Routing invariant (the pdHess=FALSE doctrine): the 12 SDs are direct
  # profile targets; the 66 correlations are derived and NOT profile/Wald-ready
  # (they route through profile/bootstrap; ELR excluded).
  expect_true(all(sd_rows$profile_ready))
  expect_true(all(!cor_rows$profile_ready))
})

test_that("two-slope all-four requires one shared covariance label", {
  tree <- q12_test_tree(8L)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  dat <- q12_biv_data(t(chol(A)), tree$tip.label, "species", n_each = 6L)

  # Block-diagonal labels (mu-block vs sigma-block) stay rejected.
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + z + phylo(1 + x + z | pm | species, tree = tree),
        mu2 = y2 ~ x + z + phylo(1 + x + z | pm | species, tree = tree),
        sigma1 = ~ z + phylo(1 + x + z | ps | species, tree = tree),
        sigma2 = ~ z + phylo(1 + x + z | ps | species, tree = tree),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "one shared covariance label"
  )
})

test_that("two-slope all-four requires matching coefficients in all four", {
  tree <- q12_test_tree(8L)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  dat <- q12_biv_data(t(chol(A)), tree$tip.label, "species", n_each = 6L)

  # sigma endpoints carry only one slope while mu carries two -> rejected.
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x + z + phylo(1 + x + z | p | species, tree = tree),
        mu2 = y2 ~ x + z + phylo(1 + x + z | p | species, tree = tree),
        sigma1 = ~ z + phylo(1 + x | p | species, tree = tree),
        sigma2 = ~ z + phylo(1 + x | p | species, tree = tree),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat
    ),
    "same structured coefficient"
  )
})
