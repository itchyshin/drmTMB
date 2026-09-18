test_that("Julia checkout paths prefer canonical settings and retain old ones", {
  withr::local_options(list(drmTMB.DRModels.jl.path = NULL, drmTMB.DRM.jl.path = NULL))
  withr::local_envvar(c(DRMODELS_JL_PATH = NA, DRM_JL_PATH = NA))
  root <- withr::local_tempdir()
  dir.create(file.path(root, "r-package"))
  withr::local_dir(file.path(root, "r-package"))
  expect_identical(drm_julia_path(), "")
  dir.create(file.path(root, "DRM.jl"))
  expect_identical(drm_julia_path(), normalizePath(file.path(root, "DRM.jl"), winslash = "/"))
  dir.create(file.path(root, "DRModels.jl"))
  expect_identical(drm_julia_path(), normalizePath(file.path(root, "DRModels.jl"), winslash = "/"))
  Sys.setenv(DRM_JL_PATH = "legacy-env")
  expect_identical(drm_julia_path(), "legacy-env")
  options(drmTMB.DRM.jl.path = "legacy-option")
  expect_identical(drm_julia_path(), "legacy-option")
  Sys.setenv(DRMODELS_JL_PATH = "canonical-env")
  expect_identical(drm_julia_path(), "canonical-env")
  options(drmTMB.DRModels.jl.path = "canonical-option")
  expect_identical(drm_julia_path(), "canonical-option")
  options(drmTMB.DRModels.jl.path = NA_character_)
  expect_identical(drm_julia_path(), "canonical-env")
})

test_that("module loader selects canonical then legacy and reports both failures", {
  calls <- character()
  command <- function(code) { calls <<- c(calls, code); invisible(NULL) }
  expect_identical(drm_julia_load_module(command), "DRModels")
  expect_identical(calls, "import DRModels; drmTMB_backend = DRModels")
  calls <- character()
  legacy <- function(code) {
    calls <<- c(calls, code)
    if (grepl("import DRModels", code, fixed = TRUE)) stop("new unavailable")
  }
  expect_identical(drm_julia_load_module(legacy), "DRM")
  expect_identical(calls, c("import DRModels; drmTMB_backend = DRModels", "import DRM; drmTMB_backend = DRM"))
  expect_error(drm_julia_load_module(function(code) stop(code)), "Could not load DRModels or DRM")
  expect_error(drm_julia_load_module(function(code) stop("Tuple{Base.PkgId}")), "Tuple\\{Base.PkgId\\}")
})

test_that("generated Julia helpers use the selected backend", {
  for (source in list(drm_julia_conditional_gaussian_components_source(), drm_julia_xfam_helper_source())) {
    expect_match(source, "drmTMB_backend.", fixed = TRUE)
    expect_false(grepl("DRM.", source, fixed = TRUE))
  }
  expect_match(paste(deparse(body(drm_julia_call_joint)), collapse = "\n"), "drmTMB_backend.drm_bridge_joint", fixed = TRUE)
  expect_match(paste(deparse(formals(drm_julia_require_joint_capability)), collapse = "\n"), "isdefined(drmTMB_backend,", fixed = TRUE)
})

test_that("setup activates before importing and registers only shared-alias helpers", {
  skip_if_not_installed("JuliaCall")
  root <- withr::local_tempdir()
  writeLines('name = "DRModels"', file.path(root, "Project.toml"))
  for (selected in c("DRModels", "DRM")) {
    state <- new.env(parent = emptyenv())
    local_mocked_bindings(drm_julia_setup_state = state,
                          drm_julia_cran_lane_blocked = function(...) FALSE)
    commands <- character()
    local_mocked_bindings(
      julia_setup = function(...) invisible(NULL),
      julia_command = function(code) {
        commands <<- c(commands, code)
        if (selected == "DRM" && startsWith(code, "import DRModels;")) stop("not found")
        invisible(NULL)
      }, .package = "JuliaCall"
    )
    expect_message(drm_julia_setup(root), "Starting Julia")
    expect_match(commands[[1L]], "Pkg.activate(", fixed = TRUE)
    expect_identical(state$module, selected)
    expect_true(state$ready)
    helpers <- commands[!startsWith(commands, "import ")]
    expect_false(any(grepl("\\b(DRM|DRModels)[.,]", helpers)))
    expect_true(any(grepl("isdefined(drmTMB_backend,", helpers, fixed = TRUE)))
    expect_true(any(grepl("drmTMB_backend.drm_bridge", helpers, fixed = TRUE)))
    n <- length(commands)
    drm_julia_setup(root)
    expect_length(commands, n)
  }
})
