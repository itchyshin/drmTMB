# Fit-free characterisation of the pure helpers in R/prediction-grid.R.

preds <- c("x", "g", "z")

test_that("validate_prediction_grid_n() accepts positive whole numbers", {
  f <- drmTMB:::validate_prediction_grid_n
  expect_identical(f(3), 3L)
  expect_identical(f(3.0), 3L)
  expect_identical(f(3L), 3L)
  expect_identical(f(1), 1L)
})

test_that("validate_prediction_grid_n() rejects everything else", {
  f <- drmTMB:::validate_prediction_grid_n
  for (bad in list(0, -2, 2.5, NA, NA_real_, c(1, 2), "a", NULL, TRUE)) {
    expect_error(f(bad), "positive whole number")
  }
})

test_that("validate_prediction_grid_terms() handles NULL", {
  f <- drmTMB:::validate_prediction_grid_terms
  expect_identical(f(NULL, preds, "focal", allow_null = TRUE), character())
  expect_error(
    f(NULL, preds, "focal", allow_null = FALSE),
    "must name predictor columns"
  )
  expect_error(f(NULL, preds, "focal"), "must name predictor columns")
})

test_that("validate_prediction_grid_terms() checks type, duplicates, names", {
  f <- drmTMB:::validate_prediction_grid_terms
  expect_error(f(1, preds, "focal"), "must be a character vector")
  expect_error(f(c("x", NA), preds, "focal"), "must be a character vector")
  expect_identical(f(c("x", "g", "x"), preds, "focal"), c("x", "g"))
  expect_identical(f(character(), preds, "focal"), character())
  expect_error(f(c("x", "nope"), preds, "focal"), "Available predictors")
  expect_error(f("nope", preds, "focal"), "unknown predictor")
})

test_that("validate_prediction_grid_named_terms() validates names", {
  f <- drmTMB:::validate_prediction_grid_named_terms
  expect_invisible(f(character(), preds, "at"))
  expect_identical(f(character(), preds, "at"), character())
  expect_invisible(f(c("x", "g"), preds, "at"))
  expect_error(f(c("x", ""), preds, "at"), "names must be non-empty")
  expect_error(f("nope", preds, "at"), "unknown predictor")
  expect_error(f("nope", preds, "at"), "Available predictors")
})

test_that("validate_prediction_grid_list() requires a named list", {
  f <- drmTMB:::validate_prediction_grid_list
  expect_identical(f(NULL, "at"), list())
  expect_identical(f(list(), "at"), list())
  ok <- list(x = 1, g = "a")
  expect_identical(f(ok, "at"), ok)
  expect_error(f(data.frame(x = 1), "at"), "must be a named list")
  expect_error(f(list(1, 2), "at"), "must be a named list")
  expect_error(f(list(x = 1, 2), "at"), "must be a named list")
  nm_na <- list(1, 2)
  names(nm_na) <- c("x", NA)
  expect_error(f(nm_na, "at"), "must be a named list")
  expect_error(f(1:3, "at"), "must be a named list")
})

test_that("prediction_grid_cast_values() keeps factor levels and ordering", {
  f <- drmTMB:::prediction_grid_cast_values
  tmpl <- factor(c("a", "b", "c"), levels = c("c", "b", "a"))
  out <- f(c("a", "c"), tmpl, "g")
  expect_s3_class(out, "factor")
  expect_identical(levels(out), c("c", "b", "a"))
  expect_false(is.ordered(out))
  expect_identical(as.character(out), c("a", "c"))

  ord <- factor(c("lo", "hi"), levels = c("lo", "hi"), ordered = TRUE)
  out_ord <- f("hi", ord, "g")
  expect_true(is.ordered(out_ord))
  expect_identical(levels(out_ord), c("lo", "hi"))

  expect_error(f("zzz", tmpl, "g"), "Allowed levels")
  expect_error(f(c("a", "zzz"), tmpl, "g"), "invalid level")
})

test_that("prediction_grid_cast_values() casts Date and POSIXct templates", {
  f <- drmTMB:::prediction_grid_cast_values
  d <- as.Date("2020-01-01") + 0:2
  out <- f("2021-05-06", d, "d")
  expect_s3_class(out, "Date")
  expect_identical(out, as.Date("2021-05-06"))

  tt <- as.POSIXct("2020-01-01 12:00:00", tz = "America/Edmonton")
  out_tt <- f("2021-05-06 08:30:00", tt, "t")
  expect_s3_class(out_tt, "POSIXct")
  expect_identical(attr(out_tt, "tzone"), "America/Edmonton")
  expect_equal(
    out_tt,
    as.POSIXct("2021-05-06 08:30:00", tz = "America/Edmonton")
  )

  tt_utc <- as.POSIXct("2020-01-01 12:00:00", tz = "UTC")
  expect_identical(attr(f("2021-05-06 08:30:00", tt_utc, "t"), "tzone"), "UTC")
})

test_that("prediction_grid_cast_values() casts integer, numeric, logical", {
  f <- drmTMB:::prediction_grid_cast_values
  expect_identical(f(c(1, 2), 1:5, "k"), c(1L, 2L))
  expect_identical(f("3", 1:5, "k"), 3L)
  expect_identical(f(2L, c(0.5, 1.5), "x"), 2)
  expect_identical(f("2.5", c(0.5, 1.5), "x"), 2.5)
  expect_identical(f(c("TRUE", "FALSE"), c(TRUE, NA), "b"), c(TRUE, FALSE))
  expect_identical(f(0, c(TRUE, FALSE), "b"), FALSE)
})

test_that("prediction_grid_cast_values() treats character templates as factors", {
  f <- drmTMB:::prediction_grid_cast_values
  tmpl <- c("b", "a", NA, "b", "c")
  out <- f(c("a", "c"), tmpl, "s")
  expect_s3_class(out, "factor")
  expect_identical(levels(out), c("b", "a", "c"))
  expect_identical(as.character(out), c("a", "c"))
  expect_error(f("zzz", tmpl, "s"), "Allowed values")
  expect_error(f("zzz", tmpl, "s"), "invalid value")
})

test_that("prediction_grid_tz() falls back to UTC", {
  f <- drmTMB:::prediction_grid_tz
  expect_identical(f(as.POSIXct("2020-01-01", tz = "UTC")), "UTC")
  expect_identical(f(as.POSIXct("2020-01-01", tz = "Asia/Tokyo")), "Asia/Tokyo")
  x <- structure(0, class = c("POSIXct", "POSIXt"), tzone = "")
  expect_identical(f(x), "UTC")
  expect_identical(f(1), "UTC")
})

test_that("prediction_grid_predictors() reads terms of a fit-like list", {
  f <- drmTMB:::prediction_grid_predictors
  obj <- list(
    model = list(
      terms = list(
        mu = terms(y ~ x + g),
        sigma = terms(~ x + z + other)
      )
    ),
    data = data.frame(y = 1, x = 1, g = "a", z = 2)
  )
  # response dropped, order of first appearance, columns absent from data dropped
  expect_identical(f(obj), c("x", "g", "z"))
})

test_that("prediction_grid_values() dispatches on `values`", {
  f <- drmTMB:::prediction_grid_values
  expect_identical(f(c(1, 2, 3), NULL, n = 5L, term = "x"), c(1, 2, 3))
  expect_equal(f(c(0, 5, 10), NULL, n = 2L, term = "x"), c(0, 10))
  expect_identical(f(c(1, 2, 3), c(2, 4), n = 5L, term = "x"), c(2, 4))
  expect_error(f(c(1, 2), numeric(), n = 3L, term = "x"), "non-empty and non-missing")
  expect_error(f(c(1, 2), c(1, NA), n = 3L, term = "x"), "non-empty and non-missing")
  expect_error(
    f(factor(c("a", "b")), "zzz", n = 3L, term = "g"),
    "Allowed levels"
  )
})

test_that("prediction_grid_auto_values() covers each template type", {
  f <- drmTMB:::prediction_grid_auto_values
  # factor: all levels, ordering kept, unused levels kept
  fac <- factor(c("b", "a"), levels = c("c", "b", "a"), ordered = TRUE)
  out <- f(fac, n = 2L)
  expect_identical(levels(out), c("c", "b", "a"))
  expect_true(is.ordered(out))
  expect_identical(as.character(out), c("c", "b", "a"))

  # numeric: few unique values returned sorted, non-finite dropped
  expect_identical(f(c(3, 1, 3, NA, Inf), n = 5L), c(1, 3))
  expect_equal(f(c(0, 1, 2, 3, 4), n = 3L), c(0, 2, 4))
  expect_identical(f(c(1L, 2L, 2L), n = 2L), c(1L, 2L))

  # logical
  expect_identical(f(c(TRUE, NA, FALSE, TRUE), n = 5L), c(FALSE, TRUE))

  # character: order of first appearance, as factor
  ch <- f(c("b", "a", NA, "b"), n = 5L)
  expect_s3_class(ch, "factor")
  expect_identical(levels(ch), c("b", "a"))

  # Date
  d <- as.Date("2020-01-01") + c(0, 10, 20, 30, 40)
  expect_identical(f(d[c(1, 1, 3)], n = 5L), d[c(1, 3)])
  dseq <- f(d, n = 3L)
  expect_s3_class(dseq, "Date")
  expect_equal(as.numeric(dseq), as.numeric(d[c(1, 3, 5)]))

  # POSIXct
  tt <- as.POSIXct("2020-01-01 00:00:00", tz = "UTC") + 3600 * c(0, 1, 2, 3, 4)
  expect_equal(f(tt[c(2, 2, 4)], n = 5L), tt[c(2, 4)])
  tseq <- f(tt, n = 3L)
  expect_s3_class(tseq, "POSIXct")
  expect_equal(as.numeric(tseq), as.numeric(tt[c(1, 3, 5)]))
})
