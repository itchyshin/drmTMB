# Gaussian sigma-endpoint structured SD regression, q1 (native route).
#
#   y ~ x,  sigma ~ 1 + phylo(1 | id, tree = tree)   (or animal / relmat / spatial)
#   sd(id, level = <provider level>, dpar = "sigma") ~ z
#
# The structured effect sits in log sigma, so the marginal likelihood is not
# Gaussian. The oracle is a dense Laplace approximation over the structured
# sigma effects u ~ N(0, K), evaluated at the fitted parameters. It uses only
# fixture quantities (K from ape::vcv, a supplied matrix, or the exponential
# kernel) and its own derivatives; no drmTMB helper is called.
#
# Tolerances fixed before the first run:
#   abs. logLik against the oracle        1e-4
#   oracle mode gradient (inf norm)       < 1e-8, Hessian positive definite
#   two oracle starts, objective gap      < 1e-6
#   oracle FD gradient / Hessian error    < 1e-4 / < 2e-4
#   constant-SD limit, abs. logLik        1e-5
#   emulated-bug oracle shift             > 1e-2 (100 times the logLik tolerance)
#
# Scope: likelihood agreement at the fitted parameters only. The phylo kernel is
# a correlation matrix (unit diagonal) by package construction; relmat, animal
# and spatial use non-unit-diagonal K. No recovery, coverage, calibration or
# parity claim is made.

gss_levels <- c(phylo = "phylogenetic", animal = "animal", relmat = "relmat",
                spatial = "spatial")
gss_key <- function(provider) sprintf("sd_%s(id)", provider)

gss_fixture <- function(provider, seed, n_g = 48L, n_each = 20L) {
  set.seed(seed)
  ids <- sprintf("s%02d", seq_len(n_g))
  tree <- coords <- NULL
  if (provider == "phylo") {
    tree <- ape::rcoal(n_g, tip.label = ids)
    K <- ape::vcv(tree, corr = TRUE)[ids, ids]
  } else if (provider == "spatial") {
    coords <- cbind(x = rep(seq_len(8L), each = 8L)[seq_len(n_g)],
                    y = rep(seq_len(8L), 8L)[seq_len(n_g)])
    rownames(coords) <- ids
    distance <- as.matrix(stats::dist(coords))
    range <- stats::median(distance[upper.tri(distance) & distance > 0])
    K <- exp(-distance / range) + diag(1e-6, n_g)
  } else {
    diagonal <- seq(0.7, 1.4, length.out = n_g)
    K <- 0.3^abs(outer(seq_len(n_g), seq_len(n_g), "-")) *
      outer(sqrt(diagonal), sqrt(diagonal))
  }
  # K handed to the model is stored in a shuffled level order.
  perm <- sample(ids)
  dimnames(K) <- list(ids, ids)
  K <- K[perm, perm]
  z <- stats::setNames(seq(-1, 1, length.out = n_g), ids)
  u <- stats::setNames(drop(t(chol(K[ids, ids])) %*% stats::rnorm(n_g)), ids)
  alpha <- c(log(0.45), 0.5)
  group <- rep(ids, each = n_each)
  x <- stats::rnorm(length(group))
  scale <- exp(alpha[[1L]] + alpha[[2L]] * z[group])
  y <- 0.2 + 0.5 * x +
    stats::rnorm(length(group), sd = exp(log(0.5) + scale * u[group]))
  data <- data.frame(y = y, x = x, id = factor(group, levels = sample(ids)),
                     z = unname(z[group]))
  data <- data[sample(nrow(data)), ]
  rownames(data) <- NULL
  list(data = data, K = K, tree = tree, coords = coords, z = z,
       provider = provider)
}

gss_form <- function(fx, constant = FALSE, sd_dpar = "sigma") {
  K <- fx$K; tree <- fx$tree; coords <- fx$coords
  provider <- fx$provider
  sigma <- switch(
    provider,
    phylo = sigma ~ 1 + phylo(1 | id, tree = tree),
    animal = sigma ~ 1 + animal(1 | id, A = K),
    relmat = sigma ~ 1 + relmat(1 | id, K = K),
    spatial = sigma ~ 1 + spatial(1 | id, coords = coords)
  )
  rhs <- if (constant) "1" else "z"
  sd <- stats::as.formula(sprintf(
    'sd(id, level = "%s", dpar = "%s") ~ %s', gss_levels[[provider]], sd_dpar, rhs
  ))
  environment(sigma) <- environment()
  environment(sd) <- environment()
  bf(y ~ x, sigma, sd)
}

gss_fit <- function(form, data) {
  drmTMB(form, family = stats::gaussian(), data = data,
         control = drm_control(se = FALSE))
}

# Dense Laplace over u ~ N(0, K) with eta_i = s0 + scale_g(i) u_g(i):
#   f(u) = sum_i [0.5 log 2 pi + eta_i + 0.5 r_i^2 exp(-2 eta_i)]
#          + 0.5 u' K^-1 u + 0.5 log det K + 0.5 m log 2 pi
gss_oracle <- function(fit, fx, scale = NULL) {
  d <- fx$data
  ids <- rownames(fx$K)
  m <- length(ids)
  P <- solve(fx$K)
  logdet <- as.numeric(determinant(fx$K, logarithm = TRUE)$modulus)
  a <- stats::coef(fit, gss_key(fx$provider))
  if (is.null(scale)) scale <- exp(a[[1L]] + a[[2L]] * fx$z[ids])
  ii <- match(as.character(d$id), ids)
  B <- matrix(0, nrow(d), m)
  B[cbind(seq_len(nrow(d)), ii)] <- scale[ii]
  r <- d$y - drop(cbind(1, d$x) %*% stats::coef(fit, "mu"))
  s0 <- stats::coef(fit, "sigma")[[1L]]
  eta <- function(u) s0 + drop(B %*% u)
  f <- function(u) {
    e <- eta(u)
    sum(0.5 * log(2 * pi) + e + 0.5 * r^2 * exp(-2 * e)) +
      0.5 * drop(crossprod(u, P %*% u)) + 0.5 * logdet + 0.5 * m * log(2 * pi)
  }
  grad <- function(u) {
    w <- 1 - r^2 * exp(-2 * eta(u))
    drop(crossprod(B, w) + P %*% u)
  }
  hess <- function(u) {
    P + crossprod(B, 2 * r^2 * exp(-2 * eta(u)) * B)
  }
  starts <- list(rep(0, m), seq(-0.05, 0.05, length.out = m))
  modes <- lapply(starts, function(s0_) {
    u <- stats::nlminb(s0_, f, grad, hess,
                       control = list(iter.max = 200L, eval.max = 400L,
                                      rel.tol = 1e-14))$par
    for (k in seq_len(50L)) {
      g <- grad(u)
      if (max(abs(g)) < 1e-11) break
      u <- u - solve(hess(u), g)
    }
    u
  })
  objectives <- vapply(modes, f, numeric(1L))
  u <- modes[[which.min(objectives)]]
  H <- hess(u)
  probe <- starts[[2L]]
  step <- 1e-5
  cols <- unique(c(1L, m %/% 2L, m))
  fd_grad <- vapply(cols, function(j) {
    e <- numeric(m); e[[j]] <- step
    (f(probe + e) - f(probe - e)) / (2 * step)
  }, numeric(1L))
  fd_hess <- vapply(cols, function(j) {
    e <- numeric(m); e[[j]] <- step
    (grad(probe + e) - grad(probe - e)) / (2 * step)
  }, numeric(m))
  list(
    loglik = -f(u) + 0.5 * m * log(2 * pi) -
      0.5 * as.numeric(determinant(H, logarithm = TRUE)$modulus),
    max_grad = max(abs(grad(u))),
    min_eig = min(eigen(H, symmetric = TRUE, only.values = TRUE)$values),
    mode_gap = diff(range(objectives)),
    grad_error = max(abs(fd_grad - grad(probe)[cols])),
    hess_error = max(abs(fd_hess - hess(probe)[, cols, drop = FALSE]))
  )
}

gss_expect_oracle <- function(fit, oracle) {
  expect_equal(fit$opt$convergence, 0L)
  expect_lt(oracle$max_grad, 1e-8)
  expect_gt(oracle$min_eig, 0)
  expect_lt(oracle$mode_gap, 1e-6)
  expect_lt(oracle$grad_error, 1e-4)
  expect_lt(oracle$hess_error, 2e-4)
  expect_lt(abs(as.numeric(stats::logLik(fit)) - oracle$loglik), 1e-4)
}

gss_seeds <- c(phylo = 2026110101L, animal = 2026110102L, relmat = 2026110103L,
               spatial = 2026110104L)

for (provider in names(gss_levels)) {
  local({
    provider <- provider
    test_that(sprintf("Gaussian sigma %s q1 SD regression matches the dense Laplace oracle", provider), {
      skip_on_cran()
      skip_if_not_installed("ape")
      fx <- gss_fixture(provider, gss_seeds[[provider]])
      fit <- gss_fit(gss_form(fx), fx$data)
      key <- gss_key(provider)
      expect_true(key %in% names(fit$sdpars))
      expect_length(stats::coef(fit, key), 2L)
      expect_named(stats::coef(fit, key), c("(Intercept)", "z"))
      gss_expect_oracle(fit, gss_oracle(fit, fx))
      # Predicted structured SDs follow the SD formula by level name.
      predicted <- stats::predict(fit, dpar = key)
      a <- stats::coef(fit, key)
      expect_setequal(names(predicted), rownames(fx$K))
      expect_equal(unname(predicted),
                   unname(exp(a[[1L]] + a[[2L]] * fx$z[names(predicted)])),
                   tolerance = 1e-10)
    })

    test_that(sprintf("Gaussian sigma %s q1: constant SD formula reproduces the formula-free fit", provider), {
      skip_on_cran()
      skip_if_not_installed("ape")
      fx <- gss_fixture(provider, gss_seeds[[provider]])
      constant <- gss_fit(gss_form(fx, constant = TRUE), fx$data)
      K <- fx$K; tree <- fx$tree; coords <- fx$coords
      sigma <- switch(
        provider,
        phylo = sigma ~ 1 + phylo(1 | id, tree = tree),
        animal = sigma ~ 1 + animal(1 | id, A = K),
        relmat = sigma ~ 1 + relmat(1 | id, K = K),
        spatial = sigma ~ 1 + spatial(1 | id, coords = coords)
      )
      environment(sigma) <- environment()
      base <- gss_fit(bf(y ~ x, sigma), fx$data)
      expect_equal(constant$opt$convergence, 0L)
      expect_equal(base$opt$convergence, 0L)
      expect_lt(abs(as.numeric(stats::logLik(constant)) -
                      as.numeric(stats::logLik(base))), 1e-5)
      expect_lt(max(abs(stats::coef(constant, "mu") - stats::coef(base, "mu"))), 1e-3)
      expect_lt(max(abs(stats::coef(constant, "sigma") -
                          stats::coef(base, "sigma"))), 1e-3)
    })
  })
}

test_that("Gaussian sigma q1 SD oracle is sensitive to swapped formulas and misaligned levels", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (provider in c("relmat", "phylo")) {
    fx <- gss_fixture(provider, gss_seeds[[provider]])
    fit <- gss_fit(gss_form(fx), fx$data)
    ids <- rownames(fx$K)
    a <- stats::coef(fit, gss_key(provider))
    # A fixture whose SD slope is near zero would make this check vacuous.
    expect_gt(abs(a[[2L]]), 0.1)
    truth <- exp(a[[1L]] + a[[2L]] * fx$z[ids])
    ll <- as.numeric(stats::logLik(fit))
    right <- gss_oracle(fit, fx)$loglik
    expect_lt(abs(ll - right), 1e-4)
    shifted <- function(scale) abs(gss_oracle(fit, fx, scale = scale)$loglik - ll)
    # swapped SD formula: slope sign flipped
    expect_gt(shifted(exp(a[[1L]] - a[[2L]] * fx$z[ids])), 1e-2)
    # misaligned levels: SD rows reversed against the K order
    expect_gt(shifted(stats::setNames(rev(unname(truth)), ids)), 1e-2)
    # constant SD in place of the formula
    expect_gt(shifted(stats::setNames(rep(exp(a[[1L]]), length(ids)), ids)), 1e-2)
  }
})

test_that("Gaussian sigma structured SD keeps neighbouring routes closed", {
  skip_if_not_installed("ape")
  fx <- gss_fixture("relmat", gss_seeds[["relmat"]])
  fp <- gss_fixture("phylo", gss_seeds[["phylo"]])
  d <- fx$data
  dp <- fp$data
  K <- fx$K
  tree <- fp$tree
  gaussian_fit <- function(...) drmTMB(bf(...), family = stats::gaussian(), data = d)
  # structured effect in mu, SD aimed at sigma
  expect_error(
    drmTMB(bf(y ~ x + phylo(1 | id, tree = tree), sigma ~ 1,
              sd(id, level = "phylogenetic", dpar = "sigma") ~ z),
           family = stats::gaussian(), data = dp),
    "own endpoint of the structured term only"
  )
  # structured effect in sigma, SD aimed at mu or left at the mu default
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1 + phylo(1 | id, tree = tree),
              sd(id, level = "phylogenetic", dpar = "mu") ~ z),
           family = stats::gaussian(), data = dp),
    "own endpoint of the structured term only"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1 + phylo(1 | id, tree = tree),
              sd(id, level = "phylogenetic") ~ z),
           family = stats::gaussian(), data = dp),
    "must name its endpoint"
  )
  # mu and sigma structured effects together (location-scale block)
  expect_error(
    drmTMB(bf(y ~ x + phylo(1 | id, tree = tree),
              sigma ~ 1 + phylo(1 | id, tree = tree),
              sd(id, level = "phylogenetic") ~ z),
           family = stats::gaussian(), data = dp),
    "not implemented with residual-scale effects"
  )
  expect_error(
    drmTMB(bf(y ~ x + phylo(1 | id, tree = tree),
              sigma ~ 1 + phylo(1 | id, tree = tree),
              sd(id, level = "phylogenetic", dpar = "sigma") ~ z),
           family = stats::gaussian(), data = dp),
    "own endpoint of the structured term only"
  )
  # structured sigma slope stays closed
  expect_error(
    gaussian_fit(y ~ x, sigma ~ 1 + relmat(0 + x | id, K = K),
                 sd(id, level = "relmat", dpar = "sigma") ~ z),
    "intercept-only"
  )
  # ordinary random effects, meta_V and aggregation are not combined with it
  expect_error(
    gaussian_fit(y ~ x, sigma ~ 1 + (1 | id) + relmat(1 | id, K = K),
                 sd(id, level = "relmat", dpar = "sigma") ~ z),
    "one structured sigma intercept alone"
  )
  expect_error(
    gaussian_fit(y ~ x + (1 | id), sigma ~ 1 + relmat(1 | id, K = K),
                 sd(id, level = "relmat", dpar = "sigma") ~ z),
    "one structured sigma intercept alone"
  )
  d$V <- 0.1
  expect_error(
    gaussian_fit(y ~ x + meta_V(V = V), sigma ~ 1 + relmat(1 | id, K = K),
                 sd(id, level = "relmat", dpar = "sigma") ~ z),
    "one structured sigma intercept alone"
  )
  d$V <- NULL
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1 + relmat(1 | id, K = K),
              sd(id, level = "relmat", dpar = "sigma") ~ z),
           family = stats::gaussian(), data = d,
           control = drm_control(aggregate_gaussian = TRUE)),
    "aggregation is not implemented with structured"
  )
  # target mismatches
  expect_error(
    gaussian_fit(y ~ x, sigma ~ 1 + relmat(1 | id, K = K),
                 sd(id, level = "animal", dpar = "sigma") ~ z),
    "does not match the structured"
  )
  expect_error(
    gaussian_fit(y ~ x, sigma ~ 1 + relmat(1 | id, K = K),
                 sd(x, level = "relmat", dpar = "sigma") ~ z),
    "does not match the grouping variable"
  )
  expect_error(
    gaussian_fit(y ~ x, sigma ~ 1 + relmat(1 | id, K = K),
                 sd(id, level = "relmat", dpar = "sigma") ~ x),
    "constant within"
  )
  # another family keeps the sigma-endpoint structured SD closed
  d$yb <- stats::plogis(d$y)
  expect_error(
    drmTMB(bf(yb ~ x, sigma ~ 1 + relmat(1 | id, K = K),
              sd(id, level = "relmat", dpar = "sigma") ~ z),
           family = beta_family(), data = d),
    "No structured location random-effect term matches"
  )
})
