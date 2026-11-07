# Batch 29 (strengthen-a) companion for the native Gaussian-family ordinary
# random-slope SD evidence ids, which were recovery-only (coarse coefficient
# tolerances, no likelihood oracle, no emulated-bug sensitivity):
#   gaussian-native-independent-slope-sd-20261024
#   gaussian-native-independent-slope-sd-current-20261025
#     (test-gaussian-sd-slope-regression.R, mu:x1..xp iid_numeric_slope)
#   native-gaussian-sigma-iid-slope-20261025
#     (test-gaussian-sigma-sd-slope-regression.R, sigma:x1..xp)
#   native-lognormal-sigma-iid-slope-20261025
#     (test-lognormal-sigma-sd-regression.R, sigma:x1..xp)
#
# Reviewer deficiency closed: no independent likelihood oracle and no
# emulated-bug sensitivity. Here, in base R only (helper-sb26-oracle.R and
# helper-b26sa-oracles.R hold nothing from drmTMB):
#   * mu slope  y ~ x + (0 + x | id), sd(id, coef = "x") ~ w: exact Gaussian
#     marginal y ~ N(X b, s^2 I + Z diag(tau)^2 Z'), Z[i, g(i)] = x_i.
#   * sigma slope  sigma ~ 1 + (0 + z | id), sd(id, dpar = "sigma",
#     coef = "z") ~ w: dense Laplace of the Gaussian density with
#     log sigma_i = s0 + z_i tau_g u_g (b26sa_gauss_laplace).
#   * lognormal sigma slope: the same oracle on log(y), minus sum(log y).
# The SD vector is built by hand from the fitted coefficients, exp(a0 + a1 w),
# not from predict(). Agreement tolerance 1e-4 absolute on logLik (exact
# marginal: 1e-6). Every emulated bug must move the oracle by more than
# b29_gap_floor (declared before the first run); the floor is not tuned.
# Emulated bugs: reversed per-group SD vector, intercept and w coefficients
# swapped, sign-flipped w coefficient, the SD predictor ignored (mean SD), and
# the slope covariate replaced by another column (selector swap).
# Scope: likelihood agreement at the fitted parameters and selector
# alignment. No calibration, coverage or parity claim.

b29_gap_floor <- 1

b29_gs_fixture <- function(seed, n_group = 50L, n_each = 16L,
                           kind = c("mu", "sigma")) {
  kind <- match.arg(kind)
  set.seed(seed)
  id <- factor(rep(sprintf("g%02d", seq_len(n_group)), each = n_each))
  gi <- as.integer(id)
  w_group <- sample(seq(-1, 1, length.out = n_group))
  tau <- exp(log(0.4) + (if (identical(kind, "mu")) 0.9 else 1.4) * w_group)
  x <- stats::rnorm(length(id))
  z <- stats::rnorm(length(id))
  u <- stats::rnorm(n_group, sd = tau)
  if (identical(kind, "mu")) {
    y <- 0.2 + 0.35 * x + u[gi] * x + 0.4 * stats::rnorm(length(id))
  } else {
    y <- 0.2 + 0.35 * x +
      stats::rnorm(length(id), sd = exp(log(0.4) + u[gi] * z))
  }
  list(data = data.frame(y = y, x = x, z = z, w = w_group[gi], id = id),
       w_group = w_group, n_group = n_group)
}

b29_sd_curve <- function(a, w_group) unname(exp(a[[1L]] + a[[2L]] * w_group))

b29_bug_gaps <- function(ll, bugs) {
  gaps <- abs(ll - unlist(bugs))
  if (nzchar(Sys.getenv("B29_PRINT"))) print(round(gaps, 3))
  for (nm in names(gaps)) {
    expect_gt(gaps[[nm]], b29_gap_floor, label = paste("gap for", nm))
  }
  invisible(gaps)
}

test_that("Gaussian mu random-slope SD matches the exact marginal and moves under emulated bugs", {
  skip_on_cran()
  fx <- b29_gs_fixture(20261301L, kind = "mu")
  d <- fx$data
  target <- 'sd(id, coef = "x")'
  fit <- drmTMB(
    bf(y ~ x + (0 + x | id), sigma ~ 1, sd(id, coef = "x") ~ w),
    family = stats::gaussian(), data = d, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  a <- coef(fit, dpar = target)
  expect_named(a, c("(Intercept)", "w"))
  beta <- unname(coef(fit, "mu"))
  sig <- exp(unname(coef(fit, "sigma"))[[1L]])
  mu <- beta[[1L]] + beta[[2L]] * d$x
  idx <- as.integer(d$id)
  G <- fx$n_group
  oracle <- function(tau, weight = d$x) {
    sb26_gauss_loglik(d$y, mu, sig, sb26_Z(idx, G, tau, weight), diag(G))
  }
  tau_hat <- b29_sd_curve(a, fx$w_group)
  expect_gt(stats::sd(log(tau_hat)), 0.3)
  ll <- as.numeric(logLik(fit))
  expect_lt(abs(ll - oracle(tau_hat)), 1e-6)
  b29_bug_gaps(ll, list(
    reversed_sd = oracle(rev(tau_hat)),
    swapped_coefficients = oracle(b29_sd_curve(rev(a), fx$w_group)),
    sign_flipped_w = oracle(b29_sd_curve(c(a[[1L]], -a[[2L]]), fx$w_group)),
    predictor_ignored = oracle(rep(mean(tau_hat), G)),
    slope_covariate_swapped = oracle(tau_hat, weight = d$z),
    slope_applied_as_intercept = oracle(tau_hat, weight = 1)
  ))
})

b29_gs_sigma_oracle <- function(y, X, beta, s0, zvec, idx, G, tau, V = 0) {
  b26sa_gauss_laplace(
    y = y, X = X, beta = beta, s0 = s0, V = rep(V, length(y)),
    Zm = matrix(0, length(y), G),
    Zs = zvec * b26sa_indicator(idx, G),
    P = diag(1 / tau^2, G), logdet_cov = sum(log(tau^2))
  )
}

test_that("Gaussian sigma random-slope SD matches a dense Laplace oracle and moves under emulated bugs", {
  skip_on_cran()
  fx <- b29_gs_fixture(20261302L, kind = "sigma")
  d <- fx$data
  target <- 'sd(id, dpar = "sigma", coef = "z")'
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1 + (0 + z | id), sd(id, dpar = "sigma", coef = "z") ~ w),
    family = stats::gaussian(), data = d, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  a <- coef(fit, dpar = target)
  expect_named(a, c("(Intercept)", "w"))
  idx <- as.integer(d$id)
  G <- fx$n_group
  oracle <- function(tau, zvec = d$z) {
    b29_gs_sigma_oracle(d$y, cbind(1, d$x), unname(coef(fit, "mu")),
                        unname(coef(fit, "sigma"))[[1L]], zvec, idx, G, tau)
  }
  tau_hat <- b29_sd_curve(a, fx$w_group)
  expect_gt(stats::sd(log(tau_hat)), 0.3)
  base <- oracle(tau_hat)
  expect_lt(base$max_grad, 1e-8)
  expect_gt(base$min_eig, 0)
  ll <- as.numeric(logLik(fit))
  expect_lt(abs(ll - base$loglik), 1e-4)
  b29_bug_gaps(ll, list(
    reversed_sd = oracle(rev(tau_hat))$loglik,
    swapped_coefficients = oracle(b29_sd_curve(rev(a), fx$w_group))$loglik,
    sign_flipped_w = oracle(b29_sd_curve(c(a[[1L]], -a[[2L]]), fx$w_group))$loglik,
    predictor_ignored = oracle(rep(mean(tau_hat), G))$loglik,
    slope_covariate_swapped = oracle(tau_hat, zvec = d$x)$loglik
  ))
})

test_that("Lognormal sigma random-slope SD matches a dense Laplace oracle on log(y) and moves under emulated bugs", {
  skip_on_cran()
  fx <- b29_gs_fixture(20261303L, kind = "sigma")
  d <- fx$data
  d$y <- exp(d$y)                      # lognormal response
  target <- 'sd(id, dpar = "sigma", coef = "z")'
  fit <- drmTMB(
    bf(y ~ 1, sigma ~ 1 + (0 + z | id), sd(id, dpar = "sigma", coef = "z") ~ w),
    family = lognormal(), data = d, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  a <- coef(fit, dpar = target)
  expect_named(a, c("(Intercept)", "w"))
  idx <- as.integer(d$id)
  G <- fx$n_group
  oracle <- function(tau, zvec = d$z) {
    b29_gs_sigma_oracle(log(d$y), matrix(1, nrow(d), 1L),
                        unname(coef(fit, "mu")),
                        unname(coef(fit, "sigma"))[[1L]], zvec, idx, G, tau)
  }
  tau_hat <- b29_sd_curve(a, fx$w_group)
  expect_gt(stats::sd(log(tau_hat)), 0.3)
  base <- oracle(tau_hat)
  expect_lt(base$max_grad, 1e-8)
  expect_gt(base$min_eig, 0)
  jac <- sum(log(d$y))                 # lognormal density = normal(log y) / y
  ll <- as.numeric(logLik(fit))
  expect_lt(abs(ll - (base$loglik - jac)), 1e-4)
  b29_bug_gaps(ll, list(
    reversed_sd = oracle(rev(tau_hat))$loglik - jac,
    swapped_coefficients = oracle(b29_sd_curve(rev(a), fx$w_group))$loglik - jac,
    sign_flipped_w = oracle(b29_sd_curve(c(a[[1L]], -a[[2L]]), fx$w_group))$loglik - jac,
    predictor_ignored = oracle(rep(mean(tau_hat), G))$loglik - jac,
    slope_covariate_swapped = oracle(tau_hat, zvec = d$x)$loglik - jac
  ))
})
