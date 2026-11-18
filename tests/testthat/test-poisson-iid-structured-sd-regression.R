# Native Poisson IID (ordinary) intercept plus a structured intercept, each with
# its own predictor-dependent SD:
#   y ~ x + (1 | site) + <provider>(1 | id, ...)
#   sd(site) ~ z_site;  sd(id, level = <provider level>) ~ z_id
# Providers: relmat (K, Q), animal (A, Ainv), phylo (tree).
# Templates: test-binomial-animal-iid-sd-regression.R,
# test-binomial-iid-relmat-kernel-equivalence-nonlogit-sd.R and
# test-poisson-relmat-sd-regression.R.
#
# Oracle: a dense, drmTMB-independent Laplace marginal likelihood over the joint
# latent f = (u, v), u ~ N(0, K) (structured, scaled by its SD row) and
# v ~ N(0, I) (site, scaled by its SD row), with
#   eta = X beta + J f,  J = [diag(sd_id)[id, ] , diag(sd_site)[site, ]].
# Laplace value: ll(f*) - f*' S^-1 f* / 2 - logdet(I + S J' W J) / 2,
# S = blockdiag(K, I), W = diag(exp(eta*)).
#
# Tolerances are fixed before the first run and are never loosened:
#   oracle agreement 1e-4 absolute on the log-likelihood (as the Poisson
#   slope templates); constant-SD equivalence 2e-5 relative on logLik and 1e-4
#   on mu coefficients (as the relmat template); K vs Q / A vs Ainv agreement
#   1e-4 relative; structured SD slope within 0.5 of truth, IID SD slope within
#   0.6 of truth; term-order invariance 1e-5 absolute on logLik; a nested
#   model may not beat the full model by more than 1e-3 log-likelihood units.

pis_providers <- list(
  relmat_K = list(
    term = "relmat(1 | id, K = K)", level = "relmat",
    dpar = "sd_relmat(id)", cov = "K"
  ),
  relmat_Q = list(
    term = "relmat(1 | id, Q = Q)", level = "relmat",
    dpar = "sd_relmat(id)", cov = "K"
  ),
  animal_A = list(
    term = "animal(1 | id, A = A)", level = "animal",
    dpar = "sd_animal(id)", cov = "K"
  ),
  animal_Ainv = list(
    term = "animal(1 | id, Ainv = Ainv)", level = "animal",
    dpar = "sd_animal(id)", cov = "K"
  ),
  phylo = list(
    term = "phylo(1 | id, tree = tree)", level = "phylogenetic",
    dpar = "sd_phylo(id)", cov = "K"
  )
)

pis_alpha_id <- c(`(Intercept)` = log(0.5), z_id = 0.5)
pis_alpha_site <- c(`(Intercept)` = log(0.5), z_site = 0.5)

# Covariance in a matrix order that differs from the factor-level order of the
# data, with a non-unit scale to detect accidental correlation conversion.
pis_make_K <- function(kind, n_id, seed) {
  set.seed(seed)
  id_levels <- paste0("id", seq_len(n_id))
  if (identical(kind, "phylo")) {
    tree <- ape::rcoal(n_id)
    tree$tip.label <- sample(id_levels)
    K <- drmTMB:::drm_phylo_tip_covariance(tree)
    return(list(K = K, tree = tree))
  }
  base <- 1.6 * 0.45^abs(outer(seq_len(n_id), seq_len(n_id), `-`))
  dimnames(base) <- list(id_levels, id_levels)
  order <- c(seq.int(1L, n_id, by = 2L), seq.int(2L, n_id, by = 2L))
  list(K = base[order, order], tree = NULL)
}

pis_fixture <- function(kind, n_id = 48L, n_site = 32L, n_each = 12L,
                        seed = 20261120L) {
  km <- pis_make_K(kind, n_id, seed)
  K <- km$K
  set.seed(seed + 1L)
  id_levels <- rownames(K)
  data_levels <- rev(id_levels)
  site_levels <- paste0("site", seq_len(n_site))
  z_id <- stats::setNames(
    seq(-1, 1, length.out = n_id)[sample.int(n_id)], id_levels
  )
  z_site <- stats::setNames(
    seq(-1, 1, length.out = n_site)[sample.int(n_site)], site_levels
  )
  sd_id <- exp(pis_alpha_id[[1L]] + pis_alpha_id[[2L]] * z_id)
  sd_site <- exp(pis_alpha_site[[1L]] + pis_alpha_site[[2L]] * z_site)
  u <- as.vector(t(chol(K)) %*% stats::rnorm(n_id)) * sd_id[id_levels]
  names(u) <- id_levels
  v <- stats::rnorm(n_site) * sd_site[site_levels]
  n_obs <- n_id * n_each
  id_chr <- rep(id_levels, each = n_each)
  site_chr <- site_levels[sample.int(n_site, n_obs, replace = TRUE)]
  x <- stats::rnorm(n_obs)
  mu <- exp(0.3 + 0.2 * x + u[id_chr] + v[site_chr])
  data <- data.frame(
    y = stats::rpois(n_obs, mu),
    x = x,
    id = factor(id_chr, levels = data_levels),
    site = factor(site_chr, levels = site_levels),
    z_id = unname(z_id[id_chr]),
    z_site = unname(z_site[site_chr])
  )
  list(
    data = data, K = K, Q = solve(K), tree = km$tree,
    z_id = z_id, z_site = z_site, id_levels = id_levels,
    site_levels = site_levels
  )
}

# Build the formula inside this frame so K, Q, A, Ainv and tree resolve.
pis_formula <- function(fx, provider, sd_struct = "z_id", sd_iid = "z_site",
                        iid_first = FALSE) {
  K <- fx$K
  Q <- fx$Q
  Q <- Q[rownames(K), rownames(K)]
  A <- K
  Ainv <- Q
  tree <- fx$tree
  spec <- pis_providers[[provider]]
  rhs <- if (iid_first) {
    paste("y ~ x + (1 | site) +", spec$term)
  } else {
    paste("y ~ x +", spec$term, "+ (1 | site)")
  }
  parts <- rhs
  if (!is.null(sd_struct)) {
    parts <- c(parts, sprintf(
      "sd(id, level = \"%s\") ~ %s", spec$level, sd_struct
    ))
  }
  if (!is.null(sd_iid)) {
    parts <- c(parts, sprintf("sd(site) ~ %s", sd_iid))
  }
  eval(parse(text = sprintf("bf(%s)", paste(parts, collapse = ", "))))
}

pis_fit <- function(fx, provider, ...) {
  drmTMB(
    pis_formula(fx, provider, ...),
    family = stats::poisson(), data = fx$data,
    control = drm_control(se = FALSE)
  )
}

pis_dense_laplace_loglik <- function(y, x, id_idx, site_idx, beta, sd_id,
                                     sd_site, K) {
  n_id <- nrow(K)
  n_site <- length(sd_site)
  n_obs <- length(y)
  J <- matrix(0, n_obs, n_id + n_site)
  J[cbind(seq_len(n_obs), id_idx)] <- sd_id[id_idx]
  J[cbind(seq_len(n_obs), n_id + site_idx)] <- sd_site[site_idx]
  Sinv <- matrix(0, n_id + n_site, n_id + n_site)
  Sinv[seq_len(n_id), seq_len(n_id)] <- solve(K)
  Sinv[n_id + seq_len(n_site), n_id + seq_len(n_site)] <- diag(n_site)
  S <- matrix(0, n_id + n_site, n_id + n_site)
  S[seq_len(n_id), seq_len(n_id)] <- K
  S[n_id + seq_len(n_site), n_id + seq_len(n_site)] <- diag(n_site)
  eta0 <- beta[[1L]] + beta[[2L]] * x
  logjoint <- function(f) {
    eta <- eta0 + as.vector(J %*% f)
    sum(stats::dpois(y, exp(eta), log = TRUE)) -
      0.5 * sum(f * (Sinv %*% f))
  }
  f <- rep(0, n_id + n_site)
  for (iter in seq_len(200L)) {
    mu <- exp(eta0 + as.vector(J %*% f))
    grad <- as.vector(crossprod(J, y - mu)) - as.vector(Sinv %*% f)
    H <- crossprod(J, mu * J) + Sinv
    step <- as.vector(solve(H, grad))
    scale <- 1
    f0 <- logjoint(f)
    while (logjoint(f + scale * step) < f0 && scale > 1e-8) scale <- scale / 2
    f <- f + scale * step
    if (max(abs(scale * step)) < 1e-12) break
  }
  mu <- exp(eta0 + as.vector(J %*% f))
  W_JJ <- crossprod(J, mu * J)
  logjoint(f) -
    0.5 * as.numeric(determinant(diag(n_id + n_site) + S %*% W_JJ)$modulus)
}

pis_oracle <- function(fit, fx) {
  K <- fx$K
  spec_dpar <- NULL
  sd_names <- grep("^sd_", names(fit$sdpars), value = TRUE)
  struct_name <- setdiff(sd_names, "sd(site)")
  sd_struct <- predict(fit, dpar = struct_name)
  sd_site <- predict(fit, dpar = "sd(site)")
  pis_dense_laplace_loglik(
    y = fx$data$y,
    x = fx$data$x,
    id_idx = match(as.character(fx$data$id), rownames(K)),
    site_idx = match(as.character(fx$data$site), fx$site_levels),
    beta = fit$coefficients$mu[c("(Intercept)", "x")],
    sd_id = sd_struct[rownames(K)],
    sd_site = sd_site[fx$site_levels],
    K = K
  )
}

pis_check_provider <- function(provider, fx) {
  spec <- pis_providers[[provider]]
  info <- provider
  fit <- pis_fit(fx, provider)

  expect_equal(fit$opt$convergence, 0L, info = info)
  expect_true(is.finite(as.numeric(logLik(fit))), info = info)
  expect_setequal(
    names(coef(fit)), c("mu", spec$dpar, "sd(site)")
  )
  struct_coef <- coef(fit, spec$dpar)
  site_coef <- coef(fit, "sd(site)")
  expect_identical(names(struct_coef), c("(Intercept)", "z_id"), info = info)
  expect_identical(names(site_coef), c("(Intercept)", "z_site"), info = info)
  expect_lt(abs(struct_coef[["z_id"]] - pis_alpha_id[["z_id"]]), 0.5)
  expect_lt(abs(site_coef[["z_site"]] - pis_alpha_site[["z_site"]]), 0.6)

  # Name-aligned predictions: each SD row follows its own level, not the
  # position of the covariance matrix or the factor-level order of the data.
  struct_pred <- predict(fit, dpar = spec$dpar)
  site_pred <- predict(fit, dpar = "sd(site)")
  expect_setequal(names(struct_pred), fx$id_levels)
  expect_setequal(names(site_pred), fx$site_levels)
  expect_equal(
    unname(struct_pred),
    unname(exp(struct_coef[["(Intercept)"]] +
      struct_coef[["z_id"]] * fx$z_id[names(struct_pred)])),
    tolerance = 1e-8, info = info
  )
  expect_equal(
    unname(site_pred),
    unname(exp(site_coef[["(Intercept)"]] +
      site_coef[["z_site"]] * fx$z_site[names(site_pred)])),
    tolerance = 1e-8, info = info
  )
  expect_equal(
    unname(struct_pred), unname(fit$sdpars[[spec$dpar]]), tolerance = 1e-10
  )
  expect_equal(
    unname(site_pred), unname(fit$sdpars[["sd(site)"]]), tolerance = 1e-10
  )
  pp <- predict_parameters(fit, dpar = spec$dpar)
  expect_true(all(pp$dpar == spec$dpar))
  expect_equal(nrow(pp), length(fx$id_levels))

  # Dense independent oracle.
  oracle <- pis_oracle(fit, fx)
  expect_lt(abs(as.numeric(logLik(fit)) - oracle), 1e-4)

  # Constant-SD equivalence with the base (no sd formula) model.
  base_fit <- pis_fit(fx, provider, sd_struct = NULL, sd_iid = NULL)
  constant_fit <- pis_fit(fx, provider, sd_struct = "1", sd_iid = "1")
  expect_equal(base_fit$opt$convergence, 0L, info = info)
  expect_equal(constant_fit$opt$convergence, 0L, info = info)
  expect_equal(
    as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
  expect_equal(
    constant_fit$coefficients$mu, base_fit$coefficients$mu, tolerance = 1e-4
  )

  # Each SD target can be modelled on its own; the other stays a scalar SD.
  site_only <- pis_fit(fx, provider, sd_struct = NULL)
  struct_only <- pis_fit(fx, provider, sd_iid = NULL)
  expect_equal(site_only$opt$convergence, 0L, info = info)
  expect_equal(struct_only$opt$convergence, 0L, info = info)
  expect_setequal(names(coef(site_only)), c("mu", "sd(site)"))
  expect_setequal(names(coef(struct_only)), c("mu", spec$dpar))
  expect_lt(
    as.numeric(logLik(site_only)), as.numeric(logLik(fit)) + 1e-3
  )
  expect_lt(
    as.numeric(logLik(struct_only)), as.numeric(logLik(fit)) + 1e-3
  )

  simulated <- simulate(fit, nsim = 1L, seed = 20261121L)
  expect_named(simulated, "sim_1")
  expect_length(simulated[[1L]], nrow(fx$data))
  expect_true(all(simulated[[1L]] >= 0L))
  expect_true(all(simulated[[1L]] == as.integer(simulated[[1L]])))

  saved <- tempfile(fileext = ".rds")
  on.exit(unlink(saved), add = TRUE)
  saveRDS(fit, saved)
  reloaded <- readRDS(saved)
  expect_equal(predict(reloaded, dpar = spec$dpar), struct_pred,
               tolerance = 1e-12)
  expect_equal(predict(reloaded, dpar = "sd(site)"), site_pred,
               tolerance = 1e-12)
  invisible(fit)
}

test_that("Poisson relmat plus IID intercepts keep separate SD designs (K and Q)", {
  skip_on_cran()
  fx <- pis_fixture("relmat")
  expect_false(identical(levels(fx$data$id), rownames(fx$K)))
  fit_K <- pis_check_provider("relmat_K", fx)
  fit_Q <- pis_check_provider("relmat_Q", fx)
  expect_equal(
    as.numeric(logLik(fit_Q)), as.numeric(logLik(fit_K)), tolerance = 1e-4
  )
  expect_equal(
    predict(fit_Q, dpar = "sd_relmat(id)")[fx$id_levels],
    predict(fit_K, dpar = "sd_relmat(id)")[fx$id_levels],
    tolerance = 1e-3
  )
  expect_equal(
    predict(fit_Q, dpar = "sd(site)")[fx$site_levels],
    predict(fit_K, dpar = "sd(site)")[fx$site_levels],
    tolerance = 1e-3
  )

  # The order of the two random-effect terms in the formula is immaterial.
  swapped <- pis_fit(fx, "relmat_K", iid_first = TRUE)
  expect_equal(swapped$opt$convergence, 0L)
  expect_lt(abs(as.numeric(logLik(swapped)) - as.numeric(logLik(fit_K))), 1e-5)
})

test_that("Poisson animal plus IID intercepts keep separate SD designs (A and Ainv)", {
  skip_on_cran()
  fx <- pis_fixture("animal", seed = 20261130L)
  fit_A <- pis_check_provider("animal_A", fx)
  fit_Ainv <- pis_check_provider("animal_Ainv", fx)
  expect_equal(
    as.numeric(logLik(fit_Ainv)), as.numeric(logLik(fit_A)), tolerance = 1e-4
  )
})

test_that("Poisson phylo plus IID intercepts keep separate SD designs", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- pis_fixture("phylo", seed = 20261140L)
  expect_false(identical(levels(fx$data$id), fx$tree$tip.label))
  pis_check_provider("phylo", fx)
})

test_that("Poisson IID plus structured SD keeps its other gates closed", {
  skip_on_cran()
  fx <- pis_fixture("relmat", n_id = 24L, n_site = 12L, n_each = 4L)
  K <- fx$K
  # Missing-response integration is admitted since batch 23; fitted evidence is
  # in test-count-iid-slope-sd-missing-include.R. The builder keeps every row.
  d_miss <- fx$data
  d_miss$y[c(3L, 40L)] <- NA
  spec_inc <- drm_build_poisson_spec(
    bf(
      y ~ x + relmat(1 | id, K = K) + (1 | site),
      sd(id, level = "relmat") ~ z_id,
      sd(site) ~ z_site
    ),
    d_miss, missing = miss_control(response = "include")
  )
  expect_identical(length(spec_inc$y), nrow(d_miss))
  # Zero inflation is not part of this slice.
  expect_error(
    drmTMB(
      bf(
        y ~ x + relmat(1 | id, K = K) + (1 | site),
        zi ~ 1,
        sd(id, level = "relmat") ~ z_id,
        sd(site) ~ z_site
      ),
      family = stats::poisson(), data = fx$data,
      control = drm_control(se = FALSE)
    ),
    "non-inflated model"
  )
})
