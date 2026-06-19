args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "docs/dev-log/simulation-artifacts/2026-06-18-structured-q2-boundary-diagnostic/run-pilot.R",
    mustWork = TRUE
  )
}

artifact_dir <- dirname(script_path)
repo_root <- normalizePath(
  file.path(artifact_dir, "../../../.."),
  mustWork = TRUE
)
tables_dir <- file.path(artifact_dir, "tables")
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages(devtools::load_all(repo_root, quiet = TRUE))
source(file.path(repo_root, "inst/sim/R/sim_registry.R"))
source(file.path(repo_root, "inst/sim/R/sim_utils.R"))
source(file.path(repo_root, "inst/sim/R/sim_runner.R"))
source(file.path(repo_root, "inst/sim/R/sim_uncertainty.R"))
source(file.path(repo_root, "inst/sim/dgp/sim_dgp_spatial_q2.R"))
source(file.path(repo_root, "inst/sim/fit/sim_summarise_spatial_q2.R"))
source(file.path(repo_root, "inst/sim/run/sim_run_spatial_q2_smoke.R"))
source(file.path(repo_root, "inst/sim/dgp/sim_dgp_animal_relmat_q2.R"))
source(file.path(repo_root, "inst/sim/fit/sim_summarise_animal_relmat_q2.R"))
source(file.path(repo_root, "inst/sim/run/sim_run_animal_relmat_q2_smoke.R"))

rho_guard <- 0.999999
rho_boundary <- 0.98

git_lines <- function(...) {
  tryCatch(
    system2("git", c("-C", repo_root, ...), stdout = TRUE, stderr = TRUE),
    warning = function(w) NA_character_,
    error = function(e) NA_character_
  )
}

git_value <- function(...) {
  out <- git_lines(...)
  if (!length(out) || all(is.na(out))) {
    return(NA_character_)
  }
  out[[1L]]
}

capture_fit <- function(expr) {
  warnings <- character()
  value <- withCallingHandlers(
    tryCatch(expr, error = function(e) e),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  list(value = value, warnings = warnings)
}

max_abs_gradient <- function(fit) {
  gradient <- tryCatch(fit$obj$gr(fit$opt$par), error = function(e) NA_real_)
  if (!is.numeric(gradient) || !any(is.finite(gradient))) {
    return(NA_real_)
  }
  max(abs(gradient), na.rm = TRUE)
}

first_check_value <- function(checks, check, field) {
  row <- checks[checks$check == check, , drop = FALSE]
  if (nrow(row) == 0L || !field %in% names(row)) {
    return(NA_character_)
  }
  as.character(row[[field]][[1L]])
}

check_status <- function(checks, check) {
  first_check_value(checks, check, "status")
}

check_value <- function(checks, check) {
  first_check_value(checks, check, "value")
}

check_message <- function(checks, check) {
  first_check_value(checks, check, "message")
}

gradient_component <- function(value) {
  out <- sub("^.*component=([^;]+).*$", "\\1", value)
  if (identical(out, value)) {
    return(NA_character_)
  }
  out
}

rho_link <- function(rho) {
  atanh(pmax(pmin(rho / rho_guard, 1 - 1e-12), -1 + 1e-12))
}

rho_response_local <- function(eta) {
  rho_guard * tanh(eta)
}

source_grid <- data.frame(
  target = c("zero", "moderate", "high", "boundary"),
  rho_true = c(0, 0.4, 0.9, 0.98),
  stringsAsFactors = FALSE
)
source_grid$eta_equivalent <- rho_link(source_grid$rho_true)
source_grid$rho_guarded <- rho_response_local(source_grid$eta_equivalent)
source_grid$rho_unguarded <- tanh(source_grid$eta_equivalent)
source_grid$guard_delta <- source_grid$rho_unguarded -
  source_grid$rho_guarded
source_grid$boundary_distance <- 1 - abs(source_grid$rho_guarded)
source_grid$one_minus_rho2 <- 1 - source_grid$rho_guarded^2
source_grid$delta_derivative <- rho_guard *
  (1 - tanh(source_grid$eta_equivalent)^2)

conditions <- do.call(
  rbind,
  lapply(
    c("spatial", "animal", "relmat"),
    function(surface) {
      data.frame(
        surface = surface,
        check_name = paste0("biv_", surface, "_q2_covariance"),
        target = source_grid$target,
        n_level = 10L,
        n_each = 8L,
        matrix_argument = if (identical(surface, "spatial")) {
          NA_character_
        } else {
          "precision"
        },
        rho_true = source_grid$rho_true,
        seed = switch(
          surface,
          spatial = c(5100L, 5140L, 5190L, 5198L),
          animal = c(6100L, 6140L, 6190L, 6198L),
          relmat = c(7100L, 7140L, 7190L, 7198L)
        ),
        stringsAsFactors = FALSE
      )
    }
  )
)
conditions$cell_id <- paste(conditions$surface, conditions$target, sep = "_")
conditions <- conditions[,
  c(
    "cell_id",
    "surface",
    "check_name",
    "target",
    "n_level",
    "n_each",
    "matrix_argument",
    "rho_true",
    "seed"
  )
]

condition_data <- function(cell) {
  if (identical(cell$surface[[1L]], "spatial")) {
    condition <- phase18_spatial_q2_conditions(
      n_site = cell$n_level[[1L]],
      n_each = cell$n_each[[1L]],
      geometry = "ring",
      rho_spatial = cell$rho_true[[1L]]
    )
    return(list(
      condition = condition[1L, , drop = FALSE],
      data = phase18_dgp_spatial_q2_cell(
        condition[1L, , drop = FALSE],
        seed = cell$seed[[1L]],
        cell_id = cell$cell_id[[1L]],
        replicate = 1L
      )
    ))
  }

  condition <- phase18_animal_relmat_q2_conditions(
    structured_surface = cell$surface[[1L]],
    matrix_argument = cell$matrix_argument[[1L]],
    n_level = cell$n_level[[1L]],
    n_per_level = cell$n_each[[1L]],
    rho_struct = cell$rho_true[[1L]]
  )
  list(
    condition = condition[1L, , drop = FALSE],
    data = phase18_dgp_animal_relmat_q2_cell(
      condition[1L, , drop = FALSE],
      seed = cell$seed[[1L]],
      cell_id = cell$cell_id[[1L]],
      replicate = 1L
    )
  )
}

fit_surface <- function(surface, data, condition) {
  if (identical(surface, "spatial")) {
    return(phase18_fit_spatial_q2(data, condition))
  }
  phase18_fit_animal_relmat_q2(data, condition)
}

surface_correlation <- function(surface, fit) {
  unname(fit$corpars[[surface]][[1L]])
}

component_sd_1 <- function(fit) {
  unname(fit$sdpars$mu[[1L]])
}

component_sd_2 <- function(fit) {
  unname(fit$sdpars$mu[[2L]])
}

fit_rows <- list()
check_rows <- list()
failure_rows <- list()

for (i in seq_len(nrow(conditions))) {
  cell <- conditions[i, , drop = FALSE]
  generated <- condition_data(cell)
  start_time <- proc.time()[["elapsed"]]
  result <- capture_fit(
    fit_surface(cell$surface[[1L]], generated$data, generated$condition)
  )
  elapsed <- proc.time()[["elapsed"]] - start_time
  fit <- result$value
  if (inherits(fit, "error")) {
    failure_rows[[length(failure_rows) + 1L]] <- data.frame(
      cell_id = cell$cell_id,
      surface = cell$surface,
      rho_true = cell$rho_true,
      stage = "fit",
      message = conditionMessage(fit),
      stringsAsFactors = FALSE
    )
    next
  }

  checks <- check_drm(fit, rho_boundary = rho_boundary)
  target_check <- cell$check_name[[1L]]
  rho_hat <- surface_correlation(cell$surface[[1L]], fit)
  eta_hat <- rho_link(rho_hat)

  fit_rows[[length(fit_rows) + 1L]] <- data.frame(
    cell_id = cell$cell_id,
    surface = cell$surface,
    check_name = target_check,
    target = cell$target,
    n_level = cell$n_level,
    n_each = cell$n_each,
    matrix_argument = cell$matrix_argument,
    seed = cell$seed,
    rho_true = cell$rho_true,
    eta_true_equivalent = rho_link(cell$rho_true),
    rho_hat = rho_hat,
    eta_hat = eta_hat,
    rho_error = rho_hat - cell$rho_true,
    eta_error = eta_hat - rho_link(cell$rho_true),
    boundary_distance = 1 - abs(rho_hat),
    one_minus_rho2 = 1 - rho_hat^2,
    guard_delta_at_eta_hat = tanh(eta_hat) - rho_response_local(eta_hat),
    delta_derivative_at_eta_hat = rho_guard * (1 - tanh(eta_hat)^2),
    component_sd_1 = component_sd_1(fit),
    component_sd_2 = component_sd_2(fit),
    converged = isTRUE(fit$opt$convergence == 0),
    convergence_code = as.integer(fit$opt$convergence),
    convergence_message = if (!is.null(fit$opt$message)) {
      fit$opt$message
    } else {
      NA_character_
    },
    iterations = if (!is.null(fit$opt$iterations)) {
      fit$opt$iterations
    } else {
      NA_integer_
    },
    function_evaluations = if (!is.null(fit$opt$evaluations)) {
      unname(fit$opt$evaluations[["function"]])
    } else {
      NA_integer_
    },
    gradient_evaluations = if (!is.null(fit$opt$evaluations)) {
      unname(fit$opt$evaluations[["gradient"]])
    } else {
      NA_integer_
    },
    pdHess = isTRUE(fit$sdr$pdHess),
    sdreport_status = check_status(checks, "sdreport_status"),
    max_abs_gradient = max_abs_gradient(fit),
    fixed_gradient_status = check_status(checks, "fixed_gradient"),
    fixed_gradient_value = check_value(checks, "fixed_gradient"),
    fixed_gradient_component = gradient_component(
      check_value(checks, "fixed_gradient")
    ),
    covariance_status = check_status(checks, target_check),
    covariance_value = check_value(checks, target_check),
    covariance_message = check_message(checks, target_check),
    objective = fit$opt$objective,
    logLik = as.numeric(stats::logLik(fit)),
    AIC = stats::AIC(fit),
    BIC = stats::BIC(fit),
    elapsed = elapsed,
    warning_count = length(result$warnings),
    warnings = paste(result$warnings, collapse = " | "),
    stringsAsFactors = FALSE
  )

  checks$cell_id <- cell$cell_id
  checks$surface <- cell$surface
  checks$rho_true <- cell$rho_true
  check_rows[[length(check_rows) + 1L]] <- checks[,
    c("cell_id", "surface", "rho_true", "check", "status", "value", "message"),
    drop = FALSE
  ]
}

fit_diagnostics <- if (length(fit_rows)) {
  do.call(rbind, fit_rows)
} else {
  data.frame()
}
check_drm_rows <- if (length(check_rows)) {
  do.call(rbind, check_rows)
} else {
  data.frame(
    cell_id = character(),
    surface = character(),
    rho_true = numeric(),
    check = character(),
    status = character(),
    value = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}
failures <- if (length(failure_rows)) {
  do.call(rbind, failure_rows)
} else {
  data.frame(
    cell_id = character(),
    surface = character(),
    rho_true = numeric(),
    stage = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}

exposure <- if (nrow(fit_diagnostics)) {
  data.frame(
    cell_id = fit_diagnostics$cell_id,
    surface = fit_diagnostics$surface,
    check_name = fit_diagnostics$check_name,
    target = fit_diagnostics$target,
    rho_true = fit_diagnostics$rho_true,
    guard_multiplier = rho_guard,
    rho_boundary = rho_boundary,
    true_abs_rho_max = abs(fit_diagnostics$rho_true),
    fit_abs_rho_max = abs(fit_diagnostics$rho_hat),
    min_1_minus_rho_sq = fit_diagnostics$one_minus_rho2,
    boundary_distance = fit_diagnostics$boundary_distance,
    n_abs_fit_rho_gt_0_90 = as.integer(abs(fit_diagnostics$rho_hat) > 0.90),
    n_abs_fit_rho_gt_0_95 = as.integer(abs(fit_diagnostics$rho_hat) > 0.95),
    n_abs_fit_rho_gt_0_98 = as.integer(abs(fit_diagnostics$rho_hat) > 0.98),
    n_abs_fit_rho_gt_0_99 = as.integer(abs(fit_diagnostics$rho_hat) > 0.99),
    covariance_status = fit_diagnostics$covariance_status,
    covariance_value = fit_diagnostics$covariance_value,
    covariance_message = fit_diagnostics$covariance_message,
    stringsAsFactors = FALSE
  )
} else {
  data.frame()
}

condition_summary <- data.frame(
  cell_id = conditions$cell_id,
  surface = conditions$surface,
  check_name = conditions$check_name,
  target = conditions$target,
  rho_true = conditions$rho_true,
  n_requested = 1L,
  n_attempted = 1L,
  n_fit_error = as.integer(conditions$cell_id %in% failures$cell_id),
  stringsAsFactors = FALSE
)
condition_summary$n_warning <- vapply(
  conditions$cell_id,
  function(cell_id) {
    row <- fit_diagnostics[fit_diagnostics$cell_id == cell_id, , drop = FALSE]
    if (!nrow(row)) 0L else as.integer(row$warning_count > 0L)
  },
  integer(1L)
)
condition_summary$n_converged <- vapply(
  conditions$cell_id,
  function(cell_id) {
    row <- fit_diagnostics[fit_diagnostics$cell_id == cell_id, , drop = FALSE]
    if (!nrow(row)) 0L else as.integer(isTRUE(row$converged[[1L]]))
  },
  integer(1L)
)
condition_summary$n_pdHess <- vapply(
  conditions$cell_id,
  function(cell_id) {
    row <- fit_diagnostics[fit_diagnostics$cell_id == cell_id, , drop = FALSE]
    if (!nrow(row)) 0L else as.integer(isTRUE(row$pdHess[[1L]]))
  },
  integer(1L)
)
condition_summary$n_gradient_ok <- vapply(
  conditions$cell_id,
  function(cell_id) {
    row <- fit_diagnostics[fit_diagnostics$cell_id == cell_id, , drop = FALSE]
    if (!nrow(row)) {
      0L
    } else {
      as.integer(identical(row$fixed_gradient_status[[1L]], "ok"))
    }
  },
  integer(1L)
)
condition_summary$n_check_drm_warning_or_error <- vapply(
  conditions$cell_id,
  function(cell_id) {
    sum(
      check_drm_rows$cell_id == cell_id &
        check_drm_rows$status %in% c("warning", "error")
    )
  },
  integer(1L)
)
condition_summary$n_covariance_warning <- vapply(
  conditions$cell_id,
  function(cell_id) {
    row <- fit_diagnostics[fit_diagnostics$cell_id == cell_id, , drop = FALSE]
    if (!nrow(row)) {
      0L
    } else {
      as.integer(identical(row$covariance_status[[1L]], "warning"))
    }
  },
  integer(1L)
)

surface_summary <- if (nrow(fit_diagnostics)) {
  do.call(
    rbind,
    lapply(split(fit_diagnostics, fit_diagnostics$surface), function(x) {
      data.frame(
        surface = x$surface[[1L]],
        n_fit_cells = nrow(x),
        n_converged = sum(x$converged),
        n_pdHess = sum(x$pdHess),
        n_gradient_ok = sum(x$fixed_gradient_status == "ok"),
        n_covariance_warnings = sum(x$covariance_status == "warning"),
        min_boundary_distance = min(x$boundary_distance, na.rm = TRUE),
        max_abs_rho_error = max(abs(x$rho_error), na.rm = TRUE),
        stringsAsFactors = FALSE
      )
    })
  )
} else {
  data.frame()
}
row.names(surface_summary) <- NULL

run_summary <- data.frame(
  timestamp_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  git_sha = git_value("rev-parse", "HEAD"),
  git_branch = git_value("branch", "--show-current"),
  git_dirty = length(git_lines("status", "--short")) > 0L,
  n_source_rows = nrow(source_grid),
  n_surfaces = length(unique(conditions$surface)),
  n_fit_cells = nrow(conditions),
  n_fit_errors = nrow(failures),
  n_converged = sum(fit_diagnostics$converged),
  n_pdHess = sum(fit_diagnostics$pdHess),
  n_converged_and_pdHess = sum(
    fit_diagnostics$converged & fit_diagnostics$pdHess
  ),
  n_gradient_ok = sum(fit_diagnostics$fixed_gradient_status == "ok"),
  n_check_drm_warning_or_error = sum(
    check_drm_rows$status %in% c("warning", "error")
  ),
  n_covariance_warnings = sum(fit_diagnostics$covariance_status == "warning"),
  max_abs_rho_error = if (nrow(fit_diagnostics)) {
    max(abs(fit_diagnostics$rho_error), na.rm = TRUE)
  } else {
    NA_real_
  },
  max_abs_gradient = if (nrow(fit_diagnostics)) {
    max(fit_diagnostics$max_abs_gradient, na.rm = TRUE)
  } else {
    NA_real_
  },
  min_boundary_distance = if (nrow(fit_diagnostics)) {
    min(fit_diagnostics$boundary_distance, na.rm = TRUE)
  } else {
    NA_real_
  },
  stringsAsFactors = FALSE
)

write.csv(
  source_grid,
  file.path(tables_dir, "structured-q2-boundary-source-grid.csv"),
  row.names = FALSE
)
write.csv(
  conditions,
  file.path(tables_dir, "structured-q2-boundary-conditions.csv"),
  row.names = FALSE
)
write.csv(
  fit_diagnostics,
  file.path(tables_dir, "structured-q2-boundary-fit-diagnostics.csv"),
  row.names = FALSE
)
write.csv(
  exposure,
  file.path(tables_dir, "structured-q2-boundary-exposure.csv"),
  row.names = FALSE
)
write.csv(
  condition_summary,
  file.path(tables_dir, "structured-q2-boundary-condition-summary.csv"),
  row.names = FALSE
)
write.csv(
  surface_summary,
  file.path(tables_dir, "structured-q2-boundary-surface-summary.csv"),
  row.names = FALSE
)
write.csv(
  check_drm_rows,
  file.path(tables_dir, "structured-q2-boundary-check-drm.csv"),
  row.names = FALSE
)
write.csv(
  failures,
  file.path(tables_dir, "structured-q2-boundary-failures.csv"),
  row.names = FALSE
)
write.csv(
  run_summary,
  file.path(tables_dir, "structured-q2-boundary-run-summary.csv"),
  row.names = FALSE
)

session_path <- file.path(artifact_dir, "session-info.txt")
zz <- file(session_path, open = "wt")
sink(zz)
cat("Command:\n")
cat(paste(commandArgs(), collapse = " "), "\n\n")
cat("Git status:\n")
cat(paste(git_lines("status", "--short", "--branch"), collapse = "\n"))
cat("\n\nGit log:\n")
cat(paste(git_lines("log", "--oneline", "-3"), collapse = "\n"))
cat("\n\nSession info:\n")
print(utils::sessionInfo())
sink()
close(zz)

print(run_summary)
