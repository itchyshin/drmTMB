# check row scaffolding from R/check.R (not covered by x3 twin internals).

test_that("check_row() assembles a one-row check table", {
  row <- drmTMB:::check_row("hessian", "ok", TRUE, "fine")
  expect_s3_class(row, "data.frame")
  expect_equal(row$check, "hessian")
  expect_equal(row$status, "ok")
  expect_equal(row$value, "TRUE")
  expect_equal(row$message, "fine")
  expect_equal(nrow(row), 1L)
})

test_that("disambiguate_duplicate_labels() suffixes duplicates", {
  f <- drmTMB:::disambiguate_duplicate_labels
  expect_identical(f(c("a", "b")), c("a", "b"))
  out <- f(c("b", "b", "b", "a"))
  expect_equal(out[[1L]], "b[1]")
  expect_equal(out[[2L]], "b[2]")
  expect_equal(out[[4L]], "a")
})

test_that("fixed_gradient_component_label() disambiguates parameter names", {
  obj <- list(opt = list(par = c(b = 1, b = 2, a = 3)))
  grad <- c(0.1, 0.2, 0.3)
  lab1 <- drmTMB:::fixed_gradient_component_label(obj, grad, 1L)
  expect_match(lab1, "b")
  lab2 <- drmTMB:::fixed_gradient_component_label(obj, grad, 2L)
  expect_match(lab2, "b\\[")
  none <- drmTMB:::fixed_gradient_component_label(obj, grad, NA)
  expect_equal(none, "none")
})