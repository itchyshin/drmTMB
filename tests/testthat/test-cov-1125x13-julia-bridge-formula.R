# R/julia-bridge.R formula probes not covered by label-splitting shards.

test_that("drm_julia_formula_has_dpar() reads bf() entries", {
  f <- drmTMB:::drm_julia_formula_has_dpar
  form <- bf(y ~ x, sigma ~ 1, hu ~ 1)
  expect_true(f(form, "mu"))
  expect_true(f(form, "sigma"))
  expect_true(f(form, "hu"))
  expect_false(f(form, "zi"))
  expect_false(f(form, "nu"))
  empty <- structure(list(entries = list()), class = "drm_formula")
  expect_false(f(empty, "mu"))
  bad <- structure(list(entries = "nope"), class = "drm_formula")
  expect_false(f(bad, "mu"))
})

test_that("drm_julia_has_phylo_term() detects phylo markers on means", {
  f <- drmTMB:::drm_julia_has_phylo_term
  skip_if_not_installed("ape")
  tree <- ape::stree(4, type = "balanced")
  dat <- data.frame(
    y = rnorm(8),
    id = rep(tree$tip.label, each = 2)
  )
  with_phylo <- bf(y ~ phylo(1 | id, tree = tree))
  without <- bf(y ~ 1)
  expect_true(f(with_phylo))
  expect_false(f(without))
})

test_that("drm_julia_has_sigma_phylo_term() only inspects sigma formulas", {
  f <- drmTMB:::drm_julia_has_sigma_phylo_term
  skip_if_not_installed("ape")
  tree <- ape::stree(4, type = "balanced")
  on_sigma <- bf(y ~ 1, sigma ~ phylo(1 | id, tree = tree))
  on_mu <- bf(y ~ phylo(1 | id, tree = tree), sigma ~ 1)
  expect_true(f(on_sigma))
  expect_false(f(on_mu))
})

test_that("drm_julia_family_tag() admits FE families and refuses unknown tags", {
  f <- drmTMB:::drm_julia_family_tag
  expect_identical(f("gamma", has_phylo = TRUE), "gamma")
  expect_identical(f("gaussian", has_phylo = FALSE), "gaussian")
  expect_identical(f("poisson", has_phylo = TRUE), "poisson")
  expect_identical(f("biv_gaussian", FALSE), "biv_gaussian")
  expect_error(f("definitely_not_a_drm_family"), "engine")
})

test_that("drm_julia_dpar_has_ordinary_bar() finds random-effect bars", {
  f <- drmTMB:::drm_julia_dpar_has_ordinary_bar
  form <- bf(y ~ x + (1 | id), sigma ~ 1)
  expect_true(f(form, "mu"))
  expect_false(f(form, "sigma"))
  plain <- bf(y ~ x, sigma ~ 1)
  expect_false(f(plain, "mu"))
})