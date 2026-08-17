# Contract for the CRAN invert filter in tests/testthat.R.
#
# Ligges win-builder hung inside JuliaCall::julia_setup() because JuliaCall is
# Suggests and those hosts have Julia. The invert filter must keep excluding
# every test-julia-*.R stem. Cheap R tests in test-xfam-bridge.R stay on the
# CRAN lane; live JuliaCall tests there use drm_skip_live_julia().

test_that("CRAN invert filter excludes test-julia-*.R and keeps xfam-bridge", {
  runner <- readLines(testthat::test_path("..", "testthat.R"))
  expect_true(any(grepl('"^julia"', runner, fixed = TRUE)))
  expect_true(any(grepl("invert = TRUE", runner, fixed = TRUE)))
  expect_true(any(grepl("if (not_cran)", runner, fixed = TRUE)))
  expect_true(any(grepl('test_check("drmTMB")', runner, fixed = TRUE)))

  julia_files <- list.files(
    testthat::test_path(),
    pattern = "^test-julia-.*\\.R$"
  )
  stems <- sub("^test-", "", sub("\\.R$", "", julia_files))
  expect_gte(length(stems), 10L)
  expect_true(all(grepl("^julia", stems)))
  expect_false(grepl("^julia", "xfam-bridge"))
  expect_false(grepl("^julia", "cran-lane-filter"))
})

test_that("drm_skip_live_julia skips on CRAN unless DRMTMB_JULIA_TESTS=true", {
  withr::local_envvar(c(NOT_CRAN = "false", DRMTMB_JULIA_TESTS = NA))
  cnd <- tryCatch(drm_skip_live_julia(), skip = identity)
  expect_s3_class(cnd, "skip")

  withr::local_envvar(c(NOT_CRAN = "false", DRMTMB_JULIA_TESTS = "true"))
  expect_silent(drm_skip_live_julia())

  withr::local_envvar(c(NOT_CRAN = "true", DRMTMB_JULIA_TESTS = NA))
  expect_silent(drm_skip_live_julia())
})
