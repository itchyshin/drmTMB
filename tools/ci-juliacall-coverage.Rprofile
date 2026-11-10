# Sourced in every R process started during julia-bridge coverage (covr, callr).
# Do not call JuliaCall::julia_setup() here — drm_julia_setup() must run first
# with install = TRUE on its own disposable project (JuliaCall returns early when
# already initialized, which would skip RCall in that project).
if (identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true")) {
  Sys.setenv(R_HOME = R.home())
  install_lib <- Sys.getenv("DRMTMB_COVR_INSTALL_LIB", "")
  if (nzchar(install_lib) && requireNamespace("pkgload", quietly = TRUE)) {
    local({
      ns <- asNamespace("pkgload")
      if (!exists(".drmtmb_covr_load_all_orig", envir = ns, inherits = FALSE)) {
        orig <- get("load_all", envir = ns)
        assign(".drmtmb_covr_load_all_orig", orig, envir = ns)
        shim <- function(path, ...) {
          covr_root <- Sys.getenv("DRMTMB_COVR_PKG_ROOT", "")
          if (nzchar(covr_root)) {
            same <- tryCatch(
              identical(
                normalizePath(path, winslash = "/", mustWork = TRUE),
                normalizePath(covr_root, winslash = "/", mustWork = TRUE)
              ),
              error = function(e) FALSE
            )
            if (isTRUE(same)) {
              return(library(drmTMB, lib.loc = install_lib, quietly = TRUE))
            }
          }
          get(".drmtmb_covr_load_all_orig", envir = ns)(path, ...)
        }
        if (bindingIsLocked("load_all", ns)) {
          unlockBinding("load_all", ns)
        }
        assign("load_all", shim, envir = ns)
        lockBinding("load_all", ns)
      }
    })
  }
  covr_root <- Sys.getenv("DRMTMB_COVR_PKG_ROOT", "")
  if (nzchar(covr_root) && requireNamespace("testthat", quietly = TRUE)) {
    local({
      ns <- asNamespace("testthat")
      if (exists(".drmtmb_covr_test_path_orig", envir = ns, inherits = FALSE)) {
        return(invisible(NULL))
      }
      orig <- get("test_path", envir = ns)
      assign(".drmtmb_covr_test_path_orig", orig, envir = ns)
      patch <- function(...) {
        args <- list(...)
        if (length(args) == 2L && identical(args, list("..", ".."))) {
          return(normalizePath(covr_root, winslash = "/", mustWork = TRUE))
        }
        do.call(orig, args)
      }
      if (bindingIsLocked("test_path", ns)) {
        unlockBinding("test_path", ns)
      }
      assign("test_path", patch, envir = ns)
      lockBinding("test_path", ns)
    })
  }
}
