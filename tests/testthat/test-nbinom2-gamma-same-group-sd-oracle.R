# Independent dense-Laplace oracle for the same-group independent intercept +
# slope model with separate SD regressions:
#   sd(id, coef = "(Intercept)") ~ w1,  sd(id, coef = "x") ~ w2.
# Written without drmTMB internals. Per group, b = (b0, b1), q = 2, independent
# N(0, tau0^2), N(0, tau1^2); marginal = Laplace at the conditional mode.
# Tolerance fixed before the first run: |logLik(fit) - oracle| < 1e-4 (absolute).
# Each emulated bug (swapped SD formulas, swapped predictors, level
# misalignment) must move the oracle by more than 1 log-likelihood unit, which
# is 1e4 times the tolerance. Different predictors and clearly different true
# coefficients are used so that a swap is detectable.

oracle_fixture <- function(family, seed = 20261103L, n_id = 40L, n_each = 10L) {
  set.seed(seed)
  id <- factor(rep(sprintf("g%02d", seq_len(n_id)), each = n_each))
  gi <- as.integer(id)
  x <- rep(seq(-1.2, 1.2, length.out = n_each), times = n_id)
  w1 <- as.numeric(scale(sin(seq_len(n_id) * 1.7)))        # intercept-SD predictor
  w2 <- as.numeric(scale(cos(seq_len(n_id) * 0.9 + 1)))    # slope-SD predictor
  a0 <- c(log(0.55), 0.8)
  a1 <- c(log(0.30), -0.9)
  b0 <- rnorm(n_id, sd = exp(a0[1] + a0[2] * w1))
  b1 <- rnorm(n_id, sd = exp(a1[1] + a1[2] * w2))
  mu <- exp(0.4 + 0.3 * x + b0[gi] + b1[gi] * x)
  sig <- 0.4
  y <- if (family == "nbinom2") {
    rnbinom(length(mu), size = 1 / sig^2, mu = mu)
  } else {
    rgamma(length(mu), shape = 1 / sig^2, scale = mu * sig^2)
  }
  data.frame(y = y, x = x, id = id, w1 = w1[gi], w2 = w2[gi])
}

# Log density, score and observed information in log mu.
oracle_terms <- function(family, y, lin, sig) {
  mu <- exp(lin)
  k <- 1 / sig^2
  if (family == "nbinom2") {
    list(ll = dnbinom(y, size = k, mu = mu, log = TRUE),
         g = k * (y - mu) / (k + mu),
         h = k * mu * (k + y) / (k + mu)^2)
  } else {
    list(ll = dgamma(y, shape = k, scale = mu / k, log = TRUE),
         g = k * (y / mu - 1), h = k * y / mu)
  }
}

oracle_group <- function(family, y, eta, Z, tau, sig) {
  q <- ncol(Z)
  joint <- function(b) {
    sum(oracle_terms(family, y, eta + drop(Z %*% b), sig)$ll) +
      sum(dnorm(b, 0, tau, log = TRUE))
  }
  b <- rep(0, q)
  for (it in seq_len(200L)) {
    tm <- oracle_terms(family, y, eta + drop(Z %*% b), sig)
    grad <- drop(crossprod(Z, tm$g)) - b / tau^2
    H <- crossprod(Z, tm$h * Z) + diag(1 / tau^2, q)
    step <- drop(solve(H, grad))
    s <- 1
    while (joint(b + s * step) < joint(b) - 1e-12 && s > 1e-8) s <- s / 2
    b <- b + s * step
    if (max(abs(grad)) < 1e-10) break
  }
  tm <- oracle_terms(family, y, eta + drop(Z %*% b), sig)
  stopifnot(max(abs(drop(crossprod(Z, tm$g)) - b / tau^2)) < 1e-8)
  H <- crossprod(Z, tm$h * Z) + diag(1 / tau^2, q)
  joint(b) + 0.5 * q * log(2 * pi) -
    0.5 * as.numeric(determinant(H, logarithm = TRUE)$modulus)
}

# Modes: "ok"; "swap_sd" (intercept latent gets the slope SD formula and vice
# versa, each with its own predictor); "swap_pred" (right coefficients, wrong
# predictor in each formula); "misalign" (group SDs shifted by one level).
oracle_loglik <- function(family, d, beta, a0, a1, log_sigma,
                          mode = "ok") {
  gl <- levels(d$id)
  ng <- length(gl)
  w1g <- d$w1[match(gl, d$id)]
  w2g <- d$w2[match(gl, d$id)]
  t0 <- exp(a0[1] + a0[2] * (if (mode == "swap_pred") w2g else w1g))
  t1 <- exp(a1[1] + a1[2] * (if (mode == "swap_pred") w1g else w2g))
  if (mode == "misalign") {
    t0 <- t0[c(2:ng, 1L)]
    t1 <- t1[c(2:ng, 1L)]
  }
  sum(vapply(seq_len(ng), function(j) {
    i <- which(d$id == gl[j])
    tau <- if (mode == "swap_sd") c(t1[j], t0[j]) else c(t0[j], t1[j])
    oracle_group(family, d$y[i], beta[1] + beta[2] * d$x[i],
                 cbind(1, d$x[i]), tau, exp(log_sigma))
  }, numeric(1L)))
}

oracle_check <- function(family_fun, family_name) {
  d <- oracle_fixture(family_name)
  k0 <- 'sd(id, dpar = "mu", coef = "(Intercept)")'
  k1 <- 'sd(id, dpar = "mu", coef = "x")'
  fit <- drmTMB(
    bf(y ~ x + (1 | id) + (0 + x | id), sigma ~ 1,
       sd(id, dpar = "mu", coef = "(Intercept)") ~ w1,
       sd(id, dpar = "mu", coef = "x") ~ w2),
    family = family_fun(), data = d, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  beta <- unname(coef(fit, "mu"))
  a0 <- unname(coef(fit, k0))
  a1 <- unname(coef(fit, k1))
  ls <- unname(coef(fit, "sigma"))
  ll <- as.numeric(logLik(fit))
  expect_lt(abs(ll - oracle_loglik(family_name, d, beta, a0, a1, ls)), 1e-4)
  for (m in c("swap_sd", "swap_pred", "misalign")) {
    gap <- abs(ll - oracle_loglik(family_name, d, beta, a0, a1, ls, mode = m))
    expect_gt(gap, 1)
  }
  invisible(fit)
}

test_that("NB2 same-group intercept and slope SD regressions match a dense Laplace oracle", {
  skip_on_cran()
  oracle_check(nbinom2, "nbinom2")
})

test_that("Gamma same-group intercept and slope SD regressions match a dense Laplace oracle", {
  skip_on_cran()
  oracle_check(function() Gamma(link = "log"), "gamma")
})
