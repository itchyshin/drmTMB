test_that("public inference refuses an SD-prior MAP fit", {
  d <- data.frame(x = rep(c(-1, 0, 1), 4), site = factor(rep(1:4, each = 3)))
  d$y <- 0.3 + 0.5*d$x + rep(c(-0.5, 0.2, 0.4, -0.1), each = 3) +
    rep(c(0.1, -0.2, 0.15), 4)
  formula <- bf(mu = y ~ x + (1 | site), sigma = ~ 1)
  priors <- drm_priors(drm_prior_sd_gamma(group = "site", shape = 2.5, rate = 1.7))
  fit <- suppressWarnings(drmTMB(formula, data = d, priors = priors))
  plain <- suppressWarnings(drmTMB(formula, data = d))
  reduced <- suppressWarnings(drmTMB(bf(mu = y ~ 1 + (1 | site), sigma = ~ 1),
                                    data = d, priors = priors))
  expect_identical(fit$estimator, "MAP")
  expect_error(confint(fit, method = "bootstrap", R = 2), "prior")
  expect_error(profile(fit, parm = "sigma"), "prior")
  expect_error(summary(fit, conf.int = TRUE), "prior")
  expect_error(predict_parameters(fit, conf.int = TRUE), "prior")
  expect_warning(aic_value <- AIC(fit), class = "drmTMB_ic_map_warning")
  expect_warning(bic_value <- BIC(fit), class = "drmTMB_ic_map_warning")
  expect_warning(aicc_value <- aicc(fit), class = "drmTMB_ic_map_warning")
  expect_equal(aic_value, -2 * fit$logLik + 2 * fit$df)
  expect_equal(bic_value, -2 * fit$logLik + log(fit$nobs) * fit$df)
  expect_equal(
    aicc_value,
    -2 * fit$logLik + 2 * fit$df +
      2 * fit$df * (fit$df + 1) / (fit$nobs - fit$df - 1)
  )
  expect_warning(
    expect_error(anova(plain, fit), class = "drmTMB_anova_estimator_error"),
    class = "drmTMB_lrtest_map_warning"
  )
  expect_warning(
    expect_error(anova(reduced, fit), "prior"),
    class = "drmTMB_lrtest_map_warning"
  )
  expect_warning(
    expect_error(anova(fit, fit), class = "drmTMB_anova_map_error"),
    class = "drmTMB_lrtest_map_warning"
  )
  fewer_rows <- suppressWarnings(
    drmTMB(formula, data = d[-1, , drop = FALSE], priors = priors)
  )
  expect_false(identical(nobs(fit), nobs(fewer_rows)))
  expect_warning(
    expect_error(drmTMB:::drm_lrtest(fit, fewer_rows), "penalized"),
    class = "drmTMB_lrtest_map_warning"
  )
  reml_different_mean <- suppressWarnings(
    drmTMB(bf(mu = y ~ 1 + (1 | site), sigma = ~ 1),
           data = d, REML = TRUE)
  )
  expect_warning(
    expect_error(drmTMB:::drm_lrtest(reml_different_mean, fit), "penalized"),
    class = "drmTMB_lrtest_map_warning"
  )
})
