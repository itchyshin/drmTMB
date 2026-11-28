test_that("DRM_JL_JULIA_HOME takes precedence over JULIA_HOME", {
  withr::local_envvar(c(
    DRM_JL_JULIA_HOME = "/tmp/drmtmb-julia-override",
    JULIA_HOME = "/tmp/drmtmb-julia-base"
  ))

  expect_identical(drm_test_julia_home(), "/tmp/drmtmb-julia-override")
})

test_that("JULIA_HOME is used when DRM_JL_JULIA_HOME is absent", {
  withr::local_envvar(c(
    DRM_JL_JULIA_HOME = NA,
    JULIA_HOME = "/tmp/drmtmb-julia-base"
  ))

  expect_identical(drm_test_julia_home(), "/tmp/drmtmb-julia-base")
})

test_that("set helper writes the effective Julia home for child setup", {
  withr::local_envvar(c(
    DRM_JL_JULIA_HOME = "/tmp/drmtmb-julia-override",
    JULIA_HOME = "/tmp/drmtmb-julia-base"
  ))

  expect_identical(drm_test_set_julia_home(), "/tmp/drmtmb-julia-override")
  expect_identical(Sys.getenv("JULIA_HOME"), "/tmp/drmtmb-julia-override")
})

test_that("Julia BINDIR probe quotes -e for sh-safe system2 (#1746)", {
  captured <- NULL
  mock_system2 <- function(command, args, ...) {
    captured <<- list(command = command, args = args)
    "/fake/julia/bindir"
  }
  testthat::local_mocked_bindings(system2 = mock_system2, .package = "base")
  quote_type <- if (.Platform$OS.type == "windows") "cmd" else "sh"
  expect_identical(
    drm_test_julia_bindir_from_path("/usr/bin/julia"),
    "/fake/julia/bindir"
  )
  expect_identical(
    captured$args,
    c("-e", shQuote("print(Sys.BINDIR)", type = quote_type))
  )
})

test_that("local helper exposes Julia home only in the caller scope", {
  old_home <- Sys.getenv("JULIA_HOME", unset = NA_character_)
  old_override <- Sys.getenv("DRM_JL_JULIA_HOME", unset = NA_character_)

  observed <- local({
    withr::local_envvar(c(
      DRM_JL_JULIA_HOME = "/tmp/drmtmb-julia-override",
      JULIA_HOME = "/tmp/drmtmb-julia-base"
    ))

    c(
      returned = drm_test_local_julia_home(),
      visible = Sys.getenv("JULIA_HOME")
    )
  })

  expect_identical(
    unname(observed),
    c("/tmp/drmtmb-julia-override", "/tmp/drmtmb-julia-override")
  )
  expect_identical(Sys.getenv("JULIA_HOME", unset = NA_character_), old_home)
  expect_identical(
    Sys.getenv("DRM_JL_JULIA_HOME", unset = NA_character_),
    old_override
  )
})
