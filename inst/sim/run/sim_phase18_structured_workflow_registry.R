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
    candidates <- c(
      candidates,
      file.path(getwd(), "inst", registry_file),
      file.path(getwd(), registry_file)
    )
    installed <- system.file(registry_file, package = package)
    if (nzchar(installed)) {
      candidates <- c(candidates, installed)
    }
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

phase18_random_slope_operating_characteristic_plan <- function(
  registry = phase18_read_structured_workflow_registry(),
  include_source_test = TRUE
) {
  plan <- phase18_random_slope_workflow_plan(registry)
  if (!include_source_test) {
    plan <- plan[
      plan$admission_status != "ready_source_test",
      ,
      drop = FALSE
    ]
  }
  if (nrow(plan) == 0L) {
    return(phase18_empty_random_slope_operating_characteristic_plan())
  }

  plan$existing_actions_task <- ifelse(
    is.na(plan$actions_task),
    "none",
    plan$actions_task
  )
  plan$accuracy_status <-
    phase18_random_slope_oc_accuracy_status(plan$admission_status)
  plan$coverage_status <-
    phase18_random_slope_oc_coverage_status(plan$lane_id)
  plan$power_status <-
    phase18_random_slope_oc_power_status(plan$lane_id)
  plan$minimum_estimands <-
    phase18_random_slope_oc_minimum_estimands(plan$lane_id, plan$dpar)
  plan$boundary_note <- phase18_random_slope_oc_boundary_note(
    admission_status = plan$admission_status,
    supervision_boundary = plan$supervision_boundary
  )
  row.names(plan) <- NULL
  plan[c(
    "lane_id",
    "family_group",
    "family_route",
    "dpar",
    "dependence",
    "admission_status",
    "existing_actions_task",
    "accuracy_status",
    "coverage_status",
    "power_status",
    "minimum_estimands",
    "boundary_note"
  )]
}

phase18_random_slope_wrapper_target_plan <- function(
  registry = phase18_read_structured_workflow_registry()
) {
  plan <- phase18_random_slope_workflow_plan(registry)
  targets <- plan[
    plan$workflow_helper == "random_slope_wrapper",
    ,
    drop = FALSE
  ]
  if (nrow(targets) == 0L) {
    return(phase18_empty_random_slope_wrapper_target_plan())
  }

  targets$target_status <- "grid_writer_available"
  targets$source_evidence <- phase18_random_slope_wrapper_source_evidence(
    targets$lane_id
  )
  targets$required_helper <- phase18_random_slope_wrapper_required_helper(
    targets$lane_id
  )
  targets$artifact_writer <- phase18_random_slope_wrapper_artifact_writer(
    targets$lane_id
  )
  targets$dispatch_mode <- "local_artifacts_not_actions"
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
    "required_helper",
    "artifact_writer",
    "source_evidence",
    "dispatch_mode",
    "next_autonomous_action",
    "supervision_boundary"
  )]
}

phase18_random_slope_registry_preflight <- function(
  registry = phase18_read_structured_workflow_registry()
) {
  phase18_validate_structured_workflow_registry(registry)
  rows <- phase18_filter_structured_workflow_registry(
    registry = registry,
    workflow_lane = "random_slopes"
  )
  if (nrow(rows) == 0L) {
    stop("No `workflow_lane == \"random_slopes\"` rows found.", call. = FALSE)
  }
  phase18_assert_random_slope_preflight_fields(rows)

  plan <- phase18_random_slope_workflow_plan(registry)
  plan_row <- match(rows$lane_id, plan$lane_id)
  rows$dispatch_status <- "held_by_status"
  rows$actions_task <- NA_character_
  rows$workflow_helper <- "held_no_dispatch"
  rows$audit_focus <- "blocked_design_required"
  rows$audit_focus[rows$admission_status == "design_only"] <- "design_required"
  matched <- !is.na(plan_row)
  rows$dispatch_status[matched] <- plan$dispatch_status[plan_row[matched]]
  rows$actions_task[matched] <- plan$actions_task[plan_row[matched]]
  rows$workflow_helper[matched] <- plan$workflow_helper[plan_row[matched]]
  rows$audit_focus[matched] <- plan$audit_focus[plan_row[matched]]

  row_columns <- c(
    "lane_id",
    "family_group",
    "family_route",
    "dpar",
    "dependence",
    "block_q",
    "admission_status",
    "existing_actions_task",
    "dispatch_status",
    "actions_task",
    "workflow_helper",
    "audit_focus",
    "next_autonomous_action",
    "supervision_boundary"
  )
  rows <- rows[row_columns]
  row.names(rows) <- NULL

  list(
    checks = phase18_random_slope_preflight_checks(rows),
    rows = rows
  )
}

phase18_biv_gaussian_q8_endpoint_precode_gate <- function(
  registry = phase18_read_structured_workflow_registry()
) {
  phase18_validate_structured_workflow_registry(registry)
  row <- registry[
    registry$lane_id == "bivariate_gaussian_q8_endpoint",
    ,
    drop = FALSE
  ]
  if (nrow(row) != 1L) {
    stop(
      "Expected exactly one `bivariate_gaussian_q8_endpoint` registry row.",
      call. = FALSE
    )
  }

  endpoints <- phase18_biv_gaussian_q8_endpoint_taxonomy()
  n_endpoint <- nrow(endpoints)
  n_correlation <- n_endpoint * (n_endpoint - 1L) / 2L
  checks <- data.frame(
    check = c(
      "registry_row_design_only",
      "no_actions_task",
      "endpoint_count",
      "correlation_count",
      "supervision_boundary"
    ),
    value = c(
      row$admission_status,
      row$existing_actions_task,
      as.character(n_endpoint),
      as.character(n_correlation),
      row$supervision_boundary
    ),
    status = c(
      ifelse(row$admission_status == "design_only", "pass", "fail"),
      ifelse(row$existing_actions_task == "none", "pass", "fail"),
      ifelse(n_endpoint == 8L, "pass", "fail"),
      ifelse(n_correlation == 28L, "pass", "fail"),
      ifelse(nzchar(row$supervision_boundary), "pass", "fail")
    ),
    stringsAsFactors = FALSE
  )

  list(
    row = row,
    endpoints = endpoints,
    checks = checks
  )
}

phase18_biv_gaussian_q8_endpoint_taxonomy <- function() {
  data.frame(
    endpoint_index = seq_len(8L),
    endpoint = c(
      "mu1:(Intercept)",
      "mu1:x",
      "mu2:(Intercept)",
      "mu2:x",
      "sigma1:(Intercept)",
      "sigma1:x",
      "sigma2:(Intercept)",
      "sigma2:x"
    ),
    dpar = rep(c("mu1", "mu2", "sigma1", "sigma2"), each = 2L),
    coefficient = rep(c("(Intercept)", "x"), 4L),
    endpoint_role = rep(c("intercept", "slope"), 4L),
    stringsAsFactors = FALSE
  )
}

phase18_format_random_slope_registry_preflight <- function(
  preflight = phase18_random_slope_registry_preflight()
) {
  phase18_assert_random_slope_registry_preflight(preflight)
  row_columns <- c(
    "lane_id",
    "admission_status",
    "existing_actions_task",
    "dispatch_status",
    "actions_task",
    "workflow_helper",
    "audit_focus",
    "supervision_boundary"
  )
  c(
    "Phase 18 random-slope registry preflight",
    paste(
      "No simulations, GitHub Actions jobs, likelihoods, or status",
      "promotions are dispatched."
    ),
    "",
    "Checks",
    phase18_format_structured_workflow_table(preflight$checks),
    "",
    "Random-slope rows",
    phase18_format_structured_workflow_table(preflight$rows[row_columns])
  )
}

phase18_print_random_slope_registry_preflight <- function(
  preflight = phase18_random_slope_registry_preflight(),
  file = ""
) {
  lines <- phase18_format_random_slope_registry_preflight(preflight)
  phase18_write_structured_workflow_lines(lines, file = file)
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
  plan$audit_focus[plan$dispatch_status == "ready_existing_task"] <- paste(
    "Run or audit the existing Actions task before treating artifacts as",
    "recovery evidence."
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

phase18_correlation_block_wrapper_target_plan <- function(
  registry = phase18_read_structured_workflow_registry(),
  include_diagnostic = TRUE
) {
  plan <- phase18_correlation_block_workflow_plan(
    registry = registry,
    include_diagnostic = include_diagnostic
  )
  targets <- plan[
    plan$workflow_helper %in% "correlation_block_wrapper",
    ,
    drop = FALSE
  ]
  if (nrow(targets) == 0L) {
    return(phase18_empty_correlation_block_wrapper_target_plan())
  }

  targets$target_status <- phase18_correlation_block_wrapper_target_status(
    dispatch_status = targets$dispatch_status,
    interval_policy = targets$interval_policy
  )
  targets$required_evidence <- phase18_correlation_block_wrapper_evidence(
    interval_policy = targets$interval_policy
  )
  targets$dispatch_mode <- "read_only_no_models_or_actions"
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
    "interval_policy",
    "actions_task",
    "workflow_helper",
    "required_evidence",
    "dispatch_mode",
    "audit_focus",
    "next_autonomous_action",
    "supervision_boundary"
  )]
}

phase18_family_surface_workflow_plan <- function(
  registry = phase18_read_structured_workflow_registry(),
  include_blocked = TRUE
) {
  rows <- phase18_filter_structured_workflow_registry(
    registry = registry,
    workflow_lane = "family_surface"
  )
  if (!include_blocked) {
    rows <- rows[
      !rows$admission_status %in% c("blocked", "design_only"),
      ,
      drop = FALSE
    ]
  }
  if (nrow(rows) == 0L) {
    return(phase18_empty_family_surface_workflow_plan())
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
  plan$admission_category <- phase18_family_surface_admission_category(
    plan$admission_status
  )
  plan$dispatch_status <- phase18_family_surface_dispatch_status(
    admission_status = plan$admission_status,
    has_existing_task = has_existing_task,
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
  plan$audit_focus <- phase18_family_surface_audit_focus(
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
    "admission_category",
    "dispatch_status",
    "actions_task",
    "workflow_helper",
    "audit_focus",
    "next_autonomous_action",
    "supervision_boundary"
  )]
}

phase18_family_surface_status_tables <- function(
  registry = phase18_read_structured_workflow_registry(),
  include_blocked = TRUE
) {
  plan <- phase18_family_surface_workflow_plan(
    registry = registry,
    include_blocked = include_blocked
  )
  row_summary <- phase18_family_surface_row_status_summary(plan)

  list(
    row_summary = row_summary,
    category_summary = phase18_family_surface_status_count_summary(
      row_summary,
      by = c(
        "admission_category",
        "admission_status",
        "dispatch_status"
      )
    ),
    distribution_summary = phase18_family_surface_status_count_summary(
      row_summary,
      by = c(
        "family_group",
        "family_route",
        "admission_category",
        "admission_status"
      )
    )
  )
}

phase18_family_surface_row_status_summary <- function(plan) {
  phase18_assert_structured_workflow_plan(plan)
  row_columns <- c(
    "lane_id",
    "family_group",
    "family_route",
    "dpar",
    "dependence",
    "block_q",
    "admission_status",
    "admission_category",
    "dispatch_status",
    "actions_task",
    "next_autonomous_action",
    "supervision_boundary"
  )
  missing <- setdiff(row_columns, names(plan))
  if (length(missing) > 0L) {
    stop(
      "`plan` is missing family-surface status columns: ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }

  summary <- plan[row_columns]
  summary$status_scope <- rep("registry_status_only", nrow(summary))
  row.names(summary) <- NULL
  summary
}

phase18_family_surface_status_count_summary <- function(rows, by) {
  if (!is.data.frame(rows)) {
    stop("`rows` must be a data frame.", call. = FALSE)
  }
  missing <- setdiff(by, names(rows))
  if (length(missing) > 0L) {
    stop(
      "`by` contains unknown columns: ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  if (nrow(rows) == 0L) {
    out <- as.data.frame(
      stats::setNames(
        replicate(length(by), character(), simplify = FALSE),
        by
      ),
      stringsAsFactors = FALSE
    )
    out$n <- integer()
    out$status_scope <- character()
    return(out)
  }

  rows$.n <- 1L
  summary <- aggregate(
    rows[".n"],
    rows[by],
    sum
  )
  names(summary)[names(summary) == ".n"] <- "n"
  summary$status_scope <- "registry_status_only"
  row.names(summary) <- NULL
  summary[do.call(order, summary[by]), , drop = FALSE]
}

phase18_structured_workflow_plan_bundle <- function(
  registry = phase18_read_structured_workflow_registry()
) {
  phase18_validate_structured_workflow_registry(registry)
  plans <- list(
    random_slopes = phase18_random_slope_workflow_plan(registry),
    structured_dependence = phase18_structured_dependence_workflow_plan(
      registry
    ),
    correlation_blocks = phase18_correlation_block_workflow_plan(registry),
    family_surface = phase18_family_surface_workflow_plan(registry)
  )
  list(
    registry_summary = phase18_structured_workflow_registry_summary(registry),
    plan_counts = phase18_structured_workflow_plan_counts(plans),
    plans = plans
  )
}

phase18_structured_workflow_plan_counts <- function(plans) {
  if (is.list(plans) && !is.null(plans$plans)) {
    plans <- plans$plans
  }
  if (!is.list(plans) || length(plans) == 0L) {
    stop(
      "`plans` must be a non-empty list of workflow plan tables.",
      call. = FALSE
    )
  }

  out <- lapply(names(plans), function(plan_name) {
    plan <- plans[[plan_name]]
    if (!is.data.frame(plan)) {
      stop("Each workflow plan must be a data frame.", call. = FALSE)
    }
    data.frame(
      workflow_plan = plan_name,
      n = nrow(plan),
      existing_actions_tasks = sum(!is.na(plan$actions_task)),
      wrapper_targets = sum(grepl("wrapper_target", plan$dispatch_status)),
      ready_grid = sum(plan$admission_status == "ready_grid"),
      ready_or_smoke = sum(plan$admission_status == "ready_or_smoke"),
      ready_source_test = sum(plan$admission_status == "ready_source_test"),
      diagnostic_only = sum(plan$admission_status == "diagnostic_only"),
      ready_smoke = sum(plan$admission_status == "ready_smoke"),
      hold_smoke_only = sum(plan$admission_status == "hold_smoke_only"),
      blocked = sum(plan$admission_status == "blocked"),
      design_only = sum(plan$admission_status == "design_only"),
      stringsAsFactors = FALSE
    )
  })
  do.call(rbind, out)
}

phase18_format_structured_workflow_bundle_dry_run <- function(
  bundle = phase18_structured_workflow_plan_bundle()
) {
  phase18_assert_structured_workflow_bundle(bundle)
  count_columns <- intersect(
    c(
      "workflow_plan",
      "n",
      "existing_actions_tasks",
      "wrapper_targets",
      "diagnostic_only",
      "blocked",
      "design_only"
    ),
    names(bundle$plan_counts)
  )
  lines <- c(
    "Phase 18 structured workflow dry run",
    paste(
      "No simulations, GitHub Actions jobs, likelihoods, or status",
      "promotions are dispatched."
    ),
    "",
    "Plan counts",
    phase18_format_structured_workflow_table(
      bundle$plan_counts[count_columns]
    )
  )

  for (plan_name in names(bundle$plans)) {
    lines <- c(
      lines,
      "",
      phase18_format_structured_workflow_plan_dry_run(
        plan = bundle$plans[[plan_name]],
        plan_name = plan_name
      )
    )
  }
  lines
}

phase18_print_structured_workflow_bundle_dry_run <- function(
  bundle = phase18_structured_workflow_plan_bundle(),
  file = ""
) {
  lines <- phase18_format_structured_workflow_bundle_dry_run(bundle)
  phase18_write_structured_workflow_lines(lines, file = file)
}

phase18_format_structured_workflow_plan_dry_run <- function(
  plan,
  plan_name = NULL
) {
  phase18_assert_structured_workflow_plan(plan)
  plan_columns <- intersect(
    c(
      "lane_id",
      "family_group",
      "dpar",
      "dependence",
      "block_q",
      "admission_status",
      "admission_category",
      "dispatch_status",
      "interval_policy",
      "actions_task",
      "workflow_helper"
    ),
    names(plan)
  )
  c(
    if (!is.null(plan_name)) paste0("Plan: ", plan_name),
    phase18_format_structured_workflow_table(plan[plan_columns])
  )
}

phase18_print_structured_workflow_plan_dry_run <- function(
  plan,
  plan_name = NULL,
  file = ""
) {
  lines <- phase18_format_structured_workflow_plan_dry_run(
    plan = plan,
    plan_name = plan_name
  )
  phase18_write_structured_workflow_lines(lines, file = file)
}

phase18_write_structured_workflow_lines <- function(lines, file = "") {
  if (!is.character(lines)) {
    stop("`lines` must be a character vector.", call. = FALSE)
  }
  cat(paste(lines, collapse = "\n"), "\n", sep = "", file = file)
  invisible(lines)
}

phase18_format_structured_workflow_table <- function(table) {
  if (!is.data.frame(table)) {
    stop("`table` must be a data frame.", call. = FALSE)
  }
  if (nrow(table) == 0L) {
    return("(none)")
  }
  table[] <- lapply(table, function(column) {
    column <- as.character(column)
    column[is.na(column)] <- ""
    column
  })
  old_width <- getOption("width")
  options(width = max(old_width, 180L))
  on.exit(options(width = old_width), add = TRUE)
  utils::capture.output(print(table, row.names = FALSE, right = FALSE))
}

phase18_assert_structured_workflow_bundle <- function(bundle) {
  if (
    !is.list(bundle) ||
      is.null(bundle$plans) ||
      is.null(bundle$plan_counts) ||
      !is.list(bundle$plans) ||
      !is.data.frame(bundle$plan_counts)
  ) {
    stop(
      "`bundle` must come from phase18_structured_workflow_plan_bundle().",
      call. = FALSE
    )
  }
  invisible(bundle)
}

phase18_assert_structured_workflow_plan <- function(plan) {
  if (!is.data.frame(plan)) {
    stop("`plan` must be a workflow plan data frame.", call. = FALSE)
  }
  required <- c("lane_id", "admission_status", "dispatch_status")
  missing <- setdiff(required, names(plan))
  if (length(missing) > 0L) {
    stop(
      "`plan` is missing required columns: ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  invisible(plan)
}

phase18_assert_random_slope_preflight_fields <- function(rows) {
  required <- c(
    "admission_status",
    "existing_actions_task",
    "supervision_boundary"
  )
  for (column in required) {
    values <- trimws(as.character(rows[[column]]))
    missing <- is.na(values) | !nzchar(values)
    if (any(missing)) {
      stop(
        "Random-slope registry preflight requires non-empty `",
        column,
        "` values. Missing rows: ",
        paste(rows$lane_id[missing], collapse = ", "),
        ".",
        call. = FALSE
      )
    }
  }
  invisible(rows)
}

phase18_random_slope_preflight_checks <- function(rows) {
  phase18_assert_random_slope_preflight_fields(rows)
  data.frame(
    check = c(
      "random_slope_rows",
      "required_fields_complete",
      "existing_actions_tasks",
      "source_test_audits",
      "wrapper_targets"
    ),
    value = c(
      as.character(nrow(rows)),
      "pass",
      as.character(sum(!is.na(rows$actions_task))),
      as.character(sum(rows$dispatch_status == "source_test_audit")),
      as.character(sum(grepl("wrapper_target", rows$dispatch_status)))
    ),
    status = c(
      ifelse(nrow(rows) > 0L, "pass", "fail"),
      "pass",
      "informational",
      "informational",
      ifelse(
        any(grepl("wrapper_target", rows$dispatch_status)),
        "needs_wrapper",
        "pass"
      )
    ),
    stringsAsFactors = FALSE
  )
}

phase18_assert_random_slope_registry_preflight <- function(preflight) {
  if (
    !is.list(preflight) ||
      !is.data.frame(preflight$checks) ||
      !is.data.frame(preflight$rows)
  ) {
    stop(
      "`preflight` must come from ",
      "phase18_random_slope_registry_preflight().",
      call. = FALSE
    )
  }
  invisible(preflight)
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
    "poisson_mu_re_recovery",
    "nbinom2_mu_re_recovery",
    "positive_continuous_mu_random_intercept",
    "student_mu_random_intercept",
    "ordinal_fixed_effect",
    "zero_one_beta_fixed_effect",
    "correlation_block_status",
    "biv_gaussian_mu_slope",
    "biv_gaussian_mu_slope_recovery",
    "biv_gaussian_q4_location",
    "biv_gaussian_q4_location_recovery",
    "biv_gaussian_q6_location",
    "biv_gaussian_q6_location_recovery",
    "biv_gaussian_q2_scale",
    "biv_gaussian_q2_scale_recovery",
    "spatial_mu_slope",
    "phylo_mu_slope",
    "animal_mu_slope",
    "relmat_mu_slope",
    "poisson_phylo_q1_formal",
    "nbinom2_phylo_q1_formal"
  )
}

phase18_empty_family_surface_workflow_plan <- function() {
  data.frame(
    lane_id = character(),
    family_group = character(),
    family_route = character(),
    dpar = character(),
    dependence = character(),
    block_q = character(),
    admission_status = character(),
    admission_category = character(),
    dispatch_status = character(),
    actions_task = character(),
    workflow_helper = character(),
    audit_focus = character(),
    next_autonomous_action = character(),
    supervision_boundary = character(),
    stringsAsFactors = FALSE
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

phase18_empty_correlation_block_wrapper_target_plan <- function() {
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
    interval_policy = character(),
    actions_task = character(),
    workflow_helper = character(),
    required_evidence = character(),
    dispatch_mode = character(),
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

phase18_empty_random_slope_operating_characteristic_plan <- function() {
  data.frame(
    lane_id = character(),
    family_group = character(),
    family_route = character(),
    dpar = character(),
    dependence = character(),
    admission_status = character(),
    existing_actions_task = character(),
    accuracy_status = character(),
    coverage_status = character(),
    power_status = character(),
    minimum_estimands = character(),
    boundary_note = character(),
    stringsAsFactors = FALSE
  )
}

phase18_empty_random_slope_wrapper_target_plan <- function() {
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
    required_helper = character(),
    artifact_writer = character(),
    source_evidence = character(),
    dispatch_mode = character(),
    next_autonomous_action = character(),
    supervision_boundary = character(),
    stringsAsFactors = FALSE
  )
}

phase18_random_slope_oc_accuracy_status <- function(admission_status) {
  status <- rep(NA_character_, length(admission_status))
  status[admission_status == "ready_grid"] <- paste(
    "artifact_or_smoke_lane_exists_accuracy_not_estimated"
  )
  status[admission_status == "ready_source_test"] <- paste(
    "source_tests_exist_artifact_lane_needed"
  )
  status[admission_status == "ready_or_smoke"] <- paste(
    "grid_or_smoke_status_needs_artifact_audit"
  )
  status[admission_status == "ready_smoke"] <- paste(
    "smoke_only_accuracy_not_estimated"
  )
  status[admission_status == "smoke_formal_admission"] <- paste(
    "formal_admission_needed_accuracy_not_estimated"
  )

  unknown <- is.na(status)
  if (any(unknown)) {
    stop(
      "Random-slope operating-characteristic plan has unsupported statuses: ",
      paste(unique(admission_status[unknown]), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  status
}

phase18_random_slope_oc_coverage_status <- function(lane_id) {
  rep("planned_not_estimated", length(lane_id))
}

phase18_random_slope_oc_power_status <- function(lane_id) {
  rep("planned_not_estimated", length(lane_id))
}

phase18_random_slope_oc_minimum_estimands <- function(lane_id, dpar) {
  estimands <- rep(
    paste(
      "link-scale fixed effects; random-effect SDs; convergence,",
      "Hessian, warning, boundary, and runtime diagnostics"
    ),
    length(lane_id)
  )
  estimands[lane_id == "gaussian_ordinary_mu_slopes"] <- paste(
    "mu fixed effects; mu random-slope SDs; ordinary q > 2 derived",
    "correlation rows labelled non-direct for intervals; diagnostics"
  )
  estimands[lane_id == "gaussian_sigma_independent_slopes"] <- paste(
    "sigma fixed effects on log(sigma); independent residual-scale",
    "slope SDs; response-scale sigma summaries; diagnostics"
  )
  estimands[lane_id == "bivariate_gaussian_slope_only"] <- paste(
    "mu1 and mu2 fixed effects; paired random-slope SDs;",
    "slope-slope corpairs row; residual rho12 kept separate; diagnostics"
  )
  estimands[lane_id == "bivariate_gaussian_q4_location"] <- paste(
    "mu1 and mu2 fixed effects; four direct q4 location SDs;",
    "six derived q4 location correlations kept point/status-only;",
    "residual rho12 kept separate; diagnostics"
  )
  estimands[lane_id == "bivariate_gaussian_q6_location"] <- paste(
    "mu1 and mu2 fixed effects; six direct q6 location SDs;",
    "15 derived q6 location correlations kept point/status-only;",
    "residual rho12 kept separate; diagnostics"
  )
  estimands[
    lane_id %in%
      c(
        "poisson_mu_random_effects",
        "nbinom2_mu_random_effects",
        "truncated_nbinom2_mu_random_effects"
      )
  ] <- paste(
    "mu fixed effects; count-scale random-effect SDs;",
    "mean-response summaries; convergence, boundary, and warning diagnostics"
  )
  estimands[
    lane_id %in%
      c(
        "bounded_mu_random_effects",
        "positive_continuous_mu_random_effects",
        "student_mu_random_effects"
      )
  ] <- paste(
    "mu fixed effects; ordinary mu random-effect SDs;",
    "family-specific response summaries; convergence and boundary diagnostics"
  )
  estimands
}

phase18_random_slope_oc_boundary_note <- function(
  admission_status,
  supervision_boundary
) {
  note <- ifelse(
    admission_status == "ready_source_test",
    paste(
      "Focused source tests are readiness evidence only; add an artifact",
      "lane before recovery, coverage, or power claims."
    ),
    paste(
      "Run replicate grids with MCSE-backed summaries before recovery,",
      "coverage, or power claims."
    )
  )
  paste(note, supervision_boundary)
}

phase18_family_surface_admission_category <- function(admission_status) {
  category <- rep(NA_character_, length(admission_status))
  category[
    admission_status %in%
      c(
        "ready_grid",
        "ready_or_smoke",
        "ready_source_test",
        "smoke_formal_admission"
      )
  ] <- "admitted"
  category[admission_status == "ready_smoke"] <- "smoke_only"
  category[admission_status == "diagnostic_only"] <- "diagnostic"
  category[admission_status == "hold_smoke_only"] <- "hold"
  category[admission_status == "blocked"] <- "blocked"
  category[admission_status == "design_only"] <- "design_only"

  unknown <- is.na(category)
  if (any(unknown)) {
    stop(
      "Family-surface workflow has unsupported status values: ",
      paste(unique(admission_status[unknown]), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  category
}

phase18_family_surface_dispatch_status <- function(
  admission_status,
  has_existing_task,
  needs_target
) {
  status <- rep(NA_character_, length(admission_status))
  status[admission_status == "blocked"] <- "blocked_design_required"
  status[admission_status == "design_only"] <- "design_required"
  status[needs_target & is.na(status)] <- "needs_wrapper_target"
  status[has_existing_task & admission_status == "ready_grid"] <-
    "ready_existing_task"
  status[has_existing_task & admission_status == "ready_smoke"] <-
    "smoke_audit"
  status[has_existing_task & admission_status == "ready_or_smoke"] <-
    "ready_or_smoke_audit"
  status[has_existing_task & admission_status == "ready_source_test"] <-
    "source_test_audit"
  status[is.na(status) & admission_status == "diagnostic_only"] <-
    "diagnostic_audit"

  unknown <- is.na(status)
  if (any(unknown)) {
    stop(
      "Family-surface workflow has unsupported dispatch rows: ",
      paste(unique(admission_status[unknown]), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  status
}

phase18_family_surface_audit_focus <- function(admission_status) {
  focus <- rep(NA_character_, length(admission_status))
  focus[admission_status == "ready_grid"] <- paste(
    "Run or audit the named fixed or family-surface grid before",
    "summary reporting."
  )
  focus[admission_status == "ready_smoke"] <- paste(
    "Keep as smoke evidence until grid, MCSE, and artifact audit exist."
  )
  focus[admission_status == "blocked"] <- paste(
    "Keep in the failure ledger until a likelihood, grammar, and",
    "simulation design gate opens it."
  )
  focus[admission_status == "design_only"] <- paste(
    "Keep as design-only until a joint likelihood and validation contract",
    "exist."
  )
  focus[admission_status == "ready_source_test"] <- paste(
    "Treat source tests as readiness evidence until an artifact lane exists."
  )
  focus[admission_status == "ready_or_smoke"] <- paste(
    "Confirm whether the row has grid or smoke evidence before reporting."
  )
  focus[admission_status == "diagnostic_only"] <- paste(
    "Use only for diagnostic summaries; do not make recovery claims."
  )
  focus[admission_status == "hold_smoke_only"] <- paste(
    "Keep as held smoke evidence until boundary diagnostics clear."
  )
  focus[admission_status == "smoke_formal_admission"] <- paste(
    "Run formal-admission audit before treating as recovery evidence."
  )

  unknown <- is.na(focus)
  if (any(unknown)) {
    stop(
      "Family-surface workflow has unsupported status values: ",
      paste(unique(admission_status[unknown]), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  focus
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

phase18_correlation_block_wrapper_target_status <- function(
  dispatch_status,
  interval_policy
) {
  status <- rep("status_only_wrapper_target", length(dispatch_status))
  status[
    dispatch_status == "needs_wrapper_target" &
      interval_policy == "direct_or_layer_specific_q2"
  ] <- "q2_interval_provenance_needed"
  status[
    dispatch_status == "diagnostic_wrapper_target" &
      interval_policy == "q4_derived_interval_unavailable"
  ] <- "q4_diagnostic_only"
  status
}

phase18_correlation_block_wrapper_evidence <- function(interval_policy) {
  evidence <- rep(
    "Audit direct interval targets before profile or bootstrap work.",
    length(interval_policy)
  )
  evidence[interval_policy == "direct_or_layer_specific_q2"] <- paste(
    "Layer-specific q=2 interval provenance and artifact audit are needed",
    "before dispatch."
  )
  evidence[interval_policy == "q4_derived_interval_unavailable"] <- paste(
    "Point-estimate diagnostics may be reported; derived q=4 intervals",
    "remain unavailable."
  )
  evidence
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

phase18_random_slope_wrapper_source_evidence <- function(lane_id) {
  evidence <- rep(NA_character_, length(lane_id))
  evidence[lane_id == "bivariate_gaussian_slope_only"] <- paste(
    "tests/testthat/test-biv-gaussian.R:",
    "matching mu1/mu2 slope-only covariance block source test"
  )
  unknown <- is.na(evidence)
  if (any(unknown)) {
    stop(
      "Random-slope wrapper has unknown target rows: ",
      paste(unique(lane_id[unknown]), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  evidence
}

phase18_random_slope_wrapper_required_helper <- function(lane_id) {
  helper <- rep(NA_character_, length(lane_id))
  helper[lane_id == "bivariate_gaussian_slope_only"] <-
    "phase18_run_bivariate_gaussian_mu_slope_smoke()"
  unknown <- is.na(helper)
  if (any(unknown)) {
    stop(
      "Random-slope wrapper has unknown target rows: ",
      paste(unique(lane_id[unknown]), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  helper
}

phase18_random_slope_wrapper_artifact_writer <- function(lane_id) {
  writer <- rep(NA_character_, length(lane_id))
  writer[lane_id == "bivariate_gaussian_slope_only"] <-
    "phase18_write_biv_gaussian_mu_slope_grid_outputs()"
  unknown <- is.na(writer)
  if (any(unknown)) {
    stop(
      "Random-slope wrapper has unknown target rows: ",
      paste(unique(lane_id[unknown]), collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  writer
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
