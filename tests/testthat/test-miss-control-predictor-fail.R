test_that("miss_control(predictor = fail) honors stored controls and variables (#1484)", {
  d <- datasets::airquality
  ctl <- miss_control()
  pf <- "fail"
  err_re <- "complete predictors"

  expect_error(
    drmTMB(bf(Wind ~ Solar.R), data = d, missing = miss_control()),
    err_re
  )
  expect_error(
    drmTMB(bf(Wind ~ Solar.R), data = d, missing = ctl),
    err_re
  )
  expect_error(
    drmTMB(bf(Wind ~ Solar.R), data = d, missing = miss_control(predictor = pf)),
    err_re
  )

  # Omitting missing= still drops incomplete predictor rows (complete-case).
  fit <- drmTMB(
    bf(Wind ~ Solar.R),
    data = d,
    control = drm_control(se = FALSE)
  )
  expect_equal(nobs(fit), 146L)
})
