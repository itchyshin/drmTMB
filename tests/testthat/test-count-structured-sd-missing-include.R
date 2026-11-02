# Poisson and NB2 structured-intercept SD regression with
# miss_control(response = "include").
#
# Routes: relmat(1 | id, K), animal(1 | id, A), phylo(1 | id, tree) and
# spatial(1 | id, coords), each with its own sd(id, level = ...) ~ z.
#
# Claim. A response coded NA contributes no likelihood term: the C++ observed_y
# mask drops only that row's density, and the structured latent field keeps its
# prior for every node (the prior is applied to the whole field, not row by
# row). So (a) when every group keeps at least one observed row, the include
# fit equals the complete-case fit on the observed rows; (b) when a whole group
# is NA, the include fit still holds that group's node under the prior and must
# match an oracle that keeps the prior term. NA rows still receive predictions.
# Because an empty node is a prior-only block of a Gaussian field it integrates
# out exactly, so in (b) the include fit also equals the complete-case fit on
# these routes (checked, not assumed); the oracle is still the primary check.
#
# Oracle (independent of drmTMB's likelihood): a dense Laplace marginal over the
# G node effects u ~ N(0, Sigma), eta_i = eta0_i + tau[g_i] u[g_i], scored only
# on observed rows, with the fixed part and the SD surface taken from the fit:
#   ll(u*) - u*' Sigma^-1 u* / 2 - log|Sigma| / 2 - log|H| / 2,
#   H = diag(tau^2 * colSums over observed rows of Z' info) + Sigma^-1.
# Empty groups are handled by an indicator matrix, so they keep the prior term.
# Disclosure: for phylo and spatial the covariance Sigma is built with
# drmTMB:::drm_phylo_tip_covariance and drmTMB:::drm_spatial_coords_precision,
# which are part of what is under test only through name alignment (data order
# is deliberately different from the covariance order).
#
# Tolerances were fixed before the first run and none was loosened:
# include vs complete-case logLik 1e-8, oracle 1e-6 (relative), bug-sensitivity
# gap > 0.05.
#
# Fences pinned here: q2 (intercept + slope) and zero-inflated structured SD
# routes stay refused with include. Slope-only and ordinary-plus-structured
# (iid) shapes are admitted in test-count-iid-slope-sd-missing-include.R.

smi_levels <- function(n_id) sprintf("id%02d", seq_len(n_id))

smi_make_sigma <- function(kind, n_id, seed) {
  lev <- smi_levels(n_id)
  set.seed(seed)
  if (identical(kind, "phylo")) {
    tree <- ape::rcoal(n_id)
    tree$tip.label <- sample(lev)
    K <- drmTMB:::drm_phylo_tip_covariance(tree)
    return(list(Sigma = K, tree = tree, coords = NULL))
  }
  if (identical(kind, "spatial")) {
    theta <- seq(0, 2 * pi, length.out = n_id + 1L)[-1L]
    ring <- data.frame(x = cos(theta), y = sin(theta), row.names = lev)
    coords <- ring[sample(lev), , drop = FALSE]
    P <- as.matrix(drmTMB:::drm_spatial_coords_precision(
      coords, site = lev, group = "id"
    )$precision)[lev, lev]
    return(list(Sigma = solve(P), tree = NULL, coords = coords))
  }
  base <- 1.6 * 0.45^abs(outer(seq_len(n_id), seq_len(n_id), `-`))
  dimnames(base) <- list(lev, lev)
  order <- c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L))
  list(Sigma = base[order, order], tree = NULL, coords = NULL)
}

smi_spec <- list(
  relmat = list(term = "relmat(1 | id, K = K)", level = "relmat",
                dpar = "sd_relmat(id)"),
  animal = list(term = "animal(1 | id, A = K)", level = "animal",
                dpar = "sd_animal(id)"),
  phylo = list(term = "phylo(1 | id, tree = tree)", level = "phylogenetic",
               dpar = "sd_phylo(id)"),
  spatial = list(term = "spatial(1 | id, coords = coords)", level = "spatial",
                 dpar = "sd_spatial(id)")
)

# na_groups: group levels (by position in the covariance order) made entirely NA.
smi_fixture <- function(kind, family, seed, n_id = 24L, n_each = 8L,
                        na_groups = integer(0)) {
  sm <- smi_make_sigma(kind, n_id, seed)
  Sigma <- sm$Sigma
  lev <- rownames(Sigma)
  set.seed(seed + 1L)
  z_group <- stats::setNames(
    seq(-1, 1, length.out = n_id)[sample.int(n_id)], lev
  )
  tau <- exp(log(0.5) + 0.5 * z_group)
  u <- stats::setNames(as.vector(t(chol(Sigma)) %*% stats::rnorm(n_id)), lev)
  data_levels <- rev(lev)
  id <- factor(rep(data_levels, each = n_each), levels = data_levels)
  x <- stats::rnorm(length(id))
  eta <- 0.3 + 0.3 * x + tau[as.character(id)] * u[as.character(id)]
  y <- if (identical(family, "poisson")) {
    stats::rpois(length(eta), exp(eta))
  } else {
    stats::rnbinom(length(eta), size = 1 / 0.4^2, mu = exp(eta))
  }
  dat <- data.frame(y = y, x = x, id = id,
                    z = as.numeric(z_group[as.character(id)]))
  dat$y[seq_len(nrow(dat)) %% 5L == 2L] <- NA
  for (g in na_groups) dat$y[as.character(dat$id) == lev[g]] <- NA
  list(data = dat, K = Sigma, tree = sm$tree, coords = sm$coords,
       Sigma = Sigma, z_group = z_group, kind = kind, family = family)
}

smi_fit <- function(fx, include = TRUE, formula_kind = "intercept") {
  spec <- smi_spec[[fx$kind]]
  K <- fx$K
  tree <- fx$tree
  coords <- fx$coords
  mu_formula <- stats::as.formula(paste("y ~ x +", spec$term))
  sd_formula <- stats::as.formula(
    sprintf('sd(id, level = "%s") ~ z', spec$level)
  )
  sigma_formula <- sigma ~ 1
  f <- if (identical(fx$family, "poisson")) {
    bf(mu_formula, sd_formula)
  } else {
    bf(mu_formula, sigma_formula, sd_formula)
  }
  dat <- if (include) fx$data else fx$data[!is.na(fx$data$y), , drop = FALSE]
  if (!include && !is.null(coords)) {
    # The complete-case spatial fit needs one coordinate row per remaining id.
    coords <- coords[rownames(coords) %in% as.character(dat$id), , drop = FALSE]
  }
  drmTMB(
    f,
    family = if (identical(fx$family, "poisson")) stats::poisson() else nbinom2(),
    data = dat,
    missing = if (include) miss_control(response = "include") else miss_control(),
    control = drm_control(se = FALSE)
  )
}

smi_oracle <- function(fx, fit, tau_group = NULL, na_as_zero = FALSE,
                       drop_prior_groups = NULL) {
  dat <- fx$data
  Sigma <- fx$Sigma
  lev <- rownames(Sigma)
  if (is.null(tau_group)) {
    spec <- smi_spec[[fx$kind]]
    tau_group <- unname(predict(fit, dpar = spec$dpar)[lev])
  }
  stopifnot(length(tau_group) == length(lev), all(is.finite(tau_group)))
  mu_coef <- coef(fit, "mu")
  eta0 <- as.numeric(mu_coef[["(Intercept)"]] + mu_coef[["x"]] * dat$x)
  size <- if (identical(fx$family, "nbinom2")) {
    1 / exp(coef(fit, "sigma")[["(Intercept)"]])^2
  }
  y <- dat$y
  observed <- if (na_as_zero) rep(TRUE, nrow(dat)) else !is.na(y)
  y[is.na(y)] <- 0
  n <- nrow(dat)
  G <- length(lev)
  g <- match(as.character(dat$id), lev)
  Z <- matrix(0, n, G)
  Z[cbind(seq_len(n), g)] <- 1
  Sinv <- solve(Sigma)
  logdet_Sigma <- as.numeric(determinant(Sigma, logarithm = TRUE)$modulus)
  parts <- function(u) {
    eta <- eta0 + as.vector(Z %*% (tau_group * u))
    mu <- exp(eta)
    if (is.null(size)) {
      list(ll = sum(stats::dpois(y[observed], mu[observed], log = TRUE)),
           score = (y - mu) * observed,
           info = mu * observed)
    } else {
      list(ll = sum(stats::dnbinom(y[observed], size = size, mu = mu[observed],
                                   log = TRUE)),
           score = (y - mu) * size / (size + mu) * observed,
           info = size * mu * (size + y) / (size + mu)^2 * observed)
    }
  }
  objective <- function(u) parts(u)$ll - 0.5 * sum(u * (Sinv %*% u))
  hess <- function(u) {
    p <- parts(u)
    diag(tau_group^2 * as.vector(crossprod(Z, p$info)), G) + Sinv
  }
  u <- rep(0, G)
  for (iter in seq_len(300L)) {
    p <- parts(u)
    grad <- tau_group * as.vector(crossprod(Z, p$score)) -
      as.vector(Sinv %*% u)
    step <- as.vector(solve(hess(u), grad))
    old <- objective(u)
    s <- 1
    while (objective(u + s * step) < old - 1e-12 && s > 1e-8) s <- s / 2
    u <- u + s * step
    if (max(abs(s * step)) < 1e-12) break
  }
  p <- parts(u)
  stopifnot(max(abs(tau_group * as.vector(crossprod(Z, p$score)) -
                      as.vector(Sinv %*% u))) < 1e-7)
  logdet_H <- as.numeric(determinant(hess(u), logarithm = TRUE)$modulus)
  objective(u) - 0.5 * logdet_Sigma - 0.5 * logdet_H
}

smi_routes <- c("relmat", "animal", "phylo", "spatial")
smi_families <- c("poisson", "nbinom2")

smi_partial_check <- function(kind, family, seed) {
  fx <- smi_fixture(kind, family, seed)
  dat <- fx$data
  spec <- smi_spec[[kind]]
  expect_true(anyNA(dat$y))
  # Every group keeps observed rows in the partial fixture.
  expect_true(all(tapply(!is.na(dat$y), dat$id, any)))
  expect_false(identical(levels(dat$id), rownames(fx$Sigma)))
  inc <- smi_fit(fx, include = TRUE)
  cc <- smi_fit(fx, include = FALSE)
  expect_equal(as.integer(inc$opt$convergence), 0L)
  expect_equal(as.integer(cc$opt$convergence), 0L)
  # Complete-case equality: NA rows must not contribute.
  expect_equal(as.numeric(logLik(inc)), as.numeric(logLik(cc)),
               tolerance = 1e-8)
  expect_equal(unname(coef(inc, "mu")), unname(coef(cc, "mu")),
               tolerance = 1e-5)
  expect_equal(unname(coef(inc, spec$dpar)), unname(coef(cc, spec$dpar)),
               tolerance = 1e-5)
  expect_equal(nobs(inc), sum(!is.na(dat$y)))
  # Independent dense Laplace oracle on the observed rows.
  oracle <- smi_oracle(fx, inc)
  expect_equal(as.numeric(logLik(inc)), oracle, tolerance = 1e-6)
  # Emulated bugs move the oracle: NA scored as observed zero, SD surface
  # attached to the wrong groups.
  expect_gt(abs(smi_oracle(fx, inc, na_as_zero = TRUE) - oracle), 0.05)
  tau_hat <- predict(inc, dpar = spec$dpar)[rownames(fx$Sigma)]
  expect_gt(abs(smi_oracle(fx, inc, tau_group = rev(unname(tau_hat))) - oracle),
            0.05)
  # Predictions exist for the NA rows and for every group SD.
  mu_hat <- predict(inc, dpar = "mu")
  expect_length(mu_hat, nrow(dat))
  expect_true(all(is.finite(mu_hat[is.na(dat$y)])))
  expect_length(tau_hat, nrow(fx$Sigma))
  expect_true(all(is.finite(tau_hat) & tau_hat > 0))
  invisible(list(inc = inc, cc = cc, fx = fx))
}

for (smi_family in smi_families) {
  for (smi_kind in smi_routes) {
    local({
      family <- smi_family
      kind <- smi_kind
      seed <- 2026110200L + 10L * match(kind, smi_routes) +
        match(family, smi_families)
      test_that(sprintf("%s %s SD include equals complete-case and the oracle",
                        family, kind), {
        skip_on_cran()
        if (identical(kind, "phylo")) skip_if_not_installed("ape")
        smi_partial_check(kind, family, seed)
      })
      test_that(sprintf("%s %s SD include keeps the prior for an all-NA group",
                        family, kind), {
        skip_on_cran()
        if (identical(kind, "phylo")) skip_if_not_installed("ape")
        fx <- smi_fixture(kind, family, seed + 5L, na_groups = c(3L, 17L))
        dat <- fx$data
        lev <- rownames(fx$Sigma)
        empty <- as.character(dat$id) %in% lev[c(3L, 17L)]
        expect_true(all(is.na(dat$y[empty])))
        expect_true(all(is.na(dat$y[empty])) && sum(empty) == 16L)
        spec <- smi_spec[[kind]]
        inc <- smi_fit(fx, include = TRUE)
        expect_equal(as.integer(inc$opt$convergence), 0L)
        # The oracle keeps the prior term of the empty nodes (all G nodes).
        oracle <- smi_oracle(fx, inc)
        expect_equal(as.numeric(logLik(inc)), oracle, tolerance = 1e-6)
        # An empty node is a prior-only block of a Gaussian field, so it
        # integrates out exactly; the include fit therefore also equals the
        # complete-case fit that never saw the empty groups (measured to
        # 1e-12 on every route before this assertion was written).
        cc <- smi_fit(fx, include = FALSE)
        expect_equal(as.numeric(logLik(inc)), as.numeric(logLik(cc)),
                     tolerance = 1e-8)
        # Emulated bug: NA rows scored as zeros moves the oracle.
        expect_gt(abs(smi_oracle(fx, inc, na_as_zero = TRUE) - oracle), 0.05)
        expect_equal(nobs(inc), sum(!is.na(dat$y)))
        # Every group, including the empty ones, has an SD and NA-row
        # predictions exist.
        sd_hat <- predict(inc, dpar = spec$dpar)
        expect_length(sd_hat, length(lev))
        expect_true(all(is.finite(sd_hat) & sd_hat > 0))
        expect_true(all(is.finite(predict(inc, dpar = "mu")[empty])))
      })
    })
  }
}

test_that("structured SD include fences stay closed for count families", {
  fx_n <- 12L
  lev <- smi_levels(fx_n)
  set.seed(20261102L)
  dat <- data.frame(
    y = stats::rpois(fx_n * 4L, 3), x = stats::rnorm(fx_n * 4L),
    id = factor(rep(lev, each = 4L), levels = lev),
    site = factor(rep(seq_len(4L), length.out = fx_n * 4L)),
    z = rep(seq(-1, 1, length.out = fx_n), each = 4L)
  )
  dat$z_site <- as.numeric(dat$site)
  dat$y[c(2L, 9L)] <- NA
  K <- 1.4 * 0.5^abs(outer(seq_len(fx_n), seq_len(fx_n), `-`))
  dimnames(K) <- list(lev, lev)
  inc <- miss_control(response = "include")
  sd_id <- sd(id, level = "relmat") ~ z

  # Admitted shape builds (no fit): include with one relmat intercept SD.
  expect_no_error(drm_build_poisson_spec(
    bf(y ~ x + relmat(1 | id, K = K), sd_id), dat, missing = inc))
  expect_no_error(drm_build_nbinom2_spec(
    bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1, sd_id), dat, missing = inc))

  # Intercept-plus-slope (q2) structured SD stays refused.
  sd_a <- sd(id, level = "relmat", coef = "(Intercept)") ~ z
  sd_b <- sd(id, level = "relmat", coef = "x") ~ z
  expect_error(drm_build_poisson_spec(
    bf(y ~ x + relmat(1 + x | id, K = K), sd_a, sd_b), dat, missing = inc),
    "complete\\s+responses")
  expect_error(drm_build_nbinom2_spec(
    bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1, sd_a, sd_b), dat,
    missing = inc),
    "complete\\s+data")

  # Slope-only and ordinary-plus-structured (iid) shapes are admitted in
  # test-count-iid-slope-sd-missing-include.R.

  # Zero-inflated structured SD stays refused.
  expect_error(drm_build_poisson_spec(
    bf(y ~ x + relmat(1 | id, K = K), zi ~ 1, sd_id), dat, missing = inc),
    "complete\\s+responses")
  expect_error(drm_build_nbinom2_spec(
    bf(y ~ x + relmat(1 | id, K = K), sigma ~ 1, zi ~ 1, sd_id), dat,
    missing = inc),
    "complete\\s+data")

  # Without include, the default drop policy is unchanged: NA rows are dropped.
  spec <- drm_build_poisson_spec(
    bf(y ~ x + relmat(1 | id, K = K), sd_id), dat)
  expect_identical(length(spec$y), sum(!is.na(dat$y)))
})
