# Native NB2 phylogenetic-interaction SD regression:
#   y ~ x + phylo_interaction(<1 | 0 + x> | plant:pollinator, tree1, tree2),
#   sigma ~ 1
#   sd(pair, level = "phylogenetic_interaction") ~ z_pair
# Poisson analogue and template: test-poisson-batch5-sd-regression.R.
#
# Oracle: a dense, drmTMB-independent Laplace marginal likelihood over the pair
# latent f ~ N(0, K), K = kronecker(A2, A1) (pair order: plant fastest), with
#   eta = X beta + J f,  J = diag(sd_pair * value)[pair, ],
# value = 1 (intercept) or x (slope-only), NB2 size = 1 / sigma^2, and
#   Laplace value = ll(f*) - f*' K^-1 f* / 2 - logdet(I + K J' W J) / 2,
#   W = diag((y + size) * size * mu / (size + mu)^2) at the inner mode f*.
# The two trees have different sizes (8 and 4 tips) and shuffled tip-label
# order, so a swapped Kronecker order or a wrong level order is detected. K is
# the unit-diagonal correlation form the package uses for trees (a non-unit
# diagonal is not available for phylogenetic providers).
#
# Tolerances are fixed before the first run and are never loosened:
#   oracle agreement 1e-4 absolute on the log-likelihood; constant-SD
#   equivalence 2e-5 relative on logLik and 1e-4 on mu coefficients; SD slope
#   within 0.5 of truth; row-order invariance 1e-5 absolute on logLik; a nested
#   model may not beat the full model by more than 1e-3 log-likelihood units;
#   each emulated bug must move the oracle by more than 0.05 log-likelihood
#   units away from the fitted log-likelihood.

npi_tree <- function(n_tip, prefix) {
  stopifnot(n_tip >= 2L, log2(n_tip) == floor(log2(n_tip)))
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L
  build <- function(tips) {
    if (length(tips) == 1L) return(tips)
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
    list(edge = edges, edge.length = edge_lengths,
         tip.label = sample(paste0(prefix, seq_len(n_tip))),
         Nnode = n_tip - 1L),
    class = "phylo"
  )
}

npi_alpha <- c(`(Intercept)` = log(0.5), z_pair = 0.5)
npi_dispersion <- 0.3

npi_fixture <- function(kind = c("intercept", "slope"), seed = 20261160L,
                        n_each = 12L) {
  kind <- match.arg(kind)
  set.seed(seed)
  tree1 <- npi_tree(8L, "plant_")
  tree2 <- npi_tree(4L, "poll_")
  A1 <- drmTMB:::drm_phylo_tip_covariance(tree1)
  A2 <- drmTMB:::drm_phylo_tip_covariance(tree2)
  grid <- expand.grid(
    plant = rownames(A1), pollinator = rownames(A2),
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  grid$pair <- paste(grid$plant, grid$pollinator, sep = ":")
  K <- kronecker(A2[rownames(A2), rownames(A2)], A1[rownames(A1), rownames(A1)])
  dimnames(K) <- list(grid$pair, grid$pair)
  n_pair <- nrow(grid)
  z_pair <- stats::setNames(
    seq(-1.5, 1.5, length.out = n_pair)[sample.int(n_pair)], grid$pair
  )
  sd_pair <- exp(npi_alpha[[1L]] + npi_alpha[[2L]] * z_pair)
  field <- as.vector(t(chol(K)) %*% stats::rnorm(n_pair)) * sd_pair
  names(field) <- grid$pair
  row <- sample(rep(seq_len(n_pair), each = n_each))
  dat <- grid[row, , drop = FALSE]
  rownames(dat) <- NULL
  dat$z_pair <- unname(z_pair[dat$pair])
  dat$x <- stats::rnorm(nrow(dat))
  value <- if (identical(kind, "slope")) dat$x else 1
  eta <- 0.9 + 0.3 * dat$x + value * unname(field[dat$pair])
  dat$y <- stats::rnbinom(
    nrow(dat), mu = exp(eta), size = 1 / npi_dispersion^2
  )
  list(
    data = dat, tree1 = tree1, tree2 = tree2, K = K, kind = kind,
    pairs = grid$pair, z_pair = z_pair
  )
}

npi_fit <- function(fx, data = fx$data, sd_formula = "z_pair") {
  tree1 <- fx$tree1
  tree2 <- fx$tree2
  coef_part <- if (identical(fx$kind, "slope")) "0 + x" else "1"
  parts <- c(
    sprintf(
      "y ~ x + phylo_interaction(%s | plant:pollinator, tree1 = tree1, tree2 = tree2)",
      coef_part
    ),
    "sigma ~ 1"
  )
  if (!is.null(sd_formula)) {
    parts <- c(parts, sprintf(
      "sd(pair, level = \"phylogenetic_interaction\") ~ %s", sd_formula
    ))
  }
  drmTMB(
    eval(parse(text = sprintf("bf(%s)", paste(parts, collapse = ", ")))),
    family = nbinom2(), data = data,
    control = drm_control(se = FALSE)
  )
}

npi_dense_laplace_loglik <- function(y, x, value, pair_idx, beta, sd_pair, K,
                                     sigma) {
  n_pair <- nrow(K)
  n_obs <- length(y)
  size <- 1 / sigma^2
  J <- matrix(0, n_obs, n_pair)
  J[cbind(seq_len(n_obs), pair_idx)] <- sd_pair[pair_idx] * value
  Kinv <- solve(K)
  eta0 <- beta[[1L]] + beta[[2L]] * x
  logjoint <- function(f) {
    eta <- eta0 + as.vector(J %*% f)
    sum(stats::dnbinom(y, size = size, mu = exp(eta), log = TRUE)) -
      0.5 * sum(f * (Kinv %*% f))
  }
  f <- rep(0, n_pair)
  for (iter in seq_len(200L)) {
    mu <- exp(eta0 + as.vector(J %*% f))
    score <- (y - mu) * size / (size + mu)
    info <- (y + size) * size * mu / (size + mu)^2
    grad <- as.vector(crossprod(J, score)) - as.vector(Kinv %*% f)
    H <- crossprod(J, info * J) + Kinv
    step <- as.vector(solve(H, grad))
    scale <- 1
    f0 <- logjoint(f)
    while (logjoint(f + scale * step) < f0 && scale > 1e-8) scale <- scale / 2
    f <- f + scale * step
    if (max(abs(scale * step)) < 1e-12) break
  }
  mu <- exp(eta0 + as.vector(J %*% f))
  info <- (y + size) * size * mu / (size + mu)^2
  logjoint(f) -
    0.5 * as.numeric(determinant(diag(n_pair) + K %*% crossprod(J, info * J))$modulus)
}

npi_check <- function(kind) {
  fx <- npi_fixture(kind)
  dat <- fx$data
  fit <- npi_fit(fx)
  expect_equal(fit$opt$convergence, 0L, info = kind)
  expect_true(is.finite(as.numeric(logLik(fit))), info = kind)

  sd_coef <- coef(fit, "sd_phylo(pair)")
  expect_identical(names(sd_coef), names(npi_alpha), info = kind)
  expect_lt(abs(sd_coef[["z_pair"]] - npi_alpha[["z_pair"]]), 0.5)

  # Name-aligned prediction: each SD follows its own observed pair.
  sd_hat <- predict(fit, dpar = "sd_phylo(pair)")
  expect_setequal(names(sd_hat), fx$pairs)
  expect_equal(
    unname(sd_hat),
    unname(exp(sd_coef[["(Intercept)"]] +
      sd_coef[["z_pair"]] * fx$z_pair[names(sd_hat)])),
    tolerance = 1e-8, info = kind
  )
  expect_equal(
    unname(sd_hat), unname(fit$sdpars[["sd_phylo(pair)"]]), tolerance = 1e-10
  )

  # Dense independent oracle at the fitted parameters.
  sigma_hat <- exp(coef(fit, "sigma")[["(Intercept)"]])
  value <- if (identical(kind, "slope")) dat$x else rep(1, nrow(dat))
  oracle_at <- function(value = value, sd_pair = sd_hat[rownames(fx$K)],
                        K = fx$K) {
    npi_dense_laplace_loglik(
      y = dat$y, x = dat$x, value = value,
      pair_idx = match(dat$pair, rownames(fx$K)),
      beta = fit$coefficients$mu[c("(Intercept)", "x")],
      sd_pair = sd_pair, K = K, sigma = sigma_hat
    )
  }
  fitted_ll <- as.numeric(logLik(fit))
  oracle <- oracle_at(value = value)
  expect_lt(abs(fitted_ll - oracle), 1e-4)

  # Emulated-bug sensitivity: the oracle must reject wrong loadings, a
  # constant (mean) SD, a swapped Kronecker order, and a wrongly scaled K.
  wrong_value <- if (identical(kind, "slope")) rep(1, nrow(dat)) else dat$x
  expect_gt(abs(fitted_ll - oracle_at(value = wrong_value)), 0.05)
  expect_gt(
    abs(fitted_ll - oracle_at(
      value = value,
      sd_pair = rep(mean(sd_hat), length(sd_hat))
    )), 0.05
  )
  K_swapped <- kronecker(
    drmTMB:::drm_phylo_tip_covariance(fx$tree1),
    drmTMB:::drm_phylo_tip_covariance(fx$tree2)
  )
  dimnames(K_swapped) <- dimnames(fx$K)
  expect_gt(abs(fitted_ll - oracle_at(value = value, K = K_swapped)), 0.05)
  expect_gt(abs(fitted_ll - oracle_at(value = value, K = 2 * fx$K)), 0.05)

  # Constant-SD equivalence with the base (no sd formula) model.
  base_fit <- npi_fit(fx, sd_formula = NULL)
  constant_fit <- npi_fit(fx, sd_formula = "1")
  expect_equal(base_fit$opt$convergence, 0L, info = kind)
  expect_equal(constant_fit$opt$convergence, 0L, info = kind)
  expect_equal(
    as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
  expect_equal(
    constant_fit$coefficients$mu, base_fit$coefficients$mu, tolerance = 1e-4
  )
  # Nesting: the constant-SD model cannot beat the SD-regression model.
  expect_lt(as.numeric(logLik(constant_fit)), fitted_ll + 1e-3)

  # Row-order invariance.
  shuffled <- dat[rev(seq_len(nrow(dat))), , drop = FALSE]
  fit_rev <- npi_fit(fx, data = shuffled)
  expect_lt(abs(as.numeric(logLik(fit_rev)) - fitted_ll), 1e-5)

  # SD inputs must be constant within an observed pair.
  varying <- dat
  varying$z_pair[[1L]] <- varying$z_pair[[1L]] + 1
  expect_error(npi_fit(fx, data = varying), "varies within pair level")

  simulated <- simulate(fit, nsim = 1L, seed = 20261161L)
  expect_named(simulated, "sim_1")
  expect_length(simulated[[1L]], nrow(dat))
  expect_true(all(simulated[[1L]] >= 0L))
  expect_true(all(simulated[[1L]] == as.integer(simulated[[1L]])))
  expect_identical(
    simulated$sim_1, simulate(fit, nsim = 1L, seed = 20261161L)$sim_1
  )

  saved <- tempfile(fileext = ".rds")
  on.exit(unlink(saved), add = TRUE)
  saveRDS(fit, saved)
  expect_equal(
    predict(readRDS(saved), dpar = "sd_phylo(pair)"), sd_hat, tolerance = 1e-12
  )
  invisible(fit)
}

test_that("NB2 phylogenetic-interaction intercept SD varies by observed pair", {
  skip_on_cran()
  npi_check("intercept")
})

test_that("NB2 phylogenetic-interaction slope-only SD varies by observed pair", {
  skip_on_cran()
  npi_check("slope")
})

test_that("NB2 phylogenetic-interaction SD keeps pair identity and other gates closed", {
  skip_on_cran()
  fx <- npi_fixture("intercept")
  tree1 <- fx$tree1
  tree2 <- fx$tree2
  fit_nb2 <- function(formula, data = fx$data) {
    drmTMB(formula, family = nbinom2(), data = data,
           control = drm_control(se = FALSE))
  }
  # Pair labels must identify observed species pairs one-to-one.
  bad <- fx$data
  bad$pair[[1L]] <- "not-the-observed-pair"
  expect_error(npi_fit(fx, data = bad), "identify observed species pairs one-to-one")
  # Zero inflation is not part of this slice.
  expect_error(
    fit_nb2(bf(
      y ~ x + phylo_interaction(1 | plant:pollinator, tree1 = tree1, tree2 = tree2),
      sigma ~ 1, zi ~ 1,
      sd(pair, level = "phylogenetic_interaction") ~ z_pair
    )),
    "Zero-inflated NB2 structured random effects are planned"
  )
  # Ordinary random effects beside the interaction field are not admitted.
  expect_error(
    fit_nb2(bf(
      y ~ x + phylo_interaction(1 | plant:pollinator, tree1 = tree1, tree2 = tree2) +
        (1 | plant),
      sigma ~ 1,
      sd(pair, level = "phylogenetic_interaction") ~ z_pair
    )),
    "cannot be combined with ordinary"
  )
  # A structured sigma term beside the interaction SD is not admitted.
  expect_error(
    fit_nb2(bf(
      y ~ x + phylo_interaction(1 | plant:pollinator, tree1 = tree1, tree2 = tree2),
      sigma ~ phylo_interaction(1 | plant:pollinator, tree1 = tree1, tree2 = tree2),
      sd(pair, level = "phylogenetic_interaction") ~ z_pair
    )),
    "structured .sigma. effect plus"
  )
  # A wrong SD level for the interaction field is refused.
  expect_error(
    fit_nb2(bf(
      y ~ x + phylo_interaction(1 | plant:pollinator, tree1 = tree1, tree2 = tree2),
      sigma ~ 1,
      sd(pair, level = "phylogenetic") ~ z_pair
    )),
    "does not match"
  )
})
