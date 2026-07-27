dispatch_path <- testthat::test_path("..", "..", "tools", "prepare-b1-drac-dispatch.R")

if (!file.exists(dispatch_path)) {
  test_that("B1 dispatch helpers are available in a source checkout", {
    skip("Top-level tools are intentionally excluded from the source tarball")
  })
} else {
  source(dispatch_path)

  test_that("B1 partition plan preserves all immutable tasks and the cap", {
    manifest <- b1_make_full_manifest()
    plan <- b1_dispatch_partition(manifest, max_array_size = 500L, concurrency = 1000L)
    expect_equal(sum(vapply(plan$parts, nrow, integer(1L))), 960L)
    expect_equal(sum(plan$plan$concurrency_cap), 1000L)
    expect_true(all(plan$plan$n_tasks <= 500L))
  })

  test_that("B1 dispatch refuses a throttle above the approved maximum", {
    expect_error(b1_dispatch_partition(b1_make_full_manifest(), 1000L, 1001L), "integer in range")
  })
}
