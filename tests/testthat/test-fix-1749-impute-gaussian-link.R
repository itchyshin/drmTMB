# Issue #1749: drm_impute_family_type() must not accept gaussian(link != "identity").

test_that("gaussian imputation keeps the identity link", {
  expect_identical(
    drmTMB:::drm_impute_family_type(stats::gaussian()),
    "gaussian"
  )
  expect_identical(
    drmTMB:::drm_impute_family_type(stats::gaussian(link = "identity")),
    "gaussian"
  )
  z <- seq(-1.5, 1.5, length.out = 48)
  w <- cos(seq_along(z) / 5)
  x_full <- 0.25 + 0.8 * z - 0.15 * w + 0.08 * sin(seq_along(z))
  y <- 0.7 + 1.4 * x_full - 0.35 * z + 0.12 * cos(seq_along(z) / 3)
  d <- data.frame(y = y, x = x_full, z = z, w = w)
  d$x[c(6L, 17L, 31L, 42L)] <- NA_real_
  fit <- drmTMB(
    bf(y ~ z + mi(x), sigma ~ 1),
    data = d,
    family = stats::gaussian(),
    impute = list(x = impute_model(x ~ z + w, family = stats::gaussian())),
    missing = miss_control(predictor = "model"),
    control = drm_control(se = FALSE)
  )
  expect_true(is_converged(fit))
  expect_true(is.finite(as.numeric(stats::logLik(fit))))
})

test_that("gaussian imputation rejects a non-identity link", {
  expect_error(
    impute_model(x ~ z, family = stats::gaussian(link = "log")),
    regexp = "identity link",
    class = "rlang_error"
  )
  expect_error(
    drmTMB:::drm_impute_family_type(stats::gaussian(link = "inverse")),
    regexp = "identity link",
    class = "rlang_error"
  )
})
