# Poisson ordinary random-effect SD regression with
# miss_control(response = "include").
#
# Claim: a response coded NA contributes no likelihood term (the C++ observed_y
# mask drops its Poisson density and nothing is imputed), so the fit with the NA
# rows kept equals the fit on the observed rows only, while the NA rows still
# receive predictions from their (complete) predictors.
#
# Oracle, independent of drmTMB: the dense Laplace marginal
#   joint(b*) + (q/2) log(2 pi) - 0.5 log det(Z' diag(mu*) Z + diag(1/tau^2))
# per group, evaluated at the fitted coefficients on the observed rows only.
# Tolerances were fixed before the first run: include vs complete-case logLik
# 1e-8 (exact, same likelihood); oracle 1e-6; bug-sensitivity gap > 0.05.

pmi_laplace <- function(y, eta, Z, tau) {
  q <- ncol(Z)
  b <- rep(0, q)
  joint <- function(b) {
    lin <- eta + as.vector(Z %*% b)
    sum(y * lin - exp(lin) - lgamma(y + 1)) -
      0.5 * sum(b^2 / tau^2) - sum(log(tau)) - 0.5 * q * log(2 * pi)
  }
  for (iter in seq_len(200L)) {
    mu <- exp(eta + as.vector(Z %*% b))
    grad <- as.vector(crossprod(Z, y - mu)) - b / tau^2
    H <- crossprod(Z, mu * Z) + diag(1 / tau^2, q)
    step <- as.vector(solve(H, grad))
    scale <- 1
    while (joint(b + scale * step) < joint(b) - 1e-12 && scale > 1e-8) {
      scale <- scale / 2
    }
    b <- b + scale * step
    if (max(abs(grad)) < 1e-11) break
  }
  mu <- exp(eta + as.vector(Z %*% b))
  H <- crossprod(Z, mu * Z) + diag(1 / tau^2, q)
  stopifnot(max(abs(as.vector(crossprod(Z, y - mu)) - b / tau^2)) < 1e-8)
  joint(b) + 0.5 * q * log(2 * pi) -
    0.5 * as.numeric(determinant(H, logarithm = TRUE)$modulus)
}

# Shuffled group levels, group-level SD covariates w0 and w1, and counts.
pmi_fixture <- function(seed = 2026110191L, n_id = 40L, n_each = 8L,
                        na_group = NULL) {
  set.seed(seed)
  lev <- sprintf("id%02d", sample.int(n_id))
  id <- factor(rep(lev, each = n_each), levels = sort(lev))
  gi <- as.integer(id)
  x <- stats::rnorm(n_id * n_each)
  w0 <- seq(-1, 1, length.out = n_id)[sample.int(n_id)]
  w1 <- rep(c(-0.5, 0.5), length.out = n_id)[sample.int(n_id)]
  tau0 <- exp(log(0.55) + 0.45 * w0)
  tau1 <- exp(log(0.4) - 0.5 * w1)
  b0 <- stats::rnorm(n_id, sd = tau0)
  b1 <- stats::rnorm(n_id, sd = tau1)
  y <- stats::rpois(n_id * n_each,
                    exp(0.2 + 0.3 * x + b0[gi] + b1[gi] * x))
  dat <- data.frame(y = y, x = x, id = id, w0 = w0[gi], w1 = w1[gi])
  # Roughly 20% of responses are NA; each group keeps observed rows unless it
  # is named in na_group, which is made entirely NA.
  dat$y[seq_len(nrow(dat)) %% 5L == 2L] <- NA
  if (!is.null(na_group)) dat$y[dat$id == levels(dat$id)[na_group]] <- NA
  dat
}

pmi_observed <- function(dat) dat[!is.na(dat$y), , drop = FALSE]

pmi_oracle <- function(dat, beta, tau_fun, design) {
  obs <- pmi_observed(dat)
  sum(vapply(split(seq_len(nrow(obs)), as.character(obs$id)), function(i) {
    g <- obs[i, , drop = FALSE]
    Z <- design(g)
    stopifnot(ncol(Z) == length(tau_fun(g[1L, ])))
    pmi_laplace(g$y, beta[[1L]] + beta[[2L]] * g$x, Z, tau_fun(g[1L, ]))
  }, numeric(1L)))
}

pmi_fit <- function(formula, dat, include = TRUE) {
  drmTMB(formula, poisson(),
         if (include) dat else pmi_observed(dat),
         missing = if (include) miss_control(response = "include") else
           miss_control(),
         control = drm_control(se = FALSE))
}

test_that("Poisson intercept SD include fit equals complete-case and the oracle", {
  skip_on_cran()
  dat <- pmi_fixture()
  expect_true(anyNA(dat$y))
  inc <- pmi_fit(bf(y ~ x + (1 | id), sd(id) ~ w0), dat)
  cc <- pmi_fit(bf(y ~ x + (1 | id), sd(id) ~ w0), dat, include = FALSE)
  expect_equal(inc$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(inc)), as.numeric(logLik(cc)),
               tolerance = 1e-8)
  expect_equal(unname(coef(inc, "mu")), unname(coef(cc, "mu")),
               tolerance = 1e-5)
  expect_equal(unname(coef(inc, "sd(id)")), unname(coef(cc, "sd(id)")),
               tolerance = 1e-5)
  expect_equal(nobs(inc), sum(!is.na(dat$y)))
  tau_fun <- function(g) exp(coef(inc, "sd(id)")[[1L]] +
                               coef(inc, "sd(id)")[[2L]] * g$w0)
  design <- function(g) matrix(1, nrow(g), 1L)
  oracle <- pmi_oracle(dat, coef(inc, "mu"), tau_fun, design)
  expect_equal(as.numeric(logLik(inc)), oracle, tolerance = 1e-6)
  # Emulated bug: masked rows scored as observed zeros.
  zeroed <- dat
  zeroed$y[is.na(zeroed$y)] <- 0
  bugged <- pmi_oracle(zeroed, coef(inc, "mu"), tau_fun, design)
  expect_gt(abs(bugged - oracle), 0.05)
  # Emulated bug: the SD covariate attached to the wrong groups.
  wrong_tau <- function(g) exp(coef(inc, "sd(id)")[[1L]] -
                                 coef(inc, "sd(id)")[[2L]] * g$w0)
  expect_gt(abs(pmi_oracle(dat, coef(inc, "mu"), wrong_tau, design) - oracle),
            0.05)
  # Constant-SD equivalence: sd(id) ~ 1 equals the plain random intercept.
  plain <- pmi_fit(bf(y ~ x + (1 | id)), dat)
  const <- pmi_fit(bf(y ~ x + (1 | id), sd(id) ~ 1), dat)
  expect_equal(as.numeric(logLik(const)), as.numeric(logLik(plain)),
               tolerance = 1e-5)
  # Predictions exist for the NA rows and for every group SD.
  mu_hat <- predict(inc, dpar = "mu")
  expect_length(mu_hat, nrow(dat))
  expect_true(all(is.finite(mu_hat[is.na(dat$y)])))
  sd_hat <- predict(inc, dpar = "sd(id)")
  expect_length(sd_hat, nlevels(dat$id))
  expect_true(all(is.finite(sd_hat) & sd_hat > 0))
})

test_that("Poisson intercept SD include handles a group with every response NA", {
  skip_on_cran()
  dat <- pmi_fixture(seed = 2026110192L, na_group = 7L)
  empty <- dat$id == levels(dat$id)[7L]
  expect_true(all(is.na(dat$y[empty])))
  inc <- pmi_fit(bf(y ~ x + (1 | id), sd(id) ~ w0), dat)
  cc <- pmi_fit(bf(y ~ x + (1 | id), sd(id) ~ w0), dat, include = FALSE)
  expect_equal(as.numeric(logLik(inc)), as.numeric(logLik(cc)),
               tolerance = 1e-8)
  expect_equal(unname(coef(inc, "sd(id)")), unname(coef(cc, "sd(id)")),
               tolerance = 1e-5)
  mu_hat <- predict(inc, dpar = "mu")
  expect_true(all(is.finite(mu_hat[empty])))
  expect_length(predict(inc, dpar = "sd(id)"), nlevels(dat$id))
})

test_that("Poisson slope SD include fit equals complete-case and the oracle", {
  skip_on_cran()
  dat <- pmi_fixture(seed = 2026110193L)
  key <- 'sd(id, coef = "x")'
  f <- bf(y ~ x + (0 + x | id), sd(id, coef = "x") ~ w1)
  inc <- pmi_fit(f, dat)
  cc <- pmi_fit(f, dat, include = FALSE)
  expect_equal(inc$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(inc)), as.numeric(logLik(cc)),
               tolerance = 1e-8)
  expect_equal(unname(coef(inc, key)), unname(coef(cc, key)),
               tolerance = 1e-5)
  tau_fun <- function(g) exp(coef(inc, key)[[1L]] + coef(inc, key)[[2L]] * g$w1)
  design <- function(g) matrix(g$x, nrow(g), 1L)
  oracle <- pmi_oracle(dat, coef(inc, "mu"), tau_fun, design)
  expect_equal(as.numeric(logLik(inc)), oracle, tolerance = 1e-6)
  zeroed <- dat
  zeroed$y[is.na(zeroed$y)] <- 0
  expect_gt(abs(pmi_oracle(zeroed, coef(inc, "mu"), tau_fun, design) - oracle),
            0.05)
  # Constant-SD equivalence with the plain independent slope.
  plain <- pmi_fit(bf(y ~ x + (0 + x | id)), dat)
  const <- pmi_fit(bf(y ~ x + (0 + x | id), sd(id, coef = "x") ~ 1), dat)
  expect_equal(as.numeric(logLik(const)), as.numeric(logLik(plain)),
               tolerance = 1e-5)
  mu_hat <- predict(inc, dpar = "mu")
  expect_true(all(is.finite(mu_hat[is.na(dat$y)])))
  sd_hat <- predict(inc, dpar = key)
  expect_length(sd_hat, nlevels(dat$id))
  expect_true(all(is.finite(sd_hat) & sd_hat > 0))
})

test_that("Poisson same-group intercept and slope SDs include fit matches", {
  skip_on_cran()
  dat <- pmi_fixture(seed = 2026110194L)
  key0 <- 'sd(id, coef = "(Intercept)")'
  key1 <- 'sd(id, coef = "x")'
  f <- bf(y ~ x + (1 | id) + (0 + x | id),
          sd(id, coef = "(Intercept)") ~ w0, sd(id, coef = "x") ~ w1)
  inc <- pmi_fit(f, dat)
  cc <- pmi_fit(f, dat, include = FALSE)
  expect_equal(inc$opt$convergence, 0L)
  expect_equal(as.numeric(logLik(inc)), as.numeric(logLik(cc)),
               tolerance = 1e-8)
  a0 <- coef(inc, key0)
  a1 <- coef(inc, key1)
  tau_fun <- function(g) c(exp(a0[[1L]] + a0[[2L]] * g$w0),
                           exp(a1[[1L]] + a1[[2L]] * g$w1))
  design <- function(g) cbind(1, g$x)
  oracle <- pmi_oracle(dat, coef(inc, "mu"), tau_fun, design)
  expect_equal(as.numeric(logLik(inc)), oracle, tolerance = 1e-6)
  swapped <- function(g) rev(tau_fun(g))
  expect_gt(abs(pmi_oracle(dat, coef(inc, "mu"), swapped, design) - oracle),
            0.05)
  expect_true(all(is.finite(predict(inc, dpar = "mu")[is.na(dat$y)])))
})

test_that("Poisson SD include keeps its other fences closed", {
  dat <- pmi_fixture(n_id = 12L, n_each = 4L)
  inc <- miss_control(response = "include")
  # Zero-inflated include with an SD formula stays refused.
  expect_error(drm_build_poisson_spec(
    bf(y ~ x + (1 | id), zi ~ 1, sd(id) ~ w0), dat, missing = inc),
    "complete predictors")
  # Correlated blocks with missing responses stay refused.
  expect_error(drm_build_poisson_spec(
    bf(y ~ x + (1 + x | id), sd(id, coef = "x") ~ w0), dat, missing = inc),
    "missing-response integration")
  # One ordinary intercept beside a relmat intercept is the iid shape; it is
  # admitted with include since batch 23
  # (test-count-iid-slope-sd-missing-include.R). Two ordinary random effects
  # beside a structured intercept stay refused (the structured validator fires
  # before the SD gate).
  K <- diag(nlevels(dat$id))
  rownames(K) <- colnames(K) <- levels(dat$id)
  dat$site <- factor(rep(seq_len(4L), length.out = nrow(dat)))
  dat$site2 <- factor(rep(seq_len(3L), length.out = nrow(dat)))
  expect_no_error(drm_build_poisson_spec(
    bf(y ~ x + relmat(1 | id, K = K) + (1 | site), sd(site) ~ 1),
    dat, missing = inc))
  expect_error(drm_build_poisson_spec(
    bf(y ~ x + relmat(1 | id, K = K) + (1 | site) + (1 | site2),
       sd(site) ~ 1),
    dat, missing = inc),
    "cannot be combined with ordinary")
  # Without include, NA responses are still dropped (complete-case default).
  spec <- drm_build_poisson_spec(bf(y ~ x + (1 | id), sd(id) ~ w0), dat)
  expect_identical(length(spec$y), sum(!is.na(dat$y)))
})
