drm_test_drmjl_path <- function(envvar = "DRM_JL_PHYLO_PATH") {
  path <- Sys.getenv(envvar, "")
  if (!nzchar(path) && !identical(envvar, "DRM_JL_PHYLO_PATH")) {
    path <- Sys.getenv("DRM_JL_PHYLO_PATH", "")
  }
  path
}

drm_test_julia_home <- function() {
  home <- Sys.getenv("DRM_JL_JULIA_HOME", "")
  if (!nzchar(home)) {
    home <- Sys.getenv("JULIA_HOME", "")
  }
  home
}

drm_test_set_julia_home <- function() {
  home <- drm_test_julia_home()
  if (nzchar(home)) {
    Sys.setenv(JULIA_HOME = home)
  }
  invisible(home)
}

drm_test_local_julia_home <- function(.local_envir = parent.frame()) {
  home <- drm_test_julia_home()
  if (nzchar(home)) {
    withr::local_envvar(c(JULIA_HOME = home), .local_envir = .local_envir)
  }
  invisible(home)
}
