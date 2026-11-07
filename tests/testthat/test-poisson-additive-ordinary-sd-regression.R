# Native Poisson additive ordinary terms with separate predictor-dependent SDs:
#   (1 | g) + (0 + x | g)  with coefficient-selected SDs, and
#   (1 | g) + (1 | h)      with sd(g) and sd(h).
#
# Exact oracle: Laplace marginal of
#   y_i | b ~ Poisson(exp(eta_i + Z_i b)),  b ~ N(0, diag(tau^2)),
# which is  joint(b*) + (q/2) log(2 pi) - 0.5 log det(Z' diag(mu*) Z + diag(1/tau^2)),
# with b* found by Newton's method. It uses the fitted coefficients, so it checks
# the likelihood assembly (which SD multiplies which latent coefficient), not
# the optimiser. Tolerances are fixed before the first run:
#   oracle logLik: relative 1e-6; constant-SD limit: absolute 1e-4 on logLik.

poisson_additive_laplace <- function(y, eta, Z, tau) {
  q <- ncol(Z)
  b <- rep(0, q)
  joint <- function(b) {
    lin <- eta + as.vector(Z %*% b)
    sum(y * lin - exp(lin) - lgamma(y + 1)) -
      0.5 * sum(b^2 / tau^2) - sum(log(tau)) - 0.5 * q * log(2 * pi)
  }
  for (iter in seq_len(200L)) {
    mu <- exp(eta + as.vector(Z %*% b))
    grad <- as.vector(crossprod(Z, y - mu)) - b / tau^2
    H <- crossprod(Z, mu * Z) + diag(1 / tau^2, q)
    step <- as.vector(solve(H, grad))
    scale <- 1
    while (joint(b + scale * step) < joint(b) - 1e-12 && scale > 1e-8) {
      scale <- scale / 2
    }
    b <- b + scale * step
    if (max(abs(grad)) < 1e-10) break
  }
  mu <- exp(eta + as.vector(Z %*% b))
  H <- crossprod(Z, mu * Z) + diag(1 / tau^2, q)
  stopifnot(max(abs(as.vector(crossprod(Z, y - mu)) - b / tau^2)) < 1e-8)
  joint(b) + 0.5 * q * log(2 * pi) -
    0.5 * as.numeric(determinant(H, logarithm = TRUE)$modulus)
}

poisson_same_group_fixture <- function(seed = 2026110141L, n_id = 60L,
                                        n_each = 10L) {
  set.seed(seed)
  id <- factor(rep(sprintf("id%02d", seq_len(n_id)), each = n_each))
  x <- rep(seq(-1.2, 1.2, length.out = n_each), times = n_id)
  w0 <- rep(c(-0.5, 0.5), length.out = n_id)
  w1 <- rep(c(-0.5, 0.5), each = n_id %/% 2L)
  alpha0 <- c(`(Intercept)` = log(0.5), w0 = 0.4)
  alpha1 <- c(`(Intercept)` = log(0.4), w1 = -0.5)
  b0 <- stats::rnorm(n_id, sd = exp(alpha0[[1L]] + alpha0[[2L]] * w0))
  b1 <- stats::rnorm(n_id, sd = exp(alpha1[[1L]] + alpha1[[2L]] * w1))
  gi <- as.integer(id)
  y <- stats::rpois(n_id * n_each,
                    exp(0.2 + 0.3 * x + b0[gi] + b1[gi] * x))
  list(data = data.frame(y = y, x = x, id = id, w0 = w0[gi], w1 = w1[gi]),
       alpha0 = alpha0, alpha1 = alpha1)
}

poisson_same_group_oracle <- function(data, beta, alpha0, alpha1) {
  sum(vapply(split(seq_len(nrow(data)), data$id), function(i) {
    tau <- c(exp(alpha0[[1L]] + alpha0[[2L]] * data$w0[i[[1L]]]),
             exp(alpha1[[1L]] + alpha1[[2L]] * data$w1[i[[1L]]]))
    poisson_additive_laplace(data$y[i], beta[[1L]] + beta[[2L]] * data$x[i],
                             cbind(1, data$x[i]), tau)
  }, numeric(1L)))
}

poisson_crossed_fixture <- function(seed = 2026110142L, n_g = 30L, n_h = 24L,
                                     reps = 3L) {
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
  dat$y <- stats::rpois(nrow(dat),
    exp(0.2 + 0.3 * dat$x + b_g[as.integer(dat$g)] + b_h[as.integer(dat$h)]))
  list(data = dat, alpha_g = alpha_g, alpha_h = alpha_h, zg = zg, zh = zh)
}

poisson_crossed_oracle <- function(data, beta, alpha_g, alpha_h, zg, zh) {
  Z <- cbind(stats::model.matrix(~ 0 + g, data), stats::model.matrix(~ 0 + h, data))
  tau <- c(exp(alpha_g[[1L]] + alpha_g[[2L]] * zg),
           exp(alpha_h[[1L]] + alpha_h[[2L]] * zh))
  poisson_additive_laplace(data$y, beta[[1L]] + beta[[2L]] * data$x, Z, tau)
}

test_that("Poisson same-group intercept and slope assemble separate coefficient SD rows", {
  fx <- poisson_same_group_fixture()
  spec <- drm_build_poisson_spec(bf(
    y ~ x + (1 | id) + (0 + x | id),
    sd(id, coef = "(Intercept)") ~ w0,
    sd(id, coef = "x") ~ w1
  ), fx$data)
  key0 <- 'sd(id, coef = "(Intercept)")'
  key1 <- 'sd(id, coef = "x")'
  expect_named(spec$random_scale$mu$X_list, c(key0, key1))
  expect_identical(spec$random_scale$mu$target_identity[[key0]]$coef,
                   "(Intercept)")
  expect_identical(spec$random_scale$mu$target_identity[[key1]]$coef, "x")
  expect_equal(unname(spec$random_scale$mu$X_list[[key0]][, "w0"]),
               as.numeric(tapply(fx$data$w0, fx$data$id, `[`, 1L)))
  expect_equal(unname(spec$random_scale$mu$X_list[[key1]][, "w1"]),
               as.numeric(tapply(fx$data$w1, fx$data$id, `[`, 1L)))
  expect_identical(spec$random_scale$mu$re_sd_row0,
                   seq_len(2L * nlevels(fx$data$id)) - 1L)
  expect_equal(unname(as.matrix(spec$tmb_data$mu_re_value)),
               cbind(1, fx$data$x), ignore_attr = TRUE)
  expect_identical(spec$random$mu$n_cors, 0L)
})

test_that("Poisson same-group SD without coefficient selectors stays refused", {
  fx <- poisson_same_group_fixture(n_id = 20L)
  expect_error(
    drm_build_poisson_spec(
      bf(y ~ x + (1 | id) + (0 + x | id), sd(id) ~ w0), fx$data
    ),
    "Ambiguous|coef"
  )
})

test_that("Poisson same-group intercept and slope take separate SD formulas", {
  skip_on_cran()
  fx <- poisson_same_group_fixture()
  key0 <- 'sd(id, coef = "(Intercept)")'
  key1 <- 'sd(id, coef = "x")'
  fit <- drmTMB(
    bf(
      y ~ x + (1 | id) + (0 + x | id),
      sd(id, coef = "(Intercept)") ~ w0,
      sd(id, coef = "x") ~ w1
    ),
    family = poisson(), data = fx$data, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, key0), c("(Intercept)", "w0"))
  expect_named(coef(fit, key1), c("(Intercept)", "w1"))
  expect_gt(coef(fit, key0)[["w0"]], 0)
  expect_lt(coef(fit, key1)[["w1"]], 0)
  expect_lt(abs(coef(fit, key0)[["w0"]] - fx$alpha0[["w0"]]), 0.6)
  expect_lt(abs(coef(fit, key1)[["w1"]] - fx$alpha1[["w1"]]), 0.6)

  beta <- unname(coef(fit, "mu"))
  a0 <- unname(coef(fit, key0))
  a1 <- unname(coef(fit, key1))
  oracle <- poisson_same_group_oracle(fx$data, beta, a0, a1)
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-6)
  # The oracle must be sensitive to which covariate drives which coefficient.
  swapped <- poisson_same_group_oracle(fx$data, beta, a1, a0)
  expect_gt(abs(swapped - oracle), 0.1)

  # Constant-SD limit equals the existing two-term fit.
  constant_fit <- drmTMB(
    bf(y ~ x + (1 | id) + (0 + x | id),
       sd(id, coef = "(Intercept)") ~ 1, sd(id, coef = "x") ~ 1),
    family = poisson(), data = fx$data, control = drm_control(se = FALSE)
  )
  base_fit <- drmTMB(
    bf(y ~ x + (1 | id) + (0 + x | id)),
    family = poisson(), data = fx$data, control = drm_control(se = FALSE)
  )
  expect_lt(abs(as.numeric(logLik(constant_fit)) -
                as.numeric(logLik(base_fit))), 1e-4)
  expect_equal(coef(constant_fit, "mu"), coef(base_fit, "mu"), tolerance = 1e-3)
})

test_that("Poisson crossed intercepts take separate SD formulas with an exact oracle", {
  skip_on_cran()
  fx <- poisson_crossed_fixture()
  fit <- drmTMB(
    bf(y ~ x + (1 | g) + (1 | h), sd(g) ~ w, sd(h) ~ v),
    family = poisson(), data = fx$data, control = drm_control(se = FALSE)
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
  oracle <- poisson_crossed_oracle(fx$data, beta, ag, ah, fx$zg, fx$zh)
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-6)
  # Sensitivity: attaching the SD formulas to the wrong factor changes the value.
  swapped <- poisson_crossed_oracle(fx$data, beta, ag, ah,
                                    rev(fx$zg), rev(fx$zh))
  expect_gt(abs(swapped - oracle), 0.1)

  # Constant-SD limit equals the existing crossed fit.
  constant_fit <- drmTMB(
    bf(y ~ x + (1 | g) + (1 | h), sd(g) ~ 1, sd(h) ~ 1),
    family = poisson(), data = fx$data, control = drm_control(se = FALSE)
  )
  base_fit <- drmTMB(
    bf(y ~ x + (1 | g) + (1 | h)),
    family = poisson(), data = fx$data, control = drm_control(se = FALSE)
  )
  expect_lt(abs(as.numeric(logLik(constant_fit)) -
                as.numeric(logLik(base_fit))), 1e-4)
  expect_equal(coef(constant_fit, "mu"), coef(base_fit, "mu"), tolerance = 1e-3)
})
