# Batch 31 (group ja) independent-oracle companion for the live Julia Binomial
# animal(0 + x | id) structured random numeric slope with
# sd(id, level = "animal") ~ z. Covers the 5 ledger rows animal_numeric_slope:
# A covariance (probit, cloglog) and Ainv precision (logit, probit, cloglog).
# The existing tests (test-julia-binomial-animal-slope-A-nonlogit-sd-bridge.R,
# -slope-Ainv-logit-sd-bridge.R, -nonlogit-structured-sd-bridge.R) compare
# Julia with native TMB at loose tolerances and have no independent oracle or
# emulated-bug sensitivity.
#
# The base-R dense joint-Newton Laplace oracle (helper-b31ja-oracle.R) uses a
# hand-built Henderson tabular A from an inbred pedigree (diag(A) from 1.25 to
# 1.67, row order different from the factor level order), the per-animal SD
# vector built by hand from the fitted coefficients with a random
# non-palindromic selector, eta = b0 + b1 x + x S_i u_i, and hand-derived
# observed Bernoulli derivatives. Julia's logLik must agree to 1e-3 absolute;
# every emulated bug (flipped selector slope, reversed SD vector, A * 2,
# A * 1.3, cov2cor(A), A read by position, reversed dimnames, slope read as an
# intercept) must move the oracle by more than 20 times that.
# Scope: one fixture per route; no calibration, coverage or broad parity claim.

test_that("Julia Binomial animal numeric slope (A, Ainv) matches a dense Laplace oracle and every emulated bug moves it far", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  b31ja_expect_link_terms()
  cases <- list(c("A", "probit"), c("A", "cloglog"), c("Ainv", "logit"),
                c("Ainv", "probit"), c("Ainv", "cloglog"))
  for (i in seq_along(cases)) {
    b31ja_single_check(
      cases[[i]][[1L]], cases[[i]][[2L]], slope = TRUE,
      seed = 20261120L + i, tag = paste("slope", cases[[i]][[1L]], cases[[i]][[2L]]),
      check_max = i == 1L
    )
  }
})
