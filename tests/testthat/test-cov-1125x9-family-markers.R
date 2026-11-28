# Public family constructors in R/family.R and formula markers in R/formula-markers.R.

test_that("bivariate family constructors expose dpars vectors and links", {
  bvg <- biv_gaussian()
  expect_s3_class(bvg, "drm_family")
  expect_true("mu1" %in% bvg$dpars)
  expect_true("rho12" %in% bvg$dpars)
  expect_identical(bvg$links[["sigma1"]], "log")
  bln <- biv_lognormal()
  expect_identical(bln$family, "biv_lognormal")
  expect_equal(bln$n_response, 2L)
  bst <- biv_student()
  expect_true("nu" %in% bst$dpars)
  expect_identical(bst$links[["nu"]], "logm2")
})

test_that("univariate family constructors retain sigma naming", {
  fams <- list(
    student(), skew_normal(), lognormal(), tweedie(),
    beta_family(), zero_one_beta(), beta_binomial(),
    nbinom2(), truncated_nbinom2(), cumulative_logit()
  )
  for (fam in fams) {
    expect_s3_class(fam, "drm_family")
    expect_true("mu" %in% fam$dpars)
    if ("sigma" %in% fam$dpars) {
      expect_identical(fam$links[["sigma"]], "log")
    }
  }
})

test_that("drm_family_call_parts() and drm_eval_family_arg() round-trip simple calls", {
  env <- new.env(parent = emptyenv())
  env$student <- student
  env$nbinom2 <- nbinom2
  expect_null(drmTMB:::drm_family_call_parts(quote(student)))
  beta_parts <- drmTMB:::drm_family_call_parts(quote(beta))
  expect_identical(beta_parts$name, "beta")
  ns_call <- quote(drmTMB::student())
  ns_parts <- drmTMB:::drm_family_call_parts(ns_call[[1L]])
  expect_identical(ns_parts$name, "student")
  expect_identical(ns_parts$pkg, "drmTMB")
  expect_identical(
    drmTMB:::drm_eval_family_arg(quote(student()), env),
    student()
  )
  expect_identical(
    drmTMB:::drm_eval_family_arg(quote(nbinom2()), env)$family,
    "nbinom2"
  )
})

test_that("meta_V() and mi() markers behave as documented", {
  expect_null(meta_V(V = 1:3))
  df <- data.frame(y = 1:3, x = c(NA, 1, 2))
  expect_equal(mi(df$x)[2], 1)
  expect_warning(drmTMB:::warn_meta_known_v_deprecated(), "deprecated")
})

test_that("beta alias matches beta_family structure", {
  suppressWarnings({
    expect_identical(beta()$family, beta_family()$family)
    expect_identical(beta()$dpars, beta_family()$dpars)
  })
})