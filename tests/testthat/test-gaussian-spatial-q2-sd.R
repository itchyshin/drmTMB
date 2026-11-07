# Native Gaussian coordinate-spatial intercept-plus-slope with coefficient-
# specific predictor-dependent SDs:
#
#   y ~ x + spatial(1 + x | id, coords = coords)      (also spatial(1 + x | p | id, ...))
#   sd(id, level = "spatial", coef = "(Intercept)") ~ s0
#   sd(id, level = "spatial", coef = "x")           ~ s1
#
# Model: y_i = X_i beta + sd0(i) f0[g(i)] + x_i sd1(i) f1[g(i)] + e_i,
# e ~ N(0, sigma^2), unit-scale fields (f0, f1) ~ N(0, R (x) K), R = I for the
# unlabelled block and [[1, rho], [rho, 1]] for the labelled block. y is
# Gaussian, so the marginal likelihood is exact:
#   y ~ N(X beta, sigma^2 I + sum_ab R_ab l_a l_b' o K_obs),
# with per-row loadings l_0 = sd0 and l_1 = x * sd1. The oracle builds K itself
# from irregular coordinates as an exponential kernel with range equal to the
# median positive pairwise distance and diagonal 1 + 1e-6; it shares no code
# with the package or the TMB template.
#
# Fixture design:
#   * 24 sites at irregular (uniform random) coordinates, not a lattice;
#   * the coordinate rows are passed in a shuffled order and the data rows are
#     shuffled, so reading coordinates by position instead of by site name
#     cannot pass. The spatial kernel has a diagonal of 1 + 1e-6 by
#     construction, so a non-unit-diagonal check does not apply to this
#     provider; the animal() and relmat() files carry that check.
#
# Tolerances, fixed before the first run:
#   * -logLik(fit) vs the dense marginal NLL at the fitted parameters: 1e-6
#     relative;
#   * an independent dense optimiser (L-BFGS-B) reaches the same maximum: 1e-5
#     relative;
#   * each emulated bug must move the oracle NLL by more than 1e-3 absolute;
#   * constant-SD equivalence with the existing independent spatial q2 fit:
#     1e-5 absolute on the log-likelihood.
# No recovery, coverage or calibration claim is made.

gsq2_fixture <- function(seed = 20261201L, n_id = 24L, n_each = 12L,
                         rho = 0.5) {
  set.seed(seed)
  ids <- sprintf("site%02d", seq_len(n_id))
  xy <- cbind(east = stats::runif(n_id, 0, 10), north = stats::runif(n_id, 0, 6))
  rownames(xy) <- ids
  K <- gsq2_kernel(xy)
  L <- t(chol(K))
  z0 <- drop(L %*% stats::rnorm(n_id))
  z1 <- drop(L %*% stats::rnorm(n_id))
  f0 <- z0
  f1 <- rho * z0 + sqrt(1 - rho^2) * z1
  s0 <- stats::setNames(rep(c(-1, 1), length.out = n_id), ids)
  s1 <- stats::setNames(rep(c(-1, 1), each = n_id / 2L), ids)
  b0 <- exp(log(0.45) + 0.35 * s0) * f0
  b1 <- exp(log(0.35) - 0.40 * s1) * f1
  gi <- rep(seq_len(n_id), each = n_each)
  x <- rep(seq(-1.2, 1.2, length.out = n_each), times = n_id)
  y <- 0.3 + 0.25 * x + b0[gi] + x * b1[gi] + 0.4 * stats::rnorm(length(gi))
  dat <- data.frame(
    y = y, x = x, id = ids[gi], s0 = unname(s0[gi]), s1 = unname(s1[gi]),
    stringsAsFactors = FALSE
  )
  dat <- dat[sample.int(nrow(dat)), , drop = FALSE]
  rownames(dat) <- NULL
  dat$id <- factor(dat$id, levels = sort(ids))
  coords <- xy[sample.int(n_id), , drop = FALSE]
  list(data = dat, coords = coords, K = K, xy = xy)
}

# Independent exponential kernel: range = median positive pairwise distance.
gsq2_kernel <- function(xy, range_fun = stats::median) {
  d <- sqrt(outer(xy[, 1], xy[, 1], "-")^2 + outer(xy[, 2], xy[, 2], "-")^2)
  K <- exp(-d / range_fun(d[upper.tri(d)]))
  diag(K) <- diag(K) + 1e-6
  dimnames(K) <- list(rownames(xy), rownames(xy))
  K
}

gsq2_keys <- c(
  'sd_spatial(id, dpar = "mu", coef = "(Intercept)")',
  'sd_spatial(id, dpar = "mu", coef = "x")'
)

gsq2_formula <- function(coords, label = NULL, constant = FALSE, none = FALSE) {
  lab <- if (is.null(label)) "" else paste0(label, " | ")
  mu <- stats::as.formula(
    sprintf("y ~ x + spatial(1 + x | %sid, coords = coords)", lab),
    env = environment()
  )
  if (none) return(bf(mu, sigma ~ 1))
  f0 <- stats::as.formula(sprintf(
    'sd(id, level = "spatial", coef = "(Intercept)") ~ %s',
    if (constant) "1" else "s0"
  ), env = environment())
  f1 <- stats::as.formula(sprintf(
    'sd(id, level = "spatial", coef = "x") ~ %s',
    if (constant) "1" else "s1"
  ), env = environment())
  bf(mu, sigma ~ 1, f0, f1)
}

# Dense exact marginal NLL. theta = (beta_mu[2], log sigma, a0[2], a1[2], eta),
# rho = tanh(eta). `bug` emulates a specific implementation error.
gsq2_nll <- function(theta, dat, K, xy, bug = "none", coords = NULL) {
  if (bug == "wrong_range") K <- gsq2_kernel(xy, range_fun = base::mean)
  if (bug == "gaussian_kernel") {
    d <- sqrt(outer(xy[, 1], xy[, 1], "-")^2 + outer(xy[, 2], xy[, 2], "-")^2)
    K <- exp(-(d / stats::median(d[upper.tri(d)]))^2)
    diag(K) <- diag(K) + 1e-6
    dimnames(K) <- list(rownames(xy), rownames(xy))
  }
  if (bug == "positional_K") {
    # Shuffled coordinate rows relabelled by position instead of by name.
    pos <- coords
    rownames(pos) <- sort(rownames(coords))
    K <- gsq2_kernel(pos)
  }
  idx <- match(as.character(dat$id), rownames(K))
  Kobs <- K[idx, idx]
  sd0 <- exp(theta[4L] + theta[5L] * dat$s0)
  sd1 <- exp(theta[6L] + theta[7L] * dat$s1)
  if (bug == "swap_sd_formulas") {
    sd0 <- exp(theta[6L] + theta[7L] * dat$s0)
    sd1 <- exp(theta[4L] + theta[5L] * dat$s1)
  }
  if (bug == "shared_sd") sd1 <- sd0
  l0 <- sd0
  l1 <- (if (bug == "no_slope_loading") 1 else dat$x) * sd1
  rho <- tanh(theta[8L])
  if (bug == "drop_rho") rho <- 0
  if (bug == "cross_sign") rho <- -rho
  V <- (outer(l0, l0) + outer(l1, l1) + rho * (outer(l0, l1) + outer(l1, l0))) *
    Kobs
  diag(V) <- diag(V) + exp(2 * theta[3L])
  R <- chol(V)
  r <- backsolve(R, dat$y - theta[1L] - theta[2L] * dat$x, transpose = TRUE)
  0.5 * (length(dat$y) * log(2 * pi) + 2 * sum(log(diag(R))) + sum(r^2))
}

# Dense marginal covariance of y at theta (same formula as the NLL).
gsq2_V <- function(theta, dat, K) {
  idx <- match(as.character(dat$id), rownames(K))
  l0 <- exp(theta[4L] + theta[5L] * dat$s0)
  l1 <- dat$x * exp(theta[6L] + theta[7L] * dat$s1)
  rho <- tanh(theta[8L])
  V <- (outer(l0, l0) + outer(l1, l1) + rho * (outer(l0, l1) + outer(l1, l0))) *
    K[idx, idx]
  diag(V) <- diag(V) + exp(2 * theta[3L])
  V
}

gsq2_theta_hat <- function(fit, labelled) {
  a0 <- coef(fit, gsq2_keys[[1L]])
  a1 <- coef(fit, gsq2_keys[[2L]])
  if (length(a0) == 1L) a0 <- c(a0, 0)
  if (length(a1) == 1L) a1 <- c(a1, 0)
  rho <- if (labelled) unname(fit$corpars[[1L]][[1L]]) else 0
  c(
    unname(coef(fit, "mu")), unname(coef(fit, "sigma")[[1L]]),
    unname(a0), unname(a1), atanh(rho / 0.999999)
  )
}

gsq2_expect_oracle <- function(fit, dat, K, xy, labelled,
                               check_optimum = TRUE) {
  theta <- gsq2_theta_hat(fit, labelled)
  nll <- gsq2_nll(theta, dat, K, xy)
  expect_equal(as.numeric(stats::logLik(fit)), -nll, tolerance = 1e-6)
  if (check_optimum) {
    start <- c(
      unname(stats::coef(stats::lm(y ~ x, dat))), log(0.5), log(0.3), 0,
      log(0.3), 0, 0
    )
    lower <- c(-Inf, -Inf, -5, -5, -3, -5, -3, -3)
    upper <- c(Inf, Inf, 2, 2, 3, 2, 3, 3)
    free <- if (labelled) seq_len(8L) else seq_len(7L)
    obj <- function(p) gsq2_nll(c(p, rep(0, 8L - length(p))), dat, K, xy)
    opt <- stats::optim(
      start[free], obj, method = "L-BFGS-B",
      lower = lower[free], upper = upper[free],
      control = list(maxit = 500L, factr = 1e3)
    )
    expect_equal(opt$convergence, 0L)
    expect_equal(as.numeric(stats::logLik(fit)), -opt$value, tolerance = 1e-5)
  }
  invisible(theta)
}

gsq2_fit <- function(form, dat, ...) {
  drmTMB(
    form, family = stats::gaussian(), data = dat, engine = "tmb",
    control = drm_control(se = FALSE), ...
  )
}

test_that("Gaussian spatial q2 SD regression matches the exact marginal oracle", {
  skip_on_cran()
  fx <- gsq2_fixture()
  coords <- fx$coords
  dat <- fx$data
  # Fixture non-vacuity: irregular coordinates, shuffled against the factor.
  expect_false(identical(rownames(coords), levels(dat$id)))
  expect_gt(stats::sd(diff(sort(fx$xy[, 1L]))), 0.05)

  fit_ind <- gsq2_fit(gsq2_formula(coords), dat)
  fit_cor <- gsq2_fit(gsq2_formula(coords, label = "p"), dat)
  expect_true(is_converged(fit_ind))
  expect_true(is_converged(fit_cor))
  expect_identical(
    drmTMB:::structured_mu_type(fit_cor$model$structured$phylo_mu), "spatial"
  )

  expect_null(fit_ind$corpars$spatial)
  key <- "cor(mu:(Intercept),mu:x | p | id)"
  expect_named(fit_cor$corpars$spatial, key)
  rho_hat <- unname(fit_cor$corpars$spatial[[key]])
  expect_true(is.finite(rho_hat))
  expect_lt(abs(rho_hat), 1)
  rho_report <- fit_cor$obj$report(fit_cor$obj$env$last.par.best)$rho_phylo
  expect_equal(rho_report, rho_hat, tolerance = 1e-8)

  gsq2_expect_oracle(fit_ind, dat, fx$K, fx$xy, labelled = FALSE)
  gsq2_expect_oracle(fit_cor, dat, fx$K, fx$xy, labelled = TRUE)
  expect_gte(
    as.numeric(stats::logLik(fit_cor)),
    as.numeric(stats::logLik(fit_ind)) - 1e-6
  )

  expect_named(coef(fit_cor, gsq2_keys[[1L]]), c("(Intercept)", "s0"))
  expect_named(coef(fit_cor, gsq2_keys[[2L]]), c("(Intercept)", "s1"))
  expect_true(all(is.finite(coef(fit_cor, gsq2_keys[[1L]]))))
  expect_true(all(is.finite(coef(fit_cor, gsq2_keys[[2L]]))))
  sd0 <- predict(fit_cor, dpar = gsq2_keys[[1L]])
  expect_setequal(names(sd0), rownames(coords))
  a0 <- coef(fit_cor, gsq2_keys[[1L]])
  s0_by_id <- tapply(dat$s0, as.character(dat$id), unique)
  expect_equal(
    as.numeric(sd0[names(s0_by_id)]),
    as.numeric(exp(a0[[1L]] + a0[[2L]] * s0_by_id)),
    tolerance = 1e-10
  )
})

test_that("Gaussian spatial q2 oracle is sensitive to emulated bugs", {
  skip_on_cran()
  fx <- gsq2_fixture()
  dat <- fx$data
  coords <- fx$coords
  fit <- gsq2_fit(gsq2_formula(coords, label = "p"), dat)
  theta <- gsq2_theta_hat(fit, labelled = TRUE)
  truth <- gsq2_nll(theta, dat, fx$K, fx$xy)
  expect_equal(as.numeric(stats::logLik(fit)), -truth, tolerance = 1e-6)
  for (bug in c(
    "wrong_range", "gaussian_kernel", "positional_K", "swap_sd_formulas",
    "shared_sd", "no_slope_loading", "drop_rho", "cross_sign"
  )) {
    moved <- abs(gsq2_nll(theta, dat, fx$K, fx$xy, bug, coords = fx$coords) - truth)
    expect_gt(moved, 1e-3, label = paste("emulated bug", bug))
  }
})

test_that("Gaussian spatial q2 with constant SD equals the independent spatial fit", {
  skip_on_cran()
  fx <- gsq2_fixture()
  coords <- fx$coords
  dat <- fx$data
  constant <- gsq2_fit(gsq2_formula(coords, constant = TRUE), dat)
  plain <- gsq2_fit(gsq2_formula(coords, none = TRUE), dat)
  expect_true(is_converged(constant))
  expect_true(is_converged(plain))
  expect_lt(
    abs(as.numeric(stats::logLik(constant)) - as.numeric(stats::logLik(plain))),
    1e-5
  )
  constant_cor <- gsq2_fit(gsq2_formula(coords, label = "p", constant = TRUE), dat)
  expect_gte(
    as.numeric(stats::logLik(constant_cor)),
    as.numeric(stats::logLik(constant)) - 1e-6
  )
  gsq2_expect_oracle(
    constant_cor, transform(dat, s0 = 0, s1 = 0), fx$K, fx$xy,
    labelled = TRUE, check_optimum = FALSE
  )
})

test_that("Gaussian spatial q2 simulation follows the fitted covariance", {
  skip_on_cran()
  fx <- gsq2_fixture()
  coords <- fx$coords
  dat <- fx$data
  fit <- gsq2_fit(gsq2_formula(coords, label = "p"), dat)
  theta <- gsq2_theta_hat(fit, labelled = TRUE)
  V <- gsq2_V(theta, dat, fx$K)
  # The helper reproduces the oracle NLL, so it is the same covariance.
  expect_equal(
    0.5 * (nrow(V) * log(2 * pi) + as.numeric(determinant(V)$modulus) +
             drop(crossprod(
               dat$y - theta[1L] - theta[2L] * dat$x,
               solve(V, dat$y - theta[1L] - theta[2L] * dat$x)
             ))),
    gsq2_nll(theta, dat, fx$K, fx$xy), tolerance = 1e-8
  )
  # Conditional draws are reproducible and finite.
  cond <- simulate(fit, nsim = 2L, seed = 1L, re.form = NULL)
  expect_identical(cond, simulate(fit, nsim = 2L, seed = 1L, re.form = NULL))
  expect_true(all(is.finite(as.matrix(cond))))
  # Marginal draws: empirical covariance matches the dense V (Monte Carlo
  # tolerance fixed in advance: variances within 25%, covariance pattern
  # correlation above 0.9).
  sims <- as.matrix(simulate(fit, nsim = 4000L, seed = 20261201L))
  mu_fit <- theta[1L] + theta[2L] * dat$x
  centred <- sims - mu_fit
  emp_var <- rowMeans(centred^2)
  expect_lt(max(abs(emp_var / diag(V) - 1)), 0.25)
  sel <- seq_len(60L)
  emp_cov <- tcrossprod(centred[sel, ]) / ncol(centred)
  expect_gt(stats::cor(as.vector(emp_cov), as.vector(V[sel, sel])), 0.9)
})

test_that("Gaussian spatial q2 SD refusals are designed errors", {
  skip_on_cran()
  fx <- gsq2_fixture(n_id = 12L, n_each = 8L)
  coords <- fx$coords
  d <- fx$data
  d$z <- cos(seq_len(nrow(d)))
  fit <- function(...) {
    drmTMB(bf(...), family = stats::gaussian(), data = d, engine = "tmb",
           control = drm_control(se = FALSE))
  }
  sd_int <- sd(id, level = "spatial", coef = "(Intercept)") ~ s0
  sd_x <- sd(id, level = "spatial", coef = "x") ~ s1
  pattern_one <- "requires\\s+one\\s+SD\\s+formula\\s+for\\s+each\\s+coefficient"

  # Labelled block without SD formulas keeps the old refusal.
  expect_error(
    fit(y ~ x + spatial(1 + x | p | id, coords = coords), sigma ~ 1),
    "only\\s+implemented\\s+for\\s+the\\s+all-four\\s+bivariate\\s+Gaussian"
  )
  # One SD formula for a two-coefficient block, labelled or not.
  expect_error(
    fit(y ~ x + spatial(1 + x | id, coords = coords), sigma ~ 1, sd_int),
    pattern_one
  )
  expect_error(
    fit(y ~ x + spatial(1 + x | p | id, coords = coords), sigma ~ 1, sd_x),
    pattern_one
  )
  # Two SD formulas on the same coefficient.
  expect_error(
    fit(y ~ x + spatial(1 + x | id, coords = coords), sigma ~ 1, sd_int,
        sd(id, level = "spatial", coef = "(Intercept)") ~ s1),
    pattern_one
  )
  # Unknown coefficient selector.
  expect_error(
    fit(y ~ x + spatial(1 + x | id, coords = coords), sigma ~ 1, sd_int,
        sd(id, level = "spatial", coef = "z") ~ s1),
    "does\\s+not\\s+match\\s+the\\s+available\\s+coefficient"
  )
  # SD aimed at the sigma endpoint of a mu block.
  expect_error(
    fit(y ~ x + spatial(1 + x | id, coords = coords), sigma ~ 1, sd_int,
        sd(id, level = "spatial", dpar = "sigma", coef = "x") ~ s1),
    "own\\s+endpoint"
  )
  # Provider level mismatch.
  expect_error(
    fit(y ~ x + spatial(1 + x | id, coords = coords), sigma ~ 1, sd_int,
        sd(id, level = "animal", coef = "x") ~ s1),
    "does\\s+not\\s+match\\s+the\\s+structured"
  )
  # Three structured coefficients stay refused, at the parser.
  expect_error(
    fit(y ~ x + z + spatial(1 + x + z | id, coords = coords), sigma ~ 1,
        sd_int, sd_x),
    "reserves\\s+only\\s+intercept\\s+and\\s+one-slope"
  )
  # A slope-only spatial block cannot take an intercept SD formula.
  expect_error(
    fit(y ~ x + spatial(0 + x | id, coords = coords), sigma ~ 1, sd_int, sd_x),
    "does\\s+not\\s+match\\s+the\\s+available\\s+coefficient"
  )
  # A residual-scale structured effect next to the q2 mu block stays refused.
  expect_error(
    fit(y ~ x + spatial(1 + x | id, coords = coords),
        sigma ~ spatial(1 | id, coords = coords), sd_int, sd_x),
    "must\\s+use\\s+matching"
  )
})
