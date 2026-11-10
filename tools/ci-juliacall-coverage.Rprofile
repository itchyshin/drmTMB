# Sourced in every R process started during julia-bridge coverage (covr, callr).
# Do not call JuliaCall::julia_setup() here — drm_julia_setup() must run first
# with install = TRUE on its own disposable project (JuliaCall returns early when
# already initialized, which would skip RCall in that project).
if (identical(Sys.getenv("DRMTMB_JULIA_TESTS"), "true")) {
  Sys.setenv(R_HOME = R.home())
}
