# Native Gaussian structured intercept-plus-slope with coefficient-specific
# predictor-dependent SDs:
#
#   y ~ x + animal(1 + x | id, A = A)            (also relmat(), phylo())
#   sd(id, level = "animal", coef = "(Intercept)") ~ s0
#   sd(id, level = "animal", coef = "x")           ~ s1
#
# Model: y_i = X_i beta + sd0(i) f0[g(i)] + x_i sd1(i) f1[g(i)] + e_i,
# e ~ N(0, sigma^2), and the unit-scale fields (f0, f1) ~ N(0, R (x) K) with
# R = [[1, rho], [rho, 1]] for the labelled block `animal(1 + x | p | id)`
# and R = I for the unlabelled block. y is Gaussian, so the marginal
# likelihood is exact: y ~ N(X beta, sigma^2 I + sum_ab R_ab l_a l_b' o K_obs),
# where l_0 = sd0 and l_1 = x * sd1 are per-row loadings and K_obs is K
# indexed by the row's level NAME. The oracle below builds that dense
# covariance and shares no code with the TMB template.
#
# Fixture design:
#   * K has a non-unit diagonal (0.7 to 1.8), so a fit that silently converts
#     K to a correlation matrix cannot pass.
#   * K's rows are passed in a shuffled order and the data rows are shuffled,
#     so reading K by position instead of by level name cannot pass.
#
# Tolerances, fixed before the first run:
#   * -logLik(fit) vs the dense marginal NLL at the fitted parameters:
#     1e-6 relative (expect_equal tolerance);
#   * an independent dense optimiser (L-BFGS-B, neutral starts) reaches the
#     same maximum: 1e-5 relative;
#   * each emulated bug must move the oracle log-likelihood by more than 1e-3
#     absolute;
#   * constant-SD equivalence with the existing independent-coefficient
#     structured fit: 1e-5 absolute on the log-likelihood.
# No recovery, coverage or calibration claim is made. The labelled and
# unlabelled models are checked against the likelihood surface only.

gq2_kernel <- function(n_id, seed) {
  set.seed(seed)
  ids <- sprintf("id%02d", seq_len(n_id))
  d <- seq(0.7, 1.8, length.out = n_id)[sample.int(n_id)]
  D <- diag(sqrt(d))
  C <- 0.45^abs(outer(seq_len(n_id), seq_len(n_id), `-`))
  K <- D %*% C %*% D
  dimnames(K) <- list(ids, ids)
  K
}

gq2_data <- function(seed = 20261101L, n_id = 24L, n_each = 12L, rho = 0.5,
                     K = NULL) {
  if (is.null(K)) K <- gq2_kernel(n_id, seed)
  ids <- rownames(K)
  set.seed(seed + 1L)
  L <- t(chol(K))
  z0 <- drop(L %*% stats::rnorm(n_id))
  z1 <- drop(L %*% stats::rnorm(n_id))
  f0 <- z0
  f1 <- rho * z0 + sqrt(1 - rho^2) * z1
  s0 <- rep(c(-1, 1), length.out = n_id)
  s1 <- rep(c(-1, 1), each = ceiling(n_id / 2))[seq_len(n_id)]
  names(s0) <- names(s1) <- ids
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
  # K rows in a shuffled order relative to the factor levels.
  perm <- sample.int(n_id)
  list(data = dat, K = K[perm, perm], K_true = K, rho = rho)
}

gq2_keys <- function(level) {
  c(
    sprintf('sd_%s(id, dpar = "mu", coef = "(Intercept)")', level),
    sprintf('sd_%s(id, dpar = "mu", coef = "x")', level)
  )
}

gq2_formula <- function(provider, K, tree = NULL, label = NULL,
                        constant = FALSE) {
  lab <- if (is.null(label)) "" else paste0(label, " | ")
  term <- switch(
    provider,
    animal = sprintf("animal(1 + x | %sid, A = K)", lab),
    relmat = sprintf("relmat(1 + x | %sid, K = K)", lab),
    phylo = sprintf("phylo(1 + x | %sid, tree = tree)", lab)
  )
  level <- c(
    animal = "animal", relmat = "relmat", phylo = "phylogenetic"
  )[[provider]]
  mu <- stats::as.formula(paste("y ~ x +", term), env = environment())
  rhs0 <- if (constant) "1" else "s0"
  rhs1 <- if (constant) "1" else "s1"
  f0 <- stats::as.formula(
    sprintf('sd(id, level = "%s", coef = "(Intercept)") ~ %s', level, rhs0)
  )
  f1 <- stats::as.formula(
    sprintf('sd(id, level = "%s", coef = "x") ~ %s', level, rhs1)
  )
  bf(mu, sigma ~ 1, f0, f1)
}

# Dense exact marginal NLL. theta = (beta_mu[2], log sigma, a0[2], a1[2], eta)
# with rho = tanh(eta). `bug` emulates a specific implementation error.
gq2_nll <- function(theta, dat, K, bug = "none") {
  if (bug == "unit_diag") K <- stats::cov2cor(K)
  idx <- if (bug == "positional_K") {
    as.integer(dat$id)
  } else {
    match(as.character(dat$id), rownames(K))
  }
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
  r <- backsolve(
    R, dat$y - theta[1L] - theta[2L] * dat$x, transpose = TRUE
  )
  0.5 * (length(dat$y) * log(2 * pi) + 2 * sum(log(diag(R))) + sum(r^2))
}

gq2_theta_hat <- function(fit, level, labelled) {
  keys <- gq2_keys(level)
  a0 <- coef(fit, keys[[1L]])
  a1 <- coef(fit, keys[[2L]])
  # A constant-SD formula reports only its intercept; pad the zero slope.
  if (length(a0) == 1L) a0 <- c(a0, 0)
  if (length(a1) == 1L) a1 <- c(a1, 0)
  rho <- if (labelled) {
    unname(fit$corpars[[1L]][[1L]])
  } else {
    0
  }
  c(
    unname(coef(fit, "mu")), unname(coef(fit, "sigma")[[1L]]),
    unname(a0), unname(a1), atanh(rho / 0.999999)
  )
}

gq2_expect_dense_oracle <- function(fit, dat, K, level, labelled,
                                    check_optimum = TRUE) {
  theta <- gq2_theta_hat(fit, level, labelled)
  nll <- gq2_nll(theta, dat, K)
  expect_equal(as.numeric(stats::logLik(fit)), -nll, tolerance = 1e-6)
  if (check_optimum) {
    start <- c(
      unname(stats::coef(stats::lm(y ~ x, dat))), log(0.5), log(0.3), 0,
      log(0.3), 0, 0
    )
    lower <- c(-Inf, -Inf, -5, -5, -3, -5, -3, -3)
    upper <- c(Inf, Inf, 2, 2, 3, 2, 3, 3)
    free <- if (labelled) seq_len(8L) else seq_len(7L)
    obj <- function(p) {
      th <- c(p, rep(0, 8L - length(p)))
      gq2_nll(th, dat, K)
    }
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

gq2_fit <- function(form, dat, ...) {
  drmTMB(
    form, family = stats::gaussian(), data = dat, engine = "tmb",
    control = drm_control(se = FALSE), ...
  )
}

# ---- animal: unlabelled (independent fields) and labelled (rho) -------------

test_that("Gaussian animal q2 SD regression matches the exact marginal oracle", {
  skip_on_cran()
  fx <- gq2_data()
  K <- fx$K
  dat <- fx$data
  # Fixture non-vacuity.
  expect_gt(max(abs(diag(K) - 1)), 0.5)
  expect_false(identical(rownames(K), levels(dat$id)))

  fit_ind <- gq2_fit(gq2_formula("animal", K), dat)
  fit_cor <- gq2_fit(gq2_formula("animal", K, label = "p"), dat)
  expect_true(is_converged(fit_ind))
  expect_true(is_converged(fit_cor))

  expect_null(fit_ind$corpars$animal)
  key <- "cor(mu:(Intercept),mu:x | p | id)"
  expect_named(fit_cor$corpars$animal, key)
  rho_hat <- unname(fit_cor$corpars$animal[[key]])
  expect_true(is.finite(rho_hat))
  expect_lt(abs(rho_hat), 1)
  rho_report <- fit_cor$obj$report(fit_cor$obj$env$last.par.best)$rho_phylo
  expect_equal(rho_report, rho_hat, tolerance = 1e-8)

  gq2_expect_dense_oracle(fit_ind, dat, K, "animal", labelled = FALSE)
  gq2_expect_dense_oracle(fit_cor, dat, K, "animal", labelled = TRUE)

  # Independent fields are nested in the correlated block.
  expect_gte(
    as.numeric(stats::logLik(fit_cor)), as.numeric(stats::logLik(fit_ind)) - 1e-6
  )

  # Both coefficient-specific SD regressions are reported and signed.
  keys <- gq2_keys("animal")
  expect_named(coef(fit_cor, keys[[1L]]), c("(Intercept)", "s0"))
  expect_named(coef(fit_cor, keys[[2L]]), c("(Intercept)", "s1"))
  expect_gt(coef(fit_cor, keys[[1L]])[["s0"]], 0)
  expect_lt(coef(fit_cor, keys[[2L]])[["s1"]], 0)
  # The group SD surfaces predict by level name.
  sd0 <- predict(fit_cor, dpar = keys[[1L]])
  expect_setequal(names(sd0), rownames(K))
  a0 <- coef(fit_cor, keys[[1L]])
  s0_by_id <- tapply(dat$s0, as.character(dat$id), unique)
  expect_equal(
    as.numeric(sd0[names(s0_by_id)]),
    as.numeric(exp(a0[[1L]] + a0[[2L]] * s0_by_id)),
    tolerance = 1e-10
  )
})

test_that("Gaussian animal q2 oracle is sensitive to emulated bugs", {
  skip_on_cran()
  fx <- gq2_data()
  K <- fx$K
  dat <- fx$data
  fit <- gq2_fit(gq2_formula("animal", K, label = "p"), dat)
  theta <- gq2_theta_hat(fit, "animal", labelled = TRUE)
  truth <- gq2_nll(theta, dat, K)
  expect_equal(as.numeric(stats::logLik(fit)), -truth, tolerance = 1e-6)
  for (bug in c(
    "unit_diag", "positional_K", "swap_sd_formulas", "shared_sd",
    "no_slope_loading", "drop_rho", "cross_sign"
  )) {
    moved <- abs(gq2_nll(theta, dat, K, bug) - truth)
    expect_gt(moved, 1e-3, label = paste("emulated bug", bug))
  }
})

test_that("Gaussian animal q2 with constant SD equals the independent structured fit", {
  skip_on_cran()
  fx <- gq2_data()
  K <- fx$K
  dat <- fx$data
  constant <- gq2_fit(gq2_formula("animal", K, constant = TRUE), dat)
  plain <- gq2_fit(
    bf(y ~ x + animal(1 + x | id, A = K), sigma ~ 1), dat
  )
  expect_true(is_converged(constant))
  expect_true(is_converged(plain))
  expect_lt(
    abs(as.numeric(stats::logLik(constant)) - as.numeric(stats::logLik(plain))),
    1e-5
  )
  # Labelled constant-SD fit: correlated fields can only raise the likelihood.
  constant_cor <- gq2_fit(
    gq2_formula("animal", K, label = "p", constant = TRUE), dat
  )
  expect_gte(
    as.numeric(stats::logLik(constant_cor)),
    as.numeric(stats::logLik(constant)) - 1e-6
  )
  gq2_expect_dense_oracle(
    constant_cor, transform(dat, s0 = 0, s1 = 0), K, "animal",
    labelled = TRUE, check_optimum = FALSE
  )
})

# ---- relmat and phylo providers ---------------------------------------------

test_that("Gaussian relmat q2 SD regression matches the exact marginal oracle", {
  skip_on_cran()
  fx <- gq2_data(seed = 20261111L)
  K <- fx$K
  dat <- fx$data
  fit_ind <- gq2_fit(gq2_formula("relmat", K), dat)
  fit_cor <- gq2_fit(gq2_formula("relmat", K, label = "p"), dat)
  expect_true(is_converged(fit_ind))
  expect_true(is_converged(fit_cor))
  expect_named(fit_cor$corpars$relmat, "cor(mu:(Intercept),mu:x | p | id)")
  gq2_expect_dense_oracle(fit_ind, dat, K, "relmat", labelled = FALSE)
  gq2_expect_dense_oracle(fit_cor, dat, K, "relmat", labelled = TRUE)
})

test_that("Gaussian phylo q2 SD regression matches the exact marginal oracle", {
  skip_on_cran()
  skip_if_not_installed("ape")
  n_id <- 24L
  set.seed(20261121L)
  # The phylo provider requires an ultrametric tree and works on the shared
  # ancestry CORRELATION, so the diagonal is 1 here by design; the non-unit
  # diagonal check applies to animal() and relmat() only.
  tree <- ape::rcoal(n_id)
  tree$tip.label <- sprintf("id%02d", seq_len(n_id))
  raw <- ape::vcv(tree)
  K <- stats::cov2cor(raw)
  ids <- sprintf("id%02d", seq_len(n_id))
  K <- K[ids, ids]
  perm <- sample.int(n_id)
  K <- K[perm, perm]
  fx <- gq2_data(seed = 20261122L, K = K)
  dat <- fx$data
  fit_ind <- gq2_fit(gq2_formula("phylo", K, tree = tree), dat)
  fit_cor <- gq2_fit(gq2_formula("phylo", K, tree = tree, label = "p"), dat)
  expect_true(is_converged(fit_ind))
  expect_true(is_converged(fit_cor))
  expect_named(fit_cor$corpars$phylo, "cor(mu:(Intercept),mu:x | p | id)")
  gq2_expect_dense_oracle(fit_ind, dat, K, "phylo", labelled = FALSE)
  gq2_expect_dense_oracle(fit_cor, dat, K, "phylo", labelled = TRUE)
  # Sensitivity: the raw (height-scaled) covariance is a different model.
  theta <- gq2_theta_hat(fit_cor, "phylo", labelled = TRUE)
  expect_gt(
    abs(gq2_nll(theta, dat, raw[rownames(K), rownames(K)]) -
          gq2_nll(theta, dat, K)),
    1e-3
  )
})

# ---- refusals ---------------------------------------------------------------

test_that("Gaussian structured q2 SD refusals are designed errors", {
  skip_on_cran()
  fx <- gq2_data(n_id = 12L, n_each = 8L)
  K <- fx$K
  d <- fx$data
  d$z <- cos(seq_len(nrow(d)))
  gau <- stats::gaussian()
  fit <- function(...) {
    drmTMB(bf(...), family = gau, data = d, engine = "tmb",
           control = drm_control(se = FALSE))
  }
  sd_int <- sd(id, level = "animal", coef = "(Intercept)") ~ s0
  sd_x <- sd(id, level = "animal", coef = "x") ~ s1

  # Labelled block without SD formulas keeps the old refusal.
  expect_error(
    fit(y ~ x + animal(1 + x | p | id, A = K), sigma ~ 1),
    "only\\s+implemented\\s+for\\s+the\\s+all-four\\s+bivariate\\s+Gaussian"
  )

  # One SD formula for a two-coefficient block (labelled or not).
  pattern_one <- "requires\\s+one\\s+SD\\s+formula\\s+for\\s+each\\s+coefficient"
  expect_error(
    fit(y ~ x + animal(1 + x | id, A = K), sigma ~ 1, sd_int), pattern_one
  )
  expect_error(
    fit(y ~ x + animal(1 + x | p | id, A = K), sigma ~ 1, sd_x), pattern_one
  )
  # Two SD formulas on the same coefficient.
  expect_error(
    fit(y ~ x + animal(1 + x | id, A = K), sigma ~ 1, sd_int,
        sd(id, level = "animal", coef = "(Intercept)") ~ s1),
    pattern_one
  )
  # A coefficient selector is required on a two-coefficient block.
  expect_error(
    fit(y ~ x + animal(1 + x | id, A = K), sigma ~ 1, sd_int,
        sd(id, level = "animal") ~ s1),
    "must\\s+select\\s+a\\s+coefficient"
  )
  # Unknown coefficient selector.
  expect_error(
    fit(y ~ x + animal(1 + x | id, A = K), sigma ~ 1, sd_int,
        sd(id, level = "animal", coef = "z") ~ s1),
    "does\\s+not\\s+match\\s+the\\s+available\\s+coefficient"
  )
  # SD aimed at the sigma endpoint of a mu block.
  expect_error(
    fit(y ~ x + animal(1 + x | id, A = K), sigma ~ 1, sd_int,
        sd(id, level = "animal", dpar = "sigma", coef = "x") ~ s1),
    "own\\s+endpoint"
  )
  # Provider level mismatch.
  expect_error(
    fit(y ~ x + animal(1 + x | id, A = K), sigma ~ 1, sd_int,
        sd(id, level = "relmat", coef = "x") ~ s1),
    "does\\s+not\\s+match\\s+the\\s+structured"
  )
  # Three structured coefficients stay refused, at the parser.
  expect_error(
    fit(y ~ x + z + animal(1 + x + z | id, A = K), sigma ~ 1, sd_int,
        sd(id, level = "animal", coef = "x") ~ s1,
        sd(id, level = "animal", coef = "z") ~ 1),
    "reserves\\s+only\\s+intercept\\s+and\\s+one-slope"
  )
  # Spatial q2 SD regression was admitted on 2026-11-01; its exact-marginal
  # oracle lives in test-gaussian-spatial-q2-sd.R. Here it only has to build.
  coords <- data.frame(
    a = cos(seq_len(12L)), b = sin(seq_len(12L)),
    row.names = levels(d$id)
  )
  expect_no_error(
    fit(y ~ x + spatial(1 + x | id, coords = coords), sigma ~ 1,
        sd(id, level = "spatial", coef = "(Intercept)") ~ s0,
        sd(id, level = "spatial", coef = "x") ~ s1)
  )
})
