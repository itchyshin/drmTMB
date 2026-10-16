#!/usr/bin/env Rscript
# Summarize t9 coverage tables from R and Julia replicate TSVs.

args <- commandArgs(trailingOnly = TRUE)
r_path <- if (length(args) >= 1) args[[1]] else "/workspace/sweep-oct16/t9/results/r_reps.tsv"
jl_path <- if (length(args) >= 2) args[[2]] else "/workspace/sweep-oct16/t9/results/jl_reps.tsv"
out_dir <- if (length(args) >= 3) args[[3]] else "/workspace/sweep-oct16/t9/results"

summarise_one <- function(path, engine_label) {
  if (!file.exists(path) || file.info(path)$size == 0) {
    return(NULL)
  }
  d <- utils::read.delim(path, stringsAsFactors = FALSE, na.strings = c("", "NA", "NaN"))
  if (!nrow(d)) return(NULL)
  if (!"covered" %in% names(d)) return(NULL)
  d$covered_l <- as.logical(d$covered)
  d$finite_interval <- as.logical(d$finite_interval)
  d$silent_nan <- as.logical(d$silent_nan)
  d$timed_out <- as.logical(d$timed_out)
  split_vars <- c("engine", "cell_index", "G", "sd_g", "method", "parm")
  split_vars <- split_vars[split_vars %in% names(d)]
  parts <- split(d, d[split_vars], drop = TRUE)
  rows <- lapply(parts, function(x) {
    n <- nrow(x)
    n_finite <- sum(x$finite_interval, na.rm = TRUE)
    n_cover <- sum(x$covered_l, na.rm = TRUE)
    n_attempt <- n
    cov_all <- if (n_attempt > 0) n_cover / n_attempt else NA_real_
    cov_finite <- if (n_finite > 0) n_cover / n_finite else NA_real_
    mcse <- if (n_attempt > 0 && is.finite(cov_all)) sqrt(cov_all * (1 - cov_all) / n_attempt) else NA_real_
    profile_pass <- NA
    if (identical(unique(as.character(x$method)), "profile") && is.finite(cov_all)) {
      profile_pass <- cov_all >= 0.93 && cov_all <= 0.97
    }
    data.frame(
      engine = unique(x$engine)[1],
      cell_index = unique(x$cell_index)[1],
      G = unique(x$G)[1],
      sd_g = unique(x$sd_g)[1],
      method = unique(x$method)[1],
      parm = unique(x$parm)[1],
      n_attempt = n_attempt,
      n_finite = n_finite,
      n_cover = n_cover,
      n_error = sum(!is.na(x$error) & nzchar(as.character(x$error))),
      n_timeout = sum(x$timed_out, na.rm = TRUE),
      n_silent_nan = sum(x$silent_nan, na.rm = TRUE),
      n_boundary = if ("profile_boundary" %in% names(x)) sum(as.logical(x$profile_boundary), na.rm = TRUE) else NA_integer_,
      coverage_all_attempts = cov_all,
      coverage_finite = cov_finite,
      coverage_mcse = mcse,
      profile_pass_93_97 = profile_pass,
      mean_elapsed_method = mean(as.numeric(x$elapsed_method), na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  out
}

r_sum <- summarise_one(r_path, "drmTMB")
jl_sum <- summarise_one(jl_path, "DRModels.jl")
all_sum <- rbind(r_sum, jl_sum)
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
if (!is.null(all_sum)) {
  utils::write.table(
    all_sum,
    file = file.path(out_dir, "coverage_summary.tsv"),
    sep = "\t", row.names = FALSE, quote = FALSE
  )
  print(all_sum)
} else {
  cat("No replicate tables yet.\n")
}
