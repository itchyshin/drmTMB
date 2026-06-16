# Muffle only the drmTMB fit-time convergence warning
# (class "drmTMB_convergence_warning"), letting every other warning surface.
# Used in tests that deliberately fit non-converging or marginal fixtures where
# convergence is not what the test asserts. It is a no-op when the fit converges,
# so it stays platform-independent (the nlminb code can differ across BLAS paths).
allow_nonconvergence <- function(expr) {
  withCallingHandlers(
    expr,
    drmTMB_convergence_warning = function(w) invokeRestart("muffleWarning")
  )
}
