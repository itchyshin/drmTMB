phase18_structured_workflow_registry_path <- function(
  path = NULL,
  root = NULL,
  package = "drmTMB"
) {
  if (!is.null(path)) {
    return(normalizePath(path, winslash = "/", mustWork = TRUE))
  }

  registry_file <- file.path(
    "sim",
    "registry",
    "phase18_structured_workflow_registry.csv"
  )
  candidates <- character()
  if (!is.null(root)) {
    candidates <- c(
      file.path(root, "inst", registry_file),
      file.path(root, registry_file)
    )
  } else {
    installed <- system.file(registry_file, package = package)
    if (nzchar(installed)) {
      candidates <- c(candidates, installed)
    }
    candidates <- c(
      candidates,
      file.path(getwd(), "inst", registry_file),
      file.path(getwd(), registry_file)
    )
  }

  hit <- candidates[file.exists(candidates)][1L]
  if (is.na(hit)) {
    stop(
      "Could not find Phase 18 structured workflow registry CSV.",
      call. = FALSE
    )
  }
  normalizePath(hit, winslash = "/", mustWork = TRUE)
}

phase18_read_structured_workflow_registry <- function(
  path = phase18_structured_workflow_registry_path(),
  action_tasks = phase18_structured_workflow_actions_tasks()
) {
  registry <- read.csv(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  phase18_validate_structured_workflow_registry(
    registry = registry,
    action_tasks = action_tasks
  )
  registry
}

phase18_validate_structured_workflow_registry <- function(
  registry,
  action_tasks = phase18_structured_workflow_actions_tasks()
) {
  if (!is.data.frame(registry) || nrow(registry) == 0L) {
    stop("`registry` must be a non-empty data frame.", call. = FALSE)
  }

  required <- phase18_structured_workflow_required_columns()
  missing <- setdiff(required, names(registry))
  if (length(missing) > 0L) {
    stop(
      "`registry` is missing required columns: ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  for (column in required) {
    values <- trimws(as.character(registry[[column]]))
    if (any(is.na(values) | !nzchar(values))) {
      stop(
        "`",
        column,
        "` values must be non-empty.",
        call. = FALSE
      )
    }
    registry[[column]] <- values
  }

  if (anyDuplicated(registry$lane_id)) {
    stop("`lane_id` values must be unique.", call. = FALSE)
  }

  phase18_validate_structured_workflow_values(
    values = registry$workflow_lane,
    choices = phase18_structured_workflow_lanes(),
    name = "workflow_lane"
  )
  phase18_validate_structured_workflow_values(
    values = registry$admission_status,
    choices = phase18_structured_workflow_statuses(),
    name = "admission_status"
  )

  task <- registry$existing_actions_task
  known_task <- task %in% c("none", action_tasks) | startsWith(task, "needed:")
  if (any(!known_task)) {
    stop(
      "`existing_actions_task` must be `none`, `needed:<helper>`, ",
      "or a known Phase 18 Actions task. Unknown values: ",
      paste(unique(task[!known_task]), collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  paused <- registry$admission_status %in% c("blocked", "design_only")
  if (any(paused & task != "none")) {
    stop(
      "Rows marked `blocked` or `design_only` must not name an Actions task.",
      call. = FALSE
    )
  }

  invisible(registry)
}

phase18_structured_workflow_registry_summary <- function(
  registry,
  by = c("workflow_lane", "admission_status")
) {
  phase18_validate_structured_workflow_registry(registry)
  missing <- setdiff(by, names(registry))
  if (length(missing) > 0L) {
    stop(
      "`by` contains unknown columns: ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  registry$.n <- 1L
  summary <- aggregate(
    registry[".n"],
    registry[by],
    sum
  )
  names(summary)[names(summary) == ".n"] <- "n"
  summary[do.call(order, summary[by]), , drop = FALSE]
}

phase18_filter_structured_workflow_registry <- function(
  registry,
  workflow_lane = NULL,
  admission_status = NULL,
  dependence = NULL,
  family_group = NULL
) {
  phase18_validate_structured_workflow_registry(registry)
  keep <- rep(TRUE, nrow(registry))
  if (!is.null(workflow_lane)) {
    keep <- keep & registry$workflow_lane %in% workflow_lane
  }
  if (!is.null(admission_status)) {
    keep <- keep & registry$admission_status %in% admission_status
  }
  if (!is.null(dependence)) {
    keep <- keep & registry$dependence %in% dependence
  }
  if (!is.null(family_group)) {
    keep <- keep & registry$family_group %in% family_group
  }
  registry[keep, , drop = FALSE]
}

phase18_admitted_structured_workflow_rows <- function(
  registry,
  workflow_lane = NULL
) {
  phase18_filter_structured_workflow_registry(
    registry = registry,
    workflow_lane = workflow_lane,
    admission_status = phase18_structured_workflow_admitted_statuses()
  )
}

phase18_random_slope_workflow_plan <- function(
  registry = phase18_read_structured_workflow_registry(),
  include_needed = TRUE
) {
  rows <- phase18_admitted_structured_workflow_rows(
    registry = registry,
    workflow_lane = "random_slopes"
  )
  if (!include_needed) {
    rows <- rows[
      !startsWith(rows$existing_actions_task, "needed:"),
      ,
      drop = FALSE
    ]
  }
  if (nrow(rows) == 0L) {
    return(phase18_empty_random_slope_workflow_plan())
  }

  needs_target <- startsWith(rows$existing_actions_task, "needed:")
  plan <- rows[c(
    "lane_id",
    "family_group",
    "family_route",
    "dpar",
    "dependence",
    "block_q",
    "admission_status",
    "existing_actions_task",
    "next_autonomous_action",
    "supervision_boundary"
  )]
  plan$dispatch_status <- ifelse(
    needs_target,
    "needs_wrapper_target",
    ifelse(
      plan$admission_status == "ready_source_test",
      "source_test_audit",
      "ready_existing_task"
    )
  )
  plan$actions_task <- ifelse(
    needs_target,
    NA_character_,
    plan$existing_actions_task
  )
  plan$workflow_helper <- ifelse(
    needs_target,
    sub("^needed:", "", plan$existing_actions_task),
    "phase18_actions_main"
  )
  plan$audit_focus <- phase18_random_slope_audit_focus(
    plan$admission_status
  )
  row.names(plan) <- NULL
  plan[c(
    "lane_id",
    "family_group",
    "family_route",
    "dpar",
    "dependence",
    "block_q",
    "admission_status",
    "dispatch_status",
    "actions_task",
    "workflow_helper",
    "audit_focus",
    "next_autonomous_action",
    "supervision_boundary"
  )]
}

phase18_structured_dependence_workflow_plan <- function(
  registry = phase18_read_structured_workflow_registry(),
  include_held = TRUE
) {
  rows <- phase18_filter_structured_workflow_registry(
    registry = registry,
    workflow_lane = "structured_dependence"
  )
  rows <- rows[
    !rows$admission_status %in% c("blocked", "design_only"),
    ,
    drop = FALSE
  ]
  if (!include_held) {
    rows <- rows[
      rows$admission_status %in%
        phase18_structured_workflow_admitted_statuses(),
      ,
      drop = FALSE
    ]
  }
  if (nrow(rows) == 0L) {
    return(phase18_empty_structured_dependence_workflow_plan())
  }

  needs_target <- startsWith(rows$existing_actions_task, "needed:")
  has_existing_task <- rows$existing_actions_task != "none" & !needs_target
  plan <- rows[c(
    "lane_id",
    "family_group",
    "family_route",
    "dpar",
    "dependence",
    "block_q",
    "admission_status",
    "existing_actions_task",
    "next_autonomous_action",
    "supervision_boundary"
  )]
  plan$dispatch_status <- phase18_structured_dependence_dispatch_status(
    admission_status = plan$admission_status,
    needs_target = needs_target
  )
  plan$actions_task <- ifelse(
    has_existing_task,
    plan$existing_actions_task,
    NA_character_
  )
  plan$workflow_helper <- ifelse(
    needs_target,
    sub("^needed:", "", plan$existing_actions_task),
    ifelse(has_existing_task, "phase18_actions_main", NA_character_)
  )
  plan$audit_focus <- phase18_structured_dependence_audit_focus(
    plan$admission_status
  )
  row.names(plan) <- NULL
  plan[c(
    "lane_id",
    "family_group",
    "family_route",
    "dpar",
    "dependence",
    "block_q",
    "admission_status",
    "dispatch_status",
    "actions_task",
    "workflow_helper",
    "audit_focus",
    "next_autonomous_action",
    "supervision_boundary"
  )]
}

phase18_correlation_block_workflow_plan <- function(
  registry = phase18_read_structured_workflow_registry(),
  include_diagnostic = TRUE
) {
  rows <- phase18_filter_structured_workflow_registry(
    registry = registry,
    workflow_lane = "correlation_blocks"
  )
  rows <- rows[
    !rows$admission_status %in% c("blocked", "design_only"),
    ,
    drop = FALSE
  ]
  if (!include_diagnostic) {
    rows <- rows[
      rows$admission_status != "diagnostic_only",
      ,
      drop = FALSE
    ]
  }
  if (nrow(rows) == 0L) {
    return(phase18_empty_correlation_block_workflow_plan())
  }

  needs_target <- startsWith(rows$existing_actions_task, "needed:")
  has_existing_task <- rows$existing_actions_task != "none" & !needs_target
  plan <- rows[c(
    "lane_id",
    "family_group",
    "family_route",
    "dpar",
    "dependence",
    "block_q",
    "admission_status",
    "existing_actions_task",
    "next_autonomous_action",
    "supervision_boundary"
  )]
  plan$dispatch_status <- phase18_correlation_block_dispatch_status(
    admission_status = plan$admission_status,
    needs_target = needs_target
  )
  plan$interval_policy <- phase18_correlation_block_interval_policy(
    block_q = plan$block_q,
    admission_status = plan$admission_status
  )
  plan$actions_task <- ifelse(
    has_existing_task,
    plan$existing_actions_task,
    NA_character_
  )
  plan$workflow_helper <- ifelse(
    needs_target,
    sub("^needed:", "", plan$existing_actions_task),
    ifelse(has_existing_task, "phase18_actions_main", NA_character_)
  )
  plan$audit_focus <- phase18_correlation_block_audit_focus(
    interval_policy = plan$interval_policy,
    admission_status = plan$admission_status
  )
  row.names(plan) <- NULL
  plan[c(
    "lane_id",
    "family_group",
    "family_route",
    "dpar",
    "dependence",
    "block_q",
    "admission_status",
    "dispatch_status",
    "interval_policy",
    "actions_task",
    "workflow_helper",
    "audit_focus",
    "next_autonomous_action",
    "supervision_boundary"
  )]
}

phase18_structured_workflow_actions_tasks <- function() {
  if (
    exists("phase18_actions_task_choices", mode = "function", inherits = TRUE)
  ) {
    return(phase18_actions_task_choices())
  }

  c(
    "first_wave_summary",
    "interval_heavy_summary",
    "truncated_nbinom2_mu_random_intercept",
    "proportion_fixed_effect",
    "bounded_response_mu_random_intercept",
    "positive_continuous_fixed_effect",
    "tweedie_fixed_effect",
    "count_structured_q1",
    "positive_continuous_mu_random_intercept",
    "student_mu_random_intercept",
    "ordinal_fixed_effect",
    "zero_one_beta_fixed_effect",
    "poisson_phylo_q1_formal",
    "nbinom2_phylo_q1_formal"
  )
}

phase18_empty_correlation_block_workflow_plan <- function() {
  data.frame(
    lane_id = character(),
    family_group = character(),
    family_route = character(),
    dpar = character(),
    dependence = character(),
    block_q = character(),
    admission_status = character(),
    dispatch_status = character(),
    interval_policy = character(),
    actions_task = character(),
    workflow_helper = character(),
    audit_focus = character(),
    next_autonomous_action = character(),
    supervision_boundary = character(),
    stringsAsFactors = FALSE
  )
}

phase18_empty_structured_dependence_workflow_plan <- function() {
  data.frame(
    lane_id = character(),
    family_group = character(),
    family_route = character(),
    dpar = character(),
    dependence = character(),
    block_q = character(),
    admission_status = character(),
    dispatch_status = character(),
    actions_task = character(),
    workflow_helper = character(),
    audit_focus = character(),
    next_autonomous_action = character(),
    supervision_boundary = character(),
    stringsAsFactors = FALSE
  )
}

phase18_empty_random_slope_workflow_plan <- function() {
  data.frame(
    lane_id = character(),
    family_group = character(),
    family_route = character(),
    dpar = character(),
    dependence = character(),
    block_q = character(),
    admission_status = character(),
    dispatch_status = character(),
    actions_task = character(),
    workflow_helper = character(),
    audit_focus = character(),
    next_autonomous_action = character(),
    supervision_boundary = character(),
    stringsAsFactors = FALSE
  )
}

phase18_correlation_block_dispatch_status <- function(
  admission_status,
  needs_target
) {
  status <- rep(NA_character_, length(admission_status))
  status[needs_target & admission_status == "diagnostic_only"] <-
    "diagnostic_wrapper_target"
  status[needs_target & admission_status != "diagnostic_only"] <-
    "needs_wrapper_target"
  status[is.na(status) & admission_status == "ready_grid"] <-
    "ready_existing_task"
  status[is.na(status) & admission_status == "ready_or_smoke"] <-
    "ready_or_smoke_audit"
  status[is.na(status) & admission_status == "diagnostic_only"] <-
    "diagnostic_audit"

  unknown <- is.na(status)
  if (any(unknown)) {
    stop(
      "Correlation-block workflow has unsupported status values: ",
      paste(unique(admission_status[unknown]), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  status
}

phase18_correlation_block_interval_policy <- function(
  block_q,
  admission_status
) {
  policy <- rep("direct_interval_audit", length(block_q))
  policy[block_q == "residual_coscale"] <- "direct_residual_rho12"
  policy[grepl("q2", block_q, fixed = TRUE)] <-
    "direct_or_layer_specific_q2"
  policy[grepl("q4", block_q, fixed = TRUE)] <-
    "q4_derived_interval_unavailable"
  policy[
    admission_status == "diagnostic_only" &
      !grepl("q4", block_q, fixed = TRUE)
  ] <- "diagnostic_interval_audit"
  policy
}

phase18_correlation_block_audit_focus <- function(
  interval_policy,
  admission_status
) {
  focus <- rep(NA_character_, length(interval_policy))
  focus[interval_policy == "direct_residual_rho12"] <- paste(
    "Keep residual rho12 separate from group and structured corpairs rows."
  )
  focus[interval_policy == "direct_or_layer_specific_q2"] <- paste(
    "Check direct q=2 or layer-specific interval provenance before",
    "dispatch."
  )
  focus[interval_policy == "q4_derived_interval_unavailable"] <- paste(
    "Report q=4 point estimates or diagnostics only; do not treat",
    "derived correlations as interval-ready."
  )
  focus[interval_policy == "direct_interval_audit"] <- paste(
    "Audit direct interval targets before profile or bootstrap work."
  )
  focus[interval_policy == "diagnostic_interval_audit"] <- paste(
    "Keep as diagnostic evidence until interval targets are designed."
  )
  focus[admission_status == "ready_or_smoke"] <- paste(
    focus[admission_status == "ready_or_smoke"],
    "Confirm whether the row has grid or smoke evidence."
  )

  unknown <- is.na(focus)
  if (any(unknown)) {
    stop(
      "Correlation-block workflow has unsupported interval policies: ",
      paste(unique(interval_policy[unknown]), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  focus
}

phase18_structured_dependence_dispatch_status <- function(
  admission_status,
  needs_target
) {
  status <- rep(NA_character_, length(admission_status))
  status[needs_target] <- "needs_wrapper_target"
  status[admission_status == "smoke_formal_admission"] <-
    "formal_admission_task"
  status[admission_status == "hold_smoke_only"] <- "hold_smoke_audit"
  status[admission_status == "diagnostic_only"] <- "diagnostic_audit"
  status[is.na(status) & admission_status == "ready_grid"] <-
    "ready_existing_task"
  status[is.na(status) & admission_status == "ready_source_test"] <-
    "source_test_audit"
  status[is.na(status) & admission_status == "ready_or_smoke"] <-
    "ready_or_smoke_audit"
  status[is.na(status) & admission_status == "ready_smoke"] <-
    "smoke_audit"

  unknown <- is.na(status)
  if (any(unknown)) {
    stop(
      "Structured-dependence workflow has unsupported status values: ",
      paste(unique(admission_status[unknown]), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  status
}

phase18_structured_dependence_audit_focus <- function(admission_status) {
  focus <- rep(NA_character_, length(admission_status))
  focus[admission_status == "ready_grid"] <- paste(
    "Build or audit the structured-dependence wrapper target before",
    "dispatching larger grids."
  )
  focus[admission_status == "smoke_formal_admission"] <- paste(
    "Run or audit formal-admission shards before treating the row as",
    "recovery evidence."
  )
  focus[admission_status == "hold_smoke_only"] <- paste(
    "Keep as smoke evidence until boundary and profile diagnostics clear",
    "the hold."
  )
  focus[admission_status == "diagnostic_only"] <- paste(
    "Use only for diagnostic artifact audits; do not promote to recovery",
    "or coverage evidence."
  )
  focus[admission_status == "ready_source_test"] <- paste(
    "Treat source tests as readiness evidence until an artifact lane exists."
  )
  focus[admission_status == "ready_or_smoke"] <- paste(
    "Confirm whether the row has grid or smoke evidence before dispatch."
  )
  focus[admission_status == "ready_smoke"] <- paste(
    "Use as smoke evidence only until a grid and artifact audit exist."
  )
  unknown <- is.na(focus)
  if (any(unknown)) {
    stop(
      "Structured-dependence workflow has unsupported status values: ",
      paste(unique(admission_status[unknown]), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  focus
}

phase18_random_slope_audit_focus <- function(admission_status) {
  focus <- rep(NA_character_, length(admission_status))
  focus[admission_status == "ready_grid"] <- paste(
    "Run or audit the named grid or smoke artifact before any",
    "status promotion."
  )
  focus[admission_status == "ready_source_test"] <- paste(
    "Treat focused source tests as readiness evidence; add an artifact",
    "lane before recovery or coverage claims."
  )
  focus[admission_status == "ready_or_smoke"] <- paste(
    "Confirm whether the row has formal grid evidence or only smoke",
    "evidence before dispatch."
  )
  focus[admission_status == "ready_smoke"] <- paste(
    "Use as smoke evidence only until a grid, MCSE, and artifact audit",
    "exist."
  )
  focus[admission_status == "smoke_formal_admission"] <- paste(
    "Run the formal-admission audit before treating the row as",
    "recovery evidence."
  )
  unknown <- is.na(focus)
  if (any(unknown)) {
    stop(
      "Random-slope workflow has unsupported admitted status values: ",
      paste(unique(admission_status[unknown]), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  focus
}

phase18_structured_workflow_required_columns <- function() {
  c(
    "lane_id",
    "workflow_lane",
    "family_group",
    "family_route",
    "dpar",
    "dependence",
    "block_q",
    "admission_status",
    "existing_actions_task",
    "next_autonomous_action",
    "supervision_boundary"
  )
}

phase18_structured_workflow_lanes <- function() {
  c(
    "correlation_blocks",
    "family_surface",
    "random_slopes",
    "structured_dependence"
  )
}

phase18_structured_workflow_statuses <- function() {
  c(
    "blocked",
    "design_only",
    "diagnostic_only",
    "hold_smoke_only",
    "ready_grid",
    "ready_or_smoke",
    "ready_smoke",
    "ready_source_test",
    "smoke_formal_admission"
  )
}

phase18_structured_workflow_admitted_statuses <- function() {
  c(
    "ready_grid",
    "ready_or_smoke",
    "ready_smoke",
    "ready_source_test",
    "smoke_formal_admission"
  )
}

phase18_validate_structured_workflow_values <- function(values, choices, name) {
  unknown <- setdiff(unique(values), choices)
  if (length(unknown) > 0L) {
    stop(
      "`",
      name,
      "` contains unknown values: ",
      paste(unknown, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  invisible(values)
}
