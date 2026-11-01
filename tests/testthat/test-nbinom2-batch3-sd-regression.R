# Native NB2 `sd()` regression, batch 3: the structured RESIDUAL-SCALE (sigma
# endpoint) phylogenetic q1 intercept,
#   sigma ~ phylo(1 | sp, tree = tree)
#   sd(sp, level = "phylogenetic", dpar = "sigma") ~ z
# Model: y_i ~ NB2(mu_i, sigma_i) with variance mu + sigma^2 mu^2 (size =
# 1 / sigma^2), log mu_i = X_i beta, and
#   log sigma_i = a0 + tau_g[i] * u_g[i],  u ~ N(0, V),
#   tau_g = exp(alpha0 + alpha1 * z_g).
# Oracle: a dense Laplace approximation of the marginal likelihood evaluated
# at the fitted parameters. The native engine is a Laplace fit, so the two
# must agree to optimiser precision. There is no closed form for NB2.
#
# Tolerances were fixed before the first run and are not tuned to pass:
#   oracle logLik: relative 1e-6; constant-SD limit: logLik 2e-5 and
#   coefficients 1e-4 (as in the sibling NB2 relmat/spatial file);
#   recovery of (alpha0, alpha1) with 40 species: absolute 0.75 (wiring check).

nb2_sigma_dense_laplace <- function(y, eta_mu, group, log_sigma0, tau, Sigma) {
  # log sigma_i = log_sigma0 + tau[group_i] * u[group_i]; u ~ N(0, Sigma).
  n_group <- nrow(Sigma)
  Sigma_inv <- solve(Sigma)
  logdet_Sigma <- as.numeric(determinant(Sigma, logarithm = TRUE)$modulus)
  rows <- split(seq_along(y), factor(group, levels = seq_len(n_group)))
  group_loglik <- function(g, ug) {
    i <- rows[[g]]
    sum(stats::dnbinom(
      y[i], size = exp(-2 * (log_sigma0 + tau[[g]] * ug)),
      mu = exp(eta_mu[i]), log = TRUE
    ))
  }
  loglik <- function(u) sum(vapply(seq_len(n_group), function(g) {
    group_loglik(g, u[[g]])
  }, numeric(1L)))
  derivs <- function(u) {
    d1 <- d2 <- numeric(n_group)
    for (g in seq_len(n_group)) {
      f <- function(v) group_loglik(g, v)
      d1[[g]] <- numDeriv::grad(f, u[[g]])
      d2[[g]] <- numDeriv::hessian(f, u[[g]])[1L, 1L]
    }
    list(d1 = d1, d2 = d2)
  }
  objective <- function(u) loglik(u) - 0.5 * sum(u * (Sigma_inv %*% u))
  u <- rep(0, n_group)
  for (iter in seq_len(200L)) {
    d <- derivs(u)
    grad <- d$d1 - as.numeric(Sigma_inv %*% u)
    H <- Sigma_inv - diag(d$d2, n_group)
    step <- as.numeric(solve(H, grad))
    old <- objective(u)
    s <- 1
    while (objective(u + s * step) < old - 1e-12 && s > 1e-8) s <- s / 2
    u <- u + s * step
    if (max(abs(s * step)) < 1e-10) break
  }
  d <- derivs(u)
  H <- Sigma_inv - diag(d$d2, n_group)
  logdet_H <- as.numeric(determinant(H, logarithm = TRUE)$modulus)
  objective(u) - 0.5 * logdet_Sigma - 0.5 * logdet_H
}

nb2_sigma_phylo_sd_fixture <- function(seed = 20261102L, n_sp = 40L,
                                       n_each = 14L) {
  set.seed(seed)
  tree <- ape::rcoal(n_sp)
  tree$tip.label <- paste0("sp", seq_len(n_sp))
  V <- ape::vcv(tree)
  V <- V / max(V)
  species <- tree$tip.label
  z_sp <- stats::setNames(rep(c(-0.5, 0.5), length.out = n_sp), species)
  alpha <- c(`(Intercept)` = log(0.5), z = 0.5)
  tau <- exp(alpha[[1L]] + alpha[[2L]] * z_sp)
  u <- as.numeric(t(chol(V)) %*% stats::rnorm(n_sp)) * tau
  sp <- rep(species, each = n_each)
  x <- stats::rnorm(n_sp * n_each)
  log_sigma <- log(0.45) + u[match(sp, species)]
  mu <- exp(1.2 + 0.3 * x)
  y <- stats::rnbinom(length(mu), mu = mu, size = exp(-2 * log_sigma))
  list(
    data = data.frame(y = y, x = x, sp = sp, z = z_sp[sp]),
    tree = tree, V = V, species = species, z_sp = z_sp, alpha = alpha
  )
}

nb2_sigma_fit <- function(formula, fx) {
  tree <- fx$tree
  drmTMB(formula, family = nbinom2(), data = fx$data,
         control = drm_control(se = FALSE))
}

test_that("NB2 structured sigma phylo q1 intercept accepts a predictor-dependent SD and matches a dense Laplace oracle", {
  skip_on_cran()
  skip_if_not_installed("ape")
  skip_if_not_installed("numDeriv")
  fx <- nb2_sigma_phylo_sd_fixture()
  tree <- fx$tree
  dat <- fx$data

  fit <- drmTMB(
    bf(
      y ~ x,
      sigma ~ phylo(1 | sp, tree = tree),
      sd(sp, level = "phylogenetic", dpar = "sigma") ~ z
    ),
    family = nbinom2(), data = dat, control = drm_control(se = FALSE)
  )

  expect_equal(fit$opt$convergence, 0L)
  sd_coef <- coef(fit, "sd_phylo(sp)")
  expect_named(sd_coef, c("(Intercept)", "z"))
  expect_true(all(is.finite(sd_coef)))
  expect_lt(abs(sd_coef[["(Intercept)"]] - fx$alpha[["(Intercept)"]]), 0.75)
  expect_lt(abs(sd_coef[["z"]] - fx$alpha[["z"]]), 0.75)

  # predict() returns exp(alpha0 + alpha1 z) per species, by name.
  sd_prediction <- predict(fit, dpar = "sd_phylo(sp)")
  expect_setequal(names(sd_prediction), fx$species)
  expected_sd <- exp(sd_coef[["(Intercept)"]] + sd_coef[["z"]] * fx$z_sp)
  expect_equal(unname(sd_prediction[fx$species]),
               unname(expected_sd[fx$species]), tolerance = 1e-10)

  # Dense Laplace oracle at the fitted parameters.
  mu_coef <- coef(fit, "mu")
  eta_mu <- as.numeric(mu_coef[["(Intercept)"]] + mu_coef[["x"]] * dat$x)
  log_sigma0 <- unname(coef(fit, "sigma")[["(Intercept)"]])
  group <- match(dat$sp, fx$species)
  oracle <- nb2_sigma_dense_laplace(
    y = dat$y, eta_mu = eta_mu, group = group, log_sigma0 = log_sigma0,
    tau = unname(expected_sd[fx$species]), Sigma = fx$V[fx$species, fx$species]
  )
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-6)

  # The oracle is endpoint-specific: a latent field placed on log(mu) instead
  # of log(sigma) gives a clearly different marginal likelihood.
  wrong_endpoint <- local({
    n_group <- length(fx$species)
    rows <- split(seq_len(nrow(dat)), factor(group, levels = seq_len(n_group)))
    Sigma <- fx$V[fx$species, fx$species]
    tau <- unname(expected_sd[fx$species])
    nll <- function(u) {
      -sum(vapply(seq_len(n_group), function(g) {
        i <- rows[[g]]
        sum(stats::dnbinom(dat$y[i], size = exp(-2 * log_sigma0),
                           mu = exp(eta_mu[i] + tau[[g]] * u[[g]]), log = TRUE))
      }, numeric(1L))) + 0.5 * sum(u * solve(Sigma, u))
    }
    -stats::optim(rep(0, n_group), nll, method = "BFGS")$value
  })
  expect_gt(abs(wrong_endpoint - oracle), 1)
})

test_that("NB2 structured sigma phylo SD formula `~ 1` equals the constant-SD fit", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- nb2_sigma_phylo_sd_fixture()
  tree <- fx$tree
  dat <- fx$data
  base_fit <- drmTMB(
    bf(y ~ x, sigma ~ phylo(1 | sp, tree = tree)),
    family = nbinom2(), data = dat, control = drm_control(se = FALSE)
  )
  constant_fit <- drmTMB(
    bf(y ~ x, sigma ~ phylo(1 | sp, tree = tree),
       sd(sp, level = "phylogenetic", dpar = "sigma") ~ 1),
    family = nbinom2(), data = dat, control = drm_control(se = FALSE)
  )
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(constant_fit)), as.numeric(logLik(base_fit)),
               tolerance = 2e-5)
  expect_equal(coef(constant_fit, "mu"), coef(base_fit, "mu"),
               tolerance = 1e-4)
  expect_equal(coef(constant_fit, "sigma"), coef(base_fit, "sigma"),
               tolerance = 1e-4)
})

test_that("NB2 structured sigma phylo SD regression keeps its input guards", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- nb2_sigma_phylo_sd_fixture()
  tree <- fx$tree
  dat <- fx$data
  dat$z[1L] <- dat$z[1L] + 1
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ phylo(1 | sp, tree = tree),
         sd(sp, level = "phylogenetic", dpar = "sigma") ~ z),
      family = nbinom2(), data = dat, control = drm_control(se = FALSE)
    ),
    "constant within"
  )
  # An SD formula aimed at the mu endpoint cannot select a sigma-endpoint field.
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ phylo(1 | sp, tree = tree),
         sd(sp, level = "phylogenetic", dpar = "mu") ~ z),
      family = nbinom2(), data = fx$data, control = drm_control(se = FALSE)
    ),
    "endpoint"
  )
})
