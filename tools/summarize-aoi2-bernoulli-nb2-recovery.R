#!/usr/bin/env Rscript

# AOI-2 point-recovery analysis.  It is deliberately incapable of calculating
# covariance, standard errors, intervals, or coverage.

args <- commandArgs(trailingOnly = TRUE)
arg_value <- function(name) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) != 1L) {
    stop(sprintf("Supply exactly one --%s=VALUE.", name), call. = FALSE)
  }
  sub(paste0("^--", name, "="), "", hit)
}

input_dir <- arg_value("input-dir")
out_dir <- arg_value("out-dir")
if (!dir.exists(input_dir)) stop("`input-dir` does not exist.", call. = FALSE)
if (file.exists(out_dir)) stop("Refusing to overwrite an AOI-2 analysis directory.", call. = FALSE)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

specifications <- list(
  additive = c("(Intercept)", "x1", "x2"),
  mixed = c("(Intercept)", "x1", "habitatforest"),
  factor_interaction = c("(Intercept)", "x1", "habitatforest", "x1:habitatforest"),
  numeric_interaction = c("(Intercept)", "x1", "x2", "x1:x2"),
  transformation = c("(Intercept)", "x1", "I(x2^2)")
)
files <- list.files(input_dir, pattern = "^raw-attempts\\.csv$", recursive = TRUE, full.names = TRUE)
if (!length(files)) stop("No AOI-2 raw-attempts.csv files found.", call. = FALSE)

expected_n <- c(360L, 720L, 1440L)
expected_replicates <- 200L
required_base <- c("formula_id", "n", "replicate", "seed", "source_sha", "status", "stage")
rows <- lapply(files, function(path) {
  data <- utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  missing <- setdiff(required_base, names(data))
  if (length(missing)) {
    stop(sprintf("%s is missing required fields: %s", path, paste(missing, collapse = ", ")), call. = FALSE)
  }
  data$source_file <- normalizePath(path)
  data
})

metric_rows <- list()
cell_rows <- list()
index <- 0L
for (formula_id in names(specifications)) {
  for (n_value in expected_n) {
    cell <- do.call(rbind, lapply(rows, function(x) {
      x[x$formula_id == formula_id & x$n == n_value, , drop = FALSE]
    }))
    keys <- paste(cell$replicate, cell$seed, sep = ":")
    expected_key_set <- identical(sort(unique(cell$replicate)), seq_len(expected_replicates))
    source_sha_count <- length(unique(cell$source_sha[nzchar(cell$source_sha)]))
    complete <- nrow(cell) == expected_replicates && !anyDuplicated(keys) &&
      expected_key_set && source_sha_count == 1L
    status_usable <- cell$status == "interior"
    cell_rows[[length(cell_rows) + 1L]] <- data.frame(
      formula_id = formula_id, n = n_value, expected_attempts = expected_replicates,
      retained_attempts = nrow(cell), duplicate_keys = anyDuplicated(keys) > 0L,
      complete_key_set = expected_key_set, source_sha_count = source_sha_count,
      complete = complete,
      stringsAsFactors = FALSE
    )
    for (coefficient in specifications[[formula_id]]) {
      estimate_column <- paste0("estimate_", make.names(coefficient))
      truth_column <- paste0("truth_", make.names(coefficient))
      if (!all(c(estimate_column, truth_column) %in% names(cell))) {
        stop(sprintf("%s n=%d lacks %s or %s.", formula_id, n_value, estimate_column, truth_column), call. = FALSE)
      }
      usable <- status_usable & is.finite(cell[[estimate_column]]) & is.finite(cell[[truth_column]])
      error <- cell[[estimate_column]][usable] - cell[[truth_column]][usable]
      index <- index + 1L
      metric_rows[[index]] <- data.frame(
        formula_id = formula_id, n = n_value, target = coefficient,
        target_type = "alpha", attempted = nrow(cell), usable = sum(usable),
        availability = if (nrow(cell)) mean(usable) else NA_real_,
        bias = if (length(error)) mean(error) else NA_real_,
        rmse = if (length(error)) sqrt(mean(error^2)) else NA_real_,
        pass = complete && sum(usable) >= 0.95 * expected_replicates &&
          length(error) && abs(mean(error)) <= 0.10,
        stringsAsFactors = FALSE
      )
    }
    for (prediction_index in seq_len(5L)) {
      estimate_column <- paste0("eta_newdata_", prediction_index)
      truth_column <- paste0("eta_truth_newdata_", prediction_index)
      if (!all(c(estimate_column, truth_column) %in% names(cell))) {
        stop(sprintf("%s n=%d lacks fixed newdata target %d.", formula_id, n_value, prediction_index), call. = FALSE)
      }
      usable <- status_usable & is.finite(cell[[estimate_column]]) & is.finite(cell[[truth_column]])
      error <- cell[[estimate_column]][usable] - cell[[truth_column]][usable]
      index <- index + 1L
      metric_rows[[index]] <- data.frame(
        formula_id = formula_id, n = n_value, target = paste0("eta_newdata_", prediction_index),
        target_type = "eta_link", attempted = nrow(cell), usable = sum(usable),
        availability = if (nrow(cell)) mean(usable) else NA_real_,
        bias = if (length(error)) mean(error) else NA_real_,
        rmse = if (length(error)) sqrt(mean(error^2)) else NA_real_,
        pass = complete && sum(usable) >= 0.95 * expected_replicates &&
          length(error) && abs(mean(error)) <= 0.10,
        stringsAsFactors = FALSE
      )
    }
  }
}

cell_summary <- do.call(rbind, cell_rows)
metrics <- do.call(rbind, metric_rows)
decision <- merge(
  cell_summary,
  aggregate(pass ~ formula_id + n, metrics, all),
  by = c("formula_id", "n"), all.x = TRUE
)
names(decision)[names(decision) == "pass"] <- "point_recovery_pass"
decision$decision <- ifelse(decision$complete & decision$point_recovery_pass,
  "PASS_POINT_RECOVERY_ONLY", "HOLD_NO_POINT_RECOVERY_CLAIM"
)
utils::write.csv(cell_summary, file.path(out_dir, "cell-retention.csv"), row.names = FALSE)
utils::write.csv(metrics, file.path(out_dir, "point-recovery-metrics.csv"), row.names = FALSE)
utils::write.csv(decision, file.path(out_dir, "decision.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
