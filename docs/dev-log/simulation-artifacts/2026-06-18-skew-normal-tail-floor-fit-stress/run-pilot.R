args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "docs/dev-log/simulation-artifacts/2026-06-18-skew-normal-tail-floor-fit-stress/run-pilot.R",
    mustWork = TRUE
  )
}

artifact_dir <- dirname(script_path)
tables_dir <- file.path(artifact_dir, "tables")
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages(devtools::load_all(".", quiet = TRUE))
source(system.file("sim/R/sim_registry.R", package = "drmTMB", mustWork = TRUE))
source(system.file("sim/R/sim_utils.R", package = "drmTMB", mustWork = TRUE))
source(system.file(
  "sim/dgp/sim_dgp_skew_normal_fixed_effect.R",
  package = "drmTMB",
  mustWork = TRUE
))

floor_value <- 1e-300
floor_threshold <- uniroot(
  function(x) stats::pnorm(x, log.p = TRUE) - log(floor_value),
  interval = c(-40, -30)
)$root

tail_floor_exposure <- function(alpha_z) {
  exact_log_cdf <- stats::pnorm(alpha_z, log.p = TRUE)
  raw_cdf <- stats::pnorm(alpha_z)
  floored_log_cdf <- log(raw_cdf + floor_value)
  lift <- floored_log_cdf - exact_log_cdf
  data.frame(
    min_alpha_z = min(alpha_z),
    q05_alpha_z = unname(stats::quantile(alpha_z, 0.05, names = FALSE)),
    median_alpha_z = stats::median(alpha_z),
    n_floor_dominated = sum(raw_cdf <= floor_value),
    max_log_lift = max(lift),
    max_abs_log_lift = max(abs(lift)),
    stringsAsFactors = FALSE
  )
}

inject_tail_observations <- function(data, target_alpha_z, fraction) {
  data$tail_floor_injected <- FALSE
  data$target_alpha_z <- NA_real_
  if (is.na(target_alpha_z) || fraction <= 0) {
    return(data)
  }
  n_inject <- max(1L, ceiling(nrow(data) * fraction))
  index <- seq_len(n_inject)
  data$y[index] <- data$native_xi[index] +
    data$native_omega[index] * (target_alpha_z / data$nu[index])
  data$tail_floor_injected[index] <- TRUE
  data$target_alpha_z[index] <- target_alpha_z
  data
}

fitted_alpha_z <- function(fit, data) {
  mu <- stats::predict(fit, dpar = "mu")
  sigma <- stats::predict(fit, dpar = "sigma")
  nu <- stats::predict(fit, dpar = "nu")
  delta <- nu / sqrt(1 + nu^2)
  mean_shift <- delta * sqrt(2 / pi)
  omega <- sigma / sqrt(1 - mean_shift^2)
  xi <- mu - omega * mean_shift
  nu * ((data$y - xi) / omega)
}

max_abs_gradient <- function(fit) {
  gradient <- tryCatch(
    fit$obj$gr(fit$opt$par),
    error = function(e) NA_real_
  )
  if (!is.numeric(gradient) || !any(is.finite(gradient))) {
    return(NA_real_)
  }
  max(abs(gradient), na.rm = TRUE)
}

check_status <- function(checks, name, field) {
  row <- checks[checks$check == name, , drop = FALSE]
  if (nrow(row) == 0L || !field %in% names(row)) {
    return(NA_character_)
  }
  as.character(row[[field]][[1L]])
}

conditions <- data.frame(
  cell_id = c(
    "ordinary_reference",
    "near_floor_injected",
    "floor_dominated_injected"
  ),
  target_alpha_z = c(NA_real_, -38, -45),
  contamination_fraction = c(0, 0.03, 0.03),
  n = 120L,
  nu_intercept = 6,
  nu_slope = 0,
  sigma_slope = 0.15,
  rho_xw = 0,
  stringsAsFactors = FALSE
)
n_rep <- 3L
master_seed <- 20260618L
seeds <- matrix(
  sample.int(.Machine$integer.max, nrow(conditions) * n_rep),
  nrow = nrow(conditions),
  ncol = n_rep
)
set.seed(master_seed)
seeds[] <- sample.int(.Machine$integer.max, length(seeds))

fit_rows <- list()
coef_rows <- list()
tail_rows <- list()
failure_rows <- list()

for (cell_index in seq_len(nrow(conditions))) {
  cell <- conditions[cell_index, , drop = FALSE]
  for (replicate in seq_len(n_rep)) {
    seed <- seeds[cell_index, replicate]
    data <- phase18_dgp_skew_normal_fe(
      n = cell$n[[1L]],
      beta_mu = c("(Intercept)" = 0.20, x = 0.40),
      beta_sigma = c("(Intercept)" = log(0.70), z = cell$sigma_slope[[1L]]),
      beta_nu = c("(Intercept)" = cell$nu_intercept[[1L]], w = 0),
      rho_xw = cell$rho_xw[[1L]],
      seed = seed,
      cell_id = cell$cell_id[[1L]],
      replicate = replicate
    )
    data <- inject_tail_observations(
      data,
      target_alpha_z = cell$target_alpha_z[[1L]],
      fraction = cell$contamination_fraction[[1L]]
    )
    truth <- attr(data, "truth", exact = TRUE)
    truth_alpha_z <- data$nu * ((data$y - data$native_xi) / data$native_omega)
    generating_exposure <- tail_floor_exposure(truth_alpha_z)

    warnings <- character()
    start_time <- proc.time()[["elapsed"]]
    fit <- withCallingHandlers(
      tryCatch(
        drmTMB(
          bf(y ~ x, sigma ~ z, nu ~ w),
          family = skew_normal(),
          data = data,
          control = drm_control(optimizer_preset = "careful")
        ),
        error = function(e) e
      ),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    )
    elapsed <- proc.time()[["elapsed"]] - start_time

    if (inherits(fit, "error")) {
      failure_rows[[length(failure_rows) + 1L]] <- data.frame(
        cell_id = cell$cell_id,
        replicate = replicate,
        seed = seed,
        stage = "fit",
        message = conditionMessage(fit),
        stringsAsFactors = FALSE
      )
      next
    }

    alpha_z_fit <- fitted_alpha_z(fit, data)
    fitted_exposure <- tail_floor_exposure(alpha_z_fit)
    checks <- check_drm(fit)
    fit_rows[[length(fit_rows) + 1L]] <- data.frame(
      cell_id = cell$cell_id,
      replicate = replicate,
      seed = seed,
      n = nrow(data),
      n_injected = sum(data$tail_floor_injected),
      target_alpha_z = cell$target_alpha_z,
      floor_threshold_alpha_z = floor_threshold,
      converged = isTRUE(fit$opt$convergence == 0),
      pdHess = isTRUE(fit$sdr$pdHess),
      max_abs_gradient = max_abs_gradient(fit),
      objective = fit$opt$objective,
      logLik = as.numeric(stats::logLik(fit)),
      AIC = stats::AIC(fit),
      BIC = stats::BIC(fit),
      elapsed = elapsed,
      warning_count = length(warnings),
      warnings = paste(warnings, collapse = " | "),
      skew_normal_nu_status = check_status(checks, "skew_normal_nu", "status"),
      skew_normal_nu_value = check_status(checks, "skew_normal_nu", "value"),
      fixed_gradient_status = check_status(checks, "fixed_gradient", "status"),
      fixed_gradient_value = check_status(checks, "fixed_gradient", "value"),
      stringsAsFactors = FALSE
    )

    truth_value <- c(truth$beta_mu, truth$beta_sigma, truth$beta_nu)
    names(truth_value) <- c(
      paste0("mu:", names(truth$beta_mu)),
      paste0("sigma:", names(truth$beta_sigma)),
      paste0("nu:", names(truth$beta_nu))
    )
    estimate <- c(
      stats::coef(fit, dpar = "mu")[names(truth$beta_mu)],
      stats::coef(fit, dpar = "sigma")[names(truth$beta_sigma)],
      stats::coef(fit, dpar = "nu")[names(truth$beta_nu)]
    )
    names(estimate) <- names(truth_value)
    coef_rows[[length(coef_rows) + 1L]] <- data.frame(
      cell_id = cell$cell_id,
      replicate = replicate,
      parameter = names(truth_value),
      dpar = sub(":.*", "", names(truth_value)),
      term = sub("^[^:]+:", "", names(truth_value)),
      truth = unname(truth_value),
      estimate = unname(estimate),
      error = unname(estimate - truth_value),
      stringsAsFactors = FALSE
    )

    tail_rows[[length(tail_rows) + 1L]] <- data.frame(
      cell_id = cell$cell_id,
      replicate = replicate,
      seed = seed,
      scale = c("generating", "fitted"),
      min_alpha_z = c(
        generating_exposure$min_alpha_z,
        fitted_exposure$min_alpha_z
      ),
      q05_alpha_z = c(
        generating_exposure$q05_alpha_z,
        fitted_exposure$q05_alpha_z
      ),
      median_alpha_z = c(
        generating_exposure$median_alpha_z,
        fitted_exposure$median_alpha_z
      ),
      n_floor_dominated = c(
        generating_exposure$n_floor_dominated,
        fitted_exposure$n_floor_dominated
      ),
      max_log_lift = c(
        generating_exposure$max_log_lift,
        fitted_exposure$max_log_lift
      ),
      max_abs_log_lift = c(
        generating_exposure$max_abs_log_lift,
        fitted_exposure$max_abs_log_lift
      ),
      stringsAsFactors = FALSE
    )
  }
}

fit_diagnostics <- do.call(rbind, fit_rows)
coefficients <- do.call(rbind, coef_rows)
tail_exposure <- do.call(rbind, tail_rows)
failures <- if (length(failure_rows)) {
  do.call(rbind, failure_rows)
} else {
  data.frame(
    cell_id = character(),
    replicate = integer(),
    seed = integer(),
    stage = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}

condition_summary <- do.call(rbind, lapply(
  split(fit_diagnostics, fit_diagnostics$cell_id),
  function(rows) {
    tail <- tail_exposure[
      tail_exposure$cell_id %in% rows$cell_id &
        tail_exposure$scale == "fitted",
      ,
      drop = FALSE
    ]
    data.frame(
      cell_id = rows$cell_id[[1L]],
      n_fit = nrow(rows),
      n_failed = sum(failures$cell_id == rows$cell_id[[1L]]),
      convergence_rate = mean(rows$converged),
      pdHess_rate = mean(rows$pdHess),
      mean_max_abs_gradient = mean(rows$max_abs_gradient, na.rm = TRUE),
      max_warning_count = max(rows$warning_count),
      max_fitted_log_lift = max(tail$max_log_lift),
      max_fitted_abs_log_lift = max(tail$max_abs_log_lift),
      max_fitted_floor_dominated = max(tail$n_floor_dominated),
      min_fitted_alpha_z = min(tail$min_alpha_z),
      stringsAsFactors = FALSE
    )
  }
))

coefficient_summary <- do.call(rbind, lapply(
  split(coefficients, list(coefficients$cell_id, coefficients$parameter)),
  function(rows) {
    if (nrow(rows) == 0L) {
      return(NULL)
    }
    data.frame(
      cell_id = rows$cell_id[[1L]],
      parameter = rows$parameter[[1L]],
      dpar = rows$dpar[[1L]],
      term = rows$term[[1L]],
      n_fit = nrow(rows),
      truth = rows$truth[[1L]],
      mean_estimate = mean(rows$estimate),
      bias = mean(rows$error),
      bias_mcse = stats::sd(rows$error) / sqrt(nrow(rows)),
      rmse = sqrt(mean(rows$error^2)),
      stringsAsFactors = FALSE
    )
  }
))

run_summary <- data.frame(
  surface = "skew_normal_tail_floor_fit_stress",
  label = "fit_level_diagnostic_pilot",
  n_cells = nrow(conditions),
  n_rep = n_rep,
  n_fit = nrow(fit_diagnostics),
  n_failed = nrow(failures),
  floor_threshold_alpha_z = floor_threshold,
  max_generating_abs_log_lift = max(
    tail_exposure$max_abs_log_lift[tail_exposure$scale == "generating"]
  ),
  max_fitted_abs_log_lift = max(
    tail_exposure$max_abs_log_lift[tail_exposure$scale == "fitted"]
  ),
  max_fitted_floor_dominated = max(
    tail_exposure$n_floor_dominated[tail_exposure$scale == "fitted"]
  ),
  all_converged = all(fit_diagnostics$converged),
  all_pdHess = all(fit_diagnostics$pdHess),
  stringsAsFactors = FALSE
)

utils::write.csv(
  conditions,
  file.path(tables_dir, "skew-normal-tail-floor-fit-conditions.csv"),
  row.names = FALSE
)
utils::write.csv(
  fit_diagnostics,
  file.path(tables_dir, "skew-normal-tail-floor-fit-diagnostics.csv"),
  row.names = FALSE
)
utils::write.csv(
  coefficients,
  file.path(tables_dir, "skew-normal-tail-floor-fit-coefficients.csv"),
  row.names = FALSE
)
utils::write.csv(
  coefficient_summary,
  file.path(tables_dir, "skew-normal-tail-floor-fit-coefficient-summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  tail_exposure,
  file.path(tables_dir, "skew-normal-tail-floor-fit-tail-exposure.csv"),
  row.names = FALSE
)
utils::write.csv(
  condition_summary,
  file.path(tables_dir, "skew-normal-tail-floor-fit-condition-summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  failures,
  file.path(tables_dir, "skew-normal-tail-floor-fit-failures.csv"),
  row.names = FALSE
)
utils::write.csv(
  run_summary,
  file.path(artifact_dir, "skew-normal-tail-floor-fit-run-summary.csv"),
  row.names = FALSE
)

session_info <- capture.output(sessionInfo())
session_info <- sub("[ \t]+$", "", session_info)
writeLines(session_info, file.path(artifact_dir, "session-info.txt"))

message("Wrote skew-normal tail-floor fit-stress artifact to: ", artifact_dir)
