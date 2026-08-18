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
# hung inside julia_setup() for ~10448s on the post-#1061 tarball (2026-08-17)
# because a CRAN-lane expect_error(engine = "julia") reached setup. Opt in with
# DRMTMB_JULIA_TESTS=true. Repository CI uses NOT_CRAN=true (skip is a no-op).
#
# Match tests/testthat.R CRAN-lane detection for non-interactive checks, then
# also call skip_on_cran() for defense in depth. Interactive sessions without
# NOT_CRAN still rely on skip_on_cran() so local exploration keeps working.
drm_skip_live_julia <- function() {
  if (identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true")) {
    return(invisible(TRUE))
  }
  # Same predicate as tests/testthat.R `not_cran`, but only force-skip when
  # non-interactive (R CMD check / win-builder).
  if (
    !isTRUE(as.logical(Sys.getenv("NOT_CRAN", "false"))) &&
      !interactive()
  ) {
    testthat::skip(
      "Live Julia skipped on CRAN lane (set NOT_CRAN=true or DRMTMB_JULIA_TESTS=true)."
    )
  }
  testthat::skip_on_cran()
  invisible(TRUE)
}
