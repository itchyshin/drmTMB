#!/usr/bin/env Rscript

# Five-seed-per-cell timing and output-completeness pilot for the direct
# Gaussian homogeneous Toeplitz provider.  It deliberately records that
# profile intervals are guarded; it is not a calibration campaign.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0L) stop("This runner takes no arguments.", call. = FALSE)
root <- normalizePath(".", mustWork = TRUE)
if (!file.exists(file.path(root, "DESCRIPTION"))) stop("Run from the drmTMB repository root.", call. = FALSE)
pkgload::load_all(root, compile = TRUE, quiet = TRUE)

out_dir <- Sys.getenv("DRMTMB_TEMPORAL_HOMTOEP_PILOT_OUT", unset = file.path(
  root, "docs/dev-log/simulation-artifacts/2026-09-10-temporal-homtoep-pilot-final-source"
))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
needed <- c("raw-attempts.csv", "pilot-results.csv", "pilot-summary.csv", "provenance.csv", "pilot-results.rds", "session-info.txt", "RESULTS.md")
if (any(file.exists(file.path(out_dir, needed)))) stop("Retained Toeplitz pilot evidence already exists; do not overwrite it.", call. = FALSE)

cells <- data.frame(
  cell = c("P1_ar1_shaped", "P2_nonexponential", "P3_negative_lag"),
  n_id = c(80L, 80L, 80L), n_time = c(6L, 6L, 6L),
  role = c("ar1_reference", "free_lag", "negative_lag"), stringsAsFactors = FALSE
)
seeds <- 2026091301L + seq_len(5L) - 1L
truth <- c(`(Intercept)` = 0, between = 0.5, within = 0.5, sd_temporal = 0.8, sigma = 0.4)
truth_rho <- list(
  P1_ar1_shaped = c(1, 0.55^(1:5)),
  P2_nonexponential = temporal_homtoep_correlations(c(atanh(0.45), atanh(-0.30), atanh(0.20), atanh(0.10), atanh(-0.05))),
  P3_negative_lag = temporal_homtoep_correlations(c(atanh(-0.45), atanh(0.15), atanh(-0.10), atanh(0.05), 0))
)

simulate_cell <- function(cell, seed) {
  set.seed(seed)
  n_time <- cell$n_time
  n_id <- cell$n_id
  occasion <- rep(seq.int(0L, n_time - 1L), n_id)
  id <- factor(rep(sprintf("id_%03d", seq_len(n_id)), each = n_time))
  between <- rep(rep(c(-0.5, 0.5), length.out = n_id), each = n_time)
  within <- unlist(lapply(seq_len(n_id), function(i) sample(rep(c(-0.5, 0.5), length.out = n_time))), use.names = FALSE)
  R <- stats::toeplitz(truth_rho[[cell$cell]])
  temporal <- unlist(lapply(seq_len(n_id), function(i) {
    as.vector(t(chol(R)) %*% rnorm(n_time, sd = truth[["sd_temporal"]]))
  }), use.names = FALSE)
  data.frame(
    y = truth[["(Intercept)"]] + truth[["between"]] * between + truth[["within"]] * within + temporal + rnorm(n_id * n_time, sd = truth[["sigma"]]),
    id = id, occasion = occasion, between = between, within = within
  )
}

fit_one <- function(cell, seed) {
  warnings <- character()
  started <- proc.time()[["elapsed"]]
  result <- withCallingHandlers(tryCatch(
    list(fit = drmTMB(bf(y ~ between + within + temporal(1 | id, time = occasion, structure = "homtoep"), sigma ~ 1), data = simulate_cell(cell, seed), family = gaussian(), REML = FALSE), error = NA_character_),
    error = function(e) list(fit = NULL, error = conditionMessage(e))
  ), warning = function(w) { warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning") })
  elapsed_sec <- proc.time()[["elapsed"]] - started
  fixture <- paste(cell$cell, seed, sep = "_")
  warning <- paste(warnings, collapse = " | ")
  if (is.null(result$fit)) {
    return(list(
      selected = data.frame(fixture = fixture, cell = cell$cell, role = cell$role, seed = seed, n_id = cell$n_id, n_time = cell$n_time, selected = FALSE, objective = NA_real_, convergence = NA_integer_, elapsed_sec = elapsed_sec, pd_hessian = NA, profile_available = FALSE, n_profile_intervals = 0L, profile_status = "fit_error", warning = warning, error = result$error),
      attempts = data.frame(fixture = fixture, cell = cell$cell, seed = seed, start = NA_integer_, status = "error", convergence = NA_integer_, objective = NA_real_, elapsed_sec = elapsed_sec, selected = FALSE, warning = warning, error = result$error)
    ))
  }
  fit <- result$fit
  profile <- tryCatch(stats::confint(fit, method = "profile"), error = function(e) e)
  attempts <- fit$temporal_start_attempts
  attempts$fixture <- fixture; attempts$cell <- cell$cell; attempts$seed <- seed; attempts$warning <- warning; attempts$error <- NA_character_
  chosen <- attempts[attempts$selected, , drop = FALSE]
  list(
    selected = data.frame(fixture = fixture, cell = cell$cell, role = cell$role, seed = seed, n_id = cell$n_id, n_time = cell$n_time, selected = is.finite(fit$opt$objective), objective = fit$opt$objective, convergence = chosen$convergence[[1L]], elapsed_sec = elapsed_sec, pd_hessian = isTRUE(fit$sdr$pdHess), profile_available = !inherits(profile, "error"), n_profile_intervals = if (inherits(profile, "error")) 0L else nrow(profile), profile_status = if (inherits(profile, "error")) conditionMessage(profile) else "available", warning = warning, error = NA_character_),
    attempts = attempts[, c("fixture", "cell", "seed", "start", "status", "convergence", "objective", "elapsed_sec", "selected", "warning", "error")]
  )
}

rows <- list(); attempts <- list(); index <- 1L
for (i in seq_len(nrow(cells))) for (seed in seeds) {
  one <- fit_one(cells[i, , drop = FALSE], seed)
  rows[[index]] <- one$selected; attempts[[index]] <- one$attempts; index <- index + 1L
}
results <- do.call(rbind, rows)
attempts <- do.call(rbind, attempts)
summary <- do.call(rbind, lapply(split(results, results$cell), function(x) data.frame(
  cell = x$cell[[1L]], role = x$role[[1L]], n_datasets = nrow(x),
  selected_finite = sum(x$selected & is.finite(x$objective)),
  profile_available = sum(x$profile_available), profile_guarded = sum(grepl("not yet qualified", x$profile_status, fixed = TRUE)),
  median_elapsed_sec = stats::median(x$elapsed_sec), max_elapsed_sec = max(x$elapsed_sec),
  pd_hessian = sum(x$pd_hessian %in% TRUE), warnings = sum(nzchar(x$warning)), errors = sum(!is.na(x$error))
)))
write.csv(attempts, file.path(out_dir, "raw-attempts.csv"), row.names = FALSE)
write.csv(results, file.path(out_dir, "pilot-results.csv"), row.names = FALSE)
write.csv(summary, file.path(out_dir, "pilot-summary.csv"), row.names = FALSE)
provenance <- data.frame(key = c("source_commit", "runner_md5", "run_utc", "n_datasets", "n_attempts"), value = c(system2("git", c("rev-parse", "HEAD"), stdout = TRUE), unname(tools::md5sum(file.path(root, "tools/run-temporal-homtoep-pilot.R"))), format(Sys.time(), tz = "UTC", usetz = TRUE), nrow(results), nrow(attempts)))
write.csv(provenance, file.path(out_dir, "provenance.csv"), row.names = FALSE)
saveRDS(list(cells = cells, truth = truth, truth_rho = truth_rho, results = results, attempts = attempts, summary = summary, provenance = provenance), file.path(out_dir, "pilot-results.rds"))
capture.output(sessionInfo(), file = file.path(out_dir, "session-info.txt"))
writeLines(c("# Temporal homogeneous Toeplitz timed pilot", "", sprintf("The pilot retained %d data sets and %d optimizer starts.", nrow(results), nrow(attempts)), sprintf("Total elapsed fit time: %.3f seconds; longest fit: %.3f seconds.", sum(results$elapsed_sec), max(results$elapsed_sec)), sprintf("Profile interval availability: %d/%d; explicitly guarded: %d/%d.", sum(results$profile_available), nrow(results), sum(grepl("not yet qualified", results$profile_status, fixed = TRUE)), nrow(results)), "This records timing and output completeness only. It does not qualify profile intervals or authorize a campaign."), file.path(out_dir, "RESULTS.md"))
if (nrow(results) != 15L || nrow(attempts) != 15L || !all(table(attempts$fixture) == 1L) || !all(results$selected & is.finite(results$objective)) || !all(is.finite(results$elapsed_sec) & results$elapsed_sec > 0) || !all(!results$profile_available & results$n_profile_intervals == 0L & grepl("not yet qualified", results$profile_status, fixed = TRUE))) stop("Toeplitz pilot completeness checks failed; retained outputs were written for diagnosis.", call. = FALSE)
cat("TEMPORAL_HOMTOEP_PILOT_PASS\n")
