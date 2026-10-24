test_that("miss_control() records MD1 defaults", {
  ctrl <- miss_control()

  expect_s3_class(ctrl, "drm_missing_control")
  expect_equal(ctrl$response, "drop")
  expect_equal(ctrl$predictor, "fail")
  expect_equal(ctrl$engine, "laplace")
  expect_identical(formals(miss_control)$engine, "laplace")
})

test_that("miss_control() validates implemented and reserved options", {
  expect_equal(miss_control(response = "include")$response, "include")
  expect_equal(miss_control(predictor = "model")$predictor, "model")

  expect_error(miss_control(response = "omit"), "should be one of")
  expect_error(miss_control(engine = "em"), "reserved")
  expect_error(miss_control(engine = "profile"), "reserved")
  expect_error(miss_control(engine = "other"), "only supports")
})

test_that("drmTMB() parses missing-control lists and gates unsupported response masks", {
  x <- seq(-1.2, 1.4, length.out = 12)
  dat <- data.frame(
    y = 0.4 + 0.7 * x + 0.1 * sin(seq_along(x)),
    x = x
  )
  dat$y[5] <- NA_real_

  expect_s3_class(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      missing = list(response = "include"),
      control = drm_control(se = FALSE)
    )$missing_data,
    "drm_missing_data"
  )

  count_dat <- data.frame(y = c(1L, 2L, NA_integer_, 3L, 5L, 2L), x = 1:6)
  expect_s3_class(
    drmTMB(
      bf(y ~ x),
      data = count_dat,
      family = truncated_nbinom2(),
      missing = miss_control(response = "include"),
      control = drm_control(se = FALSE)
    )$missing_data,
    "drm_missing_data"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      data = dat,
      impute = list(x = x ~ 1),
      control = drm_control(se = FALSE)
    ),
    "predictor = \"model\""
  )

  expect_error(
    drmTMB(
      bf(y ~ mi(x)),
      data = dat,
      family = poisson(),
      impute = list(x = x ~ 1),
      missing = miss_control(predictor = "model"),
      control = drm_control(se = FALSE)
    ),
    "binary missing predictor"
  )
})

test_that("mediator recipe builds impute_model() from a fitted node and fits (#964)", {
  set.seed(20261011)
  n <- 120
  dat <- data.frame(x = rnorm(n))
  dat$m <- 0.5 + 0.8 * dat$x + rnorm(n, sd = 0.5)
  dat$y <- 0.2 + 0.3 * dat$x + 0.7 * dat$m + rnorm(n, sd = 0.4)
  dat$m[sample(n, 20)] <- NA_real_

  fit_m <- drmTMB(
    bf(m ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  m_formula <- stats::as.formula(formula(fit_m)$calls[[1L]])
  expect_s3_class(m_formula, "formula")
  m_model <- impute_model(m_formula, family = fit_m$family)
  expect_s3_class(m_model, "drm_impute_model")
  expect_identical(m_model$family_type, "gaussian")

  fit_y <- drmTMB(
    bf(y ~ x + mi(m), sigma ~ 1),
    family = gaussian(),
    data = dat,
    impute = list(m = m_model),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
  expect_true(all(is.finite(coef(fit_y, "mu"))))
  expect_true(all(is.finite(coef(fit_y, "mi_m"))))
  # Estimates are not shared: the two fits are close but not identical.
  expect_false(isTRUE(all.equal(
    unname(coef(fit_m, "mu")),
    unname(coef(fit_y, "mi_m")),
    tolerance = 1e-8
  )))
})

test_that("mediator recipe works for a binary mediator with a renamed left-hand side (#964)", {
  set.seed(20261012)
  n <- 160
  dat <- data.frame(x = rnorm(n))
  dat$m01 <- rbinom(n, 1, plogis(0.3 + dat$x))
  dat$y <- 0.2 + 0.9 * dat$m01 + 0.3 * dat$x + rnorm(n, sd = 0.4)
  dat$m01[sample(n, 25)] <- NA_real_
  dat$m <- factor(dat$m01, levels = 0:1)

  fit_m <- drmTMB(
    bf(m01 ~ x),
    family = binomial(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  m_formula <- stats::update(
    stats::as.formula(formula(fit_m)$calls[[1L]]),
    m ~ .
  )
  fit_y <- drmTMB(
    bf(y ~ x + mi(m), sigma ~ 1),
    family = gaussian(),
    data = dat,
    impute = list(m = impute_model(m_formula, family = fit_m$family)),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
  expect_true(all(is.finite(coef(fit_y, "mu"))))
  expect_true(all(is.finite(coef(fit_y, "mi_m"))))
})
