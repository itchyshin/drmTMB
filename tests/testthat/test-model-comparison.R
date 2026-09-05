# aicc() and drm_lrtest(): the R port of DRM.jl src/comparison.jl (#1117).
#
# Fixtures 1 and 2 are the first two cells of DRM.jl tools/parity_fixture.R
# (base_gaussian_location_scale, base_gaussian_intercept_only), so every
# number here is on data both engines are known to fit. The pure-R tests mirror
# DRM.jl test/test_comparison.jl; the live block at the end computes the same
# quantities natively in DRM.jl (pin 430ef64cc) through JuliaCall and asserts
# the port matches to 1e-8.

drm_mc_fixture_1 <- function() {
  set.seed(20260814)
  n <- 120
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  data.frame(
    y = 0.4 + 0.9 * x + exp(-0.3 + 0.25 * z) * stats::rnorm(n),
    x = x,
    z = z
  )
}

drm_mc_fixture_2 <- function() {
  set.seed(99)
  n <- 100
  x <- stats::rnorm(n)
  data.frame(y = 1.2 - 0.6 * x + 0.7 * stats::rnorm(n), x = x)
}

drm_mc_fit <- function(form, dat, engine = "tmb", ...) {
  drmTMB::drmTMB(form, family = stats::gaussian(), data = dat, engine = engine, ...)
}

test_that("aicc() is AIC plus the second-order correction (DRM.jl comparison.jl:209-215)", {
  dat <- drm_mc_fixture_1()
  fit <- drm_mc_fit(bf(y ~ x, sigma ~ z), dat)
  k <- fit$df
  n <- fit$nobs
  expect_identical(k, 4L)
  expect_identical(n, 120L)
  expected <- AIC(fit) + 2 * k * (k + 1) / (n - k - 1)
  expect_equal(aicc(fit), expected, tolerance = 1e-12)
  expect_gt(aicc(fit), AIC(fit))
  expect_true(is.finite(aicc(fit)))
})

test_that("aicc() returns Inf when n - k - 1 <= 0 (DRM.jl comparison.jl:213)", {
  dat <- drm_mc_fixture_1()[1:3, ]
  fit <- drm_mc_fit(bf(y ~ 1, sigma ~ 1), dat)
  expect_identical(fit$df, 2L)
  expect_identical(fit$nobs, 3L)
  expect_identical(aicc(fit), Inf)
  # The pure arithmetic, including the strict inequality at n - k - 1 = 0.
  expect_identical(drm_aicc_from_loglik(-1, k = 2, n = 3), Inf)
  expect_identical(drm_aicc_from_loglik(-1, k = 2, n = 2), Inf)
  expect_equal(drm_aicc_from_loglik(-1, k = 2, n = 4), 2 + 4 + 2 * 2 * 3 / 1)
})

test_that("aicc() default method works from logLik() attributes", {
  dat <- drm_mc_fixture_2()
  fit <- stats::lm(y ~ x, data = dat)
  ll <- stats::logLik(fit)
  k <- attr(ll, "df")
  n <- attr(ll, "nobs")
  expect_equal(aicc(fit), AIC(fit) + 2 * k * (k + 1) / (n - k - 1))
  expect_error(aicc(structure(list(), class = "drm_mc_no_loglik")))
})

test_that("aicc() on a REML fit warns with the AICc label", {
  dat <- drm_mc_fixture_1()
  fit <- drm_mc_fit(bf(y ~ x, sigma ~ z), dat, REML = TRUE)
  expect_warning(
    value <- aicc(fit),
    class = "drmTMB_ic_reml_warning",
    regexp = "AICc"
  )
  expect_true(is.finite(value))
})

test_that("drm_lrtest() matches DRM.jl lrtest on fixture 1 (comparison.jl:65-78)", {
  dat <- drm_mc_fixture_1()
  full <- drm_mc_fit(bf(y ~ x, sigma ~ z), dat)
  reduced <- drm_mc_fit(bf(y ~ 1, sigma ~ 1), dat)
  t <- drm_lrtest(reduced, full)
  expect_named(t, c("statistic", "df", "p.value"))
  expect_equal(t$statistic, 2 * (as.numeric(logLik(full)) - as.numeric(logLik(reduced))))
  expect_identical(t$df, as.numeric(full$df - reduced$df))
  expect_identical(t$df, 2)
  expect_equal(t$p.value, stats::pchisq(t$statistic, df = 2, lower.tail = FALSE))
  expect_gt(t$statistic, 0)
  expect_lt(t$p.value, 0.05)
  # Wrong argument order: no extra parameters in "full".
  expect_error(drm_lrtest(full, reduced), "more parameters")
  # Different data are not a likelihood ratio.
  expect_error(drm_lrtest(drm_mc_fit(bf(y ~ 1, sigma ~ 1), dat[1:60, ]), full), "observations")
})

test_that("drm_lrtest() REML guard: same mean structure passes, different errors (comparison.jl:133-142)", {
  dat <- drm_mc_fixture_1()
  full <- drm_mc_fit(bf(y ~ x, sigma ~ z), dat, REML = TRUE)
  same_mean <- drm_mc_fit(bf(y ~ x, sigma ~ 1), dat, REML = TRUE)
  diff_mean <- drm_mc_fit(bf(y ~ 1, sigma ~ z), dat, REML = TRUE)
  t <- drm_lrtest(same_mean, full)
  expect_identical(t$df, 1)
  expect_true(t$p.value >= 0 && t$p.value <= 1)
  expect_error(drm_lrtest(diff_mean, full), class = "drmTMB_lrtest_reml_error")
})

test_that("drm_lrtest() refuses penalized (MAP) fits (comparison.jl:151-158)", {
  dat <- drm_mc_fixture_1()
  full <- drm_mc_fit(bf(y ~ x, sigma ~ z), dat)
  reduced <- drm_mc_fit(bf(y ~ 1, sigma ~ 1), dat)
  map <- full
  map$estimator <- "MAP"
  expect_error(drm_lrtest(reduced, map), class = "drmTMB_lrtest_map_error")
})

test_that("drm_lrtest() warns on a boundary variance-component null (comparison.jl:101-114)", {
  dat <- drm_mc_fixture_1()
  dat$g <- factor(rep(seq_len(12), each = 10))
  full <- drm_mc_fit(bf(y ~ x + (1 | g), sigma ~ z), dat)
  reduced <- drm_mc_fit(bf(y ~ x, sigma ~ z), dat)
  expect_identical(drm_lrtest_vc_labels(full), "mu:(1 | g)")
  expect_identical(drm_lrtest_vc_labels(reduced), character(0))
  expect_warning(
    t <- drm_lrtest(reduced, full),
    class = "drmTMB_lrtest_boundary_warning"
  )
  expect_identical(t$df, 1)
  # Same variance structure on both sides: silent.
  expect_silent(drm_lrtest(drm_mc_fit(bf(y ~ 1 + (1 | g), sigma ~ z), dat), full))
})

# Native DRM.jl oracle: the same fixtures fit inside DRM.jl at the pin, with
# aicc()/lrtest() evaluated by DRM.jl itself, against the R port applied to
# (a) the engine = "julia" object and (b) the engine = "tmb" object.
drm_mc_julia_native <- function(dat, full_mu, full_sigma, red_mu, red_sigma) {
  JuliaCall::julia_assign("drm_mc_rdat", dat)
  cols <- paste(
    vapply(names(dat), function(v) sprintf("%s = Float64.(drm_mc_rdat.%s)", v, v), character(1)),
    collapse = ", "
  )
  JuliaCall::julia_command(sprintf("drm_mc_dat = (; %s);", cols))
  JuliaCall::julia_command(sprintf(
    "drm_mc_full = DRM.drm(DRM.bf(DRM.@formula(%s), DRM.@formula(%s)), DRM.Gaussian(); data = drm_mc_dat);",
    full_mu, full_sigma
  ))
  JuliaCall::julia_command(sprintf(
    "drm_mc_red = DRM.drm(DRM.bf(DRM.@formula(%s), DRM.@formula(%s)), DRM.Gaussian(); data = drm_mc_dat);",
    red_mu, red_sigma
  ))
  out <- JuliaCall::julia_eval(
    "let t = DRM.lrtest(drm_mc_red, drm_mc_full); [DRM.aicc(drm_mc_full), DRM.aicc(drm_mc_red), t.statistic, Float64(t.dof), t.pvalue] end"
  )
  list(aicc_full = out[[1]], aicc_red = out[[2]], statistic = out[[3]], df = out[[4]], p.value = out[[5]])
}

test_that("aicc()/drm_lrtest() agree with native DRM.jl on two committed fixtures", {
  drm_skip_live_julia()
  fixtures <- list(
    list(
      dat = drm_mc_fixture_1(),
      full = bf(y ~ x, sigma ~ z), reduced = bf(y ~ 1, sigma ~ 1),
      jl = c("y ~ 1 + x", "sigma ~ 1 + z", "y ~ 1", "sigma ~ 1")
    ),
    list(
      dat = drm_mc_fixture_2(),
      full = bf(y ~ x, sigma ~ 1), reduced = bf(y ~ 1, sigma ~ 1),
      jl = c("y ~ 1 + x", "sigma ~ 1", "y ~ 1", "sigma ~ 1")
    )
  )
  for (fx in fixtures) {
    fj_full <- drm_mc_fit(fx$full, fx$dat, engine = "julia")
    fj_red <- drm_mc_fit(fx$reduced, fx$dat, engine = "julia")
    ft_full <- drm_mc_fit(fx$full, fx$dat, engine = "tmb")
    ft_red <- drm_mc_fit(fx$reduced, fx$dat, engine = "tmb")
    native <- drm_mc_julia_native(fx$dat, fx$jl[1], fx$jl[2], fx$jl[3], fx$jl[4])
    # (a) formula parity on DRM.jl's own log-likelihood: 1e-8 on every quantity.
    tj <- drm_lrtest(fj_red, fj_full)
    expect_lt(abs(aicc(fj_full) - native$aicc_full), 1e-8)
    expect_lt(abs(aicc(fj_red) - native$aicc_red), 1e-8)
    expect_lt(abs(tj$statistic - native$statistic), 1e-8)
    expect_identical(tj$df, native$df)
    expect_lt(abs(tj$p.value - native$p.value), 1e-8)
    # (b) cross-engine: TMB's optimum against DRM.jl's. Information criteria
    # and the LR statistic inherit the two engines' log-likelihood gap, measured
    # at <= 2e-12 on both fixtures (2026-09-04, pin 430ef64cc), so the 1e-8
    # bar holds here with four orders of headroom.
    tt <- drm_lrtest(ft_red, ft_full)
    expect_lt(abs(aicc(ft_full) - native$aicc_full), 1e-8)
    expect_lt(abs(aicc(ft_red) - native$aicc_red), 1e-8)
    expect_lt(abs(tt$statistic - native$statistic), 1e-8)
    expect_identical(tt$df, native$df)
    expect_lt(abs(tt$p.value - native$p.value), 1e-8)
  }
})
