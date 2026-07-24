test_that("direct lognormal coverage boundary is synchronized across public design surfaces", {
  paths <- c(
    "docs/design/01-formula-grammar.md",
    "docs/design/02-family-registry.md",
    "docs/design/03-likelihoods.md",
    "docs/dev-log/known-limitations.md",
    "vignettes/distribution-families.Rmd"
  )
  text <- vapply(
    paths,
    function(path) paste(readLines(path, warn = FALSE), collapse = "\n"),
    character(1L)
  )
  expect_true(all(grepl("profile is primary", text, fixed = TRUE)))
  expect_true(all(grepl("fixed-effect", text, fixed = TRUE)))
  expect_true(all(grepl("rho12", text, fixed = TRUE)))
  expect_false(any(grepl("calibrated comparators", text, fixed = TRUE)))
})
