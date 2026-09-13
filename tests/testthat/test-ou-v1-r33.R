test_that("R3.3 contract has independent target, proposal, and ESS gates", {
  p <- testthat::test_path("..", "..", "tools", "run-phylo-ou-r33-importance-reference.R"); x <- paste(readLines(p, warn = FALSE), collapse = "\n")
  expect_match(x, "logtarget <- function")
  expect_match(x, "optim\\(rep\\(0, 6\\)")
  expect_match(x, "min_ess")
})
