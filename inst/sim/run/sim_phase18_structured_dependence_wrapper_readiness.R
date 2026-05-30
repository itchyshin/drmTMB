phase18_structured_dependence_wrapper_target_readiness <- function(
  registry = phase18_read_structured_workflow_registry()
) {
  plan <- phase18_structured_dependence_workflow_plan(registry)
  targets <- plan[
    plan$dispatch_status == "needs_wrapper_target" &
      plan$workflow_helper == "structured_dependence_wrapper",
    ,
    drop = FALSE
  ]
  if (nrow(targets) == 0L) {
    return(phase18_empty_structured_dependence_wrapper_target_readiness())
  }

  targets$target_status <-
    phase18_structured_dependence_wrapper_target_status(targets$lane_id)
  targets$required_artifact <-
    phase18_structured_dependence_wrapper_required_artifact(targets$lane_id)
  targets$source_evidence <-
    phase18_structured_dependence_wrapper_source_evidence(targets$lane_id)
  targets$dispatch_mode <- "wrapper_target_not_actions"

  row.names(targets) <- NULL
  targets[c(
    "lane_id",
    "family_group",
    "family_route",
    "dpar",
    "dependence",
    "block_q",
    "admission_status",
    "dispatch_status",
    "target_status",
    "actions_task",
    "workflow_helper",
    "required_artifact",
    "source_evidence",
    "dispatch_mode",
    "audit_focus",
    "next_autonomous_action",
    "supervision_boundary"
  )]
}

phase18_empty_structured_dependence_wrapper_target_readiness <- function() {
  data.frame(
    lane_id = character(),
    family_group = character(),
    family_route = character(),
    dpar = character(),
    dependence = character(),
    block_q = character(),
    admission_status = character(),
    dispatch_status = character(),
    target_status = character(),
    actions_task = character(),
    workflow_helper = character(),
    required_artifact = character(),
    source_evidence = character(),
    dispatch_mode = character(),
    audit_focus = character(),
    next_autonomous_action = character(),
    supervision_boundary = character(),
    stringsAsFactors = FALSE
  )
}

phase18_structured_dependence_wrapper_target_status <- function(lane_id) {
  status <- rep(NA_character_, length(lane_id))
  status[lane_id == "gaussian_spatial_mu_one_slope"] <-
    "grid_writer_available"
  status[
    lane_id %in%
      c(
        "gaussian_phylo_mu_one_slope",
        "gaussian_animal_mu_one_slope",
        "gaussian_relmat_mu_one_slope"
      )
  ] <- "source_test_ready"
  phase18_assert_known_structured_dependence_wrapper_targets(
    status,
    lane_id
  )
  status
}

phase18_structured_dependence_wrapper_required_artifact <- function(lane_id) {
  artifact <- rep(NA_character_, length(lane_id))
  artifact[lane_id == "gaussian_phylo_mu_one_slope"] <-
    "needed:phylo_mu_slope_artifact_writer"
  artifact[lane_id == "gaussian_spatial_mu_one_slope"] <-
    "phase18_write_spatial_mu_slope_grid_outputs()"
  artifact[lane_id == "gaussian_animal_mu_one_slope"] <-
    "needed:animal_mu_slope_artifact_writer"
  artifact[lane_id == "gaussian_relmat_mu_one_slope"] <-
    "needed:relmat_mu_slope_artifact_writer"
  phase18_assert_known_structured_dependence_wrapper_targets(
    artifact,
    lane_id
  )
  artifact
}

phase18_structured_dependence_wrapper_source_evidence <- function(lane_id) {
  evidence <- rep(NA_character_, length(lane_id))
  evidence[lane_id == "gaussian_phylo_mu_one_slope"] <-
    "tests/testthat/test-phylo-gaussian.R"
  evidence[lane_id == "gaussian_spatial_mu_one_slope"] <-
    paste(
      "tests/testthat/test-phase18-spatial-mu-slope.R;",
      "inst/sim/run/sim_write_spatial_mu_slope_grid.R"
    )
  evidence[lane_id == "gaussian_animal_mu_one_slope"] <-
    "tests/testthat/test-animal-relmat-gaussian.R"
  evidence[lane_id == "gaussian_relmat_mu_one_slope"] <-
    "tests/testthat/test-animal-relmat-gaussian.R"
  phase18_assert_known_structured_dependence_wrapper_targets(
    evidence,
    lane_id
  )
  evidence
}

phase18_assert_known_structured_dependence_wrapper_targets <- function(
  values,
  lane_id
) {
  unknown <- is.na(values)
  if (any(unknown)) {
    stop(
      "Structured-dependence wrapper readiness has unknown target rows: ",
      paste(unique(lane_id[unknown]), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  invisible(values)
}
