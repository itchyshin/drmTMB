# Native Gaussian mu, batch 5: shapes with no Gaussian direct-SD test yet.
#
#   (1) ordinary (1 | site) plus one structured intercept (animal A / Ainv,
#       relmat K / Q, phylo tree), each with its own predictor-dependent SD:
#         y ~ x + (1 | site) + <provider>(1 | id, ...)
#         sd(site) ~ z_site;  sd(id, level = <provider level>) ~ z_id
#   (2) one structured numeric-slope field with a coefficient-selected SD:
#         relmat(0 + x | id, K), spatial(0 + x | site, coords),
#         phylo(0 + x | species, tree);  sd(<g>, level = <l>, coef = "x") ~ z
#   (3) two structured providers on different groups in one model
#       (animal + spatial, phylo + animal), each with its own SD formula.
#       This is expected to be RED today: the Gaussian builder refuses a second
#       structured effect type (R/drmTMB.R, "Only one structured effect type is
#       implemented per univariate Gaussian model").
#
# Model for (1)-(3): y = X beta + sum_k Zk u_k + e, e ~ N(0, sigma^2 I),
# Cov(u_k) = diag(tau_k) K_k diag(tau_k), tau_k = exp(alpha_k0 + alpha_k1 z_k).
# Gaussian y has an exact marginal likelihood, so the oracle is the dense
# multivariate-normal density of y with V = sum_k Zk Cov(u_k) Zk' + sigma^2 I,
# evaluated in plain R at the fitted (beta, sigma, SD vectors). It does not
# touch the TMB template, the Ainv/pedigree code, or the Laplace path. The
# phylogenetic covariance is ape::vcv(tree, corr = TRUE) (the package's unit-
# diagonal tip covariance convention), not the package helper.
#
# Tolerances, fixed before the first run and never loosened:
#   oracle logLik (relative)                          1e-6
#   independent dense optimiser maximum (relative)    1e-5
#   constant-SD equivalence, logLik (relative)        2e-5
#   A vs Ainv, K vs Q logLik (relative)               1e-5
#   predict() vs coefficients                         1e-10
#   SD-slope recovery: strictly positive and within 0.8 of truth
#
# Not covered: Q / Ainv / pedigree for the slope and pair shapes, se = TRUE
# inference, profile targets, sigma-endpoint structured SDs, simulate(), any
# calibration or coverage claim, and the Julia engine.

# ---- dense oracle ------------------------------------------------------------

# blocks: list(list(Z = n x m, tau = length m, K = m x m), ...)
gb5_dense_nll <- function(y, X, beta, sigma, blocks) {
  V <- diag(sigma^2, length(y))
  for (b in blocks) {
    V <- V + b$Z %*% (outer(b$tau, b$tau) * b$K) %*% t(b$Z)
  }
  R <- chol(V)
  r <- backsolve(R, y - as.vector(X %*% beta), transpose = TRUE)
  0.5 * (length(y) * log(2 * pi) + 2 * sum(log(diag(R))) + sum(r^2))
}

# Indicator (or slope-weighted) design for one grouping factor, columns in the
# row order of K.
gb5_Z <- function(group, K, slope = NULL) {
  idx <- match(as.character(group), rownames(K))
  stopifnot(!anyNA(idx))
  Z <- matrix(0, length(idx), nrow(K))
  Z[cbind(seq_along(idx), idx)] <- if (is.null(slope)) 1 else slope
  Z
}

# SD vector aligned to the rows of K from predict(), looked up by level name.
gb5_tau <- function(fit, dpar, K) {
  p <- predict(fit, dpar = dpar)
  stopifnot(all(rownames(K) %in% names(p)))
  unname(p[rownames(K)])
}

gb5_expect_oracle <- function(fit, dat, blocks_fun, reps = 0L) {
  X <- stats::model.matrix(~x, dat)
  beta <- unname(coef(fit, "mu")[c("(Intercept)", "x")])
  sigma_hat <- unname(stats::sigma(fit))
  blocks <- blocks_fun(fit)
  nll_at_fit <- gb5_dense_nll(dat$y, X, beta, sigma_hat, blocks)
  expect_equal(
    as.numeric(stats::logLik(fit)), -nll_at_fit, tolerance = 1e-6
  )
  # Sensitivity: the oracle must move when an SD is changed.
  b2 <- blocks
  b2[[1L]]$tau <- rev(b2[[1L]]$tau)
  expect_gt(abs(gb5_dense_nll(dat$y, X, beta, sigma_hat, b2) - nll_at_fit), 1e-2)
  invisible(nll_at_fit)
}

# Independent dense optimiser. `make_blocks(tau_list)` returns the blocks for
# given per-block SD vectors; `z_list` holds the group-level SD predictors, one
# per block, aligned to the rows of each K.
gb5_expect_dense_max <- function(fit, dat, make_blocks, z_list) {
  X <- stats::model.matrix(~x, dat)
  nb <- length(z_list)
  obj <- function(par) {
    tau <- lapply(seq_len(nb), function(k) {
      exp(par[[3L + 2L * k - 1L]] + par[[3L + 2L * k]] * z_list[[k]])
    })
    gb5_dense_nll(dat$y, X, par[1:2], exp(par[[3L]]), make_blocks(tau))
  }
  start <- c(unname(stats::coef(stats::lm(y ~ x, dat))), log(0.4),
             rep(c(log(0.4), 0), nb))
  opt <- stats::optim(
    start, obj, method = "L-BFGS-B",
    lower = c(-Inf, -Inf, -5, rep(c(-5, -3), nb)),
    upper = c(Inf, Inf, 2, rep(c(2, 3), nb)),
    # factr = 10 asks for a relative reduction of 2e-15, below what the dense
    # objective resolves once BLAS threading changes the rounding order; L-BFGS-B
    # then stops with code 52 (abnormal line search) at the same optimum.
    # factr = 1e3 (2e-13) is the optimiser stopping rule only: the comparison
    # with the fitted logLik below keeps its 1e-5 tolerance.
    control = list(maxit = 500L, factr = 1e3)
  )
  expect_equal(opt$convergence, 0L)
  expect_equal(as.numeric(stats::logLik(fit)), -opt$value, tolerance = 1e-5)
  invisible(opt)
}

# ---- covariance fixtures -----------------------------------------------------

gb5_kernel <- function(kind, n, seed, prefix = "id") {
  set.seed(seed)
  levels_ <- paste0(prefix, seq_len(n))
  if (identical(kind, "phylo")) {
    tree <- ape::rcoal(n)
    tree$tip.label <- sample(levels_)
    K <- ape::vcv(tree, corr = TRUE) # package convention: unit-diagonal tip covariance
    return(list(K = K, tree = tree))
  }
  base <- 1.6 * 0.45^abs(outer(seq_len(n), seq_len(n), `-`))
  dimnames(base) <- list(levels_, levels_)
  ord <- c(seq.int(1L, n, by = 2L), seq.int(2L, n, by = 2L)) # not level order
  list(K = base[ord, ord], tree = NULL)
}

gb5_spatial_kernel <- function(n_site) {
  site_levels <- paste0("site_", seq_len(n_site))
  th <- seq(0, 2 * pi, length.out = n_site + 1L)[-1L]
  coords <- data.frame(x = cos(th), y = sin(th), row.names = site_levels)
  coords <- coords[rev(site_levels), , drop = FALSE] # row order != levels
  prec <- drmTMB:::drm_spatial_coords_precision(
    coords, site = site_levels, group = "site"
  )
  K <- solve(as.matrix(prec$precision))
  dimnames(K) <- list(site_levels, site_levels)
  list(K = K, coords = coords)
}

gb5_draw <- function(K, tau) {
  stats::setNames(
    tau[rownames(K)] * as.vector(t(chol(K)) %*% stats::rnorm(nrow(K))),
    rownames(K)
  )
}

gb5_z <- function(levels_) {
  stats::setNames(
    seq(-1, 1, length.out = length(levels_))[sample.int(length(levels_))],
    levels_
  )
}

# ---- (1) ordinary + structured intercept ------------------------------------

gb5_providers <- list(
  animal_A = list(
    term = "animal(1 | id, A = A)", level = "animal", kind = "animal",
    dpar = "sd_animal(id)"
  ),
  animal_Ainv = list(
    term = "animal(1 | id, Ainv = Ainv)", level = "animal", kind = "animal",
    dpar = "sd_animal(id)"
  ),
  relmat_K = list(
    term = "relmat(1 | id, K = K)", level = "relmat", kind = "animal",
    dpar = "sd_relmat(id)"
  ),
  relmat_Q = list(
    term = "relmat(1 | id, Q = Q)", level = "relmat", kind = "animal",
    dpar = "sd_relmat(id)"
  ),
  phylo = list(
    term = "phylo(1 | id, tree = tree)", level = "phylogenetic",
    kind = "phylo", dpar = "sd_phylo(id)"
  )
)

gb5_alpha_id <- c(`(Intercept)` = log(0.55), z_id = 0.6)
gb5_alpha_site <- c(`(Intercept)` = log(0.5), z_site = 0.6)

gb5_iid_fixture <- function(kind, n_id = 60L, n_site = 40L, n_each = 5L,
                            seed = 20261201L) {
  km <- gb5_kernel(kind, n_id, seed)
  K <- km$K
  set.seed(seed + 1L)
  id_levels <- rownames(K)
  site_levels <- paste0("site", seq_len(n_site))
  z_id <- gb5_z(id_levels)
  z_site <- gb5_z(site_levels)
  u <- gb5_draw(K, exp(gb5_alpha_id[[1L]] + gb5_alpha_id[[2L]] * z_id))
  Ks <- diag(n_site); dimnames(Ks) <- list(site_levels, site_levels)
  v <- gb5_draw(
    Ks, exp(gb5_alpha_site[[1L]] + gb5_alpha_site[[2L]] * z_site)
  )
  n_obs <- n_id * n_each
  id_chr <- rep(id_levels, each = n_each)
  site_chr <- site_levels[sample.int(n_site, n_obs, replace = TRUE)]
  x <- stats::rnorm(n_obs)
  y <- 0.3 + 0.2 * x + u[id_chr] + v[site_chr] + stats::rnorm(n_obs, sd = 0.3)
  list(
    data = data.frame(
      y = unname(y), x = x,
      id = factor(id_chr, levels = rev(id_levels)),
      site = factor(site_chr, levels = site_levels),
      z_id = unname(z_id[id_chr]), z_site = unname(z_site[site_chr])
    ),
    K = K, Ks = Ks, Q = solve(K)[rownames(K), rownames(K)], tree = km$tree,
    z_id = z_id, z_site = z_site, id_levels = id_levels,
    site_levels = site_levels
  )
}

gb5_iid_formula <- function(fx, provider, sd_struct = "z_id", sd_iid = "z_site") {
  K <- fx$K
  Q <- fx$Q
  A <- K
  Ainv <- Q
  tree <- fx$tree
  spec <- gb5_providers[[provider]]
  parts <- paste("y ~ x + (1 | site) +", spec$term)
  if (!is.null(sd_struct)) {
    parts <- c(parts, sprintf(
      "sd(id, level = \"%s\") ~ %s", spec$level, sd_struct
    ))
  }
  if (!is.null(sd_iid)) parts <- c(parts, sprintf("sd(site) ~ %s", sd_iid))
  eval(parse(text = sprintf("bf(%s)", paste(parts, collapse = ", "))))
}

gb5_iid_fit <- function(fx, provider, ...) {
  drmTMB(
    gb5_iid_formula(fx, provider, ...),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
}

gb5_check_iid_provider <- function(provider) {
  fx <- gb5_iid_fixture(gb5_providers[[provider]]$kind)
  spec <- gb5_providers[[provider]]
  fit <- gb5_iid_fit(fx, provider)
  dat <- fx$data
  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, spec$dpar), c("(Intercept)", "z_id"))
  expect_named(coef(fit, "sd(site)"), c("(Intercept)", "z_site"))

  # Predictions are keyed by level name, not by factor-level position.
  a_id <- coef(fit, spec$dpar)
  a_site <- coef(fit, "sd(site)")
  sd_id <- predict(fit, dpar = spec$dpar)
  sd_site <- predict(fit, dpar = "sd(site)")
  expect_setequal(names(sd_id), fx$id_levels)
  expect_setequal(names(sd_site), fx$site_levels)
  expect_equal(
    unname(sd_id[fx$id_levels]),
    unname(exp(a_id[[1L]] + a_id[[2L]] * fx$z_id[fx$id_levels])),
    tolerance = 1e-10
  )
  expect_equal(
    unname(sd_site[fx$site_levels]),
    unname(exp(a_site[[1L]] + a_site[[2L]] * fx$z_site[fx$site_levels])),
    tolerance = 1e-10
  )

  # Signed recovery of both SD slopes.
  expect_gt(a_id[["z_id"]], 0)
  expect_gt(a_site[["z_site"]], 0)
  expect_lt(abs(a_id[["z_id"]] - gb5_alpha_id[["z_id"]]), 0.8)
  expect_lt(abs(a_site[["z_site"]] - gb5_alpha_site[["z_site"]]), 0.8)

  # Exact oracle, structured block first.
  blocks_fun <- function(f) list(
    list(Z = gb5_Z(dat$id, fx$K), tau = gb5_tau(f, spec$dpar, fx$K), K = fx$K),
    list(Z = gb5_Z(dat$site, fx$Ks), tau = gb5_tau(f, "sd(site)", fx$Ks),
         K = fx$Ks)
  )
  gb5_expect_oracle(fit, dat, blocks_fun)
  make_blocks <- function(tau) list(
    list(Z = gb5_Z(dat$id, fx$K), tau = tau[[1L]], K = fx$K),
    list(Z = gb5_Z(dat$site, fx$Ks), tau = tau[[2L]], K = fx$Ks)
  )
  gb5_expect_dense_max(
    fit, dat, make_blocks,
    list(fx$z_id[rownames(fx$K)], fx$z_site[rownames(fx$Ks)])
  )

  # Constant-SD limit equals the base model with no sd() formulas.
  base_fit <- gb5_iid_fit(fx, provider, sd_struct = NULL, sd_iid = NULL)
  const_fit <- gb5_iid_fit(fx, provider, sd_struct = "1", sd_iid = "1")
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(const_fit$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(const_fit)), as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
  # A nested model cannot beat the SD-regression model.
  expect_lte(as.numeric(logLik(const_fit)), as.numeric(logLik(fit)) + 1e-6)
  fit
}

test_that("Gaussian ordinary plus animal A intercepts match the exact oracle", {
  skip_on_cran()
  gb5_check_iid_provider("animal_A")
})

test_that("Gaussian ordinary plus relmat K intercepts match the exact oracle", {
  skip_on_cran()
  gb5_check_iid_provider("relmat_K")
})

test_that("Gaussian ordinary plus phylogenetic intercepts match the exact oracle", {
  skip_on_cran()
  gb5_check_iid_provider("phylo")
})

test_that("Gaussian ordinary plus structured Ainv and Q equal the A and K fits", {
  skip_on_cran()
  fx <- gb5_iid_fixture("animal")
  for (pair in list(c("animal_A", "animal_Ainv"), c("relmat_K", "relmat_Q"))) {
    ref <- gb5_iid_fit(fx, pair[[1L]])
    alt <- gb5_iid_fit(fx, pair[[2L]])
    expect_equal(alt$opt$convergence, 0L)
    expect_equal(
      as.numeric(logLik(alt)), as.numeric(logLik(ref)), tolerance = 1e-5
    )
    dpar <- gb5_providers[[pair[[1L]]]]$dpar
    expect_equal(
      unname(coef(alt, dpar)), unname(coef(ref, dpar)), tolerance = 1e-3
    )
  }
})

test_that("Gaussian ordinary plus structured SD formula order does not matter", {
  skip_on_cran()
  fx <- gb5_iid_fixture("animal")
  K <- fx$K
  A <- K
  dat <- fx$data
  swapped <- drmTMB(
    bf(
      y ~ x + (1 | site) + animal(1 | id, A = A),
      sd(site) ~ z_site, sd(id, level = "animal") ~ z_id
    ),
    family = stats::gaussian(), data = dat, control = drm_control(se = FALSE)
  )
  ref <- gb5_iid_fit(fx, "animal_A")
  expect_equal(
    as.numeric(logLik(swapped)), as.numeric(logLik(ref)), tolerance = 1e-6
  )
})

# ---- (2) structured numeric-slope fields ------------------------------------

gb5_alpha_slope <- c(`(Intercept)` = log(0.5), z = 0.6)

gb5_slope_fixture <- function(kind, n_g = 60L, n_each = 5L, seed = 20261211L) {
  if (identical(kind, "spatial")) {
    km <- gb5_spatial_kernel(n_g)
    group <- "site"
  } else {
    km <- gb5_kernel(kind, n_g, seed, prefix = "g")
    group <- if (identical(kind, "phylo")) "species" else "id"
  }
  K <- km$K
  set.seed(seed + 1L)
  g_levels <- rownames(K)
  z_g <- gb5_z(g_levels)
  u <- gb5_draw(K, exp(gb5_alpha_slope[[1L]] + gb5_alpha_slope[[2L]] * z_g))
  g_chr <- rep(if (identical(kind, "spatial")) sort(g_levels) else g_levels,
               each = n_each)
  x <- stats::rnorm(length(g_chr))
  y <- 0.2 + 0.5 * x + u[g_chr] * x + stats::rnorm(length(g_chr), sd = 0.3)
  dat <- data.frame(
    y = unname(y), x = x,
    g = factor(g_chr, levels = rev(unique(g_chr))),
    z = unname(z_g[g_chr])
  )
  names(dat)[names(dat) == "g"] <- group
  list(
    data = dat, K = K, Q = solve(K)[g_levels, g_levels], tree = km$tree,
    coords = km$coords, z_g = z_g, g_levels = g_levels, group = group
  )
}

gb5_slope_specs <- list(
  relmat = list(
    kind = "animal", term = "relmat(0 + x | id, K = K)", group = "id",
    level = "relmat", dpar = "sd_relmat(id)"
  ),
  spatial = list(
    kind = "spatial", term = "spatial(0 + x | site, coords = coords)",
    group = "site", level = "spatial", dpar = "sd_spatial(site)"
  ),
  phylo = list(
    kind = "phylo", term = "phylo(0 + x | species, tree = tree)",
    group = "species", level = "phylogenetic", dpar = "sd_phylo(species)"
  )
)

gb5_slope_fit <- function(fx, spec, sd_rhs = "z") {
  K <- fx$K
  coords <- fx$coords
  tree <- fx$tree
  f <- if (is.null(sd_rhs)) {
    sprintf("bf(y ~ x + %s)", spec$term)
  } else {
    sprintf(
      "bf(y ~ x + %s, sd(%s, level = \"%s\", coef = \"x\") ~ %s)",
      spec$term, spec$group, spec$level, sd_rhs
    )
  }
  drmTMB(
    eval(parse(text = f)), family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
}

gb5_check_slope <- function(name) {
  spec <- gb5_slope_specs[[name]]
  fx <- gb5_slope_fixture(spec$kind)
  dat <- fx$data
  fit <- gb5_slope_fit(fx, spec)
  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, spec$dpar), c("(Intercept)", "z"))

  a <- coef(fit, spec$dpar)
  sd_hat <- predict(fit, dpar = spec$dpar)
  expect_setequal(names(sd_hat), fx$g_levels)
  expect_equal(
    unname(sd_hat[fx$g_levels]),
    unname(exp(a[[1L]] + a[[2L]] * fx$z_g[fx$g_levels])),
    tolerance = 1e-10
  )
  expect_gt(a[["z"]], 0)
  expect_lt(abs(a[["z"]] - gb5_alpha_slope[["z"]]), 0.8)

  grp <- dat[[spec$group]]
  blocks_fun <- function(f) list(list(
    Z = gb5_Z(grp, fx$K, slope = dat$x), tau = gb5_tau(f, spec$dpar, fx$K),
    K = fx$K
  ))
  gb5_expect_oracle(fit, dat, blocks_fun)
  make_blocks <- function(tau) list(list(
    Z = gb5_Z(grp, fx$K, slope = dat$x), tau = tau[[1L]], K = fx$K
  ))
  gb5_expect_dense_max(fit, dat, make_blocks, list(fx$z_g[rownames(fx$K)]))

  base_fit <- gb5_slope_fit(fx, spec, sd_rhs = NULL)
  const_fit <- gb5_slope_fit(fx, spec, sd_rhs = "1")
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(const_fit$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(const_fit)), as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
  fit
}

test_that("Gaussian relmat K numeric slope supports a coefficient SD formula", {
  skip_on_cran()
  gb5_check_slope("relmat")
})

test_that("Gaussian coordinate-spatial numeric slope supports a coefficient SD formula", {
  skip_on_cran()
  gb5_check_slope("spatial")
})

test_that("Gaussian phylogenetic numeric slope supports a coefficient SD formula", {
  skip_on_cran()
  gb5_check_slope("phylo")
})

# ---- (3) two structured providers (expected red today) ----------------------

gb5_pair_fixture <- function(second, seed = 20261221L, n_a = 50L, n_b = 30L) {
  ka <- gb5_kernel("animal", n_a, seed, prefix = "a")
  K1 <- ka$K
  if (identical(second, "spatial")) {
    kb <- gb5_spatial_kernel(n_b)
  } else {
    kb <- gb5_kernel("phylo", n_b, seed + 7L, prefix = "p")
  }
  K2 <- kb$K
  set.seed(seed + 1L)
  z1 <- gb5_z(rownames(K1))
  z2 <- gb5_z(rownames(K2))
  al1 <- c(`(Intercept)` = log(0.5), z1 = 0.6)
  al2 <- c(`(Intercept)` = log(0.5), z2 = 0.6)
  u1 <- gb5_draw(K1, exp(al1[[1L]] + al1[[2L]] * z1))
  u2 <- gb5_draw(K2, exp(al2[[1L]] + al2[[2L]] * z2))
  n_obs <- n_a * 6L
  a_chr <- rep(rownames(K1), each = 6L)
  b_chr <- rownames(K2)[sample.int(n_b, n_obs, replace = TRUE)]
  x <- stats::rnorm(n_obs)
  y <- 0.3 + 0.2 * x + u1[a_chr] + u2[b_chr] + stats::rnorm(n_obs, sd = 0.3)
  list(
    data = data.frame(
      y = unname(y), x = x,
      animal_id = factor(a_chr, levels = rev(rownames(K1))),
      grp2 = factor(b_chr, levels = rev(rownames(K2))),
      z1 = unname(z1[a_chr]), z2 = unname(z2[b_chr])
    ),
    K1 = K1, K2 = K2, z1 = z1, z2 = z2, tree = kb$tree, coords = kb$coords
  )
}

gb5_check_pair <- function(second) {
  fx <- gb5_pair_fixture(second)
  A <- fx$K1
  tree <- fx$tree
  coords <- fx$coords
  dat <- fx$data
  if (identical(second, "spatial")) {
    names(dat)[names(dat) == "grp2"] <- "site"
    rhs <- "y ~ x + animal(1 | animal_id, A = A) + spatial(1 | site, coords = coords)"
    sd2 <- "sd(site, level = \"spatial\") ~ z2"
    dpar2 <- "sd_spatial(site)"
    grp2 <- "site"
  } else {
    names(dat)[names(dat) == "grp2"] <- "species"
    rhs <- "y ~ x + animal(1 | animal_id, A = A) + phylo(1 | species, tree = tree)"
    sd2 <- "sd(species, level = \"phylogenetic\") ~ z2"
    dpar2 <- "sd_phylo(species)"
    grp2 <- "species"
  }
  fml <- eval(parse(text = sprintf(
    "bf(%s, sd(animal_id, level = \"animal\") ~ z1, %s)", rhs, sd2
  )))
  # RED today at the Gaussian structured-type guard.
  fit <- drmTMB(
    fml, family = stats::gaussian(), data = dat,
    control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd_animal(animal_id)"), c("(Intercept)", "z1"))
  expect_named(coef(fit, dpar2), c("(Intercept)", "z2"))
  blocks_fun <- function(f) list(
    list(Z = gb5_Z(dat$animal_id, fx$K1),
         tau = gb5_tau(f, "sd_animal(animal_id)", fx$K1), K = fx$K1),
    list(Z = gb5_Z(dat[[grp2]], fx$K2),
         tau = gb5_tau(f, dpar2, fx$K2), K = fx$K2)
  )
  gb5_expect_oracle(fit, dat, blocks_fun)
  fit
}

test_that("Gaussian animal plus spatial intercepts take separate SD formulas", {
  testthat::skip("Held route, not implemented: Gaussian structured-plus-structured pairs need a multi-layer engine; recorded in docs/dev-log/general-sd-regression/phase1-milestone.md")
  skip_on_cran()
  gb5_check_pair("spatial")
})

test_that("Gaussian phylogenetic plus animal intercepts take separate SD formulas", {
  testthat::skip("Held route, not implemented: Gaussian structured-plus-structured pairs need a multi-layer engine; recorded in docs/dev-log/general-sd-regression/phase1-milestone.md")
  skip_on_cran()
  gb5_check_pair("phylo")
})
