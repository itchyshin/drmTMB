# Batch 31 (group no) companion for the native structured-intercept rows
#   gaussian        relmat_intercept  Q_precision
#   beta            relmat_intercept  K_covariance;  animal_intercept A_covariance
# each fitted as `<provider>(1 | id, ...)` with `sd(id, level = ...) ~ w`.
#
# Ledger deficiency addressed: no independent oracle and no emulated-bug
# sensitivity (Julia parity only / unreviewed). Oracles, evaluated at the fitted
# parameters with SD vectors built by hand from the fitted coefficients:
#   gaussian: exact Gaussian marginal y ~ N(X beta, sigma^2 I + Z K Z');
#   beta: base-R dense Laplace marginal (helper-sb26-oracle.R) with the Beta
#     (mean-precision, phi = 1 / sigma^2) density from helper-b31no-oracle.R
#     (hand-written, checked there against numerical integrals), eta
#     derivatives by a five-point stencil.
# The ZeroOneBeta relmat/animal rows are NOT covered: native drmTMB refuses a
# structured SD formula for zero_one_beta ("structured SD regression is not
# implemented"), so there is no native fit to test.
# The relmat kernel has a non-constant diagonal (D K D, D in [0.8, 1.6]); the
# animal kernel is Henderson A of an inbred pedigree (diag up to about 1.7).
# Supplied kernels are in reverse level order. Tolerance 1e-4 absolute on
# logLik; every emulated bug (reversed SD, flipped selector, K by position,
# K x 2, cov2cor(K)) must move the oracle by more than 0.1. No calibration,
# coverage or parity claim.

b31no_struct_case <- function(family, kind, provider, seed, per_group = 14L) {
  set.seed(seed)
  field <- b29b_make_field(kind)
  if (kind == "relmat") field <- b31no_nonunit(field)
  lev <- field$levels
  G <- length(lev)
  z <- field$zlev
  a <- c(log(0.8), 1.0)
  u <- b31no_latent(field, a, z)
  n <- G * per_group
  chr <- sample(rep(lev, length.out = n))
  x <- stats::rnorm(n)
  eta <- 0.1 + 0.3 * x + u[chr]
  phi_true <- 1 / 0.5^2
  y <- switch(family,
    gaussian = eta + 0.5 * stats::rnorm(n),
    beta = stats::rbeta(n, stats::plogis(eta) * phi_true,
                        (1 - stats::plogis(eta)) * phi_true))
  if (family != "gaussian") {
    inner <- y > 0 & y < 1
    y[inner] <- pmin(pmax(y[inner], 1e-6), 1 - 1e-6)
  }
  dat <- data.frame(y = y, x = x, id = factor(chr, levels = lev), w = unname(z[chr]))
  K <- field$K
  A <- field$K
  Ainv <- solve(field$K)
  dimnames(Ainv) <- dimnames(K)
  Q <- Ainv
  term <- switch(provider,
    K = "relmat(1 | id, K = K)", Q = "relmat(1 | id, Q = Q)",
    A = "animal(1 | id, A = A)", Ainv = "animal(1 | id, Ainv = Ainv)")
  level <- if (kind == "relmat") "relmat" else "animal"
  mu <- stats::as.formula(paste("y ~ x +", term))
  environment(mu) <- environment()
  sdf <- stats::as.formula(sprintf('sd(id, level = "%s") ~ w', level))
  extra <- list(sigma ~ 1)
  fam <- switch(family, gaussian = stats::gaussian(), beta = beta_family())
  fit <- suppressWarnings(drmTMB(do.call(bf, c(list(mu), extra, list(sdf))),
                                 family = fam, data = dat,
                                 control = drm_control(se = FALSE)))
  info <- paste(family, kind, provider)
  key <- sprintf("sd_%s(id)", level)
  co <- coef(fit, key)
  expect_named(co, c("(Intercept)", "w"))
  beta_hat <- unname(coef(fit, "mu"))
  eta_fixed <- beta_hat[[1L]] + beta_hat[[2L]] * dat$x
  sig <- exp(unname(coef(fit, "sigma")[[1L]]))
  terms <- list(b31no_term(field, dat, "id", 1, co, z, "intercept"))
  gauss <- NULL
  deriv <- NULL
  if (family == "gaussian") {
    gauss <- list(y = dat$y, mu = eta_fixed, sigma = sig)
  } else if (family == "beta") {
    phi <- 1 / sig^2
    deriv <- b31no_fd(function(e) b31no_dbeta_log(dat$y, stats::plogis(e), phi))
  }
  b31no_check(fit, deriv, eta_fixed, terms, info, gauss = gauss)
}

test_that("Gaussian relmat (Q) intercept SD: exact marginal oracle and bug sensitivity", {
  skip_on_cran()
  b31no_struct_case("gaussian", "relmat", "Q", 31401L)
})
test_that("Beta relmat (K) intercept SD: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_struct_case("beta", "relmat", "K", 31402L)
})
test_that("Beta animal (A) intercept SD: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b31no_struct_case("beta", "animal", "A", 31403L)
})
