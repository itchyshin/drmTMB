# Batch 29 (lane b) companion to the sigma random-slope SD tests
#   test-gaussian-sigma-sd-slope-regression.R
#   test-lognormal-sigma-sd-regression.R   (sigma ~ 1 + (0 + x | id))
#   test-nbinom2-sigma-slope-sd-regression.R
# (evidence ids native-gaussian-sigma-iid-slope-20261025-m26,
# native-lognormal-sigma-iid-slope-20261025-m26,
# native-nbinom2-sigma-iid-slope-20261025-m26).
#
# Reviewer deficiency closed: recovery-only tests (estimate within 0.25-0.35 of
# truth) with no likelihood oracle and no sensitivity. Here the model is
#   log sigma_i = s0 + z_i u_g,  u_g ~ N(0, tau_g^2),  tau_g = exp(a0 + a1 w_g),
# and the Laplace marginal is computed in base R from the fitted mean
# coefficients, s0 and (a0, a1): per-observation log-likelihood and its first
# two derivatives in theta = log sigma are written by hand (Gaussian, lognormal
# = Gaussian on log y less sum(log y), NB2 with size = exp(-2 theta); the NB2
# derivatives are checked against central finite differences first), and the
# dense Laplace uses observed information. logLik tolerance 1e-4 absolute.
# Emulated bugs (reversed per-group SD vector, flipped SD slope, SD ignoring the
# predictor, SD from a shuffled predictor, z shuffled across rows) must
# each move the oracle by more than 0.1. Scope: likelihood assembly and
# selector alignment at one seed; no calibration, coverage or recovery claim.

b29b_theta_deriv <- function(family, y, mu, size_fun = NULL) {
  force(y)
  force(mu)
  if (family %in% c("gaussian", "lognormal")) {
    yy <- if (identical(family, "lognormal")) log(y) else y
    jac <- if (identical(family, "lognormal")) sum(log(y)) else 0
    function(theta) {
      r2 <- (yy - mu)^2 * exp(-2 * theta)
      list(l = -0.5 * log(2 * pi) - theta - 0.5 * r2 - jac / length(y),
           d1 = -1 + r2, d2 = -2 * r2)
    }
  } else {
    function(theta) {
      s <- exp(-2 * theta)
      m <- mu
      l <- stats::dnbinom(y, size = s, mu = m, log = TRUE)
      ls <- digamma(y + s) - digamma(s) + log(s / (s + m)) + 1 - (s + y) / (s + m)
      lss <- trigamma(y + s) - trigamma(s) + 1 / s - 1 / (s + m) -
        (m - y) / (s + m)^2
      list(l = l, d1 = -2 * s * ls, d2 = 4 * s * ls + 4 * s^2 * lss)
    }
  }
}

b29b_sigma_fixture <- function(family, seed, groups = 40L, repeats = 20L) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  gi <- as.integer(id)
  w_group <- seq(-1, 1, length.out = groups)
  tau <- exp(log(0.5) + 0.8 * w_group)
  u <- stats::rnorm(groups, sd = tau)
  x <- stats::rnorm(length(id))
  z <- if (identical(family, "lognormal")) {
    rep(rep(c(-1, 1), length.out = repeats), times = groups)
  } else if (identical(family, "nbinom2")) {
    pmax(-2, pmin(2, stats::rnorm(length(id))))   # bounded: keeps log(sigma) range moderate
  } else {
    stats::rnorm(length(id))
  }
  s0 <- if (identical(family, "nbinom2")) -0.5 else -0.4
  sigma <- exp(s0 + z * u[gi])
  y <- switch(
    family,
    gaussian = stats::rnorm(length(id), 0.2 + 0.35 * x, sigma),
    lognormal = stats::rlnorm(length(id), 0.2 + 0.35 * x, sigma),
    nbinom2 = stats::rnbinom(length(id), size = 1 / sigma^2,
                             mu = exp(0.45 - 0.15 * x))
  )
  list(data = data.frame(y = y, x = x, z = z, w = w_group[gi], id = id),
       w_group = w_group)
}

b29b_sigma_check <- function(family, seed) {
  fx <- b29b_sigma_fixture(family, seed)
  dat <- fx$data
  target <- 'sd(id, dpar = "sigma", coef = "z")'
  fml <- bf(y ~ x, sigma ~ 1 + (0 + z | id), sd(id, dpar = "sigma", coef = "z") ~ w)
  fam <- switch(family, gaussian = stats::gaussian(), lognormal = lognormal(),
                nbinom2 = nbinom2())
  fit <- drmTMB(fml, family = fam, data = dat,
                control = drm_control(se = FALSE,
                                       optimizer = list(eval.max = 800, iter.max = 800)))
  expect_identical(fit$opt$convergence, 0L, info = family)
  co <- coef(fit, target)
  expect_named(co, c("(Intercept)", "w"))
  m <- unname(coef(fit, "mu"))
  mu_lin <- m[[1L]] + m[[2L]] * dat$x
  mu <- if (identical(family, "nbinom2")) exp(mu_lin) else mu_lin
  s0 <- unname(coef(fit, "sigma")[["(Intercept)"]])
  deriv <- b29b_theta_deriv(family, dat$y, mu)
  # Oracle self-check: hand derivatives against central finite differences.
  th <- seq(-1.2, 0.4, length.out = length(dat$y))
  h <- 1e-5
  d <- deriv(th)
  expect_lt(max(abs((deriv(th + h)$l - deriv(th - h)$l) / (2 * h) - d$d1)), 1e-5)
  expect_lt(max(abs((deriv(th + h)$d1 - deriv(th - h)$d1) / (2 * h) - d$d2)), 1e-5)
  gi <- as.integer(dat$id)
  m_g <- nlevels(dat$id)
  sd_of <- function(a1 = co[[2L]], w = fx$w_group, a0 = co[[1L]]) exp(a0 + a1 * w)
  oracle <- function(sd = sd_of(), z = dat$z) {
    sb26_laplace(deriv, rep(s0, length(dat$y)), sb26_Z(gi, m_g, sd, w = z),
                 diag(m_g))
  }
  ref <- oracle()
  ll <- as.numeric(logLik(fit))
  expect_lt(abs(ll - ref), 1e-4, label = family)
  expect_gt(stats::sd(log(sd_of())), 0.1)
  expect_equal(unname(predict(fit, dpar = target)), sd_of(), tolerance = 1e-6)
  set.seed(seed + 1L)
  bugs <- c(
    reversed_sd = oracle(sd = rev(sd_of())),
    flipped_sd_slope = oracle(sd = sd_of(a1 = -co[[2L]])),
    sd_ignores_predictor = oracle(sd = sd_of(a1 = 0)),
    sd_from_shuffled_predictor = oracle(sd = sd_of(w = sample(fx$w_group))),
    z_shuffled_rows = oracle(z = sample(dat$z))
  )
  for (nm in names(bugs)) {
    expect_gt(abs(bugs[[nm]] - ref), 0.1, label = paste(family, nm))
  }
  if (nzchar(Sys.getenv("B29B_SHOW_GAPS"))) {
    cat(sprintf("GAP %s | ll-ref %.2e | a=(%.2f,%.2f) | %s\n", family, ll - ref,
                co[[1L]], co[[2L]],
                paste(sprintf("%s=%.2f", names(bugs), abs(bugs - ref)), collapse = " ")))
  }
}

test_that("Gaussian sigma random-slope SD regression: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b29b_sigma_check("gaussian", 29801L)
})

test_that("Lognormal sigma random-slope SD regression: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b29b_sigma_check("lognormal", 29802L)
})

test_that("NB2 sigma random-slope SD regression: dense Laplace oracle and bug sensitivity", {
  skip_on_cran()
  b29b_sigma_check("nbinom2", 29803L)
})
