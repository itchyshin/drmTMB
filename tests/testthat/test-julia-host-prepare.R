# FX1: JuliaCall 0.17.6 + official Julia on Ubuntu can SIGSEGV (exit 139)
# during install_dependency.jl. Two host conditions from sweep-oct16/t5:
# JULIA_PROJECT pointed at the DRModels.jl checkout (so Pkg.add("RCall")
# ran in that project), and the apt R wrapper's LD_LIBRARY_PATH preferred
# system libunwind over Julia's (JuliaCall#238). The red-proof below fails
# on ca3ddef (julia_setup sees JULIA_PROJECT still set) and passes after
# drm_julia_prepare_host() runs first.

test_that("drm_julia_setup clears JULIA_PROJECT before JuliaCall::julia_setup (FX1)", {
  skip_if_not_installed("JuliaCall")
  root <- withr::local_tempdir()
  writeLines('name = "DRModels"', file.path(root, "Project.toml"))
  state <- new.env(parent = emptyenv())
  withr::local_envvar(c(
    JULIA_PROJECT = "/tmp/DRModels.jl-pin",
    JULIA_NUM_THREADS = NA,
    JULIA_HOME = NA
  ))
  local_mocked_bindings(
    drm_julia_setup_state = state,
    drm_julia_cran_lane_blocked = function(...) FALSE
  )
  seen <- NULL
  local_mocked_bindings(
    julia_setup = function(...) {
      seen <<- list(
        project = Sys.getenv("JULIA_PROJECT", unset = ""),
        threads = Sys.getenv("JULIA_NUM_THREADS", unset = "")
      )
      invisible(NULL)
    },
    julia_command = function(...) invisible(NULL),
    julia_eval = function(code, ...) {
      if (grepl("project_file_manifest_path", code, fixed = TRUE)) {
        return(c(manifest = "", manifest_format = "2.0", runtime = "1.10.0"))
      }
      "DRModels"
    },
    .package = "JuliaCall"
  )

  drm_julia_setup(root)

  expect_false(is.null(seen), info = "JuliaCall::julia_setup was not reached")
  expect_identical(seen$project, "")
  expect_identical(seen$threads, "1")
})

test_that("prepare_host prepends Julia libunwind to LD_PRELOAD for child julia", {
  root <- withr::local_tempdir()
  bindir <- file.path(root, "bin")
  libdir <- file.path(root, "lib", "julia")
  dir.create(bindir, recursive = TRUE)
  dir.create(libdir, recursive = TRUE)
  file.create(file.path(bindir, "julia"))
  unwind <- file.path(libdir, "libunwind.so.8")
  file.create(unwind)
  withr::local_envvar(c(
    JULIA_HOME = bindir,
    JULIA_PROJECT = NA,
    JULIA_NUM_THREADS = "4",
    LD_PRELOAD = "/opt/other/libfoo.so"
  ))

  info <- drm_julia_prepare_host()

  expect_identical(info$bindir, normalizePath(bindir, winslash = "/", mustWork = FALSE))
  expect_identical(info$libunwind, normalizePath(unwind, winslash = "/", mustWork = FALSE))
  expect_match(Sys.getenv("LD_PRELOAD"), "libunwind\\.so\\.8", perl = TRUE)
  expect_match(Sys.getenv("LD_PRELOAD"), "/opt/other/libfoo\\.so", perl = TRUE)
  expect_identical(Sys.getenv("JULIA_NUM_THREADS"), "4")
})

test_that("prepare_host does not invent a Julia bindir when none is configured", {
  withr::local_envvar(c(
    JULIA_HOME = NA,
    JULIA_PROJECT = NA,
    PATH = "/tmp/drmtmb-empty-path"
  ))
  info <- drm_julia_prepare_host()
  expect_identical(info$bindir, "")
  expect_identical(info$libunwind, "")
})

test_that("status-139 JuliaCall errors become a classed host-setup abort", {
  crash <- simpleError(
    "running command '.../JuliaCall/julia/install_dependency.jl' '/usr/lib/R' had status 139"
  )
  caught <- tryCatch(drm_julia_setup_failed(crash), error = identity)
  expect_s3_class(caught, "drmTMB_julia_host_setup_error")
  expect_match(conditionMessage(caught), "libunwind|JULIA_PROJECT|139")

  other <- simpleError("Package DRM not found")
  rethrown <- tryCatch(drm_julia_setup_failed(other), error = identity)
  expect_identical(rethrown, other)
})
