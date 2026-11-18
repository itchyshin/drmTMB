test_that("%||% is defined in the package namespace for R < 4.4 (#1550)", {
  expect_true(exists("%||%", envir = asNamespace("drmTMB"), inherits = FALSE))
  op <- get("%||%", envir = asNamespace("drmTMB"), inherits = FALSE)
  expect_identical(op(NULL, 1L), 1L)
  expect_identical(op(2L, 1L), 2L)
  expect_identical(op(integer(0), 1L), integer(0))
  expect_identical(op(NA, 1L), NA)
})

test_that("internal callers of %||% work without a base or global definition (#1550)", {
  expect_identical(drmTMB:::drm_mspl_link_name(NULL), "logit")
})
