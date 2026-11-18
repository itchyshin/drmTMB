# Zero-inflated Poisson with one independent mu slope and NO sd() formula.
# NB2 admits this shape; ZIP now admits it too (it used to build only with an
# sd() formula). Tolerances, fixed before running:
#   * fit versus dense integral: |logLik - oracle| / groups < 0.1 (the same
#     per-group bound the other zero-inflated Poisson oracles use);
#   * plain versus constant-SD fit: logLik relative tolerance 1e-5, fitted SD
#     relative tolerance 1e-4;
#   * sensitivity: doubling the oracle SD must move it by more than 1.
# This is a short targeted synthetic fit, not a calibration or parity claim.

zi_poisson_plain_slope_data <- function(groups = 40L, repeats = 12L,
                                        seed = 20261101L) {
  set.seed(seed)
  id <- factor(rep(seq_len(groups), each = repeats))
  x <- rep(seq(-1, 1, length.out = repeats), groups)
  b <- stats::rnorm(groups, sd = 0.6)
  mu <- exp(0.3 + 0.4 * x + b[id] * x)
  y <- ifelse(stats::rbinom(length(id), 1L, 0.25) == 1L, 0L,
              stats::rpois(length(id), mu))
  data.frame(y = y, x = x, id = id)
}

# Dense quadrature of each cluster integral over the standardised effect z,
# with b_g = sd * z entering the log mean as x * b_g.
zi_poisson_plain_slope_oracle <- function(data, beta_mu, beta_zi, sd,
                                          sd_scale = 1) {
  log_zi <- stats::plogis(beta_zi, log.p = TRUE)
  log_one_minus_zi <- stats::plogis(beta_zi, lower.tail = FALSE, log.p = TRUE)
  logspace_add_two <- function(a, b) pmax(a, b) + log1p(exp(-abs(a - b)))
  rows <- split(seq_len(nrow(data)), data$id)
  sum(vapply(rows, function(i) {
    log_integrand <- function(z) {
      mu <- exp(beta_mu[[1L]] + beta_mu[[2L]] * data$x[i] +
                  sd_scale * sd * z * data$x[i])
      y <- data$y[i]
      row_loglik <- ifelse(
        y == 0L,
        vapply(mu, function(m) logspace_add_two(log_zi, log_one_minus_zi - m),
               numeric(1)),
        log_one_minus_zi + stats::dpois(y, lambda = mu, log = TRUE)
      )
      sum(row_loglik) + stats::dnorm(z, log = TRUE)
    }
    peak <- stats::optimize(log_integrand, c(-8, 8), maximum = TRUE)$objective
    integrated <- stats::integrate(
      function(z) exp(vapply(z, log_integrand, numeric(1)) - peak),
      lower = -8, upper = 8, rel.tol = 1e-8, subdivisions = 200L
    )$value
    peak + log(integrated)
  }, numeric(1)))
}

test_that("ZIP constant-SD slope fit matches the dense integral (builds today)", {
  dat <- zi_poisson_plain_slope_data()
  constant <- drmTMB(
    bf(y ~ x + (0 + x | id), zi ~ 1, sd(id, coef = "x") ~ 1),
    family = stats::poisson(link = "log"), data = dat
  )
  expect_true(is_converged(constant))
  expect_true(isTRUE(constant$sdr$pdHess))

  sd_hat <- exp(unname(coef(constant, "sd(id, coef = \"x\")")[["(Intercept)"]]))
  beta_mu <- unname(coef(constant, "mu"))
  beta_zi <- unname(coef(constant, "zi")[["(Intercept)"]])
  oracle <- zi_poisson_plain_slope_oracle(dat, beta_mu, beta_zi, sd_hat)
  expect_lt(abs(as.numeric(logLik(constant)) - oracle) / nlevels(dat$id), 0.1)
  doubled <- zi_poisson_plain_slope_oracle(dat, beta_mu, beta_zi, sd_hat,
                                           sd_scale = 2)
  expect_gt(abs(oracle - doubled), 1)
})

test_that("ZIP plain independent slope without sd() matches oracle and constant SD", {
  dat <- zi_poisson_plain_slope_data()
  plain <- drmTMB(bf(y ~ x + (0 + x | id), zi ~ 1),
                  family = stats::poisson(link = "log"), data = dat)
  expect_true(is_converged(plain))
  expect_true(isTRUE(plain$sdr$pdHess))

  constant <- drmTMB(
    bf(y ~ x + (0 + x | id), zi ~ 1, sd(id, coef = "x") ~ 1),
    family = stats::poisson(link = "log"), data = dat
  )
  expect_equal(as.numeric(logLik(plain)), as.numeric(logLik(constant)),
               tolerance = 1e-5)
  expect_equal(coef(plain, "mu"), coef(constant, "mu"), tolerance = 1e-3)
  expect_equal(coef(plain, "zi"), coef(constant, "zi"), tolerance = 1e-3)

  sd_hat <- exp(unname(plain$opt$par[["log_sd_mu"]]))
  sd_constant <- exp(unname(coef(constant, "sd(id, coef = \"x\")")[["(Intercept)"]]))
  expect_equal(sd_hat, sd_constant, tolerance = 1e-4)

  oracle <- zi_poisson_plain_slope_oracle(
    dat, unname(coef(plain, "mu")), unname(coef(plain, "zi")[["(Intercept)"]]),
    sd_hat
  )
  expect_lt(abs(as.numeric(logLik(plain)) - oracle) / nlevels(dat$id), 0.1)
  doubled <- zi_poisson_plain_slope_oracle(
    dat, unname(coef(plain, "mu")), unname(coef(plain, "zi")[["(Intercept)"]]),
    sd_hat, sd_scale = 2
  )
  expect_gt(abs(oracle - doubled), 1)
})
