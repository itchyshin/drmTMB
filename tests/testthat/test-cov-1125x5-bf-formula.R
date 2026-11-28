# drm_formula / bf assembly from R/bf.R and R/parse-formula.R.

test_that("drm_formula() records entries and print method is invisible", {
  f <- drm_formula(y ~ x, sigma ~ 1)
  expect_s3_class(f, "drm_formula")
  expect_length(f$entries, 2L)
  expect_equal(f$entries[[1L]]$dpar, "mu")
  expect_equal(f$entries[[2L]]$dpar, "sigma")
  expect_invisible(print(f))
})

test_that("bf() is an alias for drm_formula()", {
  f1 <- drm_formula(y ~ x)
  f2 <- bf(y ~ x)
  expect_equal(f2$entries[[1L]]$dpar, f1$entries[[1L]]$dpar)
  expect_identical(f2$names, f1$names)
})

test_that("drm_formula_env() returns env or fallback", {
  form <- drm_formula(y ~ x)
  expect_identical(
    drmTMB:::drm_formula_env(form, globalenv()),
    form$env
  )
  bare <- list(calls = form$calls, names = form$names, entries = form$entries)
  class(bare) <- "drm_formula"
  expect_identical(
    drmTMB:::drm_formula_env(bare, globalenv()),
    globalenv()
  )
})

test_that("drm_formula() rejects empty calls and invalid symbols", {
  expect_error(drm_formula(), "requires at least one formula")
  expect_error(
    local({
      n <- 1
      drm_formula(not_a_formula)
    }),
    "could not evaluate"
  )
})

test_that("parse_drm_formula_entry() classifies named and unnamed formulas", {
  entry <- drmTMB:::parse_drm_formula_entry(quote(y ~ x), "", 1L)
  expect_equal(entry$dpar, "mu")
  expect_equal(entry$response, "y")
  sigma_entry <- drmTMB:::parse_drm_formula_entry(quote(~ z), "sigma", 2L)
  expect_equal(sigma_entry$dpar, "sigma")
  expect_true(is.na(sigma_entry$response))
  expect_error(
    drmTMB:::parse_drm_formula_entry(quote(y + x), "mu", 1L),
    "must be formulas"
  )
})