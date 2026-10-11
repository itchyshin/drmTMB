# Discrimination (scale) submodel `disc ~ z` for cumulative_logit() (#966).
#
# Contract under test:
#   Pr(y_i <= k) = logit^-1(disc_i * (theta_k - mu_i)),
#   log(disc_i)  = z_i' gamma   (no intercept: disc = 1 at the reference z).
# The disc intercept is fixed at log(1) = 0 because multiplying every cutpoint,
# every location coefficient, and 1 / disc by the same constant leaves the
# likelihood unchanged. ordinal::clm(scale = ~ z) uses the same constraint on
# the latent scale s_i = 1 / disc_i, so its scale coefficients equal -gamma.

new_ordinal_disc_data <- function(n = 3000, seed = 20261011,
                                  gamma = c(z = 0.45)) {
  set.seed(seed)
  dat <- data.frame(x = stats::rnorm(n), z = stats::rnorm(n))
  beta_mu <- c(x = 0.8)
  cutpoints <- c(-1.2, 0, 1.1)
  eta <- beta_mu[["x"]] * dat$x
  disc <- exp(gamma[["z"]] * dat$z)
  cumulative <- stats::plogis(
    disc * (matrix(cutpoints, n, length(cutpoints), byrow = TRUE) - eta)
  )
  prob <- cbind(cumulative, 1) - cbind(0, cumulative)
  draw <- vapply(
    seq_len(n),
    function(i) sample.int(ncol(prob), size = 1L, prob = prob[i, ]),
    integer(1)
  )
  levs <- c("none", "low", "medium", "high")
  dat$score <- ordered(levs[draw], levels = levs)
  list(data = dat, beta_mu = beta_mu, gamma = gamma, cutpoints = cutpoints)
}

test_that("disc ~ 1 reproduces the location-only cumulative-logit fit exactly", {
  sim <- new_ordinal_disc_data(n = 600, seed = 20261012)
  fit0 <- drmTMB(bf(score ~ x), family = cumulative_logit(), data = sim$data)
  fit1 <- drmTMB(
    bf(score ~ x, disc ~ 1),
    family = cumulative_logit(),
    data = sim$data
  )

  expect_identical(fit1$opt$par, fit0$opt$par)
  expect_identical(fit1$opt$objective, fit0$opt$objective)
  expect_identical(as.numeric(logLik(fit1)), as.numeric(logLik(fit0)))
  expect_identical(coef(fit1), coef(fit0))
  expect_identical(fit1$ordinal$cutpoints, fit0$ordinal$cutpoints)
  expect_identical(fit1$sdr$cov.fixed, fit0$sdr$cov.fixed)
  expect_identical(fitted(fit1), fitted(fit0))
  expect_identical(fit1$df, fit0$df)
  expect_named(coef(fit1), "mu")
})

test_that("disc ~ z recovers the location, cutpoints, and discrimination slope", {
  sim <- new_ordinal_disc_data()
  fit <- drmTMB(
    bf(score ~ x, disc ~ z),
    family = cumulative_logit(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0)
  expect_true(fit$sdr$pdHess)
  expect_named(coef(fit), c("mu", "disc"))
  expect_named(coef(fit, "disc"), "z")
  expect_equal(fit$df, 1L + 3L + 1L)

  se <- sqrt(diag(vcov(fit)))
  expect_lt(abs(coef(fit, "mu")[["x"]] - sim$beta_mu[["x"]]), 4 * se[["mu:x"]])
  expect_lt(
    abs(coef(fit, "disc")[["z"]] - sim$gamma[["z"]]),
    4 * se[["disc:z"]]
  )
  expect_equal(unname(fit$ordinal$cutpoints), sim$cutpoints, tolerance = 0.15)

  ci <- confint(fit)
  disc_row <- ci[ci$parm == "fixef:disc:z", , drop = FALSE]
  expect_equal(nrow(disc_row), 1L)
  expect_equal(disc_row$tmb_parameter, "beta_sigma")
  expect_true(disc_row$lower < sim$gamma[["z"]])
  expect_true(disc_row$upper > sim$gamma[["z"]])
})

test_that("disc ~ z matches ordinal::clm location-scale fits", {
  skip_if_not_installed("ordinal")
  sim <- new_ordinal_disc_data(n = 1200, seed = 20261013)
  dat <- sim$data
  dat$g <- factor(ifelse(dat$z > 0.3, "b", "a"))

  fit <- drmTMB(
    bf(score ~ x, disc ~ z),
    family = cumulative_logit(),
    data = dat
  )
  ref <- ordinal::clm(score ~ x, scale = ~z, data = dat, link = "logit")

  expect_equal(as.numeric(logLik(fit)), as.numeric(logLik(ref)),
               tolerance = 1e-6)
  expect_equal(coef(fit, "mu")[["x"]], ref$beta[["x"]], tolerance = 1e-4)
  expect_equal(unname(fit$ordinal$cutpoints), unname(ref$alpha),
               tolerance = 1e-4)
  # clm models the latent scale s = 1 / disc, so its zeta is -gamma.
  expect_equal(coef(fit, "disc")[["z"]], -ref$zeta[["z"]], tolerance = 1e-4)
  expect_equal(
    sqrt(diag(vcov(fit)))[["disc:z"]],
    sqrt(diag(vcov(ref)))[["z"]],
    tolerance = 1e-3
  )

  fit_g <- drmTMB(
    bf(score ~ x, disc ~ g),
    family = cumulative_logit(),
    data = dat
  )
  ref_g <- ordinal::clm(score ~ x, scale = ~g, data = dat, link = "logit")
  expect_named(coef(fit_g, "disc"), "gb")
  expect_equal(as.numeric(logLik(fit_g)), as.numeric(logLik(ref_g)),
               tolerance = 1e-6)
  expect_equal(coef(fit_g, "disc")[["gb"]], -ref_g$zeta[["gb"]],
               tolerance = 1e-4)
})

test_that("disc ~ z methods use the discrimination in every probability", {
  sim <- new_ordinal_disc_data(n = 400, seed = 20261014)
  fit <- drmTMB(
    bf(score ~ x, disc ~ z),
    family = cumulative_logit(),
    data = sim$data
  )

  gamma_hat <- coef(fit, "disc")[["z"]]
  disc_hat <- exp(gamma_hat * fit$data$z)
  expect_equal(predict(fit, dpar = "disc"), disc_hat, tolerance = 1e-12)
  expect_equal(
    predict(fit, dpar = "disc", type = "link"),
    gamma_hat * fit$data$z,
    tolerance = 1e-12
  )
  expect_equal(sigma(fit), 1 / disc_hat, tolerance = 1e-12)

  eta <- predict(fit, dpar = "mu", type = "link")
  cp <- unname(fit$ordinal$cutpoints)
  cumulative <- stats::plogis(
    disc_hat * (matrix(cp, length(eta), length(cp), byrow = TRUE) - eta)
  )
  prob <- cbind(cumulative, 1) - cbind(0, cumulative)
  y <- as.integer(fit$model$y)
  expect_equal(
    as.numeric(logLik(fit)),
    sum(log(prob[cbind(seq_along(y), y)])),
    tolerance = 1e-8
  )
  expected_score <- as.vector(prob %*% seq_len(ncol(prob)))
  expect_equal(fitted(fit), expected_score, tolerance = 1e-10)
  expect_equal(
    unname(drmTMB:::ordinal_category_probabilities(fit)),
    prob,
    tolerance = 1e-10
  )

  newdata <- data.frame(x = c(-1, 0, 1), z = c(1, 0, -1))
  expect_equal(
    predict(fit, newdata = newdata, dpar = "disc"),
    exp(gamma_hat * newdata$z),
    tolerance = 1e-12
  )
  prob_new <- drmTMB:::ordinal_category_probabilities(fit, newdata = newdata)
  eta_new <- coef(fit, "mu")[["x"]] * newdata$x
  cum_new <- stats::plogis(
    exp(gamma_hat * newdata$z) *
      (matrix(cp, 3L, length(cp), byrow = TRUE) - eta_new)
  )
  expect_equal(unname(prob_new), cbind(cum_new, 1) - cbind(0, cum_new),
               tolerance = 1e-10)

  # The distributional-output closures read the same discrimination.
  expect_equal(
    predict(fit, type = "cdf", newdata = transform(newdata, score = 2L)),
    cum_new[, 2L],
    tolerance = 1e-10
  )

  sims <- simulate(fit, nsim = 2, seed = 20261015)
  expect_true(is.ordered(sims$sim_1))
  expect_equal(levels(sims$sim_1), fit$ordinal$levels)
})

test_that("disc ~ z combines with a mu random intercept", {
  sim <- new_ordinal_disc_data(n = 900, seed = 20261016)
  dat <- sim$data
  dat$id <- factor(rep(seq_len(90), each = 10))
  fit <- drmTMB(
    bf(score ~ x + (1 | id), disc ~ z),
    family = cumulative_logit(),
    data = dat
  )
  expect_equal(fit$opt$convergence, 0)
  expect_named(coef(fit), c("mu", "disc"))
  expect_true(is.finite(coef(fit, "disc")[["z"]]))
})

test_that("disc formulas are validated with an explicit identifiability contract", {
  sim <- new_ordinal_disc_data(n = 120, seed = 20261017)
  dat <- sim$data
  dat$id <- factor(rep(seq_len(12), each = 10))

  expect_error(
    drmTMB(bf(score ~ x, disc ~ z + (1 | id)), family = cumulative_logit(),
           data = dat),
    "disc"
  )
  expect_error(
    drmTMB(bf(score ~ x, disc ~ 0 + z), family = cumulative_logit(),
           data = dat),
    "intercept"
  )
  expect_error(
    drmTMB(bf(score ~ x, disc ~ z + offset(x)), family = cumulative_logit(),
           data = dat),
    "offset"
  )
  expect_error(
    drmTMB(bf(score ~ x, sigma ~ z), family = cumulative_logit(), data = dat),
    "support only"
  )
  expect_error(
    drmTMB(bf(y ~ x, disc ~ z), family = gaussian(),
           data = transform(dat, y = x)),
    "disc"
  )
})
