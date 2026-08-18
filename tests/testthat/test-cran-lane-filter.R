# Contract for the CRAN invert filter in tests/testthat.R and the live-Julia
# hard stop in drm_julia_setup().
#
# Ligges win-builder hung inside JuliaCall::julia_setup() because JuliaCall is
# Suggests and those hosts have Julia. #1061's `^julia` filter excludes
# test-julia-*.R, but CRAN-lane expect_error(engine = "julia") in
# test-binomial-response.R still reached setup after Workflow G admitted
# fixed-effect binomial. The invert filter, drm_skip_live_julia(), and the
# drm_julia_setup() CRAN-lane abort must all stay in place.

test_that("CRAN invert filter excludes test-julia-*.R stems", {
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
  expect_false(grepl("^julia", "binomial-response"))
})

test_that("testthat CRAN invert filter drops julia contexts", {
  filter <- paste(
    "phase18|structured-re-conversion-contracts",
    "^associate-pairs",
    "^missing-response-g4g5-foundation$",
    "^zero-one-beta$",
    "^biv-gaussian$",
    "^profile-targets$",
    "^julia",
    sep = "|"
  )
  files <- testthat:::find_test_scripts(
    testthat::test_path(),
    filter = filter,
    invert = TRUE,
    full.names = FALSE
  )
  expect_false(any(grepl("^test-julia-", files)))
  expect_true(any(grepl("^test-binomial-response\\.R$", files)))
  expect_true(any(grepl("^test-xfam-bridge\\.R$", files)))
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

test_that("drm_julia_cran_lane_blocked matches CRAN-lane predicate", {
  withr::local_envvar(c(NOT_CRAN = "false", DRMTMB_JULIA_TESTS = NA))
  expect_true(drmTMB:::drm_julia_cran_lane_blocked(is_interactive = FALSE))
  expect_false(drmTMB:::drm_julia_cran_lane_blocked(is_interactive = TRUE))

  withr::local_envvar(c(NOT_CRAN = "true", DRMTMB_JULIA_TESTS = NA))
  expect_false(drmTMB:::drm_julia_cran_lane_blocked(is_interactive = FALSE))

  withr::local_envvar(c(NOT_CRAN = "false", DRMTMB_JULIA_TESTS = "true"))
  expect_false(drmTMB:::drm_julia_cran_lane_blocked(is_interactive = FALSE))
})

test_that("drm_julia_setup aborts before JuliaCall when CRAN-lane blocked", {
  skip_if(
    interactive() && !isTRUE(as.logical(Sys.getenv("NOT_CRAN", "false"))),
    "interactive CRAN-lane simulation is environment-gated"
  )
  withr::local_envvar(c(NOT_CRAN = "false", DRMTMB_JULIA_TESTS = NA))
  # Non-interactive + NOT_CRAN=false must abort before JuliaCall::julia_setup().
  expect_error(
    drmTMB:::drm_julia_setup(),
    "CRAN check lane|disabled on the CRAN"
  )
})
