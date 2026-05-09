test_that("internal link table maps implemented distributional parameters", {
  fake_gaussian <- list(model = list(model_type = "gaussian"))
  fake_student <- list(model = list(model_type = "student"))
  fake_lognormal <- list(model = list(model_type = "lognormal"))
  fake_biv <- list(model = list(model_type = "biv_gaussian"))

  expect_equal(drmTMB:::drm_dpar_link(fake_gaussian, "mu"), "identity")
  expect_equal(drmTMB:::drm_dpar_link(fake_gaussian, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_student, "nu"), "logm2")
  expect_equal(drmTMB:::drm_dpar_link(fake_lognormal, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_biv, "rho12"), "atanh_guarded")
  expect_equal(unname(biv_gaussian()$links[["rho12"]]), "atanh_guarded")
})

test_that("internal inverse links match the documented parameter scales", {
  fake_gaussian <- list(model = list(model_type = "gaussian"))
  fake_student <- list(model = list(model_type = "student"))
  fake_biv <- list(model = list(model_type = "biv_gaussian"))
  eta <- c(-1, 0, 1)

  expect_equal(drmTMB:::drm_inverse_link(fake_gaussian, "mu", eta), eta)
  expect_equal(drmTMB:::drm_inverse_link(fake_gaussian, "sigma", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_student, "nu", eta), 2 + exp(eta))
  expect_equal(
    drmTMB:::drm_inverse_link(fake_biv, "rho12", eta),
    0.99999999 * tanh(eta)
  )
})

test_that("fitted response helper uses family-specific response summaries", {
  dat <- data.frame(
    y = exp(c(-0.5, -0.1, 0.25, 0.55, 0.9, 1.1)),
    x = c(-1, -0.4, 0, 0.3, 0.8, 1.2)
  )
  fit_lognormal <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = lognormal(),
    data = dat
  )
  dat_gaussian <- data.frame(
    y = c(-0.8, -0.25, 0.1, 0.35, 0.7, 1.05),
    x = dat$x
  )
  fit_gaussian <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat_gaussian
  )

  expect_equal(
    fitted(fit_lognormal),
    exp(predict(fit_lognormal, dpar = "mu") + 0.5 * sigma(fit_lognormal)^2),
    tolerance = 1e-12
  )
  expect_equal(
    fitted(fit_gaussian),
    predict(fit_gaussian, dpar = "mu"),
    tolerance = 1e-12
  )
})

test_that("internal link helpers reject unsupported routing", {
  fake_unknown <- list(model = list(model_type = "unknown"))
  fake_gaussian <- list(model = list(model_type = "gaussian"))

  expect_error(
    drmTMB:::drm_dpar_link(fake_unknown, "mu"),
    "no link table"
  )
  expect_error(
    drmTMB:::drm_dpar_link(fake_gaussian, "rho12"),
    "no link entry"
  )
  expect_error(
    drmTMB:::drm_fitted_response(fake_unknown),
    "no fitted-response rule"
  )
})
