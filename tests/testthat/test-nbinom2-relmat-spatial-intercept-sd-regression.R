# Native NB2 `sd()` regression for the relatedness-matrix (`relmat()`) and
# coordinate-spatial (`spatial()`) intercept fields:
#   sd(id, level = "relmat") ~ z
#   sd(site, level = "spatial") ~ z
# Model: eta_i = X_i beta + tau_g[i] * u_g[i], u ~ N(0, Sigma),
# tau_g = exp(alpha0 + alpha1 * z_g), NB2 variance mu + sigma^2 mu^2.
# Oracle: a dense Laplace approximation of the marginal likelihood evaluated
# at the fitted parameters. The native engine is a Laplace fit, so the two
# must agree to optimiser precision.
#
# Disclosure: the spatial oracle and data-generating covariance are built with
# drmTMB:::drm_spatial_coords_precision (the helper under test); the relmat
# oracle uses the analytic kernel directly. The helper's name alignment is
# checked separately against a kernel rebuilt here from the unshuffled ring
# (same exponential / median-distance / 1e-6-jitter formula, so the formula is
# mirrored, not independent).
# Name alignment: the kernel (relmat) and coordinate (spatial) rows are passed
# in a fixed non-symmetric shuffle of the level order; a reversal is a symmetry
# of a Toeplitz kernel or a ring and would hide positional misalignment. Each
# test asserts that reading the shuffled rows by position changes the kernel
# and the oracle log-likelihood.
# Tolerances fixed before the first run: dense-Laplace match 1e-6 (relative);
# kernel rebuild 1e-8; positional relmat kernel must differ by more than 0.2
# (max abs, unit-scale ~1.7); positional spatial precision must differ by more
# than 0.5 (max abs); positional oracle log-likelihood must differ by more than
# 1000 x (1e-6 x |logLik|).

nb2_sd_dense_laplace <- function(y, eta0, group, sigma, tau, Sigma) {
  # `group` indexes rows/columns of `Sigma` (and entries of `tau`) per row of y.
  n_group <- nrow(Sigma)
  size <- 1 / sigma^2
  Sigma_inv <- solve(Sigma)
  logdet_Sigma <- as.numeric(determinant(Sigma, logarithm = TRUE)$modulus)
  scale_obs <- tau[group]
  agg <- function(v) as.numeric(rowsum(v, group, reorder = TRUE))
  stopifnot(identical(sort(unique(group)), seq_len(n_group)))

  parts <- function(u) {
    mu <- exp(eta0 + scale_obs * u[group])
    list(
      mu = mu,
      loglik = sum(stats::dnbinom(y, size = size, mu = mu, log = TRUE)),
      # d log p / d eta and -d^2 log p / d eta^2 (observed information)
      score = size * (y - mu) / (size + mu),
      info = size * mu * (size + y) / (size + mu)^2
    )
  }
  objective <- function(u) {
    p <- parts(u)
    p$loglik - 0.5 * sum(u * (Sigma_inv %*% u))
  }
  u <- rep(0, n_group)
  for (iter in seq_len(200L)) {
    p <- parts(u)
    grad <- tau * agg(p$score) - as.numeric(Sigma_inv %*% u)
    H <- diag(tau^2 * agg(p$info), n_group) + Sigma_inv
    step <- as.numeric(solve(H, grad))
    # Damped Newton step: halve until the penalised log-likelihood improves.
    old <- objective(u)
    s <- 1
    while (objective(u + s * step) < old - 1e-12 && s > 1e-8) s <- s / 2
    u <- u + s * step
    if (max(abs(s * step)) < 1e-11) break
  }
  p <- parts(u)
  H <- diag(tau^2 * agg(p$info), n_group) + Sigma_inv
  logdet_H <- as.numeric(determinant(H, logarithm = TRUE)$modulus)
  # log integral of exp(loglik(u)) * N(u; 0, Sigma) du by Laplace:
  # f(u*) - 0.5 log|Sigma| - n/2 log(2 pi) + n/2 log(2 pi) - 0.5 log|H|
  objective(u) - 0.5 * logdet_Sigma - 0.5 * logdet_H
}

# Kernel rebuilt from named coordinates (levels order), mirroring the helper's
# formula: exp(-d / median positive distance) plus 1e-6 on the diagonal.
nb2_spatial_kernel_by_name <- function(coords, levels) {
  d <- as.matrix(stats::dist(as.matrix(coords[levels, 1:2])))
  pos <- d[upper.tri(d)]
  K <- exp(-d / stats::median(pos[pos > 0]))
  diag(K) <- diag(K) + 1e-6
  dimnames(K) <- list(levels, levels)
  K
}

nb2_relmat_sd_fixture <- function(seed = 20261101L) {
  n_id <- 24L
  n_each <- 10L
  id_levels <- paste0("id_", seq_len(n_id))
  # Non-unit covariance scale: detects accidental correlation-scaling of K.
  K_true <- 1.7 * 0.45 ^ abs(outer(seq_len(n_id), seq_len(n_id), `-`))
  dimnames(K_true) <- list(id_levels, id_levels)
  # The kernel handed to the fit is in a fixed shuffled row/column order (own
  # seed, so the data stream below is unchanged); `K_true` stays in level order.
  set.seed(seed + 1L)
  shuffle <- sample(id_levels)
  K <- K_true[shuffle, shuffle]
  set.seed(seed)
  z_id <- setNames(rep(c(-1, 1), length.out = n_id), id_levels)
  alpha <- c(`(Intercept)` = log(0.45), z = 0.3)
  latent <- as.vector(t(chol(K_true)) %*% stats::rnorm(n_id))
  names(latent) <- id_levels
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z_id)
  id_index <- rep(seq_len(n_id), each = n_each)
  id <- factor(id_levels[id_index], levels = id_levels)
  x <- stats::rnorm(length(id))
  mu <- exp(1.0 + 0.2 * x + tau[as.character(id)] * latent[as.character(id)])
  dat <- data.frame(
    y = stats::rnbinom(length(mu), mu = mu, size = 1 / 0.5^2),
    x = x, id = id, z = z_id[as.character(id)]
  )
  list(data = dat, K = K, K_true = K_true, shuffle = shuffle, alpha = alpha,
       z_id = z_id, levels = id_levels)
}

nb2_spatial_sd_fixture <- function(seed = 2026110131L) {
  n_site <- 24L
  n_each <- 12L
  site_levels <- paste0("site_", seq_len(n_site))
  theta <- seq(0, 2 * pi, length.out = n_site + 1L)[-1L]
  # Site k sits at angle theta_k. Row order of `coords` is a fixed shuffle of
  # the factor-level order (own seed, data stream below unchanged), so the fit
  # has to map coordinates to sites by name.
  coords_ring <- data.frame(
    x = cos(theta), y = sin(theta), row.names = site_levels
  )
  set.seed(seed + 1L)
  shuffle <- sample(site_levels)
  coords <- coords_ring[shuffle, , drop = FALSE]
  set.seed(seed)
  z_site <- setNames(as.numeric(scale(stats::rnorm(n_site))), site_levels)
  alpha <- c(`(Intercept)` = log(0.55), z = 0.4)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z_site[site_levels])
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords, site = site_levels, group = "site"
  )
  Sigma <- solve(as.matrix(precision$precision))
  Sigma <- Sigma[site_levels, site_levels]
  field <- as.vector(t(chol(Sigma)) %*% stats::rnorm(n_site))
  names(field) <- site_levels
  site_index <- rep(seq_len(n_site), each = n_each)
  site <- factor(site_levels[site_index], levels = site_levels)
  x <- stats::rnorm(length(site))
  mu <- exp(1.0 + 0.2 * x + tau[as.character(site)] * field[as.character(site)])
  dat <- data.frame(
    y = stats::rnbinom(length(mu), mu = mu, size = 1 / 0.5^2),
    x = x, site = site, z = z_site[as.character(site)]
  )
  list(data = dat, coords = coords, coords_ring = coords_ring,
       shuffle = shuffle, Sigma = Sigma, alpha = alpha,
       z_site = z_site, levels = site_levels)
}

test_that("NB2 relmat intercepts accept a predictor-dependent SD and match a dense Laplace oracle", {
  skip_on_cran()
  fx <- nb2_relmat_sd_fixture()
  dat <- fx$data
  K <- fx$K
  # Name alignment: K arrives shuffled; its positional reading differs.
  expect_false(identical(rownames(K), fx$levels))
  expect_equal(K[fx$levels, fx$levels], fx$K_true)
  K_positional <- K
  dimnames(K_positional) <- list(fx$levels, fx$levels)
  expect_gt(max(abs(K_positional - fx$K_true)), 0.2)

  fit <- drmTMB(
    bf(
      y ~ x + relmat(1 | id, K = K),
      sigma ~ 1,
      sd(id, level = "relmat") ~ z
    ),
    family = nbinom2(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  sd_coef <- coef(fit, "sd_relmat(id)")
  expect_named(sd_coef, c("(Intercept)", "z"))
  expect_true(all(is.finite(sd_coef)))
  # Loose recovery bounds (24 groups): fixed before the first run.
  expect_lt(abs(sd_coef[["(Intercept)"]] - fx$alpha[["(Intercept)"]]), 0.5)
  expect_lt(abs(sd_coef[["z"]] - fx$alpha[["z"]]), 0.5)

  # predict() returns exp(alpha0 + alpha1 z) per relmat level, by name.
  sd_prediction <- predict(fit, dpar = "sd_relmat(id)")
  expect_setequal(names(sd_prediction), fx$levels)
  expected_sd <- exp(sd_coef[["(Intercept)"]] + sd_coef[["z"]] * fx$z_id)
  expect_equal(unname(sd_prediction[fx$levels]), unname(expected_sd[fx$levels]),
               tolerance = 1e-10)

  # Dense Laplace oracle at the fitted parameters.
  mu_coef <- coef(fit, "mu")
  sigma_hat <- exp(unname(coef(fit, "sigma")[["(Intercept)"]]))
  eta0 <- as.numeric(stats::model.matrix(~ x, dat) %*% mu_coef[c("(Intercept)", "x")])
  oracle_for <- function(Sigma) {
    nb2_sd_dense_laplace(
      y = dat$y, eta0 = eta0, group = as.integer(dat$id), sigma = sigma_hat,
      tau = unname(expected_sd[fx$levels]), Sigma = Sigma
    )
  }
  oracle <- oracle_for(fx$K_true)
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-6)
  expect_gt(
    abs(oracle_for(unname(K_positional)) - oracle), 1000 * 1e-6 * abs(oracle)
  )

  # Constant-SD equivalence with the scalar relmat fit.
  base_fit <- drmTMB(
    bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1),
    family = nbinom2(), data = dat, control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1,
       sd(id, level = "relmat") ~ 1),
    family = nbinom2(), data = dat, control = drm_control(se = FALSE)
  )
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
               tolerance = 2e-5)
  expect_equal(constant_fit$coefficients$mu, base_fit$coefficients$mu,
               tolerance = 1e-4)
  expect_equal(
    unname(coef(constant_fit, "sd_relmat(id)")[["(Intercept)"]]),
    log(unname(base_fit$sdpars$mu[["relmat(1 | id)"]])),
    tolerance = 1e-4
  )
})

test_that("NB2 relmat SD regression rejects a z that varies within a level", {
  skip_on_cran()
  fx <- nb2_relmat_sd_fixture()
  dat <- fx$data
  K <- fx$K
  dat$z[1L] <- dat$z[1L] + 1
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1,
         sd(id, level = "relmat") ~ z),
      family = nbinom2(), data = dat, control = drm_control(se = FALSE)
    ),
    "constant within"
  )
})

test_that("NB2 coordinate-spatial intercepts accept a predictor-dependent SD and match a dense Laplace oracle", {
  skip_on_cran()
  fx <- nb2_spatial_sd_fixture()
  dat <- fx$data
  coords <- fx$coords
  # Name alignment: the helper must read the shuffled rows by name (checked
  # against a kernel rebuilt from the ring), and reading them by position (row
  # names dropped) must give a different precision matrix.
  lev <- fx$levels
  expect_false(identical(rownames(coords), lev))
  P_named <- as.matrix(drmTMB:::drm_spatial_coords_precision(
    coords, site = lev, group = "site"
  )$precision)[lev, lev]
  coords_positional <- coords
  rownames(coords_positional) <- NULL
  P_positional <- as.matrix(drmTMB:::drm_spatial_coords_precision(
    coords_positional, site = lev, group = "site"
  )$precision)[lev, lev]
  expect_equal(
    unname(solve(P_named)),
    unname(nb2_spatial_kernel_by_name(fx$coords_ring, lev)),
    tolerance = 1e-8
  )
  expect_gt(max(abs(P_named - P_positional)), 0.5)

  fit <- drmTMB(
    bf(
      y ~ x + spatial(1 | site, coords = coords),
      sigma ~ 1,
      sd(site, level = "spatial") ~ z
    ),
    family = nbinom2(),
    data = dat,
    control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  sd_coef <- coef(fit, "sd_spatial(site)")
  expect_named(sd_coef, c("(Intercept)", "z"))
  expect_true(all(is.finite(sd_coef)))
  expect_lt(abs(sd_coef[["z"]] - fx$alpha[["z"]]), 0.6)

  sd_prediction <- predict(fit, dpar = "sd_spatial(site)")
  expect_setequal(names(sd_prediction), fx$levels)
  expected_sd <- exp(sd_coef[["(Intercept)"]] + sd_coef[["z"]] * fx$z_site)
  expect_equal(unname(sd_prediction[fx$levels]), unname(expected_sd[fx$levels]),
               tolerance = 1e-10)

  mu_coef <- coef(fit, "mu")
  sigma_hat <- exp(unname(coef(fit, "sigma")[["(Intercept)"]]))
  eta0 <- as.numeric(stats::model.matrix(~ x, dat) %*% mu_coef[c("(Intercept)", "x")])
  oracle_for <- function(Sigma) {
    nb2_sd_dense_laplace(
      y = dat$y, eta0 = eta0, group = as.integer(dat$site), sigma = sigma_hat,
      tau = unname(expected_sd[fx$levels]), Sigma = Sigma[lev, lev]
    )
  }
  oracle <- oracle_for(fx$Sigma)
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-6)
  expect_gt(
    abs(oracle_for(solve(P_positional)) - oracle), 1000 * 1e-6 * abs(oracle)
  )

  base_fit <- drmTMB(
    bf(y ~ x + spatial(1 | site, coords = coords), sigma ~ 1),
    family = nbinom2(), data = dat, control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(y ~ x + spatial(1 | site, coords = coords), sigma ~ 1,
       sd(site, level = "spatial") ~ 1),
    family = nbinom2(), data = dat, control = drm_control(se = FALSE)
  )
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
               tolerance = 2e-5)
  expect_equal(constant_fit$coefficients$mu, base_fit$coefficients$mu,
               tolerance = 1e-4)
  expect_equal(
    unname(coef(constant_fit, "sd_spatial(site)")[["(Intercept)"]]),
    log(unname(base_fit$sdpars$mu[["spatial(1 | site)"]])),
    tolerance = 1e-4
  )
})
