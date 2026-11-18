# Native Gamma(link = "log") ordinary plus related-matrix mu intercepts with a
# separate predictor-dependent SD for each field:
#   y ~ x + (1 | g) + relmat(1 | p, K = K),
#   sd(g) ~ zg,  sd(p, level = "relmat") ~ zp,  sigma ~ 1.
#
# Exact oracle: Laplace marginal of
#   y_i | b ~ Gamma(shape = k, mean = exp(eta_i + Z_i b)),  k = 1 / sigma^2,
#   b ~ N(0, blockdiag(diag(tau_g^2), D K D)),  D = diag(tau_p),
# i.e.  joint(b*) + (q/2) log(2 pi) - 0.5 log det(H),  with
#   H = k Z' diag(y / mu*) Z + Sigma^-1  (observed information)
# and b* found by Newton's method. The oracle uses the fitted coefficients, so
# it checks the likelihood assembly (which SD multiplies which latent block and
# how K is aligned to the factor levels), not the optimiser.
# Tolerances were fixed before the first run and are not tuned to pass:
#   oracle logLik: absolute 1e-5 (relative 1e-6 of |logLik| ~ 800 is 8e-4, so
#   the absolute bound is the stricter one); K versus Q and SD-order
#   invariance: logLik 1e-5; constant-SD limit: logLik 1e-4, mu/sigma
#   coefficients 1e-3; predict() identity: relative 1e-7; truth recovery:
#   absolute 0.6 on each SD slope (20 to 24 levels per field).

gamma_iid_relmat_laplace <- function(y, eta, Z, Sigma, shape) {
  q <- ncol(Z)
  Sinv <- solve(Sigma)
  logdet_S <- as.numeric(determinant(Sigma, logarithm = TRUE)$modulus)
  b <- rep(0, q)
  joint <- function(b) {
    lin <- eta + as.vector(Z %*% b)
    sum(shape * (log(shape) - lin) + (shape - 1) * log(y) -
          shape * y * exp(-lin) - lgamma(shape)) -
      0.5 * sum(b * (Sinv %*% b)) - 0.5 * logdet_S - 0.5 * q * log(2 * pi)
  }
  grad_fun <- function(b) {
    mu <- exp(eta + as.vector(Z %*% b))
    shape * as.vector(crossprod(Z, y / mu - 1)) - as.vector(Sinv %*% b)
  }
  for (iter in seq_len(200L)) {
    mu <- exp(eta + as.vector(Z %*% b))
    grad <- grad_fun(b)
    H <- shape * crossprod(Z, (y / mu) * Z) + Sinv
    step <- as.vector(solve(H, grad))
    scale <- 1
    while (joint(b + scale * step) < joint(b) - 1e-12 && scale > 1e-8) {
      scale <- scale / 2
    }
    b <- b + scale * step
    if (max(abs(grad)) < 1e-10) break
  }
  mu <- exp(eta + as.vector(Z %*% b))
  H <- shape * crossprod(Z, (y / mu) * Z) + Sinv
  stopifnot(max(abs(grad_fun(b))) < 1e-8)
  joint(b) + 0.5 * q * log(2 * pi) -
    0.5 * as.numeric(determinant(H, logarithm = TRUE)$modulus)
}

gamma_iid_relmat_fixture <- function(seed = 2026110401L, n_g = 24L, n_p = 20L,
                                     reps = 2L, shape = 6L) {
  set.seed(seed)
  g_levels <- sprintf("g%02d", seq_len(n_g))
  p_levels <- sprintf("p%02d", seq_len(n_p))
  # The kernel is stored in a shuffled (odd levels, then even levels) order and
  # the AR structure follows the original level index, so the stored matrix is
  # not Toeplitz and a positional (rather than name-based) alignment of K to the
  # factor levels would be wrong.
  kernel_order <- c(seq(1L, n_p, by = 2L), seq(2L, n_p, by = 2L))
  K <- outer(kernel_order, kernel_order, function(i, j) 0.5^abs(i - j))
  dimnames(K) <- list(p_levels[kernel_order], p_levels[kernel_order])
  zg <- stats::setNames(seq(-1, 1, length.out = n_g), g_levels)
  zp <- stats::setNames(seq(-1, 1, length.out = n_p), p_levels)
  alpha_g <- c(`(Intercept)` = log(0.5), zg = 0.4)
  alpha_p <- c(`(Intercept)` = log(0.45), zp = -0.3)
  b_g <- stats::setNames(
    stats::rnorm(n_g, sd = exp(alpha_g[[1L]] + alpha_g[[2L]] * zg)), g_levels
  )
  field <- as.vector(t(chol(K)) %*% stats::rnorm(n_p))
  names(field) <- p_levels[kernel_order]
  b_p <- (field * exp(alpha_p[[1L]] + alpha_p[[2L]] * zp[names(field)]))[p_levels]
  design <- expand.grid(rep = seq_len(reps), gi = seq_len(n_g), pi = seq_len(n_p))
  dat <- data.frame(
    x = stats::rnorm(nrow(design)),
    g = factor(g_levels[design$gi], levels = g_levels),
    p = factor(p_levels[design$pi], levels = p_levels)
  )
  dat$zg <- unname(zg[as.character(dat$g)])
  dat$zp <- unname(zp[as.character(dat$p)])
  mu <- exp(0.2 + 0.3 * dat$x + b_g[as.character(dat$g)] +
              b_p[as.character(dat$p)])
  dat$y <- stats::rgamma(nrow(dat), shape = shape, scale = mu / shape)
  list(data = dat, K = K, zg = zg, zp = zp, alpha_g = alpha_g,
       alpha_p = alpha_p, g_levels = g_levels, p_levels = p_levels)
}

gamma_iid_relmat_fit <- function(fx, input = c("K", "Q"), sd_g = ~zg,
                                 sd_p = ~zp, relmat_first = FALSE) {
  input <- match.arg(input)
  K <- fx$K
  Q <- solve(fx$K)
  rhs <- if (identical(input, "K")) {
    quote(relmat(1 | p, K = K))
  } else {
    quote(relmat(1 | p, Q = Q))
  }
  mean_formula <- if (relmat_first) {
    bquote(y ~ x + .(rhs) + (1 | g))
  } else {
    bquote(y ~ x + (1 | g) + .(rhs))
  }
  formula <- do.call(bf, list(
    mean_formula, sigma ~ 1,
    stats::as.formula(call("~", quote(sd(g)), sd_g[[2L]]), env = environment()),
    stats::as.formula(
      call("~", quote(sd(p, level = "relmat")), sd_p[[2L]]),
      env = environment()
    )
  ))
  drmTMB(formula, family = Gamma(link = "log"), data = fx$data,
         control = drm_control(se = FALSE))
}

gamma_iid_relmat_oracle <- function(fit, fx, zg = fx$zg, zp = fx$zp) {
  dat <- fx$data
  beta <- unname(coef(fit, "mu"))
  ag <- unname(coef(fit, "sd(g)"))
  ap <- unname(coef(fit, "sd_relmat(p)"))
  shape <- exp(-2 * unname(coef(fit, "sigma"))[[1L]])
  Zg <- stats::model.matrix(~ 0 + g, dat)
  Zp <- stats::model.matrix(~ 0 + p, dat)
  tau_g <- exp(ag[[1L]] + ag[[2L]] * zg[fx$g_levels])
  tau_p <- exp(ap[[1L]] + ap[[2L]] * zp[fx$p_levels])
  Kp <- fx$K[fx$p_levels, fx$p_levels]
  Sigma <- matrix(0, ncol(Zg) + ncol(Zp), ncol(Zg) + ncol(Zp))
  ig <- seq_len(ncol(Zg))
  ip <- ncol(Zg) + seq_len(ncol(Zp))
  Sigma[ig, ig] <- diag(tau_g^2, length(ig))
  Sigma[ip, ip] <- outer(tau_p, tau_p) * Kp
  gamma_iid_relmat_laplace(
    dat$y, beta[[1L]] + beta[[2L]] * dat$x, cbind(Zg, Zp), Sigma, shape
  )
}

test_that("Gamma ordinary plus relmat intercepts assemble separate SD rows", {
  fx <- gamma_iid_relmat_fixture()
  K <- fx$K
  spec <- drm_build_gamma_ls_spec(
    bf(y ~ x + (1 | g) + relmat(1 | p, K = K), sigma ~ 1,
       sd(g) ~ zg, sd(p, level = "relmat") ~ zp),
    fx$data
  )
  expect_identical(spec$model_type, "gamma")
  expect_true("sd(g)" %in% names(spec$random_scale$mu$X_list))
  expect_equal(
    unname(spec$random_scale$mu$X_list[["sd(g)"]][, "zg"]),
    unname(fx$zg)
  )
})

test_that("Gamma ordinary plus relmat SD targets that are duplicated or unmatched stay refused", {
  fx <- gamma_iid_relmat_fixture()
  K <- fx$K
  expect_error(
    drm_build_gamma_ls_spec(
      bf(y ~ x + (1 | g) + relmat(1 | p, K = K), sigma ~ 1,
         sd(g) ~ zg, sd(k, level = "relmat") ~ zp),
      fx$data
    ),
    "sd|group|random|match"
  )
  expect_error(
    drm_build_gamma_ls_spec(
      bf(y ~ x + (1 | g) + relmat(1 | p, K = K), sigma ~ 1,
         sd(g) ~ zg, sd(p, level = "relmat") ~ zp, sd(g) ~ zg),
      fx$data
    ),
    "sd|SD|duplicate|once|multiple"
  )
})

test_that("Gamma ordinary plus relmat SDs match a dense Laplace oracle", {
  skip_on_cran()
  fx <- gamma_iid_relmat_fixture()
  fit <- gamma_iid_relmat_fit(fx, "K")
  expect_equal(fit$opt$convergence, 0L)
  expect_named(fit$sdpars, c("sd(g)", "sd_relmat(p)"))
  expect_named(coef(fit, "sd(g)"), c("(Intercept)", "zg"))
  expect_named(coef(fit, "sd_relmat(p)"), c("(Intercept)", "zp"))
  expect_lt(abs(coef(fit, "sd(g)")[["zg"]] - fx$alpha_g[["zg"]]), 0.6)
  expect_lt(abs(coef(fit, "sd_relmat(p)")[["zp"]] - fx$alpha_p[["zp"]]), 0.6)

  # Name-aligned prediction of each field's SD.
  pg <- predict(fit, dpar = "sd(g)")
  pp <- predict(fit, dpar = "sd_relmat(p)")
  expect_setequal(names(pg), fx$g_levels)
  expect_setequal(names(pp), fx$p_levels)
  ag <- coef(fit, "sd(g)")
  ap <- coef(fit, "sd_relmat(p)")
  expect_equal(unname(pg), unname(exp(ag[[1L]] + ag[[2L]] * fx$zg[names(pg)])),
               tolerance = 1e-7)
  expect_equal(unname(pp), unname(exp(ap[[1L]] + ap[[2L]] * fx$zp[names(pp)])),
               tolerance = 1e-7)

  oracle <- gamma_iid_relmat_oracle(fit, fx)
  expect_equal(as.numeric(logLik(fit)), oracle, tolerance = 1e-5)
  # Sensitivity: attaching either SD formula to the wrong levels, or aligning
  # K by position rather than name, changes the oracle value.
  expect_gt(abs(gamma_iid_relmat_oracle(fit, fx, zg = stats::setNames(rev(unname(fx$zg)), names(fx$zg))) - oracle), 0.1)
  expect_gt(abs(gamma_iid_relmat_oracle(fit, fx, zp = stats::setNames(rev(unname(fx$zp)), names(fx$zp))) - oracle), 0.1)
  positional <- fx
  positional$K <- fx$K
  dimnames(positional$K) <- list(fx$p_levels, fx$p_levels)
  expect_gt(abs(gamma_iid_relmat_oracle(fit, positional) - oracle), 0.1)
})

test_that("Gamma ordinary plus relmat SD fits agree for K, Q and term order", {
  skip_on_cran()
  fx <- gamma_iid_relmat_fixture()
  fit_k <- gamma_iid_relmat_fit(fx, "K")
  fit_q <- gamma_iid_relmat_fit(fx, "Q")
  fit_rev <- gamma_iid_relmat_fit(fx, "K", relmat_first = TRUE)
  for (other in list(fit_q, fit_rev)) {
    expect_equal(other$opt$convergence, 0L)
    expect_equal(as.numeric(logLik(other)), as.numeric(logLik(fit_k)),
                 tolerance = 1e-5)
  }
  expect_equal(coef(fit_q, "sd(g)"), coef(fit_k, "sd(g)"), tolerance = 1e-3)
  expect_equal(coef(fit_q, "sd_relmat(p)"), coef(fit_k, "sd_relmat(p)"),
               tolerance = 1e-3)
})

test_that("Gamma ordinary plus relmat constant-SD limit equals the plain additive fit", {
  skip_on_cran()
  fx <- gamma_iid_relmat_fixture()
  K <- fx$K
  constant_fit <- gamma_iid_relmat_fit(fx, "K", sd_g = ~1, sd_p = ~1)
  base_fit <- drmTMB(
    bf(y ~ x + (1 | g) + relmat(1 | p, K = K), sigma ~ 1),
    family = Gamma(link = "log"), data = fx$data,
    control = drm_control(se = FALSE)
  )
  expect_equal(constant_fit$opt$convergence, 0L)
  expect_equal(base_fit$opt$convergence, 0L)
  expect_lt(abs(as.numeric(logLik(constant_fit)) -
                as.numeric(logLik(base_fit))), 1e-4)
  expect_equal(coef(constant_fit, "mu"), coef(base_fit, "mu"), tolerance = 1e-3)
  expect_equal(coef(constant_fit, "sigma"), coef(base_fit, "sigma"),
               tolerance = 1e-3)
})
