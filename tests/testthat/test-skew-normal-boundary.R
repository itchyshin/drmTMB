test_that("skew-normal remains design-only until the likelihood lane opens", {
  expect_false(
    exists("skew_normal", envir = asNamespace("drmTMB"), inherits = FALSE)
  )

  source_map <- file.path(
    testthat::test_path("..", ".."),
    "docs",
    "design",
    "123-phase-18-skew-normal-source-map-slices-1519-1538.md"
  )
  testthat::skip_if_not(
    file.exists(source_map),
    "skew-normal source-map design doc is not installed during R CMD check"
  )

  text <- paste(readLines(source_map, warn = FALSE), collapse = "\n")
  expect_match(text, "Planned, not fitted yet", fixed = TRUE)
  expect_match(text, "does not\\s+implement `skew_normal\\(\\)`")
  expect_match(text, "skew\\(id\\) ~ x")
})
