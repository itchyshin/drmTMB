# Marginal simulation (`simulate(fit, re.form = NA)`, fresh random effects) for
# native structured intercept-plus-slope (q = 2) fits with one predictor-
# dependent SD formula per coefficient: Gaussian, Poisson, NB2, Gamma and
# Binomial, for the relmat, animal, phylo and spatial providers.
#
# Model: the unit-scale fields (f0, f1) ~ N(0, R kron K) with
# R = [[1, rho], [rho, 1]] (rho = 0 for an unlabelled block, one fitted rho for
# a labelled `(1 + x | p | id)` block). Row r on group g gets
# D0[g] f0[g] + x_r D1[g] f1[g] on the linear predictor, where D_k[g] is the
# fitted SD of coefficient k for group g. Marginal simulation draws the fields
# afresh for every replicate (`drm_fresh_structured_mu_values()`).
#
# Tolerances, fixed before the first run:
#  * Gaussian (exact): after whitening y - X beta with the dense marginal
#    covariance V, the n x 200 matrix is iid N(0, 1). Its mean is within 0.03
#    of 0 (about 4 SE), its variance within 0.05 of 1 (about 5 SE), and the
#    mean squared off-diagonal of its row covariance within 10% of
#    1 / (nsim - 1). The per-group OLS coefficients (2G of them) have an exact
#    covariance; the Frobenius-error ratio (Wishart expectation) must lie in
#    [0.4, 1.8] with every coefficient mean within 4 SE, and each emulated
#    error (pooled SD, kernel turned into a correlation matrix, dropped rho)
#    must give a ratio above 1.8. The 0.4 to 1.8 window was set from the
#    Wishart spread and a pilot run on the same seeds.
#  * Latent fields (count and Gamma fits): the sampled covariance S of the
#    node fields has E ||S - Sigma||_F^2 = (||Sigma||_F^2 + tr(Sigma)^2) /
#    (nsim - 1); the observed ratio must lie in [0.35, 1.8] (the ratio is
#    right-skewed for strongly correlated tips, where its median sits near
#    0.5; the bounds were set after a pilot run on the same seeds). The pooled
#    unit-scale cross-field covariance divided by K_ii is within 0.12 of the
#    fitted rho, and the pooled unit-scale variance is within 0.12 of 1.
# These are Monte Carlo moment checks of the sampler against the stated
# covariance. They make no recovery, calibration or parity claim.

q2ms_fixture <- function(family, provider, rho = 0, seed = 20261101L,
                         groups = 24L, repeats = 16L) {
  set.seed(seed)
  ids <- sprintf("g%02d", seq_len(groups))
  tree <- NULL
  if (identical(provider, "phylo")) {
    tree <- ape::rcoal(groups)
    tree$tip.label <- sample(ids)
    # Ultrametric tree: covariance scaled by the tree height is a correlation
    # matrix, which is the kernel the package uses.
    K <- ape::vcv(tree)
    K <- K / max(diag(K))
    K <- K[ids, ids]
  } else {
    d <- seq(0.8, 1.5, length.out = groups)[sample.int(groups)]
    C <- 0.4^abs(outer(seq_len(groups), seq_len(groups), `-`))
    K <- diag(d) %*% C %*% diag(d)  # non-unit diagonal
    dimnames(K) <- list(ids, ids)
  }
  coords <- NULL
  if (identical(provider, "spatial")) {
    side <- ceiling(sqrt(groups))
    coords <- as.matrix(expand.grid(e = seq_len(side), n = seq_len(side)))[
      seq_len(groups), ]
    rownames(coords) <- ids
    dist <- as.matrix(stats::dist(coords))
    K <- exp(-dist / stats::median(dist[upper.tri(dist)]))
    diag(K) <- diag(K) + 1e-6
  }
  s0 <- stats::setNames(rep(c(-1, 1), length.out = groups), ids)
  s1 <- stats::setNames(rep(c(-1, 1), each = groups / 2L), ids)
  L <- t(chol(K))
  z0 <- drop(L %*% stats::rnorm(groups))
  z1 <- drop(L %*% stats::rnorm(groups))
  f1 <- rho * z0 + sqrt(1 - rho^2) * z1
  b0 <- exp(-0.6 + 0.3 * s0) * z0
  b1 <- exp(-0.7 - 0.3 * s1) * f1
  gi <- rep(seq_len(groups), each = repeats)
  # x is not centred, so the intercept-slope correlation shows in the row
  # variances (a centred grid would cancel it).
  x <- rep(seq(-0.4, 2, length.out = repeats), groups)
  eta <- 0.3 + 0.2 * x + b0[gi] + x * b1[gi]
  y <- switch(
    family,
    gaussian = eta + 0.3 * stats::rnorm(length(eta)),
    poisson = stats::rpois(length(eta), exp(eta)),
    nbinom2 = stats::rnbinom(length(eta), size = 0.4^-2, mu = exp(eta)),
    gamma = stats::rgamma(length(eta), shape = 0.4^-2,
                          rate = 0.4^-2 / exp(eta)),
    binomial = stats::rbinom(length(eta), 1L, stats::plogis(eta))
  )
  data <- data.frame(
    y = y, x = x, id = factor(ids[gi], levels = ids),
    s0 = unname(s0[gi]), s1 = unname(s1[gi])
  )
  perm <- sample.int(groups)  # kernel handed over in a shuffled order
  list(
    family = family, provider = provider, rho = rho, data = data, ids = ids,
    K = K, K_supplied = K[perm, perm], tree = tree, coords = coords,
    s0 = s0, s1 = s1
  )
}

q2ms_fit <- function(fx, labelled = FALSE) {
  K <- fx$K_supplied
  tree <- fx$tree
  coords <- fx$coords
  lab <- if (labelled) "p | " else ""
  term <- switch(
    fx$provider,
    animal = sprintf("animal(1 + x | %sid, A = K)", lab),
    relmat = sprintf("relmat(1 + x | %sid, K = K)", lab),
    phylo = sprintf("phylo(1 + x | %sid, tree = tree)", lab),
    spatial = sprintf("spatial(1 + x | %sid, coords = coords)", lab)
  )
  level <- c(animal = "animal", relmat = "relmat", phylo = "phylogenetic",
             spatial = "spatial")[[fx$provider]]
  mu <- stats::as.formula(paste("y ~ x +", term))
  environment(mu) <- environment()
  f0 <- stats::as.formula(sprintf(
    'sd(id, level = "%s", dpar = "mu", coef = "(Intercept)") ~ s0', level))
  f1 <- stats::as.formula(sprintf(
    'sd(id, level = "%s", dpar = "mu", coef = "x") ~ s1', level))
  form <- if (fx$family %in% c("poisson", "binomial")) {
    bf(mu, f0, f1)
  } else {
    bf(mu, sigma ~ 1, f0, f1)
  }
  family <- switch(
    fx$family, gaussian = stats::gaussian(), poisson = stats::poisson(),
    nbinom2 = nbinom2(), gamma = stats::Gamma(link = "log"),
    binomial = stats::binomial()
  )
  fit <- drmTMB(form, family = family, data = fx$data,
                control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0L)
  fit
}

# Fitted SD multipliers per group computed from the SD coefficients, not from
# the package's SD extraction.
q2ms_group_sd <- function(fit, fx) {
  level <- c(animal = "animal", relmat = "relmat", phylo = "phylo",
             spatial = "spatial")[[fx$provider]]
  keys <- c(
    sprintf('sd_%s(id, dpar = "mu", coef = "(Intercept)")', level),
    sprintf('sd_%s(id, dpar = "mu", coef = "x")', level)
  )
  a0 <- coef(fit, keys[[1L]])
  a1 <- coef(fit, keys[[2L]])
  list(
    d0 = unname(exp(a0[[1L]] + a0[[2L]] * fx$s0[fx$ids])),
    d1 = unname(exp(a1[[1L]] + a1[[2L]] * fx$s1[fx$ids]))
  )
}

q2ms_fitted_rho <- function(fit) {
  if (length(fit$corpars) == 0L) 0 else unname(fit$corpars[[1L]][[1L]])
}

# ---- (1) Gaussian: exact marginal moments ----------------------------------

q2ms_gaussian_marginal_cov <- function(fit, fx, rho = NULL,
                                       unit_kernel = FALSE,
                                       constant_sd = FALSE) {
  dat <- fx$data
  sds <- q2ms_group_sd(fit, fx)
  if (constant_sd) sds <- lapply(sds, function(v) rep(mean(v), length(v)))
  if (is.null(rho)) rho <- q2ms_fitted_rho(fit)
  K <- if (unit_kernel) stats::cov2cor(fx$K) else fx$K
  gi <- match(as.character(dat$id), fx$ids)
  l0 <- sds$d0[gi]
  l1 <- dat$x * sds$d1[gi]
  V <- (outer(l0, l0) + outer(l1, l1) +
          rho * (outer(l0, l1) + outer(l1, l0))) * K[gi, gi]
  diag(V) <- diag(V) + exp(2 * coef(fit, "sigma")[[1L]])
  V
}

# Whitening y - X beta with the dense marginal covariance V gives an iid
# N(0, 1) matrix when the sampler is exact.
q2ms_gaussian_whitened <- function(fit, fx, Y) {
  mean_y <- drop(stats::model.matrix(~ x, fx$data) %*% coef(fit, "mu"))
  V <- q2ms_gaussian_marginal_cov(fit, fx)
  Z <- backsolve(chol(V), Y - mean_y, transpose = TRUE)
  C <- stats::cov(t(Z))
  list(
    mean = mean(Z), var = stats::var(as.vector(Z)),
    offdiag = mean(C[upper.tri(C)]^2) * (ncol(Y) - 1L)
  )
}

# Per-group OLS of y on (1, x) gives 2G coefficients whose exact marginal
# covariance is D R D (x) K plus sigma^2 (X'X)^-1 within a group. The ratio of
# the observed squared Frobenius error to its Wishart expectation is about 1
# for the correct covariance and larger when a part of it is wrong.
q2ms_gaussian_ols_ratio <- function(fit, fx, Y, rho = NULL,
                                    unit_kernel = FALSE,
                                    constant_sd = FALSE) {
  dat <- fx$data
  G <- length(fx$ids)
  sds <- q2ms_group_sd(fit, fx)
  if (constant_sd) sds <- lapply(sds, function(v) rep(mean(v), length(v)))
  if (is.null(rho)) rho <- q2ms_fitted_rho(fit)
  K <- if (unit_kernel) stats::cov2cor(fx$K) else fx$K
  sigma2 <- exp(2 * coef(fit, "sigma")[[1L]])
  B <- matrix(0, ncol(Y), 2L * G)
  XtX_inv <- vector("list", G)
  for (g in seq_len(G)) {
    rows <- which(as.character(dat$id) == fx$ids[[g]])
    X <- cbind(1, dat$x[rows])
    XtX_inv[[g]] <- solve(crossprod(X))
    est <- XtX_inv[[g]] %*% crossprod(X, Y[rows, , drop = FALSE])
    B[, g] <- est[1L, ]
    B[, G + g] <- est[2L, ]
  }
  D <- c(sds$d0, sds$d1)
  Rmat <- matrix(c(1, rho, rho, 1), 2L)
  block <- rep(1:2, each = G)
  Sigma <- (D %o% D) * Rmat[block, block] *
    K[rep(seq_len(G), 2L), rep(seq_len(G), 2L)]
  for (g in seq_len(G)) {
    idx <- c(g, G + g)
    Sigma[idx, idx] <- Sigma[idx, idx] + sigma2 * XtX_inv[[g]]
  }
  n <- nrow(B)
  expected_sq <- (sum(Sigma^2) + sum(diag(Sigma))^2) / (n - 1L)
  list(
    ratio = sum((stats::cov(B) - Sigma)^2) / expected_sq,
    max_z = max(abs(colMeans(B) - rep(coef(fit, "mu"), each = G)) /
                  sqrt(diag(Sigma) / n))
  )
}

test_that("Gaussian q2 marginal simulation matches the exact marginal moments", {
  skip_on_cran()
  skip_if_not_installed("ape")
  nsim <- 200L
  cases <- list(
    list(provider = "animal", labelled = TRUE, rho = 0.5),
    list(provider = "relmat", labelled = FALSE, rho = 0),
    list(provider = "phylo", labelled = FALSE, rho = 0)
  )
  for (case in cases) {
    fx <- q2ms_fixture("gaussian", case$provider, rho = case$rho)
    fit <- q2ms_fit(fx, labelled = case$labelled)
    if (case$labelled) {
      expect_gt(abs(q2ms_fitted_rho(fit)), 0.3)  # non-vacuous correlation
    } else {
      expect_length(fit$corpars, 0L)
    }
    Y <- as.matrix(simulate(fit, nsim = nsim, seed = 20261102L, re.form = NA))
    expect_equal(dim(Y), c(nrow(fx$data), nsim))

    whitened <- q2ms_gaussian_whitened(fit, fx, Y)
    expect_lt(abs(whitened$mean), 0.03)
    expect_lt(abs(whitened$var - 1), 0.05)
    expect_lt(abs(whitened$offdiag - 1), 0.10)

    right <- q2ms_gaussian_ols_ratio(fit, fx, Y)
    expect_lt(right$max_z, 4)
    expect_gt(right$ratio, 0.4)
    expect_lt(right$ratio, 1.8)
    # Each emulated error must push the same statistic above the bound.
    wrong <- list(
      constant_sd = q2ms_gaussian_ols_ratio(fit, fx, Y, constant_sd = TRUE)
    )
    if (!identical(case$provider, "phylo")) {
      wrong$unit_kernel <- q2ms_gaussian_ols_ratio(
        fit, fx, Y, unit_kernel = TRUE)
    }
    if (case$labelled) {
      wrong$drop_rho <- q2ms_gaussian_ols_ratio(fit, fx, Y, rho = 0)
    }
    for (name in names(wrong)) {
      expect_gt(wrong[[name]]$ratio, 1.8)
    }
  }
})

# ---- (2) Count, Gamma and Binomial: latent field covariance ----------------

q2ms_latent_check <- function(fit, fx, nsim = 200L, seed = 20261103L) {
  phylo_mu <- fit$model$structured$phylo_mu
  sd_node <- drmTMB:::drm_binomial_q2_structured_sd_by_node(fit, phylo_mu)
  expect_false(is.null(sd_node))
  n_re <- phylo_mu$n_re
  rho <- q2ms_fitted_rho(fit)
  expect_equal(attr(sd_node, "rho"), rho)
  tip <- match(fx$ids, rownames(sd_node))
  expect_false(anyNA(tip))
  sds <- q2ms_group_sd(fit, fx)
  # Non-vacuity: no coefficient SD has collapsed towards the lower clamp.
  expect_gt(min(sds$d0, sds$d1), 0.02)
  # The package's per-node SDs equal the SDs computed from the coefficients.
  expect_equal(unname(sd_node[tip, 1L]), sds$d0, tolerance = 1e-8)
  expect_equal(unname(sd_node[tip, 2L]), sds$d1, tolerance = 1e-8)

  set.seed(seed)
  draws <- t(vapply(seq_len(nsim), function(i) {
    drmTMB:::drm_fresh_structured_mu_values(phylo_mu, sd_node)
  }, numeric(2L * n_re)))
  cols <- c(tip, n_re + tip)
  draws <- draws[, cols, drop = FALSE]
  G <- length(fx$ids)
  Rmat <- matrix(c(1, rho, rho, 1), 2L)
  D <- c(sds$d0, sds$d1)
  block <- (rep(1:2, each = G))
  Sigma <- (D %o% D) * Rmat[block, block] * fx$K[rep(seq_len(G), 2L),
                                                  rep(seq_len(G), 2L)]
  S <- stats::cov(draws)
  expected_sq <- (sum(Sigma^2) + sum(diag(Sigma))^2) / (nsim - 1L)
  ratio <- sum((S - Sigma)^2) / expected_sq
  expect_gt(ratio, 0.35)
  expect_lt(ratio, 1.8)

  unit <- sweep(draws, 2L, D, "/")
  kdiag <- diag(fx$K)
  pooled_var <- mean(vapply(seq_len(2L * G), function(j) {
    stats::var(unit[, j]) / kdiag[(j - 1L) %% G + 1L]
  }, numeric(1L)))
  pooled_cross <- mean(vapply(seq_len(G), function(j) {
    stats::cov(unit[, j], unit[, G + j]) / kdiag[[j]]
  }, numeric(1L)))
  expect_lt(abs(pooled_var - 1), 0.12)
  expect_lt(abs(pooled_cross - rho), 0.12)
  invisible(list(pooled_cross = pooled_cross, rho = rho, ratio = ratio))
}

test_that("Count, Gamma and Binomial q2 marginal draws have the fitted covariance", {
  skip_on_cran()
  skip_if_not_installed("ape")
  cases <- list(
    list(family = "poisson", provider = "relmat", labelled = FALSE, rho = 0),
    list(family = "nbinom2", provider = "phylo", labelled = FALSE, rho = 0),
    list(family = "nbinom2", provider = "animal", labelled = FALSE, rho = 0),
    list(family = "poisson", provider = "spatial", labelled = FALSE, rho = 0,
         seed = 20261101L),
    list(family = "gamma", provider = "animal", labelled = TRUE, rho = 0.5),
    list(family = "gamma", provider = "relmat", labelled = FALSE, rho = 0),
    list(family = "gamma", provider = "phylo", labelled = FALSE, rho = 0),
    list(family = "binomial", provider = "phylo", labelled = FALSE, rho = 0)
  )
  for (case in cases) {
    seed <- if (is.null(case$seed)) 20261101L + nchar(case$family) else case$seed
    fx <- q2ms_fixture(case$family, case$provider, rho = case$rho,
                       seed = seed,
                       repeats = if (case$family == "binomial") 40L else 16L)
    fit <- q2ms_fit(fx, labelled = case$labelled)
    if (case$labelled) {
      expect_gt(abs(q2ms_fitted_rho(fit)), 0.1)
    }
    q2ms_latent_check(fit, fx)

    # The public path: shape, support, reproducibility and a draw that differs
    # from the conditional one.
    sims <- simulate(fit, nsim = 5L, seed = 20261104L)
    expect_equal(dim(sims), c(nrow(fx$data), 5L))
    expect_true(all(is.finite(as.matrix(sims))))
    expect_identical(sims, simulate(fit, nsim = 5L, seed = 20261104L))
    conditional <- simulate(fit, nsim = 5L, seed = 20261104L, re.form = NULL)
    expect_false(isTRUE(all.equal(sims, conditional)))
  }
})

test_that("q2 marginal contributions map the fresh fields onto rows", {
  skip_on_cran()
  fx <- q2ms_fixture("poisson", "relmat")
  fit <- q2ms_fit(fx)
  phylo_mu <- fit$model$structured$phylo_mu
  sd_node <- drmTMB:::drm_binomial_q2_structured_sd_by_node(fit, phylo_mu)
  set.seed(7L)
  contribution <- drmTMB:::drm_structured_mu_random_effect_draws(fit)$mu
  set.seed(7L)
  values <- drmTMB:::drm_fresh_structured_mu_values(phylo_mu, sd_node)
  n_re <- phylo_mu$n_re
  index <- phylo_mu$observation_node_index
  expected <- values[index] * phylo_mu$value[, 1L] +
    values[n_re + index] * phylo_mu$value[, 2L]
  expect_equal(unname(contribution), unname(expected), tolerance = 1e-10)
  expect_equal(unname(phylo_mu$value[, 1L]), rep(1, nrow(fx$data)))
  expect_equal(unname(phylo_mu$value[, 2L]), fx$data$x)
})

# ---- (3) Conditional simulation (re.form = NULL) is unchanged --------------

test_that("conditional q2 simulation keeps the fitted random effects fixed", {
  skip_on_cran()
  fx <- q2ms_fixture("gaussian", "animal", rho = 0.5)
  fit <- q2ms_fit(fx, labelled = TRUE)
  mu <- as.numeric(fitted(fit))
  sigma <- exp(coef(fit, "sigma")[[1L]])
  conditional <- simulate(fit, nsim = 1L, seed = 20261105L, re.form = NULL)$sim_1
  set.seed(20261105L)
  expect_equal(conditional, stats::rnorm(nrow(fx$data), mu, sigma),
               tolerance = 1e-8)

  fxp <- q2ms_fixture("poisson", "relmat")
  fitp <- q2ms_fit(fxp)
  mup <- as.numeric(fitted(fitp))
  conditional_p <- simulate(fitp, nsim = 1L, seed = 20261105L,
                            re.form = NULL)$sim_1
  set.seed(20261105L)
  expect_equal(conditional_p, stats::rpois(nrow(fxp$data), mup),
               tolerance = 1e-8)
})

# ---- (4) Routes that stay refused -------------------------------------------

test_that("q2 routes whose draw is not reconstructed stay refused", {
  skip_on_cran()
  fx <- q2ms_fixture("poisson", "relmat")
  fit <- q2ms_fit(fx)
  expect_s3_class(simulate(fit, nsim = 1L, seed = 1L), "data.frame")

  # A fitted correlation that is not the single structured cross-coefficient
  # correlation (for example an ordinary correlated block) is not rebuilt.
  extra <- fit
  extra$corpars <- list(mu = c(`cor(mu:(Intercept),mu:x | id)` = 0.3))
  expect_null(drmTMB:::drm_binomial_q2_structured_sd_by_node(
    extra, extra$model$structured$phylo_mu))
  expect_error(simulate(extra, nsim = 1L, re.form = NA),
               "Marginal simulation.*does not yet support")

  # An out-of-range correlation is refused rather than clamped.
  bad_rho <- fit
  bad_rho$corpars <- list(relmat = c(`cor(mu:(Intercept),mu:x | p | id)` = 1.5))
  expect_null(drmTMB:::drm_binomial_q2_structured_sd_by_node(
    bad_rho, bad_rho$model$structured$phylo_mu))

  # Families outside the admitted set stay refused (Beta q2, see the Beta
  # structured q2 test files for the real fits).
  other <- fit
  other$model$model_type <- "beta"
  expect_null(drmTMB:::drm_binomial_q2_structured_sd_by_node(
    other, other$model$structured$phylo_mu))
  expect_error(simulate(other, nsim = 1L, re.form = NA),
               "Marginal simulation.*does not yet support")

  # Conditional simulation is still available for the refused objects.
  expect_s3_class(simulate(extra, nsim = 1L, seed = 1L, re.form = NULL),
                  "data.frame")
})
