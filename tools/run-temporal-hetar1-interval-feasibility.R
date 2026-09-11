#!/usr/bin/env Rscript

# Frozen local interval-feasibility fixtures for heterogeneous temporal AR1.
# This runner assesses whether the public full-Hessian Wald surface returns
# finite fixed-mean intervals. It is not a coverage or SE-calibration study.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L || !args[[1L]] %in% c("--pilot", "--full")) {
  stop("Usage: Rscript --vanilla tools/run-temporal-hetar1-interval-feasibility.R --pilot|--full", call. = FALSE)
}

mode <- sub("^--", "", args[[1L]])
root <- normalizePath(".", mustWork = TRUE)
if (!file.exists(file.path(root, "DESCRIPTION"))) {
  stop("Run this script from the drmTMB repository root.", call. = FALSE)
}

artifact_root <- file.path(
  root, "docs", "dev-log", "simulation-artifacts",
  "2026-09-11-temporal-hetar1-interval-feasibility"
)
out_dir <- file.path(artifact_root, mode)
required_outputs <- c(
  "configuration.csv", "raw-attempts.csv", "fixture-results.csv",
  "interval-results.csv", "summary.csv", "provenance.csv",
  "results.rds", "session-info.txt", "RESULTS.md"
)
if (dir.exists(out_dir) || any(file.exists(file.path(out_dir, required_outputs)))) {
  stop("Frozen interval-feasibility outputs already exist; do not overwrite them.", call. = FALSE)
}
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

compile_native <- !identical(tolower(Sys.getenv("DRMTMB_HETAR1_COMPILE", "true")), "false")
pkgload::load_all(root, compile = compile_native, quiet = TRUE)

conditions <- data.frame(
  cell = c("C1", "C2", "C3", "C4"),
  role = c("primary", "primary", "primary", "stress"),
  n_id = c(80L, 80L, 80L, 20L),
  n_time = c(8L, 12L, 8L, 6L),
  phi = c(0.50, 0.80, -0.50, 0.80),
  sd_pattern = c("monotone", "u_shaped", "unequal", "high_variance_occasion"),
  seed_base = c(2026091100L, 2026091200L, 2026091300L, 2026091400L),
  stringsAsFactors = FALSE
)
if (identical(mode, "pilot")) {
  conditions <- conditions[conditions$cell == "C1", , drop = FALSE]
}
seeds <- 1:5
configuration <- do.call(rbind, lapply(seq_len(nrow(conditions)), function(i) {
  condition <- conditions[i, , drop = FALSE]
  data.frame(
    fixture = paste0(condition$cell, "_", condition$seed_base + seeds),
    cell = condition$cell, role = condition$role, seed = condition$seed_base + seeds,
    n_id = condition$n_id, n_time = condition$n_time, phi = condition$phi,
    sd_pattern = condition$sd_pattern, stringsAsFactors = FALSE
  )
}))

truth <- c(`(Intercept)` = 0, between = 0.5, within = 0.5)
sd_pattern <- function(pattern, n_time) {
  switch(
    pattern,
    monotone = seq(0.45, 1.05, length.out = n_time),
    u_shaped = 0.45 + 0.75 * abs(seq(-1, 1, length.out = n_time)),
    unequal = rep(c(0.45, 1.10, 0.65, 0.95), length.out = n_time),
    high_variance_occasion = c(rep(0.50, n_time - 1L), 1.45),
    stop("Unknown SD pattern.", call. = FALSE)
  )
}

simulate_fixture <- function(row) {
  set.seed(row$seed)
  n_id <- as.integer(row$n_id)
  n_time <- as.integer(row$n_time)
  occasion_levels <- seq.int(0L, n_time - 1L)
  id_levels <- sprintf("id_%03d", seq_len(n_id))
  id <- factor(rep(id_levels, each = n_time), levels = id_levels)
  occasion <- rep(occasion_levels, n_id)
  between_id <- rep(c(-0.5, 0.5), length.out = n_id)
  between <- rep(between_id, each = n_time)
  within <- unlist(lapply(seq_len(n_id), function(i) {
    sample(rep(c(-0.5, 0.5), length.out = n_time))
  }), use.names = FALSE)
  process_sd <- sd_pattern(row$sd_pattern, n_time)
  correlation <- row$phi ^ abs(outer(occasion_levels, occasion_levels, "-"))
  temporal <- unlist(lapply(seq_len(n_id), function(i) {
    process_sd * as.vector(t(chol(correlation)) %*% stats::rnorm(n_time))
  }), use.names = FALSE)
  dat <- data.frame(
    y = truth[["(Intercept)"]] + truth[["between"]] * between +
      truth[["within"]] * within + temporal +
      stats::rnorm(n_id * n_time, sd = 0.4),
    id = id, occasion = occasion, between = between, within = within
  )
  attr(dat, "process_sd") <- process_sd
  dat
}

fit_fixture <- function(dat) {
  drmTMB::drmTMB(
    drmTMB::bf(
      y ~ between + within +
        temporal(1 | id, time = occasion, structure = "hetar1"),
      sigma ~ 1
    ),
    data = dat, family = stats::gaussian(), REML = FALSE
  )
}

safe_fit <- function(dat) {
  started <- proc.time()[["elapsed"]]
  result <- tryCatch(
    list(fit = fit_fixture(dat), error = NA_character_),
    error = function(e) list(fit = NULL, error = conditionMessage(e))
  )
  result$elapsed_sec <- proc.time()[["elapsed"]] - started
  result
}

empty_attempt <- function(fixture, elapsed_sec, error) {
  data.frame(
    fixture = fixture, start = NA_character_, persistence_start = NA_real_,
    status = "error", convergence = NA_integer_, objective = NA_real_,
    elapsed_sec = elapsed_sec, selected = FALSE, error = error,
    stringsAsFactors = FALSE
  )
}

extract_fixture <- function(row, result) {
  if (is.null(result$fit)) {
    return(data.frame(
      fixture = row$fixture, cell = row$cell, role = row$role, seed = row$seed,
      selected = FALSE, error = result$error, elapsed_sec = result$elapsed_sec,
      objective = NA_real_, pd_hess = FALSE, covariance_finite = FALSE,
      process_sd_truth = paste(sd_pattern(row$sd_pattern, row$n_time), collapse = ";"),
      stringsAsFactors = FALSE
    ))
  }
  fit <- result$fit
  covariance <- tryCatch(stats::vcov(fit), error = function(e) e)
  data.frame(
    fixture = row$fixture, cell = row$cell, role = row$role, seed = row$seed,
    selected = TRUE, error = NA_character_, elapsed_sec = result$elapsed_sec,
    objective = -as.numeric(stats::logLik(fit)), pd_hess = isTRUE(fit$sdr$pdHess),
    covariance_finite = is.matrix(covariance) && all(is.finite(covariance)),
    process_sd_truth = paste(sd_pattern(row$sd_pattern, row$n_time), collapse = ";"),
    stringsAsFactors = FALSE
  )
}

extract_intervals <- function(row, result) {
  target_names <- paste0("fixef:mu:", names(truth))
  if (is.null(result$fit)) {
    return(data.frame(
      fixture = row$fixture, cell = row$cell, role = row$role, seed = row$seed,
      parm = target_names, truth = unname(truth), estimate = NA_real_,
      std_error = NA_real_, lower = NA_real_, upper = NA_real_,
      finite_interval = FALSE, stringsAsFactors = FALSE
    ))
  }
  fit <- result$fit
  intervals <- tryCatch(
    stats::confint(fit, parm = target_names, method = "wald"),
    error = function(e) e
  )
  covariance <- tryCatch(stats::vcov(fit), error = function(e) e)
  if (inherits(intervals, "error") || inherits(covariance, "error")) {
    return(data.frame(
      fixture = row$fixture, cell = row$cell, role = row$role, seed = row$seed,
      parm = target_names, truth = unname(truth), estimate = NA_real_,
      std_error = NA_real_, lower = NA_real_, upper = NA_real_,
      finite_interval = FALSE, stringsAsFactors = FALSE
    ))
  }
  coefficient_names <- names(fit$coefficients$mu)
  covariance_names <- paste0("mu:", coefficient_names)
  data.frame(
    fixture = row$fixture, cell = row$cell, role = row$role, seed = row$seed,
    parm = target_names, truth = unname(truth),
    estimate = unname(fit$coefficients$mu[coefficient_names]),
    std_error = sqrt(diag(covariance)[match(covariance_names, rownames(covariance))]),
    lower = intervals$lower, upper = intervals$upper,
    finite_interval = is.finite(intervals$lower) & is.finite(intervals$upper) &
      intervals$lower < intervals$upper,
    stringsAsFactors = FALSE
  )
}

fixture_rows <- vector("list", nrow(configuration))
attempt_rows <- vector("list", nrow(configuration))
interval_rows <- vector("list", nrow(configuration))
for (i in seq_len(nrow(configuration))) {
  row <- configuration[i, , drop = FALSE]
  result <- safe_fit(simulate_fixture(row))
  fixture_rows[[i]] <- extract_fixture(row, result)
  attempts <- if (is.null(result$fit)) empty_attempt(row$fixture, result$elapsed_sec, result$error) else result$fit$temporal_start_attempts
  attempts$fixture <- row$fixture
  if (!"error" %in% names(attempts)) {
    attempts$error <- NA_character_
  }
  attempt_rows[[i]] <- attempts[, c(
    "fixture", "start", "persistence_start", "status", "convergence",
    "objective", "elapsed_sec", "selected", "error"
  )]
  interval_rows[[i]] <- extract_intervals(row, result)
}

fixture_results <- do.call(rbind, fixture_rows)
attempts <- do.call(rbind, attempt_rows)
intervals <- do.call(rbind, interval_rows)
primary <- intervals$role == "primary"
summary <- data.frame(
  metric = c(
    "n_fixtures", "n_attempts", "n_selected", "n_selected_finite",
    "n_primary_interval_rows", "n_primary_finite_intervals",
    "n_stress_interval_rows", "n_stress_finite_intervals",
    "median_elapsed_sec", "max_elapsed_sec"
  ),
  value = c(
    nrow(fixture_results), nrow(attempts), sum(fixture_results$selected),
    sum(fixture_results$selected & is.finite(fixture_results$objective)),
    sum(primary), sum(intervals$finite_interval[primary]),
    sum(!primary), sum(intervals$finite_interval[!primary]),
    stats::median(fixture_results$elapsed_sec), max(fixture_results$elapsed_sec)
  ),
  stringsAsFactors = FALSE
)

write.csv(configuration, file.path(out_dir, "configuration.csv"), row.names = FALSE)
write.csv(attempts, file.path(out_dir, "raw-attempts.csv"), row.names = FALSE)
write.csv(fixture_results, file.path(out_dir, "fixture-results.csv"), row.names = FALSE)
write.csv(intervals, file.path(out_dir, "interval-results.csv"), row.names = FALSE)
write.csv(summary, file.path(out_dir, "summary.csv"), row.names = FALSE)
provenance <- data.frame(
  key = c("source_commit", "runner_md5", "mode", "native_compile", "run_utc", "n_fixtures", "n_attempts"),
  value = c(
    system2("git", c("rev-parse", "HEAD"), stdout = TRUE),
    unname(tools::md5sum(file.path(root, "tools", "run-temporal-hetar1-interval-feasibility.R"))),
    mode, as.character(compile_native), format(Sys.time(), tz = "UTC", usetz = TRUE), nrow(fixture_results), nrow(attempts)
  ), stringsAsFactors = FALSE
)
write.csv(provenance, file.path(out_dir, "provenance.csv"), row.names = FALSE)
saveRDS(
  list(configuration = configuration, attempts = attempts,
       fixture_results = fixture_results, intervals = intervals,
       summary = summary, provenance = provenance),
  file.path(out_dir, "results.rds")
)
capture.output(sessionInfo(), file = file.path(out_dir, "session-info.txt"))
writeLines(c(
  paste0("# Heterogeneous AR1 interval-feasibility ", mode), "",
  "This immutable fixture run evaluates finite full-Hessian Wald intervals for fixed mean coefficients.",
  "It is not a coverage, standard-error-calibration, variance-component or persistence-inference result.",
  "Every selected fit and signed-start attempt is retained in the accompanying CSV files.", "",
  paste0("Fixtures: ", nrow(fixture_results), "; signed-start attempts: ", nrow(attempts), "."),
  paste0("Primary finite intervals: ", sum(intervals$finite_interval[primary]), "/", sum(primary), "."),
  paste0("Stress finite intervals: ", sum(intervals$finite_interval[!primary]), "/", sum(!primary), ".")
), file.path(out_dir, "RESULTS.md"))

cat(sprintf("TEMPORAL_HETAR1_INTERVAL_%s_WRITTEN\\n", toupper(mode)))
