# Issue #1127: DRM_JL_PATH is the source of truth for every test file's
# Julia-engine path, with DRM_JL_PHYLO_PATH as a fallback (kept for callers
# still using the older phylo-only env var). A legacy family-specific
# `envvar` (e.g. "DRM_JL_XFAM_PATH") is honored first if set, so existing
# opt-in overrides keep working, then falls through to DRM_JL_PATH and
# finally DRM_JL_PHYLO_PATH. This is the only place DRM_JL_PHYLO_PATH is
# read (gate N7-G3).
drm_test_drmjl_path <- function(envvar = "DRM_JL_PATH") {
  if (!identical(envvar, "DRM_JL_PATH") && !identical(envvar, "DRM_JL_PHYLO_PATH")) {
    path <- Sys.getenv(envvar, "")
    if (nzchar(path)) {
      return(path)
    }
  }
  path <- Sys.getenv("DRM_JL_PATH", "")
  if (!nzchar(path)) {
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

# Issue #1081 option 1: a green run states its own boundary. Every path
# through drm_skip_live_julia() records itself here, and a teardown file
# prints the tally so silence about the untested bridge is no longer silent.
drm_julia_bridge_summary_env <- new.env(parent = emptyenv())
drm_julia_bridge_summary_env$ran <- 0L
drm_julia_bridge_summary_env$skipped <- 0L

drm_julia_bridge_summary_reset <- function() {
  drm_julia_bridge_summary_env$ran <- 0L
  drm_julia_bridge_summary_env$skipped <- 0L
  invisible(NULL)
}

drm_julia_bridge_summary_record_skip <- function() {
  drm_julia_bridge_summary_env$skipped <- drm_julia_bridge_summary_env$skipped + 1L
  invisible(NULL)
}

drm_julia_bridge_summary_record_live <- function() {
  drm_julia_bridge_summary_env$ran <- drm_julia_bridge_summary_env$ran + 1L
  invisible(NULL)
}

drm_julia_bridge_summary_line <- function() {
  ran <- drm_julia_bridge_summary_env$ran
  skipped <- drm_julia_bridge_summary_env$skipped
  if (ran > 0L) {
    ran_part <- sprintf(
      "%d live test%s ran", ran, if (ran == 1L) "" else "s"
    )
    if (skipped > 0L) {
      sprintf(
        "Julia bridge: %s, %d skipped; bridge glue was exercised in this configuration.",
        ran_part, skipped
      )
    } else {
      sprintf(
        "Julia bridge: %s; bridge glue was exercised in this configuration.",
        ran_part
      )
    }
  } else {
    sprintf(
      "Julia bridge: %d live test%s skipped; bridge glue is UNTESTED in this configuration.",
      skipped, if (skipped == 1L) "" else "s"
    )
  }
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
#
# Every call is recorded into drm_julia_bridge_summary_env (issue #1081
# option 1) so a green run can state whether the bridge glue ran or was
# skipped, instead of a silent mock-only pass.
drm_skip_live_julia <- function() {
  proceed <- tryCatch(
    {
      .drm_skip_live_julia_impl()
      TRUE
    },
    skip = function(cnd) {
      drm_julia_bridge_summary_record_skip()
      stop(cnd)
    }
  )
  if (isTRUE(proceed)) {
    drm_julia_bridge_summary_record_live()
  }
  invisible(proceed)
}

.drm_skip_live_julia_impl <- function() {
  if (identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true")) {
    return(invisible(TRUE))
  }
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
