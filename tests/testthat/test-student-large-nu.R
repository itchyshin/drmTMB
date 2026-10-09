# #1462: the univariate Student log-density used lgamma((nu+1)/2) - lgamma(nu/2)
# and log(1 + z^2/nu). Both cancel as nu -> Inf, so the compiled logLik can
# sit above the Gaussian maximum. The stable form must match stats::dt() and
# keep the gradient and Hessian finite at that edge. No Julia.

student_large_nu_data <- function(seed = 20286929, n = 80) {
  set.seed(seed)
  x <- stats::rnorm(n)
  data.frame(
    y = 1 + 0.5 * x + exp(-0.4) * stats::rnorm(n),
    x = x
  )
}

student_large_nu_par <- function(fit, beta_mu, log_sigma, eta_nu) {
  par <- fit$obj$par
  par[names(par) == "beta_mu"] <- beta_mu
  par[names(par) == "beta_sigma"] <- log_sigma
  par[names(par) == "beta_nu"] <- eta_nu
  par
}

test_that("student density at huge nu matches dt() and stays finite in the Hessian (#1462)", {
  dat <- student_large_nu_data()
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ 1),
    family = student(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  beta_mu <- unname(stats::coef(stats::lm(y ~ x, dat)))
  mu <- as.numeric(cbind(1, dat$x) %*% beta_mu)
  sigma <- sqrt(mean((dat$y - mu)^2))
  ll_gauss <- sum(stats::dnorm(dat$y, mu, sigma, log = TRUE))
  z <- (dat$y - mu) / sigma

  # Below the Stirling switch (nu = 1e4) the lgamma branch must still match dt().
  # Above it, including the eta_nu ~ 57 region from #1462, the series must too.
  for (eta_nu in c(log(8), 10, log(1e4 - 2), 20, 40, 55)) {
    nu <- 2 + exp(eta_nu)
    par <- student_large_nu_par(fit, beta_mu, log(sigma), eta_nu)
    ll <- -fit$obj$fn(par)
    ref <- sum(stats::dt(z, df = nu, log = TRUE) - log(sigma))
    expect_equal(ll, ref, tolerance = 1e-6, info = paste("eta_nu", eta_nu))
    # A finite-nu Student density can sit slightly above the Gaussian density
    # at the same sigma, because the peak is sharper. The #1462 failure was an
    # excess of order 1e11 once nu was huge. Past nu = 1e6 that excess has to
    # stay tiny as the density approaches the Gaussian limit.
    if (nu >= 1e6) {
      expect_lt(ll - ll_gauss, 1e-4, label = paste("excess", eta_nu))
    }
    grad <- as.numeric(fit$obj$gr(par))
    hess <- fit$obj$he(par)
    expect_true(all(is.finite(grad)), info = paste("gradient", eta_nu))
    expect_true(all(is.finite(hess)), info = paste("Hessian", eta_nu))
  }
})

test_that("a Student fit of Gaussian data does not report a logLik above the Gaussian maximum (#1462)", {
  dat <- student_large_nu_data()
  gauss <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  stud <- suppressWarnings(drmTMB(
    bf(y ~ x, sigma ~ 1, nu ~ 1),
    family = student(),
    data = dat,
    control = drm_control(se = FALSE)
  ))
  # An extra shape parameter can improve the likelihood by a fraction of a
  # nat on Gaussian data. The broken objective improved it by about 1e11.
  stud_ll <- as.numeric(stats::logLik(stud))
  gauss_ll <- as.numeric(stats::logLik(gauss))
  expect_true(is.finite(stud_ll))
  expect_lt(stud_ll - gauss_ll, 2)
})
