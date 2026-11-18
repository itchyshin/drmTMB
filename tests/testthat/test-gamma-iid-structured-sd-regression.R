# Native Gamma(link = "log") ordinary iid intercept plus one structured mu
# intercept (animal, phylo or spatial; relmat is covered by
# test-gamma-batch4-sd-regression.R), each with its own predictor-dependent SD:
#   y ~ x + (1 | g) + <provider>(1 | p, ...),  sigma ~ 1,
#   sd(g) ~ zg,  sd(p, level = <provider level>) ~ zp.
# Mirrors the NB2 / Poisson iid-plus-structured routes.
#
# Oracle: a dense, drmTMB-independent Laplace marginal of
#   y_i | b ~ Gamma(shape = k, mean = exp(eta_i + Z_i b)),  k = 1 / sigma^2,
#   b ~ N(0, blockdiag(diag(tau_g^2), D K D)),  D = diag(tau_p),
# i.e. joint(b*) + (q/2) log(2 pi) - 0.5 log det(H), H = k Z' diag(y / mu*) Z +
# Sigma^-1 (observed information), b* by Newton. It uses the fitted coefficients,
# so it checks the likelihood assembly (which SD multiplies which latent block
# and how K is aligned to factor levels), not the optimiser.
#
# Tolerances were fixed before the first run and are not loosened:
#   oracle logLik 1e-5 absolute; K versus Q (or A versus Ainv) and term-order
#   invariance 1e-5 logLik; constant-SD limit 1e-4 logLik and 1e-3 on mu and
#   sigma coefficients; predict() identity 1e-7 relative; SD-slope recovery 0.6
#   absolute (20 to 24 levels per field); a nested model may not beat the full
#   model by more than 1e-3 log-likelihood units.

gis_laplace <- function(y, eta, Z, Sigma, shape) {
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

gis_providers <- list(
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
gis_make_K <- function(kind, n_p, p_levels) {
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

gis_fixture <- function(kind, seed, n_g = 24L, n_p = 20L, reps = 2L,
                        shape = 6) {
  set.seed(seed)
  g_levels <- sprintf("g%02d", seq_len(n_g))
  p_levels <- sprintf("p%02d", seq_len(n_p))
  km <- gis_make_K(kind, n_p, p_levels)
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
  b_p <- (field * exp(alpha_p[[1L]] + alpha_p[[2L]] * zp[names(field)]))[p_levels]
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
gis_formula <- function(fx, provider, sd_p = "zp", sd_g = "zg",
                        ordinary_first = TRUE) {
  A <- fx$K
  Ainv <- solve(fx$K)
  tree <- fx$tree
  coords <- fx$coords
  spec <- gis_providers[[provider]]
  mean_part <- if (ordinary_first) {
    paste("y ~ x + (1 | g) +", spec$term)
  } else {
    paste("y ~ x +", spec$term, "+ (1 | g)")
  }
  parts <- c(mean_part, "sigma ~ 1")
  if (!is.null(sd_g)) parts <- c(parts, sprintf("sd(g) ~ %s", sd_g))
  if (!is.null(sd_p)) {
    parts <- c(parts, sprintf("sd(p, level = \"%s\") ~ %s", spec$level, sd_p))
  }
  eval(parse(text = sprintf("bf(%s)", paste(parts, collapse = ", "))))
}

gis_fit <- function(fx, provider, ...) {
  drmTMB(gis_formula(fx, provider, ...), family = Gamma(link = "log"),
         data = fx$data, control = drm_control(se = FALSE))
}

gis_oracle <- function(fit, fx, provider, zg = fx$zg, zp = fx$zp) {
  dat <- fx$data
  spec <- gis_providers[[provider]]
  beta <- unname(coef(fit, "mu"))
  ag <- unname(coef(fit, "sd(g)"))
  ap <- unname(coef(fit, spec$dpar))
  shape <- exp(-2 * unname(coef(fit, "sigma"))[[1L]])
  Zg <- stats::model.matrix(~ 0 + g, dat)
  Zp <- stats::model.matrix(~ 0 + p, dat)
  # Latent blocks follow the factor-level order of the data columns.
  g_order <- levels(dat$g)
  p_order <- levels(dat$p)
  tau_g <- exp(ag[[1L]] + ag[[2L]] * zg[g_order])
  tau_p <- exp(ap[[1L]] + ap[[2L]] * zp[p_order])
  Kp <- fx$K[p_order, p_order]
  Sigma <- matrix(0, ncol(Zg) + ncol(Zp), ncol(Zg) + ncol(Zp))
  ig <- seq_len(ncol(Zg))
  ip <- ncol(Zg) + seq_len(ncol(Zp))
  Sigma[ig, ig] <- diag(tau_g^2, length(ig))
  Sigma[ip, ip] <- outer(tau_p, tau_p) * Kp
  gis_laplace(dat$y, beta[[1L]] + beta[[2L]] * dat$x, cbind(Zg, Zp), Sigma,
              shape)
}

gis_check_provider <- function(provider, fx) {
  spec <- gis_providers[[provider]]
  fit <- gis_fit(fx, provider)
  expect_equal(fit$opt$convergence, 0L, info = provider)
  expect_named(fit$sdpars, c("sd(g)", spec$dpar), info = provider)
  expect_named(coef(fit, "sd(g)"), c("(Intercept)", "zg"))
  expect_named(coef(fit, spec$dpar), c("(Intercept)", "zp"))
  expect_lt(abs(coef(fit, "sd(g)")[["zg"]] - fx$alpha_g[["zg"]]), 0.6)
  expect_lt(abs(coef(fit, spec$dpar)[["zp"]] - fx$alpha_p[["zp"]]), 0.6)

  # Name-aligned prediction of each field's SD.
  pg <- predict(fit, dpar = "sd(g)")
  pp <- predict(fit, dpar = spec$dpar)
  expect_setequal(names(pg), fx$g_levels)
  expect_setequal(names(pp), fx$p_levels)
  ag <- coef(fit, "sd(g)")
  ap <- coef(fit, spec$dpar)
  expect_equal(unname(pg), unname(exp(ag[[1L]] + ag[[2L]] * fx$zg[names(pg)])),
               tolerance = 1e-7)
  expect_equal(unname(pp), unname(exp(ap[[1L]] + ap[[2L]] * fx$zp[names(pp)])),
               tolerance = 1e-7)

  oracle <- gis_oracle(fit, fx, provider)
  expect_lt(abs(as.numeric(logLik(fit)) - oracle), 1e-5)
  # Sensitivity: swapping either SD design across levels, or aligning K by
  # position rather than name, moves the oracle value.
  rev_named <- function(v) stats::setNames(rev(unname(v)), names(v))
  expect_gt(abs(gis_oracle(fit, fx, provider, zg = rev_named(fx$zg)) - oracle), 0.1)
  expect_gt(abs(gis_oracle(fit, fx, provider, zp = rev_named(fx$zp)) - oracle), 0.1)
  positional <- fx
  dimnames(positional$K) <- list(fx$p_levels, fx$p_levels)
  expect_gt(abs(gis_oracle(fit, positional, provider) - oracle), 0.1)

  # Constant-SD equivalence with the formula-free fit.
  base_fit <- gis_fit(fx, provider, sd_p = NULL, sd_g = NULL)
  constant_fit <- gis_fit(fx, provider, sd_p = "1", sd_g = "1")
  expect_equal(base_fit$opt$convergence, 0L, info = provider)
  expect_equal(constant_fit$opt$convergence, 0L, info = provider)
  expect_lt(abs(as.numeric(logLik(constant_fit)) -
                  as.numeric(logLik(base_fit))), 1e-4)
  expect_equal(coef(constant_fit, "mu"), coef(base_fit, "mu"), tolerance = 1e-3)
  expect_equal(coef(constant_fit, "sigma"), coef(base_fit, "sigma"),
               tolerance = 1e-3)

  # The structured SD may be modelled alone (ordinary SD a scalar); the nested
  # model cannot beat the full one. The ordinary SD alone beside a structured
  # term is admitted (test-gamma-ordinary-sd-beside-structured.R); a structured
  # SD formula for a sigma-side endpoint beside it stays refused.
  p_only <- gis_fit(fx, provider, sd_g = NULL)
  expect_equal(p_only$opt$convergence, 0L, info = provider)
  expect_lt(as.numeric(logLik(p_only)), as.numeric(logLik(fit)) + 1e-3)
  ordinary_only <- gis_fit(fx, provider, sd_p = NULL)
  expect_equal(ordinary_only$opt$convergence, 0L, info = provider)
  expect_lt(as.numeric(logLik(ordinary_only)), as.numeric(logLik(fit)) + 1e-3)
  A <- fx$K
  dat_h <- transform(fx$data, h = g)
  expect_error(
    drmTMB(bf(y ~ x + (1 | g) + animal(1 | p, A = A), sigma ~ 1,
              sd(g) ~ zg, sd(h, dpar = "sigma") ~ zg),
           family = Gamma(link = "log"), data = dat_h,
           control = drm_control(se = FALSE)),
    "one endpoint at a time"
  )

  # Term order is immaterial.
  swapped <- gis_fit(fx, provider, ordinary_first = FALSE)
  expect_equal(swapped$opt$convergence, 0L, info = provider)
  expect_lt(abs(as.numeric(logLik(swapped)) - as.numeric(logLik(fit))), 1e-5)
  invisible(fit)
}

test_that("Gamma ordinary plus animal intercepts keep separate SD designs (A and Ainv)", {
  skip_on_cran()
  fx <- gis_fixture("animal", 2026110501L)
  expect_false(identical(levels(fx$data$p), rownames(fx$K)))
  fit_A <- gis_check_provider("animal_A", fx)
  fit_Ainv <- gis_check_provider("animal_Ainv", fx)
  expect_lt(abs(as.numeric(logLik(fit_Ainv)) - as.numeric(logLik(fit_A))), 1e-5)
})

test_that("Gamma ordinary plus phylo intercepts keep separate SD designs", {
  skip_on_cran()
  skip_if_not_installed("ape")
  fx <- gis_fixture("phylo", 2026110502L)
  expect_false(identical(levels(fx$data$p), fx$tree$tip.label))
  gis_check_provider("phylo", fx)
})

test_that("Gamma ordinary plus spatial intercepts keep separate SD designs", {
  skip_on_cran()
  fx <- gis_fixture("spatial", 2026110503L)
  expect_false(identical(levels(fx$data$p), rownames(fx$K)))
  gis_check_provider("spatial", fx)
})

test_that("Gamma ordinary plus structured SD keeps neighbouring gates closed", {
  skip_on_cran()
  fx <- gis_fixture("animal", 2026110501L, n_g = 8L, n_p = 8L, reps = 1L)
  A <- fx$K
  dat <- fx$data
  dat$h <- factor(rep(c("a", "b"), length.out = nrow(dat)))
  fam <- Gamma(link = "log")
  ctl <- drm_control(se = FALSE)
  # Two ordinary intercepts beside the structured term.
  expect_error(
    drmTMB(bf(y ~ x + (1 | g) + (1 | h) + animal(1 | p, A = A), sigma ~ 1,
              sd(p, level = "animal") ~ zp),
           family = fam, data = dat, control = ctl),
    "cannot be combined|one endpoint"
  )
  # Ordinary correlated intercept-slope beside the structured term.
  expect_error(
    drmTMB(bf(y ~ x + (1 + x | g) + animal(1 | p, A = A), sigma ~ 1,
              sd(p, level = "animal") ~ zp),
           family = fam, data = dat, control = ctl),
    "Only independent"
  )
  # Ordinary random effect on sigma beside the structured mu term.
  expect_error(
    drmTMB(bf(y ~ x + (1 | g) + animal(1 | p, A = A), sigma ~ 1 + (1 | h),
              sd(p, level = "animal") ~ zp),
           family = fam, data = dat, control = ctl)
  )
  # Missing-response integration.
  expect_error(
    drmTMB(bf(y ~ x + (1 | g) + animal(1 | p, A = A), sigma ~ 1,
              sd(g) ~ zg, sd(p, level = "animal") ~ zp),
           family = fam, data = dat,
           missing = miss_control(response = "include"), control = ctl),
    "complete responses"
  )
  # An SD level that does not match the structured term kind.
  expect_error(
    drmTMB(bf(y ~ x + (1 | g) + animal(1 | p, A = A), sigma ~ 1,
              sd(g) ~ zg, sd(p, level = "spatial") ~ zp),
           family = fam, data = dat, control = ctl)
  )
  # Structured intercept-slope beside an ordinary intercept stays closed.
  expect_error(
    drmTMB(bf(y ~ x + (1 | g) + animal(1 + x | p, A = A), sigma ~ 1,
              sd(g) ~ zg, sd(p, level = "animal") ~ zp),
           family = fam, data = dat, control = ctl)
  )
})
