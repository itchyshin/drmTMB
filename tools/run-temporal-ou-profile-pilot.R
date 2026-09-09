#!/usr/bin/env Rscript

# Five-seed-per-cell timing, resource, and output-completeness pilot for the
# temporal OU fixed-effect profile route. It is not an interval-calibration
# campaign.

args <- commandArgs(trailingOnly = TRUE)
preflight <- identical(args, "--preflight")
campaign_arg <- grep("^--campaign-task=[0-9]+$", args, value = TRUE)
campaign_task <- if (length(campaign_arg) == 1L) {
  as.integer(sub("^--campaign-task=", "", campaign_arg))
} else NA_integer_
campaign_mode <- !is.na(campaign_task)
if ((length(args) > 0L && !preflight && !campaign_mode) || length(args) > 1L) {
  stop("Usage: Rscript --vanilla tools/run-temporal-ou-profile-pilot.R [--preflight | --campaign-task=<1..3000>]", call. = FALSE)
}
if (campaign_mode && (campaign_task < 1L || campaign_task > 3000L)) {
  stop("Campaign task must be an integer from 1 through 3000.", call. = FALSE)
}
if (campaign_mode && !identical(Sys.getenv("DRMTMB_TEMPORAL_OU_CAMPAIGN_AUTHORIZED"), "1")) {
  stop("Campaign mode requires DRMTMB_TEMPORAL_OU_CAMPAIGN_AUTHORIZED=1.", call. = FALSE)
}
root <- normalizePath(".", mustWork = TRUE)
if (!file.exists(file.path(root, "DESCRIPTION"))) {
  stop("Run this script from the drmTMB repository root.", call. = FALSE)
}
pkgload::load_all(root, quiet = TRUE)

out_dir <- if (campaign_mode) {
  campaign_root <- Sys.getenv("DRMTMB_TEMPORAL_OU_CAMPAIGN_OUT")
  if (!nzchar(campaign_root)) {
    stop("Campaign mode requires DRMTMB_TEMPORAL_OU_CAMPAIGN_OUT.", call. = FALSE)
  }
  file.path(campaign_root, sprintf("task-%04d", campaign_task))
} else {
  Sys.getenv(
    "DRMTMB_TEMPORAL_OU_PILOT_OUT",
    unset = file.path(root, "docs/dev-log/simulation-artifacts", if (preflight) {
      "2026-09-09-temporal-ou-profile-preflight"
    } else "2026-09-09-temporal-ou-profile-pilot")
  )
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
evidence_files <- file.path(out_dir, c(
  "raw-attempts.csv", "profile-pilot-results.csv", "profile-pilot-summary.csv",
  "provenance.csv", "profile-pilot-results.rds", "session-info.txt", "RESULTS.md"
))
if (any(file.exists(evidence_files))) {
  stop("Retained OU profile-pilot evidence already exists; do not overwrite it.", call. = FALSE)
}

cells <- data.frame(
  cell = c("U1", "U2", "U3"),
  ordinary_intercept = c(TRUE, TRUE, FALSE),
  n_id = c(80L, 80L, 80L),
  elapsed_set = c("short", "long", "long"),
  decay = c(0.40, 0.15, 0.70),
  role = c("combined_short", "combined_persistent", "ou_only"),
  stringsAsFactors = FALSE
)
seeds <- 2026091201L + seq_len(5L) - 1L
truth <- c(`(Intercept)` = 0, between = 0.5, within = 0.5)
elapsed_sets <- list(
  short = c(0, 0.5, 1.5, 3, 5, 8),
  long = c(0, 0.5, 1.5, 3, 5, 8, 12, 17, 23, 30, 38, 47)
)

simulate_cell <- function(cell, seed) {
  set.seed(seed)
  elapsed_values <- elapsed_sets[[cell$elapsed_set]]
  n_time <- length(elapsed_values)
  n <- cell$n_id * n_time
  id_levels <- sprintf("site_%03d", seq_len(cell$n_id))
  id <- factor(rep(id_levels, each = n_time), levels = id_levels)
  elapsed <- rep(elapsed_values, cell$n_id)
  between <- rep(rep(c(-0.5, 0.5), length.out = cell$n_id), each = n_time)
  within <- unlist(lapply(seq_len(cell$n_id), function(i) {
    sample(rep(c(-0.5, 0.5), length.out = n_time))
  }), use.names = FALSE)
  R <- exp(-cell$decay * abs(outer(elapsed_values, elapsed_values, "-")))
  temporal <- unlist(lapply(seq_len(cell$n_id), function(i) {
    as.vector(t(chol(R)) %*% rnorm(n_time, sd = 0.8))
  }), use.names = FALSE)
  stable <- if (cell$ordinary_intercept) {
    rep(rnorm(cell$n_id, sd = 0.6), each = n_time)
  } else numeric(n)
  data.frame(
    y = truth[["(Intercept)"]] + truth[["between"]] * between +
      truth[["within"]] * within + stable + temporal + rnorm(n, sd = 0.4),
    id = id, elapsed = elapsed, between = between, within = within
  )
}

fit_cell <- function(dat, ordinary_intercept) {
  if (ordinary_intercept) {
    drmTMB(
      bf(y ~ between + within + (1 | id) +
           temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1),
      data = dat, family = gaussian(), REML = FALSE
    )
  } else {
    drmTMB(
      bf(y ~ between + within +
           temporal(1 | id, time = elapsed, structure = "ou"), sigma ~ 1),
      data = dat, family = gaussian(), REML = FALSE
    )
  }
}

run_one <- function(cell, seed) {
  warnings <- character()
  fit_started <- proc.time()[["elapsed"]]
  result <- tryCatch(
    withCallingHandlers(
      list(fit = fit_cell(simulate_cell(cell, seed), cell$ordinary_intercept), error = NA_character_),
      warning = function(w) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) list(fit = NULL, error = conditionMessage(e))
  )
  fit_elapsed_sec <- proc.time()[["elapsed"]] - fit_started
  fixture <- paste(cell$cell, seed, sep = "_")
  warning <- paste(warnings, collapse = " | ")
  if (is.null(result$fit)) {
    selected <- data.frame(
      fixture = fixture, cell = cell$cell, role = cell$role, seed = seed,
      n_id = cell$n_id, n_time = length(elapsed_sets[[cell$elapsed_set]]),
      decay_truth = cell$decay, ordinary_intercept = cell$ordinary_intercept,
      selected = FALSE, objective = NA_real_, convergence = NA_integer_,
      fit_elapsed_sec = fit_elapsed_sec, profile_elapsed_sec = NA_real_,
      pd_hessian = NA, profile_hessian_status = "fit_error", n_intervals = 0L,
      interval_available = FALSE, interval_status = "fit_error", warning = warning,
      error = result$error, stringsAsFactors = FALSE
    )
    attempts <- data.frame(
      fixture = fixture, cell = cell$cell, seed = seed, start = NA_character_,
      decay_start = NA_real_, status = "error", convergence = NA_integer_,
      objective = NA_real_, elapsed_sec = fit_elapsed_sec, selected = FALSE,
      warning = warning, error = result$error, stringsAsFactors = FALSE
    )
    return(list(selected = selected, attempts = attempts))
  }
  fit <- result$fit
  profile_warnings <- character()
  profile_started <- proc.time()[["elapsed"]]
  intervals <- tryCatch(
    withCallingHandlers(
      stats::confint(fit, method = "profile"),
      warning = function(w) {
        profile_warnings <<- c(profile_warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    ),
    error = function(e) e
  )
  profile_elapsed_sec <- proc.time()[["elapsed"]] - profile_started
  n_intervals <- if (inherits(intervals, "error")) 0L else nrow(intervals)
  available <- n_intervals == 3L &&
    all(intervals$conf.status == "profile") &&
    all(is.finite(intervals$lower)) && all(is.finite(intervals$upper))
  temporal_check <- check_drm(fit)
  profile_check <- temporal_check[
    temporal_check$check == "temporal_mean_profile",
    ,
    drop = FALSE
  ]
  attempts <- fit$temporal_start_attempts
  attempts$status <- ifelse(
    is.finite(attempts$convergence) & attempts$convergence != 0L,
    "nonconverged", attempts$status
  )
  attempts$fixture <- fixture
  attempts$cell <- cell$cell
  attempts$seed <- seed
  attempts$warning <- warning
  attempts$error <- NA_character_
  selected_start <- attempts[attempts$selected, , drop = FALSE]
  selected <- data.frame(
    fixture = fixture, cell = cell$cell, role = cell$role, seed = seed,
    n_id = cell$n_id, n_time = length(elapsed_sets[[cell$elapsed_set]]),
    decay_truth = cell$decay, ordinary_intercept = cell$ordinary_intercept,
    selected = TRUE, objective = -as.numeric(stats::logLik(fit)),
    convergence = selected_start$convergence[[1L]],
    fit_elapsed_sec = fit_elapsed_sec, profile_elapsed_sec = profile_elapsed_sec,
    pd_hessian = isTRUE(fit$sdr$pdHess),
    profile_hessian_status = profile_check$value[[1L]], n_intervals = n_intervals,
    interval_available = available,
    interval_status = if (inherits(intervals, "error")) conditionMessage(intervals) else paste(intervals$conf.status, collapse = ";"),
    warning = paste(c(warnings, profile_warnings), collapse = " | "),
    error = NA_character_, stringsAsFactors = FALSE
  )
  attempts <- attempts[, c(
    "fixture", "cell", "seed", "start", "decay_start", "status",
    "convergence", "objective", "elapsed_sec", "selected", "warning", "error"
  )]
  list(selected = selected, attempts = attempts)
}

result_rows <- list()
attempt_rows <- list()
index <- 1L
if (campaign_mode) {
  campaign_cell <- (campaign_task - 1L) %/% 1000L + 1L
  campaign_rep <- (campaign_task - 1L) %% 1000L + 1L
  run_cells <- cells[campaign_cell, , drop = FALSE]
  run_seeds <- 2026100000L + campaign_rep - 1L
} else {
  run_cells <- if (preflight) cells[1L, , drop = FALSE] else cells
  run_seeds <- if (preflight) seeds[1L] else seeds
}
for (i in seq_len(nrow(run_cells))) {
  for (seed in run_seeds) {
    result <- run_one(run_cells[i, , drop = FALSE], seed)
    result_rows[[index]] <- result$selected
    attempt_rows[[index]] <- result$attempts
    index <- index + 1L
  }
}
results <- do.call(rbind, result_rows)
attempts <- do.call(rbind, attempt_rows)
summary <- do.call(rbind, lapply(split(results, results$cell), function(x) {
  data.frame(
    cell = x$cell[[1L]], role = x$role[[1L]], n_datasets = nrow(x),
    selected_finite = sum(x$selected & is.finite(x$objective)),
    interval_available = sum(x$interval_available),
    interval_availability = mean(x$interval_available),
    median_fit_elapsed_sec = stats::median(x$fit_elapsed_sec),
    median_profile_elapsed_sec = stats::median(x$profile_elapsed_sec),
    max_profile_elapsed_sec = max(x$profile_elapsed_sec),
    pd_hessian = sum(x$pd_hessian %in% TRUE), warnings = sum(nzchar(x$warning)),
    errors = sum(!is.na(x$error)), stringsAsFactors = FALSE
  )
}))

write.csv(attempts, file.path(out_dir, "raw-attempts.csv"), row.names = FALSE)
write.csv(results, file.path(out_dir, "profile-pilot-results.csv"), row.names = FALSE)
write.csv(summary, file.path(out_dir, "profile-pilot-summary.csv"), row.names = FALSE)
provenance <- data.frame(
  key = c("source_commit", "runner_md5", "run_utc", "mode", "campaign_task", "n_datasets", "n_attempts"),
  value = c(
    system2("git", c("rev-parse", "HEAD"), stdout = TRUE),
    unname(tools::md5sum(file.path(root, "tools/run-temporal-ou-profile-pilot.R"))),
    format(Sys.time(), tz = "UTC", usetz = TRUE),
    if (campaign_mode) "campaign" else if (preflight) "preflight" else "pilot",
    if (campaign_mode) campaign_task else NA_integer_, nrow(results), nrow(attempts)
  ), stringsAsFactors = FALSE
)
write.csv(provenance, file.path(out_dir, "provenance.csv"), row.names = FALSE)
saveRDS(list(cells = cells, results = results, attempts = attempts, summary = summary,
             provenance = provenance), file.path(out_dir, "profile-pilot-results.rds"))
writeLines(sub("[[:space:]]+$", "", capture.output(sessionInfo())),
           file.path(out_dir, "session-info.txt"))
writeLines(c(
  if (campaign_mode) "# Temporal OU fixed-effect profile campaign task" else "# Temporal OU fixed-effect profile pilot", "",
  sprintf("The pilot retained %d data sets and %d optimizer starts.", nrow(results), nrow(attempts)),
  sprintf("Total elapsed fit time: %.3f seconds; total profile time: %.3f seconds.", sum(results$fit_elapsed_sec), sum(results$profile_elapsed_sec)),
  sprintf("Fixed-effect profile interval availability: %d/%d.", sum(results$interval_available), nrow(results)),
  sprintf("Regular fitted Hessians: %d/%d; irregular-Hessian profile warnings: %d/%d.", sum(results$pd_hessian %in% TRUE), nrow(results), sum(grepl("base_hessian_non_pd", results$profile_hessian_status, fixed = TRUE)), nrow(results)),
  if (campaign_mode) "This is one retained all-attempt campaign task." else "This records timing and output completeness only. It does not qualify interval calibration or authorize a campaign."
), file.path(out_dir, "RESULTS.md"))

expected_datasets <- if (preflight || campaign_mode) 1L else 15L
expected_attempts <- 2L * expected_datasets
if (nrow(results) != expected_datasets || nrow(attempts) != expected_attempts ||
    !all(table(attempts$fixture) == 2L) ||
    !all(results$selected & is.finite(results$objective)) ||
    !all(is.finite(results$fit_elapsed_sec) & results$fit_elapsed_sec > 0) ||
    !all(is.finite(results$profile_elapsed_sec) & results$profile_elapsed_sec > 0)) {
  stop("Temporal OU profile-pilot completeness checks failed; retained outputs were written for diagnosis.", call. = FALSE)
}
cat(if (campaign_mode) "TEMPORAL_OU_PROFILE_CAMPAIGN_TASK_PASS\n" else "TEMPORAL_OU_PROFILE_PILOT_PASS\n")
