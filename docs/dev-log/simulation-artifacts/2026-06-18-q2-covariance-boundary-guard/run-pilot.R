args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "docs/dev-log/simulation-artifacts/2026-06-18-q2-covariance-boundary-guard/run-pilot.R",
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

master_seed <- 20260618L
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

q2_covariance_data <- function(
  n_id = 34L,
  n_each = 8L,
  rho = 0.4,
  seed = 1L
) {
  set.seed(seed)
  n <- n_id * n_each
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  u_mu <- stats::rnorm(n_id)
  u_sigma <- rho * u_mu + sqrt(1 - rho^2) * stats::rnorm(n_id)
  mu <- 0.2 + 0.45 * x + 0.55 * u_mu[id]
  sigma <- exp(log(0.55) + 0.18 * z + 0.28 * u_sigma[id])
  data.frame(
    y = stats::rnorm(n, mean = mu, sd = sigma),
    x = x,
    z = z,
    id = id,
    stringsAsFactors = FALSE
  )
}

conditions <- data.frame(
  cell_id = c(
    "q2_mu_sigma_zero",
    "q2_mu_sigma_moderate",
    "q2_mu_sigma_high",
    "q2_mu_sigma_boundary"
  ),
  n_id = 34L,
  n_each = 8L,
  rho_true = c(0, 0.4, 0.9, 0.98),
  seed = master_seed + seq_len(4L),
  stringsAsFactors = FALSE
)

fit_rows <- list()
check_rows <- list()
failure_rows <- list()

for (i in seq_len(nrow(conditions))) {
  cell <- conditions[i, , drop = FALSE]
  data <- q2_covariance_data(
    n_id = cell$n_id[[1L]],
    n_each = cell$n_each[[1L]],
    rho = cell$rho_true[[1L]],
    seed = cell$seed[[1L]]
  )
  start_time <- proc.time()[["elapsed"]]
  result <- capture_fit(
    drmTMB(
      bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id)),
      family = gaussian(),
      data = data
    )
  )
  elapsed <- proc.time()[["elapsed"]] - start_time
  fit <- result$value
  if (inherits(fit, "error")) {
    failure_rows[[length(failure_rows) + 1L]] <- data.frame(
      cell_id = cell$cell_id,
      rho_true = cell$rho_true,
      stage = "fit",
      message = conditionMessage(fit),
      stringsAsFactors = FALSE
    )
    next
  }

  checks <- check_drm(fit, rho_boundary = rho_boundary)
  cov_value <- check_value(checks, "mu_sigma_random_effect_covariance")
  rho_hat <- unname(fit$corpars$mu_sigma[[1L]])
  eta_hat <- rho_link(rho_hat)

  fit_rows[[length(fit_rows) + 1L]] <- data.frame(
    cell_id = cell$cell_id,
    n_id = cell$n_id,
    n_each = cell$n_each,
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
    sd_mu = unname(fit$sdpars$mu[[1L]]),
    sd_sigma = unname(fit$sdpars$sigma[[1L]]),
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
    q2_covariance_status = check_status(
      checks,
      "mu_sigma_random_effect_covariance"
    ),
    q2_covariance_value = cov_value,
    q2_covariance_message = check_message(
      checks,
      "mu_sigma_random_effect_covariance"
    ),
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
  checks$rho_true <- cell$rho_true
  check_rows[[length(check_rows) + 1L]] <- checks[,
    c("cell_id", "rho_true", "check", "status", "value", "message"),
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
    rho_true = numeric(),
    stage = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}

exposure <- if (nrow(fit_diagnostics)) {
  data.frame(
    cell_id = fit_diagnostics$cell_id,
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
    q2_covariance_status = fit_diagnostics$q2_covariance_status,
    q2_covariance_value = fit_diagnostics$q2_covariance_value,
    q2_covariance_message = fit_diagnostics$q2_covariance_message,
    stringsAsFactors = FALSE
  )
} else {
  data.frame()
}

condition_summary <- if (nrow(conditions)) {
  data.frame(
    cell_id = conditions$cell_id,
    rho_true = conditions$rho_true,
    n_requested = 1L,
    n_attempted = 1L,
    n_fit_error = as.integer(conditions$cell_id %in% failures$cell_id),
    n_warning = vapply(
      conditions$cell_id,
      function(cell_id) {
        if (!nrow(fit_diagnostics)) {
          return(0L)
        }
        row <- fit_diagnostics[
          fit_diagnostics$cell_id == cell_id,
          ,
          drop = FALSE
        ]
        if (!nrow(row)) 0L else as.integer(row$warning_count > 0L)
      },
      integer(1L)
    ),
    n_converged = vapply(
      conditions$cell_id,
      function(cell_id) {
        row <- fit_diagnostics[
          fit_diagnostics$cell_id == cell_id,
          ,
          drop = FALSE
        ]
        if (!nrow(row)) 0L else as.integer(isTRUE(row$converged[[1L]]))
      },
      integer(1L)
    ),
    n_pdHess = vapply(
      conditions$cell_id,
      function(cell_id) {
        row <- fit_diagnostics[
          fit_diagnostics$cell_id == cell_id,
          ,
          drop = FALSE
        ]
        if (!nrow(row)) 0L else as.integer(isTRUE(row$pdHess[[1L]]))
      },
      integer(1L)
    ),
    n_converged_and_pdHess = vapply(
      conditions$cell_id,
      function(cell_id) {
        row <- fit_diagnostics[
          fit_diagnostics$cell_id == cell_id,
          ,
          drop = FALSE
        ]
        if (!nrow(row)) {
          return(0L)
        }
        as.integer(isTRUE(row$converged[[1L]]) && isTRUE(row$pdHess[[1L]]))
      },
      integer(1L)
    ),
    n_gradient_ok = vapply(
      conditions$cell_id,
      function(cell_id) {
        row <- fit_diagnostics[
          fit_diagnostics$cell_id == cell_id,
          ,
          drop = FALSE
        ]
        if (!nrow(row)) {
          0L
        } else {
          as.integer(identical(row$fixed_gradient_status[[1L]], "ok"))
        }
      },
      integer(1L)
    ),
    n_check_drm_warning_or_error = vapply(
      conditions$cell_id,
      function(cell_id) {
        rows <- check_drm_rows[
          check_drm_rows$cell_id == cell_id,
          ,
          drop = FALSE
        ]
        as.integer(any(rows$status %in% c("warning", "error")))
      },
      integer(1L)
    ),
    stringsAsFactors = FALSE
  )
} else {
  data.frame()
}

run_summary <- data.frame(
  artifact = basename(artifact_dir),
  master_seed = master_seed,
  timestamp_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  git_sha = git_value("rev-parse", "HEAD"),
  git_branch = git_value("branch", "--show-current"),
  git_dirty = any(nzchar(git_lines("status", "--porcelain"))),
  command = paste(commandArgs(trailingOnly = FALSE), collapse = " "),
  n_source_rows = nrow(source_grid),
  n_fit_cells = nrow(conditions),
  n_fit_errors = nrow(failures),
  n_converged = if (nrow(fit_diagnostics)) {
    sum(fit_diagnostics$converged)
  } else {
    0L
  },
  n_pdHess = if (nrow(fit_diagnostics)) sum(fit_diagnostics$pdHess) else 0L,
  n_converged_and_pdHess = if (nrow(condition_summary)) {
    sum(condition_summary$n_converged_and_pdHess)
  } else {
    0L
  },
  n_gradient_ok = if (nrow(condition_summary)) {
    sum(condition_summary$n_gradient_ok)
  } else {
    0L
  },
  n_check_drm_warning_or_error = if (nrow(condition_summary)) {
    sum(condition_summary$n_check_drm_warning_or_error)
  } else {
    0L
  },
  n_q2_covariance_warnings = sum(
    check_drm_rows$check == "mu_sigma_random_effect_covariance" &
      check_drm_rows$status == "warning"
  ),
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
  file.path(tables_dir, "q2-covariance-boundary-source-grid.csv"),
  row.names = FALSE
)
write.csv(
  conditions,
  file.path(tables_dir, "q2-covariance-boundary-conditions.csv"),
  row.names = FALSE
)
write.csv(
  fit_diagnostics,
  file.path(tables_dir, "q2-covariance-boundary-fit-diagnostics.csv"),
  row.names = FALSE
)
write.csv(
  exposure,
  file.path(tables_dir, "q2-covariance-boundary-exposure.csv"),
  row.names = FALSE
)
write.csv(
  condition_summary,
  file.path(tables_dir, "q2-covariance-boundary-condition-summary.csv"),
  row.names = FALSE
)
write.csv(
  check_drm_rows,
  file.path(tables_dir, "q2-covariance-boundary-check-drm.csv"),
  row.names = FALSE
)
write.csv(
  failures,
  file.path(tables_dir, "q2-covariance-boundary-failures.csv"),
  row.names = FALSE
)
write.csv(
  run_summary,
  file.path(artifact_dir, "q2-covariance-boundary-run-summary.csv"),
  row.names = FALSE
)
session_info <- sub("[[:space:]]+$", "", capture.output(sessionInfo()))
writeLines(
  c(
    paste0("artifact: ", basename(artifact_dir)),
    paste0("timestamp_utc: ", run_summary$timestamp_utc),
    paste0("git_sha: ", run_summary$git_sha),
    paste0("git_branch: ", run_summary$git_branch),
    paste0("git_dirty: ", run_summary$git_dirty),
    paste0("command: ", run_summary$command),
    "",
    session_info
  ),
  file.path(artifact_dir, "session-info.txt")
)

cat("q2 covariance boundary guard diagnostic complete\n")
print(run_summary)
