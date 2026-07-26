test_that("A1 interval accounting preserves paired and failed-interval semantics", {
  helper <- testthat::test_path(
    "..", "..", "docs", "dev-log", "simulation-artifacts",
    "2026-07-26-a1-r999-bootstrap-diagnosis", "a1_profile_common.R"
  )
  if (!file.exists(helper)) {
    skip("Developer-only campaign artifact is unavailable outside a source checkout")
  }
  source(helper, local = TRUE)

  paired <- a1_paired_difference(
    c(FALSE, FALSE, TRUE, TRUE),
    c(FALSE, TRUE, FALSE, TRUE)
  )
  expect_equal(paired$difference, 0)
  expect_equal(paired$r199_only, 1)
  expect_equal(paired$r999_only, 1)
  expect_match(paired$ci_method, "paired normal")

  coverage <- a1_exact_binomial(c(TRUE, NA, FALSE))
  expect_equal(coverage$n, 3)
  expect_equal(coverage$n_valid_interval, 2)
  expect_equal(coverage$n_unavailable_interval, 1)
  expect_equal(coverage$coverage, 1 / 3)

  old <- data.frame(cell_id = rep(c("c01", "c03"), each = 2), seed = 1:4, R_boot = 199)
  new <- transform(old, R_boot = 999)
  expect_invisible(a1_validate_r999_inputs(old, new, c(c01 = 2L, c03 = 2L)))
  expect_error(
    a1_validate_r999_inputs(rbind(old, old[1, ]), new, c(c01 = 2L, c03 = 2L)),
    "Duplicate"
  )

  ci <- data.frame(
    parm = "sd:mu:(1 | g)", lower = 0, upper = 0.9,
    profile.engine = "endpoint", profile.boundary = TRUE,
    conf.status = "profile", profile.message = "ok"
  )
  row <- a1_interval_row(ci, "sd:mu:(1 | g)", 0.5, "profile")
  expect_identical(row$status, "valid")
  expect_true(row$covers)
  expect_true(row$profile_boundary)
  expect_identical(row$profile_engine, "endpoint")

  failed <- a1_interval_row(structure("boom", class = "try-error"),
                            "sd:mu:(1 | g)", 0.5, "profile")
  expect_identical(failed$status, "error")
  expect_true(is.na(failed$covers))
})
