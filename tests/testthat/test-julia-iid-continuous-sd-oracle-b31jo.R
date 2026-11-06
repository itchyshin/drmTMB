# Batch 31 (group jo): live Julia (engine = "julia") ordinary iid-group
# predictor-dependent-SD routes for Beta, Gamma, Gaussian, lognormal and
# ZeroOneBeta (mean random intercept and independent mean random slope), each
# compared with an independent base-R oracle evaluated at the Julia estimates.
# Oracle: exact Gaussian marginal (Gaussian), otherwise the exact one-dimensional
# integral per group (fine trapezoid grid), with all densities written by hand
# (helper-b31jo-oracle.R). Agreement asserted to 1e-3 absolute on the logLik;
# every emulated bug (swapped/sign-flipped/dropped selector coefficients,
# reversed per-level SD vector on a non-palindromic predictor, SD times 2,
# slope SD applied to the intercept field) must move the oracle by more than 0.1
# (more than 100 times the agreement tolerance).
# Claim scope: one fixed draw per route; no calibration, coverage or broad parity.

for (route in list(c("beta", "intercept"), c("beta", "slope"),
                   c("gamma", "intercept"), c("gamma", "slope"),
                   c("gaussian", "intercept"), c("gaussian", "slope"),
                   c("lognormal", "intercept"), c("lognormal", "slope"),
                   c("zero_one_beta", "intercept"), c("zero_one_beta", "slope"))) {
  local({
    fam <- route[[1L]]; kind <- route[[2L]]
    test_that(paste("Julia", fam, "iid", kind, "SD matches the independent oracle"), {
      b31jo_skip_unless_live_julia()
      b31jo_expect_iid_route(fam, kind)
    })
  })
}
