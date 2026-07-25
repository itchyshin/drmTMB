# Arc B slice S3: CondExp branch-continuity and AD-safety audit.
#
# Scope: every `CppAD::CondExp*` site in src/drmTMB.cpp and the drm_*.h
# headers. Each site is declared a smoothness class BEFORE testing (see the
# per-`test_that` header comments), because a blanket "value and derivative
# must both be continuous" is false by design for the guard/floor sites: a
# floor that clamps a shape parameter or a normalizing constant is meant to
# have a derivative that jumps to zero once the floor engages. Asserting C1
# there would red-flag a deliberate, correct guard. Only the series/direct
# approximation switches (drm_log1mexp, the NB2 series, drm_log1p_nonnegative)
# and the identity-preserving softclamp are expected to be C1.
#
# Pre-registered tolerances (fixed before any result was inspected):
#   VALUE_TOL <- 1e-9   (relative, value continuity, every site)
#   DERIV_TOL <- 1e-6   (relative, first-derivative continuity, C1 sites only)
# A finite-difference cross-check at two step sizes is also run for the three
# series/direct sites; it is corroborating evidence (its own, looser,
# truncation-scaled tolerance), never the primary gate -- the primary gate is
# always the analytic derivative of each closed-form branch, which avoids the
# catastrophic-cancellation noise that a too-small finite-difference step
# would inject right at these thresholds (that noise is exactly why the
# series branches exist).
#
# No skip_*() anywhere in this file.

VALUE_TOL <- 1e-9
DERIV_TOL <- 1e-6

rel_diff <- function(a, b) abs(a - b) / abs(b)

# The C++ sources sit at different relative locations depending on how this
# suite is invoked: `../../src` from a source checkout (devtools::test,
# test_dir), but `../../00_pkg_src/<pkg>/src` under `R CMD check`, which runs
# tests from `<pkg>.Rcheck/tests/`. Resolve against both rather than assuming
# the checkout layout -- assuming it passed under test_dir and ERRORed under
# R CMD check, which is exactly how this was caught.
#
# Deliberately no skip_*(): if no candidate resolves, fail loudly. A drift
# guard that quietly opts out when it cannot find its subject is worse than no
# guard at all.
drm_src_path <- function(rel) {
  candidates <- c(
    testthat::test_path("..", "..", "src", rel),
    testthat::test_path("..", "..", "00_pkg_src", "drmTMB", "src", rel)
  )
  hit <- candidates[file.exists(candidates)]
  if (length(hit) == 0L) {
    stop(
      "Cannot locate C++ source '", rel, "'. Tried:\n  ",
      paste(candidates, collapse = "\n  "),
      call. = FALSE
    )
  }
  hit[[1L]]
}

read_src <- function(rel) {
  readLines(drm_src_path(rel), warn = FALSE)
}

# ---------------------------------------------------------------------------
# Part A anchor: the enumeration this suite is built against. If a future
# edit adds/removes a CondExp site, this count changes and flags that the
# enumeration (and this suite) needs revisiting -- it is not a correctness
# check on its own, just a drift guard.
# ---------------------------------------------------------------------------
test_that("the CondExp enumeration this suite audits has not silently drifted", {
  n_cpp <- sum(grepl("CppAD::CondExp", read_src("drmTMB.cpp")))
  n_numeric <- sum(grepl("CppAD::CondExp", read_src("drm_numeric.h")))
  n_count <- sum(grepl("CppAD::CondExp", read_src("drm_count_kernels.h")))
  n_response <- sum(grepl("CppAD::CondExp", read_src("drm_response_kernels.h")))

  expect_equal(n_cpp, 21L)
  expect_equal(n_numeric, 2L)
  expect_equal(n_count, 1L)
  expect_equal(n_response, 2L)
})

# ---------------------------------------------------------------------------
# Site: drm_log1mexp (src/drm_numeric.h:28-35), threshold u = 1e-6.
# Class: C1 expected. Per the recon pass this threshold is already measured
# and defensible (naive vs exact log(1-exp(-u)) over u in [1e-7,1e-1]: max
# rel error 3.0e-11); this test only confirms the two branches are still
# consistent at the switch point (a regression guard), it does not
# re-investigate the threshold choice.
# ---------------------------------------------------------------------------
test_that("drm_log1mexp: series and direct branches agree at u = 1e-6 (confirm and close)", {
  u0 <- 1e-6
  series_val <- log(u0 - u0^2 / 2 + u0^3 / 6)
  direct_val <- log(1 - exp(-u0))
  series_der <- (1 - u0 + u0^2 / 2) / (u0 - u0^2 / 2 + u0^3 / 6)
  direct_der <- exp(-u0) / (1 - exp(-u0))

  expect_lt(rel_diff(series_val, direct_val), VALUE_TOL)
  expect_lt(rel_diff(series_der, direct_der), DERIV_TOL)

  # Corroborating finite-difference cross-check at two step sizes (moderate,
  # away from the cancellation regime the series branch exists to avoid).
  f_series <- function(u) log(u - u^2 / 2 + u^3 / 6)
  f_direct <- function(u) log(1 - exp(-u))
  for (h in c(1e-2 * u0, 1e-3 * u0)) {
    fd_s <- (f_series(u0 + h) - f_series(u0 - h)) / (2 * h)
    fd_d <- (f_direct(u0 + h) - f_direct(u0 - h)) / (2 * h)
    expect_lt(rel_diff(fd_s, fd_d), 1e-4)
  }
})

# ---------------------------------------------------------------------------
# Site: drm_log1p_nonnegative (src/drm_numeric.h:19-25), threshold x = 1e-5.
# Class: C1 expected.
# ---------------------------------------------------------------------------
test_that("drm_log1p_nonnegative: series and direct branches are C1 at x = 1e-5", {
  x0 <- 1e-5
  series_val <- x0 - x0^2 / 2 + x0^3 / 3
  direct_val <- log(1 + x0)
  series_der <- 1 - x0 + x0^2
  direct_der <- 1 / (1 + x0)

  expect_lt(rel_diff(series_val, direct_val), VALUE_TOL)
  expect_lt(rel_diff(series_der, direct_der), DERIV_TOL)

  f_series <- function(x) x - x^2 / 2 + x^3 / 3
  f_direct <- function(x) log(1 + x)
  for (h in c(1e-2 * x0, 1e-3 * x0)) {
    fd_s <- (f_series(x0 + h) - f_series(x0 - h)) / (2 * h)
    fd_d <- (f_direct(x0 + h) - f_direct(x0 - h)) / (2 * h)
    expect_lt(rel_diff(fd_s, fd_d), 1e-4)
  }
})

# ---------------------------------------------------------------------------
# Site: NB2 count-normalizer series (src/drm_count_kernels.h:6-27), threshold
# alpha * y = 1e-2. Class: C1 expected. This is also the switch implicated in
# Part D below.
# ---------------------------------------------------------------------------
nb2_series <- function(alpha, y) {
  y1 <- y - 1
  sj <- y * y1 / 2
  sj2 <- y * y1 * (2 * y - 1) / 6
  sj3 <- sj^2
  sj4 <- y * y1 * (2 * y - 1) * (3 * y^2 - 3 * y - 1) / 30
  sj5 <- y^2 * y1^2 * (2 * y^2 - 2 * y - 1) / 12
  a2 <- alpha^2
  alpha * sj - a2 * sj2 / 2 + a2 * alpha * sj3 / 3 -
    a2 * a2 * sj4 / 4 + a2 * a2 * alpha * sj5 / 5
}
nb2_lgamma_ratio <- function(alpha, y) {
  inv_a <- 1 / alpha
  lgamma(y + inv_a) - lgamma(inv_a) + y * log(alpha)
}

test_that("NB2 series and lgamma-ratio branches are C1 at alpha * y = 1e-2", {
  y0 <- 5
  alpha0 <- 1e-2 / y0
  series_val <- nb2_series(alpha0, y0)
  lr_val <- nb2_lgamma_ratio(alpha0, y0)
  y1 <- y0 - 1
  sj <- y0 * y1 / 2
  sj2 <- y0 * y1 * (2 * y0 - 1) / 6
  sj3 <- sj^2
  sj4 <- y0 * y1 * (2 * y0 - 1) * (3 * y0^2 - 3 * y0 - 1) / 30
  sj5 <- y0^2 * y1^2 * (2 * y0^2 - 2 * y0 - 1) / 12
  series_der <- sj - alpha0 * sj2 + alpha0^2 * sj3 - alpha0^3 * sj4 + alpha0^4 * sj5
  inv_a <- 1 / alpha0
  lr_der <- (-1 / alpha0^2) * (digamma(y0 + inv_a) - digamma(inv_a)) + y0 / alpha0

  expect_lt(rel_diff(series_val, lr_val), VALUE_TOL)
  expect_lt(rel_diff(series_der, lr_der), DERIV_TOL)

  for (h in c(1e-2 * alpha0, 1e-3 * alpha0)) {
    fd_s <- (nb2_series(alpha0 + h, y0) - nb2_series(alpha0 - h, y0)) / (2 * h)
    fd_d <- (nb2_lgamma_ratio(alpha0 + h, y0) - nb2_lgamma_ratio(alpha0 - h, y0)) / (2 * h)
    expect_lt(rel_diff(fd_s, fd_d), 1e-4)
  }
})

# ---------------------------------------------------------------------------
# Site: drm_softclamp_log_sigma (src/drmTMB.cpp:26-36). Class: C1 by
# construction (hi + margin*tanh((x-hi)/margin) equals hi with derivative 1
# at x = hi, algebraically). Expected to pass; confirmed both analytically
# and through the compiled model's own REPORT(log_sigma).
# ---------------------------------------------------------------------------
test_that("drm_softclamp_log_sigma is C1 by construction at the hi/lo boundary", {
  softclamp_above <- function(x, hi, margin) hi + margin * tanh((x - hi) / margin)
  hi <- 12
  margin <- 3
  expect_equal(softclamp_above(hi, hi, margin), hi, tolerance = 1e-15)
  h <- 1e-6
  der_below <- 1 # identity branch, exact
  der_above <- (softclamp_above(hi + h, hi, margin) - softclamp_above(hi - h, hi, margin)) / (2 * h)
  expect_lt(abs(der_above - der_below), 1e-9)
})

test_that("drm_softclamp_log_sigma keeps REPORT(log_sigma) within the clamped band from the public API", {
  set.seed(1)
  n <- 20
  dat <- data.frame(y = stats::rpois(n, 3))
  fit <- allow_nonconvergence(drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 1, iter.max = 1)
    )
  ))
  par0 <- fit$obj$par
  sig_idx <- which(names(par0) == "beta_sigma")

  # Sweep the raw (unconstrained) intercept dense across the upper boundary
  # hi = 12 (margin 3, saturating band (-15, 15)) and confirm the reported,
  # post-clamp log_sigma is continuous.
  grid <- seq(12 - 1.2, 12 + 1.2, length.out = 41)
  reported <- vapply(grid, function(v) {
    par <- par0
    par[sig_idx] <- v
    fit$obj$report(par)$log_sigma[[1]]
  }, numeric(1))
  step <- diff(grid)[[1]]
  jumps <- abs(diff(reported))
  expect_true(all(jumps < 5 * step)) # no discontinuity: consecutive steps stay O(step)
  expect_true(all(reported <= 15 + 1e-8))
})

# ---------------------------------------------------------------------------
# Site: beta_shape_floor (src/drmTMB.cpp:2901-2910, byte-identical at
# 2984-2993, 1363-1374, 1479-1490, 1618-1629, and
# src/drm_response_kernels.h:64-67 -- verified identical via the shared
# `shape_floor`/`beta_shape_floor` constant and CondExpLt form). Class: C0
# only. Both CondExp branches equal the floor constant exactly at the switch
# point (`alpha_raw == shape_floor`), so value continuity holds by
# construction; a derivative jump from 1 (identity branch) to 0 (floor
# branch) is expected and is NOT asserted.
# ---------------------------------------------------------------------------
test_that("beta_shape_floor: REPORT(alpha) is continuous at alpha_raw = 1e-8 from the public API", {
  set.seed(1)
  n <- 20
  dat <- data.frame(y = stats::rbeta(n, 5, 5))
  fit <- allow_nonconvergence(drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = beta(),
    data = dat,
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 1, iter.max = 1)
    )
  ))
  par0 <- fit$obj$par
  par0[names(par0) == "beta_mu"] <- 0 # eta_mu = 0 -> mu = 0.5 exactly
  sig_idx <- which(names(par0) == "beta_sigma")

  # alpha_raw = mu * phi = 0.5 * exp(-2*log_sigma) crosses 1e-8 at:
  target <- -0.5 * log(1e-8 / 0.5)

  for (h in c(1e-2, 1e-5)) {
    par_below <- par0
    par_below[sig_idx] <- target - h
    par_above <- par0
    par_above[sig_idx] <- target + h
    a_below <- fit$obj$report(par_below)$alpha[[1]]
    a_above <- fit$obj$report(par_above)$alpha[[1]]
    # Both sides sit at (or a hair below/above) the floor: value gap must
    # shrink with h, not sit at a fixed offset.
    expect_lt(abs(a_below - a_above), 5 * h * 1e-8)
  }
  # At the floor itself, alpha_raw and shape_floor are numerically identical.
  par_at <- par0
  par_at[sig_idx] <- target
  expect_equal(fit$obj$report(par_at)$alpha[[1]], 1e-8, tolerance = VALUE_TOL)
})

# ---------------------------------------------------------------------------
# Site: prior_norm floor (src/drmTMB.cpp:1437-1438, byte-identical at
# 1583-1584, 1764-1765, 1850-1851, 1955-1956, 2031-2032, 2119-2120,
# 2213-2214 -- eight occurrences, all `CondExpGt(prior_norm, 1e-300,
# prior_norm, 1e-300)`, verified identical via grep). Class: C0 only. As
# above, both branches equal the constant exactly at the switch, so value
# continuity holds by construction; a derivative jump to zero on the floored
# side is expected and not asserted. Tested here through the actual
# mi()-quadrature branch that computes prior_norm (both predictor and
# response missing on the same row), reading the downstream REPORT(mi_x_full)
# imputed value, which is what a user-facing bug would actually corrupt.
# ---------------------------------------------------------------------------
test_that("prior_norm floor: REPORT(mi_x_full) stays finite and continuous as prior_norm crosses 1e-300", {
  set.seed(1)
  n <- 40
  z <- seq(-1.5, 1.5, length.out = n)
  cover <- stats::plogis(-0.2 + 0.8 * z)
  y <- 0.3 + 1.1 * cover - 0.2 * z + stats::rnorm(n, 0, 0.05)
  dat <- data.frame(y = y, z = z, cover = cover)
  both_missing <- c(5, 15, 25)
  dat$cover[both_missing] <- NA_real_
  dat$y[both_missing] <- NA_real_

  fit <- allow_nonconvergence(drmTMB(
    bf(y ~ z + mi(cover), sigma ~ 1),
    data = dat,
    impute = list(cover = impute_model(cover ~ z, family = beta())),
    missing = miss_control(response = "include", predictor = "model"),
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 1, iter.max = 1)
    )
  ))
  mp <- fit$model$missing_predictor
  nodes <- mp$quad_nodes
  weights <- mp$quad_weights
  target_row <- both_missing[[1]]
  z_row <- dat$z[[target_row]]

  par0 <- fit$obj$par
  beta_mi_idx <- which(names(par0) == "beta_mi")
  log_sigma_mi_idx <- which(names(par0) == "log_sigma_mi")
  b0 <- unname(par0[beta_mi_idx[[1]]])
  bz <- unname(par0[beta_mi_idx[[2]]])

  # Mirror of the C++ prior_norm computation (src/drmTMB.cpp:1419-1432),
  # used only to LOCATE the crossing coefficient; the actual continuity
  # assertion below reads TMB's own REPORT(mi_x_full), not this mirror.
  prior_norm_r <- function(log_sigma_mi) {
    eta <- b0 + bz * z_row
    eps <- 1e-12
    mu <- eps + (1 - 2 * eps) * stats::plogis(eta)
    phi <- 1 / exp(log_sigma_mi)^2
    floor_ <- 1e-8
    alpha <- pmax(mu * phi, floor_)
    beta_ <- pmax((1 - mu) * phi, floor_)
    log_dens <- lgamma(alpha + beta_) - lgamma(alpha) - lgamma(beta_) +
      (alpha - 1) * log(nodes) + (beta_ - 1) * log(1 - nodes)
    sum(weights * exp(log_dens))
  }
  root_fn <- function(ls) log(prior_norm_r(ls) + 1e-320) - log(1e-300)
  target <- stats::uniroot(root_fn, c(-20, 5), tol = 1e-10)$root

  # This region is hyper-exponentially steep in log_sigma_mi (the underlying
  # beta density concentrates), so a coarse fixed-width grid can straddle the
  # whole 0 -> nonzero transition inside a single step and look like a jump
  # when it is not one. Zoom to a window narrow enough to resolve it: a real
  # discontinuity stays a hard 2-level step no matter how much the grid is
  # refined, whereas a steep-but-smooth transition resolves into a continuum
  # of intermediate values.
  win <- 0.035
  grid <- seq(target - win, target + win, length.out = 41)
  reported <- vapply(grid, function(ls) {
    par <- par0
    par[log_sigma_mi_idx] <- ls
    fit$obj$report(par)$mi_x_full[[target_row]]
  }, numeric(1))
  expect_true(all(is.finite(reported)))
  expect_true(all(diff(reported) >= -1e-12)) # monotone in this window, no oscillation
  n_interior <- sum(reported > min(reported) + 1e-15 & reported < max(reported) - 1e-15)
  expect_gt(n_interior, 10) # a real continuum of intermediate values, not a 2-level step
})

# ---------------------------------------------------------------------------
# Site: max_eta running-max for the categorical mi() logsumexp
# (src/drmTMB.cpp:1284-1286). Not a series/direct or floor switch: it is a
# numerically-stable log-sum-exp (softmax normalizer), where
# log(sum_i exp(eta_i)) = M + log(sum_i exp(eta_i - M)) is an exact algebraic
# identity for ANY M, so the reported quantity is invariant to which state's
# eta the running-max CondExp happens to select. Class: C-infinity by
# algebraic identity (stronger than C1-expected); confirmed here across a
# genuine argmax tie between two states.
# ---------------------------------------------------------------------------
test_that("categorical mi() state-probability logsumexp is smooth across an argmax tie", {
  set.seed(1)
  n <- 30
  z <- seq(-1.5, 1.5, length.out = n)
  score <- 0.4 * z
  habitat_full <- factor(
    ifelse(score < -0.2, "forest", ifelse(score < 0.3, "grass", "wetland")),
    levels = c("forest", "grass", "wetland")
  )
  y <- 0.2 + 0.5 * z + stats::rnorm(n, 0, 0.1)
  dat <- data.frame(y = y, z = z, habitat = habitat_full)
  miss_rows <- c(5, 15, 25)
  dat$habitat[miss_rows] <- NA

  fit <- allow_nonconvergence(drmTMB(
    bf(y ~ z + mi(habitat), sigma ~ 1),
    data = dat,
    impute = list(habitat = impute_model(habitat ~ z, family = categorical())),
    missing = miss_control(predictor = "model"),
    control = drm_control(
      se = FALSE,
      optimizer = list(eval.max = 1, iter.max = 1)
    )
  ))
  par0 <- fit$obj$par
  mi_idx <- which(names(par0) == "beta_mi")
  target_row <- miss_rows[[1]]
  z_row <- dat$z[[target_row]]

  # beta_mi layout: [state1_intercept, state1_z, state2_intercept, state2_z].
  # Solve for the state2 intercept that ties eta_state(1) == eta_state(2) at
  # this row, forcing the running-max CondExp to switch which state it
  # selects as the max.
  eta1 <- par0[[mi_idx[[1]]]] + par0[[mi_idx[[2]]]] * z_row
  target <- eta1 - par0[[mi_idx[[4]]]] * z_row

  for (h in c(1e-3, 1e-6)) {
    par_below <- par0
    par_below[mi_idx[[3]]] <- target - h
    par_above <- par0
    par_above[mi_idx[[3]]] <- target + h
    prob_below <- fit$obj$report(par_below)$mi_state_probability[target_row, ]
    prob_above <- fit$obj$report(par_above)$mi_state_probability[target_row, ]
    expect_true(all(is.finite(prob_below)))
    expect_true(all(is.finite(prob_above)))
    expect_lt(max(abs(prob_below - prob_above)), 50 * h) # shrinks with h: smooth, not a jump
  }
})

# ---------------------------------------------------------------------------
# Part D: NB2 unselected-branch NaN hazard, drm_nbinom2_log_count_product
# (src/drm_count_kernels.h:6-28). Hypothesis: for alpha lesssim 1e-154
# (log_sigma lesssim -177, since alpha = exp(2*log_sigma) + 1e-300), the
# unselected lgamma_ratio branch's inv_alpha = 1/alpha node has reverse-mode
# local derivative -1/alpha^2 -> -Inf, multiplied by the CondExp-selected
# zero adjoint of the unselected branch, giving 0 * (-Inf) = NaN that would
# poison d(nll)/d(log_sigma).
# ---------------------------------------------------------------------------
test_that("nbinom2 REPORT(log_sigma) is bounded by the default softclamp even at an extreme raw intercept", {
  set.seed(1)
  n <- 20
  dat <- data.frame(y = stats::rpois(n, 3))
  fit <- allow_nonconvergence(drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = drm_control(se = FALSE, optimizer = list(eval.max = 1, iter.max = 1))
    # logsigma_clamp left at its drm_control() default, c(-12, 12), margin 3
    # -> saturating band (-15, 15). This is the default public-API config.
  ))
  par <- fit$obj$par
  par[names(par) == "beta_sigma"] <- -177
  reported <- fit$obj$report(par)$log_sigma[[1]]
  expect_true(is.finite(reported))
  expect_gt(reported, -15 - 1e-6) # never reaches the hazard region by default
  g <- fit$obj$gr(par)
  expect_false(anyNA(g))
  expect_true(all(is.finite(g)))
})

test_that("Part D: with the softclamp explicitly disabled, log_sigma = -177 IS reachable, and obj$gr stays finite", {
  set.seed(1)
  n <- 20
  dat <- data.frame(y = stats::rpois(n, 3))
  fit <- allow_nonconvergence(drmTMB(
    bf(y ~ 1, sigma ~ 1),
    family = nbinom2(),
    data = dat,
    control = drm_control(
      se = FALSE,
      logsigma_clamp = NULL, # user explicitly disables the guard
      optimizer = list(eval.max = 1, iter.max = 1)
    )
  ))
  par0 <- fit$obj$par
  sig_idx <- names(par0) == "beta_sigma"

  for (log_sigma_val in c(-177, -200, -400)) {
    par <- par0
    par[sig_idx] <- log_sigma_val
    reported <- fit$obj$report(par)$log_sigma[[1]]
    expect_equal(reported, log_sigma_val) # confirms the hazard region really is reached

    fn <- fit$obj$fn(par)
    g <- fit$obj$gr(par)
    expect_true(is.finite(fn))
    expect_false(anyNA(g))
    expect_true(all(is.finite(g)))
  }
})
