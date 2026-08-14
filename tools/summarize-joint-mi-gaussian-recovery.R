#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
out_dir <- if (length(args)) args[[1L]] else file.path(
  "docs", "dev-log", "simulation-artifacts", "2026-08-13-joint-mi-gaussian-recovery"
)
result_dir <- file.path(out_dir, "results")
paths <- sort(list.files(result_dir, pattern = "\\.csv$", full.names = TRUE))
if (!length(paths)) stop("No replicate CSV files found.", call. = FALSE)
raw <- do.call(rbind, lapply(paths, utils::read.csv, stringsAsFactors = FALSE))
key <- paste(raw$cell, raw$replicate, raw$seed, sep = ":")
if (anyDuplicated(key) || nrow(raw) != 3000L) {
  stop("Expected 3,000 unique preregistered replicate rows.", call. = FALSE)
}
raw$usable <- with(raw,
  fit_success & convergence == 0L & pdHess & is.finite(max_gradient) & max_gradient <= 0.01
)
parameters <- sub("^truth_", "", grep("^truth_", names(raw), value = TRUE))
cells <- unique(raw[c("cell_id", "cell", "n", "rho_x", "missing_rate")])
cell_summary <- do.call(rbind, lapply(seq_len(nrow(cells)), function(i) {
  x <- raw[raw$cell == cells$cell[[i]], , drop = FALSE]
  data.frame(cells[i, , drop = FALSE],
    attempted = nrow(x), usable = sum(x$usable),
    usable_fraction = mean(x$usable),
    failures = sum(!x$fit_success), nonconverged = sum(x$fit_success & x$convergence != 0L, na.rm = TRUE),
    non_pdHess = sum(x$fit_success & !x$pdHess),
    gradient_fail = sum(x$fit_success & is.finite(x$max_gradient) & x$max_gradient > 0.01),
    median_elapsed = stats::median(x$elapsed), stringsAsFactors = FALSE
  )
}))
summary <- do.call(rbind, lapply(seq_len(nrow(cells)), function(i) {
  x <- raw[raw$cell == cells$cell[[i]] & raw$usable, , drop = FALSE]
  do.call(rbind, lapply(parameters, function(parameter) {
    truth <- x[[paste0("truth_", parameter)]]
    estimate <- x[[paste0("estimate_", parameter)]]
    error <- estimate - truth
    data.frame(cells[i, , drop = FALSE], parameter = parameter,
      usable = sum(is.finite(error)), mean_error = mean(error, na.rm = TRUE),
      mcse_mean_error = stats::sd(error, na.rm = TRUE) / sqrt(sum(is.finite(error))),
      rmse = sqrt(mean(error^2, na.rm = TRUE)), stringsAsFactors = FALSE)
  }))
}))
utils::write.csv(raw, file.path(out_dir, "replicates.csv"), row.names = FALSE)
utils::write.csv(cell_summary, file.path(out_dir, "cell-summary.csv"), row.names = FALSE)
utils::write.csv(summary, file.path(out_dir, "parameter-summary.csv"), row.names = FALSE)
cat(sprintf("Summarised %d attempts across %d cells.\n", nrow(raw), nrow(cells)))
