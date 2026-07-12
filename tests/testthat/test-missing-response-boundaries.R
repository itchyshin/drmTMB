test_that("all-missing responses reject for every MR-T1 route", {
  dat <- data.frame(x = seq(-1, 1, length.out = 8), y = NA_real_)
  include <- miss_control(response = "include")

  expect_error(
    drmTMB(bf(y ~ x), gaussian(), dat, missing = include),
    "At least one observed Gaussian response"
  )
  expect_error(
    drmTMB(bf(y ~ x), beta(), dat, missing = include),
    "At least one observed beta response"
  )
  expect_error(
    drmTMB(bf(y ~ x), poisson(), dat, missing = include),
    "At least one observed Poisson response"
  )
  expect_error(
    drmTMB(bf(y ~ x), nbinom2(), dat, missing = include),
    "At least one observed nbinom2 response"
  )
  expect_error(
    drmTMB(bf(y ~ x), binomial(), dat, missing = include),
    "At least one observed binomial response"
  )

  biv <- transform(dat, y1 = NA_real_, y2 = NA_real_)
  expect_error(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      ),
      biv_gaussian(),
      biv,
      missing = include
    ),
    "at least one observed response"
  )
})

test_that("masked rows do not hide invalid observed response values", {
  include <- miss_control(response = "include")
  base <- data.frame(x = seq(-1, 1, length.out = 6))

  beta_dat <- transform(base, y = c(0.2, NA, 0, 0.4, 0.6, 0.8))
  expect_error(
    drmTMB(bf(y ~ x), beta(), beta_dat, missing = include),
    "strictly between 0 and 1"
  )

  for (bad in c(-1, 1.5)) {
    count_dat <- transform(base, y = c(0, NA, bad, 1, 2, 3))
    expect_error(
      drmTMB(bf(y ~ x), poisson(), count_dat, missing = include),
      "non-negative integer count"
    )
    expect_error(
      drmTMB(bf(y ~ x), nbinom2(), count_dat, missing = include),
      "non-negative integer count"
    )
  }

  binary_dat <- transform(base, y = c(0, NA, 2, 1, 0, 1))
  expect_error(
    drmTMB(bf(y ~ x), binomial(), binary_dat, missing = include),
    "0/1 event indicators"
  )

  trials_dat <- transform(
    base,
    success = c(1, NA, 2, 1, 0, 1),
    failure = c(3, NA, -1, 2, 4, 3)
  )
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x),
      binomial(),
      trials_dat,
      missing = include
    ),
    "finite non-negative integers"
  )
})

test_that("cbind binomial masking preserves the admitted row contract", {
  dat <- data.frame(
    x = seq(-1, 1, length.out = 8),
    success = c(1, 2, NA, 0, 3, 1, 2, 0),
    failure = c(3, 2, NA, 4, 1, 3, 2, 4)
  )
  fit <- drmTMB(
    bf(cbind(success, failure) ~ x),
    binomial(),
    dat,
    missing = miss_control(response = "include"),
    control = drm_control(se = FALSE)
  )

  expect_equal(nobs(fit), 7L)
  expect_equal(fit$missing_data$original_row, seq_len(nrow(dat)))
  expect_length(fitted(fit), nrow(dat))
  expect_true(is.na(residuals(fit)[[3L]]))
  expect_true(is.na(residuals(fit, type = "pearson")[[3L]]))
})
