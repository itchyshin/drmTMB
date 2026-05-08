test_that("package metadata is available", {
  expect_equal(utils::packageDescription("drmTMB")$Package, "drmTMB")
})

test_that("drm_formula() captures distributional formulas", {
  form <- drm_formula(
    mu1 = y1 ~ x1 + (1 | p | id),
    mu2 = y2 ~ x2 + (1 | p | id),
    sigma1 = ~ x1,
    sigma2 = ~ x2,
    rho12 = ~ x1 + x2
  )

  expect_s3_class(form, "drm_formula")
  expect_equal(names(form$calls), c("mu1", "mu2", "sigma1", "sigma2", "rho12"))
  expect_equal(vapply(form$entries, `[[`, character(1), "dpar"), names(form$calls))
  expect_equal(vapply(form$entries[1:2], `[[`, character(1), "response"), c("y1", "y2"))
  expect_equal(form$entries[[5]]$dpar, "rho12")
})

test_that("bf() remains a short alias for drm_formula()", {
  form <- bf(y ~ x, sigma ~ z)

  expect_s3_class(form, "drm_formula")
  expect_length(form$calls, 2)
  expect_equal(vapply(form$entries, `[[`, character(1), "dpar"), c("mu", "sigma"))
})

test_that("drm_formula() captures meta-analysis and random-effect scale syntax", {
  form <- drm_formula(
    yi ~ moderator + meta_known_V(V = vi),
    sigma ~ moderator,
    sd(study) ~ moderator
  )

  expect_s3_class(form, "drm_formula")
  expect_length(form$calls, 3)
  expect_equal(vapply(form$entries, `[[`, character(1), "dpar"), c("mu", "sigma", "sd(study)"))
  expect_equal(form$entries[[1]]$response, "yi")
  expect_match(deparse1(form$calls[[1]]), "meta_known_V\\(V = vi\\)")
  expect_match(deparse1(form$calls[[3]]), "sd\\(study\\)")
})

test_that("formula markers are no-op placeholders", {
  expect_null(meta_known_V(V = 1))
  expect_null(gr(id, cov = diag(1)))
  expect_null(phylo(species))
  expect_null(spatial(x, y))
})
