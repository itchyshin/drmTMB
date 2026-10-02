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

# #1442-review fixture (DRModels.jl twin: the same constants in
# test/test_binomial_separation.jl): set.seed(3); x <- round(rnorm(200), 3);
# y <- rbinom(200, 1, plogis(-1 + 9 * x)). A steep but well-identified slope
# (glm: beta = 9.308, SE = 2.014, z = 4.62; min fitted probability 4.9e-11). The
# pre-fix near rule (a fitted probability within 1e-8 of 0/1 AND an SE > 1e4)
# flagged it as soon as x was divided by 1e5 (SE 2.0e5).
sep_xh <- c(
  -0.962, -0.293, 0.259, -1.152, 0.196, 0.030, 0.085, 1.117, -1.219, 1.267,
  -0.745, -1.131, -0.716, 0.253, 0.152, -0.308, -0.953, -0.648, 1.224, 0.200,
  -0.578, -0.942, -0.204, -1.666, -0.484, -0.741, 1.161, 1.012, -0.072,
  -1.137, 0.901, 0.852, 0.728, 0.737, -0.352, 0.706, 1.300, 0.038, -0.979,
  0.794, 0.787, -0.310, 1.699, -0.795, 0.348, -2.265, -0.162, 1.131, -0.456,
  -0.899, 0.727, -0.809, 0.267, -1.737, -1.411, -0.454, -1.035, 1.362, 0.917,
  -0.785, 0.574, 0.918, 0.256, 0.352, 1.174, -0.481, -0.419, 0.955, -1.289,
  0.186, -0.031, 0.467, 1.024, 0.267, 0.232, 0.748, 1.217, 0.383, -0.988,
  -0.157, 1.736, -0.352, 0.689, 1.224, 0.794, -0.006, 0.219, -0.886, 0.440,
  -0.886, -0.854, -0.990, -0.651, 1.054, -0.391, -0.071, -0.462, 0.541, 0.932,
  -0.209, 0.617, -0.405, 1.053, 0.602, 1.017, 0.608, 0.207, -1.898, -0.683,
  0.481, -0.463, -0.280, -0.414, 1.619, -0.721, -0.453, 0.014, 0.216, 0.189,
  -0.050, -1.495, 0.368, 0.517, -0.484, 0.675, -0.762, 0.386, -0.664, -1.724,
  1.156, 0.694, 0.143, 1.493, -1.632, 0.128, -2.404, 1.444, -0.879, -1.306,
  -0.877, -1.164, -1.982, -0.990, -0.152, 0.913, 0.408, -1.242, -0.643, 1.930,
  0.410, -1.291, 2.635, 0.487, 0.854, 1.088, 0.226, 0.068, -0.985, -1.311,
  2.464, -0.665, 0.913, 0.965, 1.608, 1.835, 0.702, 1.218, -1.124, 0.668,
  1.216, 0.235, -0.419, 0.238, -0.551, -0.501, 1.164, 2.156, -1.709, -1.601,
  -1.039, 0.323, -0.889, 0.394, 0.237, -0.430, -0.548, -1.322, 0.682, 2.163,
  -0.417, -1.357, -0.671, 0.650, 0.771, 2.677, -1.371, 0.058, -0.197, -1.262,
  -0.662
)
sep_yh <- c(
  0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0,
  0, 1, 1, 0, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0,
  1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1,
  1, 1, 1, 0, 0, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1, 0, 1, 1, 0,
  1, 0, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 1, 1, 0, 1,
  0, 1, 0, 0, 1, 1, 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 0, 1, 1,
  0, 1, 1, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 0,
  1, 1, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0, 0
)

sep_capture <- function(expr) {
  warns <- list()
  fit <- withCallingHandlers(
    expr,
    warning = function(w) {
      warns[[length(warns) + 1L]] <<- w
      invokeRestart("muffleWarning")
    }
  )
  sep_warns <- Filter(function(w) inherits(w, "drmTMB_separation_warning"), warns)
  list(fit = fit, sep_warns = sep_warns, warns = warns)
}

sep_fit <- function(y, x, ...) {
  dat <- data.frame(y = y, x = x)
  sep_capture(drmTMB(bf(y ~ x), family = binomial(), data = dat, ...))
}

# A flagged coefficient: Inf variance, NaN covariances, SE Inf, and the Wald
# interval (confint, summary(conf.int = TRUE), tidy) is (-Inf, Inf).
sep_check_flagged <- function(fit, label) {
  vc <- vcov(fit)
  expect_identical(vc[label, label], Inf)
  expect_true(all(is.nan(vc[label, setdiff(colnames(vc), label)])))
  se <- summary(fit)$coefficients
  expect_identical(se[label, "std_error"], Inf)
  ci <- confint(fit, parm = paste0("fixef:", label))
  expect_identical(c(ci$lower, ci$upper), c(-Inf, Inf))
  expect_identical(ci$conf.status, "wald_separation")
  sm <- summary(fit, conf.int = TRUE)$coefficients
  expect_identical(unname(unlist(sm[label, c("conf.low", "conf.high")])), c(-Inf, Inf))
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
  sep_check_flagged(out$fit, "mu:(Intercept)")
  sep_check_flagged(out$fit, "mu:x")
})

test_that("quasi-complete separation toy flags the slope only", {
  out <- sep_fit(c(0, 0, 0, 1, 1, 1), c(-2, -1, 0, 0, 1, 2))
  expect_length(out$sep_warns, 1L)
  expect_identical(out$fit$separation$flagged, "x")
  se <- summary(out$fit)$coefficients[, "std_error"]
  expect_true(is.infinite(se[[2L]]))
  expect_true(is.finite(se[[1L]]))
  sep_check_flagged(out$fit, "mu:x")
  ci <- confint(out$fit, parm = "fixef:mu:(Intercept)")
  expect_true(all(is.finite(c(ci$lower, ci$upper))))
})

test_that("cbind(successes, failures) and weights through drmTMB()", {
  # grouped counts: the same quasi-separation verdict as the Bernoulli expansion
  d <- data.frame(s = c(0, 2, 3), f = c(3, 1, 0), x = c(-1, 0, 1))
  out <- sep_capture(drmTMB(bf(cbind(s, f) ~ x), family = binomial(), data = d))
  expect_length(out$sep_warns, 1L)
  expect_identical(out$fit$separation$flagged, "x")
  sep_check_flagged(out$fit, "mu:x")

  # zero weights drop rows from the screen: the overlapping rows carry weight 0,
  # leaving a completely separated design
  xw <- c(-3, -2, -1, 1, 2, 3, -2.5, 2.5)
  yw <- c(0, 0, 0, 1, 1, 1, 1, 0)
  ww <- c(1, 1, 1, 1, 1, 1, 0, 0)
  outw <- sep_capture(drmTMB(bf(y ~ x), family = binomial(),
                             data = data.frame(y = yw, x = xw), weights = ww))
  expect_length(outw$sep_warns, 1L)
  expect_identical(outw$fit$separation$flagged, c("(Intercept)", "x"))
  outw1 <- sep_capture(drmTMB(bf(y ~ x), family = binomial(),
                              data = data.frame(y = yw, x = xw)))
  expect_length(outw1$sep_warns, 0L)
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

test_that("near-separation rule: scale-free, never from a missing SE", {
  mu <- c(0.5, 1e-9, 0.9)
  ns <- drmTMB:::drm_near_separation
  # coefficient 2 spans the whole logit range with |z| = 0.01: flagged
  expect_identical(ns(mu, c(0.1, 40), c(1, 4000), c(0, 1)), 2L)
  # the same coefficient on a covariate divided by 1e5: same verdict
  expect_identical(ns(mu, c(0.1, 4e6), c(1, 4e8), c(0, 1e-5)), 2L)
  expect_identical(ns(mu, c(0.1, 40), c(1, 8), c(0, 1)), integer())     # z = 5
  expect_identical(ns(mu, c(0.1, 20), c(1, 4000), c(0, 1)), integer())  # span 20
  expect_identical(ns(c(0.5, 0.2), c(0.1, 40), c(1, 4000), c(0, 1)), integer())
  # an unavailable SE (se = FALSE, failed vcov) is never near separation
  expect_identical(ns(mu, c(0.1, 40), c(NA, NA), c(0, 1)), integer())
  expect_identical(ns(mu, c(0.1, 40), c(Inf, Inf), c(0, 1)), integer())
  # logit span constant shared with DRModels.jl (_SEP_NEAR_SPAN = 36.84)
  lf <- stats::binomial()$linkfun
  expect_equal(lf(1 - 1e-8) - lf(1e-8), 2 * log((1 - 1e-8) / 1e-8))
})

test_that("healthy steep slope, raw and rescaled covariate: not flagged (#1442 review)", {
  out <- sep_fit(sep_yh, sep_xh)
  expect_length(out$sep_warns, 0L)
  expect_identical(out$fit$separation$status, "none")
  g <- stats::glm(sep_yh ~ sep_xh, family = stats::binomial())
  expect_equal(unname(unlist(coef(out$fit))), unname(stats::coef(g)), tolerance = 1e-6)
  expect_equal(as.numeric(logLik(out$fit)), as.numeric(logLik(g)), tolerance = 1e-8)
  outs <- sep_fit(sep_yh, sep_xh / 1e5)
  expect_length(outs$sep_warns, 0L)
  se <- summary(outs$fit)$coefficients[, "std_error"]
  expect_gt(se[[2L]], 1e4)                     # what the old rule tripped on
  expect_true(all(is.finite(se)))
})

test_that("se = FALSE on a healthy fit is not flagged (#1442 review)", {
  out <- sep_fit(sep_yh, sep_xh, control = drm_control(se = FALSE))
  expect_length(out$sep_warns, 0L)
  expect_identical(out$fit$separation$status, "none")
  xc <- seq(-2, 2, length.out = 40)
  yc <- c(0,0,1,0,0,0,1,0,1,0,0,1,0,1,0,1,1,0,1,0,
          0,1,1,0,1,1,0,1,1,1,0,1,1,1,1,0,1,1,1,1)
  outc <- sep_fit(yc, xc, control = drm_control(se = FALSE))
  expect_length(outc$sep_warns, 0L)
})

test_that("healthy fit: the screen leaves vcov and estimates byte-identical", {
  out <- sep_fit(sep_yh, sep_xh)
  fit <- out$fit
  bare <- fit
  bare$separation <- NULL                      # the feature disabled
  expect_identical(vcov(fit), vcov(bare))
  expect_identical(summary(fit)$coefficients, summary(bare)$coefficients)
  expect_identical(confint(fit), confint(bare))
  expect_identical(coef(fit), coef(bare))
  expect_identical(logLik(fit), logLik(bare))
})

test_that("inconclusive check warns, never reads as no separation", {
  # overlapping toy: proving "no separation" needs NNLS steps, so a zero budget
  # leaves the check inconclusive (a complete-separation design is decided at
  # y = 0 without any step)
  X <- cbind(1, c(-3, -2, -1, 1, 2, 3))
  yo <- c(0, 1, 0, 1, 0, 1)
  d <- drmTMB:::drm_detect_separation(X, yo, 1 - yo, max_iter = 0L)
  expect_false(d$conclusive)
  expect_false(d$separated)
  expect_true(drmTMB:::drm_detect_separation(X, yo, 1 - yo)$conclusive)
  expect_warning(
    drmTMB:::drm_warn_separation(list(status = "inconclusive", flagged = character(),
                                      conclusive = FALSE)),
    class = "drmTMB_separation_warning", regexp = "inconclusive"
  )
})

test_that("timing guard: separated designs with many columns stay fast", {
  n <- 1000
  lv <- ((7 * seq_len(n)) - 1L) %% 40L + 1L      # DRModels.jl mod1(7i, 40)
  X <- matrix(0, n, 40); X[, 1] <- 1
  X[cbind(which(lv > 1), lv[lv > 1])] <- 1
  y <- ifelse(lv %% 3 == 0, 0, ifelse(lv %% 3 == 1, 1, as.numeric(seq_len(n) %% 2 == 1)))
  t <- system.time(d <- drmTMB:::drm_detect_separation(X, y, 1 - y))[["elapsed"]]
  expect_true((d$separated && d$conclusive && t < 5) || !d$conclusive)
  i <- seq_len(10000)
  Xb <- cbind(1, outer(i, 1:9, function(a, b) sin(0.37 * a * b)))
  yb <- as.numeric(Xb[, 2] > 0)
  t2 <- system.time(db <- drmTMB:::drm_detect_separation(Xb, yb, 1 - yb))[["elapsed"]]
  expect_true(db$separated)
  expect_identical(db$flagged, 1:10)
  expect_lt(t2, 5)
})

test_that("bootstrap refits do not repeat the separation warning", {
  out <- sep_fit(c(0, 0, 0, 1, 1, 1), c(-3, -2, -1, 1, 2, 3))
  expect_length(out$sep_warns, 1L)
  boot <- sep_capture(suppressMessages(
    confint(out$fit, parm = "fixef:mu:x", method = "bootstrap", R = 3, seed = 1)
  ))
  expect_length(boot$sep_warns, 0L)
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
