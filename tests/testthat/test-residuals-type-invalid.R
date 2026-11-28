# Invalid `residuals.drmTMB(..., type = )` must not leak raw `match.arg()` errors (#1869).

test_that("residuals() aborts with supported type choices for an invalid type", {
  skip_if_not_installed("lme4")
  data(cbpp, package = "lme4")
  fit <- drmTMB(
    bf(mu = cbind(incidence, size - incidence) ~ period + (1 | herd)),
    family = binomial(),
    data = cbpp,
    control = drm_control(se = FALSE, parallel = "none")
  )
  expect_error(residuals(fit, type = "deviance"), "type")
  expect_error(
    residuals(fit, type = "deviance"),
    "response.*pearson.*quantile"
  )
  expect_error(residuals(fit, type = "working"), "type")
  expect_error(
    residuals(fit, type = "working"),
    "response.*pearson.*quantile"
  )
  expect_length(residuals(fit, type = "pearson"), nrow(cbpp))
})