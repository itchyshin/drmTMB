# NB2 labelled phylogenetic intercept-plus-slope (q = 2) with one
# predictor-dependent SD formula per coefficient: phylo(1 + x | p | id, tree).
#
# Meaning of the label. Inside one `mu` formula the unlabelled
# phylo(1 + x | id, tree) block has two independent unit-scale latent fields
# (rho = 0). The labelled block phylo(1 + x | p | id, tree) adds one
# cross-coefficient correlation rho, so the latent prior is R kron K with
# R = [1 rho; rho 1] and K = cov2cor(ape::vcv(tree)). The C++ NB2 template
# already carries this prior (shared with NB2 animal and relmat); batch 32 only
# opened the R-side gate for the phylo provider.
#
# Oracle: a dense Laplace marginal likelihood in plain base R evaluated at the
# fitted parameters INCLUDING the fitted rho. The kernel is built here from
# ape::vcv (never from the package's tree precision or tip-covariance helper);
# the package helper is only compared against it. The unit-scale latent vector
# u = (u0, u1) has prior covariance R kron K; each coefficient SD scales its
# field, and Laplace is invariant to that linear reparameterisation.
# Tolerances fixed before the first run: 1e-4 absolute for oracle agreement,
# 1e-6 for nesting, 0.1 log-likelihood units as the floor for emulated bugs.
# This is a likelihood-evaluation check, not a recovery or calibration claim.

nb2p_fixture <- function(rho = 0.8, seed = 20261131L, groups = 60L,
                         repeats = 16L) {
  set.seed(seed)
  ids <- sprintf("g%02d", seq_len(groups))
  tree <- ape::rcoal(groups)
  tree$tip.label <- sample(ids)  # tree tip order differs from levels(id)
  Kfull <- stats::cov2cor(ape::vcv(tree))
  K <- Kfull[ids, ids]
  w <- stats::setNames(sample(rep(c(-1, 1), length.out = groups)), ids)
  v <- stats::setNames(sample(rep(c(-1, 1), each = groups / 2L)), ids)
  s0 <- exp(-1.0 + 0.8 * w)
  s1 <- exp(-1.0 - 0.8 * v)
  L <- t(chol(K))
  z0 <- stats::rnorm(groups)
  z1 <- stats::rnorm(groups)
  b0 <- s0 * drop(L %*% z0)
  b1 <- s1 * drop(L %*% (rho * z0 + sqrt(1 - rho^2) * z1))
  id <- factor(rep(ids, each = repeats), levels = sample(ids))
  x <- rep(seq(-1.2, 1.2, length.out = repeats), times = groups)
  eta <- 0.8 + 0.25 * x + b0[as.character(id)] + b1[as.character(id)] * x
  y <- stats::rnbinom(length(eta), size = 0.4^-2, mu = exp(eta))
  data <- data.frame(
    y = y, x = x, id = id,
    w = unname(w[as.character(id)]), v = unname(v[as.character(id)])
  )
  list(data = data, tree = tree, K = K, w = w, v = v, ids = ids)
}

nb2p_formula <- function(fx, label = "p", constant = FALSE, only = NULL,
                         swap = FALSE) {
  tree <- fx$tree
  bar <- if (is.null(label)) "1 + x | id" else paste0("1 + x | ", label, " | id")
  mu <- stats::as.formula(sprintf("y ~ x + phylo(%s, tree = tree)", bar))
  environment(mu) <- environment()
  rhs0 <- if (constant) "1" else if (swap) "v" else "w"
  rhs1 <- if (constant) "1" else if (swap) "w" else "v"
  f0 <- stats::as.formula(sprintf(
    'sd(id, level = "phylogenetic", dpar = "mu", coef = "(Intercept)") ~ %s',
    rhs0), env = environment())
  f1 <- stats::as.formula(sprintf(
    'sd(id, level = "phylogenetic", dpar = "mu", coef = "x") ~ %s', rhs1),
    env = environment())
  sds <- list(f0, f1)
  if (identical(only, "intercept")) sds <- sds[1L]
  if (identical(only, "slope")) sds <- sds[2L]
  do.call(bf, c(list(mu, sigma ~ 1), sds))
}

nb2p_fit <- function(fx, ...) {
  drmTMB(nb2p_formula(fx, ...), family = nbinom2(), data = fx$data,
         control = drm_control(se = FALSE))
}

nb2p_keys <- c('sd_phylo(id, dpar = "mu", coef = "(Intercept)")',
               'sd_phylo(id, dpar = "mu", coef = "x")')

nb2p_sds <- function(fit, fx) {
  b0 <- coef(fit, nb2p_keys[[1L]])
  b1 <- coef(fit, nb2p_keys[[2L]])
  list(
    s0 = unname(exp(b0[["(Intercept)"]] + b0[["w"]] * fx$w[fx$ids])),
    s1 = unname(exp(b1[["(Intercept)"]] + b1[["v"]] * fx$v[fx$ids])),
    b0 = b0, b1 = b1
  )
}

# Dense Laplace marginal log-likelihood. `K` must be aligned to `ids`, and the
# group order below follows `ids` (the sorted label order, not levels(id)).
nb2p_oracle <- function(fx, K, beta, s0, s1, size, rho) {
  data <- fx$data
  ids <- fx$ids
  G <- length(ids)
  gi <- match(as.character(data$id), ids)
  y <- data$y
  Zg <- outer(gi, seq_len(G), function(i, g) as.numeric(i == g))
  Z <- cbind(Zg %*% diag(s0), (Zg * data$x) %*% diag(s1))
  offset <- beta[[1L]] + beta[[2L]] * data$x
  R <- matrix(c(1, rho, rho, 1), 2L, 2L)
  P <- kronecker(solve(R), solve(K))
  logdet_prior <- G * log(det(R)) +
    2 * as.numeric(determinant(K, logarithm = TRUE)$modulus)
  loglik <- function(eta) {
    sum(stats::dnbinom(y, size = size, mu = exp(eta), log = TRUE))
  }
  score <- function(eta) {
    mu <- exp(eta)
    size * (y - mu) / (mu + size)
  }
  weight <- function(eta) {
    mu <- exp(eta)
    (y + size) * mu * size / (mu + size)^2
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

nb2p_rho <- function(fit) {
  rho <- fit$obj$report(fit$obj$env$last.par.best)$rho_phylo
  stopifnot(length(rho) == 1L)
  unname(rho)
}

nb2p_cache <- new.env(parent = emptyenv())
nb2p_cached <- function(rho = 0.8, seed = 20261131L) {
  key <- paste(rho, seed)
  if (is.null(nb2p_cache[[key]])) {
    fx <- nb2p_fixture(rho = rho, seed = seed)
    nb2p_cache[[key]] <- list(fx = fx, labelled = nb2p_fit(fx))
  }
  nb2p_cache[[key]]
}

test_that("hand kernel equals the package tip-covariance helper", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- nb2p_fixture()
  helper <- drmTMB:::drm_phylo_tip_covariance(fx$tree)
  expect_equal(unname(helper[fx$ids, fx$ids]), unname(fx$K), tolerance = 1e-8)
  # The kernel is a genuine correlation matrix and not palindromic in sd.
  expect_equal(unname(diag(fx$K)), rep(1, length(fx$ids)))
  expect_false(isTRUE(all.equal(unname(fx$w), rev(unname(fx$w)))))
  expect_false(isTRUE(all.equal(unname(fx$v), rev(unname(fx$v)))))
  expect_false(identical(fx$tree$tip.label, fx$ids))
  expect_false(identical(levels(fx$data$id), fx$ids))
})

test_that("labelled NB2 phylo q2 SD fits match a dense Laplace oracle with rho", {
  skip_on_cran()
  skip_if_not_installed("ape")
  gaps <- numeric()
  bug_gaps <- numeric()
  for (seed in c(20261131L, 20261132L)) {
    cached <- nb2p_cached(seed = seed)
    fx <- cached$fx
    fit <- cached$labelled
    expect_equal(fit$opt$convergence, 0L)
    sds <- nb2p_sds(fit, fx)
    expect_gt(stats::sd(log(sds$s0)), 0.1)
    expect_gt(stats::sd(log(sds$s1)), 0.1)
    expect_named(sds$b0, c("(Intercept)", "w"))
    expect_named(sds$b1, c("(Intercept)", "v"))
    beta <- coef(fit, "mu")
    size <- exp(-2 * coef(fit, "sigma")[[1L]])
    rho <- nb2p_rho(fit)
    expect_gt(abs(rho), 0.05)
    reference <- nb2p_oracle(fx, fx$K, beta, sds$s0, sds$s1, size, rho)
    gap <- abs(as.numeric(logLik(fit)) - reference)
    gaps <- c(gaps, gap)
    expect_lt(gap, 1e-4)

    # Emulated bugs must move the oracle by far more than the tolerance.
    raw_vcv <- ape::vcv(fx$tree)[fx$ids, fx$ids]
    bugs <- c(
      swapped_sd_formulas = nb2p_oracle(fx, fx$K, beta, sds$s1, sds$s0, size, rho),
      reversed_sd_vector = nb2p_oracle(fx, fx$K, beta, rev(sds$s0), rev(sds$s1),
                                       size, rho),
      rho_dropped = nb2p_oracle(fx, fx$K, beta, sds$s0, sds$s1, size, 0),
      rho_sign_flipped = nb2p_oracle(fx, fx$K, beta, sds$s0, sds$s1, size, -rho),
      raw_vcv_not_correlation = nb2p_oracle(fx, raw_vcv, beta, sds$s0, sds$s1,
                                            size, rho),
      kernel_by_level_position = nb2p_oracle(
        fx, unname(fx$K[levels(fx$data$id), levels(fx$data$id)]), beta,
        sds$s0, sds$s1, size, rho),
      kernel_in_tree_tip_order = nb2p_oracle(
        fx, unname(stats::cov2cor(ape::vcv(fx$tree))), beta, sds$s0, sds$s1,
        size, rho)
    )
    for (nm in names(bugs)) {
      expect_gt(abs(bugs[[nm]] - reference), 0.1)
      bug_gaps <- c(bug_gaps, stats::setNames(abs(bugs[[nm]] - reference), nm))
    }
  }
  message("b32 NB2 phylo oracle gaps: ", paste(signif(gaps, 3), collapse = ", "))
  message("b32 smallest emulated-bug gap: ", names(which.min(bug_gaps)), " ", signif(min(bug_gaps), 3))
})

test_that("swapped SD formulas in the call are detected by the oracle", {
  skip_on_cran()
  skip_if_not_installed("ape")
  cached <- nb2p_cached()
  fx <- cached$fx
  swapped <- nb2p_fit(fx, swap = TRUE)
  expect_equal(swapped$opt$convergence, 0L)
  # Fitting with the predictors the wrong way round is a different model, and
  # its likelihood differs from the correctly specified fit by far more than
  # the 1e-4 oracle tolerance.
  expect_gt(abs(as.numeric(logLik(swapped)) - as.numeric(logLik(cached$labelled))),
            0.1)
})

test_that("labelled NB2 phylo q2 estimates a correlation that moves with the data", {
  skip_on_cran()
  skip_if_not_installed("ape")
  cached <- nb2p_cached()
  labelled <- cached$labelled
  unlabelled <- nb2p_fit(cached$fx, label = NULL)
  expect_equal(unlabelled$opt$convergence, 0L)
  key <- "cor(mu:(Intercept),mu:x | p | id)"
  expect_named(labelled$corpars$phylo, key)
  rho_hat <- unname(labelled$corpars$phylo[[key]])
  expect_true(is.finite(rho_hat))
  expect_lt(abs(rho_hat), 1)
  expect_equal(nb2p_rho(labelled), rho_hat, tolerance = 1e-8)
  expect_null(unlabelled$corpars$phylo)
  # Nested: the unlabelled fit is the rho = 0 special case.
  expect_gte(as.numeric(logLik(labelled)), as.numeric(logLik(unlabelled)) - 1e-6)
  expect_equal(names(coef(labelled)), names(coef(unlabelled)))
  # The label name is arbitrary.
  renamed <- nb2p_fit(cached$fx, label = "q")
  expect_equal(as.numeric(logLik(renamed)), as.numeric(logLik(labelled)),
               tolerance = 1e-6)
  expect_named(renamed$corpars$phylo, "cor(mu:(Intercept),mu:x | q | id)")
  # Same design, data simulated with the opposite true rho (-0.8): the estimate moves.
  opposite <- nb2p_cached(rho = -0.8)
  rho_other <- unname(opposite$labelled$corpars$phylo[[key]])
  expect_gt(rho_hat - rho_other, 0.4)
})

test_that("constant coefficient SDs reduce to the labelled block with fitted rho", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- nb2p_cached()$fx
  fit <- nb2p_fit(fx, constant = TRUE)
  expect_equal(fit$opt$convergence, 0L)
  b0 <- coef(fit, nb2p_keys[[1L]])
  b1 <- coef(fit, nb2p_keys[[2L]])
  expect_length(b0, 1L)
  expect_length(b1, 1L)
  G <- length(fx$ids)
  reference <- nb2p_oracle(
    fx, fx$K, coef(fit, "mu"), rep(exp(unname(b0)), G), rep(exp(unname(b1)), G),
    exp(-2 * coef(fit, "sigma")[[1L]]), nb2p_rho(fit))
  expect_lt(abs(as.numeric(logLik(fit)) - reference), 1e-4)
})

test_that("labelled NB2 phylo q2 reports SDs, predicts, and simulates marginally", {
  skip_on_cran()
  skip_if_not_installed("ape")
  cached <- nb2p_cached()
  fx <- cached$fx
  fit <- cached$labelled
  sds <- nb2p_sds(fit, fx)
  p0 <- predict(fit, dpar = nb2p_keys[[1L]])
  p1 <- predict(fit, dpar = nb2p_keys[[2L]])
  expect_setequal(names(p0), fx$ids)
  expect_equal(unname(p0[fx$ids]), sds$s0, tolerance = 1e-6)
  expect_equal(unname(p1[fx$ids]), sds$s1, tolerance = 1e-6)

  # Marginal draws of the unit-scale fields carry the fitted correlation.
  phylo_mu <- fit$model$structured$phylo_mu
  sd_node <- drmTMB:::drm_binomial_q2_structured_sd_by_node(fit, phylo_mu)
  expect_false(is.null(sd_node))
  rho <- unname(fit$corpars$phylo[[1L]])
  expect_equal(attr(sd_node, "rho"), rho)
  tip <- match(fx$ids, rownames(sd_node))
  expect_equal(unname(sd_node[tip, 1L]), sds$s0, tolerance = 1e-8)
  expect_equal(unname(sd_node[tip, 2L]), sds$s1, tolerance = 1e-8)
  n_re <- phylo_mu$n_re
  set.seed(20261133L)
  draws <- t(vapply(seq_len(300L), function(i) {
    drmTMB:::drm_fresh_structured_mu_values(phylo_mu, sd_node)
  }, numeric(2L * n_re)))
  G <- length(fx$ids)
  draws <- draws[, c(tip, n_re + tip), drop = FALSE]
  unit <- sweep(draws, 2L, c(sds$s0, sds$s1), "/")
  pooled_cross <- mean(vapply(seq_len(G), function(j) {
    stats::cov(unit[, j], unit[, G + j]) / fx$K[j, j]
  }, numeric(1L)))
  expect_lt(abs(pooled_cross - rho), 0.12)

  sims <- simulate(fit, nsim = 3L, seed = 20261134L, re.form = NA)
  expect_equal(dim(sims), c(nrow(fx$data), 3L))
  expect_true(all(is.finite(as.matrix(sims))))
  conditional <- simulate(fit, nsim = 3L, seed = 20261134L, re.form = NULL)
  expect_true(all(is.finite(as.matrix(conditional))))
  expect_false(isTRUE(all.equal(sims, conditional)))
})

test_that("neighbouring NB2 labelled phylo q2 forms keep designed refusals", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- nb2p_cached()$fx
  tree <- fx$tree
  # One SD formula for a two-coefficient block.
  expect_error(
    nb2p_fit(fx, only = "intercept"),
    "intercept\\s+plus\\s+one\\s+slope\\s+with\\s+one\\s+SD\\s+formula\\s+per\\s+coefficient"
  )
  # Ordinary random effect beside the block.
  expect_error(
    drmTMB(bf(y ~ x + phylo(1 + x | p | id, tree = tree) + (1 | id),
              sigma ~ 1,
              sd(id, level = "phylogenetic", dpar = "mu",
                 coef = "(Intercept)") ~ w,
              sd(id, level = "phylogenetic", dpar = "mu", coef = "x") ~ v),
           family = nbinom2(), data = fx$data),
    "cannot\\s+be\\s+combined|currently\\s+supports"
  )
})
