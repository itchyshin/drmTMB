test_that("non-Gaussian sigma random effects have a specific boundary", {
  dat <- data.frame(
    id = factor(rep(seq_len(4), each = 3)),
    x = rep(c(-0.8, 0, 0.8), times = 4),
    y = c(-0.5, 0.2, 1.1, -0.2, 0.4, 1.4, 0.1, 0.7, 1.7, 0.3, 0.8, 1.8),
    y_pos = c(0.7, 1.0, 1.8, 0.9, 1.4, 2.3, 1.1, 1.6, 2.8, 1.3, 2.0, 3.2),
    y_prop = c(
      0.12,
      0.18,
      0.22,
      0.30,
      0.36,
      0.42,
      0.50,
      0.56,
      0.62,
      0.70,
      0.76,
      0.84
    ),
    y_count = c(0, 1, 2, 3, 1, 4, 2, 5, 3, 6, 4, 7),
    y_pos_count = c(1, 1, 2, 3, 1, 4, 2, 5, 3, 6, 4, 7),
    success = c(1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7),
    failure = c(7, 6, 6, 5, 5, 4, 4, 3, 3, 2, 2, 1)
  )
  boundary <- "Non-Gaussian.*sigma.*random effects"

  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ x + (1 | id), nu ~ 1),
      family = student(),
      data = dat
    ),
    boundary
  )
  expect_error(
    drmTMB(
      bf(y_pos ~ x, sigma ~ x + (0 + x | id)),
      family = lognormal(),
      data = dat
    ),
    boundary
  )
  expect_error(
    drmTMB(
      bf(y_pos ~ x, sigma ~ x + (1 | id)),
      family = stats::Gamma(link = "log"),
      data = dat
    ),
    boundary
  )
  expect_error(
    drmTMB(bf(y_prop ~ x, sigma ~ x + (1 | id)), family = beta(), data = dat),
    boundary
  )
  expect_error(
    drmTMB(
      bf(cbind(success, failure) ~ x, sigma ~ x + (1 | id)),
      family = beta_binomial(),
      data = dat
    ),
    boundary
  )
  expect_error(
    drmTMB(
      bf(y_pos_count ~ x, sigma ~ x + (0 + x | id)),
      family = truncated_nbinom2(),
      data = dat
    ),
    boundary
  )
  expect_error(
    drmTMB(
      bf(y_count ~ x, sigma ~ x + (1 | id), hu ~ 1),
      family = truncated_nbinom2(),
      data = dat
    ),
    boundary
  )
})
