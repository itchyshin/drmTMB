# b26 companion for evidence id
#   native-poisson-animal-slope-ainv-pedigree-sd-20261101
# (test-poisson-animal-slope-ainv-pedigree-sd-regression.R).
#
# Ledger deficiencies addressed:
#   1. The pedigree oracle used drmTMB:::drm_pedigree_additive_relationship, the
#      helper under test. Here A is built by an independent Henderson tabular
#      method written in helper-sb26-oracle.R, compared to the helper, and used
#      in the oracle.
#   2. Rows labelled "intercept plus one independent numeric slope" were only
#      fitted slope-only. Here the pedigree provider is also fitted with
#      animal(1 + x | id) and one SD formula per coefficient.
# Oracle: dense Laplace marginal in base R, evaluated at the fitted parameters,
# tolerance 1e-4 absolute on logLik. Each emulated bug must move the oracle by
# more than 0.1 log-likelihood units. No calibration, coverage or parity claim.

sb26_ped_fixture <- function(seed, n_family = 12L, n_each = 10L) {
  set.seed(seed)
  pedigree <- sb26_inbred_pedigree(n_family)
  A <- sb26_tabular_A(pedigree)
  ids <- rownames(A)
  G <- length(ids)
  w <- stats::setNames(sample(rep(c(-1, 1), length.out = G)), ids)
  v <- stats::setNames(sample(rep(c(-1, 1), each = G / 2L)), ids)
  L <- t(chol(A))
  b0 <- exp(-0.8 + 0.6 * w) * drop(L %*% stats::rnorm(G))
  b1 <- exp(-0.7 - 0.6 * v) * drop(L %*% stats::rnorm(G))
  # Data factor levels in lexical order, deliberately not the pedigree order.
  id <- factor(rep(sort(ids), each = n_each), levels = sort(ids))
  x <- rep(seq(-1.2, 1.2, length.out = n_each), times = G)
  eta <- 0.3 + 0.25 * x + 2.5 * b1[as.character(id)] * x
  eta_q2 <- 0.3 + 0.25 * x + b0[as.character(id)] + b1[as.character(id)] * x
  list(
    pedigree = pedigree, A = A, ids = ids, w = w, v = v,
    data_slope = data.frame(y = stats::rpois(length(eta), exp(eta)), x = x,
                            id = id, w = unname(w[as.character(id)]),
                            v = unname(v[as.character(id)])),
    data_q2 = data.frame(y = stats::rpois(length(eta_q2), exp(eta_q2)), x = x,
                         id = id, w = unname(w[as.character(id)]),
                         v = unname(v[as.character(id)]))
  )
}

test_that("tabular pedigree A agrees with the package helper and is non-trivial", {
  fx <- sb26_ped_fixture(20261201L)
  A_pkg <- drmTMB:::drm_pedigree_additive_relationship(fx$pedigree)
  ids <- fx$ids
  expect_setequal(rownames(A_pkg), ids)
  expect_equal(unname(A_pkg[ids, ids]), unname(fx$A), tolerance = 1e-12)
  expect_equal(max(diag(fx$A)), 1.25, tolerance = 1e-12)
  expect_gt(sum(diag(fx$A) > 1), 0L)
  # cov2cor(A) differs from A, so the emulated bug below is observable.
  expect_gt(max(abs(stats::cov2cor(fx$A) - fx$A)), 0.2)
})

test_that("Poisson pedigree slope-only SD regression matches an independent-A oracle", {
  skip_on_cran()
  fx <- sb26_ped_fixture(20261201L)
  pedigree <- fx$pedigree
  d <- fx$data_slope
  fit <- drmTMB(
    bf(y ~ x + animal(0 + x | id, pedigree = pedigree),
       sd(id, level = "animal") ~ v),
    family = stats::poisson(), data = d, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  expect_named(coef(fit, "sd_animal(id)"), c("(Intercept)", "v"))
  lev <- levels(d$id)
  idx <- as.integer(d$id)
  a <- coef(fit, "sd_animal(id)")
  beta <- coef(fit, "mu")
  eta_fixed <- beta[[1L]] + beta[[2L]] * d$x
  oracle <- function(A, s) {
    sb26_laplace(sb26_deriv_poisson(d$y), eta_fixed,
                 sb26_Z(idx, length(lev), s, d$x), A[lev, lev])
  }
  s_hat <- exp(a[[1L]] + a[[2L]] * fx$v[lev])
  names(s_hat) <- lev
  ref <- oracle(fx$A, s_hat)
  expect_lt(abs(as.numeric(logLik(fit)) - ref), 1e-4)

  # Emulated bugs.
  expect_gt(abs(oracle(stats::cov2cor(fx$A), s_hat) - ref), 0.1)
  expect_gt(abs(oracle(fx$A, sb26_reverse(s_hat)) - ref), 0.1)
  s_flip <- exp(a[[1L]] - a[[2L]] * fx$v[lev])
  expect_gt(abs(oracle(fx$A, s_flip) - ref), 0.1)
  A_pos <- fx$A
  dimnames(A_pos) <- list(lev, lev)  # pedigree order read as factor order
  expect_gt(abs(oracle(A_pos, s_hat) - ref), 0.1)
})

test_that("Poisson pedigree intercept-plus-slope SD regression matches an independent-A oracle", {
  skip_on_cran()
  fx <- sb26_ped_fixture(20261202L)
  pedigree <- fx$pedigree
  d <- fx$data_q2
  fit <- drmTMB(
    bf(y ~ x + animal(1 + x | id, pedigree = pedigree),
       sd(id, level = "animal", dpar = "mu", coef = "(Intercept)") ~ w,
       sd(id, level = "animal", dpar = "mu", coef = "x") ~ v),
    family = stats::poisson(), data = d, control = drm_control(se = FALSE)
  )
  expect_equal(fit$opt$convergence, 0L)
  lev <- levels(d$id)
  G <- length(lev)
  idx <- as.integer(d$id)
  k0 <- coef(fit, 'sd_animal(id, dpar = "mu", coef = "(Intercept)")')
  k1 <- coef(fit, 'sd_animal(id, dpar = "mu", coef = "x")')
  expect_named(k0, c("(Intercept)", "w"))
  expect_named(k1, c("(Intercept)", "v"))
  beta <- coef(fit, "mu")
  eta_fixed <- beta[[1L]] + beta[[2L]] * d$x
  curve <- function(k, z) {
    s <- exp(k[[1L]] + k[[2L]] * z[lev])
    names(s) <- lev
    s
  }
  s0 <- curve(k0, fx$w)
  s1 <- curve(k1, fx$v)
  expect_gt(stats::sd(log(s0)), 0.1)
  expect_gt(stats::sd(log(s1)), 0.1)
  oracle <- function(A, s0, s1) {
    Ak <- A[lev, lev]
    sb26_laplace(sb26_deriv_poisson(d$y), eta_fixed,
                 cbind(sb26_Z(idx, G, s0), sb26_Z(idx, G, s1, d$x)),
                 sb26_blockdiag(Ak, Ak))
  }
  ref <- oracle(fx$A, s0, s1)
  expect_lt(abs(as.numeric(logLik(fit)) - ref), 1e-4)

  # Emulated bugs: swapped selectors, reversed per-level SDs, cov2cor(A),
  # factor-order reading of the pedigree matrix.
  expect_gt(abs(oracle(fx$A, s1, s0) - ref), 0.1)
  expect_gt(abs(oracle(fx$A, sb26_reverse(s0), sb26_reverse(s1)) - ref), 0.1)
  expect_gt(abs(oracle(stats::cov2cor(fx$A), s0, s1) - ref), 0.1)
  A_pos <- fx$A
  dimnames(A_pos) <- list(lev, lev)
  expect_gt(abs(oracle(A_pos, s0, s1) - ref), 0.1)
})
