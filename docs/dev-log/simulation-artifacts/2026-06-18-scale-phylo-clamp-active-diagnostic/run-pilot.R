args <- commandArgs(trailingOnly = FALSE)
file_arg <- grep("^--file=", args, value = TRUE)
script_path <- if (length(file_arg)) {
  normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
} else {
  normalizePath(
    "docs/dev-log/simulation-artifacts/2026-06-18-scale-phylo-clamp-active-diagnostic/run-pilot.R",
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
if (!requireNamespace("ape", quietly = TRUE)) {
  stop("Package 'ape' is required for this diagnostic artifact.", call. = FALSE)
}

master_seed <- 20260618L
data_seed <- 202L

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

make_scale_phylo_data <- function(shock, seed) {
  set.seed(seed)
  n_tip <- 80L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("t", seq_len(n_tip))
  relatedness <- ape::vcv(tree, corr = TRUE)
  chol_relatedness <- t(chol(relatedness))
  phylo_effect <- as.vector(chol_relatedness %*% stats::rnorm(n_tip))
  x <- stats::rnorm(n_tip)
  species <- factor(tree$tip.label, levels = tree$tip.label)
  y <- 0.2 + 0.5 * x + 0.5 * phylo_effect + stats::rnorm(n_tip, 0, exp(-0.3))
  y[c(5L, 40L, 70L)] <- y[c(5L, 40L, 70L)] +
    shock * c(1, -1.1, 1.2)

  list(
    data = data.frame(y = y, x = x, species = species),
    tree = tree,
    n_tip = n_tip
  )
}

control_from_label <- function(label) {
  switch(
    label,
    default = drm_control(se = FALSE),
    disabled = drm_control(se = FALSE, logsigma_clamp = NULL),
    wide = drm_control(se = FALSE, logsigma_clamp = c(-25, 25)),
    stop("Unknown clamp label: ", label, call. = FALSE)
  )
}

conditions <- expand.grid(
  stress = c("moderate_residual_shock", "extreme_residual_shock"),
  clamp = c("default", "disabled", "wide"),
  stringsAsFactors = FALSE
)
conditions$shock <- ifelse(
  conditions$stress == "moderate_residual_shock",
  50,
  50000
)
conditions$seed <- data_seed
conditions$description <- ifelse(
  conditions$stress == "moderate_residual_shock",
  "One observation per tip with three large residual shocks.",
  "One observation per tip with three deliberately extreme residual shocks."
)

fit_rows <- list()
check_rows <- list()
failure_rows <- list()

for (i in seq_len(nrow(conditions))) {
  cell <- conditions[i, , drop = FALSE]
  sim <- make_scale_phylo_data(shock = cell$shock[[1L]], seed = cell$seed[[1L]])
  tree <- sim$tree
  form <- bf(
    y ~ x + phylo(1 | species, tree = tree),
    sigma ~ x + phylo(1 | species, tree = tree)
  )

  start_time <- proc.time()[["elapsed"]]
  result <- capture_fit(
    drmTMB(
      form,
      data = sim$data,
      control = control_from_label(cell$clamp[[1L]])
    )
  )
  elapsed <- proc.time()[["elapsed"]] - start_time
  fit <- result$value
  if (inherits(fit, "error")) {
    failure_rows[[length(failure_rows) + 1L]] <- data.frame(
      stress = cell$stress,
      clamp = cell$clamp,
      shock = cell$shock,
      seed = cell$seed,
      stage = "fit",
      message = conditionMessage(fit),
      stringsAsFactors = FALSE
    )
    next
  }

  report <- fit$obj$report()
  log_sigma <- as.numeric(report$log_sigma)
  checks <- check_drm(fit)

  fit_rows[[length(fit_rows) + 1L]] <- data.frame(
    stress = cell$stress,
    clamp = cell$clamp,
    shock = cell$shock,
    seed = cell$seed,
    n_tip = sim$n_tip,
    n_per_tip = 1L,
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
    min_log_sigma = min(log_sigma, na.rm = TRUE),
    max_log_sigma = max(log_sigma, na.rm = TRUE),
    n_log_sigma_lt_minus12 = sum(log_sigma < -12),
    n_log_sigma_gt_12 = sum(log_sigma > 12),
    n_log_sigma_gt_15 = sum(log_sigma > 15),
    logsigma_clamp_status = check_status(checks, "logsigma_clamp_active"),
    logsigma_clamp_value = check_value(checks, "logsigma_clamp_active"),
    logsigma_clamp_message = check_message(checks, "logsigma_clamp_active"),
    scale_phylo_status = check_status(checks, "scale_phylo_identifiability"),
    scale_phylo_value = check_value(checks, "scale_phylo_identifiability"),
    scale_phylo_message = check_message(checks, "scale_phylo_identifiability"),
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
  checks$stress <- cell$stress
  checks$clamp <- cell$clamp
  checks$shock <- cell$shock
  check_rows[[length(check_rows) + 1L]] <- checks[,
    c("stress", "clamp", "shock", "check", "status", "value", "message"),
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
    stress = character(),
    clamp = character(),
    shock = numeric(),
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
    stress = character(),
    clamp = character(),
    shock = numeric(),
    seed = integer(),
    stage = character(),
    message = character(),
    stringsAsFactors = FALSE
  )
}

condition_summary <- if (nrow(conditions)) {
  data.frame(
    stress = conditions$stress,
    clamp = conditions$clamp,
    shock = conditions$shock,
    n_requested = 1L,
    n_attempted = 1L,
    n_fit_error = as.integer(
      paste(conditions$stress, conditions$clamp) %in%
        paste(failures$stress, failures$clamp)
    ),
    n_warning = vapply(
      seq_len(nrow(conditions)),
      function(j) {
        row <- fit_diagnostics[
          fit_diagnostics$stress == conditions$stress[[j]] &
            fit_diagnostics$clamp == conditions$clamp[[j]],
          ,
          drop = FALSE
        ]
        if (!nrow(row)) 0L else as.integer(row$warning_count > 0L)
      },
      integer(1L)
    ),
    n_converged = vapply(
      seq_len(nrow(conditions)),
      function(j) {
        row <- fit_diagnostics[
          fit_diagnostics$stress == conditions$stress[[j]] &
            fit_diagnostics$clamp == conditions$clamp[[j]],
          ,
          drop = FALSE
        ]
        if (!nrow(row)) 0L else as.integer(isTRUE(row$converged[[1L]]))
      },
      integer(1L)
    ),
    n_pdHess = vapply(
      seq_len(nrow(conditions)),
      function(j) {
        row <- fit_diagnostics[
          fit_diagnostics$stress == conditions$stress[[j]] &
            fit_diagnostics$clamp == conditions$clamp[[j]],
          ,
          drop = FALSE
        ]
        if (!nrow(row)) 0L else as.integer(isTRUE(row$pdHess[[1L]]))
      },
      integer(1L)
    ),
    n_check_drm_warning_or_error = vapply(
      seq_len(nrow(conditions)),
      function(j) {
        rows <- check_drm_rows[
          check_drm_rows$stress == conditions$stress[[j]] &
            check_drm_rows$clamp == conditions$clamp[[j]],
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
  data_seed = data_seed,
  timestamp_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  git_sha = git_value("rev-parse", "HEAD"),
  git_branch = git_value("branch", "--show-current"),
  git_dirty = any(nzchar(git_lines("status", "--porcelain"))),
  command = paste(commandArgs(trailingOnly = FALSE), collapse = " "),
  n_conditions = nrow(conditions),
  n_fit_errors = nrow(failures),
  n_converged = if (nrow(fit_diagnostics)) {
    sum(fit_diagnostics$converged)
  } else {
    0L
  },
  n_pdHess = if (nrow(fit_diagnostics)) sum(fit_diagnostics$pdHess) else 0L,
  n_false_convergence = if (nrow(fit_diagnostics)) {
    sum(fit_diagnostics$convergence_code != 0L)
  } else {
    0L
  },
  n_clamp_active_warnings = sum(
    check_drm_rows$check == "logsigma_clamp_active" &
      check_drm_rows$status == "warning"
  ),
  n_scale_phylo_notes = sum(
    check_drm_rows$check == "scale_phylo_identifiability" &
      check_drm_rows$status == "note"
  ),
  max_log_sigma = if (nrow(fit_diagnostics)) {
    max(fit_diagnostics$max_log_sigma, na.rm = TRUE)
  } else {
    NA_real_
  },
  min_log_sigma = if (nrow(fit_diagnostics)) {
    min(fit_diagnostics$min_log_sigma, na.rm = TRUE)
  } else {
    NA_real_
  },
  max_abs_gradient = if (nrow(fit_diagnostics)) {
    max(fit_diagnostics$max_abs_gradient, na.rm = TRUE)
  } else {
    NA_real_
  },
  stringsAsFactors = FALSE
)

write.csv(
  conditions,
  file.path(tables_dir, "scale-phylo-clamp-conditions.csv"),
  row.names = FALSE
)
write.csv(
  fit_diagnostics,
  file.path(tables_dir, "scale-phylo-clamp-fit-diagnostics.csv"),
  row.names = FALSE
)
write.csv(
  condition_summary,
  file.path(tables_dir, "scale-phylo-clamp-condition-summary.csv"),
  row.names = FALSE
)
write.csv(
  check_drm_rows,
  file.path(tables_dir, "scale-phylo-clamp-check-drm.csv"),
  row.names = FALSE
)
write.csv(
  failures,
  file.path(tables_dir, "scale-phylo-clamp-failures.csv"),
  row.names = FALSE
)
write.csv(
  run_summary,
  file.path(artifact_dir, "scale-phylo-clamp-run-summary.csv"),
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

cat("scale-phylo clamp-active diagnostic complete\n")
print(run_summary)
