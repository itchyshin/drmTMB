# #1583 -- `drm_julia_rhs_is_intercept_only()` was defined twice in
# R/julia-bridge.R; the second silently shadowed the first.

test_that("drm_julia_rhs_is_intercept_only() is defined exactly once (#1583)", {
  src <- file.path(test_path("..", ".."), "R", "julia-bridge.R")
  if (!file.exists(src)) {
    # Installed-package test run (R CMD check): no source tree to parse.
    succeed()
    return(invisible())
  }
  exprs <- parse(src, keep.source = FALSE)
  defs <- vapply(exprs, function(e) {
    is.call(e) && (identical(e[[1L]], as.name("<-")) || identical(e[[1L]], as.name("="))) &&
      identical(e[[2L]], as.name("drm_julia_rhs_is_intercept_only"))
  }, logical(1L))
  expect_equal(sum(defs), 1L)
})

test_that("drm_julia_rhs_is_intercept_only() follows stats::terms() semantics", {
  f <- drmTMB:::drm_julia_rhs_is_intercept_only
  expect_true(f(quote(1)))
  expect_true(f(quote((1))))
  expect_false(f(quote(0 + z)))
  expect_false(f(quote(x)))
  expect_false(f(quote(1 + offset(z))))
})
