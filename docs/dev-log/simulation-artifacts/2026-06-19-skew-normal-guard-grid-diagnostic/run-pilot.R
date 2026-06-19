args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "docs/dev-log/simulation-artifacts/2026-06-19-skew-normal-guard-grid-diagnostic/run-pilot.R",
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

if (requireNamespace("devtools", quietly = TRUE)) {
  devtools::load_all(repo_root, quiet = TRUE)
} else {
  library(drmTMB)
}

source(file.path(repo_root, "inst/sim/R/sim_registry.R"))
source(file.path(repo_root, "inst/sim/R/sim_utils.R"))
source(file.path(repo_root, "inst/sim/dgp/sim_dgp_skew_normal_fixed_effect.R"))

floor_value <- 1e-300
floor_threshold <- uniroot(
  function(x) stats::pnorm(x, log.p = TRUE) - log(floor_value),
  interval = c(-40, -30)
)$root

whole_number_env <- function(name, default) {
  value <- Sys.getenv(name, as.character(default))
  out <- suppressWarnings(as.integer(value))
  if (length(out) != 1L || is.na(out) || out <= 0L) {
    stop(name, " must be a positive whole number.", call. = FALSE)
  }
  out
}

alpha_z_exposure <- function(alpha_z) {
  exact_log_cdf <- stats::pnorm(alpha_z, log.p = TRUE)
  raw_cdf <- stats::pnorm(alpha_z)
  floored_log_cdf <- log(raw_cdf + floor_value)
  lift <- floored_log_cdf - exact_log_cdf
  n_floor <- sum(raw_cdf <= floor_value)
  n_near <- sum(alpha_z <= floor_threshold + 2 & raw_cdf > floor_value)
  data.frame(
    n_observation = length(alpha_z),
    min_alpha_z = min(alpha_z),
    q01_alpha_z = unname(stats::quantile(alpha_z, 0.01, names = FALSE)),
    q05_alpha_z = unname(stats::quantile(alpha_z, 0.05, names = FALSE)),
    median_alpha_z = stats::median(alpha_z),
    n_near_floor = n_near,
    n_floor_dominated = n_floor,
    max_log_lift = max(lift),
    max_abs_log_lift = max(abs(lift)),
    exposure_status = if (n_floor > 0L) {
      "floor_dominated"
    } else if (n_near > 0L) {
      "near_floor"
    } else {
      "ordinary_tail"
    },
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

optimizer_attempt_summary <- function(fit, field) {
  attempts <- fit$optimizer_attempts
  if (
    is.null(attempts) || !is.data.frame(attempts) || !field %in% names(attempts)
  ) {
    return(NA_character_)
  }
  paste(as.character(attempts[[field]]), collapse = "|")
}

check_value <- function(checks, name, field) {
  row <- checks[checks$check == name, , drop = FALSE]
  if (nrow(row) == 0L || !field %in% names(row)) {
    return(NA_character_)
  }
  as.character(row[[field]][[1L]])
}

empty_fit_diagnostics <- function() {
  data.frame(
    cell_id = character(),
    replicate = integer(),
    seed = integer(),
    n = integer(),
    n_injected = integer(),
    target_alpha_z = numeric(),
    contamination_fraction = numeric(),
    floor_threshold_alpha_z = numeric(),
    optimizer_preset = character(),
    optimizer_attempt_count = integer(),
    optimizer_attempt_presets = character(),
    optimizer_attempt_statuses = character(),
    convergence = integer(),
    converged = logical(),
    pdHess = logical(),
    max_abs_gradient = numeric(),
    objective = numeric(),
    logLik = numeric(),
    AIC = numeric(),
    BIC = numeric(),
    elapsed = numeric(),
    warning_count = integer(),
    warnings = character(),
    skew_normal_nu_status = character(),
    skew_normal_nu_value = character(),
    fixed_gradient_status = character(),
    fixed_gradient_value = character(),
    fit_status = character(),
    stringsAsFactors = FALSE
  )
}

empty_check_rows <- function() {
  data.frame(
    cell_id = character(),
    replicate = integer(),
    seed = integer(),
    check = character(),
    status = character(),
    value = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}

empty_tail_rows <- function() {
  data.frame(
    cell_id = character(),
    replicate = integer(),
    seed = integer(),
    exposure_scale = character(),
    n_observation = integer(),
    min_alpha_z = numeric(),
    q01_alpha_z = numeric(),
    q05_alpha_z = numeric(),
    median_alpha_z = numeric(),
    n_near_floor = integer(),
    n_floor_dominated = integer(),
    max_log_lift = numeric(),
    max_abs_log_lift = numeric(),
    exposure_status = character(),
    stringsAsFactors = FALSE
  )
}

empty_coefficient_rows <- function() {
  data.frame(
    cell_id = character(),
    replicate = integer(),
    parameter = character(),
    dpar = character(),
    term = character(),
    truth = numeric(),
    estimate = numeric(),
    std.error = numeric(),
    error = numeric(),
    stringsAsFactors = FALSE
  )
}

empty_failure_rows <- function() {
  data.frame(
    cell_id = character(),
    replicate = integer(),
    seed = integer(),
    stage = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}

classify_fit <- function(fit_row, fitted_exposure) {
  floor_exposed <- isTRUE(fitted_exposure$n_floor_dominated > 0L)
  warned <- FALSE
  if (!isTRUE(fit_row$converged) || !isTRUE(fit_row$pdHess)) {
    warned <- TRUE
  }
  if (!identical(fit_row$fixed_gradient_status, "ok")) {
    warned <- TRUE
  }
  if (isTRUE(fit_row$warning_count > 0L)) {
    warned <- TRUE
  }
  if (floor_exposed && warned) {
    return("tail_floor_exposed_fit_warned")
  }
  if (floor_exposed) {
    return("tail_floor_exposed_fit_clean")
  }
  if (warned) {
    return("tail_floor_inactive_fit_warned")
  }
  "tail_floor_inactive_fit_clean"
}

cell_decision <- function(rows, tail_rows) {
  fitted_tail <- tail_rows[tail_rows$exposure_scale == "fitted", , drop = FALSE]
  gradient_warned <- is.na(rows$fixed_gradient_status) |
    rows$fixed_gradient_status != "ok"
  if (
    any(!rows$converged) ||
      any(!rows$pdHess) ||
      any(rows$warning_count > 0L) ||
      any(gradient_warned) ||
      any(fitted_tail$n_floor_dominated > 0L)
  ) {
    "diagnostic_hold"
  } else {
    "needs_larger_grid"
  }
}

n_rep <- whole_number_env("DRMTMB_SKEW_NORMAL_GUARD_REPS", 25L)
master_seed <- whole_number_env("DRMTMB_SKEW_NORMAL_GUARD_SEED", 20260619L)

conditions <- data.frame(
  cell_id = c(
    "symmetric_reference",
    "moderate_right_static",
    "moderate_left_static",
    "moderate_right_slope",
    "strong_right_static",
    "strong_left_static",
    "near_floor_injected",
    "floor_dominated_injected"
  ),
  cell_family = c(
    "ordinary",
    "moderate_tail",
    "moderate_tail",
    "moderate_tail",
    "extreme_tail",
    "extreme_tail",
    "injected_tail",
    "injected_tail"
  ),
  n = c(720L, 720L, 720L, 720L, 360L, 360L, 240L, 240L),
  nu_intercept = c(0, 1.20, -1.20, 1.20, 6, -6, 6, 6),
  nu_slope = c(0, 0, 0, 0.35, 0, 0, 0, 0),
  sigma_slope = c(0.15, 0.15, 0.15, 0.30, 0.15, 0.15, 0.15, 0.15),
  rho_xw = c(0.20, 0.20, 0.20, 0.40, 0, 0, 0, 0),
  target_alpha_z = c(
    NA_real_,
    NA_real_,
    NA_real_,
    NA_real_,
    NA_real_,
    NA_real_,
    -38,
    -45
  ),
  contamination_fraction = c(0, 0, 0, 0, 0, 0, 0.03, 0.03),
  stringsAsFactors = FALSE
)
conditions$beta_mu_intercept <- 0.20
conditions$beta_mu_x <- 0.40
conditions$beta_sigma_intercept <- log(0.70)

set.seed(master_seed)
seeds <- matrix(
  sample.int(.Machine$integer.max, nrow(conditions) * n_rep),
  nrow = nrow(conditions),
  ncol = n_rep
)

fit_rows <- list()
check_rows <- list()
coef_rows <- list()
tail_rows <- list()
failure_rows <- list()

started <- Sys.time()
for (cell_index in seq_len(nrow(conditions))) {
  cell <- conditions[cell_index, , drop = FALSE]
  for (replicate in seq_len(n_rep)) {
    seed <- seeds[cell_index, replicate]
    data <- phase18_dgp_skew_normal_fe(
      n = cell$n[[1L]],
      beta_mu = c(
        "(Intercept)" = cell$beta_mu_intercept[[1L]],
        x = cell$beta_mu_x[[1L]]
      ),
      beta_sigma = c(
        "(Intercept)" = cell$beta_sigma_intercept[[1L]],
        z = cell$sigma_slope[[1L]]
      ),
      beta_nu = c(
        "(Intercept)" = cell$nu_intercept[[1L]],
        w = cell$nu_slope[[1L]]
      ),
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
    generating_alpha_z <- data$nu *
      ((data$y - data$native_xi) / data$native_omega)
    generating_exposure <- alpha_z_exposure(generating_alpha_z)
    tail_rows[[length(tail_rows) + 1L]] <- data.frame(
      cell_id = cell$cell_id,
      replicate = replicate,
      seed = seed,
      exposure_scale = "generating",
      generating_exposure,
      stringsAsFactors = FALSE
    )

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

    fitted_exposure <- alpha_z_exposure(fitted_alpha_z(fit, data))
    tail_rows[[length(tail_rows) + 1L]] <- data.frame(
      cell_id = cell$cell_id,
      replicate = replicate,
      seed = seed,
      exposure_scale = "fitted",
      fitted_exposure,
      stringsAsFactors = FALSE
    )

    checks <- check_drm(fit)
    if (nrow(checks) > 0L) {
      check_rows[[length(check_rows) + 1L]] <- data.frame(
        cell_id = cell$cell_id,
        replicate = replicate,
        seed = seed,
        checks,
        stringsAsFactors = FALSE
      )
    }

    fit_row <- data.frame(
      cell_id = cell$cell_id,
      replicate = replicate,
      seed = seed,
      n = nrow(data),
      n_injected = sum(data$tail_floor_injected),
      target_alpha_z = cell$target_alpha_z,
      contamination_fraction = cell$contamination_fraction,
      floor_threshold_alpha_z = floor_threshold,
      optimizer_preset = "careful",
      optimizer_attempt_count = if (is.data.frame(fit$optimizer_attempts)) {
        nrow(fit$optimizer_attempts)
      } else {
        NA_integer_
      },
      optimizer_attempt_presets = optimizer_attempt_summary(fit, "preset"),
      optimizer_attempt_statuses = optimizer_attempt_summary(fit, "status"),
      convergence = fit$opt$convergence,
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
      skew_normal_nu_status = check_value(checks, "skew_normal_nu", "status"),
      skew_normal_nu_value = check_value(checks, "skew_normal_nu", "value"),
      fixed_gradient_status = check_value(checks, "fixed_gradient", "status"),
      fixed_gradient_value = check_value(checks, "fixed_gradient", "value"),
      fit_status = NA_character_,
      stringsAsFactors = FALSE
    )
    fit_row$fit_status <- classify_fit(fit_row, fitted_exposure)
    fit_rows[[length(fit_rows) + 1L]] <- fit_row

    coefficients <- tryCatch(
      summary(fit)$coefficients,
      error = function(e) NULL
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
    std_error <- rep(NA_real_, length(estimate))
    if (is.data.frame(coefficients) && "std_error" %in% names(coefficients)) {
      matched <- match(names(estimate), row.names(coefficients))
      ok <- !is.na(matched)
      std_error[ok] <- coefficients$std_error[matched[ok]]
    }
    coef_rows[[length(coef_rows) + 1L]] <- data.frame(
      cell_id = cell$cell_id,
      replicate = replicate,
      parameter = names(truth_value),
      dpar = sub(":.*", "", names(truth_value)),
      term = sub("^[^:]+:", "", names(truth_value)),
      truth = unname(truth_value),
      estimate = unname(estimate),
      std.error = unname(std_error),
      error = unname(estimate - truth_value),
      stringsAsFactors = FALSE
    )
  }
}
finished <- Sys.time()

fit_diagnostics <- if (length(fit_rows)) {
  do.call(rbind, fit_rows)
} else {
  empty_fit_diagnostics()
}
check_drm_rows <- if (length(check_rows)) {
  do.call(rbind, check_rows)
} else {
  empty_check_rows()
}
coefficients <- if (length(coef_rows)) {
  do.call(rbind, coef_rows)
} else {
  empty_coefficient_rows()
}
tail_exposure <- if (length(tail_rows)) {
  do.call(rbind, tail_rows)
} else {
  empty_tail_rows()
}
failures <- if (length(failure_rows)) {
  do.call(rbind, failure_rows)
} else {
  empty_failure_rows()
}

condition_summary <- do.call(
  rbind,
  lapply(seq_len(nrow(conditions)), function(i) {
    cell <- conditions[i, , drop = FALSE]
    rows <- fit_diagnostics[
      fit_diagnostics$cell_id == cell$cell_id,
      ,
      drop = FALSE
    ]
    tail <- tail_exposure[tail_exposure$cell_id == cell$cell_id, , drop = FALSE]
    fitted_tail <- tail[tail$exposure_scale == "fitted", , drop = FALSE]
    generating_tail <- tail[tail$exposure_scale == "generating", , drop = FALSE]
    if (nrow(rows) == 0L) {
      return(data.frame(
        cell_id = cell$cell_id,
        cell_family = cell$cell_family,
        n_requested = n_rep,
        n_fit = 0L,
        n_failed = sum(failures$cell_id == cell$cell_id),
        n_parameter_rows = 0L,
        n_observation_total = 0L,
        n_observation_used = 0L,
        convergence_rate = NA_real_,
        pdHess_rate = NA_real_,
        warning_rate = NA_real_,
        fixed_gradient_ok_rate = NA_real_,
        max_warning_count = NA_integer_,
        max_abs_gradient = NA_real_,
        max_generating_floor_dominated = max(generating_tail$n_floor_dominated),
        max_fitted_floor_dominated = NA_integer_,
        max_generating_abs_log_lift = max(generating_tail$max_abs_log_lift),
        max_fitted_abs_log_lift = NA_real_,
        min_fitted_alpha_z = NA_real_,
        cell_decision = "diagnostic_hold",
        decision_reason = "all_fits_failed",
        stringsAsFactors = FALSE
      ))
    }
    decision <- cell_decision(rows, tail)
    reasons <- c()
    if (any(!rows$converged)) {
      reasons <- c(reasons, "optimizer_nonconvergence")
    }
    if (any(!rows$pdHess)) {
      reasons <- c(reasons, "non_positive_hessian")
    }
    if (any(rows$warning_count > 0L)) {
      reasons <- c(reasons, "fit_warnings")
    }
    if (
      any(
        is.na(rows$fixed_gradient_status) | rows$fixed_gradient_status != "ok"
      )
    ) {
      reasons <- c(reasons, "fixed_gradient_warning")
    }
    if (any(fitted_tail$n_floor_dominated > 0L)) {
      reasons <- c(reasons, "fitted_floor_dominated")
    }
    if (!length(reasons)) {
      reasons <- "clean_guard_screen"
    }
    data.frame(
      cell_id = cell$cell_id,
      cell_family = cell$cell_family,
      n_requested = n_rep,
      n_fit = nrow(rows),
      n_failed = sum(failures$cell_id == cell$cell_id),
      n_parameter_rows = nrow(rows) * 6L,
      n_observation_total = sum(rows$n),
      n_observation_used = sum(rows$n),
      convergence_rate = mean(rows$converged),
      pdHess_rate = mean(rows$pdHess),
      warning_rate = mean(rows$warning_count > 0L),
      fixed_gradient_ok_rate = mean(rows$fixed_gradient_status == "ok"),
      max_warning_count = max(rows$warning_count),
      max_abs_gradient = max(rows$max_abs_gradient, na.rm = TRUE),
      max_generating_floor_dominated = max(generating_tail$n_floor_dominated),
      max_fitted_floor_dominated = max(fitted_tail$n_floor_dominated),
      max_generating_abs_log_lift = max(generating_tail$max_abs_log_lift),
      max_fitted_abs_log_lift = max(fitted_tail$max_abs_log_lift),
      min_fitted_alpha_z = min(fitted_tail$min_alpha_z),
      cell_decision = decision,
      decision_reason = paste(reasons, collapse = "|"),
      stringsAsFactors = FALSE
    )
  })
)

coefficient_summary <- if (nrow(coefficients) == 0L) {
  data.frame()
} else {
  do.call(
    rbind,
    lapply(
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
          mean_std_error = mean(rows$std.error, na.rm = TRUE),
          stringsAsFactors = FALSE
        )
      }
    )
  )
}

overall_decision <- if (
  any(condition_summary$cell_decision == "diagnostic_hold")
) {
  "diagnostic_hold"
} else {
  "needs_larger_grid"
}

run_summary <- data.frame(
  surface = "skew_normal_guard_grid",
  label = "fixed_effect_tail_floor_guard_grid",
  evidence_lane = "native_r_tmb",
  direct_julia_claim = FALSE,
  julia_via_r_claim = FALSE,
  n_cells = nrow(conditions),
  n_replicates_per_cell = n_rep,
  n_requested = nrow(conditions) * n_rep,
  n_fit = nrow(fit_diagnostics),
  n_failed = nrow(failures),
  n_parameter_rows = nrow(coefficients),
  n_observation_total = sum(fit_diagnostics$n),
  n_observation_used = sum(fit_diagnostics$n),
  min_convergence_rate = min(condition_summary$convergence_rate, na.rm = TRUE),
  min_pdHess_rate = min(condition_summary$pdHess_rate, na.rm = TRUE),
  min_fixed_gradient_ok_rate = min(
    condition_summary$fixed_gradient_ok_rate,
    na.rm = TRUE
  ),
  max_warning_rate = max(condition_summary$warning_rate, na.rm = TRUE),
  max_generating_floor_dominated = max(
    condition_summary$max_generating_floor_dominated,
    na.rm = TRUE
  ),
  max_fitted_floor_dominated = max(
    condition_summary$max_fitted_floor_dominated,
    na.rm = TRUE
  ),
  max_fitted_abs_log_lift = max(
    condition_summary$max_fitted_abs_log_lift,
    na.rm = TRUE
  ),
  overall_decision = overall_decision,
  floor_threshold_alpha_z = floor_threshold,
  profile_requested = FALSE,
  bootstrap_requested = FALSE,
  random_effects = FALSE,
  bivariate = FALSE,
  structured = FALSE,
  started = format(started, "%Y-%m-%d %H:%M:%S %Z"),
  finished = format(finished, "%Y-%m-%d %H:%M:%S %Z"),
  elapsed_seconds = as.numeric(difftime(finished, started, units = "secs")),
  stringsAsFactors = FALSE
)

utils::write.csv(
  conditions,
  file.path(tables_dir, "skew-normal-guard-grid-conditions.csv"),
  row.names = FALSE
)
utils::write.csv(
  fit_diagnostics,
  file.path(tables_dir, "skew-normal-guard-grid-fit-diagnostics.csv"),
  row.names = FALSE
)
utils::write.csv(
  check_drm_rows,
  file.path(tables_dir, "skew-normal-guard-grid-check-drm.csv"),
  row.names = FALSE
)
utils::write.csv(
  tail_exposure,
  file.path(tables_dir, "skew-normal-guard-grid-tail-exposure.csv"),
  row.names = FALSE
)
utils::write.csv(
  coefficients,
  file.path(tables_dir, "skew-normal-guard-grid-coefficients.csv"),
  row.names = FALSE
)
utils::write.csv(
  coefficient_summary,
  file.path(tables_dir, "skew-normal-guard-grid-coefficient-summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  condition_summary,
  file.path(tables_dir, "skew-normal-guard-grid-condition-summary.csv"),
  row.names = FALSE
)
utils::write.csv(
  failures,
  file.path(tables_dir, "skew-normal-guard-grid-failures.csv"),
  row.names = FALSE
)
utils::write.csv(
  run_summary,
  file.path(artifact_dir, "skew-normal-guard-grid-run-summary.csv"),
  row.names = FALSE
)

readme <- c(
  "# Skew-Normal Guard Grid Diagnostic",
  "",
  "This artifact records a fixed-effect skew-normal guard-grid diagnostic for",
  "the numerical-guard ledger. It follows the first fixed-effect pilot and the",
  "source/fit tail-floor diagnostics, but keeps the question narrow: do",
  "ordinary, moderate-tail, extreme-tail, and deliberately injected tail cells",
  "surface floor exposure and fit-health warnings as explicit artifact data?",
  "",
  "This is native R/TMB diagnostic evidence only. It is not interval",
  "calibration, coverage evidence, power evidence, release readiness, CRAN",
  "readiness, direct Julia evidence, or Julia-via-R evidence.",
  "",
  "## ADEMP Summary",
  "",
  "**Aim.** Separate generating-scale and fitted-scale skew-normal tail-floor",
  "exposure while recording optimizer convergence, Hessian status, fixed",
  "gradients, `check_drm()` rows, warnings, and coefficient errors.",
  "",
  "**Data-generating mechanisms.** Eight complete-data fixed-effect cells use",
  "`bf(y ~ x, sigma ~ z, nu ~ w), family = skew_normal()`. The grid includes a",
  "near-symmetric reference, moderate left/right slant, a moderate slant-slope",
  "cell, strong left/right slant cells, and two injected-tail cells with",
  "`alpha * z` targets of -38 and -45.",
  "",
  "**Estimands.** Formula-scale fixed effects for `mu`, `sigma`, and `nu`, plus",
  "generating- and fitted-scale tail-floor exposure summaries.",
  "",
  "**Methods.** Each replicate uses `drm_control(optimizer_preset = \"careful\")`.",
  "No profile intervals, bootstrap intervals, random effects, bivariate",
  "responses, structured effects, or Julia bridge paths are requested.",
  "",
  "**Performance measures.** Fit convergence, `pdHess`, fixed-gradient status,",
  "warning rates, floor-dominated observation counts, maximum floor log-lift,",
  "coefficient bias/RMSE, and conservative cell decision labels.",
  "",
  "## Files",
  "",
  "- `run-pilot.R`: reproducible runner.",
  "- `skew-normal-guard-grid-run-summary.csv`: one-row run summary.",
  "- `session-info.txt`: R session information.",
  "- `tables/skew-normal-guard-grid-conditions.csv`: simulation cells.",
  "- `tables/skew-normal-guard-grid-fit-diagnostics.csv`: one row per fitted model.",
  "- `tables/skew-normal-guard-grid-check-drm.csv`: `check_drm()` rows by fit.",
  "- `tables/skew-normal-guard-grid-tail-exposure.csv`: generating/fitted tail exposure rows.",
  "- `tables/skew-normal-guard-grid-coefficients.csv`: replicate coefficient estimates.",
  "- `tables/skew-normal-guard-grid-coefficient-summary.csv`: coefficient bias/RMSE summaries.",
  "- `tables/skew-normal-guard-grid-condition-summary.csv`: cell-level fit and exposure summaries.",
  "- `tables/skew-normal-guard-grid-failures.csv`: fit failures, if any.",
  "",
  "## Results",
  "",
  paste0(
    "The grid requested ",
    run_summary$n_requested,
    " fits across ",
    run_summary$n_cells,
    " cells with ",
    run_summary$n_replicates_per_cell,
    " replicates per cell. It returned ",
    run_summary$n_fit,
    " fits and ",
    run_summary$n_failed,
    " fit errors."
  ),
  "",
  paste0(
    "Minimum convergence rate was ",
    run_summary$min_convergence_rate,
    ", minimum `pdHess` rate was ",
    run_summary$min_pdHess_rate,
    ", and minimum fixed-gradient ok rate was ",
    run_summary$min_fixed_gradient_ok_rate,
    "."
  ),
  "",
  paste0(
    "The maximum generating-scale floor-dominated count was ",
    run_summary$max_generating_floor_dominated,
    ". The maximum fitted-scale floor-dominated count was ",
    run_summary$max_fitted_floor_dominated,
    ", with maximum fitted absolute log-CDF lift ",
    signif(run_summary$max_fitted_abs_log_lift, 8),
    "."
  ),
  "",
  paste0("Overall decision label: `", run_summary$overall_decision, "`."),
  "",
  "## Interpretation",
  "",
  "Interpretation for applied users: these rows ask whether rare, extreme",
  "residual-tail observations make the internal skew-normal tail floor active",
  "after fitting. A clean row means the fitted-scale floor count is zero and",
  "the fit diagnostics are also clean. A row with non-convergence, `pdHess =",
  "FALSE`, a large fixed gradient, or a large `skew_normal_nu` diagnostic is",
  "not a usable inference result even if the likelihood is finite.",
  "",
  "The decision labels are intentionally conservative. `needs_larger_grid`",
  "means a cell had a clean guard-screen in this diagnostic and can be expanded",
  "later if formal operating-characteristic evidence is needed.",
  "`diagnostic_hold` means at least one fit-health or fitted-floor warning must",
  "travel with any future claim.",
  "",
  "What to try next for a warned applied fit: run `check_drm()`, inspect",
  "`fit$optimizer_attempts`, simplify the `nu` formula first, rescale the",
  "response or predictors, compare with a Gaussian location-scale model, and",
  "avoid Wald interval interpretation until convergence, Hessian, and gradient",
  "diagnostics are clean.",
  "",
  "## Boundary",
  "",
  "This artifact does not promote skew-normal recovery accuracy, standard-error",
  "reliability, Wald/profile/bootstrap intervals, coverage, power, random",
  "effects, structured effects, bivariate skew-normal models, residual `rho12`,",
  "external comparator parity, release readiness, CRAN readiness, direct Julia",
  "parity, Julia-via-R parity, or non-Gaussian REML/AI-REML."
)
writeLines(readme, file.path(artifact_dir, "README.md"))

session_info <- capture.output(sessionInfo())
session_info <- sub("[ \t]+$", "", session_info)
writeLines(session_info, file.path(artifact_dir, "session-info.txt"))

message("Wrote skew-normal guard-grid diagnostic artifact to: ", artifact_dir)
