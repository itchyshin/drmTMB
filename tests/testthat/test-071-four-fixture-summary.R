test_that("four-fixture summary fails closed when a fixture receipt is absent", {
  tool <- testthat::test_path("..", "..", "docs", "dev-log", "evidence",
                              "julia-r-parity", "071-ordinary-laplace",
                              "reconcile-four-fixture-summary.R")
  expect_true(file.exists(tool))
  env <- new.env(parent = globalenv())
  sys.source(tool, envir = env)
  expect_true(is.function(env$r071_reconcile_all))
  empty <- tempfile("071-empty-receipt-")
  dir.create(empty)
  expect_error(
    env$r071_reconcile_all(root = normalizePath(testthat::test_path("..", "..")),
                            drmjl_path = normalizePath(testthat::test_path("..", "..")),
                            out = empty),
    "missing binomial_ri profile receipt"
  )
})

test_that("the scoreboard has a distinct ordinary-Laplace classification path", {
  tool <- testthat::test_path("..", "..", "tools", "write-parity-scoreboard.R")
  env <- new.env(parent = globalenv())
  sys.source(tool, envir = env)
  expect_true(is.function(env$sb_ordinary_laplace_summary))
})
