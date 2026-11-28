test_that("weights = NULL counts as no weights for the Julia bridge (#1450)", {
  expect_true(drmTMB:::drm_julia_weights_absent(TRUE, NULL, data.frame(), globalenv()))
  expect_true(drmTMB:::drm_julia_weights_absent(FALSE, quote(NULL), data.frame(x = 1), globalenv()))
  w <- NULL
  expect_true(drmTMB:::drm_julia_weights_absent(FALSE, quote(w), data.frame(x = 1), environment()))
  expect_false(drmTMB:::drm_julia_weights_absent(FALSE, quote(wt), data.frame(wt = 2), globalenv()))
  expect_false(
    drmTMB:::drm_julia_weights_absent(
      FALSE, quote(nonexistent_col), data.frame(x = 1), globalenv()
    )
  )
})

test_that("drmTMB() does not abort on weights = NULL before the Julia bridge (#1450)", {
  skip_if_not_installed("JuliaCall")
  skip_on_cran()
  dat <- data.frame(y = stats::rnorm(12), x = stats::rnorm(12))
  err <- tryCatch(
    drmTMB(bf(y ~ x), data = dat, family = gaussian(), engine = "julia", weights = NULL),
    error = identity
  )
  if (!inherits(err, "error")) {
    succeed()
    return(invisible(NULL))
  }
  expect_false(grepl("does not support.*weights", conditionMessage(err), ignore.case = TRUE))
})