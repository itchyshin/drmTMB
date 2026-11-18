# Native Gaussian phylogenetic-interaction slope-only SD regression:
#   y ~ x + phylo_interaction(0 + x | plant:pollinator, tree1, tree2)
#   sd(pair, level = "phylogenetic_interaction") ~ z_pair
# The intercept form is checked with the same oracle as a neighbour.
#
# Oracle: the exact Gaussian marginal.  With the pair latent f ~ N(0, K),
# K = kronecker(A2, A1) (pair order: plant fastest), A_i = cov2cor(ape::vcv(tree_i)),
#   y ~ N(X beta, sigma^2 I + J K J'),  J = diag(sd_pair * value)[pair, ],
# value = 1 (intercept) or x (slope-only).  No drmTMB code is used: K comes
# from ape::vcv and the SD vector from the fitted SD coefficients applied to
# the data-generating predictor.  The trees have unequal branch lengths, so K
# has a non-constant, non-unit diagonal; pair and level order are shuffled.
#
# Tolerances are fixed before the first run and are never loosened:
#   oracle agreement 1e-6 relative on the log-likelihood; constant-SD
#   equivalence 2e-5 relative on logLik and 1e-4 on mu coefficients; SD slope
#   within 0.5 of truth; row-order invariance 1e-5 absolute on logLik;
#   a nested model may not beat the full model by more than 1e-6 units.
# Emulated bugs (reversed SD vector, shuffled SD vector, swapped SD formula)
# must move the oracle by more than 1e-2 log-likelihood units.

gpi_tree <- function(n_tip, prefix, seed, height) {
  stopifnot(n_tip >= 2L, log2(n_tip) == floor(log2(n_tip)))
  set.seed(seed)
  edges <- matrix(integer(), ncol = 2L)
  edge_lengths <- numeric()
  next_node <- n_tip + 1L
  # Ultrametric by construction: internal edges are random and each tip edge
  # closes the gap to `height`, so vcv(tree) has diagonal `height` (not 1)
  # and unequal off-diagonal entries.
  build <- function(tips, depth) {
    if (length(tips) == 1L) return(tips)
    node <- next_node
    next_node <<- next_node + 1L
    mid <- length(tips) / 2L
    kids <- list(tips[seq_len(mid)], tips[seq.int(mid + 1L, length(tips))])
    for (kid in kids) {
      len <- if (length(kid) == 1L) height - depth else stats::runif(1L, 0.3, 0.9)
      child <- build(kid, depth + len)
      edges <<- rbind(edges, c(node, child))
      edge_lengths <<- c(edge_lengths, len)
    }
    node
  }
  build(seq_len(n_tip), 0)
  structure(
    list(edge = edges, edge.length = edge_lengths,
         tip.label = paste0(prefix, seq_len(n_tip)), Nnode = n_tip - 1L),
    class = "phylo"
  )
}

gpi_alpha <- c(`(Intercept)` = log(0.6), z_pair = 0.5)

gpi_fixture <- function(kind = c("slope", "intercept"), seed = 20261201L,
                        n_each = 8L, plant_sd = 0) {
  kind <- match.arg(kind)
  tree1 <- gpi_tree(8L, "plant_", 11L, 3.2)
  tree2 <- gpi_tree(8L, "poll_", 12L, 2.6)
  # The engine standardises each tree to a correlation matrix (unit diagonal);
  # the raw covariances here have diagonals 3.2 and 2.6, so a missing
  # standardisation would move the oracle (checked in gpi_check).
  A1raw <- ape::vcv(tree1)
  A2raw <- ape::vcv(tree2)
  A1 <- stats::cov2cor(A1raw)
  A2 <- stats::cov2cor(A2raw)
  grid <- expand.grid(
    plant = tree1$tip.label, pollinator = tree2$tip.label,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  grid$pair <- paste(grid$plant, grid$pollinator, sep = ":")
  K <- kronecker(A2[tree2$tip.label, tree2$tip.label],
                 A1[tree1$tip.label, tree1$tip.label])
  dimnames(K) <- list(grid$pair, grid$pair)
  K_raw <- kronecker(A2raw[tree2$tip.label, tree2$tip.label],
                     A1raw[tree1$tip.label, tree1$tip.label])
  dimnames(K_raw) <- dimnames(K)
  set.seed(seed)
  n_pair <- nrow(grid)
  z_pair <- stats::setNames(
    seq(-1.5, 1.5, length.out = n_pair)[sample.int(n_pair)], grid$pair
  )
  sd_pair <- exp(gpi_alpha[[1L]] + gpi_alpha[[2L]] * z_pair)
  field <- as.vector(t(chol(K)) %*% stats::rnorm(n_pair)) * sd_pair
  names(field) <- grid$pair
  row <- sample(rep(seq_len(n_pair), each = n_each))
  dat <- grid[row, , drop = FALSE]
  rownames(dat) <- NULL
  dat$z_pair <- unname(z_pair[dat$pair])
  dat$z_other <- stats::rnorm(nrow(dat))[match(dat$pair, grid$pair)]
  dat$x <- stats::rnorm(nrow(dat))
  value <- if (identical(kind, "slope")) dat$x else 1
  plant_effect <- stats::setNames(
    plant_sd * stats::rnorm(length(tree1$tip.label)), tree1$tip.label
  )
  dat$y <- 0.15 + 0.3 * dat$x + value * unname(field[dat$pair]) +
    unname(plant_effect[dat$plant]) + stats::rnorm(nrow(dat), sd = 0.4)
  list(
    data = dat, tree1 = tree1, tree2 = tree2, K = K, K_raw = K_raw, kind = kind,
    pairs = grid$pair, z_pair = z_pair
  )
}

gpi_fit <- function(fx, data = fx$data, sd_formula = "z_pair") {
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
    family = gaussian(), data = data,
    control = drm_control(se = FALSE)
  )
}

# Exact marginal log-likelihood; `sd_pair` is aligned to the rows of K.
gpi_marginal_loglik <- function(y, x, value, pair_idx, beta, sigma, sd_pair, K,
                                extra_V = 0) {
  n_obs <- length(y)
  J <- matrix(0, n_obs, nrow(K))
  J[cbind(seq_len(n_obs), pair_idx)] <- sd_pair[pair_idx] * value
  V <- J %*% K %*% t(J) + diag(sigma^2, n_obs) + extra_V
  R <- chol(V)
  r <- backsolve(R, y - beta[[1L]] - beta[[2L]] * x, transpose = TRUE)
  -0.5 * (n_obs * log(2 * pi) + 2 * sum(log(diag(R))) + sum(r^2))
}

gpi_check <- function(kind) {
  skip_if_not_installed("ape")
  fx <- gpi_fixture(kind)
  dat <- fx$data
  fit <- gpi_fit(fx)
  expect_equal(fit$opt$convergence, 0L, info = kind)
  expect_true(is.finite(as.numeric(logLik(fit))), info = kind)

  sd_coef <- coef(fit, "sd_phylo(pair)")
  expect_identical(names(sd_coef), names(gpi_alpha), info = kind)
  expect_lt(abs(sd_coef[["z_pair"]] - gpi_alpha[["z_pair"]]), 0.5)

  # Name-aligned prediction: each SD follows its own observed pair.
  sd_hat <- predict(fit, dpar = "sd_phylo(pair)")
  expect_setequal(names(sd_hat), fx$pairs)
  expect_equal(
    unname(sd_hat),
    unname(exp(sd_coef[["(Intercept)"]] +
      sd_coef[["z_pair"]] * fx$z_pair[names(sd_hat)])),
    tolerance = 1e-8, info = kind
  )

  value <- if (identical(kind, "slope")) dat$x else rep(1, nrow(dat))
  pair_idx <- match(dat$pair, rownames(fx$K))
  beta <- unname(fit$coefficients$mu[c("(Intercept)", "x")])
  sigma_hat <- unname(stats::sigma(fit))
  ll_at <- function(sd_vec) {
    gpi_marginal_loglik(dat$y, dat$x, value, pair_idx, beta, sigma_hat,
                        sd_vec, fx$K)
  }
  sd_vec <- unname(sd_hat[rownames(fx$K)])
  oracle <- ll_at(sd_vec)
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-6)

  # Emulated bugs must move the oracle far beyond the tolerance.
  set.seed(1L)
  expect_gt(abs(ll_at(rev(sd_vec)) - oracle), 1e-2)
  expect_gt(abs(ll_at(sample(sd_vec)) - oracle), 1e-2)
  swapped <- exp(sd_coef[["(Intercept)"]] +
    sd_coef[["z_pair"]] * unname(fx$z_pair[rownames(fx$K)])[
      rev(seq_len(nrow(fx$K)))])
  expect_gt(abs(ll_at(swapped) - oracle), 1e-2)
  expect_gt(abs(ll_at(rep(mean(sd_vec), length(sd_vec))) - oracle), 1e-2)
  raw_ll <- gpi_marginal_loglik(dat$y, dat$x, value, pair_idx, beta,
                                sigma_hat, sd_vec, fx$K_raw)
  expect_gt(abs(raw_ll - oracle), 1e-2)

  # Constant-SD equivalence with the base (no sd formula) model.
  base_fit <- gpi_fit(fx, sd_formula = NULL)
  constant_fit <- gpi_fit(fx, sd_formula = "1")
  expect_equal(base_fit$opt$convergence, 0L, info = kind)
  expect_equal(constant_fit$opt$convergence, 0L, info = kind)
  expect_equal(
    as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
  expect_equal(
    constant_fit$coefficients$mu, base_fit$coefficients$mu, tolerance = 1e-4
  )
  expect_lt(
    as.numeric(logLik(constant_fit)), as.numeric(logLik(fit)) + 1e-6
  )

  # Row-order invariance.
  shuffled <- dat[rev(seq_len(nrow(dat))), , drop = FALSE]
  fit_rev <- gpi_fit(fx, data = shuffled)
  expect_lt(
    abs(as.numeric(logLik(fit_rev)) - as.numeric(logLik(fit))), 1e-5
  )

  # A different SD predictor must change the fitted likelihood.
  fit_other <- gpi_fit(fx, sd_formula = "z_other")
  expect_gt(abs(as.numeric(logLik(fit_other)) - as.numeric(logLik(fit))), 1e-3)

  # SD inputs must be constant within an observed pair.
  varying <- dat
  varying$z_pair[[1L]] <- varying$z_pair[[1L]] + 1
  expect_error(gpi_fit(fx, data = varying), "varies within pair level")

  saved <- tempfile(fileext = ".rds")
  on.exit(unlink(saved), add = TRUE)
  saveRDS(fit, saved)
  expect_equal(
    predict(readRDS(saved), dpar = "sd_phylo(pair)"), sd_hat, tolerance = 1e-12
  )
  invisible(fit)
}

test_that("Gaussian phylogenetic-interaction slope-only SD varies by observed pair", {
  skip_on_cran()
  gpi_check("slope")
})

test_that("Gaussian phylogenetic-interaction intercept SD matches the same oracle", {
  skip_on_cran()
  gpi_check("intercept")
})

test_that("Gaussian phylogenetic-interaction slope SD with an ordinary plant intercept matches the exact marginal", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- gpi_fixture("slope", seed = 20261202L, plant_sd = 0.7)
  dat <- fx$data
  tree1 <- fx$tree1
  tree2 <- fx$tree2
  fit <- drmTMB(
    bf(
      y ~ x + phylo_interaction(
        0 + x | plant:pollinator, tree1 = tree1, tree2 = tree2
      ) + (1 | plant),
      sd(pair, level = "phylogenetic_interaction") ~ z_pair
    ),
    family = gaussian(), data = dat, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  sd_hat <- predict(fit, dpar = "sd_phylo(pair)")
  sd_vec <- unname(sd_hat[rownames(fx$K)])
  tau_plant <- unname(fit$sdpars$mu[["(1 | plant)"]])
  Zp <- outer(dat$plant, tree1$tip.label, `==`) * 1
  V_plant <- tau_plant^2 * Zp %*% t(Zp)
  args <- list(
    y = dat$y, x = dat$x, value = dat$x,
    pair_idx = match(dat$pair, rownames(fx$K)),
    beta = unname(fit$coefficients$mu[c("(Intercept)", "x")]),
    sigma = unname(stats::sigma(fit)), K = fx$K
  )
  oracle <- do.call(
    gpi_marginal_loglik, c(args, list(sd_pair = sd_vec, extra_V = V_plant))
  )
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-6)
  # Dropping the ordinary block, or reversing the SD vector, moves the oracle.
  no_plant <- do.call(gpi_marginal_loglik, c(args, list(sd_pair = sd_vec)))
  expect_gt(abs(no_plant - oracle), 1e-2)
  reversed <- do.call(
    gpi_marginal_loglik,
    c(args, list(sd_pair = rev(sd_vec), extra_V = V_plant))
  )
  expect_gt(abs(reversed - oracle), 1e-2)
})

test_that("Gaussian phylogenetic-interaction slope SD keeps neighbours closed", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- gpi_fixture("slope")
  tree1 <- fx$tree1
  tree2 <- fx$tree2
  dat <- fx$data
  dat$x2 <- stats::rnorm(nrow(dat))
  fit_it <- function(f) {
    drmTMB(f, family = gaussian(), data = dat,
           control = drm_control(se = FALSE))
  }
  # Pair labels must identify observed species pairs one-to-one.
  bad <- dat
  bad$pair[[1L]] <- "not-the-observed-pair"
  expect_error(gpi_fit(fx, data = bad), "identify observed species pairs one-to-one")
  # Intercept-plus-slope interaction blocks stay refused.
  expect_error(
    fit_it(bf(
      y ~ x + phylo_interaction(
        1 + x | plant:pollinator, tree1 = tree1, tree2 = tree2
      ),
      sd(pair, level = "phylogenetic_interaction") ~ z_pair
    )),
    "Only intercept-only"
  )
  # Two slopes in one interaction block stay refused.
  expect_error(
    fit_it(bf(
      y ~ x + phylo_interaction(
        0 + x + x2 | plant:pollinator, tree1 = tree1, tree2 = tree2
      ),
      sd(pair, level = "phylogenetic_interaction") ~ z_pair
    )),
    "reserves only intercept and one-slope"
  )
  # An interaction term in sigma stays refused.
  expect_error(
    fit_it(bf(
      y ~ x,
      sigma ~ phylo_interaction(
        0 + x | plant:pollinator, tree1 = tree1, tree2 = tree2
      )
    )),
    "Structured-effect syntax is planned, not implemented"
  )
  # A phylo_interaction slope beside another structured provider stays refused.
  expect_error(
    fit_it(bf(
      y ~ x + phylo_interaction(
        0 + x | plant:pollinator, tree1 = tree1, tree2 = tree2
      ) + phylo(1 | plant, tree = tree1)
    )),
    "Only one structured effect type"
  )
  # The matching SD level is required.
  expect_error(
    fit_it(bf(
      y ~ x + phylo_interaction(
        0 + x | plant:pollinator, tree1 = tree1, tree2 = tree2
      ),
      sd(plant, level = "phylogenetic") ~ z_pair
    )),
    "does not match the structured"
  )
})
