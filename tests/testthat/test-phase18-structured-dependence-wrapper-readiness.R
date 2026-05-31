phase18_structured_dependence_registry_script <- function() {
  candidates <- c(
    testthat::test_path(
      "..",
      "..",
      "inst",
      "sim",
      "run",
      "sim_phase18_structured_workflow_registry.R"
    ),
    system.file(
      "sim",
      "run",
      "sim_phase18_structured_workflow_registry.R",
      package = "drmTMB"
    )
  )
  candidates <- candidates[nzchar(candidates)]
  candidates <- candidates[file.exists(candidates)]
  testthat::expect_true(
    length(candidates) > 0L,
    info = "Could not find Phase 18 structured workflow registry helper"
  )
  normalizePath(candidates[[1L]], winslash = "/", mustWork = TRUE)
}

phase18_structured_dependence_readiness_script <- function() {
  candidates <- c(
    testthat::test_path(
      "..",
      "..",
      "inst",
      "sim",
      "run",
      "sim_phase18_structured_dependence_wrapper_readiness.R"
    ),
    system.file(
      "sim",
      "run",
      "sim_phase18_structured_dependence_wrapper_readiness.R",
      package = "drmTMB"
    )
  )
  candidates <- candidates[nzchar(candidates)]
  candidates <- candidates[file.exists(candidates)]
  testthat::expect_true(
    length(candidates) > 0L,
    info = "Could not find structured-dependence wrapper readiness helper"
  )
  normalizePath(candidates[[1L]], winslash = "/", mustWork = TRUE)
}

phase18_structured_dependence_registry_csv <- function() {
  candidates <- c(
    testthat::test_path(
      "..",
      "..",
      "inst",
      "sim",
      "registry",
      "phase18_structured_workflow_registry.csv"
    ),
    system.file(
      "sim",
      "registry",
      "phase18_structured_workflow_registry.csv",
      package = "drmTMB"
    )
  )
  candidates <- candidates[nzchar(candidates)]
  candidates <- candidates[file.exists(candidates)]
  testthat::expect_true(
    length(candidates) > 0L,
    info = "Could not find Phase 18 structured workflow registry CSV"
  )
  normalizePath(candidates[[1L]], winslash = "/", mustWork = TRUE)
}

source_phase18_structured_dependence_readiness <- function() {
  env <- new.env(parent = globalenv())
  source(phase18_structured_dependence_registry_script(), local = env)
  source(phase18_structured_dependence_readiness_script(), local = env)
  env
}

test_that("structured-dependence readiness summarizes wrapper targets", {
  env <- source_phase18_structured_dependence_readiness()
  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_dependence_registry_csv()
  )

  readiness <- env$phase18_structured_dependence_wrapper_target_readiness(
    registry
  )
  status_counts <- table(readiness$target_status)

  expect_equal(nrow(readiness), 3L)
  expect_setequal(
    readiness$lane_id,
    c(
      "gaussian_phylo_mu_one_slope",
      "gaussian_animal_mu_one_slope",
      "gaussian_relmat_mu_one_slope"
    )
  )
  expect_equal(unname(status_counts[["source_test_ready"]]), 3L)
  expect_true(all(readiness$dispatch_status == "needs_wrapper_target"))
  expect_true(all(readiness$workflow_helper == "structured_dependence_wrapper"))
  expect_true(all(is.na(readiness$actions_task)))
  expect_true(all(readiness$dispatch_mode == "wrapper_target_not_actions"))
})

test_that("structured-dependence readiness names current artifact gap", {
  env <- source_phase18_structured_dependence_readiness()
  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_dependence_registry_csv()
  )

  readiness <- env$phase18_structured_dependence_wrapper_target_readiness(
    registry
  )

  expect_true(all(startsWith(readiness$required_artifact, "needed:")))
  expect_match(
    readiness$source_evidence[readiness$dependence == "phylo"],
    "test-phylo-gaussian.R",
    fixed = TRUE
  )
})

test_that("structured-dependence readiness fails closed for unknown targets", {
  env <- source_phase18_structured_dependence_readiness()
  registry <- env$phase18_read_structured_workflow_registry(
    path = phase18_structured_dependence_registry_csv()
  )
  extra <- registry[registry$lane_id == "gaussian_phylo_mu_one_slope", ]
  extra$lane_id <- "mock_new_structured_wrapper_target"
  registry <- rbind(registry, extra)

  expect_error(
    env$phase18_structured_dependence_wrapper_target_readiness(registry),
    "unknown target rows",
    fixed = TRUE
  )
})
