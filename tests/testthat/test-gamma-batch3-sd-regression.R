# Native Gamma(link = "log") crossed ordinary mu intercepts with separate
# predictor-dependent SDs:
#   y ~ x + (1 | g) + (1 | h),  sd(g) ~ w,  sd(h) ~ v,  sigma ~ 1.
#
# Exact oracle: Laplace marginal of
#   y_i | b ~ Gamma(shape = k, mean = exp(eta_i + Z_i b)),  k = 1 / sigma^2,
#   b ~ N(0, diag(tau^2)),
# which is  joint(b*) + (q/2) log(2 pi) - 0.5 log det(H),  with
#   H = k Z' diag(y / mu*) Z + diag(1 / tau^2)   (observed information)
# and b* found by Newton's method. The oracle uses the fitted coefficients, so
# it checks the likelihood assembly (which SD multiplies which latent block),
# not the optimiser. Tolerances are fixed before the first run:
#   oracle logLik: relative 1e-6; constant-SD limit: absolute 1e-4 on logLik,
#   1e-3 on mu and sigma coefficients; predict() identity: relative 1e-7.

gamma_additive_laplace <- function(y, eta, Z, tau, shape) {
  q <- ncol(Z)
  b <- rep(0, q)
  joint <- function(b) {
    lin <- eta + as.vector(Z %*% b)
    sum(shape * (log(shape) - lin) + (shape - 1) * log(y) -
          shape * y * exp(-lin) - lgamma(shape)) -
      0.5 * sum(b^2 / tau^2) - sum(log(tau)) - 0.5 * q * log(2 * pi)
  }
  for (iter in seq_len(200L)) {
    mu <- exp(eta + as.vector(Z %*% b))
    grad <- shape * as.vector(crossprod(Z, y / mu - 1)) - b / tau^2
    H <- shape * crossprod(Z, (y / mu) * Z) + diag(1 / tau^2, q)
    step <- as.vector(solve(H, grad))
    scale <- 1
    while (joint(b + scale * step) < joint(b) - 1e-12 && scale > 1e-8) {
      scale <- scale / 2
    }
    b <- b + scale * step
    if (max(abs(grad)) < 1e-10) break
  }
  mu <- exp(eta + as.vector(Z %*% b))
  H <- shape * crossprod(Z, (y / mu) * Z) + diag(1 / tau^2, q)
  stopifnot(
    max(abs(shape * as.vector(crossprod(Z, y / mu - 1)) - b / tau^2)) < 1e-8
  )
  joint(b) + 0.5 * q * log(2 * pi) -
    0.5 * as.numeric(determinant(H, logarithm = TRUE)$modulus)
}

gamma_crossed_fixture <- function(seed = 2026110151L, n_g = 30L, n_h = 24L,
                                   reps = 3L, sigma = 0.4) {
  set.seed(seed)
  dat <- expand.grid(g = sprintf("g%02d", seq_len(n_g)),
                     h = sprintf("h%02d", seq_len(n_h)),
                     rep = seq_len(reps), stringsAsFactors = FALSE)
  dat$g <- factor(dat$g)
  dat$h <- factor(dat$h)
  dat$x <- stats::rnorm(nrow(dat))
  zg <- seq(-1, 1, length.out = n_g)
  zh <- seq(-1, 1, length.out = n_h)
  dat$w <- zg[as.integer(dat$g)]
  dat$v <- zh[as.integer(dat$h)]
  alpha_g <- c(`(Intercept)` = log(0.5), w = 0.4)
  alpha_h <- c(`(Intercept)` = log(0.45), v = -0.3)
  b_g <- stats::rnorm(n_g, sd = exp(alpha_g[[1L]] + alpha_g[[2L]] * zg))
  b_h <- stats::rnorm(n_h, sd = exp(alpha_h[[1L]] + alpha_h[[2L]] * zh))
  mu <- exp(0.2 + 0.3 * dat$x + b_g[as.integer(dat$g)] + b_h[as.integer(dat$h)])
  # Gamma with coefficient of variation sigma: shape 1 / sigma^2, mean mu.
  dat$y <- stats::rgamma(nrow(dat), shape = 1 / sigma^2, scale = mu * sigma^2)
  list(data = dat, alpha_g = alpha_g, alpha_h = alpha_h, zg = zg, zh = zh,
       sigma = sigma)
}

gamma_crossed_oracle <- function(data, beta, alpha_g, alpha_h, zg, zh, shape) {
  Z <- cbind(stats::model.matrix(~ 0 + g, data),
             stats::model.matrix(~ 0 + h, data))
  tau <- c(exp(alpha_g[[1L]] + alpha_g[[2L]] * zg),
           exp(alpha_h[[1L]] + alpha_h[[2L]] * zh))
  gamma_additive_laplace(
    data$y, beta[[1L]] + beta[[2L]] * data$x, Z, tau, shape
  )
}

test_that("Gamma crossed intercepts assemble separate group SD rows", {
  fx <- gamma_crossed_fixture(n_g = 12L, n_h = 10L, reps = 2L)
  spec <- drm_build_gamma_ls_spec(
    bf(y ~ x + (1 | g) + (1 | h), sigma ~ 1, sd(g) ~ w, sd(h) ~ v), fx$data
  )
  expect_identical(spec$model_type, "gamma")
  expect_named(spec$random_scale$mu$X_list, c("sd(g)", "sd(h)"))
  expect_equal(unname(spec$random_scale$mu$X_list[["sd(g)"]][, "w"]), fx$zg[1:12])
  expect_equal(unname(spec$random_scale$mu$X_list[["sd(h)"]][, "v"]), fx$zh[1:10])
  expect_identical(spec$random_scale$mu$re_sd_row0, seq_len(22L) - 1L)
})

test_that("Gamma crossed SD targets that are duplicated or unmatched stay refused", {
  fx <- gamma_crossed_fixture(n_g = 12L, n_h = 10L, reps = 2L)
  expect_error(
    drm_build_gamma_ls_spec(
      bf(y ~ x + (1 | g) + (1 | h), sigma ~ 1, sd(g) ~ w, sd(k) ~ v), fx$data
    ),
    "sd|group|random"
  )
  expect_error(
    drm_build_gamma_ls_spec(
      bf(y ~ x + (1 | g) + (1 | h), sigma ~ 1, sd(g) ~ w, sd(g) ~ w), fx$data
    ),
    "sd|duplicate|once|multiple"
  )
})

test_that("Gamma crossed intercepts take separate SD formulas with an exact oracle", {
  skip_on_cran()
  fx <- gamma_crossed_fixture()
  fit <- drmTMB(
    bf(y ~ x + (1 | g) + (1 | h), sigma ~ 1, sd(g) ~ w, sd(h) ~ v),
    family = Gamma(link = "log"), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd(g)"), c("(Intercept)", "w"))
  expect_named(coef(fit, "sd(h)"), c("(Intercept)", "v"))
  expect_gt(coef(fit, "sd(g)")[["w"]], 0)
  expect_lt(coef(fit, "sd(h)")[["v"]], 0)
  expect_lt(abs(coef(fit, "sd(g)")[["w"]] - fx$alpha_g[["w"]]), 0.6)
  expect_lt(abs(coef(fit, "sd(h)")[["v"]] - fx$alpha_h[["v"]]), 0.6)
  expect_equal(
    unname(predict(fit, dpar = "sd(g)")),
    unname(exp(coef(fit, "sd(g)")[[1L]] + coef(fit, "sd(g)")[[2L]] * fx$zg)),
    tolerance = 1e-7
  )
  expect_equal(
    unname(predict(fit, dpar = "sd(h)")),
    unname(exp(coef(fit, "sd(h)")[[1L]] + coef(fit, "sd(h)")[[2L]] * fx$zh)),
    tolerance = 1e-7
  )

  beta <- unname(coef(fit, "mu"))
  ag <- unname(coef(fit, "sd(g)"))
  ah <- unname(coef(fit, "sd(h)"))
  shape <- exp(-2 * unname(coef(fit, "sigma"))[[1L]])
  oracle <- gamma_crossed_oracle(fx$data, beta, ag, ah, fx$zg, fx$zh, shape)
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-6)
  # Sensitivity: attaching the SD formulas to the wrong levels changes the value.
  swapped <- gamma_crossed_oracle(fx$data, beta, ag, ah,
                                  rev(fx$zg), rev(fx$zh), shape)
  expect_gt(abs(swapped - oracle), 0.1)

  # Constant-SD limit equals the existing crossed fit.
  constant_fit <- drmTMB(
    bf(y ~ x + (1 | g) + (1 | h), sigma ~ 1, sd(g) ~ 1, sd(h) ~ 1),
    family = Gamma(link = "log"), data = fx$data,
    control = drm_control(se = FALSE)
  )
  base_fit <- drmTMB(
    bf(y ~ x + (1 | g) + (1 | h), sigma ~ 1),
    family = Gamma(link = "log"), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_lt(abs(as.numeric(logLik(constant_fit)) -
                as.numeric(logLik(base_fit))), 1e-4)
  expect_equal(coef(constant_fit, "mu"), coef(base_fit, "mu"), tolerance = 1e-3)
  expect_equal(coef(constant_fit, "sigma"), coef(base_fit, "sigma"),
               tolerance = 1e-3)
})
