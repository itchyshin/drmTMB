# Native Gaussian mu with a structured provider and a predictor-dependent SD.
#
# Model (provider-generic): y = X beta + Zs u + e, e ~ N(0, sigma^2 I),
# u = diag(tau) L w with L L' = K and w ~ N(0, I), so
# Cov(u) = diag(tau) K diag(tau), tau_g = exp(alpha0 + alpha1 * z_g).
# Zs is the group indicator matrix (intercept) or diag(x) times it (slope).
# The marginal likelihood is exact for Gaussian y, so a dense oracle is cheap.
#
# Providers probed separately:
#   (a) relmat(1 | id, K = K)               sd(id, level = "relmat") ~ z
#   (b) spatial(1 | site, coords = coords)  sd(site, level = "spatial") ~ z
#   (c) animal(0 + x | id, A = A)           sd(id, level = "animal", coef = "x") ~ z
#
# Disclosure: for (b) the data-generating covariance and the dense oracle's K
# are built with drmTMB:::drm_spatial_coords_precision (the helper under
# test); (a) uses the analytic Toeplitz kernel and (c) the analytic
# geometric kernel directly. The helper's name alignment is checked separately against a
# kernel rebuilt here from the unshuffled ring (same exponential /
# median-distance / 1e-6-jitter formula, so the formula is mirrored, not
# independent).
# Name alignment: in (a) the kernel rows and in (b) the coordinate rows are
# passed in a fixed non-symmetric shuffle of the level order (a reversed
# Toeplitz or ring is a symmetry of the kernel and would hide positional
# misalignment); (c) already uses an odd/even interleave. Each test asserts
# that reading the shuffled rows by position changes the kernel / precision,
# and that the positional dense oracle log-likelihood differs from the named
# one. Tolerances fixed before the first run: positional (a)/(c) kernel
# differs by more than 0.2 (max abs); positional (b) precision differs by more
# than 0.5 (max abs; named entries reach ~13); positional oracle
# log-likelihood differs by more than 1000 x (1e-6 x |logLik|); kernel
# rebuild 1e-8.
#
# Not covered here: Q / Ainv / pedigree inputs for (a) and (c), slope SDs for
# (a) and (b), multi-coefficient blocks, `sigma` regression, se = TRUE
# inference, profile targets, and any non-Gaussian family.

gsd_prov_dense_nll <- function(y, mu, sigma, Zs, tau, K) {
  cov_u <- outer(tau, tau) * K
  V <- Zs %*% cov_u %*% t(Zs) + diag(sigma^2, length(y))
  R <- chol(V)
  r <- backsolve(R, y - mu, transpose = TRUE)
  0.5 * (length(y) * log(2 * pi) + 2 * sum(log(diag(R))) + sum(r^2))
}

# Dense checks for one fitted model.
#  1. -logLik(fit) equals the dense marginal NLL evaluated at the fitted
#     (beta, sigma, alpha) -- tolerance 1e-6 (relative), fixed before first run.
#  2. An independent dense optimiser started from neutral values reaches the
#     same maximum -- tolerance 1e-5 (relative), fixed before first run.
gsd_prov_expect_dense_oracle <- function(fit, dat, group, K, z_group,
                                         sd_dpar, slope = NULL) {
  lev <- levels(dat[[group]])
  K <- K[lev, lev]
  Zs <- stats::model.matrix(stats::as.formula(paste("~ 0 +", group)), dat)
  if (!is.null(slope)) Zs <- Zs * dat[[slope]]
  X <- stats::model.matrix(~x, dat)
  zg <- z_group[lev]

  alpha_hat <- coef(fit, sd_dpar)
  tau_hat <- exp(alpha_hat[[1L]] + alpha_hat[[2L]] * zg)
  nll_at_fit <- gsd_prov_dense_nll(
    dat$y, as.vector(X %*% coef(fit, "mu")), unname(sigma(fit)),
    Zs, tau_hat, K
  )
  expect_equal(as.numeric(stats::logLik(fit)), -nll_at_fit, tolerance = 1e-6)

  # sd_dpar prediction must be the same tau, keyed by level name.
  expect_equal(
    unname(predict(fit, dpar = sd_dpar)[lev]),
    unname(tau_hat),
    tolerance = 1e-10
  )

  obj <- function(par) {
    gsd_prov_dense_nll(
      dat$y, as.vector(X %*% par[1:2]), exp(par[[3L]]), Zs,
      exp(par[[4L]] + par[[5L]] * zg), K
    )
  }
  start <- c(unname(stats::coef(stats::lm(y ~ x, dat))), log(0.5), log(0.3), 0)
  # Box constraints on the log-scale parameters keep the line search away from
  # numerically singular covariances (an optimiser guard, not a tolerance).
  opt <- stats::optim(
    start, obj, method = "L-BFGS-B",
    lower = c(-Inf, -Inf, -5, -5, -3), upper = c(Inf, Inf, 2, 2, 3),
    control = list(maxit = 500L, factr = 10)
  )
  expect_equal(opt$convergence, 0L)
  expect_equal(as.numeric(stats::logLik(fit)), -opt$value, tolerance = 1e-5)
  invisible(NULL)
}

# The dense oracle value at the fitted parameters with a given kernel (levels
# order), used to show that a positionally misread kernel changes the value.
gsd_prov_oracle_ll <- function(fit, dat, group, K, z_group, sd_dpar,
                               slope = NULL) {
  lev <- levels(dat[[group]])
  Zs <- stats::model.matrix(stats::as.formula(paste("~ 0 +", group)), dat)
  if (!is.null(slope)) Zs <- Zs * dat[[slope]]
  X <- stats::model.matrix(~x, dat)
  alpha_hat <- coef(fit, sd_dpar)
  -gsd_prov_dense_nll(
    dat$y, as.vector(X %*% coef(fit, "mu")), unname(sigma(fit)), Zs,
    exp(alpha_hat[[1L]] + alpha_hat[[2L]] * z_group[lev]), K[lev, lev]
  )
}

# Kernel rebuilt from named coordinates (levels order), mirroring the helper's
# formula: exp(-d / median positive distance) plus 1e-6 on the diagonal.
gsd_prov_spatial_kernel_by_name <- function(coords, levels) {
  d <- as.matrix(stats::dist(as.matrix(coords[levels, 1:2])))
  pos <- d[upper.tri(d)]
  K <- exp(-d / stats::median(pos[pos > 0]))
  diag(K) <- diag(K) + 1e-6
  dimnames(K) <- list(levels, levels)
  K
}

gsd_prov_expect_fit_surface <- function(fit, sd_dpar, group_levels, dat,
                                        alpha_true) {
  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, sd_dpar), c("(Intercept)", "z"))
  sd_hat <- predict(fit, dpar = sd_dpar)
  expect_setequal(names(sd_hat), group_levels)
  expect_length(sd_hat, length(group_levels))
  expect_true(all(is.finite(sd_hat)) && all(sd_hat > 0))
  # Smoke recovery only; the dense oracle is the real check.
  expect_gt(coef(fit, sd_dpar)[["z"]], 0)
  expect_lt(abs(coef(fit, sd_dpar)[["z"]] - alpha_true[["z"]]), 0.4)
  expect_length(simulate(fit, nsim = 1L, seed = 20261102L)[[1L]], nrow(dat))
  saved <- tempfile(fileext = ".rds")
  on.exit(unlink(saved), add = TRUE)
  saveRDS(fit, saved)
  expect_equal(
    predict(readRDS(saved), dpar = sd_dpar), sd_hat, tolerance = 1e-12
  )
}

# ---- (a) relmat K ------------------------------------------------------------

gsd_prov_relmat_fixture <- function(seed = 20261101L, n_id = 60L, n_each = 6L) {
  id_levels <- paste0("id", seq_len(n_id))
  K_true <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.45^abs(i - j))
  dimnames(K_true) <- list(id_levels, id_levels)
  # Kernel handed to the fit: fixed non-symmetric shuffle of rows and columns
  # (own seed, so the data stream below is unchanged).
  set.seed(seed + 1L)
  shuffle <- sample(id_levels)
  K <- K_true[shuffle, shuffle]
  set.seed(seed)
  z_group <- stats::setNames(as.numeric(scale(stats::rnorm(n_id))), id_levels)
  alpha <- c(`(Intercept)` = log(0.55), z = 0.4)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z_group[id_levels])
  u <- stats::setNames(
    tau * as.vector(t(chol(K_true)) %*% stats::rnorm(n_id)), id_levels
  )
  id <- factor(rep(id_levels, each = n_each), levels = id_levels)
  x <- stats::rnorm(length(id))
  y <- 0.2 + 0.5 * x + u[as.character(id)] + stats::rnorm(length(id), sd = 0.3)
  list(
    data = data.frame(y = unname(y), id, x, z = unname(z_group[as.character(id)])),
    K = K, K_true = K_true, z_group = z_group, alpha = alpha,
    id_levels = id_levels
  )
}

test_that("Gaussian relmat K intercept supports predictor-dependent SDs", {
  skip_on_cran()
  fx <- gsd_prov_relmat_fixture()
  K <- fx$K
  # Name alignment: K arrives shuffled; its positional reading differs.
  expect_false(identical(rownames(K), fx$id_levels))
  expect_equal(K[fx$id_levels, fx$id_levels], fx$K_true)
  K_positional <- K
  dimnames(K_positional) <- list(fx$id_levels, fx$id_levels)
  expect_gt(max(abs(K_positional - fx$K_true)), 0.2)
  fit <- drmTMB(
    bf(y ~ x + relmat(1 | id, K = K), sd(id, level = "relmat") ~ z),
    family = stats::gaussian(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  gsd_prov_expect_fit_surface(fit, "sd_relmat(id)", fx$id_levels, fx$data, fx$alpha)
  gsd_prov_expect_dense_oracle(
    fit, fx$data, "id", fx$K_true, fx$z_group, "sd_relmat(id)"
  )
  ll_named <- gsd_prov_oracle_ll(
    fit, fx$data, "id", fx$K_true, fx$z_group, "sd_relmat(id)"
  )
  ll_positional <- gsd_prov_oracle_ll(
    fit, fx$data, "id", K_positional, fx$z_group, "sd_relmat(id)"
  )
  expect_gt(abs(ll_positional - ll_named), 1000 * 1e-6 * abs(ll_named))

  base_fit <- drmTMB(
    bf(y ~ x + relmat(1 | id, K = K)),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(y ~ x + relmat(1 | id, K = K), sd(id, level = "relmat") ~ 1),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
})

# ---- (b) coordinate spatial --------------------------------------------------

gsd_prov_spatial_fixture <- function(seed = 20261103L, n_site = 60L, n_each = 6L) {
  site_levels <- paste0("site_", seq_len(n_site))
  theta <- seq(0, 2 * pi, length.out = n_site + 1L)[-1L]
  # Site k sits at angle theta_k; coordinate rows are passed in a fixed shuffle
  # of the level order (own seed, so the data stream below is unchanged).
  coords_ring <- data.frame(
    x = cos(theta), y = sin(theta), row.names = site_levels
  )
  set.seed(seed + 1L)
  shuffle <- sample(site_levels)
  coords <- coords_ring[shuffle, , drop = FALSE]
  set.seed(seed)
  z_group <- stats::setNames(as.numeric(scale(stats::rnorm(n_site))), site_levels)
  alpha <- c(`(Intercept)` = log(0.55), z = 0.4)
  precision <- drmTMB:::drm_spatial_coords_precision(
    coords, site = site_levels, group = "site"
  )
  K <- solve(as.matrix(precision$precision))
  dimnames(K) <- list(site_levels, site_levels)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z_group[site_levels])
  u <- stats::setNames(
    tau * as.vector(t(chol(K)) %*% stats::rnorm(n_site)), site_levels
  )
  site <- factor(rep(site_levels, each = n_each), levels = site_levels)
  x <- stats::rnorm(length(site))
  y <- 0.2 + 0.5 * x + u[as.character(site)] +
    stats::rnorm(length(site), sd = 0.3)
  list(
    data = data.frame(
      y = unname(y), site, x, z = unname(z_group[as.character(site)])
    ),
    coords = coords, coords_ring = coords_ring, shuffle = shuffle, K = K,
    z_group = z_group, alpha = alpha, site_levels = site_levels
  )
}

test_that("Gaussian coordinate-spatial intercept supports predictor-dependent SDs", {
  skip_on_cran()
  fx <- gsd_prov_spatial_fixture()
  coords <- fx$coords
  # Name alignment: the helper reads the shuffled rows by name (checked against
  # a kernel rebuilt from the ring); by position they give another precision.
  lev <- fx$site_levels
  expect_false(identical(rownames(coords), lev))
  coords_positional <- coords
  rownames(coords_positional) <- NULL
  P_named <- as.matrix(drmTMB:::drm_spatial_coords_precision(
    coords, site = lev, group = "site"
  )$precision)[lev, lev]
  P_positional <- as.matrix(drmTMB:::drm_spatial_coords_precision(
    coords_positional, site = lev, group = "site"
  )$precision)[lev, lev]
  expect_equal(
    unname(solve(P_named)),
    unname(gsd_prov_spatial_kernel_by_name(fx$coords_ring, lev)),
    tolerance = 1e-8
  )
  expect_gt(max(abs(P_named - P_positional)), 0.5)
  fit <- drmTMB(
    bf(
      y ~ x + spatial(1 | site, coords = coords),
      sd(site, level = "spatial") ~ z
    ),
    family = stats::gaussian(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  gsd_prov_expect_fit_surface(
    fit, "sd_spatial(site)", fx$site_levels, fx$data, fx$alpha
  )
  gsd_prov_expect_dense_oracle(
    fit, fx$data, "site", fx$K, fx$z_group, "sd_spatial(site)"
  )
  ll_named <- gsd_prov_oracle_ll(
    fit, fx$data, "site", fx$K, fx$z_group, "sd_spatial(site)"
  )
  ll_positional <- gsd_prov_oracle_ll(
    fit, fx$data, "site", solve(P_positional), fx$z_group, "sd_spatial(site)"
  )
  expect_gt(abs(ll_positional - ll_named), 1000 * 1e-6 * abs(ll_named))

  base_fit <- drmTMB(
    bf(y ~ x + spatial(1 | site, coords = coords)),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(
      y ~ x + spatial(1 | site, coords = coords),
      sd(site, level = "spatial") ~ 1
    ),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
})

# ---- (c) animal one-slope-only -----------------------------------------------

gsd_prov_animal_slope_fixture <- function(seed = 20261105L, n_id = 60L,
                                          n_each = 6L) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  kernel_order <- c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L))
  A <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.35^abs(i - j))
  A_true <- A
  dimnames(A_true) <- list(id_levels, id_levels)
  A <- A[kernel_order, kernel_order]
  dimnames(A) <- list(id_levels[kernel_order], id_levels[kernel_order])
  z_group <- stats::setNames(rep(c(-0.5, 0.5), length.out = n_id), id_levels)
  alpha <- c(`(Intercept)` = log(0.5), z = 0.4)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z_group[rownames(A)])
  u <- stats::setNames(
    tau * as.vector(t(chol(A)) %*% stats::rnorm(n_id)), rownames(A)
  )
  id <- factor(rep(id_levels, each = n_each), levels = id_levels)
  x <- stats::rnorm(length(id))
  y <- 0.2 + 0.5 * x + u[as.character(id)] * x +
    stats::rnorm(length(id), sd = 0.3)
  list(
    data = data.frame(y = unname(y), id, x, z = unname(z_group[as.character(id)])),
    A = A, A_true = A_true, z_group = z_group, alpha = alpha,
    id_levels = id_levels
  )
}

test_that("Gaussian animal slope-only SD supports predictor-dependent SDs", {
  skip_on_cran()
  fx <- gsd_prov_animal_slope_fixture()
  A <- fx$A
  # Name alignment: A arrives in an odd/even interleave; its positional reading
  # differs from the named one.
  A_positional <- A
  dimnames(A_positional) <- list(fx$id_levels, fx$id_levels)
  expect_equal(A[fx$id_levels, fx$id_levels], fx$A_true)
  expect_gt(max(abs(A_positional - fx$A_true)), 0.2)
  fit <- drmTMB(
    bf(
      y ~ x + animal(0 + x | id, A = A),
      sd(id, level = "animal", dpar = "mu", coef = "x") ~ z
    ),
    family = stats::gaussian(),
    data = fx$data,
    control = drm_control(se = FALSE)
  )
  gsd_prov_expect_fit_surface(fit, "sd_animal(id)", fx$id_levels, fx$data, fx$alpha)
  gsd_prov_expect_dense_oracle(
    fit, fx$data, "id", A, fx$z_group, "sd_animal(id)", slope = "x"
  )
  ll_named <- gsd_prov_oracle_ll(
    fit, fx$data, "id", A, fx$z_group, "sd_animal(id)", slope = "x"
  )
  ll_positional <- gsd_prov_oracle_ll(
    fit, fx$data, "id", A_positional, fx$z_group, "sd_animal(id)", slope = "x"
  )
  expect_gt(abs(ll_positional - ll_named), 1000 * 1e-6 * abs(ll_named))

  # Omitting `coef` addresses the only structured coefficient: same model.
  implicit_fit <- drmTMB(
    bf(y ~ x + animal(0 + x | id, A = A), sd(id, level = "animal") ~ z),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(
    as.numeric(logLik(implicit_fit)), as.numeric(logLik(fit)),
    tolerance = 2e-5
  )

  base_fit <- drmTMB(
    bf(y ~ x + animal(0 + x | id, A = A)),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(
      y ~ x + animal(0 + x | id, A = A),
      sd(id, level = "animal", coef = "x") ~ 1
    ),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
})
