# R/model-comparison.R guards and anova boundary logic (no full optimizer ladders).

fake_fit <- function(
  estimator = "ML",
  mu_names = c("(Intercept)", "x"),
  sdpars = list(mu = stats::setNames(0.3, "(Intercept)")),
  corpars = list(),
  logLik = -10,
  df = 3,
  nobs = 20
) {
  mu_coef <- stats::setNames(rep(0.1, length(mu_names)), mu_names)
  structure(
    list(
      estimator = estimator,
      coefficients = list(mu = mu_coef),
      sdpars = sdpars,
      corpars = corpars,
      logLik = logLik,
      df = df,
      nobs = nobs
    ),
    class = "drmTMB"
  )
}

test_that("drm_fit_estimator() defaults missing estimator to ML", {
  expect_identical(drmTMB:::drm_fit_estimator(list()), "ML")
  expect_identical(drmTMB:::drm_fit_estimator(list(estimator = "REML")), "REML")
  expect_identical(drmTMB:::drm_fit_estimator(list(estimator = NULL)), "ML")
})

test_that("drm_lrtest_mean_structure() flattens mu coefficient names", {
  reduced <- fake_fit(mu_names = c("(Intercept)", "x"))
  full <- fake_fit(mu_names = c("(Intercept)", "x", "z"))
  expect_identical(
    drmTMB:::drm_lrtest_mean_structure(reduced),
    c("mu (Intercept)", "mu x")
  )
  expect_length(drmTMB:::drm_lrtest_mean_structure(full), 3L)
  biv <- fake_fit(mu_names = character())
  biv$coefficients <- list(mu1 = c("(Intercept)" = 0), mu2 = c("(Intercept)" = 0))
  expect_true(all(grepl("^mu", drmTMB:::drm_lrtest_mean_structure(biv))))
})

test_that("drm_anova_vc_labels() expands sdpars and corpars", {
  fit <- fake_fit(
    sdpars = list(mu = c("(Intercept)" = 0.2, "x" = 0.1), sigma = c("(Intercept)" = 0.05)),
    corpars = list(phylo = c("mu1:mu2" = 0.1))
  )
  sd <- drmTMB:::drm_anova_vc_labels(fit, "sdpars")
  expect_true("mu:(Intercept)" %in% sd)
  expect_true("sigma:(Intercept)" %in% sd)
  cor <- drmTMB:::drm_anova_vc_labels(fit, "corpars")
  expect_identical(cor, "phylo:mu1:mu2")
  empty <- drmTMB:::drm_anova_vc_labels(fake_fit(sdpars = list(), corpars = list()), "sdpars")
  expect_identical(empty, character())
})

test_that("drm_anova_boundary() detects one added SD with matching df", {
  reduced <- fake_fit(
    sdpars = list(mu = c("(Intercept)" = 0.3)),
    df = 3,
    corpars = list()
  )
  full <- fake_fit(
    sdpars = list(
      mu = c("(Intercept)" = 0.3, "(1 | g)" = 0.2)
    ),
    df = 4,
    corpars = list()
  )
  hit <- drmTMB:::drm_anova_boundary(reduced, full)
  expect_identical(hit$added_sd, "mu:(1 | g)")
  expect_equal(hit$q, 1L)
  expect_true(hit$applies)
  extra <- fake_fit(
    sdpars = list(mu = c("(Intercept)" = 0.3, "(1 | g)" = 0.2, "(1 | h)" = 0.1)),
    df = 5
  )
  hit2 <- drmTMB:::drm_anova_boundary(reduced, extra)
  expect_equal(hit2$q, 2L)
  expect_true(hit2$applies)
  with_cor <- fake_fit(
    sdpars = list(mu = stats::setNames(0.3, "(Intercept)")),
    corpars = list(phylo = stats::setNames(0.2, "mu1:mu2")),
    df = 4
  )
  miss <- drmTMB:::drm_anova_boundary(reduced, with_cor)
  expect_false(miss$applies)
})

test_that("drm_lrtest_reml_guard() and drm_lrtest_map_guard() refuse bad comparisons", {
  r1 <- fake_fit(estimator = "REML", mu_names = c("(Intercept)", "x"))
  r2 <- fake_fit(estimator = "REML", mu_names = c("(Intercept)"))
  expect_error(
    drmTMB:::drm_lrtest_reml_guard(r2, r1),
    class = "drmTMB_lrtest_reml_error"
  )
  map <- fake_fit(estimator = "MAP")
  expect_error(
    drmTMB:::drm_lrtest_map_guard(map, r1),
    class = "drmTMB_lrtest_map_error"
  )
  expect_invisible(drmTMB:::drm_lrtest_map_guard(r1, r2))
})

test_that("drm_aicc_from_loglik() matches the closed form and saturates", {
  f <- drmTMB:::drm_aicc_from_loglik
  expect_error(f(-1, k = NULL, n = 10), "df")
  expect_identical(f(-1, k = 2, n = 2), Inf)
  expect_identical(f(-1, k = 2, n = 3), Inf)
  expect_equal(f(-1, k = 2, n = 4), 2 + 4 + 2 * 2 * 3 / 1)
  expect_equal(f(-100, k = 3, n = 50), -2 * (-100) + 2 * 3 + 2 * 3 * 4 / 46)
})

test_that("drm_anova_lrt() validates test argument and engine", {
  fits <- list(fake_fit(), fake_fit(df = 4))
  expect_error(
    drmTMB:::drm_anova_lrt(fits, c("m1", "m2"), test = "F"),
    "test"
  )
  julia <- fake_fit(df = 4)
  class(julia) <- "drmTMB_julia"
  expect_error(
    drmTMB:::drm_anova_lrt(list(fake_fit(df = 3), julia), c("tmb", "julia")),
    "engine"
  )
  expect_error(
    drmTMB:::drm_anova_lrt(list(fake_fit()), c("only")),
    "at least two"
  )
})