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

# Live JuliaCall::julia_setup() is unsafe on CRAN / win-builder even when
# JuliaCall is installed (Suggests) and Julia is on PATH. Ligges R-release
# and R-oldrelease hung inside julia_setup() for 105-149 minutes (2026-08-16).
# Opt in with DRMTMB_JULIA_TESTS=true. Repository CI uses NOT_CRAN=true and
# still runs the full suite (skip_on_cran is a no-op there).
drm_skip_live_julia <- function() {
  if (!identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true")) {
    testthat::skip_on_cran()
  }
  invisible(TRUE)
}
