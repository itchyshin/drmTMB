factor_y_data <- function(ordered = FALSE) {
  set.seed(1)
  n <- 40
  d <- data.frame(x = stats::rnorm(n))
  labels <- sample(c("3", "7", "12"), n, TRUE)
  d$y <- if (ordered) ordered(labels) else factor(labels)
  d
}

test_that("continuous builders #1481: reject factor response and name the column", {
  d <- factor_y_data()
  for (fam in list(
    list(call = quote(gaussian()), re = "Gaussian"),
    list(call = quote(student()), re = "Student-t"),
    list(call = quote(skew_normal()), re = "skew-normal")
  )) {
    err <- expect_error(
      drmTMB(bf(y ~ x, sigma ~ 1), family = eval(fam$call), data = d),
      "not a factor",
      class = "rlang_error"
    )
    expect_match(conditionMessage(err), fam$re, fixed = TRUE)
    expect_match(conditionMessage(err), "y", fixed = TRUE)
  }
})

test_that("continuous builders #1481: ordered factor is rejected the same way", {
  d <- factor_y_data(ordered = TRUE)
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = d),
    "not a factor",
    class = "rlang_error"
  )
})