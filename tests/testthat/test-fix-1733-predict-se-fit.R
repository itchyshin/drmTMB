# predict(se.fit = TRUE) must name se.fit. The dots guard used to say only
# that `...` is reserved, which hides the stats::predict argument users type
# (#1733). Other unknown arguments keep that reserved-options abort.

test_that("predict() names se.fit and says standard errors are unavailable (#1733)", {
  set.seed(1733)
  dat <- data.frame(y = stats::rnorm(24), x = stats::rnorm(24))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  err <- expect_error(
    predict(fit, se.fit = TRUE),
    class = "rlang_error"
  )
  msg <- conditionMessage(err)
  expect_match(msg, "se.fit", fixed = TRUE)
  expect_match(msg, "standard errors", fixed = TRUE)
  expect_false(grepl("reserved for future options", msg, fixed = TRUE))
})

test_that("predict() still rejects other unknown arguments as reserved (#1733)", {
  set.seed(1733)
  dat <- data.frame(y = stats::rnorm(24), x = stats::rnorm(24))
  fit <- drmTMB(
    bf(y ~ x, sigma ~ 1),
    family = gaussian(),
    data = dat,
    control = drm_control(se = FALSE)
  )
  err <- expect_error(
    predict(fit, future_option = TRUE),
    class = "rlang_error"
  )
  expect_match(conditionMessage(err), "reserved for future options", fixed = TRUE)
})
