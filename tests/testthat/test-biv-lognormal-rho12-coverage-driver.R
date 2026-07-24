test_that("direct lognormal rho12 coverage driver retains outer and bootstrap attempts", {
  skip_if_not_installed("drmTMB")
  driver <- test_path("..", "..", "inst", "sim", "run", "sim_run_biv_lognormal_rho12_coverage.R")
  skip_if_not(
    file.exists(driver),
    "The source-only coverage driver is unavailable in an installed-package check."
  )
  outdir <- tempfile("biv-lognormal-rho12-coverage-")
  old <- Sys.getenv(c("OUTDIR", "SMOKE", "NCORES", "BOOTSTRAP_R", "QUIET"), unset = NA_character_)
  on.exit({
    for (name in names(old)) {
      if (is.na(old[[name]])) Sys.unsetenv(name) else Sys.setenv(structure(old[[name]], names = name))
    }
  }, add = TRUE)
  Sys.setenv(OUTDIR = outdir, SMOKE = "true", NCORES = "1", BOOTSTRAP_R = "9", QUIET = "true")
  source(driver)

  outer <- utils::read.csv(file.path(outdir, "direct-biv-lognormal-rho12-attempts.csv"))
  bootstrap <- utils::read.csv(file.path(outdir, "direct-biv-lognormal-rho12-bootstrap-attempts.csv"))
  summary <- utils::read.csv(file.path(outdir, "direct-biv-lognormal-rho12-summary.csv"))
  expect_equal(nrow(outer), 9L)
  expect_equal(nrow(bootstrap), 81L)
  expect_equal(nrow(summary), 27L)
  expect_true(all(c("coverage_conditional", "coverage_all_attempts", "point_rmse") %in% names(summary)))
  expect_true(all(c("outer_seed", "refit_status", "draw_used") %in% names(bootstrap)))
})
