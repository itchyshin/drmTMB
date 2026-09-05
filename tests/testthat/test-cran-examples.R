cran_example_lines <- function(path) {
  rd <- tools::parse_Rd(testthat::test_path("..", "..", path))
  examples <- Filter(
    function(node) identical(attr(node, "Rd_tag"), "\\examples"),
    rd
  )
  stopifnot(length(examples) == 1L)
  strsplit(
    paste0(unlist(examples[[1L]], use.names = FALSE), collapse = ""),
    "\n",
    fixed = TRUE
  )[[1L]]
}

test_that("reviewed CRAN examples contain no commented-out code", {
  for (path in c("man/confint.drmTMB.Rd", "man/corpairs.Rd")) {
    examples <- cran_example_lines(path)
    expect_false(
      any(grepl("^\\s*#", examples)),
      info = path
    )
  }
})

test_that("meta_vcov_bivariate remains part of the public API", {
  namespace <- readLines(
    testthat::test_path("..", "..", "NAMESPACE"),
    warn = FALSE
  )
  expect_true("export(meta_vcov_bivariate)" %in% namespace)
  expect_true("meta_vcov_bivariate" %in% getNamespaceExports("drmTMB"))
})

test_that("package examples do not use dontrun", {
  package_root <- testthat::test_path("..", "..")
  example_sources <- c(
    list.files(file.path(package_root, "R"), pattern = "[.]R$", full.names = TRUE),
    list.files(file.path(package_root, "man"), pattern = "[.]Rd$", full.names = TRUE)
  )
  dontrun_lines <- unlist(lapply(example_sources, function(path) {
    lines <- readLines(path, warn = FALSE)
    sprintf("%s:%d", path, grep("\\\\dontrun\\{", lines))
  }))
  expect_length(dontrun_lines, 0L)
})
