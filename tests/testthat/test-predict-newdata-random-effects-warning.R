test_that("predict(newdata) warns once per session that random effects are omitted (#1870)", {
  skip_on_cran()
  skip_if_not_installed("lme4")
  data(sleepstudy, package = "lme4")
  fit <- drmTMB(
    bf(mu = Reaction ~ Days + (1 | Subject)),
    family = gaussian(),
    data = sleepstudy,
    control = drm_control(se = FALSE, parallel = "none")
  )
  expect_equal(
    length(capture_messages(predict(fit, dpar = "mu"))),
    0L
  )
  msgs <- capture_messages(predict(fit, newdata = sleepstudy, dpar = "mu"))
  expect_length(msgs, 1L)
  expect_match(msgs[[1]], "omit fitted random effects")
  expect_equal(
    length(capture_messages(predict(fit, newdata = sleepstudy, dpar = "mu"))),
    0L
  )
})