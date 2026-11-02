# Native NB2 batch 5: additive q1 intercept fields on `mu`, each with its own
# predictor-dependent SD.
#   (A) NB2 IID (ordinary) intercept plus one structured intercept:
#         y ~ x + (1 | site) + <provider>(1 | id, ...)
#         sd(site) ~ z_site;  sd(id, level = <provider level>) ~ z_id
#       Providers: relmat (K, Q), animal (A, Ainv), phylo (tree).
#       Poisson has this route (test-poisson-iid-structured-sd-regression.R)
#       and Gamma relmat plus iid already works; the NB2 builder refuses it at
#       the structured-plus-ordinary gate, so (A) is expected RED until that
#       guard is lifted (see the after-task note for file:line).
#   (B) NB2 crossed ordinary intercepts (1 | g1) + (1 | g2) with sd(g1) and
#       sd(g2). This route is already admitted; it had no test or oracle.
#
# Oracle (independent of drmTMB): dense Laplace marginal of the joint latent
# f = (f_1, ..., f_B), f_b ~ N(0, Sigma_b), with
#   eta = X beta + J f,  J_b[i, l] = sd_b[l] * 1(level(i) = l),
#   y | f ~ NB2(mu = exp(eta), size = 1 / sigma^2).
# Laplace value: ll(f*) - f*' S^-1 f* / 2 - logdet(I + S J' W J) / 2, with
# S = blockdiag(Sigma_b) and W = diag(observed information
# size * mu * (size + y) / (size + mu)^2). It is evaluated at the fitted
# parameters, so it checks the likelihood assembly (which SD row multiplies
# which latent coefficient), not the optimiser.
#
# Tolerances were fixed before the first run and are never loosened:
#   oracle agreement 1e-4 absolute on the log-likelihood;
#   constant-SD equivalence 2e-5 relative on logLik and 1e-4 on mu coefficients;
#   K vs Q and A vs Ainv logLik agreement 1e-4 relative;
#   predicted SD vs exp(X alpha) 1e-8; term-order invariance 1e-5 absolute;
#   SD-slope recovery within 0.6 of truth (wiring check, not calibration);
#   a nested model may not beat the full model by more than 1e-3 logLik.
# No calibration, parity, or support claim follows from this file.

nb5_providers <- list(
  relmat_K = list(
    term = "relmat(1 | id, K = K)", level = "relmat",
    dpar = "sd_relmat(id)"
  ),
  relmat_Q = list(
    term = "relmat(1 | id, Q = Q)", level = "relmat",
    dpar = "sd_relmat(id)"
  ),
  animal_A = list(
    term = "animal(1 | id, A = A)", level = "animal",
    dpar = "sd_animal(id)"
  ),
  animal_Ainv = list(
    term = "animal(1 | id, Ainv = Ainv)", level = "animal",
    dpar = "sd_animal(id)"
  ),
  phylo = list(
    term = "phylo(1 | id, tree = tree)", level = "phylogenetic",
    dpar = "sd_phylo(id)"
  )
)

nb5_alpha_id <- c(`(Intercept)` = log(0.5), z_id = 0.5)
nb5_alpha_site <- c(`(Intercept)` = log(0.5), z_site = 0.5)
nb5_sigma <- 0.35

nb5_dense_laplace <- function(y, eta0, size, blocks) {
  # blocks: list of list(index = integer level per row, sd = per-level SD,
  #                      Sigma = per-level covariance)
  n_obs <- length(y)
  n_lev <- vapply(blocks, function(b) length(b$sd), integer(1L))
  offset <- c(0L, cumsum(n_lev))
  q <- sum(n_lev)
  J <- matrix(0, n_obs, q)
  S <- matrix(0, q, q)
  for (k in seq_along(blocks)) {
    cols <- offset[[k]] + seq_len(n_lev[[k]])
    J[cbind(seq_len(n_obs), offset[[k]] + blocks[[k]]$index)] <-
      blocks[[k]]$sd[blocks[[k]]$index]
    S[cols, cols] <- blocks[[k]]$Sigma
  }
  Sinv <- solve(S)
  logjoint <- function(f) {
    eta <- eta0 + as.vector(J %*% f)
    sum(stats::dnbinom(y, size = size, mu = exp(eta), log = TRUE)) -
      0.5 * sum(f * (Sinv %*% f))
  }
  info_weights <- function(f) {
    mu <- exp(eta0 + as.vector(J %*% f))
    list(
      mu = mu,
      score = size * (y - mu) / (size + mu),
      info = size * mu * (size + y) / (size + mu)^2
    )
  }
  f <- rep(0, q)
  for (iter in seq_len(300L)) {
    w <- info_weights(f)
    grad <- as.vector(crossprod(J, w$score)) - as.vector(Sinv %*% f)
    H <- crossprod(J, w$info * J) + Sinv
    step <- as.vector(solve(H, grad))
    scale <- 1
    f0 <- logjoint(f)
    while (logjoint(f + scale * step) < f0 && scale > 1e-8) scale <- scale / 2
    f <- f + scale * step
    if (max(abs(scale * step)) < 1e-12) break
  }
  w <- info_weights(f)
  # Oracle self-check (not an engine tolerance): the penalised score at the
  # mode is zero up to the conditioning of S^-1 (the phylo K has condition
  # number ~1e5, so 1e-6 absolute is below double-precision solve noise).
  # A first-order gradient residual of this size moves the Laplace value only
  # at second order.
  stopifnot(max(abs(
    as.vector(crossprod(J, w$score)) - as.vector(Sinv %*% f)
  )) < 1e-4 * (1 + max(abs(Sinv %*% f))))
  logjoint(f) -
    0.5 * as.numeric(determinant(
      diag(q) + S %*% crossprod(J, w$info * J)
    )$modulus)
}

# Covariance in a matrix order that differs from the factor-level order of the
# data, with a non-unit scale to detect accidental correlation conversion.
nb5_make_K <- function(kind, n_id, seed) {
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

nb5_fixture <- function(kind, n_id = 48L, n_site = 32L, n_each = 12L,
                        seed = 20261120L) {
  km <- nb5_make_K(kind, n_id, seed)
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
  sd_id <- exp(nb5_alpha_id[[1L]] + nb5_alpha_id[[2L]] * z_id)
  sd_site <- exp(nb5_alpha_site[[1L]] + nb5_alpha_site[[2L]] * z_site)
  u <- as.vector(t(chol(K)) %*% stats::rnorm(n_id)) * sd_id[id_levels]
  names(u) <- id_levels
  v <- stats::rnorm(n_site) * sd_site[site_levels]
  names(v) <- site_levels
  n_obs <- n_id * n_each
  id_chr <- rep(id_levels, each = n_each)
  site_chr <- site_levels[sample.int(n_site, n_obs, replace = TRUE)]
  x <- stats::rnorm(n_obs)
  mu <- exp(0.3 + 0.2 * x + u[id_chr] + v[site_chr])
  data <- data.frame(
    y = stats::rnbinom(n_obs, size = 1 / nb5_sigma^2, mu = mu),
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
nb5_formula <- function(fx, provider, sd_struct = "z_id", sd_iid = "z_site",
                        iid_first = FALSE) {
  K <- fx$K
  Q <- fx$Q
  Q <- Q[rownames(K), rownames(K)]
  A <- K
  Ainv <- Q
  tree <- fx$tree
  spec <- nb5_providers[[provider]]
  rhs <- if (iid_first) {
    paste("y ~ x + (1 | site) +", spec$term)
  } else {
    paste("y ~ x +", spec$term, "+ (1 | site)")
  }
  parts <- c(rhs, "sigma ~ 1")
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

nb5_fit <- function(fx, provider, ...) {
  drmTMB(
    nb5_formula(fx, provider, ...),
    family = nbinom2(), data = fx$data,
    control = drm_control(se = FALSE)
  )
}

nb5_oracle <- function(fit, fx) {
  K <- fx$K
  sd_names <- grep("^sd_", names(fit$sdpars), value = TRUE)
  struct_name <- setdiff(sd_names, "sd(site)")
  sd_struct <- predict(fit, dpar = struct_name)
  sd_site <- predict(fit, dpar = "sd(site)")
  dat <- fx$data
  eta0 <- as.numeric(
    stats::model.matrix(~ x, dat) %*% coef(fit, "mu")[c("(Intercept)", "x")]
  )
  sigma_hat <- exp(unname(coef(fit, "sigma")[["(Intercept)"]]))
  nb5_dense_laplace(
    y = dat$y, eta0 = eta0, size = 1 / sigma_hat^2,
    blocks = list(
      list(
        index = match(as.character(dat$id), rownames(K)),
        sd = unname(sd_struct[rownames(K)]), Sigma = K
      ),
      list(
        index = match(as.character(dat$site), fx$site_levels),
        sd = unname(sd_site[fx$site_levels]),
        Sigma = diag(length(fx$site_levels))
      )
    )
  )
}

nb5_check_provider <- function(provider, fx) {
  spec <- nb5_providers[[provider]]
  info <- provider
  fit <- nb5_fit(fx, provider)

  expect_equal(fit$opt$convergence, 0L, info = info)
  expect_true(is.finite(as.numeric(logLik(fit))), info = info)
  expect_setequal(names(coef(fit)), c("mu", "sigma", spec$dpar, "sd(site)"))
  struct_coef <- coef(fit, spec$dpar)
  site_coef <- coef(fit, "sd(site)")
  expect_identical(names(struct_coef), c("(Intercept)", "z_id"), info = info)
  expect_identical(names(site_coef), c("(Intercept)", "z_site"), info = info)
  expect_lt(abs(struct_coef[["z_id"]] - nb5_alpha_id[["z_id"]]), 0.6)
  expect_lt(abs(site_coef[["z_site"]] - nb5_alpha_site[["z_site"]]), 0.6)

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

  # Dense independent oracle.
  oracle <- nb5_oracle(fit, fx)
  expect_lt(abs(as.numeric(logLik(fit)) - oracle), 1e-4)

  # Constant-SD equivalence with the base (no sd formula) model.
  base_fit <- nb5_fit(fx, provider, sd_struct = NULL, sd_iid = NULL)
  constant_fit <- nb5_fit(fx, provider, sd_struct = "1", sd_iid = "1")
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
  site_only <- nb5_fit(fx, provider, sd_struct = NULL)
  struct_only <- nb5_fit(fx, provider, sd_iid = NULL)
  expect_equal(site_only$opt$convergence, 0L, info = info)
  expect_equal(struct_only$opt$convergence, 0L, info = info)
  expect_lt(as.numeric(logLik(site_only)), as.numeric(logLik(fit)) + 1e-3)
  expect_lt(as.numeric(logLik(struct_only)), as.numeric(logLik(fit)) + 1e-3)

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

test_that("NB2 relmat plus IID intercepts keep separate SD designs (K and Q)", {
  skip_on_cran()
  fx <- nb5_fixture("relmat")
  expect_false(identical(levels(fx$data$id), rownames(fx$K)))
  fit_K <- nb5_check_provider("relmat_K", fx)
  fit_Q <- nb5_check_provider("relmat_Q", fx)
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
  swapped <- nb5_fit(fx, "relmat_K", iid_first = TRUE)
  expect_equal(swapped$opt$convergence, 0L)
  expect_lt(abs(as.numeric(logLik(swapped)) - as.numeric(logLik(fit_K))), 1e-5)
})

test_that("NB2 animal plus IID intercepts keep separate SD designs (A and Ainv)", {
  skip_on_cran()
  fx <- nb5_fixture("animal", seed = 20261130L)
  fit_A <- nb5_check_provider("animal_A", fx)
  fit_Ainv <- nb5_check_provider("animal_Ainv", fx)
  expect_equal(
    as.numeric(logLik(fit_Ainv)), as.numeric(logLik(fit_A)), tolerance = 1e-4
  )
})

test_that("NB2 phylo plus IID intercepts keep separate SD designs", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- nb5_fixture("phylo", seed = 20261140L)
  expect_false(identical(levels(fx$data$id), fx$tree$tip.label))
  nb5_check_provider("phylo", fx)
})

test_that("NB2 IID plus structured SD keeps its other gates closed", {
  skip_on_cran()
  fx <- nb5_fixture("relmat", n_id = 24L, n_site = 12L, n_each = 4L)
  K <- fx$K
  dat <- fx$data
  dat$site2 <- factor(rep(c("p", "q", "r"), length.out = nrow(dat)))
  ctl <- drm_control(se = FALSE)
  # A second ordinary intercept next to the structured one stays refused.
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 | id, K = K) + (1 | site) + (1 | site2),
         sigma ~ 1, sd(id, level = "relmat") ~ z_id),
      family = nbinom2(), data = dat, control = ctl
    )
  )
  # An ordinary random slope next to the structured intercept stays refused.
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 | id, K = K) + (0 + x | site),
         sigma ~ 1, sd(id, level = "relmat") ~ z_id),
      family = nbinom2(), data = dat, control = ctl
    )
  )
  # A correlated ordinary block next to the structured intercept stays refused.
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 | id, K = K) + (1 + x | site),
         sigma ~ 1, sd(id, level = "relmat") ~ z_id),
      family = nbinom2(), data = dat, control = ctl
    )
  )
  # Zero inflation is not part of this slice.
  expect_error(
    drmTMB(
      bf(y ~ x + relmat(1 | id, K = K) + (1 | site), zi ~ 1,
         sd(id, level = "relmat") ~ z_id, sd(site) ~ z_site),
      family = zi_nbinom2(), data = dat, control = ctl
    )
  )
  # Missing-response integration is admitted since batch 23; fitted evidence is
  # in test-count-iid-slope-sd-missing-include.R. The builder keeps every row.
  d_miss <- dat
  d_miss$y[c(3L, 40L)] <- NA
  spec_inc <- drm_build_nbinom2_spec(
    bf(y ~ x + relmat(1 | id, K = K) + (1 | site), sigma ~ 1,
       sd(id, level = "relmat") ~ z_id, sd(site) ~ z_site),
    d_miss, missing = miss_control(response = "include")
  )
  expect_identical(length(spec_inc$y), nrow(d_miss))
})

# ---- (B) crossed ordinary intercepts ----------------------------------------

# Group counts were raised from 24/18 groups after the first run: with 18
# levels the SD-slope estimate for g2 missed truth by 0.84 (a fixture-power
# problem, not a likelihood fault; the oracle agreed). The 0.6 recovery
# bound itself was NOT changed.
nb5_crossed_fixture <- function(seed = 20261150L, n1 = 48L, n2 = 40L,
                                n_obs = 960L) {
  set.seed(seed)
  l1 <- sprintf("a%02d", seq_len(n1))
  l2 <- sprintf("b%02d", seq_len(n2))
  # Every level occurs at least once; the rest are drawn at random.
  g1 <- factor(c(l1, sample(l1, n_obs - n1, TRUE)), levels = l1)
  g2 <- factor(c(sample(l2, n1 - n2, TRUE), l2, sample(l2, n_obs - n1, TRUE)),
               levels = l2)
  z1 <- stats::setNames(seq(-1, 1, length.out = n1)[sample.int(n1)], l1)
  z2 <- stats::setNames(seq(-1, 1, length.out = n2)[sample.int(n2)], l2)
  alpha1 <- c(`(Intercept)` = log(0.45), z1 = 0.5)
  alpha2 <- c(`(Intercept)` = log(0.35), z2 = -0.4)
  b1 <- stats::rnorm(n1, sd = exp(alpha1[[1L]] + alpha1[[2L]] * z1))
  b2 <- stats::rnorm(n2, sd = exp(alpha2[[1L]] + alpha2[[2L]] * z2))
  names(b1) <- l1
  names(b2) <- l2
  x <- stats::rnorm(n_obs)
  mu <- exp(0.4 + 0.2 * x + b1[as.character(g1)] + b2[as.character(g2)])
  list(
    data = data.frame(
      y = stats::rnbinom(n_obs, size = 1 / nb5_sigma^2, mu = mu), x = x,
      g1 = g1, g2 = g2,
      z1 = unname(z1[as.character(g1)]), z2 = unname(z2[as.character(g2)])
    ),
    z1 = z1, z2 = z2, alpha1 = alpha1, alpha2 = alpha2, l1 = l1, l2 = l2
  )
}

test_that("NB2 crossed ordinary intercepts take separate SD formulas and match a dense Laplace oracle", {
  skip_on_cran()
  fx <- nb5_crossed_fixture()
  dat <- fx$data
  ctl <- drm_control(se = FALSE)
  fit <- drmTMB(
    bf(y ~ x + (1 | g1) + (1 | g2), sigma ~ 1,
       sd(g1) ~ z1, sd(g2) ~ z2),
    family = nbinom2(), data = dat, control = ctl
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_setequal(names(coef(fit)), c("mu", "sigma", "sd(g1)", "sd(g2)"))
  c1 <- coef(fit, "sd(g1)")
  c2 <- coef(fit, "sd(g2)")
  expect_identical(names(c1), c("(Intercept)", "z1"))
  expect_identical(names(c2), c("(Intercept)", "z2"))
  expect_lt(abs(c1[["z1"]] - fx$alpha1[["z1"]]), 0.6)
  expect_lt(abs(c2[["z2"]] - fx$alpha2[["z2"]]), 0.6)

  p1 <- predict(fit, dpar = "sd(g1)")
  p2 <- predict(fit, dpar = "sd(g2)")
  expect_setequal(names(p1), fx$l1)
  expect_setequal(names(p2), fx$l2)
  expect_equal(
    unname(p1),
    unname(exp(c1[["(Intercept)"]] + c1[["z1"]] * fx$z1[names(p1)])),
    tolerance = 1e-8
  )
  expect_equal(
    unname(p2),
    unname(exp(c2[["(Intercept)"]] + c2[["z2"]] * fx$z2[names(p2)])),
    tolerance = 1e-8
  )

  eta0 <- as.numeric(
    stats::model.matrix(~ x, dat) %*% coef(fit, "mu")[c("(Intercept)", "x")]
  )
  sigma_hat <- exp(unname(coef(fit, "sigma")[["(Intercept)"]]))
  oracle <- nb5_dense_laplace(
    y = dat$y, eta0 = eta0, size = 1 / sigma_hat^2,
    blocks = list(
      list(index = match(as.character(dat$g1), fx$l1),
           sd = unname(p1[fx$l1]), Sigma = diag(length(fx$l1))),
      list(index = match(as.character(dat$g2), fx$l2),
           sd = unname(p2[fx$l2]), Sigma = diag(length(fx$l2)))
    )
  )
  expect_lt(abs(as.numeric(logLik(fit)) - oracle), 1e-4)

  # A reversed SD assignment must NOT match the oracle (sensitivity check).
  swapped <- nb5_dense_laplace(
    y = dat$y, eta0 = eta0, size = 1 / sigma_hat^2,
    blocks = list(
      list(index = match(as.character(dat$g1), fx$l1),
           sd = rev(unname(p1[fx$l1])), Sigma = diag(length(fx$l1))),
      list(index = match(as.character(dat$g2), fx$l2),
           sd = rev(unname(p2[fx$l2])), Sigma = diag(length(fx$l2)))
    )
  )
  expect_gt(abs(as.numeric(logLik(fit)) - swapped), 1e-2)

  # Constant-SD equivalence with the base crossed fit.
  base_fit <- drmTMB(
    bf(y ~ x + (1 | g1) + (1 | g2), sigma ~ 1),
    family = nbinom2(), data = dat, control = ctl
  )
  constant_fit <- drmTMB(
    bf(y ~ x + (1 | g1) + (1 | g2), sigma ~ 1,
       sd(g1) ~ 1, sd(g2) ~ 1),
    family = nbinom2(), data = dat, control = ctl
  )
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
  expect_equal(
    constant_fit$coefficients$mu, base_fit$coefficients$mu, tolerance = 1e-4
  )
  expect_lt(as.numeric(logLik(constant_fit)), as.numeric(logLik(fit)) + 1e-3)
})
