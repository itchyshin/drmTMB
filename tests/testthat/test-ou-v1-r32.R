test_that("R3.2 runner retains a fixed four-cell rate-amplitude grid", {
  path <- testthat::test_path("..", "..", "tools", "run-phylo-ou-r32-relative-profile.R")
  txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
  expect_match(txt, "rate <- list\\(interior = c\\(.7, 1.3\\), ridge = c\\(8, 8\\)\\)")
  expect_match(txt, "amp <- list\\(interior = c\\(.45, .25\\), ridge = c\\(.19, .057\\)\\)")
  expect_match(txt, "quadrature_rank")
})
