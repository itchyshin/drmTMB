#!/usr/bin/env Rscript

# Five-seed-per-cell timing and completeness pilot for the proposed temporal
# AR1 Wald-interval calibration.  This is not the 1,000-replicate campaign.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0L) stop("This runner takes no arguments.", call. = FALSE)
root <- normalizePath(".", mustWork = TRUE)
if (!file.exists(file.path(root, "DESCRIPTION"))) {
  stop("Run this script from the drmTMB repository root.", call. = FALSE)
}
pkgload::load_all(root, quiet = TRUE)

out_dir <- Sys.getenv(
  "DRMTMB_TEMPORAL_AR1_PILOT_OUT",
  unset = file.path(
    root,
    "docs/dev-log/simulation-artifacts/2026-09-08-temporal-ar1-calibration-pilot"
  )
)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
evidence_files <- file.path(out_dir, c(
  "raw-attempts.csv", "pilot-results.csv", "pilot-summary.csv",
  "provenance.csv", "pilot-results.rds"
))
if (any(file.exists(evidence_files))) {
  stop("Retained pilot evidence already exists; do not overwrite it.", call. = FALSE)
}

cells <- data.frame(
  cell = c("C1", "C2", "C3", "C4", "C5"),
  ordinary_intercept = c(TRUE, TRUE, TRUE, FALSE, TRUE),
  n_id = c(80L, 80L, 80L, 80L, 20L),
  n_time = c(6L, 24L, 12L, 12L, 6L),
  phi = c(0.4, 0.85, -0.6, 0.4, 0.85),
  role = c("primary_short", "primary_persistent", "primary_negative", "primary_ar1_only", "stress"),
  stringsAsFactors = FALSE
)
seeds <- 2026091001L + seq_len(5L) - 1L
truth <- c(`(Intercept)` = 0, between = 0.5, within = 0.5)

simulate_cell <- function(cell, seed) {
  set.seed(seed)
  time <- seq.int(0L, by = 1L, length.out = cell$n_time)
  n <- cell$n_id * cell$n_time
  id_levels <- sprintf("id_%03d", seq_len(cell$n_id))
  id <- factor(rep(id_levels, each = cell$n_time), levels = id_levels)
  occasion <- rep(time, cell$n_id)
  between <- rep(rep(c(-0.5, 0.5), length.out = cell$n_id), each = cell$n_time)
  within <- unlist(lapply(seq_len(cell$n_id), function(i) {
    sample(rep(c(-0.5, 0.5), length.out = cell$n_time))
  }), use.names = FALSE)
  R <- cell$phi ^ abs(outer(time, time, "-"))
  temporal <- unlist(lapply(seq_len(cell$n_id), function(i) {
    as.vector(t(chol(R)) %*% rnorm(cell$n_time, sd = 0.8))
  }), use.names = FALSE)
  stable <- if (cell$ordinary_intercept) {
    rep(rnorm(cell$n_id, sd = 0.6), each = cell$n_time)
  } else numeric(n)
  data.frame(
    y = truth[["(Intercept)"]] + truth[["between"]] * between +
      truth[["within"]] * within + stable + temporal + rnorm(n, sd = 0.4),
    id = id, occasion = occasion, between = between, within = within
  )
}

fit_cell <- function(dat, ordinary_intercept) {
  if (ordinary_intercept) {
    drmTMB(
      bf(y ~ between + within + (1 | id) +
           temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
      data = dat, family = gaussian(), REML = FALSE
    )
  } else {
    drmTMB(
      bf(y ~ between + within +
           temporal(1 | id, time = occasion, structure = "ar1"), sigma ~ 1),
      data = dat, family = gaussian(), REML = FALSE
    )
  }
}

run_one <- function(cell, seed) {
  warnings <- character()
  started <- proc.time()[["elapsed"]]
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
  elapsed <- proc.time()[["elapsed"]] - started
  fixture <- paste(cell$cell, seed, sep = "_")
  if (is.null(result$fit)) {
    selected <- data.frame(
      fixture = fixture, cell = cell$cell, role = cell$role, seed = seed,
      n_id = cell$n_id, n_time = cell$n_time, phi_truth = cell$phi,
      ordinary_intercept = cell$ordinary_intercept, selected = FALSE,
      objective = NA_real_, convergence = NA_integer_, elapsed_sec = elapsed,
      pd_hessian = NA, n_intervals = 0L, interval_available = FALSE,
      warning = paste(warnings, collapse = " | "), error = result$error,
      stringsAsFactors = FALSE
    )
    attempts <- data.frame(
      fixture = fixture, cell = cell$cell, seed = seed, start = NA_character_,
      persistence_start = NA_real_, status = "error", convergence = NA_integer_,
      objective = NA_real_, elapsed_sec = elapsed, selected = FALSE,
      warning = paste(warnings, collapse = " | "), error = result$error,
      stringsAsFactors = FALSE
    )
    return(list(selected = selected, attempts = attempts))
  }
  fit <- result$fit
  intervals <- tryCatch(stats::confint(fit, method = "wald"), error = function(e) e)
  n_intervals <- if (inherits(intervals, "error")) 0L else nrow(intervals)
  available <- n_intervals == 3L && all(is.finite(intervals$lower)) && all(is.finite(intervals$upper))
  selected <- data.frame(
    fixture = fixture, cell = cell$cell, role = cell$role, seed = seed,
    n_id = cell$n_id, n_time = cell$n_time, phi_truth = cell$phi,
    ordinary_intercept = cell$ordinary_intercept, selected = TRUE,
    objective = -as.numeric(stats::logLik(fit)),
    convergence = fit$temporal_start_attempts$convergence[fit$temporal_start_attempts$selected][[1L]],
    elapsed_sec = elapsed, pd_hessian = isTRUE(fit$sdr$pdHess),
    n_intervals = n_intervals, interval_available = available,
    warning = paste(warnings, collapse = " | "),
    error = if (inherits(intervals, "error")) conditionMessage(intervals) else NA_character_,
    stringsAsFactors = FALSE
  )
  attempts <- fit$temporal_start_attempts
  attempts$fixture <- fixture
  attempts$cell <- cell$cell
  attempts$seed <- seed
  attempts$warning <- paste(warnings, collapse = " | ")
  attempts$error <- NA_character_
  attempts <- attempts[, c(
    "fixture", "cell", "seed", "start", "persistence_start", "status",
    "convergence", "objective", "elapsed_sec", "selected", "warning", "error"
  )]
  list(selected = selected, attempts = attempts)
}

result_rows <- list()
attempt_rows <- list()
index <- 1L
for (i in seq_len(nrow(cells))) {
  for (seed in seeds) {
    result <- run_one(cells[i, , drop = FALSE], seed)
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
    median_elapsed_sec = stats::median(x$elapsed_sec),
    max_elapsed_sec = max(x$elapsed_sec),
    pd_hessian = sum(x$pd_hessian %in% TRUE),
    warnings = sum(nzchar(x$warning)), errors = sum(!is.na(x$error)),
    stringsAsFactors = FALSE
  )
}))

write.csv(attempts, file.path(out_dir, "raw-attempts.csv"), row.names = FALSE)
write.csv(results, file.path(out_dir, "pilot-results.csv"), row.names = FALSE)
write.csv(summary, file.path(out_dir, "pilot-summary.csv"), row.names = FALSE)
provenance <- data.frame(
  key = c("source_commit", "runner_md5", "run_utc", "n_datasets", "n_attempts"),
  value = c(
    system2("git", c("rev-parse", "HEAD"), stdout = TRUE),
    unname(tools::md5sum(file.path(root, "tools/run-temporal-ar1-pilot.R"))),
    format(Sys.time(), tz = "UTC", usetz = TRUE), nrow(results), nrow(attempts)
  ), stringsAsFactors = FALSE
)
write.csv(provenance, file.path(out_dir, "provenance.csv"), row.names = FALSE)
saveRDS(list(cells = cells, results = results, attempts = attempts, summary = summary,
             provenance = provenance), file.path(out_dir, "pilot-results.rds"))
capture.output(sessionInfo(), file = file.path(out_dir, "session-info.txt"))

if (nrow(results) != 25L || nrow(attempts) != 50L ||
    !all(table(attempts$fixture) == 2L) ||
    !all(results$selected & is.finite(results$objective)) ||
    !all(is.finite(results$elapsed_sec) & results$elapsed_sec > 0)) {
  stop("Temporal AR1 pilot completeness checks failed; retained outputs were written for diagnosis.", call. = FALSE)
}
cat("TEMPORAL_AR1_PILOT_PASS\n")
