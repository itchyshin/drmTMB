# #1653 — explicit S3 usage on associate_pairs() so roxygen2 stays stable when
# Matrix (or other packages) alter the inferred update() signature.

test_that("associate_pairs pins update() usage in roxygen (#1653)", {
  text <- readLines(drm_pkg_path("R/associate-pairs.R"), warn = FALSE)
  expect_true(any(grepl("^#' @usage$", text)))
  expect_true(any(grepl("associate_pairs\\(fit_1, fit_2, kernel, association\\)", text)))
  expect_true(any(grepl("\\\\method\\{update\\}\\{drm_pair_association\\}", text)))
})