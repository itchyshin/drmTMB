test_that("confint() lists valid parm names when parm does not match", {
  set.seed(401)
  g <- factor(rep(1:10, each = 3))
  d <- data.frame(
    y = stats::rnorm(30) + stats::rnorm(10, sd = 0.4)[g],
    x = stats::rnorm(30),
    g = g
  )
  fit <- drmTMB(bf(y ~ x + (1 | g)), family = gaussian(), data = d)

  err <- expect_error(stats::confint(fit, parm = "(1 | g)"))
  expect_match(conditionMessage(err), "Unknown confidence-interval target", fixed = TRUE)
  expect_match(conditionMessage(err), "Available targets", fixed = TRUE)
  expect_match(conditionMessage(err), "sd:mu:(1 | g)", fixed = TRUE)
  expect_false(grepl("First available targets", conditionMessage(err), fixed = TRUE))
})