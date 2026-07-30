source_missing_response_g4g5 <- function(env = parent.frame()) {
  path <- system.file("sim/R/sim_missing_response_g4g5.R", package = "drmTMB")
  if (!nzchar(path)) path <- testthat::test_path("..", "..", "inst", "sim", "R", "sim_missing_response_g4g5.R")
  source(path, local = env)
}

test_that("the missing-response manifest freezes all 18 G3 routes", {
  source_missing_response_g4g5()
  manifest <- mr_g4g5_route_manifest()
  expect_silent(mr_g4g5_validate_manifest(manifest))
  expect_equal(nrow(manifest), 18L)
  expect_true("biv_gaussian" %in% manifest$route_id)
  expect_identical(manifest$mask_design[manifest$route_id == "biv_gaussian"], "paired_within_group")
})

test_that("G4 retains failed, clamped, and truth-missing profile attempts", {
  source_missing_response_g4g5()
  ok <- mr_g4_validate_record(data.frame(conf.low = 0.1, conf.high = 0.4, conf.status = "profile", profile.boundary = FALSE, truth = 0.2))
  clamp <- mr_g4_validate_record(data.frame(conf.low = NA_real_, conf.high = NA_real_, conf.status = "clamp_limited", profile.boundary = TRUE, truth = 0.2))
  miss <- mr_g4_validate_record(data.frame(conf.low = 0.1, conf.high = 0.4, conf.status = "profile", profile.boundary = FALSE, truth = 0.8))
  expect_true(ok$g4_pass)
  expect_false(clamp$g4_interval_usable)
  expect_false(miss$g4_pass)
  expect_false(miss$g4_truth_contained)
})
