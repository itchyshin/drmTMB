unknown_dpar_message <- function(err) {
  if (!inherits(err, "condition")) {
    return("")
  }
  paste(c(conditionMessage(err), format(err)), collapse = "\n")
}

test_that("coef() and fixef() require an exact fitted dpar name (#1698)", {
  set.seed(1)
  dat <- data.frame(y = rnorm(20), x = rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_identical(coef(fit, dpar = "sigma"), fit$coefficients$sigma)
  expect_identical(fixef(fit, dpar = "mu"), fit$coefficients$mu)
  expect_identical(fixef(fit, dpar = "sigma"), coef(fit, dpar = "sigma"))
  expect_identical(names(coef(fit)), c("mu", "sigma"))

  expect_error(coef(fit, dpar = "s"), class = "drmTMB_unknown_dpar")
  err <- tryCatch(coef(fit, dpar = "s"), error = identity)
  msg <- unknown_dpar_message(err)
  expect_match(msg, "exactly match")
  expect_match(msg, "Did you mean[^\n]*sigma")
  expect_no_match(msg, "Did you mean[^\n]*mu")
  expect_match(msg, "coef")
  expect_no_match(msg, "drm_resolve_fitted_dpar_name")
  expect_no_match(msg, "drm_abort_unknown_fitted_dpar")

  expect_error(fixef(fit, dpar = "s"), class = "drmTMB_unknown_dpar")
})

test_that("coef(), fixef(), and predict() agree on invalid dpar abbreviations", {
  set.seed(1)
  dat <- data.frame(y = rnorm(20), x = rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_error(coef(fit, dpar = "s"), class = "drmTMB_unknown_dpar")
  expect_match(
    unknown_dpar_message(tryCatch(coef(fit, dpar = "s"), error = identity)),
    "Did you mean[^\n]*sigma"
  )

  expect_error(fixef(fit, dpar = "s"), class = "drmTMB_unknown_dpar")
  expect_match(
    unknown_dpar_message(tryCatch(fixef(fit, dpar = "s"), error = identity)),
    "Did you mean[^\n]*sigma"
  )

  expect_error(predict(fit, dpar = "s"), class = "drmTMB_unknown_dpar")
  pred_err <- tryCatch(predict(fit, dpar = "s"), error = identity)
  pred_msg <- unknown_dpar_message(pred_err)
  expect_match(pred_msg, "Did you mean[^\n]*sigma")
  expect_match(pred_msg, "predict")
  expect_no_match(pred_msg, "drm_resolve_fitted_dpar_name")
})

test_that("unknown dpar suggestions use prefixes, case-insensitive ties, and a cutoff", {
  set.seed(1)
  dat <- data.frame(y = rnorm(20), x = rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_error(coef(fit, dpar = "s"), class = "drmTMB_unknown_dpar")
  expect_match(
    unknown_dpar_message(tryCatch(coef(fit, dpar = "s"), error = identity)),
    "Did you mean[^\n]*sigma"
  )

  expect_error(coef(fit, dpar = "SIGMA"), class = "drmTMB_unknown_dpar")
  expect_match(
    unknown_dpar_message(tryCatch(coef(fit, dpar = "SIGMA"), error = identity)),
    "Did you mean[^\n]*sigma"
  )

  expect_error(coef(fit, dpar = "zzz"), class = "drmTMB_unknown_dpar")
  far_msg <- unknown_dpar_message(
    tryCatch(coef(fit, dpar = "zzz"), error = identity)
  )
  expect_match(far_msg, "exactly match")
  expect_no_match(far_msg, "Did you mean")
})

test_that("an ambiguous mu prefix lists every mu1/mu2 match instead of picking mu1", {
  stub <- structure(
    list(
      coefficients = list(
        mu1 = c("(Intercept)" = 0),
        mu2 = c("(Intercept)" = 0)
      )
    ),
    class = "drmTMB"
  )
  expect_error(coef(stub, dpar = "mu"), class = "drmTMB_unknown_dpar")
  msg <- unknown_dpar_message(
    tryCatch(coef(stub, dpar = "mu"), error = identity)
  )
  expect_match(msg, "Did you mean[^\n]*mu1")
  expect_match(msg, "Did you mean[^\n]*mu2")
})

test_that("drm_fixed_effect_basis() uses the same exact dpar rule", {
  set.seed(1)
  dat <- data.frame(y = rnorm(20), x = rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)

  expect_error(
    drmTMB:::drm_fixed_effect_basis(fit, dpar = "s"),
    class = "drmTMB_unknown_dpar"
  )
  expect_match(
    unknown_dpar_message(
      tryCatch(
        drmTMB:::drm_fixed_effect_basis(fit, dpar = "s"),
        error = identity
      )
    ),
    "Did you mean[^\n]*sigma"
  )
  expect_identical(
    drmTMB:::drm_fixed_effect_basis(fit, dpar = "sigma")$dpar,
    "sigma"
  )
})

test_that("drm_suggest_closest_name lists every prefix or adist tie", {
  suggest <- function(...) {
    tryCatch(drmTMB:::drm_suggest_closest_name(...), error = identity)
  }
  choices <- c("mu", "sigma", "sd(id)")
  expect_identical(suggest("s", choices), c("sigma", "sd(id)"))
  expect_identical(suggest("SIGMA", choices), "sigma")
  expect_null(suggest("zzz", choices))
  expect_identical(suggest("mu", c("mu1", "mu2")), c("mu1", "mu2"))
  expect_identical(suggest("ad", c("ab", "ac")), c("ab", "ac"))
})
