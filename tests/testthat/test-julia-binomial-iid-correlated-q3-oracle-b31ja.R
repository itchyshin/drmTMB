# Batch 31 (group ja) independent-oracle companion for the live Julia Binomial
# ordinary (1 + x1 + x2 | id) correlated q3 logit block with an sd() formula
# on each of the three coefficients. Covers the 3 ledger rows
# iid_correlated_block "O-multi-within-q3-anchor" (mu:I, mu:x1, mu:x2; one fit).
# The existing test (test-julia-binomial-correlated-q3-logit-sd-bridge.R)
# compares Julia with native TMB at loose tolerance, with palindromic block
# selectors and no independent oracle or emulated-bug sensitivity.
#
# Julia integrates each group's 3-dimensional random effect with adaptive
# Gauss-Hermite quadrature (5 nodes per axis, 125 nodes), not a Laplace
# approximation, so the oracle is an independent base-R per-group adaptive
# Gauss-Hermite (helper-b31ja-oracle.R) with the same 5 nodes per axis,
# evaluated at the Julia estimates with SD vectors built by hand from the fitted
# coefficients (random, non-palindromic per-group selectors) and R parsed by
# coefficient name from the fitted cor(a,b | id). Julia's logLik must agree to
# 1e-3 absolute; each emulated bug (SD coefficient sets rotated one position,
# reversed SD vector for each coefficient, flipped first correlation,
# R = identity) must move the oracle by more than 20 times that.
# Run time: a cold live q = 3 Julia fit needs about 6 minutes of compilation,
# so this file takes longer than the 2-minute target of the other files.
# Scope: one fixture; no calibration, coverage or broad parity claim.

test_that("Julia Binomial iid correlated q3 logit block matches a per-group adaptive Gauss-Hermite oracle and every emulated bug moves it far", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  b31ja_expect_link_terms()
  b31ja_iid_check(3L, "logit", seed = 20261140L, groups = 100L, repeats = 24L)
})
