#!/usr/bin/env Rscript

# One immutable data set per DRAC/Fir array task for the marginal homogeneous
# Toeplitz profile-interval campaign. Campaign mode always writes one result,
# including a fit or profile failure, before returning a nonzero status.

args <- commandArgs(trailingOnly = TRUE)
task_arg <- grep("^--campaign-task=[0-9]+$", args, value = TRUE)
if (length(args) != 1L || length(task_arg) != 1L) {
  stop("Usage: Rscript --vanilla tools/run-temporal-homtoep-marginal-profile-campaign.R --campaign-task=<1..4000>", call. = FALSE)
}
task <- as.integer(sub("^--campaign-task=", "", task_arg))
if (!is.finite(task) || task < 1L || task > 4000L) {
  stop("Campaign task must be an integer from 1 through 4000.", call. = FALSE)
}
if (!identical(Sys.getenv("DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_AUTHORIZED"), "1")) {
  stop("Campaign mode requires DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_AUTHORIZED=1.", call. = FALSE)
}
source_commit <- Sys.getenv("DRMTMB_TEMPORAL_HOMTOEP_SOURCE_COMMIT")
if (!grepl("^[0-9a-f]{40}$", source_commit)) {
  stop("Campaign mode requires a 40-character DRMTMB_TEMPORAL_HOMTOEP_SOURCE_COMMIT.", call. = FALSE)
}
campaign_root <- Sys.getenv("DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_OUT")
if (!nzchar(campaign_root)) {
  stop("Campaign mode requires DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_OUT.", call. = FALSE)
}
attempt <- as.integer(Sys.getenv("DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_ATTEMPT", "1"))
if (!is.finite(attempt) || attempt < 1L) {
  stop("DRMTMB_TEMPORAL_HOMTOEP_CAMPAIGN_ATTEMPT must be a positive integer.", call. = FALSE)
}

root <- normalizePath(".", mustWork = TRUE)
if (!file.exists(file.path(root, "DESCRIPTION"))) {
  stop("Run this script from the frozen drmTMB source root.", call. = FALSE)
}
worker <- file.path(root, "tools", "run-temporal-homtoep-marginal-profile-campaign.R")
out_dir <- file.path(campaign_root, sprintf("task-%04d", task), sprintf("attempt-%03d", attempt))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
needed <- c("raw-attempts.csv", "profile-results.csv", "profile-intervals.csv",
            "provenance.csv", "session-info.txt", "RESULTS.md")
if (any(file.exists(file.path(out_dir, needed)))) {
  stop("Refuse to overwrite retained campaign task evidence.", call. = FALSE)
}

cell_index <- (task - 1L) %/% 1000L + 1L
replicate <- (task - 1L) %% 1000L + 1L
cells <- data.frame(
  cell = c("P1", "P2", "P3", "S1"),
  role = c("primary", "primary", "primary", "stress"),
  n_id = c(80L, 80L, 80L, 20L),
  n_time = c(6L, 6L, 6L, 4L),
  stringsAsFactors = FALSE
)
cell <- cells[cell_index, , drop = FALSE]
seed <- 2026091500L + task
truth <- c("(Intercept)" = 0, between = 0.5, within = 0.5)
expected_parm <- paste0("fixef:mu:", names(truth))

interval_rows_unavailable <- function(reason, estimates = NULL) {
  estimate <- rep(NA_real_, length(expected_parm))
  if (!is.null(estimates)) {
    matched <- match(names(truth), names(estimates))
    estimate[!is.na(matched)] <- unname(estimates[matched[!is.na(matched)]])
  }
  data.frame(
    task = task, attempt = attempt, fixture = sprintf("%s_%04d", cell$cell, replicate),
    cell = cell$cell, role = cell$role, replicate = replicate, seed = seed,
    parm = expected_parm, coefficient = names(truth), truth = unname(truth),
    estimate = estimate, lower = NA_real_, upper = NA_real_,
    interval_available = FALSE, covered = FALSE, conf.status = reason,
    stringsAsFactors = FALSE
  )
}

interval_rows_from_profile <- function(intervals, estimates) {
  if (inherits(intervals, "error") || !all(expected_parm %in% intervals$parm)) {
    reason <- if (inherits(intervals, "error")) conditionMessage(intervals) else "missing_mean_profile_targets"
    return(interval_rows_unavailable(reason, estimates))
  }
  rows <- intervals[match(expected_parm, intervals$parm), , drop = FALSE]
  available <- rows$conf.status == "profile" &
    is.finite(rows$lower) & is.finite(rows$upper)
  data.frame(
    task = task, attempt = attempt, fixture = sprintf("%s_%04d", cell$cell, replicate),
    cell = cell$cell, role = cell$role, replicate = replicate, seed = seed,
    parm = expected_parm, coefficient = names(truth), truth = unname(truth),
    estimate = unname(estimates[names(truth)]), lower = rows$lower, upper = rows$upper,
    interval_available = available,
    covered = available & rows$lower <= unname(truth) & unname(truth) <= rows$upper,
    conf.status = rows$conf.status, stringsAsFactors = FALSE
  )
}

rho_for <- function(name) {
  if (identical(name, "P1")) return(c(1, 0.55^(1:5)))
  if (identical(name, "P2")) return(drmTMB:::temporal_homtoep_correlations(c(
    atanh(0.45), atanh(-0.30), atanh(0.20), atanh(0.10), atanh(-0.05)
  )))
  if (identical(name, "P3")) return(drmTMB:::temporal_homtoep_correlations(c(
    atanh(-0.45), atanh(0.15), atanh(-0.10), atanh(0.05), 0
  )))
  drmTMB:::temporal_homtoep_correlations(c(atanh(0.80), atanh(-0.20), atanh(0.10)))
}

simulate_cell <- function() {
  set.seed(seed)
  n_id <- cell$n_id[[1L]]
  n_time <- cell$n_time[[1L]]
  id_levels <- sprintf("id_%03d", seq_len(n_id))
  id <- factor(rep(id_levels, each = n_time), levels = id_levels)
  occasion <- rep(seq.int(0L, n_time - 1L), n_id)
  between <- rep(rep(c(-0.5, 0.5), length.out = n_id), each = n_time)
  within <- unlist(lapply(seq_len(n_id), function(i) {
    sample(rep(c(-0.5, 0.5), length.out = n_time))
  }), use.names = FALSE)
  root <- chol(toeplitz(rho_for(cell$cell[[1L]])))
  error <- unlist(lapply(seq_len(n_id), function(i) {
    as.vector(0.8 * t(root) %*% rnorm(n_time))
  }), use.names = FALSE)
  data.frame(
    y = truth[["(Intercept)"]] + truth[["between"]] * between +
      truth[["within"]] * within + error,
    id = id, occasion = occasion, between = between, within = within
  )
}

warnings <- character()
started <- proc.time()[["elapsed"]]
load_error <- NULL
fit_result <- NULL
tryCatch(
  suppressPackageStartupMessages(pkgload::load_all(root, compile = TRUE, quiet = TRUE)),
  error = function(e) load_error <<- conditionMessage(e)
)
if (is.null(load_error)) {
  fit_result <- tryCatch(
    withCallingHandlers(
      list(
        fit = drmTMB::drmTMB(
          drmTMB::bf(y ~ between + within +
            temporal(1 | id, time = occasion, structure = "homtoep"), sigma ~ 1),
          data = simulate_cell(), family = gaussian(), REML = FALSE
        ),
        error = NA_character_
      ),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) list(fit = NULL, error = conditionMessage(e))
  )
}
fit_elapsed_sec <- proc.time()[["elapsed"]] - started

profile_elapsed_sec <- NA_real_
profile_warnings <- character()
if (!is.null(load_error) || is.null(fit_result$fit)) {
  reason <- if (!is.null(load_error)) paste0("load_error: ", load_error) else paste0("fit_error: ", fit_result$error)
  results <- data.frame(
    task = task, attempt = attempt, fixture = sprintf("%s_%04d", cell$cell, replicate),
    cell = cell$cell, role = cell$role, replicate = replicate, seed = seed,
    n_id = cell$n_id, n_time = cell$n_time, selected = FALSE, objective = NA_real_,
    convergence = NA_integer_, pd_hessian = NA, fit_elapsed_sec = fit_elapsed_sec,
    profile_elapsed_sec = profile_elapsed_sec, n_intervals = 0L,
    interval_available = FALSE, warning = paste(warnings, collapse = " | "),
    error = reason, stringsAsFactors = FALSE
  )
  attempts <- data.frame(
    task = task, attempt = attempt, fixture = results$fixture, cell = cell$cell,
    seed = seed, start = "default", status = "error", convergence = NA_integer_,
    objective = NA_real_, elapsed_sec = fit_elapsed_sec, selected = FALSE,
    warning = paste(warnings, collapse = " | "), error = reason, stringsAsFactors = FALSE
  )
  intervals <- interval_rows_unavailable(reason)
} else {
  fit <- fit_result$fit
  profile_started <- proc.time()[["elapsed"]]
  profile <- tryCatch(
    withCallingHandlers(
      drmTMB:::drm_profile_confint(
        fit, parm = expected_parm, level = 0.95, profile_engine = "tmbprofile",
        profile_precision = "fast", profile_maxit = 50L
      ),
      warning = function(w) {
        profile_warnings <<- c(profile_warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  profile_elapsed_sec <- proc.time()[["elapsed"]] - profile_started
  intervals <- interval_rows_from_profile(profile, drmTMB::fixef(fit, "mu"))
  selected_attempts <- fit$temporal_start_attempts
  if (is.null(selected_attempts) || nrow(selected_attempts) == 0L) {
    selected_attempts <- data.frame(start = "default", status = "ok", convergence = fit$fit$convergence,
      objective = -as.numeric(stats::logLik(fit)), elapsed_sec = fit_elapsed_sec, selected = TRUE)
  }
  selected_attempts$task <- task
  selected_attempts$attempt <- attempt
  selected_attempts$fixture <- sprintf("%s_%04d", cell$cell, replicate)
  selected_attempts$cell <- cell$cell
  selected_attempts$seed <- seed
  selected_attempts$warning <- paste(warnings, collapse = " | ")
  selected_attempts$error <- NA_character_
  columns <- c("task", "attempt", "fixture", "cell", "seed", "start", "status",
               "convergence", "objective", "elapsed_sec", "selected", "warning", "error")
  attempts <- selected_attempts[, intersect(columns, names(selected_attempts)), drop = FALSE]
  for (name in setdiff(columns, names(attempts))) attempts[[name]] <- NA
  attempts <- attempts[, columns, drop = FALSE]
  results <- data.frame(
    task = task, attempt = attempt, fixture = sprintf("%s_%04d", cell$cell, replicate),
    cell = cell$cell, role = cell$role, replicate = replicate, seed = seed,
    n_id = cell$n_id, n_time = cell$n_time, selected = TRUE,
    objective = selected_attempts$objective[[which(selected_attempts$selected)[[1L]]]],
    convergence = selected_attempts$convergence[[which(selected_attempts$selected)[[1L]]]],
    pd_hessian = isTRUE(fit$sdr$pdHess),
    fit_elapsed_sec = fit_elapsed_sec, profile_elapsed_sec = profile_elapsed_sec,
    n_intervals = nrow(profile), interval_available = all(intervals$interval_available),
    warning = paste(c(warnings, profile_warnings), collapse = " | "),
    error = NA_character_, stringsAsFactors = FALSE
  )
}

write.csv(attempts, file.path(out_dir, "raw-attempts.csv"), row.names = FALSE)
write.csv(results, file.path(out_dir, "profile-results.csv"), row.names = FALSE)
write.csv(intervals, file.path(out_dir, "profile-intervals.csv"), row.names = FALSE)
provenance <- data.frame(
  key = c("source_commit", "runner_md5", "run_utc", "task", "attempt", "cell", "replicate", "seed"),
  value = c(source_commit, unname(tools::md5sum(worker)), format(Sys.time(), tz = "UTC", usetz = TRUE),
            task, attempt, cell$cell, replicate, seed),
  stringsAsFactors = FALSE
)
write.csv(provenance, file.path(out_dir, "provenance.csv"), row.names = FALSE)
writeLines(sub("[[:space:]]+$", "", capture.output(sessionInfo())),
           file.path(out_dir, "session-info.txt"))
writeLines(c(
  "# Marginal Toeplitz profile campaign task", "",
  sprintf("Task %d, attempt %d; cell %s, replicate %d, seed %d.", task, attempt, cell$cell, replicate, seed),
  sprintf("Fit selected: %s; all three intervals available: %s.", results$selected, results$interval_available),
  "This is a retained all-attempt campaign record. Any unavailable interval remains uncovered."
), file.path(out_dir, "RESULTS.md"))

complete <- nrow(results) == 1L && nrow(intervals) == 3L &&
  identical(intervals$parm, expected_parm) && all(intervals$task == task) &&
  all(intervals$attempt == attempt) && identical(unique(intervals$cell), cell$cell)
if (!complete) stop("Campaign task wrote malformed retained evidence.", call. = FALSE)
if (!isTRUE(results$selected) || !all(intervals$interval_available)) {
  stop("Campaign task retained a fit or profile failure.", call. = FALSE)
}
cat("TEMPORAL_HOMTOEP_PROFILE_CAMPAIGN_TASK_PASS\n")
