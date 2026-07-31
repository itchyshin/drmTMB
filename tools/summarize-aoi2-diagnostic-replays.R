#!/usr/bin/env Rscript

# Internal AOI-2 diagnostic summary. It describes a frozen stratified replay
# sample and intentionally contains no point-recovery or uncertainty decision.

args <- commandArgs(trailingOnly = TRUE)
arg_value <- function(name) {
  hit <- grep(paste0("^--", name, "="), args, value = TRUE)
  if (length(hit) != 1L) {
    stop(sprintf("Supply exactly one --%s=VALUE.", name), call. = FALSE)
  }
  sub(paste0("^--", name, "="), "", hit)
}

manifest_path <- arg_value("manifest")
input_dir <- arg_value("input-dir")
out_dir <- arg_value("out-dir")
if (!file.exists(manifest_path)) stop("`manifest` does not exist.", call. = FALSE)
if (!dir.exists(input_dir)) stop("`input-dir` does not exist.", call. = FALSE)
if (file.exists(out_dir)) stop("Refusing to overwrite an AOI-2 diagnostic analysis directory.", call. = FALSE)

manifest <- utils::read.csv(manifest_path, check.names = FALSE, stringsAsFactors = FALSE)
key_columns <- c("formula_id", "n", "replicate", "seed")
required_manifest <- c(key_columns, "original_status", "diagnostic_stratum", "population_n")
if (length(missing <- setdiff(required_manifest, names(manifest)))) {
  stop(sprintf("Diagnostic manifest is missing required fields: %s", paste(missing, collapse = ", ")),
    call. = FALSE)
}
if (anyDuplicated(do.call(paste, c(manifest[key_columns], sep = ":")))) {
  stop("Diagnostic manifest contains duplicate replay keys.", call. = FALSE)
}

dispatch_path <- file.path(input_dir, "dispatch.csv")
if (!file.exists(dispatch_path)) stop("Diagnostic replays are not complete: dispatch.csv is absent.", call. = FALSE)
dispatch <- utils::read.csv(dispatch_path, check.names = FALSE, stringsAsFactors = FALSE)
if (nrow(dispatch) != nrow(manifest) || any(dispatch$exit_status != 0L)) {
  stop("Diagnostic replays are incomplete or contain failed attempts.", call. = FALSE)
}
files <- list.files(input_dir, pattern = "^raw-attempts\\.csv$", recursive = TRUE,
  full.names = TRUE)
if (length(files) != nrow(manifest)) {
  stop("Diagnostic replay result count does not equal the frozen manifest.", call. = FALSE)
}

rows <- lapply(files, function(path) {
  data <- utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  data$source_file <- normalizePath(path)
  data
})
columns <- unique(unlist(lapply(rows, names), use.names = FALSE))
all_rows <- do.call(rbind, lapply(rows, function(row) {
  for (column in setdiff(columns, names(row))) row[[column]] <- NA
  row[columns]
}))
required_payload <- c(
  key_columns, "status", "prediction_status", "diagnostic_hard_parameter_cap",
  "diagnostic_nonfinite_logLik", "diagnostic_convergence_failure",
  "diagnostic_multistart_disagreement", "diagnostic_weak_curvature",
  "diagnostic_score_failure", "diagnostic_endpoint_failure"
)
if (length(missing <- setdiff(required_payload, names(all_rows)))) {
  stop(sprintf("Diagnostic replay results are missing payload fields: %s", paste(missing, collapse = ", ")),
    call. = FALSE)
}
if (anyDuplicated(do.call(paste, c(all_rows[key_columns], sep = ":")))) {
  stop("Diagnostic replay results contain duplicate keys.", call. = FALSE)
}

key <- function(x) do.call(paste, c(x[key_columns], sep = ":"))
if (!identical(sort(key(all_rows)), sort(key(manifest)))) {
  stop("Diagnostic replay keys do not match the frozen manifest.", call. = FALSE)
}
rows <- merge(manifest, all_rows, by = key_columns, all = FALSE, sort = FALSE,
  suffixes = c("_manifest", "_replay"))
if (nrow(rows) != nrow(manifest)) stop("Diagnostic replay merge lost manifest rows.", call. = FALSE)

trigger_columns <- c(
  hard_parameter_cap = "diagnostic_hard_parameter_cap",
  nonfinite_logLik = "diagnostic_nonfinite_logLik",
  convergence_failure = "diagnostic_convergence_failure",
  multistart_disagreement = "diagnostic_multistart_disagreement",
  weak_curvature = "diagnostic_weak_curvature",
  score_failure = "diagnostic_score_failure",
  endpoint_failure = "diagnostic_endpoint_failure"
)
summary_rows <- list()
index <- 0L
groups <- split(rows, interaction(rows$formula_id, rows$n, rows$diagnostic_stratum,
  drop = TRUE, lex.order = TRUE))
for (group in groups) {
  for (trigger in names(trigger_columns)) {
    index <- index + 1L
    values <- group[[trigger_columns[[trigger]]]]
    summary_rows[[index]] <- data.frame(
      formula_id = group$formula_id[[1L]], n = group$n[[1L]],
      diagnostic_stratum = group$diagnostic_stratum[[1L]],
      original_population_n = group$population_n[[1L]],
      selected_n = nrow(group), trigger = trigger,
      trigger_count = sum(values %in% TRUE),
      trigger_rate = mean(values %in% TRUE),
      stringsAsFactors = FALSE
    )
  }
}
trigger_rates <- do.call(rbind, summary_rows)
status_match <- aggregate(
  I(status_replay == ifelse(original_status == "unavailable", "boundary_unresolved", original_status)) ~
    formula_id + n + diagnostic_stratum,
  data = rows, FUN = function(x) c(selected_n = length(x), matching_n = sum(x))
)
status_match <- cbind(status_match[1:3], as.data.frame(status_match[[4]]))
names(status_match)[4:5] <- c("selected_n", "status_matching_n")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
utils::write.csv(trigger_rates, file.path(out_dir, "trigger-rates.csv"), row.names = FALSE)
utils::write.csv(status_match, file.path(out_dir, "status-match.csv"), row.names = FALSE)
utils::write.csv(rows, file.path(out_dir, "replay-rows.csv"), row.names = FALSE)
writeLines(c(
  "INTERNAL_AOI2_DIAGNOSTIC_ONLY",
  "No point-recovery, uncertainty, interval, covariance, or capability claim is calculated here.",
  "Rates describe the frozen stratified sample; they are not a replacement for the original 3,000-attempt HOLD."
), file.path(out_dir, "decision.txt"))
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
