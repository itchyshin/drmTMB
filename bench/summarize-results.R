#!/usr/bin/env Rscript

# Summarise optional large-data benchmark CSV output for humans. This script is
# intentionally dependency-free because benchmark runs often happen in stripped
# down environments.

parse_args <- function(args = commandArgs(trailingOnly = TRUE)) {
  defaults <- list(
    input = "bench/results/large-phylo-location.csv",
    converged_only = FALSE
  )
  if (any(args %in% c("-h", "--help"))) {
    print_usage()
    quit(save = "no", status = 0)
  }
  if (length(args) == 0L) {
    return(defaults)
  }
  i <- 1L
  while (i <= length(args)) {
    key <- args[[i]]
    value <- NULL
    if (grepl("^--[^=]+=", key)) {
      parts <- strsplit(sub("^--", "", key), "=", fixed = TRUE)[[1L]]
      key <- parts[[1L]]
      value <- parts[[2L]]
    } else {
      key <- sub("^--", "", key)
      i <- i + 1L
      if (i > length(args)) {
        stop("Missing value for --", key, call. = FALSE)
      }
      value <- args[[i]]
    }
    key <- gsub("-", "_", key, fixed = TRUE)
    if (!key %in% names(defaults)) {
      stop("Unknown argument --", key, call. = FALSE)
    }
    defaults[[key]] <- cast_arg(value, defaults[[key]], key)
    i <- i + 1L
  }
  defaults
}

cast_arg <- function(value, template, key) {
  if (is.logical(template)) {
    value <- tolower(value)
    if (!value %in% c("true", "false", "1", "0", "yes", "no")) {
      stop("--", key, " must be true or false.", call. = FALSE)
    }
    return(value %in% c("true", "1", "yes"))
  }
  value
}

print_usage <- function() {
  cat(
    "Usage: Rscript bench/summarize-results.R [options]\n\n",
    "Options:\n",
    "  --input PATH            Benchmark CSV path; default bench/results/large-phylo-location.csv\n",
    "  --converged-only BOOL   Keep only convergence == 0 rows; default false\n",
    sep = ""
  )
}

required_columns <- c(
  "rows",
  "species",
  "tree",
  "factor_heavy",
  "sigma_x",
  "memory_light",
  "convergence",
  "fit_sec",
  "fit_object_mb",
  "model_matrix_mb",
  "tmb_data_mb",
  "gc_used_mb_post_fit",
  "sigma_hat",
  "sd_phylo_hat"
)

optional_diagnostic_columns <- c(
  "convergence_message",
  "iterations",
  "function_evaluations",
  "gradient_evaluations"
)

optional_design_columns <- c(
  "model_matrix_largest",
  "model_matrix_largest_cols",
  "model_matrix_largest_density"
)

read_results <- function(path) {
  if (!file.exists(path)) {
    stop("Benchmark CSV not found: ", path, call. = FALSE)
  }
  x <- utils::read.csv(path, check.names = FALSE)
  missing <- setdiff(required_columns, names(x))
  if (length(missing) > 0L) {
    stop(
      "Benchmark CSV is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  x
}

flag <- function(x) {
  ifelse(as.logical(x), "yes", "no")
}

scenario_label <- function(x) {
  paste0(
    x$rows,
    " rows / ",
    x$species,
    " species / ",
    x$tree,
    " / factor=",
    flag(x$factor_heavy),
    " / sigma_x=",
    flag(x$sigma_x),
    " / memory_light=",
    flag(x$memory_light)
  )
}

round_numeric <- function(x, digits = 2L) {
  ifelse(is.na(x), NA, round(as.numeric(x), digits = digits))
}

diagnostic_status <- function(x) {
  has_diagnostics <- all(optional_diagnostic_columns %in% names(x))
  if (!has_diagnostics) {
    return(rep("legacy_schema", nrow(x)))
  }
  ifelse(
    is.na(x$convergence_message) | !nzchar(x$convergence_message),
    "diagnostics_missing",
    "diagnostics_recorded"
  )
}

timing_status <- function(x) {
  ifelse(
    as.integer(x$convergence) == 0L,
    "timing_usable",
    "diagnostic_only"
  )
}

summarise_results <- function(x, converged_only = FALSE) {
  if (isTRUE(converged_only)) {
    x <- x[as.integer(x$convergence) == 0L, , drop = FALSE]
  }
  if (nrow(x) == 0L) {
    return(data.frame())
  }
  out <- data.frame(
    scenario = scenario_label(x),
    convergence = as.integer(x$convergence),
    status = timing_status(x),
    diagnostics = diagnostic_status(x),
    fit_sec = round_numeric(x$fit_sec),
    fit_object_mb = round_numeric(x$fit_object_mb),
    model_matrix_mb = round_numeric(x$model_matrix_mb),
    tmb_data_mb = round_numeric(x$tmb_data_mb),
    gc_post_fit_mb = round_numeric(x$gc_used_mb_post_fit),
    sigma_hat = round_numeric(x$sigma_hat, digits = 3L),
    sd_phylo_hat = round_numeric(x$sd_phylo_hat, digits = 3L),
    stringsAsFactors = FALSE
  )
  if (all(optional_diagnostic_columns %in% names(x))) {
    out$convergence_message <- x$convergence_message
    out$iterations <- as.integer(x$iterations)
    out$function_evaluations <- as.integer(x$function_evaluations)
  }
  if (all(optional_design_columns %in% names(x))) {
    out$model_matrix_largest <- x$model_matrix_largest
    out$model_matrix_largest_cols <- as.integer(x$model_matrix_largest_cols)
    out$model_matrix_largest_density <- round_numeric(
      x$model_matrix_largest_density,
      digits = 4L
    )
  }
  out
}

markdown_table <- function(x) {
  if (nrow(x) == 0L) {
    cat("No rows to summarize.\n")
    return(invisible(NULL))
  }
  x[] <- lapply(x, function(col) {
    col[is.na(col)] <- ""
    as.character(col)
  })
  cat("| ", paste(names(x), collapse = " | "), " |\n", sep = "")
  cat("| ", paste(rep("---", ncol(x)), collapse = " | "), " |\n", sep = "")
  for (i in seq_len(nrow(x))) {
    cat("| ", paste(x[i, ], collapse = " | "), " |\n", sep = "")
  }
  invisible(x)
}

main <- function() {
  args <- parse_args()
  results <- read_results(args$input)
  summary <- summarise_results(results, args$converged_only)
  cat("# Benchmark Summary\n\n")
  cat("Input: `", args$input, "`\n\n", sep = "")
  markdown_table(summary)
  if (!all(optional_diagnostic_columns %in% names(results))) {
    cat(
      "\nNote: this CSV uses the older benchmark schema. Rerun the benchmark ",
      "with a fresh output path to record optimizer messages and evaluation ",
      "counts.\n",
      sep = ""
    )
  }
  if (any(as.integer(results$convergence) != 0L, na.rm = TRUE)) {
    cat(
      "\nNote: rows with nonzero convergence are diagnostic only; do not use ",
      "them as stable timing evidence.\n",
      sep = ""
    )
  }
}

if (identical(environment(), globalenv())) {
  main()
}
