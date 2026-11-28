test_that("convergence vignette setup survives R CMD check extraction", {
  vignette <- testthat::test_path("..", "..", "vignettes", "convergence.Rmd")
  skip_if_not(file.exists(vignette), "vignette source is not installed")
  skip_if_not_installed("knitr")

  tangled <- tempfile(fileext = ".R")
  on.exit(unlink(tangled), add = TRUE)
  result <- tryCatch(
    knitr::purl(vignette, output = tangled, quiet = TRUE),
    error = identity
  )

  expect_false(inherits(result, "error"))
  expect_true(file.exists(tangled))
  code <- readLines(tangled, warn = FALSE)
  expect_true(any(grepl("library(drmTMB)", code, fixed = TRUE)))
  expect_true(any(grepl("has_ggplot2 <-", code, fixed = TRUE)))
})
