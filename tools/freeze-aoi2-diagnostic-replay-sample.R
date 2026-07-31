#!/usr/bin/env Rscript

# Freeze a bounded AOI-2 diagnostic replay manifest from the immutable r3/r4
# point-recovery records. This does not score point recovery or uncertainty.

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
sampling_seed <- suppressWarnings(as.integer(arg_value("sampling-seed")))
if (!dir.exists(input_dir)) stop("`input-dir` does not exist.", call. = FALSE)
if (file.exists(out_dir)) stop("Refusing to overwrite an AOI-2 diagnostic sample directory.", call. = FALSE)
if (!is.finite(sampling_seed)) stop("`sampling-seed` must be a finite integer.", call. = FALSE)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

formula_ids <- c(
  "additive", "mixed", "factor_interaction", "numeric_interaction", "transformation"
)
n_values <- c(360L, 720L, 1440L)
statuses <- c("unavailable", "near_boundary", "interior")
target_by_status <- c(unavailable = 5L, near_boundary = 2L, interior = 2L)
expected_replicates <- seq_len(200L)
required_columns <- c(
  "formula_id", "n", "replicate", "seed", "status", "source_sha", "fingerprint"
)
files <- list.files(input_dir, pattern = "^raw-attempts\\.csv$", recursive = TRUE,
  full.names = TRUE)
if (!length(files)) stop("No retained AOI-2 raw-attempts.csv files found.", call. = FALSE)

rows <- lapply(files, function(path) {
  data <- utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  missing <- setdiff(required_columns, names(data))
  if (length(missing)) {
    stop(sprintf("%s is missing required fields: %s", path, paste(missing, collapse = ", ")),
      call. = FALSE)
  }
  data$source_file <- normalizePath(path)
  data[, c(required_columns, "source_file"), drop = FALSE]
})
columns <- unique(unlist(lapply(rows, names), use.names = FALSE))
all_rows <- do.call(rbind, lapply(rows, function(row) row[columns]))

if (any(!all_rows$formula_id %in% formula_ids) || any(!all_rows$n %in% n_values)) {
  stop("Retained records contain an unsupported AOI-2 cell.", call. = FALSE)
}
if (any(!all_rows$status %in% statuses)) {
  stop("Retained records contain an unsupported AOI-2 outer status.", call. = FALSE)
}
if (any(!grepl("^[0-9a-f]{40}$", all_rows$source_sha))) {
  stop("Retained records contain a malformed source SHA.", call. = FALSE)
}

manifest <- list()
summary <- list()
index <- 0L
summary_index <- 0L
set.seed(sampling_seed)
for (formula_id in formula_ids) {
  for (n_value in n_values) {
    cell <- all_rows[all_rows$formula_id == formula_id & all_rows$n == n_value, , drop = FALSE]
    key <- paste(cell$replicate, cell$seed, sep = ":")
    if (nrow(cell) != length(expected_replicates) || anyDuplicated(key) ||
        !identical(sort(cell$replicate), expected_replicates)) {
      stop(sprintf("Retained records are incomplete or duplicate for %s n=%d.",
        formula_id, n_value), call. = FALSE)
    }
    if (length(unique(cell$source_sha)) != 1L || length(unique(cell$fingerprint)) != 1L) {
      stop(sprintf("Retained provenance is inconsistent for %s n=%d.",
        formula_id, n_value), call. = FALSE)
    }
    for (status in statuses) {
      stratum <- cell[cell$status == status, , drop = FALSE]
      target_n <- target_by_status[[status]]
      selected_n <- min(nrow(stratum), target_n)
      summary_index <- summary_index + 1L
      summary[[summary_index]] <- data.frame(
        formula_id = formula_id, n = n_value, original_status = status,
        population_n = nrow(stratum), target_n = target_n, selected_n = selected_n,
        sampling_seed = sampling_seed, stringsAsFactors = FALSE
      )
      if (!selected_n) next
      selected <- stratum[sample.int(nrow(stratum), selected_n, replace = FALSE), , drop = FALSE]
      selected$original_status <- selected$status
      selected$diagnostic_stratum <- ifelse(selected$status == "unavailable",
        "boundary_unresolved", selected$status)
      selected$population_n <- nrow(stratum)
      selected$target_n <- target_n
      selected$sampling_seed <- sampling_seed
      selected$selection_order <- seq_len(selected_n)
      index <- index + 1L
      manifest[[index]] <- selected
    }
  }
}

manifest <- do.call(rbind, manifest)
summary <- do.call(rbind, summary)
manifest <- manifest[order(manifest$formula_id, manifest$n,
  match(manifest$original_status, statuses), manifest$selection_order), , drop = FALSE]
utils::write.csv(manifest, file.path(out_dir, "manifest.csv"), row.names = FALSE)
utils::write.csv(summary, file.path(out_dir, "sampling-summary.csv"), row.names = FALSE)
writeLines(capture.output(sessionInfo()), file.path(out_dir, "session-info.txt"))
