test_that("check_row assembles the drm_check columns", {
  row <- drmTMB:::check_row("alpha", "ok", 1.25, "fine")
  expect_s3_class(row, "data.frame")
  expect_named(row, c("check", "status", "value", "message"))
  expect_equal(row$check, "alpha")
  expect_equal(row$status, "ok")
  expect_equal(row$value, "1.25")
  expect_equal(row$message, "fine")
  expect_equal(nrow(row), 1L)
})

test_that("validate_check_scalar enforces finite open-interval scalars", {
  expect_invisible(drmTMB:::validate_check_scalar(0.5, "rho_boundary", 0, 1))
  expect_error(
    drmTMB:::validate_check_scalar(c(0.1, 0.2), "rho_boundary", 0, 1),
    "finite numeric scalar"
  )
  expect_error(
    drmTMB:::validate_check_scalar(0, "rho_boundary", 0, 1),
    "finite numeric scalar"
  )
  expect_error(
    drmTMB:::validate_check_scalar(1, "rho_boundary", 0, 1),
    "finite numeric scalar"
  )
  expect_error(
    drmTMB:::validate_check_scalar(NA_real_, "rho_boundary", 0, 1),
    "finite numeric scalar"
  )
  expect_error(
    drmTMB:::validate_check_scalar(Inf, "rho_boundary", 0, 1),
    "finite numeric scalar"
  )
})

test_that("disambiguate_duplicate_labels appends sequence suffixes", {
  expect_equal(
    drmTMB:::disambiguate_duplicate_labels(c("b", "a", "b", "c")),
    c("b[1]", "a", "b[2]", "c")
  )
  expect_equal(
    drmTMB:::disambiguate_duplicate_labels(c("x", "y")),
    c("x", "y")
  )
  expect_equal(
    drmTMB:::disambiguate_duplicate_labels(c("z", "z", "z")),
    c("z[1]", "z[2]", "z[3]")
  )
})

test_that("empty_dropped_groups returns a typed empty frame", {
  empty <- drmTMB:::empty_dropped_groups()
  expect_equal(nrow(empty), 0L)
  expect_equal(names(empty), c("variable", "n_lost", "example"))
  expect_type(empty$variable, "character")
  expect_type(empty$n_lost, "integer")
})

test_that("format_check_number uses fixed significant formatting", {
  expect_equal(drmTMB:::format_check_number(1.234567), "1.235")
  expect_equal(drmTMB:::format_check_number(0), "0")
  expect_match(drmTMB:::format_check_number(1e6), "^1")
  expect_equal(drmTMB:::format_check_number(pi), formatC(pi, digits = 4L, format = "fg", flag = "#"))
})

test_that("finite extrema helpers ignore non-finite values", {
  expect_equal(drmTMB:::min_finite_or_na(c(NA, Inf, 3, 1)), 1)
  expect_equal(drmTMB:::max_finite_or_na(c(NA, -Inf, 3, 1)), 3)
  expect_equal(drmTMB:::max_abs_finite_or_na(c(NA, -4, 2)), 4)
  expect_true(is.na(drmTMB:::min_finite_or_na(c(NA, Inf))))
  expect_true(is.na(drmTMB:::max_finite_or_na(character())))
  expect_true(is.na(drmTMB:::max_abs_finite_or_na(numeric())))
})

test_that("random_effect_label_is_intercept recognises intercept spellings", {
  # intercept-suffix spellings covered by test-intercept-label-1125f1.R (refs #1853)
  expect_true(drmTMB:::random_effect_label_is_intercept("(1 | id)"))
  expect_false(drmTMB:::random_effect_label_is_intercept("(x | id)"))
  expect_false(drmTMB:::random_effect_label_is_intercept("sigma"))
})

test_that("random_effect_unique_n counts distinct finite levels", {
  expect_equal(drmTMB:::random_effect_unique_n(c(1, 1, 2, NA)), 2L)
  expect_equal(drmTMB:::random_effect_unique_n(c(Inf, 1)), 1L)
  expect_equal(drmTMB:::random_effect_unique_n(c(NA_real_, NA_real_)), 0L)
})

test_that("optimizer count helpers tolerate missing evaluation lists", {
  evals <- list(`function` = 12L, gradient = 8L)
  expect_equal(drmTMB:::optimizer_evaluation_count(evals, "function"), 12)
  expect_equal(drmTMB:::optimizer_evaluation_count(evals, "hessian"), NA_real_)
  expect_true(is.na(drmTMB:::optimizer_evaluation_count(NULL, "function")))
  expect_equal(drmTMB:::optimizer_budget_limit(list(iter.max = 40), "iter.max"), 40)
  expect_true(is.na(drmTMB:::optimizer_budget_limit(list(), "iter.max")))
  expect_true(drmTMB:::optimizer_budget_reached(50, 40))
  expect_false(drmTMB:::optimizer_budget_reached(10, 40))
  expect_false(drmTMB:::optimizer_budget_reached(10, NA_real_))
  expect_equal(drmTMB:::format_optimizer_count(7.9), "7")
  expect_equal(drmTMB:::format_optimizer_count(NA), "NA")
  expect_equal(drmTMB:::format_optimizer_count(c(1, 2)), "NA")
})

test_that("random_effect_covariance boundary flags behave on finite rho", {
  expect_true(drmTMB:::random_effect_covariance_near_boundary(0.96, 0.95))
  expect_false(drmTMB:::random_effect_covariance_near_boundary(0.94, 0.95))
  expect_false(drmTMB:::random_effect_covariance_near_boundary(NA_real_, 0.95))
  expect_true(drmTMB:::random_effect_covariance_rho_unavailable(NA_real_))
  expect_false(drmTMB:::random_effect_covariance_rho_unavailable(0.2))
  expect_match(
    drmTMB:::random_effect_covariance_unavailable_message(),
    "could not be extracted"
  )
})