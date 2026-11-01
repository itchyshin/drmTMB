test_that("Bernoulli SD-regression coefficients profile their beta_sd_mu slots", {
  sim <- binomial_sd_fixture(groups = 120L, repeats = 12L)
  fit <- drmTMB(
    bf(y ~ x + (1 | id), sd(id) ~ w),
    family = binomial(),
    data = sim$data
  )

  expect_equal(fit$opt$convergence, 0L)
  expect_true(fit$sdr$pdHess)

  targets <- profile_targets(fit)
  alpha_targets <- targets[
    targets$parm %in%
      c(
        "fixef:sd(id):(Intercept)",
        "fixef:sd(id):w"
      ),
    ,
    drop = FALSE
  ]
  expect_equal(
    alpha_targets$parm,
    c("fixef:sd(id):(Intercept)", "fixef:sd(id):w")
  )
  expect_equal(alpha_targets$tmb_parameter, rep("beta_sd_mu", 2L))
  expect_equal(alpha_targets$index, 1:2)
  expect_equal(alpha_targets$scale, rep("link", 2L))
  expect_true(all(alpha_targets$profile_ready))
  expect_equal(
    alpha_targets$estimate,
    unname(coef(fit, "sd(id)")[c("(Intercept)", "w")])
  )

  ci <- stats::confint(
    fit,
    parm = "fixef:sd(id):w",
    level = 0.975,
    method = "profile",
    trace = FALSE
  )
  alpha_w <- unname(coef(fit, "sd(id)")[["w"]])
  expect_equal(ci$parm, "fixef:sd(id):w")
  expect_equal(ci$tmb_parameter, "beta_sd_mu")
  expect_equal(ci$index, 2L)
  expect_equal(ci$scale, "link")
  expect_true(all(is.finite(c(ci$lower, ci$upper))))
  expect_lt(ci$lower, alpha_w)
  expect_gt(ci$upper, alpha_w)
  expect_lt(ci$lower, ci$upper)

  limited <- stats::confint(
    fit,
    parm = "fixef:sd(id):w",
    level = 0.975,
    method = "profile",
    trace = FALSE,
    ytol = 2
  )
  expect_equal(limited$conf.status, "profile_failed")
  expect_equal(limited$profile.message, "nonfinite_interval")
  expect_true(all(is.na(c(limited$lower, limited$upper))))

  curve <- profile(
    fit,
    parm = "fixef:sd(id):w",
    level = 0.975,
    trace = FALSE
  )
  expect_true(any(curve$delta_deviance >= stats::qchisq(0.975, df = 1)))
})
