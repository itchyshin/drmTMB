# Drift guard for missing-response scaffolding (P4a).
#
# `drm_missing_response_families()` is the single source of truth for which families
# have validated missing-response ("include") support. This test asserts that EVERY
# other family rejects `miss_control(response = "include")` with a loud, family-specific
# abort, so the capability matrix cannot silently drift as P1 loosens the gate one family
# at a time. When P1 validates a family it joins `drm_missing_response_families()` and is
# skipped here (its own recovery test then covers it).

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

test_that("drm_missing_response_families() is the single source of truth (gaussian + biv + binomial today)", {
  expect_setequal(
    drm_missing_response_families(),
    c("gaussian", "biv_gaussian", "binomial", "poisson", "nbinom2", "beta")
  )
})

test_that("miss_control(response = 'include') rejects loudly for every non-validated family", {
  dat <- data.frame(y = c(1, 2, NA, 4, 5), x = c(-1, -0.5, 0, 0.5, 1))
  validated <- drm_missing_response_families()

  candidates <- drm_missing_gate_candidates()
  for (nm in names(candidates)) {
    ft <- drm_family_type(candidates[[nm]])
    if (ft %in% validated) next # validated families proceed; covered by their own tests

    expect_error(
      drmTMB(
        bf(y ~ x),
        data = dat,
        family = candidates[[nm]],
        missing = miss_control(response = "include")
      ),
      regexp = "not implemented for the",
      info = paste0("family '", nm, "' (type ", ft, ") must reject response = 'include'")
    )
  }
})
