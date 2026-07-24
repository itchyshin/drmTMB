source_phase18_meta_v_lss_runner <- function(env = parent.frame()) {
  for (path in c(
    "sim/R/sim_registry.R",
    "sim/R/sim_utils.R",
    "sim/R/sim_runner.R",
    "sim/dgp/sim_dgp_meta_v.R",
    "sim/dgp/sim_dgp_meta_v_lss.R",
    "sim/fit/sim_summarise_meta_v_lss.R",
    "sim/run/sim_run_meta_v_lss_smoke.R"
  )) {
    source(system.file(path, package = "drmTMB", mustWork = TRUE), local = env)
  }
}

test_that("Arc 7B smoke registry retains every scheduled layer and attempt", {
  source_phase18_meta_v_lss_runner()
  conditions <- phase18_meta_v_lss_smoke_conditions()
  expect_setequal(unique(conditions$layer), c("LS", "LSS", "LSSS", "DH"))
  expect_true(any(conditions$design_role == "weak_boundary"))
  expect_true(any(conditions$known_v_type == "dense"))
  registry <- phase18_cell_registry("meta_v_lss", conditions, n_rep = 2L, master_seed = 11L)
  expect_equal(nrow(registry$seeds), 2L * nrow(conditions))
})

test_that("Arc 7B all-attempt summary keeps failed fits in its denominator", {
  source_phase18_meta_v_lss_runner()
  conditions <- phase18_meta_v_lss_smoke_conditions()[1L, , drop = FALSE]
  registry <- phase18_cell_registry("meta_v_lss", conditions, n_rep = 1L, master_seed = 12L)
  result <- list(
    cell_id = registry$cells$cell_id[[1L]], replicate = 1L,
    seed = registry$seeds$seed[[1L]], status = "error", warnings = character(),
    error = "deliberate retained failure", elapsed = 0.1, summary = NULL, skipped = FALSE
  )
  out <- phase18_meta_v_lss_all_attempt_summary(list(result), registry$cells, data.frame())
  expect_true(nrow(out) > 0L)
  expect_true(all(out$result_status == "error"))
  expect_true(all(is.na(out$estimate)))
  expect_true(all(out$interval_status[out$profile_eligible] == "outer_fit_failed"))
  reduction <- phase18_meta_v_lss_all_attempt_profile_reduction(out)
  expect_true(all(reduction$attempted == 1L))
  expect_true(all(reduction$usable_and_covering == 0L))
})

test_that("Arc 7B dense LSS sentinel retains incomplete direct-SD profiles", {
  source_phase18_meta_v_lss_runner()
  dense <- phase18_meta_v_lss_smoke_conditions()[5L, , drop = FALSE]
  run <- phase18_run_meta_v_lss_smoke(
    conditions = dense, n_rep = 1L, master_seed = 2026072407L
  )
  expect_equal(run$manifest$status, "ok")
  direct_sd <- run$summary[grepl("^sd:study:", run$summary$parameter), , drop = FALSE]
  expect_equal(nrow(direct_sd), 2L)
  expect_true(all(direct_sd$interval_status == "incomplete"))
  expect_true(all(direct_sd$interval_message == "nonfinite_interval"))
  expect_true(all(direct_sd$result_status == "ok"))
  reduction <- phase18_meta_v_lss_all_attempt_profile_reduction(run$summary)
  direct_sd_reduction <- reduction[grepl("^sd:study:", reduction$parameter), , drop = FALSE]
  expect_true(all(direct_sd_reduction$complete_profile == 0L))
  expect_true(all(direct_sd_reduction$usable_and_covering == 0L))
})
