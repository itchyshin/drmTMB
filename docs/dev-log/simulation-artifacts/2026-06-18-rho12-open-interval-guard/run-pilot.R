args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "docs/dev-log/simulation-artifacts/2026-06-18-rho12-open-interval-guard/run-pilot.R",
    mustWork = TRUE
  )
}

artifact_dir <- dirname(script_path)
repo_root <- normalizePath(file.path(artifact_dir, "../../../.."), mustWork = TRUE)
tables_dir <- file.path(artifact_dir, "tables")
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages(devtools::load_all(repo_root, quiet = TRUE))

master_seed <- 20260618L
rho_guard <- 0.999999

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

rho_source_grid <- data.frame(
  target = c("zero", "moderate", "high", "default_boundary"),
  rho_true = c(0, 0.4, 0.9, 0.98),
  stringsAsFactors = FALSE
)
rho_source_grid$eta_equivalent <- rho_link(rho_source_grid$rho_true)
rho_source_grid$rho_guarded <- rho_response_local(rho_source_grid$eta_equivalent)
rho_source_grid$rho_unguarded <- tanh(rho_source_grid$eta_equivalent)
rho_source_grid$guard_delta <- rho_source_grid$rho_unguarded -
  rho_source_grid$rho_guarded
rho_source_grid$boundary_distance <- 1 - abs(rho_source_grid$rho_guarded)
rho_source_grid$one_minus_rho2 <- 1 - rho_source_grid$rho_guarded^2
rho_source_grid$delta_derivative <- rho_guard *
  (1 - tanh(rho_source_grid$eta_equivalent)^2)

rho_data <- function(n, rho, seed) {
  set.seed(seed)
  x <- stats::rnorm(n)
  e1 <- stats::rnorm(n)
  e2 <- rho * e1 + sqrt(1 - rho^2) * stats::rnorm(n)
  data.frame(
    y1 = 0.20 + 0.50 * x + e1,
    y2 = -0.10 - 0.30 * x + e2,
    x = x,
    stringsAsFactors = FALSE
  )
}

ols_residual_correlation <- function(data) {
  X <- stats::model.matrix(~x, data)
  coef1 <- stats::lm.fit(x = X, y = data$y1)$coefficients
  coef2 <- stats::lm.fit(x = X, y = data$y2)$coefficients
  coef1[is.na(coef1)] <- 0
  coef2[is.na(coef2)] <- 0
  resid1 <- data$y1 - as.vector(X %*% coef1)
  resid2 <- data$y2 - as.vector(X %*% coef2)
  rho <- suppressWarnings(stats::cor(resid1, resid2))
  if (!is.finite(rho)) {
    return(0)
  }
  rho
}

conditions <- data.frame(
  cell_id = c(
    "rho12_zero",
    "rho12_moderate",
    "rho12_high",
    "rho12_default_boundary"
  ),
  n = 160L,
  rho_true = c(0, 0.4, 0.9, 0.98),
  seed = master_seed + seq_len(4L),
  stringsAsFactors = FALSE
)

fit_rows <- list()
check_rows <- list()
failure_rows <- list()

for (i in seq_len(nrow(conditions))) {
  cell <- conditions[i, , drop = FALSE]
  data <- rho_data(cell$n[[1L]], cell$rho_true[[1L]], cell$seed[[1L]])
  raw_start_rho <- ols_residual_correlation(data)
  clamped_start_rho <- max(min(raw_start_rho, 0.8), -0.8)
  start_time <- proc.time()[["elapsed"]]
  result <- capture_fit(
    drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      ),
      family = biv_gaussian(),
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

  checks <- check_drm(fit)
  report <- fit$obj$report()
  eta_report <- if ("eta_rho12" %in% names(report)) report$eta_rho12 else NA_real_
  rho_report <- if ("rho12" %in% names(report)) report$rho12 else NA_real_
  eta_hat <- unname(coef(fit, dpar = "rho12")[[1L]])
  rho_hat <- unname(rho12(fit)[[1L]])
  start_eta <- unname(fit$model$start$beta_rho12[[1L]])
  fixed_gradient_value <- check_value(checks, "fixed_gradient")
  rho12_boundary_value <- check_value(checks, "rho12_boundary")

  fit_rows[[length(fit_rows) + 1L]] <- data.frame(
    cell_id = cell$cell_id,
    n = cell$n,
    seed = cell$seed,
    rho_true = cell$rho_true,
    eta_true_equivalent = rho_link(cell$rho_true),
    raw_start_rho = raw_start_rho,
    clamped_start_rho = clamped_start_rho,
    start_clamped = !isTRUE(all.equal(raw_start_rho, clamped_start_rho)),
    start_eta = start_eta,
    start_rho_guarded = rho_response_local(start_eta),
    rho_hat = rho_hat,
    eta_hat = eta_hat,
    rho_error = rho_hat - cell$rho_true,
    eta_error = eta_hat - rho_link(cell$rho_true),
    max_reported_rho = suppressWarnings(max(abs(rho_report), na.rm = TRUE)),
    min_reported_one_minus_rho2 = suppressWarnings(min(1 - rho_report^2, na.rm = TRUE)),
    boundary_distance = 1 - abs(rho_hat),
    guard_delta_at_eta_hat = tanh(eta_hat) - rho_response_local(eta_hat),
    delta_derivative_at_eta_hat = rho_guard * (1 - tanh(eta_hat)^2),
    converged = isTRUE(fit$opt$convergence == 0),
    convergence_code = as.integer(fit$opt$convergence),
    convergence_message = if (!is.null(fit$opt$message)) fit$opt$message else NA_character_,
    iterations = if (!is.null(fit$opt$iterations)) fit$opt$iterations else NA_integer_,
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
    fixed_gradient_value = fixed_gradient_value,
    fixed_gradient_component = gradient_component(fixed_gradient_value),
    objective = fit$opt$objective,
    logLik = as.numeric(stats::logLik(fit)),
    AIC = stats::AIC(fit),
    BIC = stats::BIC(fit),
    elapsed = elapsed,
    warning_count = length(result$warnings),
    warnings = paste(result$warnings, collapse = " | "),
    rho12_boundary_status = check_status(checks, "rho12_boundary"),
    rho12_boundary_value = rho12_boundary_value,
    rho12_boundary_message = check_message(checks, "rho12_boundary"),
    fixed_gradient_status = check_status(checks, "fixed_gradient"),
    hessian_status = check_status(checks, "hessian_positive_definite"),
    standard_errors_status = check_status(checks, "standard_errors_finite"),
    stringsAsFactors = FALSE
  )
  checks$cell_id <- cell$cell_id
  checks$rho_true <- cell$rho_true
  check_rows[[length(check_rows) + 1L]] <- checks[
    ,
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

rho12_exposure <- if (nrow(fit_diagnostics)) {
  data.frame(
    cell_id = fit_diagnostics$cell_id,
    rho_true = fit_diagnostics$rho_true,
    guard_multiplier = rho_guard,
    true_eta_rho12_min = fit_diagnostics$eta_true_equivalent,
    true_eta_rho12_max = fit_diagnostics$eta_true_equivalent,
    true_abs_rho12_max = abs(fit_diagnostics$rho_true),
    fit_eta_rho12_min = fit_diagnostics$eta_hat,
    fit_eta_rho12_max = fit_diagnostics$eta_hat,
    fit_abs_rho12_max = abs(fit_diagnostics$rho_hat),
    min_1_minus_rho12_sq = fit_diagnostics$min_reported_one_minus_rho2,
    n_abs_fit_rho12_gt_0_90 = as.integer(abs(fit_diagnostics$rho_hat) > 0.90),
    n_abs_fit_rho12_gt_0_95 = as.integer(abs(fit_diagnostics$rho_hat) > 0.95),
    n_abs_fit_rho12_gt_0_98 = as.integer(abs(fit_diagnostics$rho_hat) > 0.98),
    n_abs_fit_rho12_gt_0_99 = as.integer(abs(fit_diagnostics$rho_hat) > 0.99),
    rho12_boundary_status = fit_diagnostics$rho12_boundary_status,
    rho12_boundary_value = fit_diagnostics$rho12_boundary_value,
    rho12_boundary_message = fit_diagnostics$rho12_boundary_message,
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
    n_warning = vapply(conditions$cell_id, function(cell_id) {
      if (!nrow(fit_diagnostics)) {
        return(0L)
      }
      row <- fit_diagnostics[fit_diagnostics$cell_id == cell_id, , drop = FALSE]
      if (!nrow(row)) 0L else as.integer(row$warning_count > 0L)
    }, integer(1L)),
    n_converged = vapply(conditions$cell_id, function(cell_id) {
      row <- fit_diagnostics[fit_diagnostics$cell_id == cell_id, , drop = FALSE]
      if (!nrow(row)) 0L else as.integer(isTRUE(row$converged[[1L]]))
    }, integer(1L)),
    n_pdHess = vapply(conditions$cell_id, function(cell_id) {
      row <- fit_diagnostics[fit_diagnostics$cell_id == cell_id, , drop = FALSE]
      if (!nrow(row)) 0L else as.integer(isTRUE(row$pdHess[[1L]]))
    }, integer(1L)),
    n_converged_and_pdHess = vapply(conditions$cell_id, function(cell_id) {
      row <- fit_diagnostics[fit_diagnostics$cell_id == cell_id, , drop = FALSE]
      if (!nrow(row)) {
        return(0L)
      }
      as.integer(isTRUE(row$converged[[1L]]) && isTRUE(row$pdHess[[1L]]))
    }, integer(1L)),
    n_gradient_ok = vapply(conditions$cell_id, function(cell_id) {
      row <- fit_diagnostics[fit_diagnostics$cell_id == cell_id, , drop = FALSE]
      if (!nrow(row)) 0L else as.integer(identical(row$fixed_gradient_status[[1L]], "ok"))
    }, integer(1L)),
    n_check_drm_warning_or_error = vapply(conditions$cell_id, function(cell_id) {
      rows <- check_drm_rows[check_drm_rows$cell_id == cell_id, , drop = FALSE]
      as.integer(any(rows$status %in% c("warning", "error")))
    }, integer(1L)),
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
  n_source_rows = nrow(rho_source_grid),
  n_fit_cells = nrow(conditions),
  n_fit_errors = nrow(failures),
  n_converged = if (nrow(fit_diagnostics)) sum(fit_diagnostics$converged) else 0L,
  n_pdHess = if (nrow(fit_diagnostics)) sum(fit_diagnostics$pdHess) else 0L,
  n_converged_and_pdHess = if (nrow(condition_summary)) {
    sum(condition_summary$n_converged_and_pdHess)
  } else {
    0L
  },
  n_gradient_ok = if (nrow(condition_summary)) sum(condition_summary$n_gradient_ok) else 0L,
  n_check_drm_warning_or_error = if (nrow(condition_summary)) {
    sum(condition_summary$n_check_drm_warning_or_error)
  } else {
    0L
  },
  n_start_clamped = if (nrow(fit_diagnostics)) sum(fit_diagnostics$start_clamped) else 0L,
  n_rho12_boundary_warnings = sum(
    check_drm_rows$check == "rho12_boundary" &
      check_drm_rows$status == "warning"
  ),
  n_fixed_gradient_warnings = sum(
    check_drm_rows$check == "fixed_gradient" &
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
  rho_source_grid,
  file.path(tables_dir, "rho12-open-interval-source-grid.csv"),
  row.names = FALSE
)
write.csv(
  conditions,
  file.path(tables_dir, "rho12-open-interval-conditions.csv"),
  row.names = FALSE
)
write.csv(
  fit_diagnostics,
  file.path(tables_dir, "rho12-open-interval-fit-diagnostics.csv"),
  row.names = FALSE
)
write.csv(
  rho12_exposure,
  file.path(tables_dir, "rho12-open-interval-exposure.csv"),
  row.names = FALSE
)
write.csv(
  condition_summary,
  file.path(tables_dir, "rho12-open-interval-condition-summary.csv"),
  row.names = FALSE
)
write.csv(
  check_drm_rows,
  file.path(tables_dir, "rho12-open-interval-check-drm.csv"),
  row.names = FALSE
)
write.csv(
  failures,
  file.path(tables_dir, "rho12-open-interval-failures.csv"),
  row.names = FALSE
)
write.csv(
  run_summary,
  file.path(artifact_dir, "rho12-open-interval-run-summary.csv"),
  row.names = FALSE
)
writeLines(
  c(
    paste0("artifact: ", basename(artifact_dir)),
    paste0("timestamp_utc: ", run_summary$timestamp_utc),
    paste0("git_sha: ", run_summary$git_sha),
    paste0("git_branch: ", run_summary$git_branch),
    paste0("git_dirty: ", run_summary$git_dirty),
    paste0("command: ", run_summary$command),
    "",
    paste(capture.output(sessionInfo()), collapse = "\n")
  ),
  file.path(artifact_dir, "session-info.txt")
)

cat("rho12 open-interval guard diagnostic complete\n")
print(run_summary)
