# Sourced during julia-bridge coverage. The workflow sets R_PROFILE_USER to this
# file. callr::r() defaults to user_profile = "project", which ignores
# R_PROFILE_USER and sources only tests/testthat/.Rprofile. The coverage driver
# plants that file so it sys.source()s this one. Do not call
# JuliaCall::julia_setup() here — drm_julia_setup() must run first with
# install = TRUE on its own disposable project (JuliaCall returns early when
# already initialized, which would skip RCall in that project).
#
# Package namespaces are locked. The originals of the shims below live in
# .drmtmb_covr_box in the global environment. Assigning a new name such as
# .drmtmb_covr_load_all_orig into the namespace raises
# "cannot add bindings to a locked environment", and that error aborts R
# startup when callr sources the planted profile (status non-zero, no result
# file: "could not start R").
if (identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true")) {
  Sys.setenv(R_HOME = R.home())
  if (!exists(".drmtmb_covr_box", envir = globalenv(), inherits = FALSE)) {
    assign(
      ".drmtmb_covr_box",
      new.env(parent = emptyenv()),
      envir = globalenv()
    )
  }
  box <- get(".drmtmb_covr_box", envir = globalenv(), inherits = FALSE)

  install_lib <- Sys.getenv("DRMTMB_COVR_INSTALL_LIB", "")
  if (nzchar(install_lib) && requireNamespace("pkgload", quietly = TRUE)) {
    ns <- asNamespace("pkgload")
    if (!exists("load_all", envir = box, inherits = FALSE)) {
      assign("load_all", get("load_all", envir = ns), envir = box)
      shim <- function(path, ...) {
        covr_root <- Sys.getenv("DRMTMB_COVR_PKG_ROOT", "")
        lib <- Sys.getenv("DRMTMB_COVR_INSTALL_LIB", "")
        if (nzchar(covr_root) && nzchar(lib)) {
          same <- tryCatch(
            identical(
              normalizePath(path, winslash = "/", mustWork = TRUE),
              normalizePath(covr_root, winslash = "/", mustWork = TRUE)
            ),
            error = function(e) FALSE
          )
          installed <- file.path(lib, "drmTMB", "DESCRIPTION")
          # lib is the library root (covr install_path), not the package
          # directory. Skip until package_coverage has installed it, so the
          # driver's own load_all(compile = TRUE) still compiles.
          if (isTRUE(same) && file.exists(installed)) {
            return(library(drmTMB, lib.loc = lib, quietly = TRUE))
          }
        }
        get(
          "load_all",
          envir = get(".drmtmb_covr_box", envir = globalenv())
        )(path, ...)
      }
      if (bindingIsLocked("load_all", ns)) {
        unlockBinding("load_all", ns)
      }
      assign("load_all", shim, envir = ns)
      lockBinding("load_all", ns)
    }
  }
  covr_root <- Sys.getenv("DRMTMB_COVR_PKG_ROOT", "")
  if (nzchar(covr_root) && requireNamespace("testthat", quietly = TRUE)) {
    ns <- asNamespace("testthat")
    if (!exists("test_path", envir = box, inherits = FALSE)) {
      assign("test_path", get("test_path", envir = ns), envir = box)
      patch <- function(...) {
        args <- list(...)
        if (length(args) == 2L && identical(args, list("..", ".."))) {
          root <- Sys.getenv("DRMTMB_COVR_PKG_ROOT", "")
          return(normalizePath(root, winslash = "/", mustWork = TRUE))
        }
        orig <- get(
          "test_path",
          envir = get(".drmtmb_covr_box", envir = globalenv())
        )
        do.call(orig, args)
      }
      if (bindingIsLocked("test_path", ns)) {
        unlockBinding("test_path", ns)
      }
      assign("test_path", patch, envir = ns)
      lockBinding("test_path", ns)
    }
  }
}
