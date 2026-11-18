# Issue #1703. On the bivariate Gaussian q = 4 location-slope block,
# maximised logLik(relmat(K)) and logLik(relmat(Q = solve(K))) can differ by
# about 0.003 when nlminb and the BFGS fallback stop at different points on a
# flat unstructured-correlation ridge. Shinichi's choice (10 Nov 2026,
# option 1) is to compare the objective at one fixed parameter vector.
# Option 2, treating that gap as a failed maximised-logLik match, is not the
# contract. The tolerance stays 1e-5.

new_fix_1703_biv_q4_fixture <- function(seed = 2026052111) {
  set.seed(seed)
  n_id <- 12L
  n_each <- 7L
  id_levels <- paste0("id", seq_len(n_id))
  K <- outer(seq_len(n_id), seq_len(n_id), function(i, j) 0.32^abs(i - j))
  diag(K) <- diag(K) + 0.12
  dimnames(K) <- list(id_levels, id_levels)
  id <- rep(id_levels, each = n_each)
  x <- rep(seq(-1, 1, length.out = n_each), n_id)
  z <- rep(rep(c(-0.5, 0.5), length.out = n_each), n_id)
  y1 <- 0.20 + 0.28 * x + stats::rnorm(length(id), sd = 0.4)
  y2 <- -0.15 - 0.22 * x + stats::rnorm(length(id), sd = 0.4)
  list(
    data = data.frame(y1 = y1, y2 = y2, x = x, z = z, id = id),
    K = K,
    Q = solve(K)
  )
}

fix_1703_assign_named <- function(par, name, value) {
  idx <- which(names(par) == name)
  if (length(idx) != length(value)) {
    stop(
      sprintf(
        "%s has length %d; expected %d",
        name,
        length(idx),
        length(value)
      ),
      call. = FALSE
    )
  }
  par[idx] <- value
  par
}

fix_1703_fixed_par <- function(template) {
  par <- template
  par[] <- 0
  par <- fix_1703_assign_named(par, "beta_mu1", c(0.20, 0.28))
  par <- fix_1703_assign_named(par, "beta_mu2", c(-0.15, -0.22))
  par <- fix_1703_assign_named(par, "beta_sigma1", c(-1.05, 0.12))
  par <- fix_1703_assign_named(par, "beta_sigma2", c(-1.10, -0.10))
  par <- fix_1703_assign_named(par, "beta_rho12", -0.08)
  par <- fix_1703_assign_named(par, "log_sd_phylo", log(c(0.42, 0.36, 0.25, 0.20)))
  par <- fix_1703_assign_named(
    par,
    "theta_phylo",
    c(0.20, -0.10, 0.05, 0.15, -0.20, 0.08)
  )
  par
}

test_that("bivariate Gaussian relmat(K) and relmat(Q=solve(K)) match at a fixed parameter vector (#1703)", {
  sim <- new_fix_1703_biv_q4_fixture()
  dat <- sim$data
  K <- sim$K
  Q <- sim$Q
  control <- drm_control(
    se = FALSE,
    fallback_optimizer = "BFGS",
    optimizer = list(eval.max = 350, iter.max = 350)
  )
  fit_K <- suppressWarnings(
    drmTMB(
      bf(
        mu1 = y1 ~ x + relmat(1 + x | p | id, K = K),
        mu2 = y2 ~ x + relmat(1 + x | p | id, K = K),
        sigma1 = ~z,
        sigma2 = ~z,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      control = control
    )
  )
  fit_Q <- suppressWarnings(
    drmTMB(
      bf(
        mu1 = y1 ~ x + relmat(1 + x | p | id, Q = Q),
        mu2 = y2 ~ x + relmat(1 + x | p | id, Q = Q),
        sigma1 = ~z,
        sigma2 = ~z,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = dat,
      control = control
    )
  )

  expect_identical(names(fit_K$opt$par), names(fit_Q$opt$par))
  fixed_par <- fix_1703_fixed_par(fit_K$opt$par)
  objective_K <- as.numeric(fit_K$obj$fn(fixed_par))
  objective_Q <- as.numeric(fit_Q$obj$fn(fixed_par))
  expect_true(is.finite(objective_K))
  expect_true(is.finite(objective_Q))
  expect_equal(objective_Q, objective_K, tolerance = 1e-5)

  # The same vector held fixed, including each fit's own reported parameters.
  # Maximised logLik values are not the equivalence check.
  expect_equal(
    as.numeric(fit_Q$obj$fn(fit_K$opt$par)),
    as.numeric(fit_K$obj$fn(fit_K$opt$par)),
    tolerance = 1e-5
  )
  expect_equal(
    as.numeric(fit_K$obj$fn(fit_Q$opt$par)),
    as.numeric(fit_Q$obj$fn(fit_Q$opt$par)),
    tolerance = 1e-5
  )
})
