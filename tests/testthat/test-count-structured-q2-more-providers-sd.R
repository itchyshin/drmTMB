# Poisson and NB2 structured intercept-plus-slope (q = 2) with one
# predictor-dependent SD formula per coefficient, for the relmat (K and Q),
# phylo (tree) and spatial (coordinate kernel) providers. The animal provider
# is covered by test-poisson-structured-q2-sd-regression.R and
# test-nbinom2-structured-q2-sd-regression.R.
#
# Oracle: a dense Laplace marginal likelihood computed in plain R at the fitted
# parameters. It uses a dense kernel K built independently in this file (never
# the package's precision matrix or log-determinant), a dnbinom/dpois data
# term and analytic dense Hessians. The latent vector u = (u0, u1) is the
# unit-scale field with prior blockdiag(K, K); the coefficient SDs scale it
# multiplicatively. Laplace is invariant to that linear reparameterisation.
# Tolerances fixed before the first run: 1e-4 absolute for oracle agreement,
# 1e-5 for constant-SD equivalence of log-likelihoods, and 1 log-likelihood
# unit for the emulated-bug sensitivity checks. This is a likelihood-evaluation
# check, not a recovery, calibration or parity claim.

more_q2_kernel <- function(provider, groups = 36L) {
  ids <- sprintf("g%02d", seq_len(groups))
  if (provider == "relmat") {
    C <- outer(seq_len(groups), seq_len(groups), function(i, j) 0.35^abs(i - j))
    d <- seq(0.8, 1.6, length.out = groups)[sample.int(groups)]
    K <- diag(d) %*% C %*% diag(d)  # non-unit diagonal
    dimnames(K) <- list(ids, ids)
    return(list(ids = ids, K = K))
  }
  if (provider == "phylo") {
    tree <- ape::rcoal(groups)
    tree$tip.label <- sample(ids)
    # Independent standardisation: covariance divided by the tree height.
    K <- ape::vcv(tree)
    K <- K / max(diag(K))
    K <- K[ids, ids]
    return(list(ids = ids, K = K, tree = tree))
  }
  side <- ceiling(sqrt(groups))
  coords <- as.matrix(expand.grid(easting = seq_len(side),
                                  northing = seq_len(side)))[seq_len(groups), ]
  rownames(coords) <- ids
  distance <- as.matrix(stats::dist(coords))
  range <- stats::median(distance[upper.tri(distance)])
  K <- exp(-distance / range)
  diag(K) <- diag(K) + 1e-6
  list(ids = ids, K = K, coords = coords, range = range)
}

more_q2_fixture <- function(provider, family, seed, groups = 36L,
                            repeats = 16L) {
  set.seed(seed)
  kern <- more_q2_kernel(provider, groups)
  ids <- kern$ids
  K <- kern$K
  w <- stats::setNames(sample(rep(c(-1, 1), length.out = groups)), ids)
  v <- stats::setNames(sample(rep(c(-1, 1), each = groups / 2L)), ids)
  s0 <- exp(-1.0 + 0.8 * w)
  s1 <- exp(-1.0 - 0.8 * v)
  L <- t(chol(K))
  b0 <- s0 * drop(L %*% stats::rnorm(groups))
  b1 <- s1 * drop(L %*% stats::rnorm(groups))
  id <- factor(rep(ids, each = repeats), levels = sample(ids))
  x <- rep(seq(-1.2, 1.2, length.out = repeats), times = groups)
  eta <- 0.8 + 0.25 * x + b0[as.character(id)] + b1[as.character(id)] * x
  y <- if (family == "poisson") {
    stats::rpois(length(eta), exp(eta))
  } else {
    stats::rnbinom(length(eta), size = 0.4^-2, mu = exp(eta))
  }
  data <- data.frame(
    y = y, x = x, id = id,
    w = unname(w[as.character(id)]), v = unname(v[as.character(id)])
  )
  # The kernel handed to the package is shuffled relative to both the data
  # factor levels and the natural order, so alignment must be by name.
  shuffled <- sample(ids)
  supplied <- list(
    K = K[shuffled, shuffled],
    coords = kern$coords[shuffled, , drop = FALSE],
    tree = kern$tree
  )
  list(provider = provider, family = family, data = data, K = K,
       supplied = supplied, w = w, v = v)
}

more_q2_family <- function(family) {
  if (family == "poisson") stats::poisson() else nbinom2()
}

more_q2_level <- function(provider) {
  c(relmat = "relmat", phylo = "phylogenetic", spatial = "spatial")[[provider]]
}

more_q2_prefix <- function(provider) {
  c(relmat = "sd_relmat", phylo = "sd_phylo", spatial = "sd_spatial")[[provider]]
}

more_q2_formula <- function(fx, constant = FALSE, reverse = FALSE,
                            use_Q = FALSE) {
  K <- fx$supplied$K
  Q <- solve(K)
  coords <- fx$supplied$coords
  tree <- fx$supplied$tree
  term <- switch(
    fx$provider,
    relmat = if (use_Q) "relmat(1 + x | id, Q = Q)" else
      "relmat(1 + x | id, K = K)",
    phylo = "phylo(1 + x | id, tree = tree)",
    spatial = "spatial(1 + x | id, coords = coords)"
  )
  mu <- stats::as.formula(paste("y ~ x +", term))
  environment(mu) <- environment()
  level <- more_q2_level(fx$provider)
  f0 <- stats::as.formula(sprintf(
    'sd(id, level = "%s", dpar = "mu", coef = "(Intercept)") ~ %s',
    level, if (constant) "1" else "w"
  ), env = environment())
  f1 <- stats::as.formula(sprintf(
    'sd(id, level = "%s", dpar = "mu", coef = "x") ~ %s',
    level, if (constant) "1" else "v"
  ), env = environment())
  sds <- if (reverse) list(f1, f0) else list(f0, f1)
  if (fx$family == "poisson") {
    do.call(bf, c(list(mu), sds))
  } else {
    do.call(bf, c(list(mu, sigma ~ 1), sds))
  }
}

more_q2_fit <- function(fx, ...) {
  drmTMB(more_q2_formula(fx, ...), family = more_q2_family(fx$family),
         data = fx$data, control = drm_control(se = FALSE))
}

more_q2_free_fit <- function(fx) {
  K <- fx$supplied$K
  coords <- fx$supplied$coords
  tree <- fx$supplied$tree
  term <- switch(
    fx$provider,
    relmat = "relmat(1 + x | id, K = K)",
    phylo = "phylo(1 + x | id, tree = tree)",
    spatial = "spatial(1 + x | id, coords = coords)"
  )
  mu <- stats::as.formula(paste("y ~ x +", term))
  environment(mu) <- environment()
  f <- if (fx$family == "poisson") bf(mu) else bf(mu, sigma ~ 1)
  drmTMB(f, family = more_q2_family(fx$family), data = fx$data,
         control = drm_control(se = FALSE))
}

more_q2_sds <- function(fit, fx) {
  prefix <- more_q2_prefix(fx$provider)
  key0 <- sprintf('%s(id, dpar = "mu", coef = "(Intercept)")', prefix)
  key1 <- sprintf('%s(id, dpar = "mu", coef = "x")', prefix)
  b0 <- coef(fit, key0)
  b1 <- coef(fit, key1)
  ids <- levels(fx$data$id)
  list(
    s0 = unname(exp(b0[["(Intercept)"]] + b0[["w"]] * fx$w[ids])),
    s1 = unname(exp(b1[["(Intercept)"]] + b1[["v"]] * fx$v[ids])),
    b0 = b0, b1 = b1, keys = c(key0, key1)
  )
}

# Dense Laplace marginal log-likelihood. `K` must be aligned to levels(id).
more_q2_oracle <- function(fx, K, beta, s0, s1, size = NULL) {
  data <- fx$data
  G <- nlevels(data$id)
  gi <- as.integer(data$id)
  y <- data$y
  Zg <- outer(gi, seq_len(G), function(i, g) as.numeric(i == g))
  Z <- cbind(Zg %*% diag(s0), (Zg * data$x) %*% diag(s1))
  offset <- beta[[1L]] + beta[[2L]] * data$x
  Pa <- solve(K)
  P <- matrix(0, 2L * G, 2L * G)
  P[seq_len(G), seq_len(G)] <- Pa
  P[G + seq_len(G), G + seq_len(G)] <- Pa
  logdet_prior <- 2 * as.numeric(determinant(K, logarithm = TRUE)$modulus)
  loglik <- function(eta) {
    if (fx$family == "poisson") {
      sum(stats::dpois(y, exp(eta), log = TRUE))
    } else {
      sum(stats::dnbinom(y, size = size, mu = exp(eta), log = TRUE))
    }
  }
  score <- function(eta) {
    mu <- exp(eta)
    if (fx$family == "poisson") y - mu else size * (y - mu) / (mu + size)
  }
  weight <- function(eta) {
    mu <- exp(eta)
    if (fx$family == "poisson") mu else (y + size) * mu * size / (mu + size)^2
  }
  joint <- function(u) {
    loglik(offset + drop(Z %*% u)) - 0.5 * drop(t(u) %*% P %*% u)
  }
  u <- rep(0, 2L * G)
  for (iter in 1:300) {
    eta <- offset + drop(Z %*% u)
    grad <- drop(crossprod(Z, score(eta))) - drop(P %*% u)
    H <- crossprod(Z, weight(eta) * Z) + P
    step <- drop(solve(H, grad))
    f0 <- joint(u)
    scale <- 1
    while (joint(u + scale * step) < f0 && scale > 1e-12) scale <- scale / 2
    u <- u + scale * step
    if (max(abs(scale * step)) < 1e-11) break
  }
  eta <- offset + drop(Z %*% u)
  H <- crossprod(Z, weight(eta) * Z) + P
  joint(u) - 0.5 * logdet_prior -
    0.5 * as.numeric(determinant(H, logarithm = TRUE)$modulus)
}

more_q2_fit_cache <- new.env(parent = emptyenv())
more_q2_cached <- function(provider, family, seed) {
  key <- paste(provider, family, seed)
  if (is.null(more_q2_fit_cache[[key]])) {
    fx <- more_q2_fixture(provider, family, seed)
    more_q2_fit_cache[[key]] <- list(fx = fx, fit = more_q2_fit(fx))
  }
  more_q2_fit_cache[[key]]
}

more_q2_check_oracle <- function(provider, family, seed) {
  cached <- more_q2_cached(provider, family, seed)
  fx <- cached$fx
  fit <- cached$fit
  expect_equal(fit$opt$convergence, 0L)
  sds <- more_q2_sds(fit, fx)
  # Two distinct SD surfaces, one per coefficient.
  expect_gt(stats::sd(log(sds$s0)), 0.1)
  expect_gt(stats::sd(log(sds$s1)), 0.1)
  expect_named(sds$b0, c("(Intercept)", "w"))
  expect_named(sds$b1, c("(Intercept)", "v"))
  ids <- levels(fx$data$id)
  K <- fx$K[ids, ids]
  beta <- coef(fit, "mu")
  size <- if (family == "nbinom2") exp(-2 * coef(fit, "sigma")[[1L]]) else NULL
  reference <- more_q2_oracle(fx, K, beta, sds$s0, sds$s1, size)
  expect_lt(abs(as.numeric(logLik(fit)) - reference), 1e-4)

  # Emulated bugs must move the oracle by far more than the tolerance.
  swapped <- more_q2_oracle(fx, K, beta, sds$s1, sds$s0, size)
  shift <- function(z) z[c(length(z), seq_len(length(z) - 1L))]
  shifted <- more_q2_oracle(fx, K, beta, shift(sds$s0), shift(sds$s1), size)
  unaligned <- more_q2_oracle(fx, unname(fx$supplied$K), beta,
                              sds$s0, sds$s1, size)
  one_sd_for_both <- more_q2_oracle(fx, K, beta, sds$s0, sds$s0, size)
  expect_gt(abs(swapped - reference), 1)
  expect_gt(abs(shifted - reference), 1)
  expect_gt(abs(unaligned - reference), 1)
  expect_gt(abs(one_sd_for_both - reference), 1)
}

test_that("Poisson relmat q2 SD regression matches a dense Laplace oracle", {
  skip_on_cran()
  for (seed in c(20261111L, 20261112L)) more_q2_check_oracle("relmat", "poisson", seed)
})

test_that("Poisson phylo q2 SD regression matches a dense Laplace oracle", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (seed in c(20261111L, 20261112L)) more_q2_check_oracle("phylo", "poisson", seed)
})

test_that("Poisson spatial q2 SD regression matches a dense Laplace oracle", {
  skip_on_cran()
  for (seed in c(20261111L, 20261112L)) more_q2_check_oracle("spatial", "poisson", seed)
})

test_that("NB2 relmat q2 SD regression matches a dense Laplace oracle", {
  skip_on_cran()
  for (seed in c(20261111L, 20261112L)) more_q2_check_oracle("relmat", "nbinom2", seed)
})

test_that("NB2 phylo q2 SD regression matches a dense Laplace oracle", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (seed in c(20261111L, 20261112L)) more_q2_check_oracle("phylo", "nbinom2", seed)
})

test_that("NB2 spatial q2 SD regression matches a dense Laplace oracle", {
  skip_on_cran()
  for (seed in c(20261111L, 20261112L)) more_q2_check_oracle("spatial", "nbinom2", seed)
})

test_that("the independent phylo kernel equals the package's tip covariance", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- more_q2_cached("phylo", "poisson", 20261111L)$fx
  pr <- more_q2_cached("phylo", "poisson", 20261111L)$fit$model$structured$phylo_mu$precision
  covariance <- solve(as.matrix(pr$precision))
  tip <- unname(pr$tip_node_index[rownames(fx$K)])
  expect_equal(unname(covariance[tip, tip]), unname(fx$K), tolerance = 1e-8)
})

test_that("relmat Q and K inputs and SD order give the same q2 SD fit", {
  skip_on_cran()
  for (family in c("poisson", "nbinom2")) {
    cached <- more_q2_cached("relmat", family, 20261111L)
    fx <- cached$fx
    fit <- cached$fit
    for (other in list(more_q2_fit(fx, use_Q = TRUE),
                       more_q2_fit(fx, reverse = TRUE))) {
      expect_equal(other$opt$convergence, 0L)
      expect_lt(abs(as.numeric(logLik(other)) - as.numeric(logLik(fit))), 1e-4)
    }
  }
})

test_that("constant coefficient SD formulas match the formula-free q2 fit", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (provider in c("relmat", "phylo", "spatial")) {
    for (family in c("poisson", "nbinom2")) {
      fx <- more_q2_fixture(provider, family, 20261111L)
      constant_fit <- more_q2_fit(fx, constant = TRUE)
      free_fit <- more_q2_free_fit(fx)
      expect_equal(constant_fit$opt$convergence, 0L)
      expect_equal(free_fit$opt$convergence, 0L)
      expect_lt(abs(as.numeric(logLik(constant_fit)) -
                      as.numeric(logLik(free_fit))), 1e-5)
    }
  }
})

test_that("q2 SD regression reports SDs per coefficient and group", {
  skip_on_cran()
  for (family in c("poisson", "nbinom2")) {
    cached <- more_q2_cached("relmat", family, 20261111L)
    fx <- cached$fx
    fit <- cached$fit
    sds <- more_q2_sds(fit, fx)
    p0 <- predict(fit, dpar = sds$keys[[1L]])
    p1 <- predict(fit, dpar = sds$keys[[2L]])
    ids <- levels(fx$data$id)
    expect_setequal(names(p0), ids)
    expect_equal(unname(p0[ids]), sds$s0, tolerance = 1e-6)
    expect_equal(unname(p1[ids]), sds$s1, tolerance = 1e-6)
    simulated <- simulate(fit, nsim = 1L, seed = 20261114L, re.form = NULL)
    expect_length(simulated[[1L]], nrow(fx$data))
    expect_true(all(is.finite(simulated[[1L]])))
  }
})

test_that("neighbouring count q2 SD routes stay refused with designed errors", {
  skip_on_cran()
  fx <- more_q2_fixture("relmat", "poisson", 20261111L)
  K <- fx$supplied$K
  d <- fx$data
  sd_int <- sd(id, level = "relmat", dpar = "mu", coef = "(Intercept)") ~ w
  sd_x <- sd(id, level = "relmat", dpar = "mu", coef = "x") ~ v

  # Only one of the two coefficients gets an SD formula.
  expect_error(
    drmTMB(bf(y ~ x + relmat(1 + x | id, K = K), sd_int),
           family = stats::poisson(), data = d),
    "requires\\s+one\\s+SD\\s+formula\\s+for\\s+each\\s+coefficient"
  )
  expect_error(
    drmTMB(bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1, sd_x),
           family = nbinom2(), data = d),
    "intercept\\s+plus\\s+one\\s+slope\\s+with\\s+one\\s+SD\\s+formula\\s+per\\s+coefficient|requires\\s+one\\s+SD\\s+formula\\s+for\\s+each\\s+coefficient"
  )

  # Labelled covariance block with coefficient SDs on a non-animal provider.
  expect_error(
    drmTMB(bf(y ~ x + relmat(1 + x | p | id, K = K), sd_int, sd_x),
           family = stats::poisson(), data = d),
    "require\\s+one\\s+structured\\s+coefficient"
  )
  expect_error(
    drmTMB(bf(y ~ x + relmat(1 + x | p | id, K = K), sigma ~ 1, sd_int, sd_x),
           family = nbinom2(), data = d),
    "only\\s+the\\s+implemented\\s+labelled\\s+covariance\\s+forms"
  )

  # Ordinary random effect beside the relmat q2 block.
  expect_error(
    drmTMB(bf(y ~ x + relmat(1 + x | id, K = K) + (1 | id),
              sd_int, sd_x),
           family = stats::poisson(), data = d),
    "non-inflated\\s+model\\s+with\\s+complete\\s+responses|cannot\\s+be\\s+combined"
  )

  # Zero-inflated and missing-response variants keep the complete-data gate.
  expect_error(
    drmTMB(bf(y ~ x + relmat(1 + x | id, K = K), zi ~ 1, sd_int, sd_x),
           family = stats::poisson(), data = d),
    "non-inflated\\s+model\\s+with\\s+complete\\s+responses"
  )
  expect_error(
    drmTMB(bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1, zi ~ 1,
              sd_int, sd_x),
           family = nbinom2(), data = d),
    "implemented\\s+only\\s+for\\s+ordinary\\s+NB2\\s+models"
  )
  d_miss <- d
  d_miss$y[c(3L, 40L)] <- NA
  expect_error(
    drmTMB(bf(y ~ x + relmat(1 + x | id, K = K), sd_int, sd_x),
           family = stats::poisson(), data = d_miss,
           missing = miss_control(response = "include")),
    "non-inflated\\s+model\\s+with\\s+complete\\s+responses"
  )
})
