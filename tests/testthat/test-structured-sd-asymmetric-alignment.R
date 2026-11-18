# Alignment of structured SD-regression providers under asymmetric inputs.
#
# Why this file exists: the older alignment fixtures for spatial, relmat and
# Toeplitz providers passed the kernel in a shuffled or reversed order of a
# ring or a Toeplitz matrix. Those kernels have symmetries (reflection,
# rotation), and their oracles built the covariance with the helper under test.
# Here every kernel is built by hand in this file from first principles:
#   * spatial: Sigma_ij = exp(-d_ij / m) + 1e-6 * 1(i = j), where d is the
#     Euclidean distance between irregular, non-symmetric coordinates and m is
#     the median of the positive pairwise distances (the documented
#     `spatial()` kernel; read from drm_spatial_coords_precision()), written
#     out here with dist() and median(), never by calling the helper;
#   * relmat: K = D R D with R = (A A' + 0.5 I) rescaled to a correlation
#     matrix and D a random positive diagonal, so K is dense, non-Toeplitz and
#     has non-unit, unequal diagonal entries.
# Data factor levels are in a shuffled order unlike rownames(K) and
# rownames(coords), and data rows are shuffled too, so the fit must match
# kernel rows to levels by name.
#
# Routes: Poisson spatial intercept; NB2 relmat intercept; NB2 spatial
# intercept; Gaussian relmat intercept; Gaussian spatial intercept, each with
# sd(group, level = ...) ~ z.
#
# Oracles: Gaussian is the exact marginal likelihood. Poisson and NB2 use a
# dense Laplace approximation (damped Newton for the mode, then
# f(u*) - 0.5 log|Sigma| - 0.5 log|H|), both evaluated at the fitted
# parameters with the hand-built covariance indexed by level name.
#
# Tolerances, fixed before the first run:
#   * fitted logLik vs oracle: relative 1e-6 (the same as the older files);
#   * misalignment bug: the oracle with the covariance read by position (the
#     rownames dropped, which is what a permuted-level bug does) must differ
#     from the correct oracle by more than 1000 x 1e-6 x |logLik|, and by more
#     than 0.5 log-likelihood units absolute;
#   * hand-built relmat/spatial kernels must be positive definite and the
#     named reading must differ from the positional one by more than 0.2 (max
#     abs entry).
#
# Not covered: slope-only fields, Toeplitz/phylo/animal providers, Q or Ainv
# inputs, se = TRUE inference, calibration or parity claims, and any family
# beyond Gaussian, Poisson and NB2.

sa_n_group <- 20L

# Hand-built spatial kernel for coords with rownames, in the order `levels`.
sa_spatial_kernel <- function(coords, levels) {
  xy <- as.matrix(coords[levels, 1:2])
  n <- nrow(xy)
  d <- matrix(0, n, n)
  for (i in seq_len(n)) {
    for (j in seq_len(n)) {
      d[i, j] <- sqrt(sum((xy[i, ] - xy[j, ])^2))
    }
  }
  pos <- d[upper.tri(d)]
  m <- stats::median(pos[pos > 0])
  K <- exp(-d / m) + 1e-6 * diag(n)
  dimnames(K) <- list(levels, levels)
  K
}

sa_relmat <- function(ids, seed) {
  set.seed(seed)
  n <- length(ids)
  A <- matrix(stats::rnorm(n * 4L), n, 4L)
  S <- tcrossprod(A) + 0.5 * diag(n)
  R <- S / sqrt(outer(diag(S), diag(S)))
  D <- diag(stats::runif(n, 0.8, 1.6))
  K <- D %*% R %*% D
  dimnames(K) <- list(ids, ids)
  K
}

# Fixture: groups g01..., factor levels shuffled; kernel / coords supplied in
# yet another order (so rownames(K) != levels(data$g) and neither is sorted).
sa_fixture <- function(provider = c("spatial", "relmat"),
                       family = c("gaussian", "poisson", "nbinom2"),
                       seed, n_each = 8L) {
  provider <- match.arg(provider)
  family <- match.arg(family)
  n <- sa_n_group
  ids <- sprintf("g%02d", seq_len(n))
  set.seed(seed)
  lev <- sample(ids)             # data factor level order
  supplied <- sample(ids)        # order of rownames(K) / rownames(coords)
  if (provider == "spatial") {
    coords_all <- data.frame(
      x = stats::runif(n, 0, 10),
      y = stats::rexp(n, 0.4),
      row.names = ids
    )
    K_all <- sa_spatial_kernel(coords_all, ids)
    supplied_obj <- coords_all[supplied, , drop = FALSE]
  } else {
    K_all <- sa_relmat(ids, seed + 7L)
    supplied_obj <- K_all[supplied, supplied]
  }
  K_lev <- K_all[lev, lev]
  z <- stats::setNames(as.numeric(scale(stats::rnorm(n))), lev)
  alpha <- c(`(Intercept)` = log(0.9), z = 0.45)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z)
  u <- tau * as.vector(t(chol(K_lev)) %*% stats::rnorm(n))
  names(u) <- lev
  g <- factor(rep(lev, each = n_each), levels = lev)
  x <- stats::rnorm(length(g))
  eta <- 0.3 + 0.3 * x + u[as.character(g)]
  y <- switch(
    family,
    gaussian = eta + stats::rnorm(length(g), sd = 0.4),
    poisson = stats::rpois(length(g), exp(eta)),
    nbinom2 = stats::rnbinom(length(g), mu = exp(eta), size = 1 / 0.5^2)
  )
  dat <- data.frame(y = y, x = x, g = g, z = unname(z[as.character(g)]))
  dat <- dat[sample(nrow(dat)), ]   # shuffled rows; levels(dat$g) unchanged
  rownames(dat) <- NULL
  list(data = dat, supplied = supplied_obj, K = K_lev, K_all = K_all,
       levels = lev, supplied_order = supplied, z = z, alpha = alpha)
}

# Exact Gaussian marginal log-likelihood, covariance indexed by level name.
sa_gaussian_ll <- function(y, eta0, group_idx, sigma, tau, Sigma) {
  n <- length(y)
  Z <- matrix(0, n, nrow(Sigma))
  Z[cbind(seq_len(n), group_idx)] <- 1
  V <- Z %*% (outer(tau, tau) * Sigma) %*% t(Z) + diag(sigma^2, n)
  R <- chol(V)
  r <- backsolve(R, y - eta0, transpose = TRUE)
  -0.5 * (n * log(2 * pi) + 2 * sum(log(diag(R))) + sum(r^2))
}

# Dense Laplace marginal log-likelihood for a log-link count model.
sa_laplace_ll <- function(y, eta0, group_idx, tau, Sigma, family, size = NULL) {
  n_group <- nrow(Sigma)
  Sigma_inv <- solve(Sigma)
  logdet_Sigma <- as.numeric(determinant(Sigma, logarithm = TRUE)$modulus)
  agg <- function(v) as.numeric(rowsum(v, group_idx, reorder = TRUE))
  stopifnot(identical(sort(unique(group_idx)), seq_len(n_group)))
  parts <- function(u) {
    mu <- exp(eta0 + tau[group_idx] * u[group_idx])
    if (family == "poisson") {
      list(ll = sum(stats::dpois(y, mu, log = TRUE)), score = y - mu, info = mu)
    } else {
      list(
        ll = sum(stats::dnbinom(y, size = size, mu = mu, log = TRUE)),
        score = size * (y - mu) / (size + mu),
        info = size * mu * (size + y) / (size + mu)^2
      )
    }
  }
  objective <- function(u) parts(u)$ll - 0.5 * sum(u * (Sigma_inv %*% u))
  u <- rep(0, n_group)
  for (iter in seq_len(200L)) {
    p <- parts(u)
    grad <- tau * agg(p$score) - as.numeric(Sigma_inv %*% u)
    H <- diag(tau^2 * agg(p$info), n_group) + Sigma_inv
    step <- as.numeric(solve(H, grad))
    old <- objective(u)
    s <- 1
    while (objective(u + s * step) < old - 1e-12 && s > 1e-8) s <- s / 2
    u <- u + s * step
    if (max(abs(s * step)) < 1e-11) break
  }
  p <- parts(u)
  H <- diag(tau^2 * agg(p$info), n_group) + Sigma_inv
  logdet_H <- as.numeric(determinant(H, logarithm = TRUE)$modulus)
  objective(u) - 0.5 * logdet_Sigma - 0.5 * logdet_H
}

# Run one route: fit, then compare logLik to the oracle with the correct
# covariance and show that a positionally-read (permuted-level) covariance
# moves the oracle far outside tolerance.
sa_check_route <- function(provider, family, seed) {
  fx <- sa_fixture(provider, family, seed)
  dat <- fx$data
  lev <- fx$levels

  # Fixture sanity: asymmetric alignment, hand-built kernel is SPD.
  expect_false(identical(lev, fx$supplied_order))
  expect_false(identical(lev, sort(lev)))
  expect_gt(min(eigen(fx$K, symmetric = TRUE, only.values = TRUE)$values), 0)
  K_positional <- fx$K
  dimnames(K_positional) <- list(lev, lev)
  K_supplied_read_by_position <- if (provider == "relmat") {
    m <- fx$supplied
    dimnames(m) <- list(lev, lev)
    m
  } else {
    cc <- fx$supplied
    rownames(cc) <- lev
    sa_spatial_kernel(cc, lev)
  }
  expect_gt(max(abs(K_supplied_read_by_position - fx$K)), 0.2)
  if (provider == "relmat") {
    expect_gt(diff(range(diag(fx$K))), 0.3)  # unequal, non-unit diagonal
  }

  if (provider == "relmat") {
    K <- fx$supplied
    form <- bf(y ~ x + relmat(1 | g, K = K), sd(g, level = "relmat") ~ z)
    sd_dpar <- "sd_relmat(g)"
  } else {
    coords <- fx$supplied
    form <- bf(y ~ x + spatial(1 | g, coords = coords),
               sd(g, level = "spatial") ~ z)
    sd_dpar <- "sd_spatial(g)"
  }
  fam <- switch(family, gaussian = stats::gaussian(), poisson = stats::poisson(),
                nbinom2 = nbinom2())
  if (family == "nbinom2") {
    form <- if (provider == "relmat") {
      bf(y ~ x + relmat(1 | g, K = K), sigma ~ 1, sd(g, level = "relmat") ~ z)
    } else {
      bf(y ~ x + spatial(1 | g, coords = coords), sigma ~ 1,
         sd(g, level = "spatial") ~ z)
    }
  }
  fit <- drmTMB(form, family = fam, data = dat, control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0L)

  # SD predictions are keyed by level name and equal exp(X alpha).
  sd_coef <- coef(fit, sd_dpar)
  tau_hat <- exp(sd_coef[["(Intercept)"]] + sd_coef[["z"]] * fx$z[lev])
  expect_equal(unname(predict(fit, dpar = sd_dpar)[lev]), unname(tau_hat),
               tolerance = 1e-8)

  mu_coef <- coef(fit, "mu")
  eta0 <- as.numeric(stats::model.matrix(~ x, dat) %*% mu_coef[c("(Intercept)", "x")])
  gidx <- match(as.character(dat$g), lev)
  oracle_for <- function(Sigma) {
    switch(
      family,
      gaussian = sa_gaussian_ll(dat$y, eta0, gidx, unname(sigma(fit)),
                                unname(tau_hat), Sigma),
      poisson = sa_laplace_ll(dat$y, eta0, gidx, unname(tau_hat), Sigma,
                              "poisson"),
      nbinom2 = sa_laplace_ll(dat$y, eta0, gidx, unname(tau_hat), Sigma,
                              "nbinom2",
                              size = 1 / exp(unname(coef(fit, "sigma")[["(Intercept)"]]))^2)
    )
  }
  ll_correct <- oracle_for(fx$K)
  expect_equal(as.numeric(stats::logLik(fit)), ll_correct, tolerance = 1e-6)

  # Permuted-level bug: kernel read by position against the data levels.
  ll_bug <- oracle_for(K_supplied_read_by_position)
  gap <- abs(ll_bug - ll_correct)
  expect_gt(gap, 1000 * 1e-6 * abs(ll_correct))
  expect_gt(gap, 0.5)
  invisible(list(ll = as.numeric(stats::logLik(fit)), oracle = ll_correct,
                 bug_oracle = ll_bug, gap = gap))
}

test_that("Poisson spatial SD regression aligns with irregular coordinates by name", {
  skip_on_cran()
  res <- sa_check_route("spatial", "poisson", seed = 20261201L)
  expect_true(is.finite(res$gap))
})

test_that("NB2 relmat SD regression aligns with an asymmetric relatedness matrix", {
  skip_on_cran()
  res <- sa_check_route("relmat", "nbinom2", seed = 20261202L)
  expect_true(is.finite(res$gap))
})

test_that("NB2 spatial SD regression aligns with irregular coordinates by name", {
  skip_on_cran()
  res <- sa_check_route("spatial", "nbinom2", seed = 20261203L)
  expect_true(is.finite(res$gap))
})

test_that("Gaussian relmat SD regression aligns with an asymmetric relatedness matrix", {
  skip_on_cran()
  res <- sa_check_route("relmat", "gaussian", seed = 20261204L)
  expect_true(is.finite(res$gap))
})

test_that("Gaussian spatial SD regression aligns with irregular coordinates by name", {
  skip_on_cran()
  res <- sa_check_route("spatial", "gaussian", seed = 20261205L)
  expect_true(is.finite(res$gap))
})
