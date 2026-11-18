# b26 companion for evidence ids
#   native-count-structured-q2-more-providers-sd-20261101d-20261102a
#   native-poisson-structured-q2-sd-regression-20261101d-20261102a-20261102b
#   native-nbinom2-structured-q2-sd-regression-20261101d-20261102a
#
# Ledger deficiency addressed: those tests fit only the q = 2 (intercept plus
# slope) structured blocks, so the single-field structured INTERCEPT rows
# ("structured random intercept", q = 1) had no fit behind them. Here, for
# Poisson and NB2 (log link), each of these single-field intercept rows is
# fitted with a predictor-dependent SD, sd(id, level = <provider>) ~ w:
#   animal_intercept (A_covariance)        both families
#   relmat_intercept K_covariance          both families
#   relmat_intercept Q_precision           both families
#   phylo_intercept (tree)                 both families
#   spatial_coordinate_intercept (coords)  both families
# Oracle: dense Laplace marginal in base R (helper-sb26-oracle.R), evaluated at
# the fitted parameters, tolerance 1e-4 absolute on logLik. Kernels are
# independent of the package: A by the Henderson tabular method from an inbred
# pedigree, phylogenetic K = ape::vcv / tree height, spatial K by hand from
# dist(coords), relmat K a hand-built non-unit-diagonal matrix. The data factor
# levels are shuffled relative to the supplied matrices, so alignment is by
# name. Emulated bugs must move the oracle by more than 0.1: reversed per-level
# SD vector, sign-flipped SD predictor, K read by position, and (where the
# diagonal is not constant) cov2cor(K) or (phylo, spatial) a wrong kernel
# convention. No calibration, coverage or parity claim.

sb26_count_kernel <- function(provider, seed) {
  set.seed(seed)
  if (provider == "animal") {
    A <- sb26_tabular_A(sb26_inbred_pedigree(5L))
    return(list(K = A, ids = rownames(A), alt = "cov2cor"))
  }
  if (provider %in% c("relmat_K", "relmat_Q")) {
    G <- 36L
    ids <- sprintf("g%02d", seq_len(G))
    C <- outer(seq_len(G), seq_len(G), function(i, j) 0.35^abs(i - j))
    dd <- seq(0.8, 1.6, length.out = G)[sample.int(G)]
    K <- diag(dd) %*% C %*% diag(dd)
    dimnames(K) <- list(ids, ids)
    return(list(K = K, ids = ids, alt = "cov2cor"))
  }
  if (provider == "phylo") {
    G <- 36L
    ids <- sprintf("g%02d", seq_len(G))
    tree <- ape::rcoal(G)
    tree$tip.label <- sample(ids)
    return(list(K = sb26_phylo_K(tree, ids), ids = ids, tree = tree,
                alt = "unstandardised"))
  }
  G <- 36L
  ids <- sprintf("g%02d", seq_len(G))
  coords <- data.frame(east = stats::runif(G, 0, 4), north = stats::runif(G, 0, 3),
                       row.names = ids)
  list(K = sb26_spatial_kernel(coords, ids), ids = ids, coords = coords,
       alt = "squared_exp")
}

sb26_count_row <- function(provider, family, seed) {
  kern <- sb26_count_kernel(provider, seed)
  ids <- kern$ids
  G <- length(ids)
  K <- kern$K
  w <- stats::setNames(sample(rep(c(-1, 1), length.out = G)), ids)
  s_true <- exp(-0.6 + 0.8 * w)
  b <- s_true * drop(t(chol(K)) %*% stats::rnorm(G))
  lev <- sample(ids)
  id <- factor(rep(lev, each = 14L), levels = lev)
  x <- rep(seq(-1.2, 1.2, length.out = 14L), times = G)
  eta <- 0.6 + 0.25 * x + b[as.character(id)]
  y <- if (family == "poisson") {
    stats::rpois(length(eta), exp(eta))
  } else {
    stats::rnbinom(length(eta), size = 2.5, mu = exp(eta))
  }
  d <- data.frame(y = y, x = x, id = id, w = unname(w[as.character(id)]))

  # Matrices handed to the package: shuffled relative to the data levels.
  sup <- sample(ids)
  Ksup <- K[sup, sup]
  Qsup <- solve(Ksup)
  dimnames(Qsup) <- dimnames(Ksup)
  coords <- kern$coords[sup, , drop = FALSE]
  tree <- kern$tree
  rhs <- switch(
    provider,
    animal = "animal(1 | id, A = Ksup)",
    relmat_K = "relmat(1 | id, K = Ksup)",
    relmat_Q = "relmat(1 | id, Q = Qsup)",
    phylo = "phylo(1 | id, tree = tree)",
    spatial = "spatial(1 | id, coords = coords)"
  )
  level <- c(animal = "animal", relmat_K = "relmat", relmat_Q = "relmat",
             phylo = "phylogenetic", spatial = "spatial")[[provider]]
  prefix <- c(animal = "sd_animal", relmat_K = "sd_relmat", relmat_Q = "sd_relmat",
              phylo = "sd_phylo", spatial = "sd_spatial")[[provider]]
  mu_formula <- stats::as.formula(paste("y ~ x +", rhs), env = environment())
  sd_formula <- stats::as.formula(
    sprintf('sd(id, level = "%s") ~ w', level), env = environment()
  )
  f <- if (family == "poisson") {
    bf(mu_formula, sd_formula)
  } else {
    bf(mu_formula, sigma ~ 1, sd_formula)
  }
  fit <- drmTMB(
    f, family = if (family == "poisson") stats::poisson() else nbinom2(),
    data = d, control = drm_control(se = FALSE)
  )
  info <- paste(family, provider)
  expect_equal(fit$opt$convergence, 0L, info = info)
  key <- sprintf("%s(id)", prefix)
  expect_setequal(setdiff(names(coef(fit)), c("mu", "sigma")), key)
  a <- coef(fit, key)
  expect_named(a, c("(Intercept)", "w"))
  s_hat <- exp(a[[1L]] + a[[2L]] * w[lev])
  names(s_hat) <- lev
  expect_gt(stats::sd(log(s_hat)), 0.1)
  expect_equal(unname(predict(fit, dpar = key)[lev]), unname(s_hat),
               tolerance = 1e-8, info = info)

  beta <- coef(fit, "mu")
  eta_fixed <- beta[[1L]] + beta[[2L]] * d$x
  deriv <- if (family == "poisson") {
    sb26_deriv_poisson(d$y)
  } else {
    sb26_deriv_nb2(d$y, exp(-2 * coef(fit, "sigma")[[1L]]))
  }
  idx <- as.integer(d$id)
  oracle <- function(Kmat, s) {
    sb26_laplace(deriv, eta_fixed, sb26_Z(idx, G, s), Kmat[lev, lev])
  }
  ref <- oracle(K, s_hat)
  expect_lt(abs(as.numeric(logLik(fit)) - ref), 1e-4, label = info)

  gap <- function(Kmat, s) abs(oracle(Kmat, s) - ref)
  expect_gt(gap(K, sb26_reverse(s_hat)), 0.1, label = paste(info, "reversed SD"))
  s_flip <- exp(a[[1L]] - a[[2L]] * w[lev])
  expect_gt(gap(K, s_flip), 0.1, label = paste(info, "flipped predictor"))
  K_pos <- K
  dimnames(K_pos) <- list(lev, lev)
  expect_gt(gap(K_pos, s_hat), 0.1, label = paste(info, "K by position"))
  alt <- switch(
    kern$alt,
    cov2cor = stats::cov2cor(K),
    unstandardised = {
      V <- ape::vcv(kern$tree)[ids, ids]
      expect_gt(max(diag(V)), 1.05)  # standardisation is observable
      V
    },
    squared_exp = {
      dm <- as.matrix(stats::dist(as.matrix(kern$coords[ids, 1:2])))
      Ksq <- exp(-(dm / stats::median(dm[upper.tri(dm)]))^2)
      diag(Ksq) <- diag(Ksq) + 1e-6
      dimnames(Ksq) <- list(ids, ids)
      Ksq
    }
  )
  expect_gt(gap(alt, s_hat), 0.1, label = paste(info, kern$alt))
  if (provider == "phylo") {
    # The package's tip covariance equals ape::vcv at unit tree height.
    expect_equal(unname(drmTMB:::drm_phylo_tip_covariance(tree)[ids, ids]),
                 unname(K[ids, ids]), tolerance = 1e-10)
  }
  invisible(fit)
}

test_that("Poisson single-field structured intercept SD regression matches a dense Laplace oracle (animal, relmat K and Q, phylo, spatial)", {
  skip_on_cran()
  skip_if_not_installed("ape")
  seeds <- c(animal = 20261301L, relmat_K = 20261302L, relmat_Q = 20261303L,
             phylo = 20261304L, spatial = 20261305L)
  for (p in names(seeds)) sb26_count_row(p, "poisson", seeds[[p]])
})

test_that("NB2 single-field structured intercept SD regression matches a dense Laplace oracle (animal, relmat K and Q, phylo, spatial)", {
  skip_on_cran()
  skip_if_not_installed("ape")
  seeds <- c(animal = 20261311L, relmat_K = 20261312L, relmat_Q = 20261313L,
             phylo = 20261314L, spatial = 20261315L)
  for (p in names(seeds)) sb26_count_row(p, "nbinom2", seeds[[p]])
})
