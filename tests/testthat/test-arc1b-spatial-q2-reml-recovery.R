source_arc1b_recovery_runner <- function(env = parent.frame()) {
  source(
    testthat::test_path(
      "..", "..", "tools", "run-arc1b-spatial-q2-reml-recovery.R"
    ),
    local = env
  )
}

test_that("Arc 1b-S1 recovery runner retains every attempted fit", {
  skip_on_cran()
  source_arc1b_recovery_runner()
  out_dir <- withr::local_tempdir()
  result <- run_arc1b_recovery(list(
    n_rep = 1L,
    cores = 1L,
    master_seed = 2026071403L,
    out_dir = out_dir
  ))

  expect_equal(nrow(result$grid), 6L)
  expect_equal(nrow(result$raw), 6L)
  expect_equal(nrow(result$summary), 18L)
  expect_equal(sum(result$raw$fit_success), 6L)
  expect_true(all(result$raw$convergence == 0L))
  expect_setequal(
    result$summary$parameter,
    c("spatial_sd1", "spatial_sd2", "spatial_cor")
  )
  expect_true(all(result$summary$attempted == 1L))
  expect_true(all(file.exists(file.path(
    out_dir,
    c("design.tsv", "raw-attempts.tsv", "summary.tsv", "session-info.txt")
  ))))
})

test_that("Arc 1b-S1 recovery CLI enforces its worker cap", {
  source_arc1b_recovery_runner()
  expect_error(parse_arc1b_args("--cores=51"), "must be <= 50")
  expect_error(parse_arc1b_args("--unknown=yes"), "Unknown argument")
})
