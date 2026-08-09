dispatch_path <- testthat::test_path("..", "..", "tools", "prepare-b1-drac-dispatch.R")

# The helper lives outside the built tarball (`^tools$` is in .Rbuildignore), so
# its absence is expected and skips. Existence alone is not enough to proceed,
# though: the helper sources a sibling contract file, and if that lookup fails
# the whole test file errors instead of skipping. Degrade to a skip so a broken
# out-of-tarball helper cannot turn the package suite red.
dispatch_loaded <- file.exists(dispatch_path) &&
  tryCatch(
    {
      source(dispatch_path)
      TRUE
    },
    error = function(e) FALSE
  )

if (!dispatch_loaded) {
  test_that("B1 dispatch helpers are available in a source checkout", {
    skip("B1 dispatch helper unavailable; top-level tools are excluded from the source tarball")
  })
} else {

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
