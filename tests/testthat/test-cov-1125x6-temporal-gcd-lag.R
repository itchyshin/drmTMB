# Small temporal utilities in R/temporal.R (not HOMTOEP fitting).

test_that("temporal_integer_gcd() reduces positive integers", {
  expect_equal(drmTMB:::temporal_integer_gcd(12L, 8L), 4L)
  expect_equal(drmTMB:::temporal_integer_gcd(7L, 0L), 7L)
  expect_equal(drmTMB:::temporal_integer_gcd(0L, 9L), 9L)
})

test_that("empty_temporal_mu_structure() returns a named empty scaffold", {
  empty <- drmTMB:::empty_temporal_mu_structure()
  expect_type(empty, "list")
  expect_true("has" %in% names(empty))
  expect_false(empty$has)
})

test_that("temporal_lag_witnesses() returns positive lag witnesses", {
  wits <- drmTMB:::temporal_lag_witnesses(c(1, 2, 3, 4, 6))
  expect_type(wits, "double")
  expect_true(all(wits > 0))
  expect_length(drmTMB:::temporal_lag_witnesses(1), 0L)
})

test_that("drm_formula_has_temporal() detects temporal() markers", {
  with_temporal <- bf(y ~ temporal(1 | id, time = t, structure = "ar1"))
  expect_true(drmTMB:::drm_formula_has_temporal(with_temporal))
  expect_false(drmTMB:::drm_formula_has_temporal(bf(y ~ x)))
})

test_that("temporal_structure_name() reads the structured label", {
  term <- bf(y ~ temporal(1 | id, time = t, structure = "ou"))$entries[[1]]$structured[[1]]
  expect_equal(drmTMB:::temporal_structure_name(term), "Temporal OU")
})