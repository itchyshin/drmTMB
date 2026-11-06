# Quick wins, batch 13: Gaussian crossed ordinary intercepts with SD formulas.
#
#   y ~ x + (1 | g) + (1 | h),  sd(g) ~ w,  sd(h) ~ v
#
# Model: y = X beta + Zg b_g + Zh b_h + e, e ~ N(0, sigma^2 I),
# b_g ~ N(0, diag(tau_g^2)), b_h ~ N(0, diag(tau_h^2)),
# tau_g = exp(a_g0 + a_g1 w), tau_h = exp(a_h0 + a_h1 v).
# Gaussian y has an exact marginal likelihood, so the oracle is the dense
# multivariate-normal density with V = Zg diag(tau_g^2) Zg' + Zh diag(tau_h^2)
# Zh' + sigma^2 I, evaluated in plain R at the fitted (beta, sigma, SD vectors).
# It never touches the TMB template or the Laplace path. Levels are shuffled so
# factor-level order differs from name order; SD vectors are matched by name.
# Ordinary intercepts have an identity correlation matrix, so the structured
# (non-unit-diagonal K) requirement does not apply here.
#
# NB2 ordinary (1 | site) beside animal / phylo / relmat intercepts with SD
# formulas on both terms is NOT re-tested here: test-nbinom2-batch5-sd-
# regression.R already covers relmat K and Q, animal A and Ainv, and phylo
# (lines 311-354), plus the crossed NB2 case with a dense Laplace oracle.
#
# Tolerances, fixed before the first run and never loosened:
#   oracle logLik (relative)                          1e-6
#   independent dense optimiser maximum (relative)    1e-5
#   constant-SD equivalence, logLik (relative)        2e-5
#   formula-order invariance, logLik (relative)       1e-6
#   predict() vs coefficients                         1e-10
#   emulated-bug sensitivity: oracle moves by > 1e-2 in logLik
#   SD-slope recovery: right sign and within 0.8 of truth
#
# Not covered: se = TRUE inference, simulate(), coverage claims, structured
# providers, and the Julia engine.

cq_alpha_g <- c(`(Intercept)` = log(0.6), w = 0.7)
cq_alpha_h <- c(`(Intercept)` = log(0.5), v = -0.6)

cq_fixture <- function(seed = 20261101L, ng = 40L, nh = 36L, n = 900L) {
  set.seed(seed)
  levels_g <- paste0("g", sample(ng))
  levels_h <- paste0("h", sample(nh))
  w <- stats::setNames(seq(-1, 1, length.out = ng)[sample(ng)], levels_g)
  v <- stats::setNames(seq(-1, 1, length.out = nh)[sample(nh)], levels_h)
  tau_g <- exp(cq_alpha_g[[1L]] + cq_alpha_g[[2L]] * w)
  tau_h <- exp(cq_alpha_h[[1L]] + cq_alpha_h[[2L]] * v)
  b_g <- stats::rnorm(ng, sd = tau_g)
  names(b_g) <- levels_g
  b_h <- stats::rnorm(nh, sd = tau_h)
  names(b_h) <- levels_h
  g_chr <- levels_g[sample.int(ng, n, replace = TRUE)]
  h_chr <- levels_h[sample.int(nh, n, replace = TRUE)]
  x <- stats::rnorm(n)
  dat <- data.frame(
    g = factor(g_chr, levels = levels_g),
    h = factor(h_chr, levels = levels_h),
    x = x,
    w = unname(w[g_chr]),
    v = unname(v[h_chr])
  )
  dat$y <- 0.3 + 0.5 * x + b_g[g_chr] + b_h[h_chr] + stats::rnorm(n, sd = 0.7)
  list(data = dat, w = w, v = v, levels_g = levels_g, levels_h = levels_h)
}

cq_Z <- function(group, levels_) {
  idx <- match(as.character(group), levels_)
  stopifnot(!anyNA(idx))
  Z <- matrix(0, length(idx), length(levels_))
  Z[cbind(seq_along(idx), idx)] <- 1
  Z
}

cq_dense_nll <- function(y, X, beta, sigma, Zg, tau_g, Zh, tau_h) {
  V <- diag(sigma^2, length(y)) +
    Zg %*% (tau_g^2 * t(Zg)) + Zh %*% (tau_h^2 * t(Zh))
  R <- chol(V)
  r <- backsolve(R, y - as.vector(X %*% beta), transpose = TRUE)
  0.5 * (length(y) * log(2 * pi) + 2 * sum(log(diag(R))) + sum(r^2))
}

cq_fit <- function(fx, sd_g = "w", sd_h = "v", swap_order = FALSE) {
  parts <- c(
    if (swap_order) "y ~ x + (1 | h) + (1 | g)" else "y ~ x + (1 | g) + (1 | h)",
    if (!is.null(sd_g)) sprintf("sd(g) ~ %s", sd_g),
    if (!is.null(sd_h)) sprintf("sd(h) ~ %s", sd_h)
  )
  if (swap_order) parts <- parts[c(1L, rev(seq_along(parts)[-1L]))]
  drmTMB(
    eval(parse(text = sprintf("bf(%s)", paste(parts, collapse = ", ")))),
    family = stats::gaussian(), data = fx$data,
    control = drm_control(se = FALSE)
  )
}

test_that("Gaussian crossed ordinary intercepts take separate SD formulas and match the exact oracle", {
  skip_on_cran()
  fx <- cq_fixture()
  dat <- fx$data
  fit <- cq_fit(fx)
  expect_equal(fit$opt$convergence, 0L)
  expect_setequal(names(coef(fit)), c("mu", "sigma", "sd(g)", "sd(h)"))
  expect_named(coef(fit, "sd(g)"), c("(Intercept)", "w"))
  expect_named(coef(fit, "sd(h)"), c("(Intercept)", "v"))

  # Predictions are keyed by level name and equal exp(X alpha).
  a_g <- coef(fit, "sd(g)")
  a_h <- coef(fit, "sd(h)")
  p_g <- predict(fit, dpar = "sd(g)")
  p_h <- predict(fit, dpar = "sd(h)")
  expect_setequal(names(p_g), fx$levels_g)
  expect_setequal(names(p_h), fx$levels_h)
  expect_equal(
    unname(p_g[fx$levels_g]),
    unname(exp(a_g[[1L]] + a_g[[2L]] * fx$w[fx$levels_g])),
    tolerance = 1e-10
  )
  expect_equal(
    unname(p_h[fx$levels_h]),
    unname(exp(a_h[[1L]] + a_h[[2L]] * fx$v[fx$levels_h])),
    tolerance = 1e-10
  )

  # Signed recovery of both SD slopes (opposite signs, so a swap is visible).
  expect_gt(a_g[["w"]], 0)
  expect_lt(a_h[["v"]], 0)
  expect_lt(abs(a_g[["w"]] - cq_alpha_g[["w"]]), 0.8)
  expect_lt(abs(a_h[["v"]] - cq_alpha_h[["v"]]), 0.8)

  # Exact marginal oracle at the fitted parameters.
  X <- stats::model.matrix(~x, dat)
  beta <- unname(coef(fit, "mu")[c("(Intercept)", "x")])
  sigma_hat <- unname(stats::sigma(fit))
  Zg <- cq_Z(dat$g, fx$levels_g)
  Zh <- cq_Z(dat$h, fx$levels_h)
  tau_g <- unname(p_g[fx$levels_g])
  tau_h <- unname(p_h[fx$levels_h])
  nll <- cq_dense_nll(dat$y, X, beta, sigma_hat, Zg, tau_g, Zh, tau_h)
  expect_equal(as.numeric(logLik(fit)), -nll, tolerance = 1e-6)

  # Emulated bugs: each must move the oracle.
  bug <- function(tg, th) {
    abs(cq_dense_nll(dat$y, X, beta, sigma_hat, Zg, tg, Zh, th) - nll)
  }
  expect_gt(bug(rev(tau_g), tau_h), 1e-2)        # position instead of name
  expect_gt(bug(tau_g, rev(tau_h)), 1e-2)
  expect_gt(
    bug(
      exp(a_g[[1L]] - a_g[[2L]] * fx$w[fx$levels_g]), tau_h
    ), 1e-2                                       # sign-flipped slope
  )
  expect_gt(
    bug(rep(mean(tau_g), length(tau_g)), tau_h), 1e-2  # SD formula ignored
  )
  expect_gt(
    bug(rep(tau_h[[1L]], length(tau_g)), rep(tau_g[[1L]], length(tau_h))),
    1e-2                                          # SD of the wrong term
  )

  # Independent dense optimiser reaches the same maximum.
  z_g <- fx$w[fx$levels_g]
  z_h <- fx$v[fx$levels_h]
  obj <- function(par) {
    cq_dense_nll(
      dat$y, X, par[1:2], exp(par[[3L]]),
      Zg, exp(par[[4L]] + par[[5L]] * z_g),
      Zh, exp(par[[6L]] + par[[7L]] * z_h)
    )
  }
  start <- c(unname(stats::coef(stats::lm(y ~ x, dat))), log(0.5),
             log(0.4), 0, log(0.4), 0)
  opt <- stats::optim(
    start, obj, method = "L-BFGS-B",
    lower = c(-Inf, -Inf, -5, -5, -3, -5, -3),
    upper = c(Inf, Inf, 2, 2, 3, 2, 3),
    control = list(maxit = 500L, factr = 1e3)
  )
  expect_equal(opt$convergence, 0L)
  expect_equal(as.numeric(logLik(fit)), -opt$value, tolerance = 1e-5)

  # Constant-SD limit equals the base model with no sd() formulas; nested.
  base_fit <- cq_fit(fx, sd_g = NULL, sd_h = NULL)
  const_fit <- cq_fit(fx, sd_g = "1", sd_h = "1")
  expect_equal(base_fit$opt$convergence, 0L)
  expect_equal(const_fit$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(const_fit)), as.numeric(logLik(base_fit)),
    tolerance = 2e-5
  )
  expect_lte(as.numeric(logLik(const_fit)), as.numeric(logLik(fit)) + 1e-6)

  # One SD formula only: the other term keeps a constant SD.
  g_only <- cq_fit(fx, sd_h = NULL)
  expect_equal(g_only$opt$convergence, 0L)
  expect_setequal(names(coef(g_only)), c("mu", "sigma", "sd(g)"))
  expect_lte(as.numeric(logLik(g_only)), as.numeric(logLik(fit)) + 1e-6)
  expect_gte(as.numeric(logLik(g_only)), as.numeric(logLik(base_fit)) - 1e-6)
})

test_that("Gaussian crossed SD fits do not depend on term or sd() order", {
  skip_on_cran()
  fx <- cq_fixture()
  ref <- cq_fit(fx)
  alt <- cq_fit(fx, swap_order = TRUE)
  expect_equal(alt$opt$convergence, 0L)
  expect_equal(
    as.numeric(logLik(alt)), as.numeric(logLik(ref)), tolerance = 1e-6
  )
  expect_equal(
    unname(coef(alt, "sd(g)")), unname(coef(ref, "sd(g)")), tolerance = 1e-3
  )
  expect_equal(
    unname(coef(alt, "sd(h)")), unname(coef(ref, "sd(h)")), tolerance = 1e-3
  )
})

test_that("Gaussian crossed SD refusals are designed errors", {
  skip_on_cran()
  fx <- cq_fixture(n = 300L)
  dat <- fx$data
  dat$wr <- stats::rnorm(nrow(dat))
  fit_with <- function(...) {
    drmTMB(
      bf(y ~ x + (1 | g) + (1 | h), ...),
      family = stats::gaussian(), data = dat,
      control = drm_control(se = FALSE)
    )
  }
  expect_error(
    fit_with(sd(g) ~ w, sd(g) ~ v),
    "Duplicate random-effect scale formula `sd\\(g\\)`"
  )
  expect_error(
    fit_with(sd(g, level = "phylogenetic") ~ w),
    "No structured location random-effect term matches `sd_phylo\\(g\\)`"
  )
  expect_error(
    fit_with(sd(g) ~ wr),
    "Predictor wr varies within g level"
  )
  expect_error(
    fit_with(sd(k) ~ w),
    "Could not find every variable from the formula"
  )
})
