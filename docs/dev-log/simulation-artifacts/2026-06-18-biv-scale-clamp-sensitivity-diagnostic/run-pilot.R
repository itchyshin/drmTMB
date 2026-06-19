args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "docs/dev-log/simulation-artifacts/2026-06-18-biv-scale-clamp-sensitivity-diagnostic/run-pilot.R",
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
n_rep <- 10L
n <- 120L

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

control_from_config <- function(config_id) {
  switch(
    config_id,
    off = drm_control(logsigma_clamp = NULL),
    default = drm_control(),
    wide = drm_control(logsigma_clamp = c(-25, 25)),
    stop("Unknown clamp configuration: ", config_id, call. = FALSE)
  )
}

make_data <- function(condition, seed) {
  set.seed(seed)
  x <- stats::runif(n, -1, 1)
  z1 <- stats::runif(n, -1, 1)
  z2 <- stats::runif(n, -1, 1)
  mu1 <- condition$beta_mu1_intercept + condition$beta_mu1_x * x
  mu2 <- condition$beta_mu2_intercept + condition$beta_mu2_x * x
  log_sigma1 <- condition$beta_sigma1_intercept +
    condition$beta_sigma1_z1 * z1
  log_sigma2 <- condition$beta_sigma2_intercept +
    condition$beta_sigma2_z2 * z2
  rho12 <- condition$rho12
  e1 <- stats::rnorm(n)
  e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)

  data.frame(
    y1 = mu1 + exp(log_sigma1) * e1,
    y2 = mu2 + exp(log_sigma2) * e2,
    x = x,
    z1 = z1,
    z2 = z2,
    truth_mu1 = mu1,
    truth_mu2 = mu2,
    truth_log_sigma1 = log_sigma1,
    truth_log_sigma2 = log_sigma2,
    stringsAsFactors = FALSE
  )
}

conditions <- data.frame(
  condition_id = c(
    "ordinary_biv_scale",
    "sigma1_above_default",
    "sigma2_above_default",
    "both_scales_above_default"
  ),
  description = c(
    "ordinary bivariate scale; expected clamp inactive",
    "legitimate huge unstandardized sigma1 scale above default band",
    "legitimate huge unstandardized sigma2 scale above default band",
    "legitimate huge unstandardized sigma1 and sigma2 scales above default band"
  ),
  beta_mu1_intercept = 0.2,
  beta_mu1_x = 0.4,
  beta_mu2_intercept = -0.1,
  beta_mu2_x = -0.3,
  beta_sigma1_intercept = c(-0.2, 16.0, -0.2, 16.0),
  beta_sigma1_z1 = c(0.2, 0.25, 0.2, 0.25),
  beta_sigma2_intercept = c(0.1, 0.1, 16.0, 15.5),
  beta_sigma2_z2 = c(-0.15, -0.15, -0.25, -0.25),
  rho12 = 0.35,
  stringsAsFactors = FALSE
)

configs <- data.frame(
  config_id = c("off", "default", "wide"),
  logsigma_clamp_lo = c(NA_real_, -12, -25),
  logsigma_clamp_hi = c(NA_real_, 12, 25),
  logsigma_clamp_margin = c(NA_real_, 3, 3),
  interpretation = c(
    "unclamped reference",
    "default drmTMB overflow guard",
    "widened guard for huge unstandardized scales"
  ),
  stringsAsFactors = FALSE
)

set.seed(master_seed)
replicate_seeds <- sample.int(.Machine$integer.max, nrow(conditions) * n_rep)
seed_index <- 0L
fit_rows <- list()
check_rows <- list()
failure_rows <- list()
row_index <- 0L

for (condition_row in seq_len(nrow(conditions))) {
  condition <- conditions[condition_row, , drop = FALSE]
  for (replicate in seq_len(n_rep)) {
    seed_index <- seed_index + 1L
    seed <- replicate_seeds[[seed_index]]
    dat <- make_data(condition, seed)
    for (config_row in seq_len(nrow(configs))) {
      config <- configs[config_row, , drop = FALSE]
      start_time <- proc.time()[["elapsed"]]
      result <- capture_fit(
        drmTMB(
          bf(
            mu1 = y1 ~ x,
            mu2 = y2 ~ x,
            sigma1 = ~z1,
            sigma2 = ~z2,
            rho12 = ~1
          ),
          family = biv_gaussian(),
          data = dat,
          control = control_from_config(config$config_id[[1L]])
        )
      )
      elapsed <- proc.time()[["elapsed"]] - start_time
      fit <- result$value
      if (inherits(fit, "error")) {
        failure_rows[[length(failure_rows) + 1L]] <- data.frame(
          condition_id = condition$condition_id,
          replicate = replicate,
          seed = seed,
          config_id = config$config_id,
          stage = "fit",
          message = conditionMessage(fit),
          stringsAsFactors = FALSE
        )
        next
      }

      report <- fit$obj$report()
      coef_fit <- coef(fit)
      vc <- tryCatch(stats::vcov(fit), error = function(e) NULL)
      se <- setNames(
        rep(NA_real_, 7L),
        c(
          "mu1:(Intercept)",
          "mu1:x",
          "mu2:(Intercept)",
          "mu2:x",
          "sigma1:(Intercept)",
          "sigma1:z1",
          "sigma2:(Intercept)"
        )
      )
      se <- c(se, "sigma2:z2" = NA_real_, "rho12:(Intercept)" = NA_real_)
      if (is.matrix(vc)) {
        diag_vc <- diag(vc)
        se[names(diag_vc)] <- sqrt(pmax(diag_vc, 0))
      }
      checks <- check_drm(fit)
      raw_log_sigma1 <- drop(stats::model.matrix(~z1, dat) %*% coef_fit$sigma1)
      raw_log_sigma2 <- drop(stats::model.matrix(~z2, dat) %*% coef_fit$sigma2)
      log_sigma1 <- as.numeric(report$log_sigma1)
      log_sigma2 <- as.numeric(report$log_sigma2)
      max_delta1 <- max(abs(raw_log_sigma1 - log_sigma1), na.rm = TRUE)
      max_delta2 <- max(abs(raw_log_sigma2 - log_sigma2), na.rm = TRUE)

      row_index <- row_index + 1L
      fit_rows[[row_index]] <- data.frame(
        condition_id = condition$condition_id,
        replicate = replicate,
        seed = seed,
        config_id = config$config_id,
        n = nrow(dat),
        converged = isTRUE(fit$opt$convergence == 0),
        convergence_code = as.integer(fit$opt$convergence),
        convergence_message = if (!is.null(fit$opt$message)) {
          fit$opt$message
        } else {
          NA_character_
        },
        pdHess = isTRUE(fit$sdr$pdHess),
        sdreport_status = check_status(checks, "sdreport_status"),
        beta_mu1_intercept = unname(coef_fit$mu1["(Intercept)"]),
        beta_mu1_x = unname(coef_fit$mu1["x"]),
        beta_mu2_intercept = unname(coef_fit$mu2["(Intercept)"]),
        beta_mu2_x = unname(coef_fit$mu2["x"]),
        beta_sigma1_intercept = unname(coef_fit$sigma1["(Intercept)"]),
        beta_sigma1_z1 = unname(coef_fit$sigma1["z1"]),
        beta_sigma2_intercept = unname(coef_fit$sigma2["(Intercept)"]),
        beta_sigma2_z2 = unname(coef_fit$sigma2["z2"]),
        beta_rho12_intercept = unname(coef_fit$rho12["(Intercept)"]),
        se_mu1_intercept = unname(se["mu1:(Intercept)"]),
        se_mu1_x = unname(se["mu1:x"]),
        se_mu2_intercept = unname(se["mu2:(Intercept)"]),
        se_mu2_x = unname(se["mu2:x"]),
        se_sigma1_intercept = unname(se["sigma1:(Intercept)"]),
        se_sigma1_z1 = unname(se["sigma1:z1"]),
        se_sigma2_intercept = unname(se["sigma2:(Intercept)"]),
        se_sigma2_z2 = unname(se["sigma2:z2"]),
        se_rho12_intercept = unname(se["rho12:(Intercept)"]),
        raw_log_sigma1_min = min(raw_log_sigma1),
        raw_log_sigma1_max = max(raw_log_sigma1),
        raw_log_sigma2_min = min(raw_log_sigma2),
        raw_log_sigma2_max = max(raw_log_sigma2),
        reported_log_sigma1_min = min(log_sigma1),
        reported_log_sigma1_max = max(log_sigma1),
        reported_log_sigma2_min = min(log_sigma2),
        reported_log_sigma2_max = max(log_sigma2),
        max_abs_clamp_delta_sigma1 = max_delta1,
        max_abs_clamp_delta_sigma2 = max_delta2,
        clamp_active = max(max_delta1, max_delta2, na.rm = TRUE) > 1e-3,
        logsigma_clamp_status = check_status(checks, "logsigma_clamp_active"),
        logsigma_clamp_value = check_value(checks, "logsigma_clamp_active"),
        logsigma_clamp_message = check_message(checks, "logsigma_clamp_active"),
        rho12_boundary_status = check_status(checks, "rho12_boundary"),
        rho12_boundary_value = check_value(checks, "rho12_boundary"),
        max_abs_gradient = max_abs_gradient(fit),
        fixed_gradient_status = check_status(checks, "fixed_gradient"),
        fixed_gradient_value = check_value(checks, "fixed_gradient"),
        fixed_gradient_component = gradient_component(
          check_value(checks, "fixed_gradient")
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
      checks$condition_id <- condition$condition_id
      checks$replicate <- replicate
      checks$config_id <- config$config_id
      check_rows[[length(check_rows) + 1L]] <- checks[,
        c(
          "condition_id",
          "replicate",
          "config_id",
          "check",
          "status",
          "value",
          "message"
        ),
        drop = FALSE
      ]
    }
  }
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
    condition_id = character(),
    replicate = integer(),
    config_id = character(),
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
    condition_id = character(),
    replicate = integer(),
    seed = integer(),
    config_id = character(),
    stage = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}

truth <- conditions[,
  c(
    "condition_id",
    "beta_mu1_intercept",
    "beta_mu1_x",
    "beta_mu2_intercept",
    "beta_mu2_x",
    "beta_sigma1_intercept",
    "beta_sigma1_z1",
    "beta_sigma2_intercept",
    "beta_sigma2_z2",
    "rho12"
  )
]
names(truth) <- c(
  "condition_id",
  "truth_mu1_intercept",
  "truth_mu1_x",
  "truth_mu2_intercept",
  "truth_mu2_x",
  "truth_sigma1_intercept",
  "truth_sigma1_z1",
  "truth_sigma2_intercept",
  "truth_sigma2_z2",
  "truth_rho12"
)
fit_diagnostics <- merge(
  fit_diagnostics,
  truth,
  by = "condition_id",
  all.x = TRUE,
  sort = FALSE
)
fit_diagnostics$bias_mu1_intercept <-
  fit_diagnostics$beta_mu1_intercept - fit_diagnostics$truth_mu1_intercept
fit_diagnostics$bias_mu1_x <-
  fit_diagnostics$beta_mu1_x - fit_diagnostics$truth_mu1_x
fit_diagnostics$bias_mu2_intercept <-
  fit_diagnostics$beta_mu2_intercept - fit_diagnostics$truth_mu2_intercept
fit_diagnostics$bias_mu2_x <-
  fit_diagnostics$beta_mu2_x - fit_diagnostics$truth_mu2_x
fit_diagnostics$bias_sigma1_intercept <-
  fit_diagnostics$beta_sigma1_intercept -
  fit_diagnostics$truth_sigma1_intercept
fit_diagnostics$bias_sigma1_z1 <-
  fit_diagnostics$beta_sigma1_z1 - fit_diagnostics$truth_sigma1_z1
fit_diagnostics$bias_sigma2_intercept <-
  fit_diagnostics$beta_sigma2_intercept -
  fit_diagnostics$truth_sigma2_intercept
fit_diagnostics$bias_sigma2_z2 <-
  fit_diagnostics$beta_sigma2_z2 - fit_diagnostics$truth_sigma2_z2

ref <- fit_diagnostics[
  fit_diagnostics$config_id == "off" &
    fit_diagnostics$converged &
    fit_diagnostics$pdHess,
  ,
  drop = FALSE
]
ref <- ref[,
  c(
    "condition_id",
    "replicate",
    "beta_mu1_intercept",
    "beta_mu1_x",
    "beta_mu2_intercept",
    "beta_mu2_x",
    "beta_sigma1_intercept",
    "beta_sigma1_z1",
    "beta_sigma2_intercept",
    "beta_sigma2_z2",
    "logLik",
    "objective",
    "AIC",
    "BIC"
  ),
  drop = FALSE
]
names(ref)[-(1:2)] <- paste0(names(ref)[-(1:2)], "_off")
comparisons <- merge(
  fit_diagnostics,
  ref,
  by = c("condition_id", "replicate"),
  all.x = TRUE,
  sort = FALSE
)
for (field in c(
  "beta_mu1_intercept",
  "beta_mu1_x",
  "beta_mu2_intercept",
  "beta_mu2_x",
  "beta_sigma1_intercept",
  "beta_sigma1_z1",
  "beta_sigma2_intercept",
  "beta_sigma2_z2",
  "logLik",
  "objective",
  "AIC",
  "BIC"
)) {
  comparisons[[paste0(field, "_diff_vs_off")]] <-
    comparisons[[field]] - comparisons[[paste0(field, "_off")]]
}

ok_rate <- function(x) mean(x, na.rm = TRUE)
max_abs <- function(x) {
  if (!any(is.finite(x))) {
    return(NA_real_)
  }
  max(abs(x), na.rm = TRUE)
}
mcse_mean <- function(x) {
  if (sum(is.finite(x)) <= 1L) {
    return(NA_real_)
  }
  stats::sd(x, na.rm = TRUE) / sqrt(sum(is.finite(x)))
}

aggregate_rows <- lapply(
  split(
    comparisons,
    interaction(comparisons$condition_id, comparisons$config_id, drop = TRUE)
  ),
  function(x) {
    data.frame(
      condition_id = x$condition_id[[1]],
      config_id = x$config_id[[1]],
      n_requested = n_rep,
      n_fit_error = sum(
        failures$condition_id == x$condition_id[[1]] &
          failures$config_id == x$config_id[[1]]
      ),
      n_ok = nrow(x),
      convergence_rate = ok_rate(x$converged),
      pdHess_rate = ok_rate(x$pdHess),
      warning_rate = mean(x$warning_count > 0L, na.rm = TRUE),
      clamp_active_rate = ok_rate(x$clamp_active),
      check_drm_warning_or_error_rate = mean(
        vapply(
          seq_len(nrow(x)),
          function(i) {
            rows <- check_drm_rows[
              check_drm_rows$condition_id == x$condition_id[[i]] &
                check_drm_rows$config_id == x$config_id[[i]] &
                check_drm_rows$replicate == x$replicate[[i]],
              ,
              drop = FALSE
            ]
            any(rows$status %in% c("warning", "error"))
          },
          logical(1L)
        )
      ),
      logsigma_clamp_warning_count = sum(
        x$logsigma_clamp_status == "warning",
        na.rm = TRUE
      ),
      fixed_gradient_warning_count = sum(
        x$fixed_gradient_status == "warning",
        na.rm = TRUE
      ),
      max_reported_log_sigma1 = max(x$reported_log_sigma1_max, na.rm = TRUE),
      max_reported_log_sigma2 = max(x$reported_log_sigma2_max, na.rm = TRUE),
      max_abs_clamp_delta_sigma1 = max_abs(x$max_abs_clamp_delta_sigma1),
      max_abs_clamp_delta_sigma2 = max_abs(x$max_abs_clamp_delta_sigma2),
      max_abs_sigma1_intercept_diff_vs_off = max_abs(
        x$beta_sigma1_intercept_diff_vs_off
      ),
      max_abs_sigma2_intercept_diff_vs_off = max_abs(
        x$beta_sigma2_intercept_diff_vs_off
      ),
      max_abs_logLik_diff_vs_off = max_abs(x$logLik_diff_vs_off),
      mcse_logLik_diff_vs_off = mcse_mean(x$logLik_diff_vs_off),
      stringsAsFactors = FALSE
    )
  }
)
aggregate_summary <- do.call(rbind, aggregate_rows)
aggregate_summary <- aggregate_summary[
  order(aggregate_summary$condition_id, aggregate_summary$config_id),
  ,
  drop = FALSE
]

condition_summary <- aggregate(
  cbind(converged, pdHess, clamp_active, warning_count) ~ condition_id,
  data = fit_diagnostics,
  FUN = function(x) sum(as.numeric(x), na.rm = TRUE)
)
names(condition_summary) <- c(
  "condition_id",
  "n_converged",
  "n_pdHess",
  "n_clamp_active",
  "n_warnings"
)
condition_summary$n_requested <- n_rep * nrow(configs)
condition_summary$n_fit_error <- vapply(
  condition_summary$condition_id,
  function(x) sum(failures$condition_id == x),
  integer(1L)
)

run_summary <- data.frame(
  artifact = basename(artifact_dir),
  master_seed = master_seed,
  timestamp_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  git_sha = git_value("rev-parse", "HEAD"),
  git_branch = git_value("branch", "--show-current"),
  git_dirty = any(nzchar(git_lines("status", "--porcelain"))),
  command = paste(commandArgs(trailingOnly = FALSE), collapse = " "),
  n_conditions = nrow(conditions),
  n_configs = nrow(configs),
  n_rep = n_rep,
  n_requested = nrow(conditions) * nrow(configs) * n_rep,
  n_fit_errors = nrow(failures),
  n_converged = if (nrow(fit_diagnostics)) {
    sum(fit_diagnostics$converged)
  } else {
    0L
  },
  n_pdHess = if (nrow(fit_diagnostics)) sum(fit_diagnostics$pdHess) else 0L,
  n_clamp_active_warnings = sum(
    check_drm_rows$check == "logsigma_clamp_active" &
      check_drm_rows$status == "warning"
  ),
  n_fixed_gradient_warnings = sum(
    check_drm_rows$check == "fixed_gradient" &
      check_drm_rows$status == "warning"
  ),
  max_reported_log_sigma1 = if (nrow(fit_diagnostics)) {
    max(fit_diagnostics$reported_log_sigma1_max, na.rm = TRUE)
  } else {
    NA_real_
  },
  max_reported_log_sigma2 = if (nrow(fit_diagnostics)) {
    max(fit_diagnostics$reported_log_sigma2_max, na.rm = TRUE)
  } else {
    NA_real_
  },
  max_abs_logLik_diff_vs_off = if (nrow(comparisons)) {
    max_abs(comparisons$logLik_diff_vs_off)
  } else {
    NA_real_
  },
  stringsAsFactors = FALSE
)

write.csv(
  conditions,
  file.path(tables_dir, "biv-scale-clamp-conditions.csv"),
  row.names = FALSE
)
write.csv(
  configs,
  file.path(tables_dir, "biv-scale-clamp-configs.csv"),
  row.names = FALSE
)
write.csv(
  fit_diagnostics,
  file.path(tables_dir, "biv-scale-clamp-fit-diagnostics.csv"),
  row.names = FALSE
)
write.csv(
  comparisons,
  file.path(tables_dir, "biv-scale-clamp-comparisons.csv"),
  row.names = FALSE
)
write.csv(
  aggregate_summary,
  file.path(tables_dir, "biv-scale-clamp-aggregate-summary.csv"),
  row.names = FALSE
)
write.csv(
  condition_summary,
  file.path(tables_dir, "biv-scale-clamp-condition-summary.csv"),
  row.names = FALSE
)
write.csv(
  check_drm_rows,
  file.path(tables_dir, "biv-scale-clamp-check-drm.csv"),
  row.names = FALSE
)
write.csv(
  failures,
  file.path(tables_dir, "biv-scale-clamp-failures.csv"),
  row.names = FALSE
)
write.csv(
  run_summary,
  file.path(artifact_dir, "biv-scale-clamp-run-summary.csv"),
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

cat("bivariate scale clamp-sensitivity diagnostic complete\n")
print(run_summary)
