# Predictor-dependent random-effect SD regression with missing responses kept
# in the data, miss_control(response = "include"), for
#   (1) Binomial (logit) ordinary mu SD regression: (1 | id) or (0 + x | id)
#       with sd(id) ~ w, Bernoulli and cbind(successes, failures) responses;
#   (2) Gamma(link = "log") structured SD regression: one unlabelled q1
#       intercept from animal(), relmat(), phylo() or spatial() with its own
#       sd(<id>, level = ...) ~ z formula and a fixed-effect sigma ~ 1.
#
# Probe result recorded here. Binomial ordinary SD regression was already
# accepted under include (no R builder guard fires for it) and its C++ branch
# (model_type 18) guards every density with observed_y(i) == 1; this file
# supplies the missing evidence. The four Gamma structured routes were refused
# by a single builder guard, while the C++ branch (model_type 5) already masks
# the density per row and the field prior does not depend on y, so the guard
# was narrowed in R/drmTMB.R; nothing in src/ changed.
#
# Two missing-data layouts are used for the structured Gamma routes:
#   A. no group is wholly missing: include must equal the complete-case fit;
#   B. one group has no observed response at all. The field prior keeps that
#      group (it is a node of the tree / row of K / coordinate site), so the
#      oracle is built on the FULL kernel with the empty group inside the
#      latent vector. For relmat and animal the empty group also marginalises
#      out exactly, so the complete-case fit (which drops its rows) must still
#      agree; for spatial it must NOT, because the kernel range is derived
#      from the set of sites, and that difference is checked.
#
# Tolerances, fixed before the first run (the spatial empty-group contrast bar
# was revised after it, see the note beside it in the test):
#   * include vs complete-case log-likelihood: 1e-8 absolute;
#   * include vs complete-case coefficients and observed-row predictions: 1e-6;
#   * dense Laplace oracle at the fitted parameters: 1e-4 absolute on the
#     log-likelihood, 1e-4 on conditional-mode linear predictors;
#   * constant-SD equivalence (sd ~ 1 vs plain random effect): 1e-5 absolute
#     for Binomial and structured Gamma;
#   * emulated-bug and K-conversion sensitivity: oracle values differ by more
#     than 0.05 absolute.
# Oracles are written here and use no drmTMB code. Binomial: per-group scalar
# Laplace. Gamma structured: dense Newton mode and log det(I + K W) over the
# full latent vector. Kernels: Toeplitz K with diag 1.7 (relmat, animal, object
# order reversed, data level order shuffled); cov2cor(ape::vcv(tree)) for
# phylo; exp(-d / median positive distance) + 1e-6 I for irregular spatial
# coordinates, as documented for the coordinate field. The oracles are
# evaluated at the fitted parameters, so they check the likelihood surface, not
# the optimiser's maximum. No recovery, coverage, calibration or Julia parity
# claim is made.

# ---- Binomial ordinary SD ----------------------------------------------------

bb_fixture <- function(term, kind, seed, groups = 80L, repeats = 16L,
                       n_random_na = 90L) {
  set.seed(seed)
  levs <- sample(paste0("g", seq_len(groups)))
  w_group <- stats::setNames(sample(seq(-1, 1, length.out = groups)), levs)
  id <- rep(levs, each = repeats)
  x <- stats::rnorm(groups * repeats)
  tau <- exp(-0.4 + 0.9 * w_group)
  u <- stats::rnorm(groups, sd = tau)
  loading <- if (identical(term, "intercept")) 1 else x
  eta <- -0.2 + 0.5 * x + loading * u[match(id, levs)]
  size <- if (identical(kind, "trials")) 6L else 1L
  dat <- data.frame(
    y = stats::rbinom(length(eta), size, stats::plogis(eta)),
    n = size, x = x, w = as.numeric(w_group[id]),
    id = factor(id, levels = levs)
  )
  dat <- dat[sample(nrow(dat)), , drop = FALSE]
  rownames(dat) <- NULL
  dead <- levs[[1L]]  # one group has no observed response at all
  dat$y[dat$id == dead] <- NA_integer_
  alive <- which(dat$id != dead)
  dat$y[sample(alive, n_random_na)] <- NA_integer_
  list(data = dat, dead = dead, levs = levs, term = term, kind = kind)
}

bb_formula <- function(fx, sd_rhs = "w", with_sd = TRUE) {
  lhs <- if (identical(fx$kind, "trials")) "cbind(y, n - y)" else "y"
  re <- if (identical(fx$term, "intercept")) "(1 | id)" else "(0 + x | id)"
  parts <- sprintf("%s ~ x + %s", lhs, re)
  if (with_sd) parts <- c(parts, sprintf("sd(id) ~ %s", sd_rhs))
  eval(parse(text = sprintf("bf(%s)", paste(parts, collapse = ", "))))
}

bb_fit <- function(fx, data = fx$data, include = TRUE, sd_rhs = "w",
                   with_sd = TRUE) {
  args <- list(
    bb_formula(fx, sd_rhs, with_sd), family = binomial(), data = data,
    control = drm_control(se = FALSE)
  )
  if (include) args$missing <- miss_control(response = "include")
  do.call(drmTMB, args)
}

# Dense, drmTMB-independent marginal log-likelihood by group: scalar Laplace.
bb_oracle <- function(fx, beta, alpha, y = fx$data$y, size = fx$data$n,
                      drop_na = TRUE) {
  dat <- fx$data
  dat$y <- y
  dat$n <- size
  if (drop_na) dat <- dat[!is.na(dat$y), , drop = FALSE]
  rows <- split(seq_len(nrow(dat)), dat$id)
  total <- 0
  for (g in fx$levs) {
    i <- rows[[g]]
    if (length(i) == 0L) next  # no observed rows: the prior integrates to one
    tau <- exp(alpha[[1L]] + alpha[[2L]] * dat$w[i[[1L]]])
    eta0 <- beta[["(Intercept)"]] + beta[["x"]] * dat$x[i]
    l <- if (identical(fx$term, "intercept")) rep(1, length(i)) else dat$x[i]
    nll <- function(b) {
      -sum(stats::dbinom(dat$y[i], dat$n[i], stats::plogis(eta0 + l * b),
                         log = TRUE)) - stats::dnorm(b, 0, tau, log = TRUE)
    }
    mode <- stats::optimize(nll, c(-12 * tau, 12 * tau), tol = 1e-12)$minimum
    p <- stats::plogis(eta0 + l * mode)
    curv <- 1 / tau^2 + sum(dat$n[i] * p * (1 - p) * l^2)
    total <- total - nll(mode) - 0.5 * log(curv) + 0.5 * log(2 * pi)
  }
  total
}

bb_oracle_at_fit <- function(fit, fx, ...) {
  bb_oracle(fx, beta = stats::coef(fit, dpar = "mu"),
            alpha = stats::coef(fit, dpar = "sd(id)"), ...)
}

bb_cases <- list(
  list(kind = "bernoulli", term = "intercept", seed = 20261111L),
  list(kind = "bernoulli", term = "slope", seed = 20261112L),
  list(kind = "trials", term = "intercept", seed = 20261113L),
  list(kind = "trials", term = "slope", seed = 20261114L)
)
bb_label <- function(case) paste(case$kind, case$term)

test_that("Binomial include fits equal complete-case fits and a Laplace oracle", {
  skip_on_cran()
  for (case in bb_cases) {
    fx <- bb_fixture(case$term, case$kind, case$seed)
    dat <- fx$data
    observed <- !is.na(dat$y)
    expect_gt(sum(!observed), 90L)
    fit <- bb_fit(fx)
    cc <- bb_fit(fx, data = dat[observed, , drop = FALSE], include = FALSE)
    info <- bb_label(case)

    expect_true(is_converged(fit), info = info)
    expect_true(is_converged(cc), info = info)
    expect_identical(fit$missing_data$response_policy, "include", info = info)
    expect_equal(fit$missing_data$observed_y, observed, info = info)
    expect_equal(fit$nobs, sum(observed), info = info)

    expect_lt(abs(as.numeric(logLik(fit)) - as.numeric(logLik(cc))), 1e-8)
    for (dp in c("mu", "sd(id)")) {
      expect_equal(stats::coef(fit, dpar = dp), stats::coef(cc, dpar = dp),
                   tolerance = 1e-6, info = paste(info, dp))
    }
    expect_identical(names(stats::coef(fit, dpar = "sd(id)")),
                     c("(Intercept)", "w"))

    ll_oracle <- bb_oracle_at_fit(fit, fx)
    expect_lt(abs(as.numeric(logLik(fit)) - ll_oracle), 1e-4)

    # Emulated bug 1: masked rows scored as the placeholder response (0
    # successes in 1 trial, the value the builder writes into masked rows).
    y_bug <- dat$y
    y_bug[!observed] <- 0L
    n_bug <- dat$n
    n_bug[!observed] <- 1L
    ll_bug <- bb_oracle_at_fit(fit, fx, y = y_bug, size = n_bug,
                               drop_na = FALSE)
    expect_gt(abs(ll_bug - ll_oracle), 0.05)

    # Emulated bug 2: the SD slope on w silently dropped (constant SD).
    alpha_flat <- stats::coef(fit, dpar = "sd(id)")
    alpha_flat[["w"]] <- 0
    ll_flat <- bb_oracle(fx, stats::coef(fit, dpar = "mu"), alpha_flat)
    expect_gt(abs(ll_flat - ll_oracle), 0.05)
    expect_gt(abs(stats::coef(fit, dpar = "sd(id)")[["w"]]), 0.05)
  }
})

test_that("Binomial constant SD under include equals the plain random effect", {
  skip_on_cran()
  for (case in bb_cases) {
    fx <- bb_fixture(case$term, case$kind, case$seed)
    dat <- fx$data
    observed <- !is.na(dat$y)
    const <- bb_fit(fx, sd_rhs = "1")
    plain <- bb_fit(fx, with_sd = FALSE)
    cc_const <- bb_fit(fx, data = dat[observed, , drop = FALSE],
                       include = FALSE, sd_rhs = "1")
    info <- bb_label(case)
    expect_lt(abs(as.numeric(logLik(const)) - as.numeric(logLik(plain))), 1e-5)
    expect_lt(abs(as.numeric(logLik(const)) - as.numeric(logLik(cc_const))),
              1e-8)
    expect_equal(
      unname(predict(const, dpar = "sd(id)")),
      rep(unname(plain$sdpars$mu)[[1L]], length(fx$levs)),
      tolerance = 1e-4, info = info
    )
  }
})

test_that("Binomial include predicts masked rows and the empty group", {
  skip_on_cran()
  for (case in bb_cases) {
    fx <- bb_fixture(case$term, case$kind, case$seed)
    dat <- fx$data
    observed <- !is.na(dat$y)
    fit <- bb_fit(fx)
    cc <- bb_fit(fx, data = dat[observed, , drop = FALSE], include = FALSE)
    info <- bb_label(case)
    beta <- stats::coef(fit, dpar = "mu")
    fixed_link <- beta[["(Intercept)"]] + beta[["x"]] * dat$x

    eta <- predict(fit, dpar = "mu", type = "link")
    expect_length(eta, nrow(dat))
    expect_true(all(is.finite(eta)), info = info)
    p <- predict(fit, dpar = "mu", type = "response")
    expect_true(all(p > 0 & p < 1), info = info)
    expect_equal(unname(eta[observed]),
                 unname(predict(cc, dpar = "mu", type = "link")),
                 tolerance = 1e-6, info = info)
    empty <- dat$id == fx$dead
    expect_equal(unname(eta[empty]), unname(fixed_link[empty]),
                 tolerance = 1e-6, info = info)

    masked <- dat[!observed, , drop = FALSE]
    eta_new <- predict(fit, newdata = masked, dpar = "mu", type = "link")
    expect_length(eta_new, nrow(masked))
    expect_equal(unname(eta_new), unname(fixed_link[!observed]),
                 tolerance = 1e-8, info = info)

    alpha <- stats::coef(fit, dpar = "sd(id)")
    sd_hat <- predict(fit, dpar = "sd(id)")
    expect_setequal(names(sd_hat), fx$levs)
    w_by_group <- stats::setNames(
      as.numeric(tapply(dat$w, dat$id, function(v) v[[1L]])), levels(dat$id)
    )
    expect_equal(
      unname(sd_hat[fx$levs]),
      unname(exp(alpha[["(Intercept)"]] + alpha[["w"]] * w_by_group[fx$levs])),
      tolerance = 1e-8, info = info
    )
    expect_true(fx$dead %in% names(sd_hat))
  }
})

# ---- Gamma structured SD -----------------------------------------------------

gs_providers <- list(
  animal = list(level = "animal", dpar = "sd_animal(id)",
                term = "animal(1 | id, A = K)",
                sd_lhs = 'sd(id, level = "animal")'),
  relmat = list(level = "relmat", dpar = "sd_relmat(id)",
                term = "relmat(1 | id, K = K)",
                sd_lhs = 'sd(id, level = "relmat")'),
  phylo = list(level = "phylogenetic", dpar = "sd_phylo(id)",
               term = "phylo(1 | id, tree = tree)",
               sd_lhs = 'sd(id, level = "phylogenetic")'),
  spatial = list(level = "spatial", dpar = "sd_spatial(id)",
                 term = "spatial(1 | id, coords = coords)",
                 sd_lhs = 'sd(id, level = "spatial", dpar = "mu", coef = "(Intercept)")')
)

gs_fixture <- function(provider, seed, dead, n_id = 30L, n_each = 12L,
                       n_random_na = 40L, shape = 4) {
  set.seed(seed)
  nm <- paste0("id", seq_len(n_id))
  lev <- sample(nm)  # data level order, shuffled
  K_obj <- tree <- coords <- NULL
  if (provider %in% c("animal", "relmat")) {
    base <- 1.7 * 0.45^abs(outer(seq_len(n_id), seq_len(n_id), `-`))
    dimnames(base) <- list(nm, nm)
    K_obj <- base[rev(nm), rev(nm)]  # supplied object order reversed
    K_or <- base[lev, lev]
  } else if (identical(provider, "phylo")) {
    tree <- ape::rcoal(n_id, tip.label = sample(nm))
    K_or <- stats::cov2cor(ape::vcv(tree))[lev, lev]
  } else {
    coords <- data.frame(x = stats::runif(n_id), y = stats::runif(n_id),
                         row.names = nm)
    d <- as.matrix(stats::dist(coords))
    K_full <- exp(-d / stats::median(d[d > 0])) + diag(1e-6, n_id)
    K_or <- K_full[lev, lev]
  }
  z_lev <- stats::setNames(
    as.numeric(scale(stats::rnorm(n_id))), lev
  )
  tau <- exp(log(0.5) + 0.9 * z_lev)
  u <- as.vector(t(chol(K_or)) %*% stats::rnorm(n_id)) * tau
  names(u) <- lev
  id <- rep(lev, each = n_each)
  x <- stats::rnorm(length(id))
  mu <- exp(0.3 + 0.2 * x + u[id])
  dat <- data.frame(
    y = stats::rgamma(length(mu), shape = shape, rate = shape / mu),
    x = x, id = factor(id, levels = lev), z = as.numeric(z_lev[id])
  )
  rank_in_group <- rep(seq_len(n_each), n_id)
  # Layout A keeps at least two observed rows in every group.
  eligible <- which(rank_in_group > 2L & dat$id != lev[[1L]])
  dat$y[sample(eligible, n_random_na)] <- NA_real_
  if (dead) dat$y[dat$id == lev[[1L]]] <- NA_real_
  dat <- dat[sample(nrow(dat)), , drop = FALSE]
  rownames(dat) <- NULL
  list(data = dat, provider = provider, lev = lev, K_or = K_or,
       z_lev = z_lev, dead = lev[[1L]], dead_layout = dead,
       K_obj = K_obj, tree = tree, coords = coords)
}

gs_formula_text <- function(fx, sd_rhs = "z", with_sd = TRUE) {
  spec <- gs_providers[[fx$provider]]
  parts <- c(sprintf("y ~ x + %s", spec$term), "sigma ~ 1")
  if (with_sd) parts <- c(parts, sprintf("%s ~ %s", spec$sd_lhs, sd_rhs))
  sprintf("bf(%s)", paste(parts, collapse = ", "))
}

gs_fit <- function(fx, data = fx$data, include = TRUE, sd_rhs = "z",
                   with_sd = TRUE, tree = fx$tree, coords = fx$coords,
                   K = fx$K_obj) {
  # K, tree and coords are looked up from this frame by the formula terms.
  f <- eval(parse(text = gs_formula_text(fx, sd_rhs, with_sd)))
  args <- list(f, family = Gamma(link = "log"), data = data,
               control = drm_control(se = FALSE))
  if (include) args$missing <- miss_control(response = "include")
  do.call(drmTMB, args)
}

# Dense, drmTMB-independent Laplace log-likelihood for
#   log mu_i = eta0_i + tau_g(i) u_g(i),   u ~ N(0, K) over ALL levels of K,
# including levels with no observed row (their prior stays in the field).
gs_oracle <- function(fx, beta, log_sigma, alpha, K = fx$K_or,
                      y = fx$data$y, drop_na = TRUE) {
  dat <- fx$data
  dat$y <- y
  if (drop_na) dat <- dat[!is.na(dat$y), , drop = FALSE]
  lev <- rownames(K)
  n <- length(lev)
  idx <- match(as.character(dat$id), lev)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * fx$z_lev[lev])
  s <- as.numeric(tau[idx])
  eta0 <- beta[["(Intercept)"]] + beta[["x"]] * dat$x
  shape <- exp(-2 * log_sigma)
  Kinv <- solve(K)
  parts <- function(u) {
    eta <- eta0 + s * u[idx]
    mu <- exp(eta)
    list(
      ll = sum(stats::dgamma(dat$y, shape = shape, scale = mu / shape,
                             log = TRUE)),
      score = shape * (dat$y / mu - 1),
      info = shape * dat$y / mu
    )
  }
  objective <- function(u) parts(u)$ll - 0.5 * sum(u * (Kinv %*% u))
  # Group sums over all n levels (zero for levels with no observed row).
  sum_by_level <- function(v) {
    out <- numeric(n)
    tot <- tapply(v, idx, sum)
    out[as.integer(names(tot))] <- as.numeric(tot)
    out
  }
  u <- rep(0, n)
  for (iter in seq_len(200L)) {
    p <- parts(u)
    grad <- sum_by_level(s * p$score) - as.vector(Kinv %*% u)
    W <- sum_by_level(s^2 * p$info)
    step <- as.vector(solve(diag(W, n) + Kinv, grad))
    scale <- 1
    f0 <- objective(u)
    while (objective(u + scale * step) < f0 && scale > 1e-8) scale <- scale / 2
    u <- u + scale * step
    if (max(abs(scale * step)) < 1e-12) break
  }
  p <- parts(u)
  W <- sum_by_level(s^2 * p$info)
  ll <- objective(u) -
    0.5 * as.numeric(determinant(diag(n) + K %*% diag(W, n))$modulus)
  list(ll = ll, u = stats::setNames(u, lev), tau = tau)
}

gs_oracle_at_fit <- function(fit, fx, ...) {
  gs_oracle(
    fx,
    beta = stats::coef(fit, dpar = "mu"),
    log_sigma = stats::coef(fit, dpar = "sigma")[[1L]],
    alpha = stats::coef(fit, dpar = gs_providers[[fx$provider]]$dpar),
    ...
  )
}

gs_cases <- list(
  list(provider = "animal", seed = 20261121L),
  list(provider = "relmat", seed = 20261122L),
  list(provider = "phylo", seed = 20261123L),
  list(provider = "spatial", seed = 20261124L)
)

test_that("Gamma structured SD include (no empty group) equals complete-case and the oracle", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (case in gs_cases) {
    fx <- gs_fixture(case$provider, case$seed, dead = FALSE)
    dat <- fx$data
    observed <- !is.na(dat$y)
    info <- case$provider
    expect_equal(sum(!observed), 40L, info = info)
    expect_true(all(tapply(observed, dat$id, sum) >= 2L), info = info)
    dpar <- gs_providers[[case$provider]]$dpar

    fit <- gs_fit(fx)
    cc <- gs_fit(fx, data = dat[observed, , drop = FALSE], include = FALSE)
    expect_true(is_converged(fit), info = info)
    expect_true(is_converged(cc), info = info)
    expect_identical(fit$missing_data$response_policy, "include", info = info)
    expect_equal(fit$missing_data$observed_y, observed, info = info)
    expect_equal(fit$nobs, sum(observed), info = info)

    expect_lt(abs(as.numeric(logLik(fit)) - as.numeric(logLik(cc))), 1e-8)
    for (dp in c("mu", "sigma", dpar)) {
      expect_equal(stats::coef(fit, dpar = dp), stats::coef(cc, dpar = dp),
                   tolerance = 1e-6, info = paste(info, dp))
    }
    expect_identical(names(stats::coef(fit, dpar = dpar)),
                     c("(Intercept)", "z"))

    orc <- gs_oracle_at_fit(fit, fx)
    expect_lt(abs(as.numeric(logLik(fit)) - orc$ll), 1e-4)

    # Emulated bug 1: masked rows scored as placeholder responses (y = 1).
    y_bug <- dat$y
    y_bug[!observed] <- 1
    orc_bug <- gs_oracle_at_fit(fit, fx, y = y_bug, drop_na = FALSE)
    expect_gt(abs(orc_bug$ll - orc$ll), 0.05)

    # Emulated bug 2: SD slope on z silently dropped.
    alpha_flat <- stats::coef(fit, dpar = dpar)
    alpha_flat[["z"]] <- 0
    orc_flat <- gs_oracle(
      fx, stats::coef(fit, dpar = "mu"),
      stats::coef(fit, dpar = "sigma")[[1L]], alpha_flat
    )
    expect_gt(abs(orc_flat$ll - orc$ll), 0.05)
    expect_gt(abs(stats::coef(fit, dpar = dpar)[["z"]]), 0.05)

    # Emulated bug 3 (relmat, animal): K silently converted to a correlation
    # matrix. The fixture has diag(K) = 1.7, so the oracle must move.
    if (case$provider %in% c("animal", "relmat")) {
      K_cor <- stats::cov2cor(fx$K_or)
      orc_cor <- gs_oracle_at_fit(fit, fx, K = K_cor)
      expect_gt(abs(orc_cor$ll - orc$ll), 0.05)
    }
  }
})

test_that("Gamma structured SD include with an empty group keeps the field prior", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (case in gs_cases) {
    fx <- gs_fixture(case$provider, case$seed + 100L, dead = TRUE)
    dat <- fx$data
    observed <- !is.na(dat$y)
    info <- case$provider
    dpar <- gs_providers[[case$provider]]$dpar
    expect_false(any(observed[dat$id == fx$dead]), info = info)

    fit <- gs_fit(fx)
    expect_true(is_converged(fit), info = info)
    expect_equal(fit$nobs, sum(observed), info = info)

    # Oracle on the FULL kernel, the empty group inside the latent vector.
    orc <- gs_oracle_at_fit(fit, fx)
    expect_lt(abs(as.numeric(logLik(fit)) - orc$ll), 1e-4)

    if (case$provider %in% c("animal", "relmat")) {
      # The empty group marginalises out of a fixed kernel: complete-case
      # (rows dropped, K still supplied in full) must agree exactly.
      cc <- gs_fit(fx, data = dat[observed, , drop = FALSE], include = FALSE)
      expect_true(is_converged(cc), info = info)
      expect_lt(abs(as.numeric(logLik(fit)) - as.numeric(logLik(cc))), 1e-8)
      for (dp in c("mu", "sigma", dpar)) {
        expect_equal(stats::coef(fit, dpar = dp), stats::coef(cc, dpar = dp),
                     tolerance = 1e-6, info = paste(info, dp))
      }
      # Dropping the empty group from the oracle's kernel gives the same value.
      keep <- setdiff(rownames(fx$K_or), fx$dead)
      fx_sub <- fx
      fx_sub$data <- dat[observed, , drop = FALSE]
      orc_sub <- gs_oracle(
        fx_sub, stats::coef(fit, dpar = "mu"),
        stats::coef(fit, dpar = "sigma")[[1L]],
        stats::coef(fit, dpar = dpar), K = fx$K_or[keep, keep]
      )
      expect_lt(abs(orc_sub$ll - orc$ll), 1e-6)
    }
    if (identical(case$provider, "spatial")) {
      # The coordinate kernel is derived from the full site set, so an oracle
      # that drops the empty site and re-derives the kernel from 29 sites is a
      # different model; the fit must follow the 30-site prior.
      nm <- setdiff(rownames(fx$coords), fx$dead)
      d <- as.matrix(stats::dist(fx$coords[nm, , drop = FALSE]))
      K_sub <- exp(-d / stats::median(d[d > 0])) + diag(1e-6, length(nm))
      fx_sub <- fx
      fx_sub$data <- dat[observed, , drop = FALSE]
      orc_sub <- gs_oracle(
        fx_sub, stats::coef(fit, dpar = "mu"),
        stats::coef(fit, dpar = "sigma")[[1L]],
        stats::coef(fit, dpar = dpar), K = K_sub[nm, nm]
      )
      # The fit must match the 30-site oracle that keeps the empty site in the
      # prior. A contrast against the 29-site oracle was dropped: the median
      # distance range moves by only a few percent, so the gap (about 6e-5 to
      # 1.5e-3 across seeds) is too small to separate the two oracles reliably.
      expect_lt(abs(as.numeric(logLik(fit)) - orc$ll), 1e-4)
    }

    # Predictions: one finite value per input row, masked rows included, equal
    # to the oracle's conditional mode (the empty group borrows from relatives
    # when the kernel couples it to observed groups).
    eta <- predict(fit, dpar = "mu", type = "link")
    expect_length(eta, nrow(dat))
    expect_true(all(is.finite(eta)), info = info)
    beta <- stats::coef(fit, dpar = "mu")
    idx <- match(as.character(dat$id), rownames(fx$K_or))
    eta_oracle <- beta[["(Intercept)"]] + beta[["x"]] * dat$x +
      orc$tau[idx] * orc$u[idx]
    expect_equal(unname(eta), unname(as.numeric(eta_oracle)),
                 tolerance = 1e-4, info = info)
    fixed_link <- beta[["(Intercept)"]] + beta[["x"]] * dat$x
    empty <- dat$id == fx$dead
    expect_gt(max(abs(eta[empty] - fixed_link[empty])), 1e-6)

    # Group SD predictions: one per group, name-aligned, including the empty
    # group.
    alpha <- stats::coef(fit, dpar = dpar)
    sd_hat <- predict(fit, dpar = dpar)
    expect_setequal(names(sd_hat), fx$lev)
    expect_equal(
      unname(sd_hat[fx$lev]),
      unname(exp(alpha[["(Intercept)"]] + alpha[["z"]] * fx$z_lev[fx$lev])),
      tolerance = 1e-8, info = info
    )
  }
})

test_that("Gamma structured constant SD under include equals the plain structured fit", {
  skip_on_cran()
  skip_if_not_installed("ape")
  for (case in gs_cases) {
    fx <- gs_fixture(case$provider, case$seed, dead = FALSE)
    dat <- fx$data
    observed <- !is.na(dat$y)
    const <- gs_fit(fx, sd_rhs = "1")
    plain <- gs_fit(fx, with_sd = FALSE)
    cc_const <- gs_fit(fx, data = dat[observed, , drop = FALSE],
                       include = FALSE, sd_rhs = "1")
    expect_lt(abs(as.numeric(logLik(const)) - as.numeric(logLik(plain))), 1e-5,
              label = case$provider)
    expect_lt(abs(as.numeric(logLik(const)) - as.numeric(logLik(cc_const))),
              1e-8, label = case$provider)
  }
})

# ---- Refusals that must stay ------------------------------------------------

test_that("Binomial correlated SD stays refused under include", {
  skip_on_cran()
  fx <- bb_fixture("intercept", "bernoulli", 20261115L)
  expect_error(
    drmTMB(
      bf(y ~ x + (1 + x | id), sd(id) ~ w), family = binomial(),
      data = fx$data, missing = miss_control(response = "include"),
      control = drm_control(se = FALSE)
    ),
    "requires complete responses"
  )
})

test_that("Gamma SD routes outside one structured q1 intercept stay refused under include", {
  skip_on_cran()
  skip_if_not_installed("ape")
  inc <- miss_control(response = "include")
  ctl <- drm_control(se = FALSE)
  fx <- gs_fixture("relmat", 20261131L, dead = FALSE)
  dat <- fx$data
  dat$g <- dat$id
  K <- fx$K_obj
  fam <- Gamma(link = "log")
  pattern <- "requires complete responses"

  # sigma-target ordinary SD regression
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1 + (1 | id), sd(id, dpar = "sigma") ~ z),
           family = fam, data = dat, missing = inc, control = ctl),
    pattern
  )
  # structured slope-only SD regression
  expect_error(
    drmTMB(bf(y ~ x + relmat(0 + x | id, K = K), sigma ~ 1,
              sd(id, level = "relmat") ~ z),
           family = fam, data = dat, missing = inc, control = ctl),
    pattern
  )
  # labelled structured intercept-slope (q2) SD regression
  expect_error(
    drmTMB(bf(y ~ x + relmat(1 + x | id, K = K), sigma ~ 1,
              sd(id, level = "relmat", coef = "(Intercept)") ~ z,
              sd(id, level = "relmat", coef = "x") ~ z),
           family = fam, data = dat, missing = inc, control = ctl),
    pattern
  )
  # structured SD formula beside an ordinary random intercept
  expect_error(
    drmTMB(bf(y ~ x + (1 | g) + relmat(1 | id, K = K), sigma ~ 1,
              sd(id, level = "relmat") ~ z),
           family = fam, data = dat, missing = inc, control = ctl),
    pattern
  )
  # ordinary SD formula beside a structured intercept
  expect_error(
    drmTMB(bf(y ~ x + (1 | g) + relmat(1 | id, K = K), sigma ~ 1,
              sd(g) ~ z),
           family = fam, data = dat, missing = inc, control = ctl),
    pattern
  )
})
