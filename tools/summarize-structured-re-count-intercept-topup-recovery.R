args <- commandArgs(trailingOnly = TRUE)

parse_args <- function(args) {
  out <- list(
    artifact_dir = "docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-topup-recovery-local",
    output = "docs/dev-log/dashboard/structured-re-count-intercept-topup-recovery-results.tsv",
    near_zero_threshold = 1e-4
  )
  for (arg in args) {
    if (startsWith(arg, "--artifact_dir=")) {
      out$artifact_dir <- sub("^--artifact_dir=", "", arg)
    } else if (startsWith(arg, "--output=")) {
      out$output <- sub("^--output=", "", arg)
    } else if (startsWith(arg, "--near_zero_threshold=")) {
      out$near_zero_threshold <- as.numeric(sub(
        "^--near_zero_threshold=",
        "",
        arg
      ))
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }
  if (!is.finite(out$near_zero_threshold) || out$near_zero_threshold <= 0) {
    stop("`--near_zero_threshold` must be a positive number.", call. = FALSE)
  }
  out
}

opts <- parse_args(args)
table_dir <- file.path(opts$artifact_dir, "tables")
replicate_path <- file.path(
  table_dir,
  "count-intercept-denominator-diagnostic-replicates.csv"
)
manifest_path <- file.path(
  table_dir,
  "count-intercept-denominator-diagnostic-condition-manifest.csv"
)
for (path in c(replicate_path, manifest_path)) {
  if (!file.exists(path)) {
    stop("Required top-up artifact does not exist: ", path, call. = FALSE)
  }
}

replicates <- utils::read.csv(
  replicate_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)
manifest <- utils::read.csv(
  manifest_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

required_manifest <- c(
  "internal_cell_id",
  "qseries_cell_id",
  "family",
  "provider",
  "diagnostic_condition_id"
)
missing_manifest <- setdiff(required_manifest, names(manifest))
if (length(missing_manifest)) {
  stop(
    "Top-up manifest is missing columns: ",
    paste(missing_manifest, collapse = ", "),
    call. = FALSE
  )
}
required_replicates <- c(
  "cell_id",
  "replicate",
  "truth",
  "estimate",
  "converged",
  "pdHess"
)
missing_replicates <- setdiff(required_replicates, names(replicates))
if (length(missing_replicates)) {
  stop(
    "Top-up replicate table is missing columns: ",
    paste(missing_replicates, collapse = ", "),
    call. = FALSE
  )
}

idx <- match(replicates$cell_id, manifest$internal_cell_id)
if (anyNA(idx)) {
  stop(
    "Top-up replicate table has internal cell ids not present in manifest.",
    call. = FALSE
  )
}
replicates$qseries_cell_id <- manifest$qseries_cell_id[idx]
replicates$qseries_family <- manifest$family[idx]
replicates$provider <- manifest$provider[idx]
replicates$diagnostic_condition_id <- manifest$diagnostic_condition_id[idx]

truthy <- function(x) {
  as.character(x) %in% c("TRUE", "true", "1")
}

fmt_num <- function(x, digits = 6) {
  if (!is.finite(x)) {
    return("NA")
  }
  format(signif(x, digits), scientific = FALSE, trim = TRUE)
}

mcse_mean <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 2L) {
    return(NA_real_)
  }
  stats::sd(x) / sqrt(length(x))
}

rmse_mcse <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 2L) {
    return(NA_real_)
  }
  y <- x^2
  sqrt(stats::var(y) / length(y)) / (2 * sqrt(mean(y)))
}

boundary_warning_count <- function(row) {
  out <- rep(FALSE, nrow(row))
  if ("sd_boundary_status" %in% names(row)) {
    out <- out | grepl("warning|boundary", row$sd_boundary_status)
  }
  if ("diagnostic_status" %in% names(row)) {
    out <- out | grepl("warning|error", row$diagnostic_status)
  }
  if ("fit_diagnostic_status" %in% names(row)) {
    out <- out | grepl("warning|error", row$fit_diagnostic_status)
  }
  sum(out, na.rm = TRUE)
}

topup_verdict <- function(
  n_rows,
  fit_ok,
  pdhess_false,
  finite_estimate,
  near_zero_rate,
  boundary_warning
) {
  if (fit_ok < 0.98 * n_rows) {
    return("topup_recovery_caveat_fit_rate")
  }
  if (pdhess_false > max(1L, floor(0.02 * n_rows))) {
    return("topup_recovery_caveat_pdhess_rate")
  }
  if (finite_estimate != n_rows) {
    return("topup_recovery_caveat_finite_estimate")
  }
  if (near_zero_rate >= 0.25) {
    return("topup_recovery_caveat_near_zero_rate")
  }
  if (boundary_warning / n_rows > 0.05) {
    return("topup_recovery_caveat_boundary_rate")
  }
  "topup_recovery_only_passed"
}

widget_state_for_verdict <- function(verdict) {
  if (identical(verdict, "topup_recovery_only_passed")) {
    return("non_gaussian_recovery_only")
  }
  "non_gaussian_recovery_caveat"
}

summarise_cell <- function(row) {
  estimate <- suppressWarnings(as.numeric(row$estimate))
  truth <- suppressWarnings(as.numeric(row$truth))
  n_rows <- nrow(row)
  fit_ok <- sum(truthy(row$converged), na.rm = TRUE)
  pdhess_false <- sum(!truthy(row$pdHess), na.rm = TRUE)
  finite_estimate <- sum(is.finite(estimate), na.rm = TRUE)
  near_zero <- sum(
    is.finite(estimate) & abs(estimate) < opts$near_zero_threshold
  )
  boundary_warning <- boundary_warning_count(row)
  error <- estimate - truth
  near_zero_rate <- near_zero / n_rows
  verdict <- topup_verdict(
    n_rows = n_rows,
    fit_ok = fit_ok,
    pdhess_false = pdhess_false,
    finite_estimate = finite_estimate,
    near_zero_rate = near_zero_rate,
    boundary_warning = boundary_warning
  )
  data.frame(
    recovery_id = paste0("count_intercept_topup_", row$qseries_cell_id[[1L]]),
    cell_id = row$qseries_cell_id[[1L]],
    family = row$qseries_family[[1L]],
    structured_type = row$provider[[1L]],
    topup_design = "stronger_denominator_80_seed_x_4_conditions",
    n_rep = n_rows,
    n_seed_replicates = length(unique(row$replicate)),
    n_internal_conditions = length(unique(row$cell_id)),
    fit_ok = fit_ok,
    nonconverged = n_rows - fit_ok,
    pdhess_false = pdhess_false,
    finite_estimate_rows = finite_estimate,
    near_zero_threshold = "1e-04",
    near_zero_estimate_rows = near_zero,
    near_zero_estimate_rate = fmt_num(near_zero_rate),
    boundary_warning_rows = boundary_warning,
    true_sd_min = fmt_num(min(truth, na.rm = TRUE)),
    true_sd_max = fmt_num(max(truth, na.rm = TRUE)),
    mean_sd = fmt_num(mean(estimate, na.rm = TRUE)),
    bias_sd = fmt_num(mean(error, na.rm = TRUE)),
    rmse_sd = fmt_num(sqrt(mean(error^2, na.rm = TRUE))),
    bias_mcse = fmt_num(mcse_mean(error)),
    rmse_mcse = fmt_num(rmse_mcse(error)),
    recovery_verdict = verdict,
    widget_state = widget_state_for_verdict(verdict),
    linked_cell_id = row$qseries_cell_id[[1L]],
    linked_coverage_status = "planned",
    evidence_url = opts$artifact_dir,
    claim_boundary = paste(
      "RECOVERY TOP-UP evidence only from a stronger-denominator local grid;",
      "failures remain in the denominator and the result does NOT promote",
      "interval_status, coverage_status, inference_ready, supported, REML,",
      "AI-REML, q2/q4 count covariance, high-q, bridge support, or public",
      "support. The original weak-denominator caveat remains documented in",
      "the caveat sidecars."
    ),
    next_gate = paste(
      "Use this as recovery-only board evidence; run primary-cluster",
      "confirmation before public recovery wording. Intervals and coverage",
      "remain unsupported until a separate interval route is designed and",
      "validated."
    ),
    stringsAsFactors = FALSE
  )
}

pieces <- lapply(split(replicates, replicates$qseries_cell_id), summarise_cell)
summary <- do.call(rbind, pieces)
summary <- summary[
  order(summary$structured_type, summary$family),
  ,
  drop = FALSE
]
rownames(summary) <- NULL

output_dir <- dirname(opts$output)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
utils::write.table(
  summary,
  file = opts$output,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)
utils::write.csv(
  summary,
  file.path(table_dir, "count-intercept-topup-recovery-summary.csv"),
  row.names = FALSE,
  na = "NA"
)
utils::write.table(
  summary,
  file.path(table_dir, "count-intercept-topup-recovery-summary.tsv"),
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

cat(
  "wrote",
  nrow(summary),
  "count-intercept top-up recovery rows to",
  opts$output,
  "\n"
)
