args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop("Usage: Rscript summarize-timing-095.R CAPSULE_DIRECTORY EXTERNAL_REGISTRY_SHA256",
       call. = FALSE)
}
if (!requireNamespace("digest", quietly = TRUE) ||
    !requireNamespace("jsonlite", quietly = TRUE)) {
  stop("digest and jsonlite are required for capsule verification", call. = FALSE)
}

capsule <- normalizePath(args[[1L]], mustWork = TRUE)
manifest_path <- file.path(capsule, "manifest.csv")
registry_path <- file.path(capsule, "source-hashes.csv")
receipt_path <- file.path(capsule, "supervisor-receipt.json")
design_path <- file.path(capsule, "design-receipt.txt")
required_capsule_files <- c(manifest_path, registry_path, receipt_path, design_path)
if (!all(file.exists(required_capsule_files))) {
  stop("Timing capsule requires manifest.csv, source-hashes.csv, design-receipt.txt, and supervisor-receipt.json",
       call. = FALSE)
}

hash_file <- function(path) digest::digest(path, algo = "sha256", file = TRUE)
registry <- utils::read.csv(registry_path, stringsAsFactors = FALSE,
                            colClasses = "character", check.names = FALSE)
if (!all(c("path", "sha256") %in% names(registry)) || nrow(registry) < 2L ||
    anyNA(registry$path) || any(!nzchar(registry$path)) ||
    anyNA(registry$sha256) || any(!grepl("^[[:xdigit:]]{64}$", registry$sha256)) ||
    anyDuplicated(registry$path)) {
  stop("Invalid or duplicate source hash registry", call. = FALSE)
}
registry_sha <- hash_file(registry_path)
if (!identical(tolower(args[[2L]]), registry_sha)) {
  stop("External source registry seal mismatch", call. = FALSE)
}
summary_arg <- sub("^--file=", "", grep("^--file=", commandArgs(), value = TRUE)[[1L]])
summary_arg <- gsub("~+~", " ", summary_arg, fixed = TRUE)
summary_script <- normalizePath(summary_arg, mustWork = TRUE)
summary_entries <- which(normalizePath(registry$path, mustWork = FALSE) == summary_script)
if (length(summary_entries) != 1L ||
    !identical(tolower(registry$sha256[[summary_entries]]), hash_file(summary_script))) {
  stop("Timing summary implementation is absent from or differs from its pinned source registry",
       call. = FALSE)
}
manifest_entries <- which(normalizePath(registry$path, mustWork = FALSE) == normalizePath(manifest_path))
if (length(manifest_entries) != 1L ||
    !identical(tolower(registry$sha256[[manifest_entries]]), hash_file(manifest_path))) {
  stop("Manifest is absent from or differs from its pinned source registry", call. = FALSE)
}
for (i in seq_len(nrow(registry))) {
  path <- registry$path[[i]]
  if (!file.exists(path) || !identical(tolower(hash_file(path)), tolower(registry$sha256[[i]]))) {
    stop("Pinned source/runtime artifact missing or hash mismatch: ", path, call. = FALSE)
  }
}

manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE,
                            check.names = FALSE, na.strings = character())
manifest_fields <- c("index", "a", "replicate", "seed", "groups", "repeats",
                     "beta0", "beta1", "alpha0", "design_mode", "master_seed", "look")
if (!all(manifest_fields %in% names(manifest)) || nrow(manifest) != 45L ||
    !identical(as.integer(manifest$index), 1:45) ||
    any(!is.finite(manifest$a)) || !setequal(unique(manifest$a), c(-0.5, 0, 0.5)) ||
    any(tabulate(match(manifest$a, c(-0.5, 0, 0.5)), nbins = 3L) != 15L) ||
    any(manifest$design_mode != "timing_only") ||
    any(as.integer(manifest$master_seed) != 2026101903L) ||
    any(manifest$look != "timing")) {
  stop("Manifest must be the 45-row timing_only design (master seed 2026101903, 15 rows per truth)",
       call. = FALSE)
}

design_lines <- readLines(design_path, warn = FALSE)
design <- strsplit(design_lines[grepl("=", design_lines, fixed = TRUE)], "=", fixed = TRUE)
design <- setNames(vapply(design, function(x) paste(x[-1L], collapse = "="), character(1L)),
                   vapply(design, `[[`, character(1L), 1L))
if (!identical(unname(design["design_mode"]), "timing_only") ||
    suppressWarnings(as.integer(design["master_seed"])) != 2026101903L ||
    ("planned_attempts" %in% names(design) && suppressWarnings(as.integer(design["planned_attempts"])) != 45L)) {
  stop("Design receipt identity differs from the timing-only manifest contract", call. = FALSE)
}

receipt <- jsonlite::fromJSON(receipt_path, simplifyVector = FALSE)
required_receipt <- c("planned_indices", "design_mode", "registry_sha256", "manifest_sha256",
                      "finished_at", "interrupted", "subset_complete", "cases")
if (!all(required_receipt %in% names(receipt)) ||
    !identical(as.character(receipt$design_mode), "timing_only") ||
    !identical(tolower(as.character(receipt$registry_sha256)), registry_sha) ||
    !identical(as.character(receipt$manifest_sha256), hash_file(manifest_path)) ||
    ("master_seed" %in% names(receipt) && suppressWarnings(as.integer(receipt$master_seed)) != 2026101903L)) {
  stop("Supervisor receipt identity does not match the timing capsule", call. = FALSE)
}
planned <- suppressWarnings(as.integer(unlist(receipt$planned_indices, use.names = FALSE)))
if (!identical(planned, 1:45)) stop("Supervisor planned indices must exactly match 1:45", call. = FALSE)
if (length(receipt$cases) != 45L) stop("Supervisor cases must retain all 45 planned indices", call. = FALSE)
cases <- do.call(rbind, lapply(receipt$cases, function(x) {
  data.frame(index = suppressWarnings(as.integer(x$index)),
             supervisor_status = as.character(x$status),
             returncode = if (is.null(x$returncode)) NA_integer_ else suppressWarnings(as.integer(x$returncode)),
             stringsAsFactors = FALSE)
}))
if (anyNA(cases$index) || anyDuplicated(cases$index) ||
    !identical(sort(cases$index), 1:45) ||
    any(!cases$supervisor_status %in% c("not_started", "started", "completed", "error",
                                        "timeout", "campaign_timeout", "launch_error", "interrupted"))) {
  stop("Supervisor cases do not provide one recognized status for every planned index", call. = FALSE)
}
if (any(cases$supervisor_status == "completed" &
        (is.na(cases$returncode) | cases$returncode != 0L)) ||
    any(cases$supervisor_status == "error" &
        (is.na(cases$returncode) | cases$returncode == 0L))) {
  stop("Supervisor status and return code disagree", call. = FALSE)
}
finished_at <- suppressWarnings(as.numeric(receipt$finished_at))
supervisor_complete <- length(finished_at) == 1L && is.finite(finished_at) &&
  isFALSE(as.logical(receipt$interrupted)) && isTRUE(as.logical(receipt$subset_complete)) &&
  all(cases$supervisor_status %in% c("completed", "error", "timeout"))

result_files <- list.files(capsule, pattern = "^result-[0-9]{4}\\.csv$", full.names = TRUE)
result_rows <- list()
result_fields <- c("index", "a", "replicate", "seed", "state", "convergence", "pdHess",
                   "max_abs_gradient", "clamp_at_optimum", "lower", "upper", "profile_level", "interval_status",
                   "profile_boundary", "valid_interval", "laplace_oracle_error", "oracle_pass",
                   "warnings", "error", "elapsed")
for (path in result_files) {
  one <- utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
  if (nrow(one) != 1L || !all(result_fields %in% names(one))) {
    stop("Malformed worker result or missing required timing fields: ", basename(path), call. = FALSE)
  }
  index <- suppressWarnings(as.integer(one$index[[1L]]))
  if (is.na(index) || !index %in% planned || !identical(basename(path), sprintf("result-%04d.csv", index))) {
    stop("Worker result file name/index is outside the planned manifest: ", basename(path), call. = FALSE)
  }
  if (!is.finite(as.numeric(one$profile_level[[1L]])) ||
      abs(as.numeric(one$profile_level[[1L]]) - 0.95) > 1e-12) {
    stop("Worker result profile level differs from 0.95 at index ", index, call. = FALSE)
  }
  if (!as.character(one$state[[1L]]) %in% c("started", "profiling", "completed") ||
      as.numeric(one$a[[1L]]) != manifest$a[[index]] ||
      as.integer(one$replicate[[1L]]) != manifest$replicate[[index]] ||
      as.integer(one$seed[[1L]]) != manifest$seed[[index]]) {
    stop("Worker result identity differs from manifest index ", index, call. = FALSE)
  }
  if (any(vapply(result_rows, function(x) x$index[[1L]] == index, logical(1L)))) {
    stop("Duplicate worker result index: ", index, call. = FALSE)
  }
  result_rows[[length(result_rows) + 1L]] <- one
}
results_by_index <- setNames(result_rows, vapply(result_rows, function(x) as.character(as.integer(x$index[[1L]])), character(1L)))

attempts <- lapply(1:45, function(i) {
  key <- as.character(i)
  result <- results_by_index[[key]]
  case <- cases[match(i, cases$index), ]
  has_result <- !is.null(result)
  if (identical(case$supervisor_status, "completed") && (!has_result || is.na(case$returncode) || case$returncode != 0L)) {
    stop("Supervisor completed index lacks its zero-exit worker result: ", i, call. = FALSE)
  }
  if (identical(case$supervisor_status, "not_started") && has_result) {
    stop("Unstarted supervisor case has a worker result: ", i, call. = FALSE)
  }
  state <- if (has_result) as.character(result$state[[1L]]) else "missing"
  elapsed <- if (has_result) suppressWarnings(as.numeric(result$elapsed[[1L]])) else NA_real_
  level <- if (has_result) suppressWarnings(as.numeric(result$profile_level[[1L]])) else NA_real_
  interval_status <- if (has_result) as.character(result$interval_status[[1L]]) else "not_reported"
  boundary <- if (has_result) isTRUE(as.logical(result$profile_boundary[[1L]])) else FALSE
  valid_profile <- has_result && identical(case$supervisor_status, "completed") &&
    isTRUE(case$returncode == 0L) && identical(state, "completed") &&
    isTRUE(as.logical(result$valid_interval[[1L]])) &&
    is.finite(level) && abs(level - 0.95) <= 1e-12 &&
    identical(interval_status, "profile") && !boundary &&
    isTRUE(as.logical(result$pdHess[[1L]])) &&
    isTRUE(as.logical(result$oracle_pass[[1L]])) &&
    is.finite(as.numeric(result$laplace_oracle_error[[1L]])) &&
    abs(as.numeric(result$laplace_oracle_error[[1L]])) < 1e-6 &&
    all(is.finite(as.numeric(c(result$lower[[1L]], result$upper[[1L]])))) &&
    as.numeric(result$lower[[1L]]) < as.numeric(result$upper[[1L]]) &&
    is.finite(as.numeric(result$convergence[[1L]])) && as.integer(result$convergence[[1L]]) == 0L &&
    is.finite(as.numeric(result$max_abs_gradient[[1L]])) && as.numeric(result$max_abs_gradient[[1L]]) < 1e-3 &&
    identical(as.character(result$clamp_at_optimum[[1L]]), "ok") &&
    (is.na(result$error[[1L]]) || !nzchar(as.character(result$error[[1L]])))
  warning_text <- if (has_result && !is.na(result$warnings[[1L]])) as.character(result$warnings[[1L]]) else ""
  error_text <- if (has_result && !is.na(result$error[[1L]])) as.character(result$error[[1L]]) else ""
  data.frame(index = i, a = manifest$a[[i]], replicate = manifest$replicate[[i]], seed = manifest$seed[[i]],
    supervisor_status = case$supervisor_status, returncode = case$returncode,
    result_present = has_result, worker_state = state, elapsed = elapsed,
    completed = identical(case$supervisor_status, "completed") && isTRUE(case$returncode == 0L) &&
      has_result && identical(state, "completed") && !nzchar(error_text),
    valid_profile = isTRUE(valid_profile),
    profile_failure = has_result && (!identical(interval_status, "profile") || !isTRUE(valid_profile)),
    profile_boundary = boundary, profile_status = interval_status,
    warning_present = nzchar(warning_text), warnings = warning_text, error = error_text,
    stringsAsFactors = FALSE)
})
attempts <- do.call(rbind, attempts)

summarize_group <- function(label, values, ix) {
  rows <- attempts[ix, , drop = FALSE]
  observed_elapsed <- rows$elapsed[is.finite(rows$elapsed) & rows$elapsed >= 0]
  data.frame(group = label, a = values, planned = nrow(rows),
    completed = sum(rows$completed), valid_profiles = sum(rows$valid_profile),
    profile_failures = sum(rows$profile_failure), profile_boundaries = sum(rows$profile_boundary),
    warnings = sum(rows$warning_present), elapsed_n = length(observed_elapsed),
    mean_elapsed = if (length(observed_elapsed)) mean(observed_elapsed) else NA_real_,
    median_elapsed = if (length(observed_elapsed)) stats::median(observed_elapsed) else NA_real_,
    calibration_claim = FALSE,
    status = if (!supervisor_complete) "incomplete" else if (!sum(rows$valid_profile)) "nonqualifying_no_valid_profiles" else "timing_only_nonqualifying",
    stringsAsFactors = FALSE)
}
by_truth <- do.call(rbind, lapply(c(-0.5, 0, 0.5), function(value) {
  summarize_group(paste0("truth_", format(value, trim = TRUE)), value, which(attempts$a == value))
}))
overall <- summarize_group("overall", NA_real_, seq_len(nrow(attempts)))
summary <- rbind(by_truth, overall)

utils::write.csv(attempts, file.path(capsule, "timing-attempts.csv"), row.names = FALSE, na = "")
utils::write.csv(summary, file.path(capsule, "timing-summary.csv"), row.names = FALSE, na = "")
writeLines(c(
  "# Timing-only Bernoulli profile summary", "",
  paste0("Status: ", if (supervisor_complete) "timing_only_nonqualifying" else "incomplete"),
  "Calibration claim: false.",
  paste0("Planned attempts retained: ", nrow(attempts), "."),
  paste0("Supervisor complete: ", supervisor_complete, "."),
  "Runtime and profile diagnostics are descriptive timing records only.",
  paste(capture.output(print(summary, row.names = FALSE)), collapse = "\n")
), file.path(capsule, "timing-summary.md"), useBytes = TRUE)
cat(sprintf("TIMING_SUMMARY_WRITTEN planned=45 completed=%d valid_profiles=%d supervisor_complete=%s calibration_claim=false\n",
            sum(attempts$completed), sum(attempts$valid_profile), supervisor_complete))
