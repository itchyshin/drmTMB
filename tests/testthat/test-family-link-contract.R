test_that("internal link table maps implemented distributional parameters", {
  fake_gaussian <- list(model = list(model_type = "gaussian"))
  fake_student <- list(model = list(model_type = "student"))
  fake_lognormal <- list(model = list(model_type = "lognormal"))
  fake_gamma <- list(model = list(model_type = "gamma"))
  fake_poisson <- list(model = list(model_type = "poisson"))
  fake_nbinom2 <- list(model = list(model_type = "nbinom2"))
  fake_biv <- list(model = list(model_type = "biv_gaussian"))

  expect_equal(drmTMB:::drm_dpar_link(fake_gaussian, "mu"), "identity")
  expect_equal(drmTMB:::drm_dpar_link(fake_gaussian, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_student, "nu"), "logm2")
  expect_equal(drmTMB:::drm_dpar_link(fake_lognormal, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_gamma, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_gamma, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_poisson, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_nbinom2, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_nbinom2, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_biv, "rho12"), "atanh_guarded")
  expect_equal(unname(biv_gaussian()$links[["rho12"]]), "atanh_guarded")
  expect_equal(unname(nbinom2()$links[["mu"]]), "log")
  expect_equal(unname(nbinom2()$links[["sigma"]]), "log")
})

test_that("internal inverse links match the documented parameter scales", {
  fake_gaussian <- list(model = list(model_type = "gaussian"))
  fake_student <- list(model = list(model_type = "student"))
  fake_gamma <- list(model = list(model_type = "gamma"))
  fake_poisson <- list(model = list(model_type = "poisson"))
  fake_nbinom2 <- list(model = list(model_type = "nbinom2"))
  fake_biv <- list(model = list(model_type = "biv_gaussian"))
  eta <- c(-1, 0, 1)

  expect_equal(drmTMB:::drm_inverse_link(fake_gaussian, "mu", eta), eta)
  expect_equal(drmTMB:::drm_inverse_link(fake_gaussian, "sigma", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_student, "nu", eta), 2 + exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_gamma, "mu", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_gamma, "sigma", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_poisson, "mu", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_nbinom2, "mu", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_nbinom2, "sigma", eta), exp(eta))
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
  dat_poisson <- data.frame(
    y = c(0, 1, 1, 2, 3, 5),
    x = dat$x
  )
  fit_poisson <- drmTMB(
    bf(y ~ x),
    family = stats::poisson(link = "log"),
    data = dat_poisson
  )
  set.seed(20260607)
  dat_nbinom2 <- data.frame(x = rep(seq(-1, 1, length.out = 20), each = 4))
  dat_nbinom2$y <- stats::rnbinom(
    nrow(dat_nbinom2),
    size = 1 / 0.45^2,
    mu = exp(0.2 + 0.5 * dat_nbinom2$x)
  )
  fit_nbinom2 <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = nbinom2(),
    data = dat_nbinom2
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
  expect_equal(
    fitted(fit_poisson),
    predict(fit_poisson, dpar = "mu"),
    tolerance = 1e-12
  )
  expect_equal(
    fitted(fit_nbinom2),
    predict(fit_nbinom2, dpar = "mu"),
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
