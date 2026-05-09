test_that("internal link table maps implemented distributional parameters", {
  fake_gaussian <- list(model = list(model_type = "gaussian"))
  fake_student <- list(model = list(model_type = "student"))
  fake_lognormal <- list(model = list(model_type = "lognormal"))
  fake_gamma <- list(model = list(model_type = "gamma"))
  fake_beta <- list(model = list(model_type = "beta"))
  fake_poisson <- list(model = list(model_type = "poisson"))
  fake_zip <- list(model = list(model_type = "zi_poisson"))
  fake_nbinom2 <- list(model = list(model_type = "nbinom2"))
  fake_truncnb2 <- list(model = list(model_type = "truncated_nbinom2"))
  fake_zinb2 <- list(model = list(model_type = "zi_nbinom2"))
  fake_biv <- list(model = list(model_type = "biv_gaussian"))

  expect_equal(drmTMB:::drm_dpar_link(fake_gaussian, "mu"), "identity")
  expect_equal(drmTMB:::drm_dpar_link(fake_gaussian, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_student, "nu"), "logm2")
  expect_equal(drmTMB:::drm_dpar_link(fake_lognormal, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_gamma, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_gamma, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_beta, "mu"), "logit")
  expect_equal(drmTMB:::drm_dpar_link(fake_beta, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_poisson, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_zip, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_zip, "zi"), "logit")
  expect_equal(drmTMB:::drm_dpar_link(fake_nbinom2, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_nbinom2, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_truncnb2, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_truncnb2, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_zinb2, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_zinb2, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_zinb2, "zi"), "logit")
  expect_equal(drmTMB:::drm_dpar_link(fake_biv, "rho12"), "atanh_guarded")
  expect_equal(unname(biv_gaussian()$links[["rho12"]]), "atanh_guarded")
  expect_equal(unname(nbinom2()$links[["mu"]]), "log")
  expect_equal(unname(nbinom2()$links[["sigma"]]), "log")
  expect_equal(unname(truncated_nbinom2()$links[["mu"]]), "log")
  expect_equal(unname(truncated_nbinom2()$links[["sigma"]]), "log")
  expect_equal(unname(beta()$links[["mu"]]), "logit")
  expect_equal(unname(beta()$links[["sigma"]]), "log")
})

test_that("internal inverse links match the documented parameter scales", {
  fake_gaussian <- list(model = list(model_type = "gaussian"))
  fake_student <- list(model = list(model_type = "student"))
  fake_gamma <- list(model = list(model_type = "gamma"))
  fake_beta <- list(model = list(model_type = "beta"))
  fake_poisson <- list(model = list(model_type = "poisson"))
  fake_zip <- list(model = list(model_type = "zi_poisson"))
  fake_nbinom2 <- list(model = list(model_type = "nbinom2"))
  fake_truncnb2 <- list(model = list(model_type = "truncated_nbinom2"))
  fake_zinb2 <- list(model = list(model_type = "zi_nbinom2"))
  fake_biv <- list(model = list(model_type = "biv_gaussian"))
  eta <- c(-1, 0, 1)

  expect_equal(drmTMB:::drm_inverse_link(fake_gaussian, "mu", eta), eta)
  expect_equal(drmTMB:::drm_inverse_link(fake_gaussian, "sigma", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_student, "nu", eta), 2 + exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_gamma, "mu", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_gamma, "sigma", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_beta, "mu", eta), stats::plogis(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_beta, "sigma", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_poisson, "mu", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_zip, "mu", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_zip, "zi", eta), stats::plogis(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_nbinom2, "mu", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_nbinom2, "sigma", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_truncnb2, "mu", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_truncnb2, "sigma", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_zinb2, "mu", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_zinb2, "sigma", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_zinb2, "zi", eta), stats::plogis(eta))
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
  dat_zip <- data.frame(
    y = c(0, 0, 1, 0, 2, 4, 0, 3, 0, 5, 1, 0),
    x = rep(dat$x, length.out = 12),
    z = rep(c(-1, 0, 1), length.out = 12)
  )
  fit_zip <- drmTMB(
    bf(y ~ x, zi ~ z),
    family = stats::poisson(link = "log"),
    data = dat_zip
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
  p0_trunc <- stats::dnbinom(
    0,
    size = 1 / 0.45^2,
    mu = exp(0.2 + 0.5 * dat_nbinom2$x)
  )
  dat_truncnb2 <- dat_nbinom2
  dat_truncnb2$y <- stats::qnbinom(
    p0_trunc + seq(0.1, 0.9, length.out = nrow(dat_truncnb2)) * (1 - p0_trunc),
    size = 1 / 0.45^2,
    mu = exp(0.2 + 0.5 * dat_nbinom2$x)
  )
  fit_truncnb2 <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = truncated_nbinom2(),
    data = dat_truncnb2
  )
  set.seed(20260619)
  dat_beta <- data.frame(
    x = rep(seq(-1, 1, length.out = 20), each = 4)
  )
  mu_beta <- stats::plogis(-0.2 + 0.6 * dat_beta$x)
  sigma_beta <- exp(-0.8)
  dat_beta$y <- stats::rbeta(
    nrow(dat_beta),
    shape1 = mu_beta / sigma_beta^2,
    shape2 = (1 - mu_beta) / sigma_beta^2
  )
  fit_beta <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = beta(),
    data = dat_beta
  )
  fit_zinb2 <- drmTMB(
    bf(y ~ x, sigma ~ 1, zi ~ x),
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
    fitted(fit_zip),
    (1 - predict(fit_zip, dpar = "zi")) * predict(fit_zip, dpar = "mu"),
    tolerance = 1e-12
  )
  expect_equal(
    fitted(fit_nbinom2),
    predict(fit_nbinom2, dpar = "mu"),
    tolerance = 1e-12
  )
  mu_truncnb2 <- predict(fit_truncnb2, dpar = "mu")
  sigma_truncnb2 <- sigma(fit_truncnb2)
  p0_truncnb2 <- stats::dnbinom(0, size = 1 / sigma_truncnb2^2, mu = mu_truncnb2)
  expect_equal(
    fitted(fit_truncnb2),
    mu_truncnb2 / (1 - p0_truncnb2),
    tolerance = 1e-12
  )
  expect_equal(
    fitted(fit_beta),
    predict(fit_beta, dpar = "mu"),
    tolerance = 1e-12
  )
  expect_equal(
    fitted(fit_zinb2),
    (1 - predict(fit_zinb2, dpar = "zi")) * predict(fit_zinb2, dpar = "mu"),
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
