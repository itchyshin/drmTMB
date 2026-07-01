args <- commandArgs(trailingOnly = TRUE)

parse_args <- function(args) {
  out <- list(
    artifact_dir = "docs/dev-log/simulation-artifacts/2026-06-29-count-slope-recovery-rorqual",
    output = "docs/dev-log/dashboard/structured-re-count-slope-cluster-recovery-results.tsv",
    evidence_url = NA_character_,
    cluster_job_id = NA_character_,
    expected_rows = 8L
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
  if (is.na(out$evidence_url) || !nzchar(out$evidence_url)) {
    out$evidence_url <- out$artifact_dir
  }
  out
}

opts <- parse_args(args)

read_tsv <- function(path) {
  utils::read.delim(
    path,
    stringsAsFactors = FALSE,
    check.names = FALSE,
    na.strings = c("NA", "")
  )
}

write_tsv <- function(x, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  utils::write.table(
    x,
    path,
    sep = "\t",
    quote = FALSE,
    row.names = FALSE,
    na = "NA"
  )
}

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

rmse <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) {
    return(NA_real_)
  }
  sqrt(mean(x^2))
}

rmse_mcse <- function(x) {
  x <- x[is.finite(x)]
  if (length(x) < 2L) {
    return(NA_real_)
  }
  squared <- x^2
  sqrt(stats::var(squared) / length(squared)) / (2 * sqrt(mean(squared)))
}

cluster_verdict <- function(n_rows, fit_ok, pdhess_false, finite_estimates) {
  if (fit_ok < 0.98 * n_rows) {
    return("cluster_recovery_caveat_fit_rate")
  }
  if (pdhess_false > max(1L, floor(0.02 * n_rows))) {
    return("cluster_recovery_caveat_pdhess_rate")
  }
  if (finite_estimates != n_rows) {
    return("cluster_recovery_caveat_finite_estimate")
  }
  "cluster_confirmed_recovery_only_passed"
}

widget_state_for_verdict <- function(verdict) {
  if (identical(verdict, "cluster_confirmed_recovery_only_passed")) {
    return("non_gaussian_recovery_only")
  }
  "non_gaussian_recovery_caveat"
}

recovery_grade_for_verdict <- function(verdict) {
  if (identical(verdict, "cluster_confirmed_recovery_only_passed")) {
    return("cluster_confirmed_recovery_only")
  }
  "cluster_recovery_caveat"
}

replicate_paths <- list.files(
  opts$artifact_dir,
  pattern = "^structured-re-count-slope-.*-local-micro-shard-replicates[.]tsv$",
  recursive = TRUE,
  full.names = TRUE
)
if (!length(replicate_paths)) {
  stop(
    "No count-slope micro-shard replicate TSVs found under: ",
    opts$artifact_dir,
    call. = FALSE
  )
}

summarise_artifact <- function(replicate_path) {
  artifact_dir <- dirname(replicate_path)
  replicate_file <- basename(replicate_path)
  summary_file <- sub("-replicates[.]tsv$", "-summary.tsv", replicate_file)
  summary_path <- file.path(artifact_dir, summary_file)
  if (!file.exists(summary_path)) {
    stop("Missing matching summary TSV: ", summary_path, call. = FALSE)
  }

  summary <- read_tsv(summary_path)
  replicates <- read_tsv(replicate_path)
  if (nrow(summary) != 1L) {
    stop("Expected one summary row in: ", summary_path, call. = FALSE)
  }

  required_summary <- c("cell_id", "family", "structured_type")
  missing_summary <- setdiff(required_summary, names(summary))
  if (length(missing_summary)) {
    stop(
      "Summary TSV is missing columns: ",
      paste(missing_summary, collapse = ", "),
      call. = FALSE
    )
  }

  required_replicates <- c(
    "attempt_status",
    "convergence",
    "pdHess",
    "sd_mu_intercept",
    "sd_mu_x",
    "truth_sd_mu_intercept",
    "truth_sd_mu_x"
  )
  missing_replicates <- setdiff(required_replicates, names(replicates))
  if (length(missing_replicates)) {
    stop(
      "Replicate TSV is missing columns: ",
      paste(missing_replicates, collapse = ", "),
      call. = FALSE
    )
  }

  sd_mu_intercept <- suppressWarnings(as.numeric(replicates$sd_mu_intercept))
  sd_mu_x <- suppressWarnings(as.numeric(replicates$sd_mu_x))
  truth_sd_mu_intercept <- suppressWarnings(
    as.numeric(replicates$truth_sd_mu_intercept)
  )
  truth_sd_mu_x <- suppressWarnings(as.numeric(replicates$truth_sd_mu_x))
  err_sd_mu_intercept <- sd_mu_intercept - truth_sd_mu_intercept
  err_sd_mu_x <- sd_mu_x - truth_sd_mu_x
  n_rows <- nrow(replicates)
  fit_ok <- sum(replicates$attempt_status == "fit_ok", na.rm = TRUE)
  nonconverged <- sum(
    replicates$attempt_status == "fit_ok" &
      suppressWarnings(as.integer(replicates$convergence)) != 0L,
    na.rm = TRUE
  )
  pdhess_false <- sum(!truthy(replicates$pdHess), na.rm = TRUE)
  finite_estimates <- sum(
    is.finite(sd_mu_intercept) & is.finite(sd_mu_x),
    na.rm = TRUE
  )
  verdict <- cluster_verdict(
    n_rows = n_rows,
    fit_ok = fit_ok,
    pdhess_false = pdhess_false,
    finite_estimates = finite_estimates
  )
  job_phrase <- if (
    is.na(opts$cluster_job_id) || !nzchar(opts$cluster_job_id)
  ) {
    "the recorded Rorqual SLURM array"
  } else {
    paste("Rorqual SLURM array", opts$cluster_job_id)
  }

  data.frame(
    recovery_id = paste0(
      "count_slope_cluster_",
      summary$cell_id[[1L]]
    ),
    cell_id = summary$cell_id[[1L]],
    family = summary$family[[1L]],
    structured_type = summary$structured_type[[1L]],
    cluster_design = "rorqual_80_seed_provider_family_micro_shard",
    n_rep = n_rows,
    fit_ok = fit_ok,
    fit_error = sum(replicates$attempt_status != "fit_ok", na.rm = TRUE),
    nonconverged = nonconverged,
    pdhess_false = pdhess_false,
    finite_estimate_rows = finite_estimates,
    true_sd_mu_x = fmt_num(mean(truth_sd_mu_x, na.rm = TRUE)),
    mean_sd_mu_x = fmt_num(mean(sd_mu_x, na.rm = TRUE)),
    bias_sd_mu_x = fmt_num(mean(err_sd_mu_x, na.rm = TRUE)),
    rmse_sd_mu_x = fmt_num(rmse(err_sd_mu_x)),
    bias_mcse_sd_mu_x = fmt_num(mcse_mean(err_sd_mu_x)),
    rmse_mcse_sd_mu_x = fmt_num(rmse_mcse(err_sd_mu_x)),
    true_sd_mu_intercept = fmt_num(mean(truth_sd_mu_intercept, na.rm = TRUE)),
    mean_sd_mu_intercept = fmt_num(mean(sd_mu_intercept, na.rm = TRUE)),
    bias_sd_mu_intercept = fmt_num(mean(err_sd_mu_intercept, na.rm = TRUE)),
    rmse_sd_mu_intercept = fmt_num(rmse(err_sd_mu_intercept)),
    bias_mcse_sd_mu_intercept = fmt_num(mcse_mean(err_sd_mu_intercept)),
    rmse_mcse_sd_mu_intercept = fmt_num(rmse_mcse(err_sd_mu_intercept)),
    recovery_verdict = verdict,
    recovery_grade = recovery_grade_for_verdict(verdict),
    widget_state = widget_state_for_verdict(verdict),
    linked_cell_id = summary$cell_id[[1L]],
    linked_coverage_status = "planned",
    evidence_url = opts$evidence_url,
    claim_boundary = paste(
      "CLUSTER RECOVERY evidence only from",
      job_phrase,
      "for one non-Gaussian count q1 mu one-slope row;",
      "this does NOT promote interval_status, coverage_status,",
      "inference_ready, supported, REML, AI-REML, q2/q4 count covariance,",
      "high-q, bridge support, public support, structured count sigma,",
      "zero-inflation, or labelled/multiple count slopes."
    ),
    next_gate = paste(
      "Use as recovery-only board evidence. Design a count-specific",
      "interval route before any interval, coverage, inference_ready,",
      "or supported claim."
    ),
    stringsAsFactors = FALSE
  )
}

summary_rows <- do.call(rbind, lapply(replicate_paths, summarise_artifact))
summary_rows <- summary_rows[
  order(summary_rows$structured_type, summary_rows$family),
  ,
  drop = FALSE
]
rownames(summary_rows) <- NULL

if (nrow(summary_rows) != opts$expected_rows) {
  stop(
    "Expected ",
    opts$expected_rows,
    " cluster recovery rows but found ",
    nrow(summary_rows),
    ".",
    call. = FALSE
  )
}

write_tsv(summary_rows, opts$output)
cat(
  "wrote",
  nrow(summary_rows),
  "count-slope cluster recovery rows to",
  opts$output,
  "\n"
)
