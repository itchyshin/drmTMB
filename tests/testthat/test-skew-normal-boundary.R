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

  test_contract <- file.path(
    testthat::test_path("..", ".."),
    "docs",
    "design",
    "128-phase-18-skew-normal-test-contract-slices-1673-1702.md"
  )
  testthat::skip_if_not(
    file.exists(test_contract),
    "skew-normal test-contract design doc is not installed during R CMD check"
  )

  contract <- paste(readLines(test_contract, warn = FALSE), collapse = "\n")
  expect_match(contract, "Planned, not fitted yet", fixed = TRUE)
  expect_match(contract, "no `skew_normal\\(\\)` constructor is added")
  expect_match(contract, "no-C\\+\\+ admission criteria")
  expect_match(contract, "keeps `rho12` out", fixed = TRUE)
})
