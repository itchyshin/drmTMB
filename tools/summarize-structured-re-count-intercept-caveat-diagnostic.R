args <- commandArgs(trailingOnly = TRUE)

parse_args <- function(args) {
  out <- list(
    artifact_dir = "docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-recovery-grid-local",
    output = "docs/dev-log/dashboard/structured-re-count-intercept-caveat-diagnostic.tsv",
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
replicate_path <- file.path(
  opts$artifact_dir,
  "tables",
  "count-intercept-recovery-replicates.csv"
)
if (!file.exists(replicate_path)) {
  stop("Replicate table does not exist: ", replicate_path, call. = FALSE)
}

replicates <- utils::read.csv(
  replicate_path,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

caveat_cells <- c(
  "qseries_phylo_poisson_q1_mu_intercept",
  "qseries_phylo_nbinom2_q1_mu_intercept",
  "qseries_spatial_nbinom2_q1_mu_intercept"
)

replicates <- replicates[
  replicates$cell_id %in%
    caveat_cells &
    replicates$parameter_class %in% c("structured_sd", "phylo_sd"),
  ,
  drop = FALSE
]

if (!nrow(replicates)) {
  stop("No caveat rows found in ", replicate_path, call. = FALSE)
}

as_character <- function(x) {
  out <- as.character(x)
  out[is.na(out)] <- "NA"
  out
}

for (col in c(
  "internal_cell_id",
  "cell_id",
  "family_label",
  "provider",
  "tree_shape",
  "n_species",
  "n_per_species",
  "n_level",
  "n_per_level",
  "sd_structured",
  "mean_count",
  "sigma_baseline",
  "geometry",
  "matrix_decay"
)) {
  if (!col %in% names(replicates)) {
    replicates[[col]] <- "NA"
  }
  replicates[[col]] <- as_character(replicates[[col]])
}

condition_key <- ifelse(
  replicates$internal_cell_id != "NA",
  replicates$internal_cell_id,
  paste(
    replicates$cell_id,
    replicates$n_level,
    replicates$n_per_level,
    replicates$sd_structured,
    replicates$mean_count,
    replicates$sigma_baseline,
    replicates$geometry,
    replicates$matrix_decay,
    sep = "::"
  )
)

split_rows <- split(
  replicates,
  paste(replicates$cell_id, condition_key, sep = "\r")
)

fmt_num <- function(x, digits = 6) {
  if (!is.finite(x)) {
    return("NA")
  }
  format(signif(x, digits), scientific = FALSE, trim = TRUE)
}

condition_label <- function(row) {
  parts <- c()
  add <- function(label, value) {
    if (!is.na(value) && nzchar(value) && value != "NA") {
      parts <<- c(parts, paste0(label, "=", value))
    }
  }
  add("internal", row$internal_cell_id[[1L]])
  add("tree", row$tree_shape[[1L]])
  add("n_species", row$n_species[[1L]])
  add("n_per_species", row$n_per_species[[1L]])
  add("n_level", row$n_level[[1L]])
  add("n_per_level", row$n_per_level[[1L]])
  add("sd", row$sd_structured[[1L]])
  add("mean_count", row$mean_count[[1L]])
  add("sigma", row$sigma_baseline[[1L]])
  add("geometry", row$geometry[[1L]])
  add("decay", row$matrix_decay[[1L]])
  paste(parts, collapse = "; ")
}

summarise_condition <- function(row) {
  estimate <- suppressWarnings(as.numeric(row$estimate))
  truth <- suppressWarnings(as.numeric(row$truth))
  n_rep <- length(estimate)
  near_zero <- sum(abs(estimate) < opts$near_zero_threshold, na.rm = TRUE)
  pdhess_false <- sum(row$pdHess != "TRUE", na.rm = TRUE)
  nonconverged <- sum(row$converged != "TRUE", na.rm = TRUE)
  boundary_warning <- sum(
    grepl("warning", row$sd_boundary_status, fixed = TRUE) |
      grepl("boundary", row$fit_diagnostic_message, fixed = TRUE),
    na.rm = TRUE
  )
  mean_sd <- mean(estimate, na.rm = TRUE)
  true_sd <- unique(truth[is.finite(truth)])
  true_sd <- if (length(true_sd)) true_sd[[1L]] else NA_real_
  bias_sd <- mean(estimate - truth, na.rm = TRUE)
  rmse_sd <- sqrt(mean((estimate - truth)^2, na.rm = TRUE))
  near_zero_rate <- near_zero / n_rep
  pdhess_rate <- pdhess_false / n_rep
  verdict <- if (pdhess_rate > 0.02) {
    "condition_pdhess_caveat"
  } else if (near_zero_rate >= 0.25) {
    "condition_near_zero_caveat"
  } else {
    "condition_recovery_ok"
  }
  data.frame(
    diagnostic_id = paste0(
      "count_intercept_caveat_",
      gsub("[^A-Za-z0-9]+", "_", row$cell_id[[1L]]),
      "_",
      gsub(
        "[^A-Za-z0-9]+",
        "_",
        condition_key[match(rownames(row)[1L], rownames(replicates))]
      )
    ),
    cell_id = row$cell_id[[1L]],
    family = row$family_label[[1L]],
    provider = row$provider[[1L]],
    condition_label = condition_label(row),
    n_rep = as.integer(n_rep),
    fit_ok = as.integer(n_rep - nonconverged),
    nonconverged = as.integer(nonconverged),
    pdhess_false = as.integer(pdhess_false),
    near_zero_threshold = "1e-04",
    near_zero_estimate_rows = as.integer(near_zero),
    near_zero_estimate_rate = fmt_num(near_zero_rate),
    boundary_warning_rows = as.integer(boundary_warning),
    true_sd = fmt_num(true_sd),
    mean_sd = fmt_num(mean_sd),
    bias_sd = fmt_num(bias_sd),
    rmse_sd = fmt_num(rmse_sd),
    diagnostic_verdict = verdict,
    evidence_url = opts$artifact_dir,
    claim_boundary = paste(
      "Condition-level diagnostic only from the 80-rep local count-intercept",
      "recovery grid; it explains recovery caveats but does NOT promote",
      "interval_status, coverage_status, inference_ready, supported, REML,",
      "AI-REML, q2/q4 count covariance, high-q, bridge support, or public support."
    ),
    next_gate = paste(
      "For caveated conditions, rerun a targeted denominator diagnostic with",
      "stronger signal and/or larger count denominators before changing",
      "non-Gaussian recovery wording; intervals and coverage remain unsupported."
    ),
    stringsAsFactors = FALSE
  )
}

diagnostics <- do.call(rbind, lapply(split_rows, summarise_condition))
diagnostics <- diagnostics[
  order(diagnostics$cell_id, diagnostics$condition_label),
  ,
  drop = FALSE
]
rownames(diagnostics) <- NULL

output_dir <- dirname(opts$output)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
utils::write.table(
  diagnostics,
  file = opts$output,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

artifact_tables <- file.path(opts$artifact_dir, "tables")
dir.create(artifact_tables, recursive = TRUE, showWarnings = FALSE)
utils::write.csv(
  diagnostics,
  file = file.path(artifact_tables, "count-intercept-caveat-diagnostic.csv"),
  row.names = FALSE,
  na = "NA"
)

cat(
  "wrote",
  nrow(diagnostics),
  "count-intercept caveat diagnostic rows to",
  opts$output,
  "\n"
)
