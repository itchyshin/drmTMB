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

test_that("module loader preserves the selected checkout's import errors", {
  sentinel <- simpleError("dependency failure Tuple{Base.PkgId}")
  caught <- tryCatch(drm_julia_load_module("chosen", evaluate = function(code) stop(sentinel)), error = identity)
  expect_identical(caught, sentinel)
})

test_that("test path settings support canonical-only configurations and family overrides", {
  withr::local_options(list(drmTMB.DRModels.jl.path = NULL, drmTMB.DRM.jl.path = NULL))
  withr::local_envvar(c(DRMODELS_JL_PATH = NA, DRM_JL_PATH = NA,
                       DRM_JL_PHYLO_PATH = NA, DRM_JL_XFAM_PATH = NA))
  expect_identical(drm_test_drmjl_path(), "")
  Sys.setenv(DRM_JL_PHYLO_PATH = "phylo")
  expect_identical(drm_test_drmjl_path(), "phylo")
  Sys.setenv(DRM_JL_PATH = "legacy")
  expect_identical(drm_test_drmjl_path(), "legacy")
  options(drmTMB.DRM.jl.path = "legacy-option")
  expect_identical(drm_test_drmjl_path(), "legacy-option")
  Sys.setenv(DRMODELS_JL_PATH = "canonical")
  expect_identical(drm_test_drmjl_path(), "canonical")
  options(drmTMB.DRModels.jl.path = "canonical-option")
  expect_identical(drm_test_drmjl_path(), "canonical-option")
  Sys.setenv(DRM_JL_XFAM_PATH = "family")
  expect_identical(drm_test_drmjl_path("DRM_JL_XFAM_PATH"), "family")
  options(drmTMB.DRModels.jl.path = NULL, drmTMB.DRM.jl.path = NULL)
  Sys.unsetenv(c("DRM_JL_PATH", "DRM_JL_PHYLO_PATH"))
  expect_identical(drm_test_drmjl_path(), "canonical")
  options(drmTMB.DRModels.jl.path = NA_character_)
  expect_identical(drm_test_drmjl_path("DRMODELS_JL_PATH"), "canonical")
  withr::local_envvar(c(DRMODELS_JL_PATH = withr::local_tempdir(), DRMTMB_JULIA_TESTS = "true"))
  expect_silent(.drm_skip_live_julia_impl())
})

test_that("family-specific checkout reaches production setup selection", {
  withr::local_options(list(
    drmTMB.DRModels.jl.path = "global-canonical",
    drmTMB.DRM.jl.path = NULL
  ))
  withr::local_envvar(c(
    DRMODELS_JL_PATH = NA,
    DRM_JL_PATH = NA,
    DRM_JL_XFAM_PATH = "family-selected"
  ))

  selected <- drm_test_drmjl_path("DRM_JL_XFAM_PATH")
  expect_identical(selected, "family-selected")

  drm_test_local_drmjl_path(selected)
  expect_identical(drm_julia_path(), selected)

  setup_path <- eval(
    formals(drm_julia_setup)[["path"]],
    envir = environment(drm_julia_setup)
  )
  expect_identical(setup_path, selected)
})

test_that("stacked Julia environments cannot substitute a different checkout", {
  skip_if_not(identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true"))
  julia <- Sys.which("julia")
  if (!nzchar(julia)) julia <- file.path(drm_test_julia_home(), "julia")
  skip_if_not(file.exists(julia), "Julia executable unavailable")
  root <- withr::local_tempdir()
  fixture <- function(directory, name, body = "const marker = :selected") {
    path <- file.path(root, directory)
    dir.create(file.path(path, "src"), recursive = TRUE)
    writeLines(c(sprintf('name = "%s"', name),
                 'uuid = "4380cc63-766c-4975-bb7a-f3bc83facc98"'), file.path(path, "Project.toml"))
    writeLines(c(paste("module", name), body, "end"), file.path(path, "src", paste0(name, ".jl")))
    path
  }
  legacy <- fixture("legacy", "DRM")
  canonical <- fixture("canonical", "DRModels")
  broken <- fixture("broken", "DRModels", 'error("D269 dependency sentinel Tuple{Base.PkgId}")')
  foreign <- fixture("foreign", "DRM", "const marker = :foreign")
  run <- function(selected, stacked, preload = FALSE) {
    source <- drm_julia_load_module(selected, evaluate = identity)
    script <- file.path(root, "check.jl")
    writeLines(c("import Pkg", "empty!(LOAD_PATH); append!(LOAD_PATH, [\"@\", \"@stdlib\"])",
                 if (preload) c(paste0("Pkg.activate(", drm_julia_quote(stacked), ")"), "import DRM"),
                 paste0("Pkg.activate(", drm_julia_quote(selected), ")"),
                 paste0("push!(LOAD_PATH, ", drm_julia_quote(stacked), ")"),
                 paste0("println(\"SELECTED=\", ", source, ")"),
                 "@assert drmTMB_backend.marker == :selected"), script)
    suppressWarnings(system2(julia, c("--startup-file=no", "--compiled-modules=no", shQuote(script)),
                             stdout = TRUE, stderr = TRUE, timeout = 30))
  }
  for (pair in list(c(legacy, canonical), c(canonical, legacy))) {
    output <- run(pair[[1]], pair[[2]])
    expect_null(attr(output, "status"), info = paste(output, collapse = "\n"))
    expected <- if (identical(pair[[1]], legacy)) "DRM" else "DRModels"
    expect_true(paste0("SELECTED=", expected) %in% output)
  }
  output <- run(broken, legacy)
  expect_identical(attr(output, "status"), 1L)
  expect_match(paste(output, collapse = "\n"), "D269 dependency sentinel Tuple{Base.PkgId}", fixed = TRUE)
  output <- run(legacy, foreign, preload = TRUE)
  expect_identical(attr(output, "status"), 1L)
  expect_match(paste(output, collapse = "\n"), "different checkout|outside the selected checkout")
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
  for (selected in c("DRModels", "DRM")) {
    writeLines(sprintf('name = "%s"', selected), file.path(root, "Project.toml"))
    state <- new.env(parent = emptyenv())
    local_mocked_bindings(drm_julia_setup_state = state,
                          drm_julia_cran_lane_blocked = function(...) FALSE)
    commands <- character()
    local_mocked_bindings(
      julia_setup = function(...) invisible(NULL),
      julia_command = function(code) {
        commands <<- c(commands, code)
        invisible(NULL)
      },
      julia_eval = function(code, ...) selected, .package = "JuliaCall"
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
