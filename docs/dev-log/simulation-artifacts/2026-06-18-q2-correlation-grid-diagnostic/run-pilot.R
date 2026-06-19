args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "docs/dev-log/simulation-artifacts/2026-06-18-q2-correlation-grid-diagnostic/run-pilot.R",
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

correlated_effects <- function(n_id, rho) {
  u1 <- stats::rnorm(n_id)
  u2 <- rho * u1 + sqrt(1 - rho^2) * stats::rnorm(n_id)
  list(u1 = u1, u2 = u2)
}

univ_mu_sigma_data <- function(n_id, n_each, rho, seed) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  u <- correlated_effects(n_id, rho)
  mu <- 0.2 + 0.45 * x + 0.55 * u$u1[id]
  sigma <- exp(log(0.55) + 0.18 * z + 0.28 * u$u2[id])
  data.frame(
    y = stats::rnorm(n, mean = mu, sd = sigma),
    x = x,
    z = z,
    id = id,
    stringsAsFactors = FALSE
  )
}

biv_mu_data <- function(n_id, n_each, rho, seed) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  u <- correlated_effects(n_id, rho)
  e1 <- stats::rnorm(n)
  e2 <- 0.15 * e1 + sqrt(1 - 0.15^2) * stats::rnorm(n)
  data.frame(
    y1 = 0.2 + 0.4 * x + 0.55 * u$u1[id] + 0.35 * e1,
    y2 = -0.1 - 0.3 * x + 0.50 * u$u2[id] + 0.38 * e2,
    x = x,
    id = id,
    stringsAsFactors = FALSE
  )
}

biv_sigma_data <- function(n_id, n_each, rho, seed) {
  set.seed(seed)
  id <- factor(rep(seq_len(n_id), each = n_each))
  n <- length(id)
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  u <- correlated_effects(n_id, rho)
  e1 <- stats::rnorm(n)
  e2 <- 0.10 * e1 + sqrt(1 - 0.10^2) * stats::rnorm(n)
  sigma1 <- exp(log(0.45) + 0.10 * z + 0.22 * u$u1[id])
  sigma2 <- exp(log(0.50) - 0.08 * z + 0.22 * u$u2[id])
  data.frame(
    y1 = 0.2 + 0.35 * x + sigma1 * e1,
    y2 = -0.1 - 0.25 * x + sigma2 * e2,
    x = x,
    z = z,
    id = id,
    stringsAsFactors = FALSE
  )
}

fit_route <- function(route, data) {
  if (identical(route, "univ_mu_sigma")) {
    return(drmTMB(
      bf(y ~ x + (1 | p | id), sigma ~ z + (1 | p | id)),
      family = gaussian(),
      data = data
    ))
  }
  if (identical(route, "biv_mu")) {
    return(drmTMB(
      bf(
        mu1 = y1 ~ x + (1 | p | id),
        mu2 = y2 ~ x + (1 | p | id),
        sigma1 = ~1,
        sigma2 = ~1,
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = data
    ))
  }
  if (identical(route, "biv_sigma")) {
    return(drmTMB(
      bf(
        mu1 = y1 ~ x,
        mu2 = y2 ~ x,
        sigma1 = ~ z + (1 | p | id),
        sigma2 = ~ z + (1 | p | id),
        rho12 = ~1
      ),
      family = biv_gaussian(),
      data = data
    ))
  }
  stop("Unknown route: ", route)
}

route_data <- function(route, n_id, n_each, rho, seed) {
  if (identical(route, "univ_mu_sigma")) {
    return(univ_mu_sigma_data(n_id, n_each, rho, seed))
  }
  if (identical(route, "biv_mu")) {
    return(biv_mu_data(n_id, n_each, rho, seed))
  }
  if (identical(route, "biv_sigma")) {
    return(biv_sigma_data(n_id, n_each, rho, seed))
  }
  stop("Unknown route: ", route)
}

route_check <- function(route) {
  switch(
    route,
    univ_mu_sigma = "mu_sigma_random_effect_covariance",
    biv_mu = "biv_mu_random_effect_covariance",
    biv_sigma = "biv_sigma_random_effect_covariance",
    stop("Unknown route: ", route)
  )
}

route_correlation <- function(route, fit) {
  switch(
    route,
    univ_mu_sigma = unname(fit$corpars$mu_sigma[[1L]]),
    biv_mu = unname(fit$corpars$mu[[1L]]),
    biv_sigma = unname(fit$corpars$sigma[[1L]]),
    stop("Unknown route: ", route)
  )
}

route_sd_1 <- function(route, fit) {
  switch(
    route,
    univ_mu_sigma = unname(fit$sdpars$mu[[1L]]),
    biv_mu = unname(fit$sdpars$mu[[1L]]),
    biv_sigma = unname(fit$sdpars$sigma[[1L]]),
    stop("Unknown route: ", route)
  )
}

route_sd_2 <- function(route, fit) {
  switch(
    route,
    univ_mu_sigma = unname(fit$sdpars$sigma[[1L]]),
    biv_mu = unname(fit$sdpars$mu[[2L]]),
    biv_sigma = unname(fit$sdpars$sigma[[2L]]),
    stop("Unknown route: ", route)
  )
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
  list(
    data.frame(
      route = "univ_mu_sigma",
      check_name = route_check("univ_mu_sigma"),
      covariance_route = "univariate mu/sigma random intercept",
      n_id = 34L,
      n_each = 8L,
      rho_true = source_grid$rho_true,
      seed = c(2000L, 2040L, 2090L, 2098L),
      stringsAsFactors = FALSE
    ),
    data.frame(
      route = "biv_mu",
      check_name = route_check("biv_mu"),
      covariance_route = "bivariate mu1/mu2 random intercept",
      n_id = 36L,
      n_each = 8L,
      rho_true = source_grid$rho_true,
      seed = c(3000L, 3040L, 3090L, 3098L),
      stringsAsFactors = FALSE
    ),
    data.frame(
      route = "biv_sigma",
      check_name = route_check("biv_sigma"),
      covariance_route = "bivariate sigma1/sigma2 random intercept",
      n_id = 40L,
      n_each = 10L,
      rho_true = source_grid$rho_true,
      seed = c(4000L, 4040L, 4090L, 4098L),
      stringsAsFactors = FALSE
    )
  )
)
conditions$target <- rep(source_grid$target, times = 3L)
conditions$cell_id <- paste(conditions$route, conditions$target, sep = "_")
conditions <- conditions[,
  c(
    "cell_id",
    "route",
    "check_name",
    "covariance_route",
    "target",
    "n_id",
    "n_each",
    "rho_true",
    "seed"
  )
]

fit_rows <- list()
check_rows <- list()
failure_rows <- list()

for (i in seq_len(nrow(conditions))) {
  cell <- conditions[i, , drop = FALSE]
  data <- route_data(
    route = cell$route[[1L]],
    n_id = cell$n_id[[1L]],
    n_each = cell$n_each[[1L]],
    rho = cell$rho_true[[1L]],
    seed = cell$seed[[1L]]
  )
  start_time <- proc.time()[["elapsed"]]
  result <- capture_fit(fit_route(cell$route[[1L]], data))
  elapsed <- proc.time()[["elapsed"]] - start_time
  fit <- result$value
  if (inherits(fit, "error")) {
    failure_rows[[length(failure_rows) + 1L]] <- data.frame(
      cell_id = cell$cell_id,
      route = cell$route,
      rho_true = cell$rho_true,
      stage = "fit",
      message = conditionMessage(fit),
      stringsAsFactors = FALSE
    )
    next
  }

  checks <- check_drm(fit, rho_boundary = rho_boundary)
  target_check <- cell$check_name[[1L]]
  covariance_value <- check_value(checks, target_check)
  rho_hat <- route_correlation(cell$route[[1L]], fit)
  eta_hat <- rho_link(rho_hat)

  fit_rows[[length(fit_rows) + 1L]] <- data.frame(
    cell_id = cell$cell_id,
    route = cell$route,
    check_name = target_check,
    covariance_route = cell$covariance_route,
    target = cell$target,
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
    component_sd_1 = route_sd_1(cell$route[[1L]], fit),
    component_sd_2 = route_sd_2(cell$route[[1L]], fit),
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
    covariance_value = covariance_value,
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
  checks$route <- cell$route
  checks$rho_true <- cell$rho_true
  check_rows[[length(check_rows) + 1L]] <- checks[,
    c("cell_id", "route", "rho_true", "check", "status", "value", "message"),
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
    route = character(),
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
    route = character(),
    rho_true = numeric(),
    stage = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}

exposure <- if (nrow(fit_diagnostics)) {
  data.frame(
    cell_id = fit_diagnostics$cell_id,
    route = fit_diagnostics$route,
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

condition_summary <- if (nrow(conditions)) {
  data.frame(
    cell_id = conditions$cell_id,
    route = conditions$route,
    check_name = conditions$check_name,
    target = conditions$target,
    rho_true = conditions$rho_true,
    n_requested = 1L,
    n_attempted = 1L,
    n_fit_error = as.integer(conditions$cell_id %in% failures$cell_id),
    n_warning = vapply(
      conditions$cell_id,
      function(cell_id) {
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
    n_covariance_warning = vapply(
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
          as.integer(identical(row$covariance_status[[1L]], "warning"))
        }
      },
      integer(1L)
    ),
    stringsAsFactors = FALSE
  )
} else {
  data.frame()
}

route_summary <- if (nrow(fit_diagnostics)) {
  do.call(
    rbind,
    lapply(unique(fit_diagnostics$route), function(route) {
      rows <- fit_diagnostics[fit_diagnostics$route == route, , drop = FALSE]
      summary_rows <- condition_summary[
        condition_summary$route == route,
        ,
        drop = FALSE
      ]
      data.frame(
        route = route,
        check_name = rows$check_name[[1L]],
        n_fit = nrow(rows),
        n_converged = sum(rows$converged, na.rm = TRUE),
        n_pdHess = sum(rows$pdHess, na.rm = TRUE),
        n_gradient_ok = sum(rows$fixed_gradient_status == "ok", na.rm = TRUE),
        n_check_drm_warning_or_error = sum(
          summary_rows$n_check_drm_warning_or_error,
          na.rm = TRUE
        ),
        n_covariance_warning = sum(
          rows$covariance_status == "warning",
          na.rm = TRUE
        ),
        n_r_warning = sum(rows$warning_count > 0L, na.rm = TRUE),
        max_abs_fit_rho = max(abs(rows$rho_hat), na.rm = TRUE),
        min_boundary_distance = min(rows$boundary_distance, na.rm = TRUE),
        max_abs_gradient = max(rows$max_abs_gradient, na.rm = TRUE),
        stringsAsFactors = FALSE
      )
    })
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
  n_routes = length(unique(conditions$route)),
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
  n_covariance_warnings = if (nrow(condition_summary)) {
    sum(condition_summary$n_covariance_warning)
  } else {
    0L
  },
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
  file.path(tables_dir, "q2-correlation-grid-source-grid.csv"),
  row.names = FALSE
)
write.csv(
  conditions,
  file.path(tables_dir, "q2-correlation-grid-conditions.csv"),
  row.names = FALSE
)
write.csv(
  fit_diagnostics,
  file.path(tables_dir, "q2-correlation-grid-fit-diagnostics.csv"),
  row.names = FALSE
)
write.csv(
  exposure,
  file.path(tables_dir, "q2-correlation-grid-exposure.csv"),
  row.names = FALSE
)
write.csv(
  condition_summary,
  file.path(tables_dir, "q2-correlation-grid-condition-summary.csv"),
  row.names = FALSE
)
write.csv(
  route_summary,
  file.path(tables_dir, "q2-correlation-grid-route-summary.csv"),
  row.names = FALSE
)
write.csv(
  check_drm_rows,
  file.path(tables_dir, "q2-correlation-grid-check-drm.csv"),
  row.names = FALSE
)
write.csv(
  failures,
  file.path(tables_dir, "q2-correlation-grid-failures.csv"),
  row.names = FALSE
)
write.csv(
  run_summary,
  file.path(artifact_dir, "q2-correlation-grid-run-summary.csv"),
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

cat("q2 correlation grid diagnostic complete\n")
print(run_summary)
