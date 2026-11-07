# Batch 31 (group ja) independent-oracle companion for the live Julia Binomial
# ordinary (1 + x1 [+ x2] | id) correlated block with an sd() formula on each
# coefficient. Covers 6 ledger rows (iid_correlated_block, q = 2): logit,
# probit, cloglog, targets mu:I and mu:x1 (one fit per link). The q = 3 logit
# anchor is in test-julia-binomial-iid-correlated-q3-oracle-b31ja.R because a
# cold live q = 3 Julia fit needs about 6 minutes of compilation.
# The existing tests (test-julia-binomial-sd.R, -nonlogit-correlated-sd-bridge.R,
# -correlated-q3-logit-sd-bridge.R, and the Julia recovery snapshots) check
# recovery and native parity at loose tolerance; none has an independent oracle
# or emulated-bug sensitivity, and their SD selectors are palindromic block
# patterns.
#
# The Julia route integrates each group with adaptive Gauss-Hermite quadrature
# (5 nodes per axis; Julia's default for this route), not a Laplace
# approximation: a Laplace oracle misses the Julia logLik by roughly 1 on these
# fixtures, which is the 5-node quadrature error. So the oracle is an
# independent base-R per-group adaptive Gauss-Hermite (helper-b31ja-oracle.R,
# Golub-Welsch nodes, own mode and curvature, tensor grid), also with 5 nodes,
# and a 15-node value is reported (not asserted) as the near-exact marginal.
# It is evaluated at the Julia estimates: Sigma_g = diag(S_g) R diag(S_g) with the SD
# vectors built by hand from the fitted coefficients (random, non-palindromic
# per-group selectors) and R parsed by coefficient name from the fitted
# cor(a,b | id). Julia's logLik must agree to 1e-3 absolute; every emulated bug
# (SD coefficient sets rotated one position, reversed SD vector for each
# coefficient, flipped first correlation, R = identity) must move the oracle
# by more than 20 times that.
# Scope: one fixture per route; no calibration, coverage or broad parity claim.

test_that("Julia Binomial iid correlated q2 blocks (logit, probit, cloglog) match a per-group adaptive Gauss-Hermite oracle and every emulated bug moves it far", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  b31ja_expect_link_terms()
  for (i in 1:3) {
    b31ja_iid_check(2L, c("logit", "probit", "cloglog")[[i]],
                    seed = 20261130L + i, groups = 80L, repeats = 24L)
  }
})
