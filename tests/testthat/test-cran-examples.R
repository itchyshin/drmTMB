cran_example_lines <- function(path) {
  lines <- readLines(testthat::test_path("..", "..", path), warn = FALSE)
  start <- grep("^\\\\examples\\{$", lines)
  stopifnot(length(start) == 1L)
  end <- which(seq_along(lines) > start & lines == "}")[1L]
  lines[seq.int(start + 1L, end - 1L)]
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
