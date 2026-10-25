test_that("temporal() records an intercept-only AR1 declaration", {
  form <- drm_formula(
    y ~ treatment + temporal(1 | id, time = occasion, structure = "ar1")
  )

  term <- form$entries[[1L]]$structured[[1L]]
  expect_equal(
    term[c("type", "dpar", "group", "time", "structure", "coef_names")],
    list(
      type = "temporal",
      dpar = "mu",
      group = "id",
      time = "occasion",
      structure = "ar1",
      coef_names = "(Intercept)"
    )
  )
  expect_null(term$covariance_label)
})

test_that("temporal() rejects unsupported declarations at parse time", {
  expect_error(
    drm_formula(y ~ temporal(1 + x | id, time = occasion, structure = "ar1")),
    "intercept-only"
  )
  expect_error(
    drm_formula(y ~ temporal(1 | block | id, time = occasion, structure = "ar1")),
    "covariance-block"
  )
  expect_error(
    drm_formula(y ~ temporal(1 | id, structure = "ar1")),
    "time"
  )
  expect_error(
    drm_formula(y ~ temporal(1 | id, time = occasion, structure = "ou")),
    "ar1"
  )
})
