# Optimizer budget bookkeeping in R/check.R.

test_that("optimizer_evaluation_count() reads nested evaluation slots", {
  expect_equal(
    drmTMB:::optimizer_evaluation_count(list(iterations = 12), "iterations"),
    12
  )
  expect_true(is.na(drmTMB:::optimizer_evaluation_count(NULL, "iterations")))
})

test_that("optimizer_budget_limit() and reached() compare counts", {
  expect_equal(drmTMB:::optimizer_budget_limit(list(iter.max = 50), "iter.max"), 50)
  expect_true(drmTMB:::optimizer_budget_reached(50, 50))
  expect_false(drmTMB:::optimizer_budget_reached(10, 50))
  expect_false(drmTMB:::optimizer_budget_reached(NA_real_, 50))
})

test_that("format_optimizer_count() stringifies finite integers", {
  expect_equal(drmTMB:::format_optimizer_count(42), "42")
  expect_equal(drmTMB:::format_optimizer_count(NA_real_), "NA")
  expect_equal(drmTMB:::format_optimizer_count(c(1, 2)), "NA")
})

test_that("validate_check_scalar() bounds numeric diagnostics", {
  expect_equal(drmTMB:::validate_check_scalar(0.5, "x", 0, 1), 0.5)
  expect_error(drmTMB:::validate_check_scalar(2, "x", 0, 1), "x")
  expect_error(drmTMB:::validate_check_scalar("a", "x"), "numeric")
})

test_that("check_optimizer_name() surfaces the optimizer label", {
  fit <- list(optimizer_used = list(optimizer = "BFGS"))
  expect_equal(drmTMB:::check_optimizer_name(fit), "BFGS")
  default <- list(control = list())
  expect_equal(drmTMB:::check_optimizer_name(default), "nlminb")
})

test_that("optimizer_budget_reached() handles non-finite limits", {
  expect_false(drmTMB:::optimizer_budget_reached(10, NA_real_))
})

test_that("check_row() assembles drm_check rows", {
  row <- drmTMB:::check_row("demo", "ok", "v", "message")
  expect_equal(row$check[[1]], "demo")
  expect_equal(row$status[[1]], "ok")
  expect_match(row$message[[1]], "message")
})