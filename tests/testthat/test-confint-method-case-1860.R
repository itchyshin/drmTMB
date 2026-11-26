test_that("validate_interval_method() accepts mixed-case method names", {
  f <- drmTMB:::validate_interval_method
  ch <- c("wald", "profile", "bootstrap")
  expect_identical(f("Wald", ch, "confint"), "wald")
  expect_identical(f("PROFILE", ch, "confint"), "profile")
})

test_that("confint() accepts method = \"Wald\"", {
  set.seed(1126)
  dat <- data.frame(y = stats::rnorm(20), x = stats::rnorm(20))
  fit <- drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
  ci_wald <- stats::confint(fit, method = "wald")
  ci_Wald <- stats::confint(fit, method = "Wald")
  expect_identical(ci_Wald$parm, ci_wald$parm)
  expect_equal(ci_Wald$lower, ci_wald$lower)
  expect_equal(ci_Wald$upper, ci_wald$upper)
})