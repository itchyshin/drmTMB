# Julia simulation guards from R/julia-simulate.R.

test_that("drm_julia_simulation_has_random_terms() detects random effects", {
  f <- drmTMB:::drm_julia_simulation_has_random_terms
  plain <- drm_formula(y ~ x, sigma ~ 1)
  expect_false(f(plain))
  re <- drm_formula(y ~ x + (1 | id), sigma ~ 1)
  expect_true(f(re))
  bad <- list(entries = NULL)
  class(bad) <- "drm_formula"
  expect_false(f(bad))
})

test_that("drm_julia_align_group_sd() keeps aligned numeric values", {
  align <- drmTMB:::drm_julia_align_group_sd
  groups <- c("a", "b", "c")
  val <- c(0.5, 1.2, 0.8)
  out <- align(val, groups = groups, dpar = "sigma", group = "id")
  expect_equal(out, val)
  expect_error(
    align(c(1, -1), groups = c("a", "b"), dpar = "sigma", group = "id"),
    "positive finite"
  )
  named <- c(a = 0.2, b = 0.3)
  expect_equal(
    align(named, groups = c("a", "b"), dpar = "sigma", group = "id"),
    c(0.2, 0.3)
  )
})