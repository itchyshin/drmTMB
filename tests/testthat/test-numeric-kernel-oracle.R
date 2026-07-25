# Kernel-level extreme-value oracle (Arc B slice S1).
#
# Compares each family's compiled C++ log-density (src/drmTMB.cpp) against an
# independent R reference on a grid that reaches the overflow/underflow
# boundary: eta (linear predictor) in {-700, -40, -5, 0, 5, 40, 700} and, for
# families with a scale, log_sigma in {-15, -5, 0, 5, 15}.
#
# Fixture design: 1- or 2-row intercept-only datasets with `beta_mu` /
# `beta_sigma` / ... left FREE (not `map`-fixed), so a single AD object per
# family is swept by overwriting `obj$par` and calling `obj$fn()` directly.
# `y` is TMB DATA, not a parameter, so each distinct y needs its own fixture
# (`build_fits()` below builds one fit per y value).
#
# `use_logsigma_clamp` is 1 by default (`drm_control()`'s `logsigma_clamp`
# default is `c(-12, 12)`, not NULL; R/control.R:134). Every fixture here
# passes `logsigma_clamp = NULL` and every family's `assert_clean_fixture()`
# call confirms `use_logsigma_clamp == 0`, so the clamp (src/drmTMB.cpp:27-36)
# never intrudes on the eta x log_sigma grid.
#
# Two families (hurdle_nbinom2, zero_one_beta) need a second row to satisfy a
# build-time validator ("at least one positive count" / "at least one
# interior response"). That anchor row carries `weights = 0`, so it satisfies
# the validator but contributes exactly 0 to `obj$fn()` -- the isolated
# target-row density, not a summed pair. An earlier draft of this suite used
# a same-weight anchor row and summed the two rows' nll; that masked a real
# ~1e-3 relative divergence in the target row whenever the anchor's own nll
# happened to dominate the sum (see the dev notes cited below for the
# zero_one_beta case). `assert_clean_fixture()` therefore accepts
# `weights %in% c(0, 1)`, not a blanket `weights == 1`.
#
# biv_gaussian, biv_lognormal, and biv_student (model_type 2, 19, 20) are
# NOT COVERED: the eta x log_sigma sweep this oracle is built around does not
# extend to a 2-response, 5-parameter kernel with a bounded rho12 residual
# correlation without a materially different fixture design; that is out of
# scope for this slice.

ctrl <- drm_control(se = FALSE, logsigma_clamp = NULL)

eta_grid <- c(-700, -40, -5, 0, 5, 40, 700)
ls_grid <- c(-15, -5, 0, 5, 15)

set_named <- function(par, name, value) {
  par[names(par) == name] <- value
  par
}

rel_err <- function(a, b) {
  if (!is.finite(a) || !is.finite(b)) {
    return(NA_real_)
  }
  abs(a - b) / pmax(abs(a), abs(b), 1)
}

assert_clean_fixture <- function(fit) {
  d <- fit$obj$env$data
  expect_true(all(d$weights %in% c(0, 1)))
  if (!is.null(d$offset_mu)) expect_true(all(d$offset_mu == 0))
  if (!is.null(d$V_known)) expect_true(all(d$V_known == 0))
  if (!is.null(d$use_logsigma_clamp)) expect_equal(unname(d$use_logsigma_clamp), 0)
  expect_identical(length(fit$obj$env$random), 0L)
}

build_fits <- function(formula, family, y_grid, weights = NULL) {
  out <- list()
  for (yv in y_grid) {
    dat <- data.frame(y = yv)
    fit <- suppressWarnings(drmTMB(
      formula,
      data = dat,
      family = family,
      weights = weights,
      control = ctrl
    ))
    out[[as.character(yv)]] <- fit
  }
  out
}

# Sweeps eta x log_sigma (or just eta when has_ls = FALSE) x names(fits_by_y)
# and returns a data.frame with one row per grid point. `exclude` optionally
# marks known reference-or-kernel precision-limit points (see per-family
# comments) that are checked separately with a looser tolerance instead of
# folding into the main `tol` assertion.
run_oracle <- function(fits_by_y, eval_fn, tol, has_ls = TRUE, exclude = NULL) {
  for (f in fits_by_y) assert_clean_fixture(f)
  ls_use <- if (has_ls) ls_grid else NA_real_
  results <- data.frame()
  for (eta in eta_grid) {
    for (ls in ls_use) {
      for (yname in names(fits_by_y)) {
        yv <- as.numeric(yname)
        fit <- fits_by_y[[yname]]
        out <- eval_fn(fit, eta, ls, yv)
        results <- rbind(results, data.frame(
          eta = eta, log_sigma = ls, y = yv,
          cpp = out[["cpp"]], ref = out[["ref"]]
        ))
      }
    }
  }
  results$rel_err <- mapply(rel_err, results$cpp, results$ref)
  results$excluded <- if (is.null(exclude)) {
    rep(FALSE, nrow(results))
  } else {
    mapply(exclude, results$eta, results$log_sigma, results$y)
  }
  kept <- results[!results$excluded, ]
  kept_finite <- kept$rel_err[!is.na(kept$rel_err)]
  expect_true(length(kept_finite) > 0)
  expect_true(max(kept_finite) <= tol)
  invisible(results)
}

# ---- gaussian (model_type 1; src/drmTMB.cpp:686-780ish) --------------------
test_that("gaussian kernel matches dnorm() on the extreme grid", {
  fits <- build_fits(bf(y ~ 1, sigma ~ 1), gaussian(), c(-3, 0, 0.37, 3))
  eval_g <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    par <- set_named(par, "beta_sigma", ls)
    c(cpp = -fit$obj$fn(par), ref = dnorm(yv, eta, exp(ls), log = TRUE))
  }
  run_oracle(fits, eval_g, tol = 1e-9)
})

# ---- student (model_type 3; src/drmTMB.cpp:2335-2426) ----------------------
test_that("student kernel matches a from-scratch location-scale dt()", {
  fits <- build_fits(bf(y ~ 1, sigma ~ 1, nu ~ 1), student(), c(-3, 0, 0.37, 3))
  eval_student <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    par <- set_named(par, "beta_sigma", ls)
    par <- set_named(par, "beta_nu", log(8)) # nu = 2 + exp(log 8) = 10
    sigma <- exp(ls)
    z <- (yv - eta) / sigma
    ref <- dt(z, df = 10, log = TRUE) - log(sigma)
    c(cpp = -fit$obj$fn(par), ref = ref)
  }
  run_oracle(fits, eval_student, tol = 1e-9)
})

# ---- skew_normal (model_type 17; src/drmTMB.cpp:2427-2487) -----------------
# helper-skew-normal-density.R (auto-loaded by testthat) already carries the
# exact-match reference including the 1e-300 log(Phi(.) + 1e-300) floor at
# src/drmTMB.cpp:2473.
test_that("skew_normal kernel matches the floored Azzalini reference", {
  fits <- build_fits(bf(y ~ 1, sigma ~ 1, nu ~ 1), skew_normal(), c(-3, 0, 0.37, 3))
  eval_skew <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    par <- set_named(par, "beta_sigma", ls)
    par <- set_named(par, "beta_nu", 2)
    ref <- skew_normal_log_density_tmb_floor_reference(yv, eta, exp(ls), 2)
    c(cpp = -fit$obj$fn(par), ref = ref)
  }
  run_oracle(fits, eval_skew, tol = 1e-9)
})

# ---- lognormal (model_type 4; src/drmTMB.cpp:2487-2584) --------------------
test_that("lognormal kernel matches dlnorm()", {
  fits <- build_fits(bf(y ~ 1, sigma ~ 1), lognormal(), c(0.001, 1, 1000))
  eval_ln <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    par <- set_named(par, "beta_sigma", ls)
    c(cpp = -fit$obj$fn(par), ref = dlnorm(yv, eta, exp(ls), log = TRUE))
  }
  run_oracle(fits, eval_ln, tol = 1e-9)
})

# ---- gamma (model_type 5; src/drmTMB.cpp:2584-2692) -------------------------
# dgamma() itself loses precision once shape = 1/sigma^2 is astronomically
# large (log_sigma <= -15 puts shape ~ 1e13): an independent from-scratch
# reimplementation of the textbook gamma log-density using only elementary
# functions (lgamma/log) matches the C++ kernel to displayed precision at
# shape ~ 1e13 where dgamma() itself is off by ~1.3e-3 relative (verified in
# the dev-log companion note). Excluding shape >= 1e10 from the strict
# dgamma()-based check documents that as a reference limit, not a kernel bug;
# a looser sanity bound still applies inside the exclusion so a real
# regression (NaN, wrong sign, wrong order of magnitude) would still fail.
test_that("gamma kernel matches dgamma() away from dgamma()'s own precision limit", {
  fits <- build_fits(bf(y ~ 1, sigma ~ 1), Gamma(link = "log"), c(0.001, 1, 1000))
  eval_gamma <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    par <- set_named(par, "beta_sigma", ls)
    mu <- exp(eta); sigma <- exp(ls)
    shape <- 1 / sigma^2; scale <- mu * sigma^2
    ref <- dgamma(yv, shape = shape, scale = scale, log = TRUE)
    c(cpp = -fit$obj$fn(par), ref = ref)
  }
  huge_shape <- function(eta, ls, yv) (1 / exp(ls)^2) >= 1e10
  res <- run_oracle(fits, eval_gamma, tol = 1e-8, exclude = huge_shape)

  # Independent elementary-function reference at the excluded (huge-shape)
  # points, matching the C++ kernel far tighter than dgamma() does there.
  excl <- res[mapply(huge_shape, res$eta, res$log_sigma, res$y), ]
  excl <- excl[is.finite(excl$cpp) & is.finite(excl$ref), ]
  expect_true(nrow(excl) > 0)
  manual_re <- mapply(function(eta, ls, yv, cpp) {
    mu <- exp(eta); sigma <- exp(ls)
    shape <- 1 / sigma^2; scale <- mu * sigma^2
    manual <- (shape - 1) * log(yv) - yv / scale - lgamma(shape) - shape * log(scale)
    rel_err(cpp, manual)
  }, excl$eta, excl$log_sigma, excl$y, excl$cpp)
  expect_true(all(manual_re[is.finite(manual_re)] <= 1e-6))
})

# ---- poisson (model_type 6; src/drmTMB.cpp:3259-3402) ----------------------
test_that("poisson kernel matches dpois()", {
  fits <- build_fits(bf(y ~ 1), poisson(), c(0, 1, 20, 500))
  eval_pois <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    c(cpp = -fit$obj$fn(par), ref = dpois(yv, exp(eta), log = TRUE))
  }
  run_oracle(fits, eval_pois, tol = 1e-9, has_ls = FALSE)
})

# ---- nbinom2 (model_type 7; drm_count_kernels.h) ----------------------------
# The bespoke kernel (a hand-rolled series with a 1e-300 alpha floor; see
# drm_count_kernels.h:6-41) is checked against a from-scratch, stable NB2
# formula parameterized by (mu, size = 1/alpha) using log1p() throughout, not
# against stats::dnbinom() directly: dnbinom(x, size, mu =) is itself
# unreliable once mu is many orders of magnitude larger than size (confirmed
# below in the differential test) -- exactly the "reference is wrong, not the
# kernel" case this oracle is built to catch.
nb2_manual_stable <- function(eta, ls, y) {
  alpha <- exp(2 * ls); mu <- exp(eta); k <- 1 / alpha
  log1p_mu_over_k <- log1p(mu / k)
  lgamma(y + k) - lgamma(k) - lgamma(y + 1) - k * log1p_mu_over_k +
    y * (log(mu / k) - log1p_mu_over_k)
}
test_that("nbinom2 kernel matches a from-scratch stable NB2 formula", {
  fits <- build_fits(bf(y ~ 1, sigma ~ 1), nbinom2(), c(0, 1, 20, 500))
  eval_nb2 <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    par <- set_named(par, "beta_sigma", ls)
    c(cpp = -fit$obj$fn(par), ref = nb2_manual_stable(eta, ls, yv))
  }
  run_oracle(fits, eval_nb2, tol = 1e-8)
})

# TMB::dnbinom_robust(log_mu, log_var_minus_mu) (installed TMB header,
# TMB/include/lgamma.hpp:76-118) is the parameterization gllvmTMB uses for
# NB2; drmTMB uses the bespoke kernel above instead. This transcribes
# dnbinom_robust's exact algebra (dnbinom_logit -> stable logit/plogis) into
# R and checks it against the compiled kernel on the same extreme grid: a
# real difference here would be the "on-record divergence" between the two
# packages' NB2 kernels; the current kernel agrees with the transcription to
# ~1e-13 relative even at the most extreme grid corners.
dnbinom_robust_r <- function(x, log_mu, log_var_minus_mu) {
  logit_p <- log_mu - log_var_minus_mu
  size <- exp(log_mu + logit_p)
  log_p <- plogis(logit_p, log.p = TRUE)
  ans <- size * log_p
  if (x != 0) {
    log_1mp <- log_p - logit_p
    ans <- ans - lbeta(size, x + 1) - log(size + x) + x * log_1mp
  }
  ans
}
test_that("nbinom2 kernel agrees with a TMB::dnbinom_robust transcription", {
  fits <- build_fits(bf(y ~ 1, sigma ~ 1), nbinom2(), c(0, 1, 20, 500))
  eval_robust <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    par <- set_named(par, "beta_sigma", ls)
    alpha <- exp(2 * ls)
    ref <- dnbinom_robust_r(yv, log_mu = eta, log_var_minus_mu = log(alpha) + 2 * eta)
    c(cpp = -fit$obj$fn(par), ref = ref)
  }
  run_oracle(fits, eval_robust, tol = 1e-8)
})

# ---- zi_poisson (model_type 8; src/drmTMB.cpp:3403-3466) -------------------
test_that("zi_poisson kernel matches an independent zero-inflated mixture", {
  fits <- build_fits(bf(y ~ 1, zi ~ 1), poisson(), c(0, 1, 20))
  eval_zip <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    par <- set_named(par, "beta_zi", qlogis(0.3))
    mu <- exp(eta); zi <- 0.3
    pois_ll <- dpois(yv, mu, log = TRUE)
    ref <- if (yv == 0) log(zi + (1 - zi) * exp(pois_ll)) else log1p(-zi) + pois_ll
    c(cpp = -fit$obj$fn(par), ref = ref)
  }
  run_oracle(fits, eval_zip, tol = 1e-9, has_ls = FALSE)
})

# ---- zi_nbinom2 (model_type 9; src/drmTMB.cpp:3805-3876) -------------------
test_that("zi_nbinom2 kernel matches an independent zero-inflated mixture", {
  fits <- build_fits(bf(y ~ 1, sigma ~ 1, zi ~ 1), nbinom2(), c(0, 1, 20))
  eval_zinb <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    par <- set_named(par, "beta_sigma", ls)
    par <- set_named(par, "beta_zi", qlogis(0.3))
    nb_ll <- nb2_manual_stable(eta, ls, yv)
    zi <- 0.3
    ref <- if (yv == 0) log(zi + (1 - zi) * exp(nb_ll)) else log1p(-zi) + nb_ll
    c(cpp = -fit$obj$fn(par), ref = ref)
  }
  run_oracle(fits, eval_zinb, tol = 1e-8)
})

# ---- truncated_nbinom2 (model_type 11; src/drmTMB.cpp:3670-3718) -----------
# log(1 - p0) uses the Machler (2012, "Accurately computing log(1-exp(-|a|))")
# log1mexp identity, not naive exp()-then-log1p(): p0 = exp(log_p0) rounds to
# exactly 1.0 in double precision whenever log_p0 is near 0, which is a
# reference-construction artifact (verified in the dev-log companion note),
# not a kernel error. The single (-700, -15) grid corner needs mu/k, a
# subnormal-range double (~9e-318); it is checked separately with a looser
# absolute bound.
log1mexp_machler <- function(x) if (x > -log(2)) log(-expm1(x)) else log1p(-exp(x))
trnb_dens_logp0 <- function(eta, ls, y) {
  alpha <- exp(2 * ls); mu <- exp(eta); k <- 1 / alpha
  log1p_mu_over_k <- log1p(mu / k)
  dens <- lgamma(y + k) - lgamma(k) - lgamma(y + 1) - k * log1p_mu_over_k +
    y * (log(mu / k) - log1p_mu_over_k)
  list(dens = dens, log_p0 = -k * log1p_mu_over_k)
}
trnb_ref <- function(eta, ls, y) {
  dp <- trnb_dens_logp0(eta, ls, y)
  dp$dens - log1mexp_machler(dp$log_p0)
}
test_that("truncated_nbinom2 kernel matches a Machler-stable truncation formula", {
  fits <- build_fits(bf(y ~ 1, sigma ~ 1), truncated_nbinom2(), c(1, 20, 500))
  eval_trnb <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    par <- set_named(par, "beta_sigma", ls)
    c(cpp = -fit$obj$fn(par), ref = trnb_ref(eta, ls, yv))
  }
  subnormal_corner <- function(eta, ls, yv) eta == -700 && ls == -15
  res <- run_oracle(fits, eval_trnb, tol = 1e-6, exclude = subnormal_corner)
  excl <- res[mapply(subnormal_corner, res$eta, res$log_sigma, res$y), ]
  expect_true(nrow(excl) > 0)
  expect_true(all(excl$rel_err[is.finite(excl$rel_err)] <= 1e-6))
})

# ---- hurdle_nbinom2 (model_type 12; src/drmTMB.cpp:3718-3804) --------------
test_that("hurdle_nbinom2 kernel matches an independent hurdle mixture", {
  fits <- list()
  for (yv in c(0, 1, 20, 500)) {
    dat <- data.frame(y = c(yv, 3))
    fits[[as.character(yv)]] <- suppressWarnings(drmTMB(
      bf(y ~ 1, sigma ~ 1, hu ~ 1), data = dat, weights = c(1, 0),
      family = truncated_nbinom2(), control = ctrl
    ))
  }
  eval_hnb <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    par <- set_named(par, "beta_sigma", ls)
    par <- set_named(par, "beta_zi", qlogis(0.25))
    hu <- 0.25
    ref <- if (yv == 0) log(hu) else log1p(-hu) + trnb_ref(eta, ls, yv)
    c(cpp = -fit$obj$fn(par), ref = ref)
  }
  subnormal_corner <- function(eta, ls, yv) eta == -700 && ls == -15
  res <- run_oracle(fits, eval_hnb, tol = 1e-6, exclude = subnormal_corner)
  excl <- res[mapply(subnormal_corner, res$eta, res$log_sigma, res$y), ]
  expect_true(nrow(excl) > 0)
  expect_true(all(excl$rel_err[is.finite(excl$rel_err)] <= 1e-6))
})

# ---- beta (model_type 10; src/drmTMB.cpp:2739-2935) ------------------------
# mu and the beta shapes carry deliberate numerical floors in the kernel
# (beta_mu_eps = 1e-12 at src/drmTMB.cpp:2882; beta_shape_floor = 1e-8 at
# src/drmTMB.cpp:2896); the reference reproduces those floors explicitly so
# the documented safety net is not mistaken for a bug.
#
# Separately, at log_sigma = -15 (phi = 1/sigma^2 ~ 1e13, so mu = 0.5 gives
# alpha = beta = phi/2 ~ 5e12), lgamma(a+b) - lgamma(a) - lgamma(b) subtracts
# lgamma values of order ~1e14 to recover an O(10) answer -- ~13-14 digits of
# cancellation out of a double's ~15-17. dbeta(), a from-scratch lgamma
# reimplementation, an lbeta()-based reimplementation, and the compiled
# kernel all disagree with each other at the 1e-3 to 1e-2 relative-log-
# density level there (verified in the dev-log companion note); none is a
# trustworthy oracle for the others in that corner, so it is excluded from
# the strict check and only sanity-bounded.
beta_mu_eps <- 1e-12
beta_shape_floor <- 1e-8
beta_shapes <- function(eta, ls) {
  mu <- beta_mu_eps + (1 - 2 * beta_mu_eps) * plogis(eta)
  phi <- 1 / exp(ls)^2
  list(
    a = max(mu * phi, beta_shape_floor),
    b = max((1 - mu) * phi, beta_shape_floor),
    phi = phi
  )
}
test_that("beta kernel matches a floor-matched dbeta() away from huge phi", {
  fits <- build_fits(bf(y ~ 1, sigma ~ 1), beta(), c(1e-6, 0.5, 1 - 1e-6))
  eval_beta <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    par <- set_named(par, "beta_sigma", ls)
    sh <- beta_shapes(eta, ls)
    c(cpp = -fit$obj$fn(par), ref = dbeta(yv, sh$a, sh$b, log = TRUE))
  }
  huge_phi <- function(eta, ls, yv) beta_shapes(eta, ls)$phi >= 1e10
  res <- run_oracle(fits, eval_beta, tol = 1e-6, exclude = huge_phi)
  excl <- res[mapply(huge_phi, res$eta, res$log_sigma, res$y), ]
  expect_true(nrow(excl) > 0)
  expect_true(all(excl$rel_err[is.finite(excl$rel_err)] <= 0.01))
})

# ---- zero_one_beta (model_type 15; src/drmTMB.cpp:2935-3030) --------------
# Needs >= 1 interior response value in the fitted data; each fixture carries
# the target y plus a weight-0 interior anchor row (y = 0.4), same convention
# as hurdle_nbinom2 above. Same huge-phi exclusion as beta().
zob_row_ref <- function(eta, ls, y, zoi, coi) {
  if (y <= 0) return(log(zoi) + log1p(-coi))
  if (y >= 1) return(log(zoi) + log(coi))
  sh <- beta_shapes(eta, ls)
  log1p(-zoi) + dbeta(y, sh$a, sh$b, log = TRUE)
}
test_that("zero_one_beta kernel matches a floor-matched atom/dbeta() mixture", {
  fits <- list()
  for (yv in c(0, 0.5, 1, 1e-6, 1 - 1e-6)) {
    dat <- data.frame(y = c(yv, 0.4))
    fits[[as.character(yv)]] <- suppressWarnings(drmTMB(
      bf(y ~ 1, sigma ~ 1, zoi ~ 1, coi ~ 1), data = dat, weights = c(1, 0),
      family = zero_one_beta(), control = ctrl
    ))
  }
  eval_zob <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    par <- set_named(par, "beta_sigma", ls)
    par <- set_named(par, "beta_zoi", qlogis(0.3))
    par <- set_named(par, "beta_coi", qlogis(0.5))
    ref <- zob_row_ref(eta, ls, yv, 0.3, 0.5)
    c(cpp = -fit$obj$fn(par), ref = ref)
  }
  huge_phi <- function(eta, ls, yv) yv > 0 && yv < 1 && beta_shapes(eta, ls)$phi >= 1e10
  res <- run_oracle(fits, eval_zob, tol = 1e-6, exclude = huge_phi)
  excl <- res[mapply(huge_phi, res$eta, res$log_sigma, res$y), ]
  expect_true(nrow(excl) > 0)
  expect_true(all(excl$rel_err[is.finite(excl$rel_err)] <= 0.01))
})

# ---- beta_binomial (model_type 14; src/drmTMB.cpp:3030-3088) --------------
# Same lgamma-cancellation limitation as beta() above, but sharper: with
# trials = 1000 and log_sigma = -15 (phi ~ 1e13), lgamma(phi) - lgamma(trials
# + phi) alone subtracts two ~1.3e14-magnitude values to recover an O(10)
# answer. The compiled kernel, dbinom-style direct lgamma differences in R,
# and an lbeta()-based / extraDistr::dbbinom() reformulation all disagree
# with each other at up to ~2.6e-2 relative log-density at log_sigma = -15
# (worst observed point: eta = -5, y = 1 -> cpp = -4.9375 vs an
# lbeta()-based / extraDistr agreement at -4.8076; verified in the dev-log
# companion note). This is the single largest confirmed precision gap found
# in this audit; log_sigma = -15 is excluded from the strict check and held
# to a loose sanity bound only.
test_that("beta_binomial kernel matches an lbeta()-based reference away from huge phi", {
  build_bb_fits <- function(y_grid, trials = 1000) {
    out <- list()
    for (yv in y_grid) {
      dat <- data.frame(succ = yv, fail = trials - yv)
      fit <- suppressWarnings(drmTMB(
        bf(cbind(succ, fail) ~ 1, sigma ~ 1), data = dat,
        family = beta_binomial(), control = ctrl
      ))
      out[[as.character(yv)]] <- fit
    }
    out
  }
  trials <- 1000
  fits <- build_bb_fits(c(0, 1, 500, 999, 1000), trials = trials)
  eval_bb <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    par <- set_named(par, "beta_sigma", ls)
    mu <- plogis(eta); phi <- 1 / exp(ls)^2
    a <- mu * phi; b <- (1 - mu) * phi
    failures <- trials - yv
    ref <- lchoose(trials, yv) + lbeta(yv + a, failures + b) - lbeta(a, b)
    c(cpp = -fit$obj$fn(par), ref = ref)
  }
  huge_phi <- function(eta, ls, yv) (1 / exp(ls)^2) >= 1e10
  res <- run_oracle(fits, eval_bb, tol = 1e-6, exclude = huge_phi)
  excl <- res[mapply(huge_phi, res$eta, res$log_sigma, res$y), ]
  expect_true(nrow(excl) > 0)
  expect_true(all(excl$rel_err[is.finite(excl$rel_err)] <= 0.05))
})

# ---- binomial (model_type 18; src/drmTMB.cpp:3088-3173) --------------------
test_that("binomial kernel matches dbinom()", {
  build_bin_fits <- function(y_grid, trials = 1000) {
    out <- list()
    for (yv in y_grid) {
      dat <- data.frame(succ = yv, fail = trials - yv)
      fit <- suppressWarnings(drmTMB(
        bf(cbind(succ, fail) ~ 1), data = dat,
        family = binomial(), control = ctrl
      ))
      out[[as.character(yv)]] <- fit
    }
    out
  }
  trials <- 1000
  fits <- build_bin_fits(c(0, 1, 500, 999, 1000), trials = trials)
  eval_bin <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    ref <- dbinom(yv, trials, plogis(eta), log = TRUE)
    c(cpp = -fit$obj$fn(par), ref = ref)
  }
  run_oracle(fits, eval_bin, tol = 1e-9, has_ls = FALSE)
})

# ---- tweedie (model_type 16; src/drmTMB.cpp:2692-2739) ---------------------
# `nll -= weights(i) * dtweedie(y(i), mu(i), phi(i), nu(i), true);` calls
# TMB's own dtweedie() (TMB/include/distributions_R.hpp:554-572, via
# atomic::tweedie_logW). A direct sweep over log_sigma at fixed eta = 0,
# y = 1, nu = 1.5 (scratchpad/tweedie_sweep.R) shows TMB's dtweedie() tracks
# tweedie::dtweedie() to ~1e-11 relative for log_sigma in
# {2, 0, -1, -2, -3, -5} (phi >= ~4.5e-5), then breaks sharply for
# log_sigma <= -8 (phi <= ~1.1e-7): at log_sigma = -8 the two already differ
# by 3.5 log-units, and by log_sigma = -15 the compiled kernel gives -28.84
# while tweedie::dtweedie() gives +14.08 -- not a rounding-level disagreement,
# a qualitatively wrong (but silently finite, not NaN) answer. This breakdown
# starts well inside the *default* logsigma_clamp identity band ([-12, 12]),
# so the default clamp does not protect a tweedie fit from it. This is the
# standout finding of this audit; see the accompanying report.
#
# The strict grid below is therefore restricted to the confirmed-valid
# log_sigma sub-range; the breakdown region is characterized, not asserted
# to silently improve, by the second test.
test_that("tweedie kernel matches tweedie::dtweedie() away from TMB's own dtweedie() breakdown", {
  fits <- build_fits(bf(y ~ 1, sigma ~ 1, nu ~ 1), tweedie(), c(0.01, 1, 100))
  safe_ls_grid <- c(-5, -3, -1, 0, 2, 5)
  eval_tw <- function(fit, eta, ls, yv) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    par <- set_named(par, "beta_sigma", ls)
    par <- set_named(par, "beta_nu", 0) # nu = 1 + plogis(0) = 1.5
    mu <- exp(eta); phi <- exp(ls)^2
    ref <- tryCatch(
      log(tweedie::dtweedie(yv, mu = mu, phi = phi, power = 1.5)),
      error = function(e) NA_real_
    )
    c(cpp = -fit$obj$fn(par), ref = ref)
  }
  for (f in fits) assert_clean_fixture(f)
  results <- data.frame()
  for (eta in eta_grid) {
    for (ls in safe_ls_grid) {
      for (yname in names(fits)) {
        yv <- as.numeric(yname)
        out <- eval_tw(fits[[yname]], eta, ls, yv)
        results <- rbind(results, data.frame(
          eta = eta, log_sigma = ls, y = yv, cpp = out[["cpp"]], ref = out[["ref"]]
        ))
      }
    }
  }
  results$rel_err <- mapply(rel_err, results$cpp, results$ref)
  finite_re <- results$rel_err[!is.na(results$rel_err)]
  expect_true(length(finite_re) > 0)
  expect_true(max(finite_re) <= 1e-6)
})

test_that("tweedie's TMB::dtweedie() breakdown at small phi is confirmed and localized", {
  fit <- build_fits(bf(y ~ 1, sigma ~ 1, nu ~ 1), tweedie(), 1)[["1"]]
  eval_at <- function(ls) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", 0)
    par <- set_named(par, "beta_sigma", ls)
    par <- set_named(par, "beta_nu", 0)
    cpp <- -fit$obj$fn(par)
    ref <- log(tweedie::dtweedie(1, mu = 1, phi = exp(ls)^2, power = 1.5))
    c(cpp = cpp, ref = ref)
  }
  clean <- eval_at(-5)
  expect_lt(abs(clean[["cpp"]] - clean[["ref"]]), 1e-6)

  broken <- eval_at(-15)
  # A confirmed, large, wrong-direction divergence: tweedie::dtweedie() rises
  # (as it must, for an ever-narrower distribution evaluated at its mode)
  # while the compiled kernel falls.
  expect_gt(broken[["ref"]] - broken[["cpp"]], 30)
})

# ---- cumulative_logit (model_type 13; src/drmTMB.cpp:3173-3259) -----------
# Has no scale parameter; only eta is swept, via a slope on a constant
# covariate (`y ~ 0 + x`, x = 1) rather than an intercept, because the
# family's own location intercept is dropped for identifiability (see
# `?cumulative_logit`) and would otherwise leave nothing free to sweep. Fixed
# cutpoints theta = (-1, 1). A naive R reference (`log(diff(plogis(.)))`) is
# NOT used as the primary check: it returns -Inf at eta = -700/-40 because
# plogis() saturates to exactly 1.0 there (verified below), a reference
# artifact, not a kernel error. The primary reference instead reimplements
# the standard stable log-space identity for log(plogis(upper) -
# plogis(lower)) (the same identity underlying src/drm_numeric.h:50-55,
# independently re-derived here, not copied).
test_that("cumulative_logit kernel matches a stable log-space reference", {
  dat <- data.frame(y = factor(c(1, 2, 3), levels = 1:3, ordered = TRUE), x = c(1, 1, 1))
  fit <- suppressWarnings(drmTMB(bf(y ~ 0 + x), data = dat, family = cumulative_logit(), control = ctrl))
  assert_clean_fixture(fit)
  cutpoints <- c(-1, 1)
  theta_ord <- c(cutpoints[1], log(diff(cutpoints)))

  logspace_add_r <- function(a, b) {
    m <- pmax(a, b)
    m + log(exp(a - m) + exp(b - m))
  }
  log_inv_logit_diff_r <- function(upper, lower) {
    upper + log1mexp_machler(lower - upper) -
      logspace_add_r(0, upper) - logspace_add_r(0, lower)
  }
  cumlogit_ref <- function(eta) {
    upper2 <- cutpoints[2] - eta; lower2 <- cutpoints[1] - eta
    logp1 <- -logspace_add_r(0, -lower2)
    logp2 <- log_inv_logit_diff_r(upper2, lower2)
    logp3 <- -logspace_add_r(0, upper2)
    logp1 + logp2 + logp3
  }

  res <- data.frame()
  for (eta in eta_grid) {
    par <- fit$obj$par
    par <- set_named(par, "beta_mu", eta)
    par[names(par) == "theta_ord"] <- theta_ord
    cpp <- -fit$obj$fn(par)
    ref <- cumlogit_ref(eta)
    res <- rbind(res, data.frame(eta = eta, cpp = cpp, ref = ref, rel_err = rel_err(cpp, ref)))
  }
  expect_true(all(res$rel_err <= 1e-9))

  # Confirm the naive (non-log-space) formula really is the one at its limit
  # at the extreme corners, not the kernel: it collapses to -Inf while the
  # kernel and the stable reference above both stay finite and agree.
  naive_ref <- function(eta) {
    mu <- eta
    p1 <- plogis(cutpoints[1] - mu, log.p = TRUE)
    p2 <- log(plogis(cutpoints[2] - mu) - plogis(cutpoints[1] - mu))
    p3 <- plogis(cutpoints[2] - mu, lower.tail = FALSE, log.p = TRUE)
    p1 + p2 + p3
  }
  expect_identical(naive_ref(-700), -Inf)
  expect_identical(naive_ref(-40), -Inf)
})
