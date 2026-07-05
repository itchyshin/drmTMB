# Structured q6 = two-slope location-only bivariate Gaussian covariance.
#
# The `(1 + x + z | p | id)` block in `mu1` and `mu2` (six endpoints:
# mu1/mu2 x {(Intercept), x, z}) is the labelled two-slope extension of the
# admitted q4 one-slope location block. It is the M2 milestone of the Q-Series
# 104/104 arc. These tests fix the admission boundary: the labelled two-slope
# location block builds a q=6 among-endpoint covariance (15 correlations) for
# each provider, while the unlabelled univariate two-slope term, the labelled
# univariate two-slope term stays rejected (the all-four two-slope block is the
# separately-admitted M3 q12 cell).

q6_location_test_tree <- function(n_tip = 8L, prefix = "sp") {
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

# Build a bivariate two-slope location dataset from the Cholesky of a per-group
# covariance. Independent latent fields per endpoint keep the fixture simple:
# these tests assert model structure, not recovery of a known covariance.
q6_biv_location_data <- function(chol_cov, group_levels, group_name, n_each,
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
  e1 <- stats::rnorm(length(grp))
  e2 <- -0.15 * e1 + sqrt(1 - 0.15^2) * stats::rnorm(length(grp))
  dat <- data.frame(y1 = eta1 + 0.25 * e1, y2 = eta2 + 0.28 * e2, x = x, z = z)
  dat[[group_name]] <- grp
  dat
}

q6_control <- function() {
  drm_control(se = FALSE, optimizer = list(eval.max = 400, iter.max = 400))
}

expect_q6_location_block <- function(fit, provider) {
  structured <- fit$model$structured$phylo_mu
  expect_equal(structured$type, provider)
  expect_equal(structured$q, 6L)
  expect_equal(structured$dpars, rep(c("mu1", "mu2"), each = 3L))
  expect_equal(
    structured$coef_names,
    rep(c("(Intercept)", "x", "z"), times = 2L)
  )
  expect_equal(structured$covariance_mode, "unstructured")
  expect_length(fit$sdpars$mu, 6L)
  expect_length(fit$corpars[[provider]], 15L)
  expect_equal(sum(names(fit$opt$par) == "theta_phylo"), 15L)
  # Extractors surface all 15 among-endpoint correlations plus residual rho12.
  expect_length(ranef(fit, paste0(provider, "_mu"))$terms, 6L)
  pairs <- corpairs(fit)
  expect_equal(sum(pairs$level != "residual"), 15L)
  expect_equal(nrow(summary(fit)$covariance), 15L)
  targets <- profile_targets(fit)
  expect_equal(sum(startsWith(targets$parm, "sd:mu:")), 6L)
  expect_equal(sum(startsWith(targets$parm, paste0("cor:", provider, ":"))), 15L)
}

test_that("labelled two-slope location block builds a q=6 phylo covariance", {
  tree <- q6_location_test_tree(8L)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  dat <- q6_biv_location_data(t(chol(A)), tree$tip.label, "species", n_each = 8L)

  fit <- suppressWarnings(drmTMB(
    bf(
      mu1 = y1 ~ x + z + phylo(1 + x + z | p | species, tree = tree),
      mu2 = y2 ~ x + z + phylo(1 + x + z | p | species, tree = tree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = q6_control()
  ))

  expect_q6_location_block(fit, "phylo")
})

test_that("labelled two-slope location block builds a q=6 spatial covariance", {
  site_levels <- paste0("site_", seq_len(8L))
  theta <- seq(0, 1.5 * pi, length.out = 8L)
  coords <- data.frame(
    x = cos(theta) + seq_len(8L) / 24,
    y = sin(theta)
  )
  rownames(coords) <- site_levels
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = site_levels,
    group = "site"
  )
  covariance <- solve(as.matrix(precision$precision))
  dat <- q6_biv_location_data(t(chol(covariance)), site_levels, "site", 8L)

  fit <- suppressWarnings(drmTMB(
    bf(
      mu1 = y1 ~ x + z + spatial(1 + x + z | p | site, coords = coords),
      mu2 = y2 ~ x + z + spatial(1 + x + z | p | site, coords = coords),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = q6_control()
  ))

  expect_q6_location_block(fit, "spatial")
})

test_that("labelled two-slope location block builds a q=6 animal covariance", {
  pedigree <- data.frame(
    id = paste0("id", seq_len(8L)),
    dam = c(NA, NA, NA, NA, "id1", "id3", "id5", "id1"),
    sire = c(NA, NA, NA, NA, "id2", "id4", "id6", "id3"),
    stringsAsFactors = FALSE
  )
  A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  dat <- q6_biv_location_data(t(chol(A)), rownames(A), "id", n_each = 8L)

  fit <- suppressWarnings(drmTMB(
    bf(
      mu1 = y1 ~ x + z + animal(1 + x + z | p | id, pedigree = pedigree),
      mu2 = y2 ~ x + z + animal(1 + x + z | p | id, pedigree = pedigree),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = q6_control()
  ))

  expect_q6_location_block(fit, "animal")
})

test_that("labelled two-slope location block builds a q=6 relmat covariance", {
  id_levels <- paste0("id", seq_len(10L))
  K <- outer(seq_len(10L), seq_len(10L), function(i, j) 0.4^abs(i - j))
  diag(K) <- diag(K) + 0.10
  dimnames(K) <- list(id_levels, id_levels)
  Q <- solve(K)
  dat <- q6_biv_location_data(t(chol(K)), id_levels, "id", n_each = 8L)

  fit <- suppressWarnings(drmTMB(
    bf(
      mu1 = y1 ~ x + z + relmat(1 + x + z | p | id, Q = Q),
      mu2 = y2 ~ x + z + relmat(1 + x + z | p | id, Q = Q),
      sigma1 = ~1,
      sigma2 = ~1,
      rho12 = ~1
    ),
    family = biv_gaussian(),
    data = dat,
    control = q6_control()
  ))

  expect_q6_location_block(fit, "relmat")
})

test_that("unlabelled univariate two-slope structured term stays rejected", {
  tree <- q6_location_test_tree(8L)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  dat <- q6_biv_location_data(t(chol(A)), tree$tip.label, "species", n_each = 6L)

  expect_error(
    drmTMB(
      bf(y1 ~ x + z + phylo(1 + x + z | species, tree = tree), sigma ~ 1),
      family = gaussian(),
      data = dat
    ),
    "reserves only intercept and one-slope"
  )
})

test_that("labelled univariate two-slope structured term stays rejected", {
  tree <- q6_location_test_tree(8L)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  dat <- q6_biv_location_data(t(chol(A)), tree$tip.label, "species", n_each = 6L)

  expect_error(
    drmTMB(
      bf(y1 ~ x + z + phylo(1 + x + z | p | species, tree = tree), sigma ~ 1),
      family = gaussian(),
      data = dat
    ),
    "all-four bivariate Gaussian block"
  )
})

# The all-four two-slope block is the M3 q12 cell (admitted); its full build and
# boundary are covered by test-structured-re-q12-all-four.R. Here we only confirm
# the location (q6) admission did not accidentally reject it as a side effect.
test_that("all-four two-slope structured block now builds q=12 (M3)", {
  tree <- q6_location_test_tree(8L)
  A <- drmTMB:::drm_phylo_tip_covariance(tree)
  dat <- q6_biv_location_data(t(chol(A)), tree$tip.label, "species", n_each = 8L)

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
    control = drm_control(se = FALSE, optimizer = list(eval.max = 100, iter.max = 100))
  ))
  expect_equal(fit$model$structured$phylo_mu$q, 12L)
})
