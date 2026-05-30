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
