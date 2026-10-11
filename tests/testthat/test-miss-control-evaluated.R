# #1484: the predictor = "fail" check must read the evaluated control, so a
# stored control or a value held in a variable behaves like its literal call.

miss_control_na_predictor_data <- function() {
  d <- datasets::airquality[, c("Wind", "Solar.R")]
  stopifnot(anyNA(d$Solar.R))
  d
}

test_that("a stored miss_control() fails like the literal call", {
  d <- miss_control_na_predictor_data()
  ctl <- miss_control()
  expect_error(
    drmTMB(bf(Wind ~ Solar.R), data = d, missing = miss_control()),
    "requires complete predictors"
  )
  expect_error(
    drmTMB(bf(Wind ~ Solar.R), data = d, missing = ctl),
    "requires complete predictors"
  )
})

test_that("predictor = \"fail\" held in a variable fails like the literal", {
  d <- miss_control_na_predictor_data()
  pf <- "fail"
  expect_error(
    drmTMB(bf(Wind ~ Solar.R), data = d, missing = miss_control(predictor = pf)),
    "requires complete predictors"
  )
  ctl <- miss_control("drop", "fail")
  expect_error(
    drmTMB(bf(Wind ~ Solar.R), data = d, missing = ctl),
    "requires complete predictors"
  )
})

test_that("response-only and omitted controls keep the complete-case drop", {
  d <- miss_control_na_predictor_data()
  n_complete <- sum(stats::complete.cases(d))
  fit_omitted <- drmTMB(bf(Wind ~ Solar.R), data = d)
  expect_equal(stats::nobs(fit_omitted), n_complete)

  ctl <- miss_control(response = "drop")
  fit_stored <- drmTMB(bf(Wind ~ Solar.R), data = d, missing = ctl)
  expect_equal(stats::nobs(fit_stored), n_complete)

  fit_list <- drmTMB(
    bf(Wind ~ Solar.R),
    data = d,
    missing = list(response = "drop")
  )
  expect_equal(stats::nobs(fit_list), n_complete)
})

test_that("miss_control() records which arguments were supplied", {
  expect_identical(
    attr(miss_control(), "explicit"),
    c(response = FALSE, predictor = FALSE, engine = FALSE)
  )
  expect_identical(
    attr(miss_control(response = "include"), "explicit"),
    c(response = TRUE, predictor = FALSE, engine = FALSE)
  )
})
