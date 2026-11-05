test_that("nlme extractor methods dispatch in a fresh R process", {
  pkg <- getNamespaceInfo(asNamespace("drmTMB"), "path")
  dev <- pkgload::is_dev_package("drmTMB")
  result <- callr::r(function(pkg, dev) {
    if (dev) {
      suppressMessages(pkgload::load_all(pkg, quiet = TRUE))
    } else {
      loadNamespace("drmTMB", lib.loc = dirname(pkg))
    }
    coefficients <- list(mu = c(`(Intercept)` = 0.25, slope = -0.4))
    fits <- list(
      structure(list(coefficients = coefficients), class = "drmTMB"),
      structure(list(coefficients = coefficients), class = "drmTMB_julia"),
      structure(
        list(coefficients = coefficients, sigma_coef = list()),
        class = "drmTMB_julia_xfam"
      )
    )
    random_effects <- list(mu = list(values = c(group_a = 0.1)))
    list(
      fixef = lapply(fits, drmTMB::fixef),
      ranef = drmTMB::ranef(
        structure(list(random_effects = random_effects), class = "drmTMB")
      )
    )
  }, args = list(pkg = pkg, dev = dev), error = "error")

  expected_coef <- list(mu = c(`(Intercept)` = 0.25, slope = -0.4))
  expected_re <- list(mu = list(values = c(group_a = 0.1)))
  expect_length(result$fixef, 3L)
  expect_true(all(vapply(result$fixef, identical, logical(1), expected_coef)))
  expect_identical(result$ranef, expected_re)
})
