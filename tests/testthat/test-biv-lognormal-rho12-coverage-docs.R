test_that("direct lognormal coverage boundary is synchronized across public design surfaces", {
  paths <- test_path("..", "..", c(
    "docs/design/01-formula-grammar.md",
    "docs/design/02-family-registry.md",
    "docs/design/03-likelihoods.md",
    "docs/dev-log/known-limitations.md",
    "vignettes/distribution-families.Rmd"
  ))
  skip_if_not(
    all(file.exists(paths)),
    "The source-only documentation surfaces are unavailable in an installed-package check."
  )
  text <- vapply(
    paths,
    function(path) paste(readLines(path, warn = FALSE), collapse = "\n"),
    character(1L)
  )
  expect_true(all(grepl("profile (is|as)( the)? primary", text)))
  expect_true(all(grepl("fixed-effect", text, fixed = TRUE)))
  expect_true(all(grepl("rho12", text, fixed = TRUE)))
  expect_false(any(grepl("calibrated comparators", text, fixed = TRUE)))
})
