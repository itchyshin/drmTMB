# #1476 / #1477: Beta prior mass and Gamma CV recovery after the
# parameter-centered Gauss-Hermite importance rules.

test_that("renormalised Beta mi() quadrature mass is 1 within 1e-10 (#1476)", {
  mus <- c(0.50, 0.10, 0.02)
  sigs <- c(1, 0.5, 0.2, 0.1, 0.05)
  for (mu in mus) {
    for (sig in sigs) {
      mass31 <- drm_beta_mi_quadrature_mass(mu, sig, n = 31L)
      mass81 <- drm_beta_mi_quadrature_mass(mu, sig, n = 81L)
      expect_equal(
        mass81,
        1,
        tolerance = 1e-10,
        info = sprintf("mu=%.2f sigma=%.2f n=81", mu, sig)
      )
      expect_equal(
        mass31,
        1,
        tolerance = 1e-8,
        info = sprintf("mu=%.2f sigma=%.2f n=31", mu, sig)
      )
    }
  }
})

test_that("Gamma mi() quadrature mass stays near 1 at low CV (#1477)", {
  for (sig in c(1, 0.5, 0.2, 0.1, 0.05)) {
    mass <- drm_gamma_mi_quadrature_mass(mu = 10, sigma = sig, n = 31L)
    expect_equal(
      mass,
      1,
      tolerance = 1e-8,
      info = sprintf("sigma=%.2f shape=%.1f", sig, 1 / sig^2)
    )
  }
})

test_that("production Gamma/Beta nodes match a high-node / integrate() logLik", {
  y <- 7
  mu_y <- 2
  sigma_y <- 0.5
  beta_x <- 0.5
  x_base <- 0
  mu <- 10
  sig <- 0.1
  quad <- drmTMB:::drm_gamma_mi_quadrature(31L)
  is <- drmTMB:::drm_gamma_mi_is_nodes(quad$nodes, quad$weights, mu, sig)
  log_mass <- drmTMB:::drm_logsumexp(is$log_prior)
  log_y <- stats::dnorm(y, mu_y + beta_x * (is$x - x_base), sigma_y, log = TRUE)
  prod_ll <- drmTMB:::drm_logsumexp(is$log_prior - log_mass + log_y)
  ref <- drm_gamma_mi_reference_loglik(y, mu_y, sigma_y, beta_x, x_base, mu, sig)
  expect_equal(prod_ll, log(ref), tolerance = 1e-5)

  mu_b <- 0.5
  sig_b <- 0.05
  quad_b <- drmTMB:::drm_beta_mi_quadrature(31L)
  is_b <- drmTMB:::drm_beta_mi_is_nodes(quad_b$nodes, quad_b$weights, mu_b, sig_b)
  log_mass_b <- drmTMB:::drm_logsumexp(is_b$log_prior)
  y_b <- 1.5
  log_y_b <- stats::dnorm(y_b, 1 + 2 * is_b$x, 0.1, log = TRUE)
  prod_b <- drmTMB:::drm_logsumexp(is_b$log_prior - log_mass_b + log_y_b)
  ref_b <- drm_beta_mi_reference_loglik(y_b, 1, 0.1, 2, 0, mu_b, sig_b)
  expect_equal(prod_b, log(ref_b), tolerance = 1e-5)
})

test_that("Gamma mi() recovers a low-CV predictor (#1477)", {
  skip_on_cran()
  set.seed(1477)
  n <- 80
  nmiss <- 20
  cv <- 0.10
  z <- stats::rnorm(n)
  mu <- exp(2 + 0.2 * z)
  x <- stats::rgamma(n, shape = 1 / cv^2, scale = mu * cv^2)
  y <- 1 + 0.5 * x + stats::rnorm(n, 0, 0.5)
  d <- data.frame(y, x, z)
  d$x[sample(n, nmiss)] <- NA
  fit <- suppressWarnings(drmTMB(
    bf(y ~ mi(x), sigma ~ 1),
    data = d,
    impute = list(x = impute_model(x ~ z, family = Gamma(link = "log"))),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  ))
  expect_equal(fit$opt$convergence, 0L)
  est <- as.numeric(fit$obj$report(fit$obj$env$last.par.best)$sigma_gamma_mi)
  expect_gt(est, 0.05)
  expect_lt(est, 0.16)
  expect_lt(abs(est - cv), 0.05)
})
