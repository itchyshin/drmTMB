# Drift guard for the fitted-family missing-response inventory.
#
# `drm_missing_response_families()` is the single source of truth for which families
# have validated missing-response ("include") support. Before MR-T7, the second test
# looped only over unvalidated candidates and therefore became an empty test once all
# fitted base families were admitted. It now asserts the completed inventory directly;
# route-specific files remain responsible for their G2/G3 evidence and neighbouring
# rejections, including the three count-mixture aliases.

drm_missing_gate_candidates <- function() {
  list(
    poisson           = poisson(),
    binomial          = binomial(),
    nbinom2           = nbinom2(),
    beta              = beta(),
    gamma             = Gamma(link = "log"),
    student           = student(),
    lognormal         = lognormal(),
    tweedie           = tweedie(),
    zero_one_beta     = zero_one_beta(),
    beta_binomial     = beta_binomial(),
    cumulative_logit  = cumulative_logit(),
    truncated_nbinom2 = truncated_nbinom2(),
    skew_normal       = skew_normal()
  )
}

test_that("drm_missing_response_families() is the response-mask source of truth", {
  expect_setequal(
    drm_missing_response_families(),
    c(
      "gaussian", "biv_gaussian", "student", "skew_normal", "lognormal",
      "gamma", "tweedie", "binomial", "poisson", "nbinom2", "beta",
      "zero_one_beta", "beta_binomial", "cumulative_logit",
      "truncated_nbinom2"
    )
  )
})

test_that("every fitted base-family candidate has validated response masking", {
  validated <- drm_missing_response_families()
  candidates <- drm_missing_gate_candidates()
  candidate_types <- vapply(candidates, drm_family_type, character(1L))

  expect_setequal(candidate_types, setdiff(validated, c("gaussian", "biv_gaussian")))
})
