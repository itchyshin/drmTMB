args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "docs/dev-log/simulation-artifacts/2026-06-18-support-floor-diagnostic/run-pilot.R",
    mustWork = TRUE
  )
}

artifact_dir <- dirname(script_path)
repo_root <- normalizePath(file.path(artifact_dir, "../../../.."), mustWork = TRUE)
tables_dir <- file.path(artifact_dir, "tables")
dir.create(tables_dir, recursive = TRUE, showWarnings = FALSE)

suppressPackageStartupMessages(devtools::load_all(repo_root, quiet = TRUE))

mean_floor <- 1e-12
shape_floor <- 1e-8
master_seed <- 20260618L

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

clamped_beta_shapes <- function(eta_mu, log_sigma) {
  mu_raw <- stats::plogis(eta_mu)
  mu <- mean_floor + (1 - 2 * mean_floor) * mu_raw
  phi <- exp(-2 * log_sigma)
  alpha_raw <- mu * phi
  beta_raw <- (1 - mu) * phi
  data.frame(
    eta_mu = eta_mu,
    log_sigma = log_sigma,
    mu_raw = mu_raw,
    mu = mu,
    sigma = exp(log_sigma),
    phi = phi,
    alpha_raw = alpha_raw,
    beta_raw = beta_raw,
    alpha = pmax(alpha_raw, shape_floor),
    beta_shape = pmax(beta_raw, shape_floor),
    alpha_floor_active = alpha_raw < shape_floor,
    beta_floor_active = beta_raw < shape_floor,
    stringsAsFactors = FALSE
  )
}

source_conditions <- expand.grid(
  route = c(
    "beta_response",
    "zero_one_beta_response",
    "missing_predictor_beta",
    "missing_predictor_zero_one_beta"
  ),
  eta_mu = c(qlogis(0.5), qlogis(1e-6), qlogis(1 - 1e-6)),
  log_sigma = c(log(0.5), log(2), 8, 12, 16),
  KEEP.OUT.ATTRS = FALSE,
  stringsAsFactors = FALSE
)
source_grid <- do.call(rbind, lapply(seq_len(nrow(source_conditions)), function(i) {
  row <- source_conditions[i, , drop = FALSE]
  out <- clamped_beta_shapes(row$eta_mu, row$log_sigma)
  data.frame(row["route"], out, stringsAsFactors = FALSE)
}))

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

max_or_na <- function(x) {
  if (!length(x) || !any(!is.na(x))) {
    return(NA_integer_)
  }
  max(x, na.rm = TRUE)
}

fit_report_row <- function(fit) {
  report <- fit$obj$report()
  has_alpha <- "alpha" %in% names(report)
  has_beta_shape <- "beta_shape" %in% names(report)
  alpha <- if (has_alpha) report$alpha else numeric()
  beta_shape <- if (has_beta_shape) report$beta_shape else numeric()
  data.frame(
    min_alpha = if (has_alpha) suppressWarnings(min(alpha, na.rm = TRUE)) else NA_real_,
    min_beta_shape = if (has_beta_shape) {
      suppressWarnings(min(beta_shape, na.rm = TRUE))
    } else {
      NA_real_
    },
    n_alpha_floor_active = if (has_alpha) {
      sum(alpha <= shape_floor * (1 + 1e-10), na.rm = TRUE)
    } else {
      NA_integer_
    },
    n_beta_floor_active = if (has_beta_shape) {
      sum(beta_shape <= shape_floor * (1 + 1e-10), na.rm = TRUE)
    } else {
      NA_integer_
    },
    max_sigma = if ("sigma" %in% names(report)) max(report$sigma, na.rm = TRUE) else NA_real_,
    stringsAsFactors = FALSE
  )
}

beta_data <- function(n, seed, boundary = FALSE) {
  set.seed(seed)
  data <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  mu <- stats::plogis(-0.25 + 0.70 * data$x)
  sigma <- exp(-0.75 + 0.20 * data$z)
  if (boundary) {
    q <- (seq_len(n) - 0.5) / n
    data$y <- pmin(pmax(stats::qbeta(
      q,
      shape1 = mu / sigma^2,
      shape2 = (1 - mu) / sigma^2
    ), 1e-10), 1 - 1e-10)
  } else {
    data$y <- stats::rbeta(n, shape1 = mu / sigma^2, shape2 = (1 - mu) / sigma^2)
  }
  data
}

zero_one_beta_data <- function(n, seed, boundary_heavy = FALSE) {
  set.seed(seed)
  data <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    w = stats::rnorm(n),
    v = stats::rnorm(n)
  )
  mu <- stats::plogis(-0.20 + 0.60 * data$x)
  sigma <- exp(-0.85 + 0.18 * data$z)
  zoi <- stats::plogis(if (boundary_heavy) 0.80 else -1.10 + 0.35 * data$w)
  coi <- stats::plogis(0.10 - 0.45 * data$v)
  data$y <- stats::rbeta(n, shape1 = mu / sigma^2, shape2 = (1 - mu) / sigma^2)
  boundary <- stats::runif(n) < zoi
  data$y[boundary] <- as.numeric(stats::runif(sum(boundary)) < coi[boundary])
  if (boundary_heavy) {
    interior <- which(data$y > 0 & data$y < 1)
    keep_interior <- head(interior, max(3L, ceiling(0.08 * n)))
    force_boundary <- setdiff(interior, keep_interior)
    data$y[force_boundary] <- rep(c(0, 1), length.out = length(force_boundary))
  }
  data
}

missing_beta_data <- function(family = c("beta", "zero_one_beta"), bad = FALSE) {
  family <- match.arg(family)
  n <- 80L
  z <- seq(-1.8, 1.8, length.out = n)
  cover <- stats::plogis(-0.15 + 0.85 * z + 0.12 * sin(seq_len(n) / 4))
  if (identical(family, "zero_one_beta")) {
    cover[seq(7, n, by = 19)] <- 0
    cover[seq(13, n, by = 23)] <- 1
  }
  y <- 0.30 + 1.10 * cover - 0.25 * z + 0.04 * cos(seq_len(n) / 5)
  data <- data.frame(y = y, z = z, cover = cover)
  data$cover[c(8, 21, 39, 58, 73)] <- NA_real_
  if (bad && identical(family, "beta")) {
    data$cover[[1L]] <- 0
  }
  if (bad && identical(family, "zero_one_beta")) {
    observed <- !is.na(data$cover)
    data$cover[observed] <- rep(c(0, 1), length.out = sum(observed))
  }
  data
}

fit_specs <- list(
  list(
    cell_id = "beta_ordinary_fit",
    route = "beta_response",
    data = beta_data(120, master_seed + 1L, boundary = FALSE),
    expr = function(data) drmTMB(bf(y ~ x, sigma ~ z), family = beta(), data = data)
  ),
  list(
    cell_id = "beta_near_boundary_fit",
    route = "beta_response",
    data = beta_data(120, master_seed + 2L, boundary = TRUE),
    expr = function(data) drmTMB(bf(y ~ x, sigma ~ z), family = beta(), data = data)
  ),
  list(
    cell_id = "zero_one_beta_ordinary_fit",
    route = "zero_one_beta_response",
    data = zero_one_beta_data(160, master_seed + 3L, boundary_heavy = FALSE),
    expr = function(data) {
      drmTMB(
        bf(y ~ x, sigma ~ z, zoi ~ w, coi ~ v),
        family = zero_one_beta(),
        data = data
      )
    }
  ),
  list(
    cell_id = "zero_one_beta_boundary_heavy_fit",
    route = "zero_one_beta_response",
    data = zero_one_beta_data(160, master_seed + 4L, boundary_heavy = TRUE),
    expr = function(data) {
      drmTMB(
        bf(y ~ x, sigma ~ z, zoi ~ 1, coi ~ 1),
        family = zero_one_beta(),
        data = data
      )
    }
  ),
  list(
    cell_id = "missing_predictor_beta_fit",
    route = "missing_predictor_beta",
    data = missing_beta_data("beta", bad = FALSE),
    expr = function(data) {
      drmTMB(
        bf(y ~ z + mi(cover), sigma ~ 1),
        data = data,
        impute = list(cover = impute_model(cover ~ z, family = beta())),
        missing = miss_control(predictor = "model")
      )
    }
  ),
  list(
    cell_id = "missing_predictor_zero_one_beta_fit",
    route = "missing_predictor_zero_one_beta",
    data = missing_beta_data("zero_one_beta", bad = FALSE),
    expr = function(data) {
      drmTMB(
        bf(y ~ z + mi(cover), sigma ~ 1),
        data = data,
        impute = list(cover = impute_model(cover ~ z, family = zero_one_beta())),
        missing = miss_control(predictor = "model")
      )
    }
  )
)

validation_specs <- list(
  list(
    cell_id = "beta_response_zero_invalid",
    route = "beta_response",
    data = transform(beta_data(24, master_seed + 5L), y = replace(y, 1L, 0)),
    expr = function(data) drmTMB(bf(y ~ x, sigma ~ z), family = beta(), data = data),
    expected = "strictly between 0 and 1"
  ),
  list(
    cell_id = "beta_response_one_invalid",
    route = "beta_response",
    data = transform(beta_data(24, master_seed + 6L), y = replace(y, 1L, 1)),
    expr = function(data) drmTMB(bf(y ~ x, sigma ~ z), family = beta(), data = data),
    expected = "strictly between 0 and 1"
  ),
  list(
    cell_id = "zero_one_beta_outside_invalid",
    route = "zero_one_beta_response",
    data = transform(zero_one_beta_data(36, master_seed + 7L), y = replace(y, 1L, -0.1)),
    expr = function(data) {
      drmTMB(
        bf(y ~ x, sigma ~ z, zoi ~ 1, coi ~ 1),
        family = zero_one_beta(),
        data = data
      )
    },
    expected = "closed interval"
  ),
  list(
    cell_id = "zero_one_beta_no_interior_invalid",
    route = "zero_one_beta_response",
    data = transform(zero_one_beta_data(36, master_seed + 8L), y = rep(c(0, 1), length.out = 36)),
    expr = function(data) {
      drmTMB(
        bf(y ~ x, sigma ~ z, zoi ~ 1, coi ~ 1),
        family = zero_one_beta(),
        data = data
      )
    },
    expected = "at least one interior"
  ),
  list(
    cell_id = "missing_predictor_beta_boundary_invalid",
    route = "missing_predictor_beta",
    data = missing_beta_data("beta", bad = TRUE),
    expr = function(data) {
      drmTMB(
        bf(y ~ z + mi(cover), sigma ~ 1),
        data = data,
        impute = list(cover = impute_model(cover ~ z, family = beta())),
        missing = miss_control(predictor = "model")
      )
    },
    expected = "strictly between 0 and 1"
  ),
  list(
    cell_id = "missing_predictor_zero_one_beta_no_interior_invalid",
    route = "missing_predictor_zero_one_beta",
    data = missing_beta_data("zero_one_beta", bad = TRUE),
    expr = function(data) {
      drmTMB(
        bf(y ~ z + mi(cover), sigma ~ 1),
        data = data,
        impute = list(cover = impute_model(cover ~ z, family = zero_one_beta())),
        missing = miss_control(predictor = "model")
      )
    },
    expected = "interior value"
  )
)

fit_rows <- list()
check_rows <- list()
failure_rows <- list()

for (spec in fit_specs) {
  start_time <- proc.time()[["elapsed"]]
  result <- capture_fit(spec$expr(spec$data))
  elapsed <- proc.time()[["elapsed"]] - start_time
  fit <- result$value
  if (inherits(fit, "error")) {
    failure_rows[[length(failure_rows) + 1L]] <- data.frame(
      cell_id = spec$cell_id,
      route = spec$route,
      stage = "fit",
      message = conditionMessage(fit),
      stringsAsFactors = FALSE
    )
    next
  }
  checks <- check_drm(fit)
  report <- fit_report_row(fit)
  fit_rows[[length(fit_rows) + 1L]] <- data.frame(
    cell_id = spec$cell_id,
    route = spec$route,
    n = nrow(spec$data),
    n_boundary_response = sum(spec$data$y %in% c(0, 1), na.rm = TRUE),
    converged = isTRUE(fit$opt$convergence == 0),
    pdHess = isTRUE(fit$sdr$pdHess),
    max_abs_gradient = max_abs_gradient(fit),
    objective = fit$opt$objective,
    logLik = as.numeric(stats::logLik(fit)),
    AIC = stats::AIC(fit),
    BIC = stats::BIC(fit),
    elapsed = elapsed,
    warning_count = length(result$warnings),
    warnings = paste(result$warnings, collapse = " | "),
    fixed_gradient_status = first_check_value(checks, "fixed_gradient", "status"),
    hessian_status = first_check_value(checks, "hessian_positive_definite", "status"),
    standard_errors_status = first_check_value(checks, "standard_errors_finite", "status"),
    report,
    stringsAsFactors = FALSE
  )
  checks$cell_id <- spec$cell_id
  checks$route <- spec$route
  check_rows[[length(check_rows) + 1L]] <- checks[
    ,
    c("cell_id", "route", "check", "status", "value", "message"),
    drop = FALSE
  ]
}

validation_rows <- lapply(validation_specs, function(spec) {
  result <- capture_fit(spec$expr(spec$data))
  message <- if (inherits(result$value, "error")) {
    conditionMessage(result$value)
  } else {
    ""
  }
  data.frame(
    cell_id = spec$cell_id,
    route = spec$route,
    expected_error = spec$expected,
    errored = inherits(result$value, "error"),
    expected_message_seen = grepl(spec$expected, message),
    message = message,
    warning_count = length(result$warnings),
    warnings = paste(result$warnings, collapse = " | "),
    stringsAsFactors = FALSE
  )
})

fit_diagnostics <- do.call(rbind, fit_rows)
check_drm_rows <- do.call(rbind, check_rows)
validation <- do.call(rbind, validation_rows)
failures <- if (length(failure_rows)) {
  do.call(rbind, failure_rows)
} else {
  data.frame(
    cell_id = character(),
    route = character(),
    stage = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}

source_summary <- aggregate(
  cbind(alpha_floor_active, beta_floor_active) ~ route + log_sigma,
  data = source_grid,
  FUN = sum
)
names(source_summary)[names(source_summary) == "alpha_floor_active"] <-
  "n_alpha_floor_active"
names(source_summary)[names(source_summary) == "beta_floor_active"] <-
  "n_beta_floor_active"
source_denominator <- aggregate(
  alpha_floor_active ~ route + log_sigma,
  data = source_grid,
  FUN = length
)
source_summary$n_rows <- source_denominator$alpha_floor_active

run_summary <- data.frame(
  artifact = basename(artifact_dir),
  master_seed = master_seed,
  timestamp_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  git_sha = git_value("rev-parse", "HEAD"),
  git_branch = git_value("branch", "--show-current"),
  git_dirty = any(nzchar(git_lines("status", "--porcelain"))),
  command = paste(commandArgs(trailingOnly = FALSE), collapse = " "),
  n_source_rows = nrow(source_grid),
  n_fit_cells = length(fit_specs),
  n_fit_errors = nrow(failures),
  n_fit_cells_with_reported_shapes = sum(
    !is.na(fit_diagnostics$min_alpha) | !is.na(fit_diagnostics$min_beta_shape)
  ),
  n_validation_cells = nrow(validation),
  n_validation_expected_errors = sum(validation$expected_message_seen),
  max_reported_fit_alpha_floor_count = if (nrow(fit_diagnostics)) {
    max_or_na(fit_diagnostics$n_alpha_floor_active)
  } else {
    NA_integer_
  },
  max_reported_fit_beta_floor_count = if (nrow(fit_diagnostics)) {
    max_or_na(fit_diagnostics$n_beta_floor_active)
  } else {
    NA_integer_
  },
  stringsAsFactors = FALSE
)

write.csv(
  source_grid,
  file.path(tables_dir, "support-floor-source-grid.csv"),
  row.names = FALSE
)
write.csv(
  source_summary,
  file.path(tables_dir, "support-floor-source-summary.csv"),
  row.names = FALSE
)
write.csv(
  fit_diagnostics,
  file.path(tables_dir, "support-floor-fit-diagnostics.csv"),
  row.names = FALSE
)
write.csv(
  check_drm_rows,
  file.path(tables_dir, "support-floor-check-drm.csv"),
  row.names = FALSE
)
write.csv(
  validation,
  file.path(tables_dir, "support-floor-validation.csv"),
  row.names = FALSE
)
write.csv(
  failures,
  file.path(tables_dir, "support-floor-failures.csv"),
  row.names = FALSE
)
write.csv(
  run_summary,
  file.path(artifact_dir, "support-floor-run-summary.csv"),
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
    capture.output(sessionInfo())
  ),
  file.path(artifact_dir, "session-info.txt")
)

print(run_summary)
