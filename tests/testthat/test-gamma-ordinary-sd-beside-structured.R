# Native Gamma(link = "log"): an ordinary sd(g) ~ w formula ALONE (no structured
# SD formula) beside one structured mu intercept (animal, phylo, spatial or
# relmat), with an ordinary (1 | g) intercept:
#   y ~ x + (1 | g) + <provider>(1 | p, ...),  sigma ~ 1,  sd(g) ~ zg.
# The structured SD is then a single scalar. Previously refused as "one
# endpoint at a time"; the model_type 5 likelihood already carries both blocks.
#
# Oracle: dense, drmTMB-independent Laplace marginal (see
# test-gamma-iid-structured-sd-regression.R) with
#   b ~ N(0, blockdiag(diag(tau_g^2), s^2 K)),  s = exp(log_sd_phylo).
# K has a non-unit diagonal and is stored in a different level order from the
# data factors. Tolerances fixed before the first run and not loosened:
#   oracle logLik 1e-5 absolute; K versus Q and term-order invariance 1e-5;
#   constant-SD limit 1e-4 logLik and 1e-3 on mu, sigma and SD coefficients;
#   a nested model may not beat the larger one by more than 1e-3.
# Covered: scalar structured SD, one ordinary SD regression, native TMB, complete
# responses. Not covered: calibration, Julia, structured slopes, sigma-side SDs.

gob_laplace <- function(y, eta, Z, Sigma, shape) {
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

gob_providers <- list(
  animal_A = list(term = "animal(1 | p, A = A)", level = "animal",
                  dpar = "sd_animal(p)"),
  animal_Ainv = list(term = "animal(1 | p, Ainv = Ainv)", level = "animal",
                     dpar = "sd_animal(p)"),
  phylo = list(term = "phylo(1 | p, tree = tree)", level = "phylogenetic",
               dpar = "sd_phylo(p)"),
  spatial = list(term = "spatial(1 | p, coords = coords)", level = "spatial",
                 dpar = "sd_spatial(p)")
)

# Structured covariance stored in an order that differs from the factor-level
# order of the data, with a non-unit diagonal.
gob_make_K <- function(kind, n_p, p_levels) {
  tree <- NULL
  coords <- NULL
  if (identical(kind, "phylo")) {
    tree <- ape::rcoal(n_p)
    tree$tip.label <- sample(p_levels)
    K <- drmTMB:::drm_phylo_tip_covariance(tree)
  } else if (identical(kind, "spatial")) {
    theta <- seq(0, 2 * pi, length.out = n_p + 1L)[-1L]
    coords <- data.frame(x = cos(theta), y = sin(theta),
                         row.names = p_levels)
    coords <- coords[sample(p_levels), , drop = FALSE]
    precision <- drmTMB:::drm_spatial_coords_precision(
      coords, site = rownames(coords), group = "p"
    )
    K <- solve(as.matrix(precision$precision))
    dimnames(K) <- list(rownames(coords), rownames(coords))
  } else {
    base <- 1.6 * 0.45^abs(outer(seq_len(n_p), seq_len(n_p), `-`))
    dimnames(base) <- list(p_levels, p_levels)
    ord <- c(seq(1L, n_p, by = 2L), seq(2L, n_p, by = 2L))
    K <- base[ord, ord]
  }
  list(K = K, tree = tree, coords = coords)
}

gob_fixture <- function(kind, seed, n_g = 24L, n_p = 20L, reps = 2L,
                        shape = 6) {
  set.seed(seed)
  g_levels <- sprintf("g%02d", seq_len(n_g))
  p_levels <- sprintf("p%02d", seq_len(n_p))
  km <- gob_make_K(kind, n_p, p_levels)
  K <- km$K
  zg <- stats::setNames(seq(-1, 1, length.out = n_g)[sample.int(n_g)], g_levels)
  zp <- stats::setNames(seq(-1, 1, length.out = n_p)[sample.int(n_p)], p_levels)
  alpha_g <- c(`(Intercept)` = log(0.5), zg = 0.9)
  alpha_p <- c(`(Intercept)` = log(0.45), zp = -0.9)
  b_g <- stats::setNames(
    stats::rnorm(n_g, sd = exp(alpha_g[[1L]] + alpha_g[[2L]] * zg)), g_levels
  )
  field <- as.vector(t(chol(K)) %*% stats::rnorm(n_p))
  names(field) <- rownames(K)
  b_p <- (field * exp(alpha_p[[1L]]))[p_levels]
  design <- expand.grid(rep = seq_len(reps), gi = seq_len(n_g),
                        pi = seq_len(n_p))
  dat <- data.frame(
    x = stats::rnorm(nrow(design)),
    g = factor(g_levels[design$gi], levels = g_levels),
    p = factor(p_levels[design$pi], levels = rev(p_levels))
  )
  dat$zg <- unname(zg[as.character(dat$g)])
  dat$zp <- unname(zp[as.character(dat$p)])
  mu <- exp(0.2 + 0.3 * dat$x + b_g[as.character(dat$g)] +
              b_p[as.character(dat$p)])
  dat$y <- stats::rgamma(nrow(dat), shape = shape, scale = mu / shape)
  list(data = dat, K = K, tree = km$tree, coords = km$coords, zg = zg,
       zp = zp, alpha_g = alpha_g, alpha_p = alpha_p, g_levels = g_levels,
       p_levels = p_levels)
}

# Build the formula inside this frame so A, Ainv, tree and coords resolve.
gob_formula <- function(fx, provider, sd_g = "zg", ordinary_first = TRUE) {
  A <- fx$K
  Ainv <- solve(fx$K)
  tree <- fx$tree
  coords <- fx$coords
  spec <- gob_providers[[provider]]
  mean_part <- if (ordinary_first) {
    paste("y ~ x + (1 | g) +", spec$term)
  } else {
    paste("y ~ x +", spec$term, "+ (1 | g)")
  }
  parts <- c(mean_part, "sigma ~ 1")
  if (!is.null(sd_g)) parts <- c(parts, sprintf("sd(g) ~ %s", sd_g))
  eval(parse(text = sprintf("bf(%s)", paste(parts, collapse = ", "))))
}

gob_fit <- function(fx, provider, ...) {
  drmTMB(gob_formula(fx, provider, ...), family = Gamma(link = "log"),
         data = fx$data, control = drm_control(se = FALSE))
}

gob_oracle <- function(fit, fx, zg = fx$zg) {
  dat <- fx$data
  beta <- unname(coef(fit, "mu"))
  ag <- unname(coef(fit, "sd(g)"))
  s_p <- unname(fit$sdpars$mu)
  shape <- exp(-2 * unname(coef(fit, "sigma"))[[1L]])
  Zg <- stats::model.matrix(~ 0 + g, dat)
  Zp <- stats::model.matrix(~ 0 + p, dat)
  tau_g <- exp(ag[[1L]] + ag[[2L]] * zg[levels(dat$g)])
  Kp <- fx$K[levels(dat$p), levels(dat$p)]
  ig <- seq_len(ncol(Zg))
  ip <- ncol(Zg) + seq_len(ncol(Zp))
  Sigma <- matrix(0, ncol(Zg) + ncol(Zp), ncol(Zg) + ncol(Zp))
  Sigma[ig, ig] <- diag(tau_g^2, length(ig))
  Sigma[ip, ip] <- s_p^2 * Kp
  gob_laplace(dat$y, beta[[1L]] + beta[[2L]] * dat$x, cbind(Zg, Zp), Sigma,
              shape)
}

gob_check_provider <- function(provider, fx) {
  fit <- gob_fit(fx, provider)
  expect_equal(fit$opt$convergence, 0L, info = provider)
  expect_named(fit$sdpars, c("sd(g)", "mu"), info = provider)
  expect_named(coef(fit, "sd(g)"), c("(Intercept)", "zg"))
  expect_lt(abs(coef(fit, "sd(g)")[["zg"]] - fx$alpha_g[["zg"]]), 0.6)

  oracle <- gob_oracle(fit, fx)
  expect_lt(abs(as.numeric(logLik(fit)) - oracle), 1e-5)
  rev_named <- function(v) stats::setNames(rev(unname(v)), names(v))
  expect_gt(abs(gob_oracle(fit, fx, zg = rev_named(fx$zg)) - oracle), 0.1)
  positional <- fx
  dimnames(positional$K) <- list(fx$p_levels, fx$p_levels)
  expect_gt(abs(gob_oracle(fit, positional) - oracle), 0.1)

  # Constant-SD equivalence with the formula-free fit.
  base_fit <- gob_fit(fx, provider, sd_g = NULL)
  const_fit <- gob_fit(fx, provider, sd_g = "1")
  expect_equal(base_fit$opt$convergence, 0L, info = provider)
  expect_equal(const_fit$opt$convergence, 0L, info = provider)
  expect_lt(abs(as.numeric(logLik(const_fit)) -
                  as.numeric(logLik(base_fit))), 1e-4)
  expect_equal(coef(const_fit, "mu"), coef(base_fit, "mu"), tolerance = 1e-3)
  expect_equal(coef(const_fit, "sigma"), coef(base_fit, "sigma"),
               tolerance = 1e-3)
  # The formula-free fit reports c(ordinary SD, structured SD) in sdpars$mu.
  expect_equal(
    unname(c(exp(coef(const_fit, "sd(g)")[[1L]]), const_fit$sdpars$mu)),
    unname(base_fit$sdpars$mu), tolerance = 1e-3
  )
  # The predictor-dependent SD cannot fit worse than the constant one.
  expect_gt(as.numeric(logLik(fit)), as.numeric(logLik(const_fit)) - 1e-3)

  # Term order is immaterial.
  swapped <- gob_fit(fx, provider, ordinary_first = FALSE)
  expect_equal(swapped$opt$convergence, 0L, info = provider)
  expect_lt(abs(as.numeric(logLik(swapped)) - as.numeric(logLik(fit))), 1e-5)
  invisible(fit)
}

test_that("Gamma ordinary SD regression alone beside animal matches the oracle (A and Ainv)", {
  skip_on_cran()
  fx <- gob_fixture("animal", 2026110601L)
  expect_false(identical(levels(fx$data$p), rownames(fx$K)))
  fit_A <- gob_check_provider("animal_A", fx)
  fit_Ainv <- gob_fit(fx, "animal_Ainv")
  expect_lt(abs(as.numeric(logLik(fit_Ainv)) - as.numeric(logLik(fit_A))), 1e-5)
})

test_that("Gamma ordinary SD regression alone beside phylo matches the oracle", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- gob_fixture("phylo", 2026110602L)
  expect_false(identical(levels(fx$data$p), fx$tree$tip.label))
  gob_check_provider("phylo", fx)
})

test_that("Gamma ordinary SD regression alone beside spatial matches the oracle", {
  skip_on_cran()
  fx <- gob_fixture("spatial", 2026110603L)
  gob_check_provider("spatial", fx)
})

test_that("Gamma ordinary SD regression alone keeps neighbouring gates closed", {
  skip_on_cran()
  fx <- gob_fixture("animal", 2026110601L, n_g = 8L, n_p = 8L, reps = 1L)
  A <- fx$K
  dat <- fx$data
  dat$h <- factor(rep(c("a", "b"), length.out = nrow(dat)))
  fam <- Gamma(link = "log")
  ctl <- drm_control(se = FALSE)
  # Structured intercept-slope beside an ordinary SD alone.
  expect_error(
    drmTMB(bf(y ~ x + (1 | g) + animal(1 + x | p, A = A), sigma ~ 1,
              sd(g) ~ zg),
           family = fam, data = dat, control = ctl)
  )
  # Two ordinary intercepts beside the structured term.
  expect_error(
    drmTMB(bf(y ~ x + (1 | g) + (1 | h) + animal(1 | p, A = A), sigma ~ 1,
              sd(g) ~ zg),
           family = fam, data = dat, control = ctl)
  )
  # Ordinary SD plus sigma-side SD.
  expect_error(
    drmTMB(bf(y ~ x + (1 | g) + animal(1 | p, A = A), sigma ~ 1 + (1 | h),
              sd(g) ~ zg),
           family = fam, data = dat, control = ctl)
  )
  # Missing-response integration.
  expect_error(
    drmTMB(bf(y ~ x + (1 | g) + animal(1 | p, A = A), sigma ~ 1, sd(g) ~ zg),
           family = fam, data = dat,
           missing = miss_control(response = "include"), control = ctl),
    "complete responses"
  )
})
