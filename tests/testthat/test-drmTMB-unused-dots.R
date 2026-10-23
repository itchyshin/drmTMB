# #1486: the `...` guard must not evaluate its arguments, and must name them.

test_that("drmTMB() names an unused subset argument without evaluating it", {
  err <- expect_error(
    drmTMB(bf(mpg ~ wt), data = mtcars, subset = cyl == 4),
    class = "drmTMB_unused_dots_error"
  )
  msg <- conditionMessage(err)
  expect_match(msg, "subset")
  expect_no_match(msg, "not found")
  expect_match(msg, "Subset")
})

test_that("drmTMB() names misspelt arguments in ...", {
  err <- expect_error(
    drmTMB(bf(mpg ~ wt), data = mtcars, weigths = mtcars$wt),
    class = "drmTMB_unused_dots_error"
  )
  expect_match(conditionMessage(err), "weigths")
  expect_match(conditionMessage(err), "spelling")

  err <- expect_error(
    drmTMB(bf(mpg ~ wt), data = mtcars, na.action = na.omit, foo = 1),
    class = "drmTMB_unused_dots_error"
  )
  expect_match(conditionMessage(err), "na.action")
  expect_match(conditionMessage(err), "foo")
  expect_match(conditionMessage(err), "miss_control")
})

test_that("drmTMB() reports unnamed extra arguments", {
  expect_error(
    drmTMB(
      bf(mpg ~ wt), gaussian(), mtcars, NULL, list(), NULL, miss_control(),
      "tmb", FALSE, NULL, "ml", stop("must not be evaluated")
    ),
    "1 unnamed extra argument",
    class = "drmTMB_unused_dots_error"
  )
})
