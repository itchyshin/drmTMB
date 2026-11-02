# Native Poisson phylogenetic-interaction SD regression (batch 5):
#   y ~ x + phylo_interaction(<1 | 0 + x> | plant:pollinator, tree1, tree2)
#   sd(pair, level = "phylogenetic_interaction") ~ z_pair
# Binomial analogues: test-binomial-phylo-interaction-sd.R and
# test-binomial-phylo-interaction-slope-sd.R.
#
# Oracle: a dense, drmTMB-independent Laplace marginal likelihood over the pair
# latent f ~ N(0, K), K = kronecker(A2, A1) (pair order: plant fastest), with
#   eta = X beta + J f,  J = diag(sd_pair * value)[pair, ],
# where value = 1 (intercept) or x (slope-only).  Laplace value:
#   ll(f*) - f*' K^-1 f* / 2 - logdet(I + K J' W J) / 2,  W = diag(exp(eta*)).
#
# Tolerances are fixed before the first run and are never loosened:
#   oracle agreement 1e-4 absolute on the log-likelihood (as the Poisson iid +
#   structured template); constant-SD equivalence 2e-5 relative on logLik and
#   1e-4 on mu coefficients; SD slope within 0.5 of truth; row-order
#   invariance 1e-5 absolute on logLik; a nested model may not beat the full
#   model by more than 1e-3 log-likelihood units.

ppi_tree <- function(n_tip, prefix) {
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
         tip.label = paste0(prefix, seq_len(n_tip)), Nnode = n_tip - 1L),
    class = "phylo"
  )
}

ppi_alpha <- c(`(Intercept)` = log(0.5), z_pair = 0.5)

ppi_fixture <- function(kind = c("intercept", "slope"), seed = 20261150L,
                        n_each = 12L) {
  kind <- match.arg(kind)
  set.seed(seed)
  tree1 <- ppi_tree(8L, "plant_")
  tree2 <- ppi_tree(8L, "poll_")
  A1 <- drmTMB:::drm_phylo_tip_covariance(tree1)
  A2 <- drmTMB:::drm_phylo_tip_covariance(tree2)
  grid <- expand.grid(
    plant = tree1$tip.label, pollinator = tree2$tip.label,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  grid$pair <- paste(grid$plant, grid$pollinator, sep = ":")
  K <- kronecker(A2, A1)
  dimnames(K) <- list(grid$pair, grid$pair)
  n_pair <- nrow(grid)
  z_pair <- stats::setNames(
    seq(-1.5, 1.5, length.out = n_pair)[sample.int(n_pair)], grid$pair
  )
  sd_pair <- exp(ppi_alpha[[1L]] + ppi_alpha[[2L]] * z_pair)
  field <- as.vector(t(chol(K)) %*% stats::rnorm(n_pair)) * sd_pair
  names(field) <- grid$pair
  row <- sample(rep(seq_len(n_pair), each = n_each))
  dat <- grid[row, , drop = FALSE]
  rownames(dat) <- NULL
  dat$z_pair <- unname(z_pair[dat$pair])
  dat$x <- stats::rnorm(nrow(dat))
  value <- if (identical(kind, "slope")) dat$x else 1
  eta <- 0.15 + 0.3 * dat$x + value * unname(field[dat$pair])
  dat$y <- stats::rpois(nrow(dat), exp(eta))
  list(
    data = dat, tree1 = tree1, tree2 = tree2, K = K, kind = kind,
    pairs = grid$pair, z_pair = z_pair
  )
}

ppi_fit <- function(fx, data = fx$data, sd_formula = "z_pair") {
  tree1 <- fx$tree1
  tree2 <- fx$tree2
  coef_part <- if (identical(fx$kind, "slope")) "0 + x" else "1"
  parts <- sprintf(
    "y ~ x + phylo_interaction(%s | plant:pollinator, tree1 = tree1, tree2 = tree2)",
    coef_part
  )
  if (!is.null(sd_formula)) {
    parts <- c(parts, sprintf(
      "sd(pair, level = \"phylogenetic_interaction\") ~ %s", sd_formula
    ))
  }
  drmTMB(
    eval(parse(text = sprintf("bf(%s)", paste(parts, collapse = ", ")))),
    family = stats::poisson(), data = data,
    control = drm_control(se = FALSE)
  )
}

ppi_dense_laplace_loglik <- function(y, x, value, pair_idx, beta, sd_pair, K) {
  n_pair <- nrow(K)
  n_obs <- length(y)
  J <- matrix(0, n_obs, n_pair)
  J[cbind(seq_len(n_obs), pair_idx)] <- sd_pair[pair_idx] * value
  Kinv <- solve(K)
  eta0 <- beta[[1L]] + beta[[2L]] * x
  logjoint <- function(f) {
    eta <- eta0 + as.vector(J %*% f)
    sum(stats::dpois(y, exp(eta), log = TRUE)) - 0.5 * sum(f * (Kinv %*% f))
  }
  f <- rep(0, n_pair)
  for (iter in seq_len(200L)) {
    mu <- exp(eta0 + as.vector(J %*% f))
    grad <- as.vector(crossprod(J, y - mu)) - as.vector(Kinv %*% f)
    H <- crossprod(J, mu * J) + Kinv
    step <- as.vector(solve(H, grad))
    scale <- 1
    f0 <- logjoint(f)
    while (logjoint(f + scale * step) < f0 && scale > 1e-8) scale <- scale / 2
    f <- f + scale * step
    if (max(abs(scale * step)) < 1e-12) break
  }
  mu <- exp(eta0 + as.vector(J %*% f))
  logjoint(f) -
    0.5 * as.numeric(determinant(diag(n_pair) + K %*% crossprod(J, mu * J))$modulus)
}

ppi_check <- function(kind) {
  fx <- ppi_fixture(kind)
  dat <- fx$data
  fit <- ppi_fit(fx)
  expect_equal(fit$opt$convergence, 0L, info = kind)
  expect_true(is.finite(as.numeric(logLik(fit))), info = kind)

  sd_coef <- coef(fit, "sd_phylo(pair)")
  expect_identical(names(sd_coef), names(ppi_alpha), info = kind)
  expect_lt(abs(sd_coef[["z_pair"]] - ppi_alpha[["z_pair"]]), 0.5)

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

  # Dense independent oracle.
  oracle <- ppi_dense_laplace_loglik(
    y = dat$y, x = dat$x,
    value = if (identical(kind, "slope")) dat$x else rep(1, nrow(dat)),
    pair_idx = match(dat$pair, rownames(fx$K)),
    beta = fit$coefficients$mu[c("(Intercept)", "x")],
    sd_pair = sd_hat[rownames(fx$K)],
    K = fx$K
  )
  expect_lt(abs(as.numeric(logLik(fit)) - oracle), 1e-4)

  # Constant-SD equivalence with the base (no sd formula) model.
  base_fit <- ppi_fit(fx, sd_formula = NULL)
  constant_fit <- ppi_fit(fx, sd_formula = "1")
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
  expect_lt(
    as.numeric(logLik(constant_fit)), as.numeric(logLik(fit)) + 1e-3
  )

  # Row-order invariance.
  shuffled <- dat[rev(seq_len(nrow(dat))), , drop = FALSE]
  fit_rev <- ppi_fit(fx, data = shuffled)
  expect_lt(
    abs(as.numeric(logLik(fit_rev)) - as.numeric(logLik(fit))), 1e-5
  )

  # SD inputs must be constant within an observed pair.
  varying <- dat
  varying$z_pair[[1L]] <- varying$z_pair[[1L]] + 1
  expect_error(ppi_fit(fx, data = varying), "varies within pair level")

  simulated <- simulate(fit, nsim = 1L, seed = 20261151L)
  expect_named(simulated, "sim_1")
  expect_length(simulated[[1L]], nrow(dat))
  expect_true(all(simulated[[1L]] >= 0L))
  expect_true(all(simulated[[1L]] == as.integer(simulated[[1L]])))
  expect_identical(
    simulated$sim_1, simulate(fit, nsim = 1L, seed = 20261151L)$sim_1
  )

  saved <- tempfile(fileext = ".rds")
  on.exit(unlink(saved), add = TRUE)
  saveRDS(fit, saved)
  expect_equal(
    predict(readRDS(saved), dpar = "sd_phylo(pair)"), sd_hat, tolerance = 1e-12
  )
  invisible(fit)
}

test_that("Poisson phylogenetic-interaction intercept SD varies by observed pair", {
  skip_on_cran()
  ppi_check("intercept")
})

test_that("Poisson phylogenetic-interaction SD keeps pair identity and other gates closed", {
  skip_on_cran()
  fx <- ppi_fixture("intercept")
  # Pair labels must identify observed species pairs one-to-one.
  bad <- fx$data
  bad$pair[[1L]] <- "not-the-observed-pair"
  expect_error(ppi_fit(fx, data = bad), "identify observed species pairs one-to-one")
  tree1 <- fx$tree1
  tree2 <- fx$tree2
  # Zero inflation is not part of this slice.
  expect_error(
    drmTMB(
      bf(
        y ~ x + phylo_interaction(
          1 | plant:pollinator, tree1 = tree1, tree2 = tree2
        ),
        zi ~ 1,
        sd(pair, level = "phylogenetic_interaction") ~ z_pair
      ),
      family = stats::poisson(), data = fx$data,
      control = drm_control(se = FALSE)
    ),
    "non-inflated model"
  )
  # Ordinary random effects beside the interaction field are not admitted.
  expect_error(
    drmTMB(
      bf(
        y ~ x + phylo_interaction(
          1 | plant:pollinator, tree1 = tree1, tree2 = tree2
        ) + (1 | plant),
        sd(pair, level = "phylogenetic_interaction") ~ z_pair
      ),
      family = stats::poisson(), data = fx$data,
      control = drm_control(se = FALSE)
    ),
    "ordinary"
  )
})

test_that("Poisson phylogenetic-interaction slope-only SD varies by observed pair", {
  skip_on_cran()
  ppi_check("slope")
})
