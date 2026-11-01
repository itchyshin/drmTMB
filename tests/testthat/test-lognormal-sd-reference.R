test_that("lognormal SD reference reproduces its symbolic DGP", {
  d <- data.frame(
    group = factor(rep(c("g1", "g2", "g3"), each = 2),
                   levels = c("g1", "g2", "g3")),
    w = rep(c(-1, 0.5, 1.5), each = 2),
    x = c(-0.5, 0.2, 1, -1, 0.4, 0.8),
    z = c(0, 1, -1, 0.3, 0.7, -0.2)
  )
  par <- lognormal_sd_reference_parameters()
  latent_u <- c(g1 = 0.25, g2 = -1.1, g3 = 0.6)
  latent_epsilon <- c(-0.4, 0.1, 1.2, -0.3, 0.8, -0.7)
  generated <- lognormal_sd_reference_dgp(d, par, latent_u, latent_epsilon)

  w_group <- c(g1 = -1, g2 = 0.5, g3 = 1.5)
  tau <- exp(par$alpha[[1]] + par$alpha[[2]] * w_group)
  sigma <- exp(par$gamma[[1]] + par$gamma[[2]] * d$z)
  log_y_expected <- par$beta[[1]] + par$beta[[2]] * d$x +
    tau[as.character(d$group)] * latent_u[as.character(d$group)] +
    sigma * latent_epsilon
  expect_equal(unname(log(generated)), unname(log_y_expected), tolerance = 1e-14)
  expect_true(all(is.finite(generated) & generated > 0))
})

test_that("exact group marginal includes heteroscedastic covariance and response Jacobian", {
  d <- data.frame(
    y = c(0.8, 1.4, 2.2, 0.6, 1.1, 1.7),
    group = factor(rep(c("a", "b"), each = 3), levels = c("a", "b")),
    w = rep(c(-0.7, 1.1), each = 3),
    x = c(-0.4, 0.3, 1.2, 0.7, -1.1, 0.2),
    z = c(-1, 0.5, 1.3, 0.2, -0.8, 0.9)
  )
  par <- lognormal_sd_reference_parameters()
  actual <- lognormal_sd_exact_marginal_loglik(d, par)

  # Independent construction: block covariance has observation-specific
  # residual variances plus the shared group-intercept covariance.
  log_y <- log(d$y)
  mu <- par$beta[[1]] + par$beta[[2]] * d$x
  sigma <- exp(par$gamma[[1]] + par$gamma[[2]] * d$z)
  tau_by_group <- exp(par$alpha[[1]] + par$alpha[[2]] * c(a = -0.7, b = 1.1))
  expected <- 0
  for (g in levels(d$group)) {
    i <- which(d$group == g)
    V <- tau_by_group[[g]]^2 * matrix(1, length(i), length(i)) +
      diag(sigma[i]^2, length(i))
    R <- chol(V)
    whitened <- forwardsolve(t(R), log_y[i] - mu[i])
    expected <- expected - 0.5 * (
      length(i) * log(2 * pi) + 2 * sum(log(diag(R))) + sum(whitened^2)
    ) - sum(log(d$y[i]))
  }
  expect_equal(actual, expected, tolerance = 1e-12)
})

test_that("exact reference has the zero-intercept-SD and singleton limits", {
  d <- data.frame(
    y = c(0.7, 1.3, 2.1), group = factor(c("a", "a", "b")),
    w = c(-1, -1, 1), x = c(-0.2, 0.4, 0.9), z = c(0, -0.5, 1)
  )
  par <- lognormal_sd_reference_parameters()
  par$alpha <- c(`(Intercept)` = -Inf, w = 0)
  log_y <- log(d$y)
  mu <- par$beta[[1]] + par$beta[[2]] * d$x
  sigma <- exp(par$gamma[[1]] + par$gamma[[2]] * d$z)
  independent <- sum(dnorm(log_y, mu, sigma, log = TRUE)) - sum(log(d$y))
  expect_equal(lognormal_sd_exact_marginal_loglik(d, par), independent,
               tolerance = 1e-12)

  one <- d[3, , drop = FALSE]
  par$alpha <- c(`(Intercept)` = log(0.9), w = 0.35)
  singleton_variance <- exp(2 * (par$gamma[[1]] + par$gamma[[2]] * one$z)) +
    exp(2 * (par$alpha[[1]] + par$alpha[[2]] * one$w))
  singleton <- dnorm(log(one$y), par$beta[[1]] + par$beta[[2]] * one$x,
                     sqrt(singleton_variance), log = TRUE) - log(one$y)
  expect_equal(lognormal_sd_exact_marginal_loglik(one, par), singleton,
               tolerance = 1e-12)
})

test_that("group mapping is invariant to row order and rejects inconsistent group w", {
  d <- data.frame(
    y = c(0.8, 1.4, 2.2, 0.6, 1.1, 1.7),
    group = factor(rep(c("g1", "g2", "g3"), each = 2),
                   levels = c("g1", "g2", "g3")),
    w = rep(c(-1.2, 0.3, 1.4), each = 2),
    x = c(0, 1, -0.4, 0.2, 0.7, -0.8),
    z = c(0.2, -0.5, 1.1, 0.7, -1, 0.4)
  )
  par <- lognormal_sd_reference_parameters()
  base <- lognormal_sd_exact_marginal_loglik(d, par)
  perm <- c(5, 2, 6, 1, 4, 3)
  expect_equal(lognormal_sd_exact_marginal_loglik(d[perm, ], par), base,
               tolerance = 1e-12)

  wrong_w <- d
  wrong_w$w <- rep(c(1.4, -1.2, 0.3), each = 2)
  expect_gt(abs(lognormal_sd_exact_marginal_loglik(wrong_w, par) - base), 1e-5)
  inconsistent <- d
  inconsistent$w[2] <- inconsistent$w[2] + 0.1
  expect_error(lognormal_sd_exact_marginal_loglik(inconsistent, par),
               "constant within group")
})
