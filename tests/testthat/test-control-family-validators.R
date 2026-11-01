# Characterisation tests for small pure-R validators in R/control.R,
# R/family.R and R/julia-bridge.R. No Julia install is needed.

test_that("drm_control_flag() accepts a single TRUE/FALSE and names the setting", {
  f <- drmTMB:::drm_control_flag
  expect_true(f(TRUE, "se"))
  expect_false(f(FALSE, "se"))
  expect_error(f(NA, "keep_data"), "keep_data")
  expect_error(f(NULL, "keep_data"), "keep_data")
  expect_error(f(c(TRUE, FALSE), "sparse_fixed"), "sparse_fixed")
  expect_error(f("TRUE", "se_group_sd"), "se_group_sd")
  expect_error(f(NA, "se"), "TRUE.*FALSE")
})

test_that("drm_control_validate_start() handles empty and malformed input", {
  f <- drmTMB:::drm_control_validate_start
  expect_null(f(NULL))
  expect_identical(f(list()), list())
  expect_error(f(data.frame(a = 1)), "named list")
  expect_error(f(1), "named list")
  expect_error(f(c(a = 1)), "named list")
  label_msg <- "must name every element with a public start label"
  expect_error(f(list(1)), label_msg)
  expect_error(f(list(a = 1, 2)), label_msg)
  expect_error(f(stats::setNames(list(1), NA_character_)), label_msg)
  expect_error(f(stats::setNames(list(1, 2), c("a", ""))), label_msg)
})

test_that("drm_control_validate_start() requires single finite numeric values", {
  f <- drmTMB:::drm_control_validate_start
  ok <- list(`fixef:mu:(Intercept)` = 0.5, `fixef:sigma:(Intercept)` = 2L)
  expect_identical(f(ok), ok)
  msg <- "single finite numbers"
  expect_error(f(list(a = c(1, 2))), msg)
  expect_error(f(list(a = NA_real_)), msg)
  expect_error(f(list(a = Inf)), msg)
  expect_error(f(list(a = -Inf)), msg)
  expect_error(f(list(a = NaN)), msg)
  expect_error(f(list(a = "1")), msg)
  expect_error(f(list(a = NULL)), msg)
  expect_error(f(list(a = TRUE)), msg)
  expect_error(f(list(a = numeric(0))), msg)
  # The offending label is named.
  expect_error(f(list(good = 1, bad = NA_real_)), "bad")
})

test_that("drm_control_reserved_names() tracks drm_control() formals", {
  nms <- drmTMB:::drm_control_reserved_names()
  expect_type(nms, "character")
  expect_false(anyDuplicated(nms) > 0L)
  expect_false("optimizer" %in% nms)
  expect_true(all(setdiff(names(formals(drmTMB::drm_control)), "optimizer") %in% nms))
  expect_true(all(
    c("starts", "start_from", "warm_start", "map", "fixed", "multistart") %in% nms
  ))
})

test_that("drm_family_call_parts() decomposes beta and namespaced calls", {
  f <- drmTMB:::drm_family_call_parts
  expect_identical(f(quote(beta)), list(pkg = NULL, name = "beta"))
  expect_identical(
    f(quote(stats::binomial)),
    list(pkg = "stats", name = "binomial", ns_op = "::")
  )
  expect_identical(
    f(quote(drmTMB:::beta)),
    list(pkg = "drmTMB", name = "beta", ns_op = ":::")
  )
  # Fallback: anything else is NULL.
  expect_null(f(quote(gaussian)))
  expect_null(f(quote(f(x))))
  expect_null(f(quote(a$b)))
  expect_null(f(NULL))
  expect_null(f("beta"))
})

test_that("beta-call detectors follow the documented truth table", {
  bare <- drmTMB:::drm_is_bare_euler_beta_call
  unexp <- drmTMB:::drm_is_unexported_drmtmb_beta_call

  expect_true(bare(quote(beta())))
  expect_true(bare(quote(base::beta())))
  expect_true(bare(quote(stats::beta())))
  expect_false(bare(quote(drmTMB:::beta())))
  expect_false(bare(quote(drmTMB::beta())))
  expect_false(bare(quote(other::beta())))
  expect_false(bare(quote(gaussian())))
  expect_false(bare(quote(beta)))

  expect_false(unexp(quote(beta())))
  expect_false(unexp(quote(base::beta())))
  expect_false(unexp(quote(drmTMB:::beta())))
  expect_true(unexp(quote(drmTMB::beta())))
  expect_false(unexp(quote(drmTMB::gaussian())))
  expect_false(unexp(quote(beta)))

  # Calls with any argument (including `...`) are not matched by either.
  expect_false(bare(quote(beta(...))))
  expect_false(bare(quote(base::beta(1, 2))))
  expect_false(unexp(quote(drmTMB::beta(...))))
})

test_that("drm_julia_supported_algorithms() lists the DRM.jl solvers", {
  expect_identical(
    drmTMB:::drm_julia_supported_algorithms(),
    c("auto", "gls", "lbfgs", "em", "sparse", "sparse_lbfgs")
  )
})

test_that("drm_julia_validate_g_tol() accepts one positive number", {
  f <- drmTMB:::drm_julia_validate_g_tol
  expect_identical(f(1e-8), 1e-8)
  expect_identical(f(1L), 1)
  expect_type(f(1L), "double")
  for (bad in list(0, -1, NA, NA_real_, Inf, c(1, 2), "a", NULL)) {
    expect_error(f(bad), "single positive number")
  }
})

test_that("drm_julia_validate_algorithm() accepts only supported solvers", {
  f <- drmTMB:::drm_julia_validate_algorithm
  for (alg in drmTMB:::drm_julia_supported_algorithms()) {
    expect_identical(f(alg), alg)
  }
  for (bad in list("nope", NA, NA_character_, c("gls", "em"), 1, NULL)) {
    expect_error(f(bad), "must be one of")
  }
  expect_error(f("nope"), "sparse_lbfgs")
  expect_error(f("nope"), "nope")
})
