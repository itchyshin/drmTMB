# Regression test for #1467: the beta-binomial log-density used to be a plain
# lgamma sum whose terms are about phi log(phi) in size, so as sigma -> 0
# (phi = exp(-2 log_sigma) -> Inf, the binomial limit) each row lost about
# eps * phi log(phi) absolutely. On main at 0eb04678 the compiled objective
# for 300 binomial(10, 0.3) rows was off the binomial limit by 2.5 at
# log_sigma = -12, by -60 at -14 and by +5e5 at -20 (it overshot the limit,
# which a beta-binomial log-likelihood cannot do). The kernel now uses
# drm_lgamma_ratio() (src/drm_numeric.h), which differences the Stirling
# series analytically.

bb_large_phi_fit <- function() {
  set.seed(20261003)
  trials <- 10
  y <- stats::rbinom(300, trials, 0.3)
  dat <- data.frame(succ = y, fail = trials - y)
  fit <- suppressWarnings(drmTMB(
    bf(cbind(succ, fail) ~ 1, sigma ~ 1),
    data = dat,
    family = beta_binomial(),
    control = drm_control(se = FALSE, logsigma_clamp = NULL)
  ))
  list(fit = fit, y = y, trials = trials)
}

# Exact reference with no lgamma call:
# lgamma(x + m) - lgamma(x) = sum_{k = 0}^{m - 1} log(x + k).
bb_exact_loglik <- function(y, trials, mu, phi) {
  a <- mu * phi
  b <- (1 - mu) * phi
  rising <- function(x, m) if (m == 0) 0 else sum(log(x + seq_len(m) - 1))
  sum(vapply(y, function(yi) {
    lchoose(trials, yi) + rising(a, yi) + rising(b, trials - yi) -
      rising(a + b, trials)
  }, numeric(1)))
}

test_that("beta_binomial log-likelihood is exact and tends to the binomial limit as sigma -> 0 (#1467)", {
  setup <- bb_large_phi_fit()
  fit <- setup$fit
  mu <- 0.3
  par <- fit$obj$par
  par[names(par) == "beta_mu"] <- stats::qlogis(mu)
  binom_limit <- sum(stats::dbinom(setup$y, setup$trials, mu, log = TRUE))
  log_sigma <- c(-2, -5, -9, -11.5, -12, -13, -14, -15, -20)
  ll <- numeric(length(log_sigma))
  for (k in seq_along(log_sigma)) {
    par[names(par) == "beta_sigma"] <- log_sigma[k]
    ll[k] <- -fit$obj$fn(par)
    # The kernel's own mean nudge (1e-12) is applied before the shapes.
    mu_k <- 1e-12 + (1 - 2e-12) * mu
    exact <- bb_exact_loglik(setup$y, setup$trials, mu_k, exp(-2 * log_sigma[k]))
    expect_lt(abs(ll[k] - exact), 1e-8)
    expect_true(all(is.finite(fit$obj$gr(par))))
  }
  # Never above the binomial limit, non-decreasing towards it, and equal to it
  # once phi is huge.
  expect_true(all(ll <= binom_limit + 1e-9))
  expect_true(all(diff(ll) >= -1e-9))
  expect_lt(abs(ll[length(ll)] - binom_limit), 1e-8)
})

test_that("drm_lgamma_ratio() branches agree at the switch (#1467)", {
  # Indirect check through the compiled kernel: a single row with trials = 50
  # evaluated just below and above phi = 100 (the Stirling switch for the
  # a + b term) must agree with the exact product form to 1e-11.
  dat <- data.frame(succ = 17, fail = 33)
  fit <- suppressWarnings(drmTMB(
    bf(cbind(succ, fail) ~ 1, sigma ~ 1),
    data = dat,
    family = beta_binomial(),
    control = drm_control(se = FALSE, logsigma_clamp = NULL)
  ))
  par <- fit$obj$par
  par[names(par) == "beta_mu"] <- 0
  for (phi in c(99.999999, 100, 100.000001, 250, 1e4)) {
    par[names(par) == "beta_sigma"] <- -0.5 * log(phi)
    mu_k <- 1e-12 + (1 - 2e-12) * 0.5
    exact <- bb_exact_loglik(17, 50, mu_k, phi)
    expect_lt(abs(-fit$obj$fn(par) - exact), 1e-11)
  }
})

# The mi() two-point sum scores a missing-predictor row through the shared
# response leaf (src/drm_response_kernels.h, case 14), not the main loop. The
# fixtures above never reach it, and the existing mi() + beta_binomial tests
# sit at log_sigma near -1 where the old and new forms agree to 1e-13. This
# drives the leaf at log_sigma = -14 (phi = 1.4e12) with the clamp off and
# compares the whole marginal log-likelihood against an exact reference.
test_that("beta_binomial mi() response leaf is exact at large phi (#1467)", {
  n <- 60
  z <- seq(-1.6, 1.7, length.out = n)
  trials <- 8L
  treat <- as.numeric(sin(seq_len(n) * 1.3) + 0.3 * z > 0)
  success <- pmin(trials, pmax(0L, as.integer(round(
    4 + 2 * sin(seq_len(n) / 4) + 2 * treat
  ))))
  dat <- data.frame(
    success = success, failure = trials - success, z = z,
    treatment = factor(treat, levels = c(0, 1))
  )
  miss_rows <- c(5, 12, 23, 31, 44, 52)
  dat$treatment[miss_rows] <- NA
  fit <- suppressWarnings(drmTMB(
    bf(cbind(success, failure) ~ z + mi(treatment), sigma ~ 1),
    data = dat,
    family = beta_binomial(),
    impute = list(treatment = impute_model(treatment ~ z, family = binomial())),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE, logsigma_clamp = NULL)
  ))
  expect_identical(as.integer(fit$obj$env$data$use_logsigma_clamp), 0L)

  model <- fit$model$missing_predictor
  rising <- function(x, m) if (m == 0) 0 else sum(log(x + seq_len(m) - 1))
  bb <- function(y, eta, log_sigma, trials) {
    mu <- 1e-12 + (1 - 2e-12) * stats::plogis(eta) # the kernel's mean nudge
    phi <- exp(-2 * log_sigma)
    a <- mu * phi
    b <- (1 - mu) * phi
    lchoose(trials, y) + rising(a, y) + rising(b, trials - y) -
      rising(a + b, trials)
  }
  manual <- function(par) {
    beta_mu <- par[names(par) == "beta_mu"]
    beta_mi <- par[names(par) == "beta_mi"]
    log_sigma <- par[names(par) == "beta_sigma"][[1]]
    eta_x <- as.vector(model$X %*% beta_mi)
    log_p1 <- stats::plogis(eta_x, log.p = TRUE)
    log_p0 <- stats::plogis(eta_x, lower.tail = FALSE, log.p = TRUE)
    eta_base <- as.vector(fit$model$offset$mu + fit$model$X$mu %*% beta_mu)
    beta_x <- beta_mu[[model$mu_col]]
    x_base <- fit$model$X$mu[, model$mu_col]
    observed <- fit$missing_data$predictors$treatment$observed
    out <- numeric(nrow(dat))
    for (row in seq_len(nrow(dat))) {
      yv <- fit$model$y[[row]]
      tr <- fit$model$trials[[row]]
      if (observed[[row]]) {
        x_row <- as.numeric(dat$treatment[[row]]) - 1
        out[[row]] <- (if (x_row == 1) log_p1[[row]] else log_p0[[row]]) +
          bb(yv, eta_base[[row]], log_sigma, tr)
      } else {
        lp1 <- log_p1[[row]] +
          bb(yv, eta_base[[row]] + beta_x * (1 - x_base[[row]]), log_sigma, tr)
        lp0 <- log_p0[[row]] +
          bb(yv, eta_base[[row]] + beta_x * (0 - x_base[[row]]), log_sigma, tr)
        m <- max(lp1, lp0)
        out[[row]] <- m + log(exp(lp1 - m) + exp(lp0 - m))
      }
    }
    sum(out)
  }
  par <- fit$obj$par
  for (ls in c(-2, -9, -12, -14, -16)) {
    par[names(par) == "beta_sigma"] <- ls
    expect_lt(abs(-fit$obj$fn(par) - manual(par)), 1e-7)
  }
})
