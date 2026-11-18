# Precision-input quick wins for predictor-dependent random-effect SDs.
#
#   (1) Poisson and NB2 slope-only relmat(0 + x | id, Q = Q) with
#       sd(id, level = "relmat") ~ z, fitted from the precision matrix alone.
#   (2) Gaussian, Poisson and NB2 ordinary (1 | site) plus
#       animal(1 | id, Ainv = Ainv) intercepts, each with its own SD formula.
#
# Both routes are fitted from the precision matrix only. The covariance that the
# oracle uses is solve(Q) computed here, so the oracle shares no code with the
# package's Q handling.
#
# Oracle: one dense, drmTMB-independent Laplace routine over the standardised
# latent f ~ N(0, S) with eta = X beta + J f, where J carries the SD scaling.
#   slope block:      J[i, level] = sd_level * x_i
#   intercept blocks: J[i, level] = sd_level
# Laplace value: ll(f*) - f*' S^-1 f* / 2 - logdet(I + S J' W J) / 2, with W the
# observed information in eta at the inner mode f* (Poisson: mu; NB2:
# size mu (size + y) / (size + mu)^2). Gaussian uses the exact marginal normal
# density, V = J S J' + sigma^2 I, with no Laplace step at all.
#
# Tolerances are fixed before the first run and are never loosened:
#   oracle agreement, absolute on the log-likelihood       1e-4
#   Gaussian exact oracle, absolute on the log-likelihood   1e-6
#   constant-SD equivalence, absolute on the log-likelihood 1e-4
#   Q-versus-K and Ainv-versus-A agreement, absolute        1e-4
#   predict() against the SD coefficients                   1e-8
#   SD-slope recovery on z (slope-only 0.6, intercepts 0.6; Gaussian 0.8)
#   emulated-bug sensitivity: the oracle must move by more than 0.05
#
# Not covered: se = TRUE inference, profile targets, simulation-based coverage,
# missing responses, and the Julia engine.

# ---- dense oracle ------------------------------------------------------------

sqa_family_pieces <- function(family, size = NA_real_) {
  if (identical(family, "poisson")) {
    list(
      loglik = function(y, mu) sum(stats::dpois(y, mu, log = TRUE)),
      score = function(y, mu) y - mu,
      info = function(y, mu) mu
    )
  } else {
    list(
      loglik = function(y, mu) {
        sum(stats::dnbinom(y, size = size, mu = mu, log = TRUE))
      },
      score = function(y, mu) size * (y - mu) / (size + mu),
      info = function(y, mu) size * mu * (size + y) / (size + mu)^2
    )
  }
}

sqa_dense_laplace <- function(family, y, eta0, J, S, size = NA_real_) {
  fam <- sqa_family_pieces(family, size)
  m <- ncol(J)
  Sinv <- solve(S)
  logjoint <- function(f) {
    fam$loglik(y, exp(eta0 + as.vector(J %*% f))) - 0.5 * sum(f * (Sinv %*% f))
  }
  f <- rep(0, m)
  for (iter in seq_len(300L)) {
    mu <- exp(eta0 + as.vector(J %*% f))
    grad <- as.vector(crossprod(J, fam$score(y, mu))) - as.vector(Sinv %*% f)
    H <- crossprod(J, fam$info(y, mu) * J) + Sinv
    step <- as.vector(solve(H, grad))
    scale <- 1
    f0 <- logjoint(f)
    while (logjoint(f + scale * step) < f0 && scale > 1e-8) scale <- scale / 2
    f <- f + scale * step
    if (max(abs(scale * step)) < 1e-12) break
  }
  mu <- exp(eta0 + as.vector(J %*% f))
  WJ <- crossprod(J, fam$info(y, mu) * J)
  logjoint(f) - 0.5 * as.numeric(determinant(diag(m) + S %*% WJ)$modulus)
}

sqa_gaussian_exact <- function(y, eta0, J, S, sigma) {
  V <- J %*% S %*% t(J) + diag(sigma^2, length(y))
  R <- chol(V)
  r <- backsolve(R, y - eta0, transpose = TRUE)
  -0.5 * (length(y) * log(2 * pi) + 2 * sum(log(diag(R))) + sum(r^2))
}

# ---- fixtures ----------------------------------------------------------------

# Non-unit-diagonal covariance whose row order differs from level order.
sqa_kernel <- function(n, scale = 1.7, rho = 0.45, prefix = "id") {
  ids <- paste0(prefix, seq_len(n))
  base <- scale * rho^abs(outer(seq_len(n), seq_len(n), `-`))
  dimnames(base) <- list(ids, ids)
  ord <- c(seq.int(1L, n, by = 2L), seq.int(2L, n, by = 2L))
  base[ord, ord]
}

sqa_precision <- function(K) {
  Q <- solve(K)
  dimnames(Q) <- dimnames(K)
  Q
}

sqa_draw <- function(K, sd_by_level) {
  stats::setNames(
    sd_by_level[rownames(K)] * as.vector(t(chol(K)) %*% stats::rnorm(nrow(K))),
    rownames(K)
  )
}

sqa_sigma_nb2 <- 0.35

sqa_draw_y <- function(family, mu) {
  switch(
    family,
    gaussian = mu + stats::rnorm(length(mu), sd = 0.3),
    poisson = stats::rpois(length(mu), mu),
    nb2 = stats::rnbinom(length(mu), size = 1 / sqa_sigma_nb2^2, mu = mu)
  )
}

sqa_family_object <- function(family) {
  switch(
    family,
    gaussian = stats::gaussian(),
    poisson = stats::poisson(),
    nb2 = nbinom2()
  )
}

# Slope-only fixture: data rows shuffled, factor levels follow K's order.
sqa_slope_fixture <- function(family, K, seed, n_each = 12L) {
  set.seed(seed)
  ids <- rownames(K)
  z_id <- stats::setNames(rep(c(-0.5, 0.5), length.out = length(ids)), ids)
  alpha <- c(`(Intercept)` = log(0.6), z = 0.4)
  slope <- sqa_draw(K, exp(alpha[[1L]] + alpha[[2L]] * z_id))
  id <- factor(rep(ids, each = n_each), levels = ids)
  x <- rep(seq(-1, 1, length.out = n_each), times = length(ids))
  mu <- exp(0.3 + 0.2 * x + slope[as.character(id)] * x)
  data <- data.frame(
    y = sqa_draw_y(family, mu), id = id, x = x,
    z = unname(z_id[as.character(id)])
  )
  data <- data[sample(nrow(data)), , drop = FALSE]
  rownames(data) <- NULL
  list(data = data, alpha = alpha, z_id = z_id, K = K)
}

sqa_slope_fit <- function(family, data, Q, sd_rhs = "z") {
  nb2 <- identical(family, "nb2")
  f <- if (is.null(sd_rhs)) {
    if (nb2) bf(y ~ x + relmat(0 + x | id, Q = Q), sigma ~ 1)
    else bf(y ~ x + relmat(0 + x | id, Q = Q))
  } else if (identical(sd_rhs, "z")) {
    if (nb2) {
      bf(y ~ x + relmat(0 + x | id, Q = Q), sigma ~ 1,
         sd(id, level = "relmat") ~ z)
    } else {
      bf(y ~ x + relmat(0 + x | id, Q = Q), sd(id, level = "relmat") ~ z)
    }
  } else {
    if (nb2) {
      bf(y ~ x + relmat(0 + x | id, Q = Q), sigma ~ 1,
         sd(id, level = "relmat") ~ 1)
    } else {
      bf(y ~ x + relmat(0 + x | id, Q = Q), sd(id, level = "relmat") ~ 1)
    }
  }
  drmTMB(f, family = sqa_family_object(family), data = data,
         control = drm_control(se = FALSE))
}

sqa_nb2_size <- function(fit) 1 / exp(fit$coefficients$sigma[[1L]])^2

# ---- (1) Poisson and NB2 slope-only relmat Q --------------------------------

sqa_slope_oracle <- function(family, fit, fx, sd_by_level) {
  K <- fx$K
  idx <- match(as.character(fx$data$id), rownames(K))
  x <- fx$data$x
  J <- matrix(0, nrow(fx$data), nrow(K))
  J[cbind(seq_along(idx), idx)] <- sd_by_level[idx] * x
  beta <- fit$coefficients$mu[c("(Intercept)", "x")]
  sqa_dense_laplace(
    family, fx$data$y, beta[[1L]] + beta[[2L]] * x, J, K,
    size = if (identical(family, "nb2")) sqa_nb2_size(fit) else NA_real_
  )
}

sqa_check_slope_q <- function(family) {
  K <- sqa_kernel(60L)
  expect_gt(max(diag(K)), 1.5)
  Q <- sqa_precision(K)
  fx <- sqa_slope_fixture(family, K, seed = 20261201L)
  expect_false(identical(rownames(K), sort(rownames(K))))

  fit_Q <- sqa_slope_fit(family, fx$data, Q)
  expect_equal(fit_Q$opt$convergence, 0L, info = family)
  expect_named(coef(fit_Q, "sd_relmat(id)"), c("(Intercept)", "z"))
  sd_coef <- coef(fit_Q, "sd_relmat(id)")
  expect_lt(abs(sd_coef[["z"]] - fx$alpha[["z"]]), 0.6)

  sd_pred <- predict(fit_Q, dpar = "sd_relmat(id)")
  expect_setequal(names(sd_pred), rownames(K))
  expect_equal(
    unname(sd_pred),
    unname(exp(sd_coef[["(Intercept)"]] +
      sd_coef[["z"]] * fx$z_id[names(sd_pred)])),
    tolerance = 1e-8
  )

  oracle <- sqa_slope_oracle(family, fit_Q, fx, sd_pred[rownames(K)])
  expect_lt(abs(as.numeric(logLik(fit_Q)) - oracle), 1e-4)
  # Emulated bugs: SDs attached to reversed levels, or to a sign-flipped z.
  reversed <- sqa_slope_oracle(family, fit_Q, fx, rev(sd_pred[rownames(K)]))
  expect_gt(abs(reversed - oracle), 0.05)
  flipped <- exp(sd_coef[["(Intercept)"]] -
    sd_coef[["z"]] * fx$z_id[rownames(K)])
  expect_gt(
    abs(sqa_slope_oracle(family, fit_Q, fx, flipped) - oracle), 0.05
  )
  # Treating Q as a covariance (the precision-as-K bug) must move the oracle.
  fx_wrong <- fx
  fx_wrong$K <- Q
  expect_gt(
    abs(sqa_slope_oracle(family, fit_Q, fx_wrong, sd_pred[rownames(K)]) -
      oracle),
    0.05
  )

  # Constant-SD limit equals the base model with no sd() formula.
  const_fit <- sqa_slope_fit(family, fx$data, Q, sd_rhs = "1")
  base_fit <- sqa_slope_fit(family, fx$data, Q, sd_rhs = NULL)
  expect_equal(const_fit$opt$convergence, 0L)
  expect_equal(base_fit$opt$convergence, 0L)
  expect_lt(
    abs(as.numeric(logLik(const_fit)) - as.numeric(logLik(base_fit))), 1e-4
  )

  # The precision and covariance routes are the same model.
  nb2 <- identical(family, "nb2")
  fit_K <- drmTMB(
    if (nb2) {
      bf(y ~ x + relmat(0 + x | id, K = K), sigma ~ 1,
         sd(id, level = "relmat") ~ z)
    } else {
      bf(y ~ x + relmat(0 + x | id, K = K), sd(id, level = "relmat") ~ z)
    },
    family = sqa_family_object(family), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_lt(abs(as.numeric(logLik(fit_Q)) - as.numeric(logLik(fit_K))), 1e-4)
  invisible(list(fit = fit_Q, fx = fx, Q = Q))
}

test_that("Poisson relmat slope SDs fitted from Q match the dense oracle", {
  skip_on_cran()
  res <- sqa_check_slope_q("poisson")
  fit <- res$fit
  simulated <- simulate(fit, nsim = 1L, seed = 20261202L, re.form = NULL)
  expect_length(simulated[[1L]], nrow(fit$data))
  expect_true(all(simulated[[1L]] == as.integer(simulated[[1L]])))
})

test_that("NB2 relmat slope SDs fitted from Q match the dense oracle", {
  skip_on_cran()
  res <- sqa_check_slope_q("nb2")
  fit <- res$fit
  simulated <- simulate(fit, nsim = 1L, seed = 20261203L, re.form = NULL)
  expect_length(simulated[[1L]], nrow(fit$data))
  expect_true(all(simulated[[1L]] >= 0L))
})

test_that("relmat slope Q SD routes keep their refusals", {
  skip_on_cran()
  K <- sqa_kernel(20L)
  Q <- sqa_precision(K)
  fx <- sqa_slope_fixture("poisson", K, seed = 20261204L, n_each = 6L)
  data <- fx$data
  # The SD predictor must be constant within each level.
  bad <- data
  bad$z[1L] <- bad$z[1L] + 1
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(0 + x | id, Q = Q), sd(id, level = "relmat") ~ z),
      family = stats::poisson(), data = bad,
      control = drm_control(se = FALSE)
    ),
    "constant within|varies within"
  )
  # An SD formula for a level that the model does not have is refused.
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(0 + x | id, Q = Q),
         sd(id, level = "animal") ~ z),
      family = stats::poisson(), data = data,
      control = drm_control(se = FALSE)
    ),
    "does not match"
  )
  # Q without dimnames cannot be aligned to the levels.
  Q_bare <- unname(Q)
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(0 + x | id, Q = Q_bare),
         sd(id, level = "relmat") ~ z),
      family = stats::poisson(), data = data,
      control = drm_control(se = FALSE)
    ),
    "non-empty row and column names"
  )
})

# ---- (2) ordinary plus animal Ainv intercepts --------------------------------

sqa_alpha_id <- c(`(Intercept)` = log(0.5), z_id = 0.5)
sqa_alpha_site <- c(`(Intercept)` = log(0.5), z_site = 0.5)

sqa_iid_fixture <- function(family, n_id = 48L, n_site = 32L, n_each = 12L,
                            seed = 20261210L) {
  K <- sqa_kernel(n_id, scale = 1.6, prefix = "a")
  set.seed(seed)
  ids <- rownames(K)
  sites <- paste0("site", seq_len(n_site))
  z_id <- stats::setNames(seq(-1, 1, length.out = n_id)[sample.int(n_id)], ids)
  z_site <- stats::setNames(
    seq(-1, 1, length.out = n_site)[sample.int(n_site)], sites
  )
  u <- sqa_draw(K, exp(sqa_alpha_id[[1L]] + sqa_alpha_id[[2L]] * z_id))
  Ks <- diag(n_site)
  dimnames(Ks) <- list(sites, sites)
  v <- sqa_draw(
    Ks, exp(sqa_alpha_site[[1L]] + sqa_alpha_site[[2L]] * z_site)
  )
  n_obs <- n_id * n_each
  id_chr <- rep(ids, each = n_each)
  site_chr <- sites[sample.int(n_site, n_obs, replace = TRUE)]
  x <- stats::rnorm(n_obs)
  mu <- 0.3 + 0.2 * x + u[id_chr] + v[site_chr]
  if (!identical(family, "gaussian")) mu <- exp(mu)
  data <- data.frame(
    y = sqa_draw_y(family, mu), x = x,
    id = factor(id_chr, levels = rev(ids)),
    site = factor(site_chr, levels = sites),
    z_id = unname(z_id[id_chr]), z_site = unname(z_site[site_chr])
  )
  list(data = data, K = K, Q = sqa_precision(K), z_id = z_id, z_site = z_site,
       ids = ids, sites = sites)
}

sqa_iid_fit <- function(family, fx, sd_struct = "z_id", sd_iid = "z_site") {
  Ainv <- fx$Q
  nb2 <- identical(family, "nb2")
  parts <- list(quote(y ~ x + animal(1 | id, Ainv = Ainv) + (1 | site)))
  if (nb2) parts <- c(parts, list(quote(sigma ~ 1)))
  if (!is.null(sd_struct)) {
    parts <- c(parts, list(str2lang(
      sprintf("sd(id, level = \"animal\") ~ %s", sd_struct)
    )))
  }
  if (!is.null(sd_iid)) {
    parts <- c(parts, list(str2lang(sprintf("sd(site) ~ %s", sd_iid))))
  }
  f <- eval(as.call(c(list(quote(bf)), parts)))
  drmTMB(f, family = sqa_family_object(family), data = fx$data,
         control = drm_control(se = FALSE))
}

sqa_iid_loglik_oracle <- function(family, fit, fx, sd_id, sd_site) {
  K <- fx$K
  n_id <- nrow(K)
  n_site <- length(fx$sites)
  n_obs <- nrow(fx$data)
  id_idx <- match(as.character(fx$data$id), rownames(K))
  site_idx <- match(as.character(fx$data$site), fx$sites)
  J <- matrix(0, n_obs, n_id + n_site)
  J[cbind(seq_len(n_obs), id_idx)] <- sd_id[id_idx]
  J[cbind(seq_len(n_obs), n_id + site_idx)] <- sd_site[site_idx]
  S <- matrix(0, n_id + n_site, n_id + n_site)
  S[seq_len(n_id), seq_len(n_id)] <- K
  S[n_id + seq_len(n_site), n_id + seq_len(n_site)] <- diag(n_site)
  beta <- fit$coefficients$mu[c("(Intercept)", "x")]
  eta0 <- beta[[1L]] + beta[[2L]] * fx$data$x
  if (identical(family, "gaussian")) {
    return(sqa_gaussian_exact(
      fx$data$y, eta0, J, S, sigma = unname(stats::sigma(fit))
    ))
  }
  sqa_dense_laplace(
    family, fx$data$y, eta0, J, S,
    size = if (identical(family, "nb2")) sqa_nb2_size(fit) else NA_real_
  )
}

sqa_check_iid_ainv <- function(family) {
  fx <- sqa_iid_fixture(family)
  expect_false(identical(levels(fx$data$id), rownames(fx$K)))
  fit <- sqa_iid_fit(family, fx)
  expect_equal(fit$opt$convergence, 0L, info = family)
  expect_named(coef(fit, "sd_animal(id)"), c("(Intercept)", "z_id"))
  expect_named(coef(fit, "sd(site)"), c("(Intercept)", "z_site"))
  a_id <- coef(fit, "sd_animal(id)")
  a_site <- coef(fit, "sd(site)")
  slack <- if (identical(family, "gaussian")) 0.8 else 0.6
  expect_lt(abs(a_id[["z_id"]] - sqa_alpha_id[["z_id"]]), slack)
  expect_lt(abs(a_site[["z_site"]] - sqa_alpha_site[["z_site"]]), slack)

  sd_id <- predict(fit, dpar = "sd_animal(id)")
  sd_site <- predict(fit, dpar = "sd(site)")
  expect_setequal(names(sd_id), fx$ids)
  expect_setequal(names(sd_site), fx$sites)
  expect_equal(
    unname(sd_id),
    unname(exp(a_id[[1L]] + a_id[[2L]] * fx$z_id[names(sd_id)])),
    tolerance = 1e-8
  )
  expect_equal(
    unname(sd_site),
    unname(exp(a_site[[1L]] + a_site[[2L]] * fx$z_site[names(sd_site)])),
    tolerance = 1e-8
  )

  tol <- if (identical(family, "gaussian")) 1e-6 else 1e-4
  oracle <- sqa_iid_loglik_oracle(
    family, fit, fx, sd_id[fx$ids], sd_site[fx$sites]
  )
  expect_lt(abs(as.numeric(logLik(fit)) - oracle), tol)
  # Emulated bugs: reversed structured SDs; structured and ordinary SD designs
  # exchanged for one another is impossible by size, so reverse the site SDs.
  expect_gt(
    abs(sqa_iid_loglik_oracle(
      family, fit, fx, rev(sd_id[fx$ids]), sd_site[fx$sites]
    ) - oracle),
    0.05
  )
  expect_gt(
    abs(sqa_iid_loglik_oracle(
      family, fit, fx, sd_id[fx$ids], rev(sd_site[fx$sites])
    ) - oracle),
    0.05
  )
  # Ainv read as a covariance must move the oracle.
  fx_wrong <- fx
  fx_wrong$K <- fx$Q
  expect_gt(
    abs(sqa_iid_loglik_oracle(
      family, fit, fx_wrong, sd_id[fx$ids], sd_site[fx$sites]
    ) - oracle),
    0.05
  )

  # Constant-SD limit equals the base model with no sd() formulas.
  base_fit <- sqa_iid_fit(family, fx, sd_struct = NULL, sd_iid = NULL)
  const_fit <- sqa_iid_fit(family, fx, sd_struct = "1", sd_iid = "1")
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(const_fit$opt$convergence, 0L)
  expect_lt(
    abs(as.numeric(logLik(const_fit)) - as.numeric(logLik(base_fit))), 1e-4
  )
  invisible(list(fit = fit, fx = fx))
}

test_that("Gaussian ordinary plus animal Ainv SDs match the exact marginal", {
  skip_on_cran()
  res <- sqa_check_iid_ainv("gaussian")
  fx <- res$fx
  # The Ainv route equals the A route on the same data.
  A <- fx$K
  fit_A <- drmTMB(
    bf(y ~ x + animal(1 | id, A = A) + (1 | site),
       sd(id, level = "animal") ~ z_id, sd(site) ~ z_site),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_lt(
    abs(as.numeric(logLik(fit_A)) - as.numeric(logLik(res$fit))), 1e-4
  )
})

test_that("Poisson ordinary plus animal Ainv SDs match the dense oracle", {
  skip_on_cran()
  sqa_check_iid_ainv("poisson")
})

test_that("NB2 ordinary plus animal Ainv SDs match the dense oracle", {
  skip_on_cran()
  sqa_check_iid_ainv("nb2")
})

test_that("ordinary plus animal Ainv SD routes keep their refusals", {
  skip_on_cran()
  fx <- sqa_iid_fixture("poisson", n_id = 24L, n_site = 12L, n_each = 4L)
  Ainv <- fx$Q
  # The ordinary SD predictor must be constant within each site.
  bad <- fx$data
  bad$z_site[1L] <- bad$z_site[1L] + 1
  expect_error(
    drmTMB(
      bf(y ~ x + animal(1 | id, Ainv = Ainv) + (1 | site),
         sd(id, level = "animal") ~ z_id, sd(site) ~ z_site),
      family = stats::poisson(), data = bad,
      control = drm_control(se = FALSE)
    ),
    "constant within|varies within"
  )
  # The structured SD predictor must be constant within each animal.
  bad <- fx$data
  bad$z_id[1L] <- bad$z_id[1L] + 1
  expect_error(
    drmTMB(
      bf(y ~ x + animal(1 | id, Ainv = Ainv) + (1 | site),
         sd(id, level = "animal") ~ z_id, sd(site) ~ z_site),
      family = stats::poisson(), data = bad,
      control = drm_control(se = FALSE)
    ),
    "constant within|varies within"
  )
  # Missing-response integration is admitted since batch 23; fitted evidence is
  # in test-count-iid-slope-sd-missing-include.R. The builder keeps every row.
  d_miss <- fx$data
  d_miss$y[c(3L, 40L)] <- NA
  spec_inc <- drm_build_poisson_spec(
    bf(y ~ x + animal(1 | id, Ainv = Ainv) + (1 | site),
       sd(id, level = "animal") ~ z_id, sd(site) ~ z_site),
    d_miss, missing = miss_control(response = "include")
  )
  expect_identical(length(spec_inc$y), nrow(d_miss))
})
