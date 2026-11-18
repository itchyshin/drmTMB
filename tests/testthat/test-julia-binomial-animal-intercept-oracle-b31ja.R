# Batch 31 (group ja) independent-oracle companion for the live Julia Binomial
# animal(1 | id) structured random intercept with sd(id, level = "animal") ~ z.
# Covers the 6 ledger rows animal_intercept x {A covariance, Ainv precision} x
# {logit, probit, cloglog} (mu:I). The existing tests
# (test-julia-binomial-animal-sd-regression.R, -animal-A-nonlogit-sd-bridge.R,
# -animal-ainv-nonlogit-sd-bridge.R) compare Julia with native TMB at loose
# tolerances and have no independent oracle or emulated-bug sensitivity.
#
# The base-R dense joint-Newton Laplace oracle (helper-b31ja-oracle.R) uses a
# Henderson tabular A built by hand from an inbred pedigree (diag(A) from 1.25
# to 1.67, row order different from the factor level order), the SD vector built
# by hand from the fitted coefficients with a random non-palindromic selector,
# and hand-derived observed Bernoulli derivatives. Julia's logLik must agree
# with it at the Julia estimates to 1e-3 absolute; every emulated bug (flipped
# selector slope, reversed SD vector, A * 2, A * 1.3, cov2cor(A) with a
# non-constant diagonal, A read by position, reversed dimnames, intercept read
# as a slope) must move the oracle by more than 20 times that.
# Scope: one fixture per route; no calibration, coverage or broad parity claim.

test_that("Julia Binomial animal intercept (A, Ainv; logit, probit, cloglog) matches a dense Laplace oracle and every emulated bug moves it far", {
  skip_on_cran()
  skip_if_not_installed("JuliaCall")
  drm_skip_live_julia()
  jl_path <- drm_test_drmjl_path("DRM_JL_PATH")
  skip_if(!nzchar(jl_path) || !dir.exists(jl_path),
          "DRM_JL_PATH not available")
  drm_test_local_drmjl_path(jl_path)
  drm_test_local_julia_home()

  b31ja_expect_link_terms()
  links <- c("logit", "probit", "cloglog")
  for (i in seq_along(links)) {
    for (provider in c("A", "Ainv")) {
      b31ja_single_check(
        provider, links[[i]], slope = FALSE,
        seed = 20261110L + i, tag = paste("intercept", provider, links[[i]]),
        check_max = identical(c(provider, links[[i]]), c("A", "logit"))
      )
    }
  }
})
