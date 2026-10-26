# #1566: fitted() and residuals() on an engine = "julia" fit follow
# ?fitted.drmTMB, not the DRModels.jl fitted definition carried in the bridge
# slot. DRModels.jl returns the lognormal median, the untruncated
# truncated_nbinom2 mu, and X beta (modes at 0) for Gaussian (1 | g).
#
# The offline tests build a bridge-shaped object from a NATIVE tmb fit: the
# coefficients are the tmb ones (the two engines agree to ~1e-11), and the
# `fitted` / `residuals` slots are what DRModels.jl returns. The expected value
# is the tmb fit's own fitted() / residuals(). The live test does the same with
# a real Julia fit.

drm_fitted_def_object <- function(ft, formula, family, data, model_type,
                                  slot_fitted, y, conditional_re = NULL) {
  dpars <- c("mu", "sigma")
  coefficients <- stats::setNames(
    lapply(dpars, function(d) {
      b <- stats::coef(ft, dpar = d)
      stats::setNames(as.numeric(b), names(b))
    }),
    dpars
  )
  out <- list(
    formula = formula,
    family = family,
    model = list(model_type = model_type),
    data = data,
    coefficients = coefficients,
    fitted = slot_fitted,
    residuals = y - slot_fitted,
    engine = "julia"
  )
  if (!is.null(conditional_re)) {
    out$conditional_re <- conditional_re
  }
  structure(out, class = "drmTMB_julia")
}

test_that("lognormal bridge fitted() and residuals() are the mean, as on engine = tmb", {
  set.seed(1566)
  n <- 120
  x <- stats::rnorm(n)
  dat <- data.frame(x = x)
  dat$y <- exp(0.3 + 0.5 * x + exp(-0.4 + 0.3 * x) * stats::rnorm(n))
  fml <- bf(y ~ x, sigma ~ x)
  ft <- drmTMB(fml, family = lognormal(), data = dat)
  mu <- stats::predict(ft, dpar = "mu")
  # What DRModels.jl returns: exp(mu), the median.
  fj <- drm_fitted_def_object(
    ft, fml, lognormal(), dat, "lognormal",
    slot_fitted = exp(mu), y = dat$y
  )
  expect_gt(max(abs(fj$fitted - stats::fitted(ft))), 0.1)
  expect_equal(stats::fitted(fj), stats::fitted(ft), tolerance = 1e-8)
  expect_equal(stats::residuals(fj), stats::residuals(ft), tolerance = 1e-8)
})

test_that("truncated_nbinom2 bridge fitted() and residuals() are the truncated mean, as on engine = tmb", {
  set.seed(15662)
  n <- 200
  x <- stats::rnorm(n)
  mu_true <- exp(0.5 + 0.25 * x)
  sigma_true <- 0.6
  p0 <- stats::dnbinom(0, size = 1 / sigma_true^2, mu = mu_true)
  u <- p0 + pmax(stats::runif(n), 1e-10) * (1 - p0)
  dat <- data.frame(x = x, y = stats::qnbinom(u, size = 1 / sigma_true^2, mu = mu_true))
  fml <- bf(y ~ x, sigma ~ 1)
  ft <- drmTMB(fml, family = truncated_nbinom2(), data = dat)
  # What DRModels.jl returns: mu, the untruncated mean.
  fj <- drm_fitted_def_object(
    ft, fml, truncated_nbinom2(), dat, "truncated_nbinom2",
    slot_fitted = stats::predict(ft, dpar = "mu"), y = dat$y
  )
  expect_gt(max(abs(fj$fitted - stats::fitted(ft))), 0.05)
  expect_equal(stats::fitted(fj), stats::fitted(ft), tolerance = 1e-8)
  expect_equal(stats::residuals(fj), stats::residuals(ft), tolerance = 1e-8)
})

test_that("Gaussian (1 | g) bridge fitted() and residuals() include the modes, as on engine = tmb", {
  set.seed(15663)
  g <- factor(rep(letters[1:8], each = 10), levels = letters[8:1])
  x <- stats::rnorm(80)
  b <- stats::rnorm(8, sd = 0.8)
  dat <- data.frame(x = x, g = g)
  dat$y <- 0.5 + 0.3 * x + b[as.integer(g)] + stats::rnorm(80, sd = 0.5)
  fml <- bf(y ~ x + (1 | g), sigma ~ 1)
  ft <- drmTMB(fml, family = gaussian(), data = dat)
  fitted_tmb <- stats::fitted(ft)
  beta <- stats::coef(ft, dpar = "mu")
  xb <- as.numeric(beta[["(Intercept)"]] + beta[["x"]] * dat$x)
  modes_row <- fitted_tmb - xb
  # Julia indexes groups by first appearance, not by factor level order.
  levels_fa <- unique(as.character(dat$g))
  blup <- vapply(levels_fa, function(l) mean(modes_row[as.character(dat$g) == l]), numeric(1L))
  expect_gt(max(abs(modes_row)), 0.1)
  fj <- drm_fitted_def_object(
    ft, fml, gaussian(), dat, "gaussian",
    slot_fitted = xb, y = dat$y,
    conditional_re = list(
      kind = "gaussian_mu_random_intercept_v1",
      group = "g",
      levels = levels_fa,
      gidx = match(as.character(dat$g), levels_fa),
      blup = as.numeric(blup)
    )
  )
  expect_equal(stats::fitted(fj), fitted_tmb, tolerance = 1e-8)
  expect_equal(stats::residuals(fj), stats::residuals(ft), tolerance = 1e-8)
  # fitted() and predict() agree within the one bridge object.
  expect_equal(stats::fitted(fj), stats::predict(fj, dpar = "mu"))
})

test_that("routes whose bridge slot is already the documented value are untouched", {
  # Fixed-effect Gaussian, and a Gaussian (1 | g) fit with no retained payload,
  # keep the bridge slot (nothing to recompute, nothing it could recompute from).
  dat <- data.frame(y = c(-1, 0, 1, 2), x = c(-2, -1, 1, 2), g = c("b", "a", "b", "a"))
  mk <- function(formula) {
    structure(
      list(
        formula = formula,
        family = gaussian(),
        model = list(model_type = "gaussian"),
        data = dat,
        coefficients = list(mu = c("(Intercept)" = 0.5, x = 0.3), sigma = c("(Intercept)" = -0.2)),
        fitted = c(9, 8, 7, 6),
        residuals = c(1, 2, 3, 4),
        engine = "julia"
      ),
      class = "drmTMB_julia"
    )
  }
  fe <- mk(bf(y ~ x, sigma ~ 1))
  expect_identical(stats::fitted(fe), c(9, 8, 7, 6))
  expect_identical(stats::residuals(fe), c(1, 2, 3, 4))
  ri <- mk(bf(y ~ x + (1 | g), sigma ~ 1))
  expect_identical(stats::fitted(ri), c(9, 8, 7, 6))
  expect_identical(stats::residuals(ri), c(1, 2, 3, 4))
})

drm_fitted_def_live <- function() {
  pkg <- normalizePath(testthat::test_path("..", ".."), mustWork = TRUE)
  jl_path <- drm_test_drmjl_path()
  callr::r(
    function(pkg, jl_path) {
      julia_home <- Sys.getenv("DRM_JL_JULIA_HOME", Sys.getenv("JULIA_HOME", ""))
      if (nzchar(julia_home)) Sys.setenv(JULIA_HOME = julia_home)
      options(drmTMB.DRM.jl.path = jl_path)
      Sys.setenv(DRM_JL_PATH = jl_path)
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
      both <- function(fml, family, data) {
        ft <- drmTMB::drmTMB(fml, family = family, data = data, engine = "tmb")
        fj <- drmTMB::drmTMB(fml, family = family, data = data, engine = "julia")
        c(
          fitted = max(abs(stats::fitted(fj) - stats::fitted(ft))),
          residuals = max(abs(stats::residuals(fj) - stats::residuals(ft)))
        )
      }
      set.seed(20261016)
      n <- 240
      x <- stats::rnorm(n)
      d_ln <- data.frame(x = x)
      d_ln$y <- exp(0.3 + 0.5 * x + exp(-0.4 + 0.3 * x) * stats::rnorm(n))
      mu_t <- exp(0.5 + 0.25 * x)
      p0 <- stats::dnbinom(0, size = 1 / 0.36, mu = mu_t)
      u <- p0 + pmax(stats::runif(n), 1e-10) * (1 - p0)
      d_tn <- data.frame(x = x, y = stats::qnbinom(u, size = 1 / 0.36, mu = mu_t))
      g <- factor(rep(seq_len(24), each = 10))
      d_ri <- data.frame(x = x, g = g)
      d_ri$y <- 0.5 + 0.3 * x + stats::rnorm(24, sd = 0.8)[as.integer(g)] +
        stats::rnorm(n, sd = 0.5)
      list(
        lognormal = both(drmTMB::bf(y ~ x, sigma ~ x), drmTMB::lognormal(), d_ln),
        truncated_nbinom2 = both(drmTMB::bf(y ~ x, sigma ~ 1), drmTMB::truncated_nbinom2(), d_tn),
        gaussian_ri = both(drmTMB::bf(y ~ x + (1 | g), sigma ~ x), drmTMB::gaussian(), d_ri)
      )
    },
    args = list(pkg = pkg, jl_path = jl_path),
    error = "stack"
  )
}

test_that("engine = \"julia\" fitted() and residuals() match engine = \"tmb\" (lognormal, truncated_nbinom2, Gaussian (1 | g))", {
  drm_skip_live_julia()
  testthat::skip_if_not_installed("JuliaCall")
  testthat::skip_if_not_installed("callr")
  res <- drm_fitted_def_live()
  for (case in names(res)) {
    expect_lt(res[[case]][["fitted"]], 1e-5)
    expect_lt(res[[case]][["residuals"]], 1e-5)
  }
})
