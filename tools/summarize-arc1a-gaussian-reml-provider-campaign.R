#!/usr/bin/env Rscript

# Reconstruct Arc 1a campaign summaries from retained raw target-level TSVs.
# This file is both a standalone CLI and a sourceable helper for the runner.

`%||%` <- function(x, y) if (is.null(x)) y else x

clean_text <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- NA_character_
  x <- gsub("[\r\n\t]+", " ", x)
  x <- gsub(" +", " ", x)
  trimws(x)
}

write_tsv <- function(x, path) {
  character_cols <- vapply(x, is.character, logical(1L))
  x[character_cols] <- lapply(x[character_cols], clean_text)
  utils::write.table(
    x,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
}

atomic_write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  temporary <- tempfile(pattern = paste0(basename(path), "."), tmpdir = dirname(path))
  on.exit(unlink(temporary), add = TRUE)
  write_tsv(x, temporary)
  if (!file.rename(temporary, path)) {
    stop("Could not atomically install artifact: ", path, call. = FALSE)
  }
  invisible(path)
}

read_tsv <- function(path) {
  utils::read.delim(
    path,
    sep = "\t",
    quote = "",
    check.names = FALSE,
    stringsAsFactors = FALSE,
    na.strings = "NA"
  )
}

mean_or_na <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) NA_real_ else mean(x)
}

median_or_na <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) NA_real_ else stats::median(x)
}

mcse_mean <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 2L) return(NA_real_)
  stats::sd(x) / sqrt(length(x))
}

mcse_proportion <- function(n_success, n_total) {
  if (n_total < 1L) return(NA_real_)
  p <- n_success / n_total
  sqrt(p * (1 - p) / n_total)
}

exact_binomial_ci <- function(n_success, n_total) {
  if (n_total < 1L) return(c(low = NA_real_, high = NA_real_))
  stats::setNames(
    as.numeric(stats::binom.test(n_success, n_total)$conf.int),
    c("low", "high")
  )
}

count_true <- function(x) sum(x %in% TRUE)

split_rows <- function(x, columns) {
  key_parts <- lapply(columns, function(column) x[[column]])
  names(key_parts) <- columns
  split(x, interaction(key_parts, drop = TRUE, lex.order = TRUE))
}

first_fit_rows <- function(raw) {
  fit_groups <- split(raw, raw$fit_id)
  rows <- lapply(fit_groups, function(x) {
    invariant <- c(
      "task_id", "fit_id", "base_cell_id", "cell_index", "provider", "M",
      "shape", "replicate_index", "seed", "estimator", "fit_status",
      "fit_error", "convergence", "pdHess", "objective", "fit_elapsed_sec",
      "fit_warning_count", "fit_warnings", "beta0_truth", "beta_x_truth",
      "sigma_truth", "beta0_hat", "beta_x_hat", "sigma_hat",
      "max_abs_gradient_fixed"
    )
    invariant <- intersect(invariant, names(x))
    for (column in invariant) {
      values <- unique(x[[column]])
      values <- values[!is.na(values)]
      if (length(values) > 1L) {
        stop(
          "Fit-level field `", column, "` varies across target rows for ",
          x$fit_id[[1L]], ".",
          call. = FALSE
        )
      }
    }
    x[1L, , drop = FALSE]
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out
}

summarize_fit_groups <- function(raw, phase) {
  fits <- first_fit_rows(raw)
  groups <- split_rows(fits, c("base_cell_id", "estimator"))
  rows <- lapply(groups, function(x) {
    n_attempted <- nrow(x)
    n_fit_error <- sum(x$fit_status == "fit_error")
    n_nonconverged <- sum(x$fit_status == "nonconverged")
    n_converged <- sum(x$fit_status == "converged")
    if (n_attempted != n_fit_error + n_nonconverged + n_converged) {
      stop("Fit-status denominator identity failed for ", x$base_cell_id[[1L]], call. = FALSE)
    }
    beta0_error <- x$beta0_hat - x$beta0_truth
    beta_x_error <- x$beta_x_hat - x$beta_x_truth
    sigma_relative_error <- (x$sigma_hat - x$sigma_truth) / x$sigma_truth
    sigma_finite <- is.finite(x$sigma_hat)
    gradient_finite <- is.finite(x$max_abs_gradient_fixed)
    data.frame(
      phase = phase,
      base_cell_id = x$base_cell_id[[1L]],
      cell_index = x$cell_index[[1L]],
      provider = x$provider[[1L]],
      M = x$M[[1L]],
      shape = x$shape[[1L]],
      estimator = x$estimator[[1L]],
      n_attempted_fits = n_attempted,
      n_fit_error = n_fit_error,
      n_nonconverged = n_nonconverged,
      n_converged = n_converged,
      n_pdHess_true = count_true(x$pdHess[x$fit_status == "converged"]),
      n_pdHess_false = sum(x$fit_status == "converged") -
        count_true(x$pdHess[x$fit_status == "converged"]),
      n_warning_fits = sum(x$fit_warning_count > 0L, na.rm = TRUE),
      n_finite_gradients = sum(gradient_finite),
      finite_gradient_rate_attempted = sum(gradient_finite) / n_attempted,
      median_max_abs_gradient_fixed = median_or_na(x$max_abs_gradient_fixed),
      n_beta0_finite = sum(is.finite(x$beta0_hat)),
      beta0_median_error = median_or_na(beta0_error),
      beta0_median_absolute_error = median_or_na(abs(beta0_error)),
      n_beta_x_finite = sum(is.finite(x$beta_x_hat)),
      beta_x_median_error = median_or_na(beta_x_error),
      beta_x_median_absolute_error = median_or_na(abs(beta_x_error)),
      n_sigma_finite = sum(sigma_finite),
      sigma_median_relative_error = median_or_na(sigma_relative_error),
      sigma_median_absolute_relative_error = median_or_na(abs(sigma_relative_error)),
      n_sigma_near_boundary = sum(sigma_finite & x$sigma_hat < 1e-4),
      sigma_near_boundary_rate_attempted = sum(sigma_finite & x$sigma_hat < 1e-4) / n_attempted,
      mean_fit_elapsed_sec = mean_or_na(x$fit_elapsed_sec),
      stringsAsFactors = FALSE
    )
  })
  out <- do.call(rbind, rows)
  row.names(out) <- NULL
  out[order(out$cell_index, out$estimator), , drop = FALSE]
}

summarize_recovery <- function(raw, output_dir) {
  required <- c(
    "task_id", "fit_id", "base_cell_id", "cell_index", "provider", "M",
    "shape", "replicate_index", "seed", "estimator", "target_role",
    "target_parameter", "truth", "fit_status", "pdHess", "estimate", "error",
    "squared_error"
  )
  missing <- setdiff(required, names(raw))
  if (length(missing)) {
    stop("Recovery raw artifact lacks columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  if (anyDuplicated(paste(raw$fit_id, raw$target_parameter, sep = "::"))) {
    stop("Recovery raw artifact contains duplicate fit-target keys.", call. = FALSE)
  }
  if (!setequal(unique(raw$estimator), c("ML", "REML"))) {
    stop("Recovery raw artifact must contain paired ML and REML estimators.", call. = FALSE)
  }

  groups <- split_rows(raw, c("base_cell_id", "target_role", "estimator"))
  rows <- lapply(groups, function(x) {
    n_attempted <- nrow(x)
    n_fit_error <- sum(x$fit_status == "fit_error")
    n_nonconverged <- sum(x$fit_status == "nonconverged")
    n_converged <- sum(x$fit_status == "converged")
    if (n_attempted != n_fit_error + n_nonconverged + n_converged) {
      stop("Recovery denominator identity failed for ", x$base_cell_id[[1L]], call. = FALSE)
    }
    finite <- is.finite(x$estimate)
    errors <- x$error[finite]
    data.frame(
      base_cell_id = x$base_cell_id[[1L]],
      cell_index = x$cell_index[[1L]],
      provider = x$provider[[1L]],
      M = x$M[[1L]],
      shape = x$shape[[1L]],
      estimator = x$estimator[[1L]],
      target_role = x$target_role[[1L]],
      target_parameter = x$target_parameter[[1L]],
      truth = x$truth[[1L]],
      n_attempted = n_attempted,
      n_fit_error = n_fit_error,
      n_nonconverged = n_nonconverged,
      n_converged = n_converged,
      n_target_finite = sum(finite),
      n_target_missing = n_attempted - sum(finite),
      n_pdHess_true = count_true(x$pdHess[x$fit_status == "converged"]),
      n_pdHess_false = n_converged - count_true(x$pdHess[x$fit_status == "converged"]),
      mean_estimate = mean_or_na(x$estimate),
      median_estimate = median_or_na(x$estimate),
      bias = mean_or_na(errors),
      bias_mcse = mcse_mean(errors),
      median_relative_error = median_or_na(errors / x$truth[finite]),
      median_absolute_relative_error = median_or_na(abs(errors / x$truth[finite])),
      n_near_boundary = sum(finite & x$estimate < 1e-4),
      near_boundary_rate_attempted = sum(finite & x$estimate < 1e-4) / n_attempted,
      rmse = if (any(finite)) sqrt(mean(x$squared_error[finite])) else NA_real_,
      mae = if (any(finite)) mean(abs(errors)) else NA_real_,
      stringsAsFactors = FALSE
    )
  })
  summary <- do.call(rbind, rows)
  row.names(summary) <- NULL
  summary <- summary[order(summary$cell_index, summary$target_role, summary$estimator), , drop = FALSE]
  atomic_write_tsv(summary, file.path(output_dir, "recovery-summary.tsv"))

  ml <- raw[raw$estimator == "ML", , drop = FALSE]
  reml <- raw[raw$estimator == "REML", , drop = FALSE]
  by <- c(
    "task_id", "base_cell_id", "cell_index", "provider", "M", "shape",
    "replicate_index", "seed", "target_role", "target_parameter", "truth"
  )
  paired <- merge(
    ml[, c(by, "estimate", "error", "squared_error", "fit_status"), drop = FALSE],
    reml[, c(by, "estimate", "error", "squared_error", "fit_status"), drop = FALSE],
    by = by,
    suffixes = c("_ml", "_reml"),
    all = TRUE,
    sort = FALSE
  )
  if (nrow(paired) != nrow(ml) || nrow(paired) != nrow(reml)) {
    stop("ML/REML pairing did not preserve one row per task-target.", call. = FALSE)
  }
  paired_groups <- split_rows(paired, c("base_cell_id", "target_role"))
  paired_rows <- lapply(paired_groups, function(x) {
    finite <- is.finite(x$estimate_ml) & is.finite(x$estimate_reml)
    delta <- x$estimate_reml[finite] - x$estimate_ml[finite]
    abs_error_delta <- abs(x$error_reml[finite]) - abs(x$error_ml[finite])
    squared_error_delta <- x$squared_error_reml[finite] - x$squared_error_ml[finite]
    data.frame(
      base_cell_id = x$base_cell_id[[1L]],
      cell_index = x$cell_index[[1L]],
      provider = x$provider[[1L]],
      M = x$M[[1L]],
      shape = x$shape[[1L]],
      target_role = x$target_role[[1L]],
      target_parameter = x$target_parameter[[1L]],
      truth = x$truth[[1L]],
      n_attempted_pairs = nrow(x),
      n_paired_finite = sum(finite),
      mean_ml = mean_or_na(x$estimate_ml[finite]),
      mean_reml = mean_or_na(x$estimate_reml[finite]),
      bias_ml = mean_or_na(x$error_ml[finite]),
      bias_reml = mean_or_na(x$error_reml[finite]),
      rmse_ml = if (any(finite)) sqrt(mean(x$error_ml[finite]^2)) else NA_real_,
      rmse_reml = if (any(finite)) sqrt(mean(x$error_reml[finite]^2)) else NA_real_,
      mean_reml_minus_ml = mean_or_na(delta),
      mean_signed_error_reml_minus_ml = mean_or_na(x$error_reml[finite] - x$error_ml[finite]),
      signed_error_delta_mcse = mcse_mean(x$error_reml[finite] - x$error_ml[finite]),
      n_reml_gt_ml = sum(delta > 0, na.rm = TRUE),
      mean_abs_error_reml_minus_ml = mean_or_na(abs_error_delta),
      absolute_error_delta_mcse = mcse_mean(abs_error_delta),
      mean_squared_error_reml_minus_ml = mean_or_na(squared_error_delta),
      squared_error_delta_mcse = mcse_mean(squared_error_delta),
      stringsAsFactors = FALSE
    )
  })
  paired_summary <- do.call(rbind, paired_rows)
  row.names(paired_summary) <- NULL
  paired_summary <- paired_summary[order(paired_summary$cell_index, paired_summary$target_role), , drop = FALSE]
  atomic_write_tsv(
    paired_summary,
    file.path(output_dir, "recovery-paired-summary.tsv")
  )

  fit_summary <- summarize_fit_groups(raw, "recovery")
  atomic_write_tsv(fit_summary, file.path(output_dir, "recovery-fit-summary.tsv"))
  invisible(list(summary = summary, paired = paired_summary, fits = fit_summary))
}

summarize_profile <- function(raw, output_dir) {
  required <- c(
    "task_id", "fit_id", "base_cell_id", "cell_index", "provider", "M",
    "shape", "replicate_index", "seed", "estimator", "target_role",
    "target_parameter", "truth", "fit_status", "pdHess", "profile_attempted",
    "profile_engine", "profile_conf_status", "profile_boundary", "profile_valid",
    "profile_two_sided_finite", "profile_finite",
    "profile_covered", "truth_below_interval", "truth_above_interval",
    "profile_lower", "profile_upper", "profile_width"
  )
  missing <- setdiff(required, names(raw))
  if (length(missing)) {
    stop("Profile raw artifact lacks columns: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  if (anyDuplicated(paste(raw$fit_id, raw$target_parameter, sep = "::"))) {
    stop("Profile raw artifact contains duplicate fit-target keys.", call. = FALSE)
  }
  if (!identical(unique(raw$estimator), "REML")) {
    stop("Profile raw artifact must contain REML fits only.", call. = FALSE)
  }
  declared_engines <- unique(raw$profile_engine[!is.na(raw$profile_engine)])
  attempted_engines <- unique(raw$profile_engine[raw$profile_attempted %in% TRUE])
  if (length(declared_engines) != 1L || !identical(declared_engines, "endpoint") ||
      length(setdiff(attempted_engines, "endpoint"))) {
    stop("Profile raw artifact must pin every target to the endpoint engine.", call. = FALSE)
  }

  groups <- split_rows(raw, c("base_cell_id", "target_role"))
  rows <- lapply(groups, function(x) {
    n_attempted <- nrow(x)
    n_fit_error <- sum(x$fit_status == "fit_error")
    n_nonconverged <- sum(x$fit_status == "nonconverged")
    n_converged <- sum(x$fit_status == "converged")
    n_profile_attempted <- count_true(x$profile_attempted)
    valid <- x$profile_valid %in% TRUE
    two_sided_finite <- x$profile_two_sided_finite %in% TRUE
    n_profile_valid <- sum(valid)
    n_profile_two_sided_finite <- sum(two_sided_finite)
    n_profile_one_sided_valid <- n_profile_valid - n_profile_two_sided_finite
    n_profile_failed_after_attempt <- n_profile_attempted - n_profile_valid
    n_failed_or_unusable <- n_attempted - n_profile_valid
    n_covered <- count_true(x$profile_covered[valid])
    n_truth_below <- count_true(x$truth_below_interval[valid])
    n_truth_above <- count_true(x$truth_above_interval[valid])

    if (n_attempted != n_fit_error + n_nonconverged + n_converged) {
      stop("Profile fit denominator identity failed for ", x$base_cell_id[[1L]], call. = FALSE)
    }
    if (n_converged != n_profile_attempted) {
      stop("Every converged fit must attempt its profile target for ", x$base_cell_id[[1L]], call. = FALSE)
    }
    if (n_profile_attempted != n_profile_valid + n_profile_failed_after_attempt) {
      stop("Profile attempted/valid/failed identity failed for ", x$base_cell_id[[1L]], call. = FALSE)
    }
    if (n_profile_valid != n_covered + n_truth_below + n_truth_above) {
      stop("Profile covered/lower/upper identity failed for ", x$base_cell_id[[1L]], call. = FALSE)
    }
    if (n_attempted != n_covered + n_truth_below + n_truth_above + n_failed_or_unusable) {
      stop("All-attempt profile outcome identity failed for ", x$base_cell_id[[1L]], call. = FALSE)
    }

    coverage_all_attempted <- n_covered / n_attempted
    coverage_conditional_valid <- if (n_profile_valid) n_covered / n_profile_valid else NA_real_
    exact <- exact_binomial_ci(n_covered, n_attempted)
    lower_miss_rate <- n_truth_below / n_attempted
    upper_miss_rate <- n_truth_above / n_attempted
    data.frame(
      base_cell_id = x$base_cell_id[[1L]],
      cell_index = x$cell_index[[1L]],
      provider = x$provider[[1L]],
      M = x$M[[1L]],
      shape = x$shape[[1L]],
      estimator = "REML",
      target_role = x$target_role[[1L]],
      target_parameter = x$target_parameter[[1L]],
      truth = x$truth[[1L]],
      n_attempted = n_attempted,
      n_fit_error = n_fit_error,
      n_nonconverged = n_nonconverged,
      n_converged = n_converged,
      n_pdHess_true = count_true(x$pdHess[x$fit_status == "converged"]),
      n_pdHess_false = n_converged - count_true(x$pdHess[x$fit_status == "converged"]),
      n_profile_attempted = n_profile_attempted,
      n_profile_valid = n_profile_valid,
      n_profile_two_sided_finite = n_profile_two_sided_finite,
      n_profile_one_sided_valid = n_profile_one_sided_valid,
      n_profile_failed_after_attempt = n_profile_failed_after_attempt,
      n_failed_or_unusable = n_failed_or_unusable,
      profile_valid_rate_attempted = n_profile_valid / n_attempted,
      profile_two_sided_finite_rate_attempted = n_profile_two_sided_finite / n_attempted,
      n_covered = n_covered,
      coverage_all_attempted = coverage_all_attempted,
      coverage_conditional_valid = coverage_conditional_valid,
      coverage_mcse_all_attempted = mcse_proportion(n_covered, n_attempted),
      coverage_exact_ci_low = exact[["low"]],
      coverage_exact_ci_high = exact[["high"]],
      n_truth_below_interval = n_truth_below,
      n_truth_above_interval = n_truth_above,
      lower_miss_rate = lower_miss_rate,
      upper_miss_rate = upper_miss_rate,
      upper_lower_miss_ratio = if (n_truth_below > 0L) n_truth_above / n_truth_below else NA_real_,
      n_boundary_profiles = count_true(x$profile_boundary[valid]),
      mean_two_sided_profile_width = mean_or_na(x$profile_width[two_sided_finite]),
      median_two_sided_profile_width = median_or_na(x$profile_width[two_sided_finite]),
      mean_profile_elapsed_sec = mean_or_na(x$profile_elapsed_sec[x$profile_attempted %in% TRUE]),
      n_profile_warning_targets = sum(x$profile_warning_count > 0L, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  })
  summary <- do.call(rbind, rows)
  row.names(summary) <- NULL
  summary <- summary[order(summary$cell_index, summary$target_role), , drop = FALSE]
  atomic_write_tsv(summary, file.path(output_dir, "profile-summary.tsv"))

  fit_summary <- summarize_fit_groups(raw, "profile")
  atomic_write_tsv(fit_summary, file.path(output_dir, "profile-fit-summary.tsv"))
  invisible(list(summary = summary, fits = fit_summary))
}

write_hash_manifest <- function(phase, output_dir) {
  paths <- c(
    file.path(output_dir, paste0(phase, "-raw.tsv")),
    file.path(output_dir, paste0(phase, "-seed-manifest.tsv")),
    file.path(output_dir, paste0(phase, "-run-manifest.tsv")),
    file.path(output_dir, paste0(phase, "-summary.tsv")),
    file.path(output_dir, paste0(phase, "-fit-summary.tsv"))
  )
  if (identical(phase, "recovery")) {
    paths <- c(paths, file.path(output_dir, "recovery-paired-summary.tsv"))
  }
  paths <- paths[file.exists(paths)]
  hashes <- data.frame(
    file = basename(paths),
    bytes = as.numeric(file.info(paths)$size),
    md5 = unname(tools::md5sum(paths)),
    stringsAsFactors = FALSE
  )
  atomic_write_tsv(hashes, file.path(output_dir, paste0(phase, "-artifact-hashes.tsv")))
  invisible(hashes)
}

summarize_arc1a_phase <- function(phase, output_dir) {
  if (!phase %in% c("recovery", "profile")) {
    stop("`phase` must be `recovery` or `profile`.", call. = FALSE)
  }
  output_dir <- normalizePath(path.expand(output_dir), mustWork = TRUE)
  raw_path <- file.path(output_dir, paste0(phase, "-raw.tsv"))
  if (!file.exists(raw_path)) stop("Raw artifact does not exist: ", raw_path, call. = FALSE)
  raw <- read_tsv(raw_path)
  if (!nrow(raw)) stop("Raw artifact is empty: ", raw_path, call. = FALSE)
  result <- if (identical(phase, "recovery")) {
    summarize_recovery(raw, output_dir)
  } else {
    summarize_profile(raw, output_dir)
  }
  write_hash_manifest(phase, output_dir)
  message(
    "Summarized Arc 1a ", phase, ": ",
    length(unique(raw$fit_id)), " unique fits; ", nrow(raw), " target rows."
  )
  invisible(result)
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  arg_value <- function(name, default = NULL) {
    prefix <- paste0("--", name, "=")
    hit <- grep(paste0("^", prefix), args, value = TRUE)
    if (!length(hit)) return(default)
    sub(prefix, "", hit[[length(hit)]], fixed = TRUE)
  }
  if (any(args %in% c("--help", "-h"))) {
    cat(paste(
      "Usage: Rscript tools/summarize-arc1a-gaussian-reml-provider-campaign.R",
      "  --phase=recovery|profile --output-dir=PATH",
      sep = "\n"
    ), "\n")
    quit(status = 0L)
  }
  cli_phase <- arg_value("phase", NULL)
  cli_output <- arg_value("output-dir", NULL)
  if (is.null(cli_phase) || is.null(cli_output)) {
    stop("Both `--phase` and `--output-dir` are required.", call. = FALSE)
  }
  summarize_arc1a_phase(cli_phase, cli_output)
}
