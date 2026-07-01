args <- commandArgs(trailingOnly = TRUE)

parse_args <- function(args) {
  out <- list(
    artifact_dir = "docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-recovery-rorqual/results/count-intercept-recovery-rorqual/artifacts",
    output = "docs/dev-log/dashboard/structured-re-count-intercept-cluster-recovery-results.tsv",
    evidence_url = "docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-recovery-rorqual",
    cluster_job_id = "unknown",
    expected_rows = 10L
  )
  for (arg in args) {
    if (startsWith(arg, "--artifact_dir=")) {
      out$artifact_dir <- sub("^--artifact_dir=", "", arg)
    } else if (startsWith(arg, "--output=")) {
      out$output <- sub("^--output=", "", arg)
    } else if (startsWith(arg, "--evidence_url=")) {
      out$evidence_url <- sub("^--evidence_url=", "", arg)
    } else if (startsWith(arg, "--cluster_job_id=")) {
      out$cluster_job_id <- sub("^--cluster_job_id=", "", arg)
    } else if (startsWith(arg, "--expected_rows=")) {
      out$expected_rows <- as.integer(sub("^--expected_rows=", "", arg))
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }
  if (!is.finite(out$expected_rows) || out$expected_rows < 1L) {
    stop("`--expected_rows` must be a positive integer.", call. = FALSE)
  }
  out
}

opts <- parse_args(args)

expected_cells <- c(
  "qseries_animal_nbinom2_q1_mu_intercept",
  "qseries_animal_poisson_q1_mu_intercept",
  "qseries_phylo_nbinom2_q1_mu_intercept",
  "qseries_phylo_poisson_q1_mu_intercept",
  "qseries_phylo_interaction_nbinom2_q1_mu",
  "qseries_phylo_interaction_poisson_q1_mu",
  "qseries_relmat_nbinom2_q1_mu_intercept",
  "qseries_relmat_poisson_q1_mu_intercept",
  "qseries_spatial_nbinom2_q1_mu_intercept",
  "qseries_spatial_poisson_q1_mu_intercept"
)

summary_path <- file.path(
  opts$artifact_dir,
  "tables",
  "count-intercept-recovery-summary.tsv"
)
if (!file.exists(summary_path)) {
  stop(
    "Count-intercept recovery summary not found: ",
    summary_path,
    call. = FALSE
  )
}

summary <- utils::read.delim(
  summary_path,
  sep = "\t",
  quote = "",
  check.names = FALSE,
  stringsAsFactors = FALSE
)

required_fields <- c(
  "recovery_id",
  "cell_id",
  "family",
  "structured_type",
  "n_rep",
  "n_seed_replicates",
  "n_internal_conditions",
  "fit_ok",
  "nonconverged",
  "pdhess_false",
  "finite_estimate_rows",
  "near_zero_threshold",
  "near_zero_estimate_rows",
  "near_zero_estimate_rate",
  "boundary_warning_rows",
  "true_sd",
  "mean_sd",
  "bias_sd",
  "rmse_sd",
  "bias_mcse",
  "rmse_mcse",
  "recovery_verdict",
  "widget_state",
  "linked_cell_id",
  "linked_coverage_status"
)
missing_fields <- setdiff(required_fields, names(summary))
if (length(missing_fields)) {
  stop(
    "Count-intercept recovery summary missing fields: ",
    paste(missing_fields, collapse = ", "),
    call. = FALSE
  )
}
summary <- summary[summary$cell_id %in% expected_cells, , drop = FALSE]
summary <- summary[match(expected_cells, summary$cell_id), , drop = FALSE]
if (anyNA(summary$cell_id)) {
  stop(
    "Count-intercept recovery summary does not cover the ten expected cells.",
    call. = FALSE
  )
}
if (nrow(summary) != opts$expected_rows) {
  stop(
    "Expected ",
    opts$expected_rows,
    " rows; saw ",
    nrow(summary),
    call. = FALSE
  )
}
if (any(summary$cell_id != summary$linked_cell_id)) {
  stop("cell_id and linked_cell_id must match.", call. = FALSE)
}

cluster_grade <- function(verdict) {
  if (identical(verdict, "recovery_only_passed")) {
    return("cluster_confirmed_recovery_only")
  }
  if (startsWith(verdict, "recovery_caveat")) {
    return("cluster_recovery_caveat")
  }
  "cluster_recovery_blocked"
}

widget_state <- function(verdict) {
  if (identical(verdict, "recovery_only_passed")) {
    return("non_gaussian_recovery_only")
  }
  if (startsWith(verdict, "recovery_caveat")) {
    return("non_gaussian_recovery_caveat")
  }
  "non_gaussian_recovery_blocked"
}

fmt_int <- function(x) {
  as.integer(as.character(x))
}

summary$cluster_design <- "rorqual_80_seed_count_intercept_recovery_grid"
summary$recovery_id <- paste0(
  "count_intercept_cluster_",
  summary$cell_id
)
summary$recovery_grade <- vapply(
  summary$recovery_verdict,
  cluster_grade,
  character(1)
)
summary$widget_state <- vapply(
  summary$recovery_verdict,
  widget_state,
  character(1)
)
summary$evidence_url <- opts$evidence_url
summary$claim_boundary <- paste(
  "CLUSTER RECOVERY evidence only from Rorqual SLURM job",
  opts$cluster_job_id,
  "for one non-Gaussian count q1 mu recovery row; this does NOT promote",
  "interval_status, coverage_status, inference_ready, supported, REML,",
  "AI-REML, q2/q4 count covariance, high-q, bridge support, public support,",
  "structured count sigma, zero-inflation, labelled/multiple count slopes,",
  "count scale routes, or non-Gaussian intervals. Original-grid caveats",
  "remain visible here and may be superseded only by a separate",
  "stronger-denominator top-up sidecar."
)
summary$next_gate <- paste(
  "Use as recovery-only board evidence. Let the stronger-denominator top-up",
  "sidecar supersede original-grid caveats where available; otherwise design",
  "a count-specific interval route before any interval, coverage,",
  "inference_ready, or supported claim."
)

integer_fields <- c(
  "n_rep",
  "n_seed_replicates",
  "n_internal_conditions",
  "fit_ok",
  "nonconverged",
  "pdhess_false",
  "finite_estimate_rows",
  "near_zero_estimate_rows",
  "boundary_warning_rows"
)
for (field in integer_fields) {
  summary[[field]] <- fmt_int(summary[[field]])
}

output_fields <- c(
  "recovery_id",
  "cell_id",
  "family",
  "structured_type",
  "cluster_design",
  "n_rep",
  "n_seed_replicates",
  "n_internal_conditions",
  "fit_ok",
  "nonconverged",
  "pdhess_false",
  "finite_estimate_rows",
  "near_zero_threshold",
  "near_zero_estimate_rows",
  "near_zero_estimate_rate",
  "boundary_warning_rows",
  "true_sd",
  "mean_sd",
  "bias_sd",
  "rmse_sd",
  "bias_mcse",
  "rmse_mcse",
  "recovery_verdict",
  "recovery_grade",
  "widget_state",
  "linked_cell_id",
  "linked_coverage_status",
  "evidence_url",
  "claim_boundary",
  "next_gate"
)

summary <- summary[output_fields]
summary <- summary[
  order(summary$structured_type, summary$family, summary$cell_id),
  ,
  drop = FALSE
]
rownames(summary) <- NULL

dir.create(dirname(opts$output), recursive = TRUE, showWarnings = FALSE)
utils::write.table(
  summary,
  file = opts$output,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

cat(
  "wrote",
  nrow(summary),
  "count-intercept cluster recovery rows to",
  opts$output,
  "\n"
)
