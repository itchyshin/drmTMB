# Native Poisson coordinate-spatial SD regression:
#   sd(site, level = "spatial") ~ z
# for an intercept field `spatial(1 | site, coords)` and a slope-only field
# `spatial(0 + x | site, coords)`. Template: test-gamma-spatial-sd-regression.R.
#
# Oracles used here:
#   * a dense Laplace approximation of the marginal likelihood at the fitted
#     parameters (the native engine is a Laplace fit, so they agree to
#     optimiser precision), written below for per-observation weights w_i
#     (1 for an intercept field, x_i for a slope-only field);
#   * constant-SD equivalence: `sd(...) ~ 1` must reproduce the scalar
#     `spatial()` fit (log-likelihood, and exp(intercept) = scalar SD);
#   * nesting: the `~ z` model contains the `~ 1` model, so its maximised
#     log-likelihood cannot be lower;
#   * exact link algebra: predict() = exp(X alpha) at each site.
# Disclosure: the dense-Laplace oracle and the data-generating covariance are
# built with drmTMB:::drm_spatial_coords_precision (the helper under test). The
# helper's name alignment is therefore checked separately, against a kernel
# rebuilt here from the unshuffled ring (same exponential / median-distance /
# 1e-6-jitter formula, so the formula itself is mirrored, not independent).
# Name alignment: the coordinate rows are passed in a fixed non-symmetric
# shuffle of the site-level order (a ring reversed is a symmetry of the
# kernel and would hide positional misalignment). The test asserts that
# reading the shuffled rows by position changes the precision matrix.
# Tolerances were fixed before the first run: dense-Laplace match 1e-6
# (relative); kernel rebuild 1e-8; the positional precision must differ by
# more than 0.5 (max abs; the named precision has max abs entries of ~5); the
# positional oracle log-likelihood must differ from the named one by more than
# 1000 x (1e-6 x |logLik|).

poisson_spatial_sd_fixture <- function(kind = c("intercept", "slope"),
                                       seed = 2026110101L,
                                       n_site = 24L,
                                       n_each = 16L) {
  kind <- match.arg(kind)
  site_levels <- paste0("site_", seq_len(n_site))
  theta <- seq(0, 2 * pi, length.out = n_site + 1L)[-1L]
  # Site k sits at angle theta_k. Rows are then put in a fixed shuffled order
  # (drawn from its own seed so the data stream below is unchanged).
  coords_ring <- data.frame(
    x = cos(theta),
    y = sin(theta),
    row.names = site_levels
  )
  set.seed(seed + 1L)
  shuffle <- sample(site_levels)
  coords <- coords_ring[shuffle, , drop = FALSE]
  set.seed(seed)
  z_site <- setNames(as.numeric(scale(stats::rnorm(n_site))), site_levels)
  alpha_sd <- c(`(Intercept)` = log(0.5), z = 0.4)
  tau <- exp(alpha_sd[[1L]] + alpha_sd[[2L]] * z_site[site_levels])
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords,
    site = site_levels,
    group = "site"
  )
  covariance <- solve(as.matrix(precision$precision))
  unit_field <- as.vector(t(chol(covariance)) %*% stats::rnorm(n_site))
  field <- setNames(tau * unit_field, site_levels)

  site <- factor(rep(site_levels, each = n_each), levels = site_levels)
  x <- stats::rnorm(length(site))
  random <- field[as.character(site)]
  eta <- 0.2 + 0.3 * x + if (identical(kind, "slope")) x * random else random
  dat <- data.frame(
    y = stats::rpois(length(eta), exp(eta)),
    x = x,
    site = site,
    z = z_site[as.character(site)]
  )
  list(
    data = dat, coords = coords, coords_ring = coords_ring,
    shuffle = shuffle, site_levels = site_levels,
    z_site = z_site, alpha_sd = alpha_sd,
    term = if (identical(kind, "slope")) {
      "spatial(0 + x | site, coords = coords)"
    } else {
      "spatial(1 | site, coords = coords)"
    },
    scalar_name = if (identical(kind, "slope")) {
      "spatial(0 + x | site)"
    } else {
      "spatial(1 | site)"
    }
  )
}

# Dense Laplace log marginal likelihood for a Poisson field with log link:
# eta_i = eta0_i + w_i * tau_g[i] * u_g[i], u ~ N(0, Sigma).
poisson_sd_dense_laplace <- function(y, eta0, w, group, tau, Sigma) {
  n_group <- nrow(Sigma)
  Sigma_inv <- solve(Sigma)
  logdet_Sigma <- as.numeric(determinant(Sigma, logarithm = TRUE)$modulus)
  stopifnot(identical(sort(unique(group)), seq_len(n_group)))
  agg <- function(v) as.numeric(rowsum(v, group, reorder = TRUE))
  parts <- function(u) {
    mu <- exp(eta0 + w * tau[group] * u[group])
    list(loglik = sum(stats::dpois(y, mu, log = TRUE)), score = y - mu, info = mu)
  }
  objective <- function(u) {
    parts(u)$loglik - 0.5 * sum(u * (Sigma_inv %*% u))
  }
  u <- rep(0, n_group)
  for (iter in seq_len(200L)) {
    p <- parts(u)
    grad <- tau * agg(w * p$score) - as.numeric(Sigma_inv %*% u)
    H <- diag(tau^2 * agg(w^2 * p$info), n_group) + Sigma_inv
    step <- as.numeric(solve(H, grad))
    old <- objective(u)
    s <- 1
    while (objective(u + s * step) < old - 1e-12 && s > 1e-8) s <- s / 2
    u <- u + s * step
    if (max(abs(s * step)) < 1e-11) break
  }
  p <- parts(u)
  H <- diag(tau^2 * agg(w^2 * p$info), n_group) + Sigma_inv
  logdet_H <- as.numeric(determinant(H, logarithm = TRUE)$modulus)
  objective(u) - 0.5 * logdet_Sigma - 0.5 * logdet_H
}

# Kernel rebuilt from named coordinates (levels order), mirroring the helper's
# formula: exp(-d / median positive distance) plus 1e-6 on the diagonal.
poisson_spatial_kernel_by_name <- function(coords, levels) {
  d <- as.matrix(stats::dist(as.matrix(coords[levels, 1:2])))
  pos <- d[upper.tri(d)]
  K <- exp(-d / stats::median(pos[pos > 0]))
  diag(K) <- diag(K) + 1e-6
  dimnames(K) <- list(levels, levels)
  K
}

poisson_spatial_sd_check <- function(kind) {
  fx <- poisson_spatial_sd_fixture(kind)
  coords <- fx$coords
  mu_formula <- stats::as.formula(paste("y ~ x +", fx$term))
  fit_one <- function(sd_formula = NULL) {
    f <- if (is.null(sd_formula)) bf(mu_formula) else bf(mu_formula, sd_formula)
    drmTMB(
      f,
      family = stats::poisson(),
      data = fx$data,
      control = drm_control(se = FALSE)
    )
  }
  # Name alignment: the helper must read the shuffled rows by name, and
  # reading them by position (row names dropped) must give a different matrix.
  lev <- fx$site_levels
  expect_false(identical(rownames(coords), lev))
  P_named <- as.matrix(drmTMB:::drm_spatial_coords_precision(
    coords, site = lev, group = "site"
  )$precision)[lev, lev]
  coords_positional <- coords
  rownames(coords_positional) <- NULL
  P_positional <- as.matrix(drmTMB:::drm_spatial_coords_precision(
    coords_positional, site = lev, group = "site"
  )$precision)[lev, lev]
  K_by_name <- poisson_spatial_kernel_by_name(fx$coords_ring, lev)
  Sigma_named <- solve(P_named)
  expect_equal(unname(Sigma_named), unname(K_by_name), tolerance = 1e-8)
  expect_gt(max(abs(P_named - P_positional)), 0.5)
  Sigma_positional <- solve(P_positional)

  fit <- fit_one(sd(site, level = "spatial") ~ z)
  fit_constant_sd <- fit_one(sd(site, level = "spatial") ~ 1)
  fit_scalar <- fit_one()

  scale_coef <- coef(fit, "sd_spatial(site)")
  sd_hat <- predict(fit, dpar = "sd_spatial(site)")
  expect_equal(as.integer(fit$opt$convergence), 0L)
  expect_equal(as.integer(fit_constant_sd$opt$convergence), 0L)
  expect_equal(as.integer(fit_scalar$opt$convergence), 0L)
  expect_named(scale_coef, names(fx$alpha_sd))
  expect_setequal(names(sd_hat), fx$site_levels)
  expect_length(sd_hat, length(fx$site_levels))
  expect_true(all(is.finite(sd_hat)))

  # Exact link algebra: predict() is exp(X alpha) at each site.
  expect_equal(
    unname(sd_hat[fx$site_levels]),
    unname(exp(scale_coef[["(Intercept)"]] +
      scale_coef[["z"]] * fx$z_site[fx$site_levels])),
    tolerance = 1e-8
  )

  # Dense Laplace oracle at the fitted parameters, with the named covariance.
  mu_coef <- coef(fit, "mu")
  dat <- fx$data
  eta0 <- as.numeric(stats::model.matrix(~ x, dat) %*% mu_coef[c("(Intercept)", "x")])
  w <- if (identical(kind, "slope")) dat$x else rep(1, nrow(dat))
  oracle_for <- function(Sigma) {
    poisson_sd_dense_laplace(
      y = dat$y, eta0 = eta0, w = w, group = as.integer(dat$site),
      tau = unname(sd_hat[lev]), Sigma = Sigma[lev, lev]
    )
  }
  oracle <- oracle_for(Sigma_named)
  expect_equal(as.numeric(stats::logLik(fit)), oracle, tolerance = 1e-6)
  # The positional covariance must give a clearly different oracle value.
  expect_gt(abs(oracle_for(Sigma_positional) - oracle), 1000 * 1e-6 * abs(oracle))

  # Constant-SD equivalence with the scalar spatial fit.
  expect_equal(
    as.numeric(stats::logLik(fit_constant_sd)),
    as.numeric(stats::logLik(fit_scalar)),
    tolerance = 2e-5
  )
  expect_equal(
    unname(coef(fit_constant_sd, "sd_spatial(site)")[["(Intercept)"]]),
    log(unname(fit_scalar$sdpars$mu[[fx$scalar_name]])),
    tolerance = 1e-4
  )

  # Nesting: ~ z contains ~ 1.
  expect_gte(
    as.numeric(stats::logLik(fit)),
    as.numeric(stats::logLik(fit_constant_sd)) - 1e-6
  )

  # Recovery (small design: sign and a loose band only).
  expect_gt(scale_coef[["z"]], 0)
  expect_lt(abs(scale_coef[["z"]] - fx$alpha_sd[["z"]]), 0.6)

  simulated <- simulate(fit, nsim = 2L, seed = 2026110102L)
  expect_length(simulated, 2L)
  expect_true(all(vapply(simulated, length, integer(1L)) == nrow(fx$data)))
  expect_true(all(unlist(simulated, use.names = FALSE) >= 0))
  invisible(fit)
}

test_that("Poisson spatial intercept SD regression maps sites by name", {
  poisson_spatial_sd_check("intercept")
})

test_that("Poisson spatial slope-only SD regression maps sites by name", {
  poisson_spatial_sd_check("slope")
})
