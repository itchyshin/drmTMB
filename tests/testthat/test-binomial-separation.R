# Separation screen for fixed-effect binomial / Bernoulli fits (#1268; twin of
# DRModels.jl #731 / #728). Policy: detect and warn -- the fit is returned, a
# warning names the affected coefficients, their SEs are Inf. The datasets and
# the expected flagged coefficients are identical constants in the Julia twin
# (test/test_binomial_separation.jl); keep them in sync.

# #728 cell-47 recipe: n = 60, x clustered near -2 / +2 (x = +-2 + N(0, 0.25),
# rounded to 3 dp; NumPy default_rng seed 20307905), true slope 3.5, y the
# Bernoulli draw -- completely separated (y = 1 iff x > 0).
sep_x47 <- c(
    -2.059, 2.3, -2.066, 1.799, -1.967, 1.757, -1.857, 1.903, -2.071, 2.125,
    -2.237, 2.02, -2.267, 1.801, -2.096, 1.58, -2.342, 1.706, -1.99, 1.843,
    -1.9, 2.578, -1.68, 1.907, -1.887, 1.945, -1.937, 1.715, -1.654, 2.21,
    -1.599, 1.656, -2.49, 2.34, -1.856, 1.961, -2.144, 2.277, -2.012, 1.795,
    -2.026, 2.361, -1.96, 1.932, -1.989, 2.349, -1.871, 2.043, -2.222, 2.174,
    -1.983, 1.885, -2.175, 2.686, -2.048, 1.724, -2.19, 1.964, -1.983, 2.275
)
sep_y47 <- as.integer(sep_x47 > 0)

sep_fit <- function(y, x) {
  dat <- data.frame(y = y, x = x)
  warns <- list()
  fit <- withCallingHandlers(
    drmTMB(bf(y ~ x), family = binomial(), data = dat),
    warning = function(w) {
      warns[[length(warns) + 1L]] <<- w
      invokeRestart("muffleWarning")
    }
  )
  sep_warns <- Filter(function(w) inherits(w, "drmTMB_separation_warning"), warns)
  list(fit = fit, sep_warns = sep_warns, warns = warns)
}

test_that("LP screen: complete, quasi-complete and overlapping toys", {
  X <- cbind(1, c(-3, -2, -1, 1, 2, 3))
  d <- drmTMB:::drm_detect_separation(X, c(0, 0, 0, 1, 1, 1), c(1, 1, 1, 0, 0, 0))
  expect_true(d$separated)
  expect_identical(d$flagged, c(1L, 2L))
  expect_true(d$conclusive)

  xq <- c(-2, -1, 0, 0, 1, 2)
  dq <- drmTMB:::drm_detect_separation(
    cbind(1, xq), c(0, 0, 0, 1, 1, 1), c(1, 1, 1, 0, 0, 0)
  )
  expect_true(dq$separated)
  expect_identical(dq$flagged, 2L)                 # quasi-complete: slope only

  xo <- c(-3, -2, -1, 1, 2, 3)
  yo <- c(0, 1, 0, 1, 0, 1)
  do <- drmTMB:::drm_detect_separation(cbind(1, xo), yo, 1 - yo)
  expect_false(do$separated)
  expect_identical(do$flagged, integer())

  # grouped counts give the same verdict as their Bernoulli expansion
  dc <- drmTMB:::drm_detect_separation(
    cbind(1, c(-1, 0, 1)), c(0, 2, 3), c(3, 1, 0)
  )
  xb <- c(-1, -1, -1, 0, 0, 0, 1, 1, 1)
  yb <- c(0, 0, 0, 1, 1, 0, 1, 1, 1)
  db <- drmTMB:::drm_detect_separation(cbind(1, xb), yb, 1 - yb)
  expect_true(dc$separated)
  expect_identical(dc$flagged, 2L)
  expect_identical(db$flagged, 2L)
})

test_that("complete separation toy: warns, names both coefficients, SE Inf", {
  out <- sep_fit(c(0, 0, 0, 1, 1, 1), c(-3, -2, -1, 1, 2, 3))
  expect_length(out$sep_warns, 1L)
  expect_identical(out$fit$separation$status, "complete_or_quasi")
  expect_identical(out$fit$separation$flagged, c("(Intercept)", "x"))
  se <- summary(out$fit)$coefficients[, "std_error"]
  expect_true(all(is.infinite(se)))
})

test_that("quasi-complete separation toy flags the slope only", {
  out <- sep_fit(c(0, 0, 0, 1, 1, 1), c(-2, -1, 0, 0, 1, 2))
  expect_length(out$sep_warns, 1L)
  expect_identical(out$fit$separation$flagged, "x")
  se <- summary(out$fit)$coefficients[, "std_error"]
  expect_true(is.infinite(se[[2L]]))
})

test_that("#728 cell-47 near-separated dataset is flagged", {
  out <- sep_fit(sep_y47, sep_x47)
  expect_length(out$sep_warns, 1L)
  expect_identical(out$fit$separation$status, "complete_or_quasi")
  expect_identical(out$fit$separation$flagged, c("(Intercept)", "x"))
  expect_true(all(is.infinite(summary(out$fit)$coefficients[, "std_error"])))
  expect_s3_class(out$fit, "drmTMB")                # the fit is still returned
})

test_that("non-separated controls: no warning, SEs untouched", {
  y <- sep_y47
  y[c(1, 3, 5, 7)] <- 1L
  y[c(2, 4, 6, 8)] <- 0L
  out <- sep_fit(y, sep_x47)
  expect_length(out$sep_warns, 0L)
  expect_identical(out$fit$separation$status, "none")
  expect_true(all(is.finite(summary(out$fit)$coefficients[, "std_error"])))

  xc <- seq(-2, 2, length.out = 40)
  yc <- c(0,0,1,0,0,0,1,0,1,0,0,1,0,1,0,1,1,0,1,0,
          0,1,1,0,1,1,0,1,1,1,0,1,1,1,1,0,1,1,1,1)
  outc <- sep_fit(yc, xc)
  expect_length(outc$sep_warns, 0L)
  expect_true(all(is.finite(summary(outc$fit)$coefficients[, "std_error"])))
  # unchanged against glm(): the screen touches nothing on a healthy fit
  g <- stats::glm(yc ~ xc, family = stats::binomial())
  expect_equal(unname(unlist(coef(outc$fit))), unname(stats::coef(g)), tolerance = 1e-5)
})

test_that("near-separation rule (numeric degeneracy)", {
  mu <- c(0.5, 1e-9, 0.9)
  expect_identical(drmTMB:::drm_near_separation(mu, c(0.3, 5e4)), 2L)
  expect_identical(drmTMB:::drm_near_separation(mu, c(0.3, 5)), integer())
  expect_identical(drmTMB:::drm_near_separation(c(0.5, 0.2), c(Inf, 1)), integer())
  expect_identical(drmTMB:::drm_near_separation(mu, c(NA, 1)), 1L)
})

test_that("separation screen skips random-effect and MSPL routes", {
  spec <- list(model_type = "binomial", estimator = "ML",
               random = list(mu = list(n_re = 3L)),
               structured = list(phylo_mu = list(has = FALSE)),
               missing_predictor = list(enabled = FALSE))
  expect_false(drmTMB:::drm_separation_applicable(spec))
  spec$random$mu$n_re <- 0L
  expect_true(drmTMB:::drm_separation_applicable(spec))
  spec$estimator <- "MSPL"
  expect_false(drmTMB:::drm_separation_applicable(spec))
})
