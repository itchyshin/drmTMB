# Batch 26 (lane sa) companion to test-gaussian-mu-sigma-joint-sd.R.
# Adds emulated-bug sensitivity to the dense Laplace oracle for the joint
# mu (1 | id) with sd(id) ~ w and sigma random effect on `site` with
# sd(site, dpar = "sigma"[, coef = "z"]) ~ v. The oracle takes the SD vectors
# from the fitted coefficients by hand (not predict()). Tolerance 1e-4 on
# logLik; each emulated bug must move the oracle by more than 0.1.
# Scope: likelihood agreement at the fitted parameters only.

b26sa_gmj_fixture <- function(seed, slope, n_id = 40L, n_site = 60L,
                              n_each = 24L) {
  set.seed(seed)
  n <- n_id * n_each
  row <- seq_len(n)
  id <- factor(sprintf("id%02d", (row - 1L) %/% n_each + 1L))
  site <- factor(sprintf("s%02d", (row - 1L) %% n_site + 1L))
  w_id <- seq(-1, 1, length.out = n_id)
  v_site <- seq(-1, 1, length.out = n_site)
  a <- stats::rnorm(n_id, sd = exp(log(0.6) + 0.4 * w_id))
  b <- stats::rnorm(n_site, sd = exp(log(0.35) + 0.6 * v_site))
  x <- stats::rnorm(n)
  z <- if (slope) stats::rnorm(n) else rep(1, n)
  gi <- as.integer(id)
  gs <- as.integer(site)
  y <- 0.2 + 0.5 * x + a[gi] +
    stats::rnorm(n, sd = exp(log(0.5) + b[gs] * z))
  list(
    data = data.frame(y = y, x = x, z = z, id = id, site = site,
                      w = w_id[gi], v = v_site[gs]),
    w_id = w_id, v_site = v_site
  )
}

b26sa_gmj_check <- function(fx, formula, key_site) {
  fit <- drmTMB(formula, family = stats::gaussian(), data = fx$data,
                control = drm_control(se = FALSE))
  expect_equal(fit$opt$convergence, 0L)
  d <- fx$data
  cm <- stats::coef(fit, "sd(id)")
  cs <- stats::coef(fit, key_site)
  expect_named(cm, c("(Intercept)", "w"))
  expect_named(cs, c("(Intercept)", "v"))
  ni <- nlevels(d$id)
  ns <- nlevels(d$site)
  curve <- function(co, z) unname(exp(co[[1L]] + co[[2L]] * z))
  oracle <- function(sd_id, sd_site) {
    b26sa_gauss_laplace(
      y = d$y, X = cbind(1, d$x), beta = unname(stats::coef(fit, "mu")),
      s0 = unname(stats::coef(fit, "sigma"))[[1L]], V = rep(0, nrow(d)),
      Zm = cbind(b26sa_indicator(as.integer(d$id), ni),
                 matrix(0, nrow(d), ns)),
      Zs = cbind(matrix(0, nrow(d), ni),
                 d$z * b26sa_indicator(as.integer(d$site), ns)),
      P = diag(c(1 / sd_id^2, 1 / sd_site^2)),
      logdet_cov = sum(log(sd_id^2)) + sum(log(sd_site^2))
    )
  }
  sd_id <- curve(cm, fx$w_id)
  sd_site <- curve(cs, fx$v_site)
  base <- oracle(sd_id, sd_site)
  expect_lt(base$max_grad, 1e-8)
  expect_gt(base$min_eig, 0)
  ll <- as.numeric(stats::logLik(fit))
  expect_lt(abs(ll - base$loglik), 1e-4)
  bugs <- c(
    reversed_mu_sd = oracle(rev(sd_id), sd_site)$loglik,
    reversed_sigma_sd = oracle(sd_id, rev(sd_site))$loglik,
    swapped_selector_coefs = oracle(curve(cs, fx$w_id),
                                    curve(cm, fx$v_site))$loglik,
    predictor_ignored = oracle(rep(mean(sd_id), ni),
                               rep(mean(sd_site), ns))$loglik
  )
  for (nm in names(bugs)) expect_gt(abs(ll - bugs[[nm]]), 0.1, label = nm)
  invisible(bugs)
}

test_that("mu intercept SD plus sigma slope SD: oracle and bug sensitivity", {
  skip_on_cran()
  fx <- b26sa_gmj_fixture(20261701L, slope = TRUE)
  b26sa_gmj_check(
    fx,
    bf(y ~ x + (1 | id), sigma ~ 1 + (0 + z | site),
       sd(id) ~ w, sd(site, dpar = "sigma", coef = "z") ~ v),
    'sd(site, dpar = "sigma", coef = "z")'
  )
})

test_that("mu intercept SD plus sigma intercept SD: oracle and bug sensitivity", {
  skip_on_cran()
  fx <- b26sa_gmj_fixture(20261102L, slope = FALSE, n_each = 30L)
  b26sa_gmj_check(
    fx,
    bf(y ~ x + (1 | id), sigma ~ 1 + (1 | site),
       sd(id) ~ w, sd(site, dpar = "sigma") ~ v),
    'sd(site, dpar = "sigma")'
  )
})
