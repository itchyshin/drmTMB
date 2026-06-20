test_that("internal link table maps implemented distributional parameters", {
  fake_gaussian <- list(model = list(model_type = "gaussian"))
  fake_student <- list(model = list(model_type = "student"))
  fake_skew_normal <- list(model = list(model_type = "skew_normal"))
  fake_lognormal <- list(model = list(model_type = "lognormal"))
  fake_gamma <- list(model = list(model_type = "gamma"))
  fake_tweedie <- list(model = list(model_type = "tweedie"))
  fake_beta <- list(model = list(model_type = "beta"))
  fake_zero_one_beta <- list(model = list(model_type = "zero_one_beta"))
  fake_poisson <- list(model = list(model_type = "poisson"))
  fake_zip <- list(model = list(model_type = "zi_poisson"))
  fake_nbinom2 <- list(model = list(model_type = "nbinom2"))
  fake_truncnb2 <- list(model = list(model_type = "truncated_nbinom2"))
  fake_hurdlenb2 <- list(model = list(model_type = "hurdle_nbinom2"))
  fake_zinb2 <- list(model = list(model_type = "zi_nbinom2"))
  fake_biv <- list(model = list(model_type = "biv_gaussian"))

  expect_equal(drmTMB:::drm_dpar_link(fake_gaussian, "mu"), "identity")
  expect_equal(drmTMB:::drm_dpar_link(fake_gaussian, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_student, "nu"), "logm2")
  expect_equal(drmTMB:::drm_dpar_link(fake_skew_normal, "mu"), "identity")
  expect_equal(drmTMB:::drm_dpar_link(fake_skew_normal, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_skew_normal, "nu"), "identity")
  expect_equal(drmTMB:::drm_dpar_link(fake_lognormal, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_gamma, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_gamma, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_tweedie, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_tweedie, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_tweedie, "nu"), "logit12")
  expect_equal(drmTMB:::drm_dpar_link(fake_beta, "mu"), "logit")
  expect_equal(drmTMB:::drm_dpar_link(fake_beta, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_zero_one_beta, "mu"), "logit")
  expect_equal(drmTMB:::drm_dpar_link(fake_zero_one_beta, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_zero_one_beta, "zoi"), "logit")
  expect_equal(drmTMB:::drm_dpar_link(fake_zero_one_beta, "coi"), "logit")
  expect_equal(drmTMB:::drm_dpar_link(fake_poisson, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_zip, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_zip, "zi"), "logit")
  expect_equal(drmTMB:::drm_dpar_link(fake_nbinom2, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_nbinom2, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_truncnb2, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_truncnb2, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_hurdlenb2, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_hurdlenb2, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_hurdlenb2, "hu"), "logit")
  expect_equal(drmTMB:::drm_dpar_link(fake_zinb2, "mu"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_zinb2, "sigma"), "log")
  expect_equal(drmTMB:::drm_dpar_link(fake_zinb2, "zi"), "logit")
  expect_equal(drmTMB:::drm_dpar_link(fake_biv, "rho12"), "atanh_guarded")
  expect_equal(unname(biv_gaussian()$links[["rho12"]]), "atanh_guarded")
  expect_equal(unname(nbinom2()$links[["mu"]]), "log")
  expect_equal(unname(nbinom2()$links[["sigma"]]), "log")
  expect_equal(unname(tweedie()$links[["mu"]]), "log")
  expect_equal(unname(tweedie()$links[["sigma"]]), "log")
  expect_equal(unname(tweedie()$links[["nu"]]), "logit12")
  expect_equal(unname(skew_normal()$links[["mu"]]), "identity")
  expect_equal(unname(skew_normal()$links[["sigma"]]), "log")
  expect_equal(unname(skew_normal()$links[["nu"]]), "identity")
  expect_equal(unname(truncated_nbinom2()$links[["mu"]]), "log")
  expect_equal(unname(truncated_nbinom2()$links[["sigma"]]), "log")
  expect_equal(unname(beta()$links[["mu"]]), "logit")
  expect_equal(unname(beta()$links[["sigma"]]), "log")
  expect_equal(unname(zero_one_beta()$links[["mu"]]), "logit")
  expect_equal(unname(zero_one_beta()$links[["sigma"]]), "log")
  expect_equal(unname(zero_one_beta()$links[["zoi"]]), "logit")
  expect_equal(unname(zero_one_beta()$links[["coi"]]), "logit")
})

test_that("internal inverse links match the documented parameter scales", {
  fake_gaussian <- list(model = list(model_type = "gaussian"))
  fake_student <- list(model = list(model_type = "student"))
  fake_skew_normal <- list(model = list(model_type = "skew_normal"))
  fake_gamma <- list(model = list(model_type = "gamma"))
  fake_tweedie <- list(model = list(model_type = "tweedie"))
  fake_beta <- list(model = list(model_type = "beta"))
  fake_zero_one_beta <- list(model = list(model_type = "zero_one_beta"))
  fake_poisson <- list(model = list(model_type = "poisson"))
  fake_zip <- list(model = list(model_type = "zi_poisson"))
  fake_nbinom2 <- list(model = list(model_type = "nbinom2"))
  fake_truncnb2 <- list(model = list(model_type = "truncated_nbinom2"))
  fake_hurdlenb2 <- list(model = list(model_type = "hurdle_nbinom2"))
  fake_zinb2 <- list(model = list(model_type = "zi_nbinom2"))
  fake_biv <- list(model = list(model_type = "biv_gaussian"))
  eta <- c(-1, 0, 1)

  expect_equal(drmTMB:::drm_inverse_link(fake_gaussian, "mu", eta), eta)
  expect_equal(drmTMB:::drm_inverse_link(fake_gaussian, "sigma", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_student, "nu", eta), 2 + exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_skew_normal, "mu", eta), eta)
  expect_equal(
    drmTMB:::drm_inverse_link(fake_skew_normal, "sigma", eta),
    exp(eta)
  )
  expect_equal(drmTMB:::drm_inverse_link(fake_skew_normal, "nu", eta), eta)
  expect_equal(drmTMB:::drm_inverse_link(fake_gamma, "mu", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_gamma, "sigma", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_tweedie, "mu", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_tweedie, "sigma", eta), exp(eta))
  expect_equal(
    drmTMB:::drm_inverse_link(fake_tweedie, "nu", eta),
    1 + stats::plogis(eta)
  )
  expect_equal(
    drmTMB:::drm_inverse_link(fake_beta, "mu", eta),
    stats::plogis(eta)
  )
  expect_equal(drmTMB:::drm_inverse_link(fake_beta, "sigma", eta), exp(eta))
  expect_equal(
    drmTMB:::drm_inverse_link(fake_zero_one_beta, "mu", eta),
    stats::plogis(eta)
  )
  expect_equal(
    drmTMB:::drm_inverse_link(fake_zero_one_beta, "sigma", eta),
    exp(eta)
  )
  expect_equal(
    drmTMB:::drm_inverse_link(fake_zero_one_beta, "zoi", eta),
    stats::plogis(eta)
  )
  expect_equal(
    drmTMB:::drm_inverse_link(fake_zero_one_beta, "coi", eta),
    stats::plogis(eta)
  )
  expect_equal(drmTMB:::drm_inverse_link(fake_poisson, "mu", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_zip, "mu", eta), exp(eta))
  expect_equal(
    drmTMB:::drm_inverse_link(fake_zip, "zi", eta),
    stats::plogis(eta)
  )
  expect_equal(drmTMB:::drm_inverse_link(fake_nbinom2, "mu", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_nbinom2, "sigma", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_truncnb2, "mu", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_truncnb2, "sigma", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_hurdlenb2, "mu", eta), exp(eta))
  expect_equal(
    drmTMB:::drm_inverse_link(fake_hurdlenb2, "sigma", eta),
    exp(eta)
  )
  expect_equal(
    drmTMB:::drm_inverse_link(fake_hurdlenb2, "hu", eta),
    stats::plogis(eta)
  )
  expect_equal(drmTMB:::drm_inverse_link(fake_zinb2, "mu", eta), exp(eta))
  expect_equal(drmTMB:::drm_inverse_link(fake_zinb2, "sigma", eta), exp(eta))
  expect_equal(
    drmTMB:::drm_inverse_link(fake_zinb2, "zi", eta),
    stats::plogis(eta)
  )
  expect_equal(
    drmTMB:::drm_inverse_link(fake_biv, "rho12", eta),
    0.999999 * tanh(eta)
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
  dat_hurdlenb2 <- dat_truncnb2
  dat_hurdlenb2$z <- rep(c(-1, 0, 1, 0), length.out = nrow(dat_hurdlenb2))
  dat_hurdlenb2$y[seq(1, nrow(dat_hurdlenb2), by = 5)] <- 0
  fit_hurdlenb2 <- drmTMB(
    bf(y ~ x, sigma ~ 1, hu ~ z),
    family = truncated_nbinom2(),
    data = dat_hurdlenb2
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
  p0_truncnb2 <- stats::dnbinom(
    0,
    size = 1 / sigma_truncnb2^2,
    mu = mu_truncnb2
  )
  expect_equal(
    fitted(fit_truncnb2),
    mu_truncnb2 / (1 - p0_truncnb2),
    tolerance = 1e-12
  )
  mu_hurdlenb2 <- predict(fit_hurdlenb2, dpar = "mu")
  sigma_hurdlenb2 <- sigma(fit_hurdlenb2)
  hu_hurdlenb2 <- predict(fit_hurdlenb2, dpar = "hu")
  p0_hurdlenb2 <- stats::dnbinom(
    0,
    size = 1 / sigma_hurdlenb2^2,
    mu = mu_hurdlenb2
  )
  expect_equal(
    fitted(fit_hurdlenb2),
    (1 - hu_hurdlenb2) * mu_hurdlenb2 / (1 - p0_hurdlenb2),
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

test_that("link registry is the single source of truth for dpar links", {
  registry <- drmTMB:::drm_link_registry()

  # Every fitted model_type drm_dpar_link can be asked about has a registry row,
  # and drm_dpar_link reads exactly that row.
  for (model_type in names(registry)) {
    fake <- list(model = list(model_type = model_type))
    for (dpar in names(registry[[model_type]])) {
      expect_identical(
        drmTMB:::drm_dpar_link(fake, dpar),
        unname(registry[[model_type]][[dpar]]),
        info = paste(model_type, dpar)
      )
    }
  }

  # Each drm_family constructor's links must agree with the registry so the two
  # link definitions cannot drift apart.
  constructors <- c(
    "biv_gaussian", "student", "skew_normal", "lognormal", "tweedie",
    "beta", "zero_one_beta", "beta_binomial", "cumulative_logit",
    "nbinom2", "truncated_nbinom2"
  )
  for (ctor in constructors) {
    fam <- do.call(ctor, list())
    expect_true(
      fam$name %in% names(registry),
      info = paste("registry missing", fam$name)
    )
    expect_identical(
      fam$links,
      registry[[fam$name]],
      info = paste("family/registry link drift for", fam$name)
    )
  }
})
