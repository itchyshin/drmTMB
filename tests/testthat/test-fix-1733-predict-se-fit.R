# predict(se.fit = TRUE) must name se.fit. The dots guard used to say only
# that `...` is reserved, which hides the stats::predict argument users type
# (#1733). Other unknown arguments keep that reserved-options abort.

new_predict_se_fit_fit <- function() {
  dat <- data.frame(y = c(0.2, 0.5, 1.1, 1.4), x = c(-1, 0, 1, 2))
  list(
    fit = drmTMB(bf(y ~ x, sigma ~ 1), data = dat, control = drm_control(se = FALSE)),
    nd = data.frame(x = c(0, 1))
  )
}

test_that("predict() names se.fit when standard errors are unavailable (#1733)", {
  z <- new_predict_se_fit_fit()
  err <- expect_error(
    predict(z$fit, newdata = z$nd, dpar = "mu", se.fit = TRUE),
    class = "rlang_error"
  )
  msg <- conditionMessage(err)
  expect_match(msg, "se.fit", fixed = TRUE)
  expect_false(grepl("reserved for future options", msg, fixed = TRUE))
})

test_that("predict() still refuses other unknown arguments (#1733)", {
  z <- new_predict_se_fit_fit()
  expect_error(
    predict(z$fit, newdata = z$nd, dpar = "mu", not_an_arg = 1),
  "reserved for future"
  )
})