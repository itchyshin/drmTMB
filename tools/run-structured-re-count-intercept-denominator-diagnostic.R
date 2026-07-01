args <- commandArgs(trailingOnly = TRUE)

parse_args <- function(args) {
  out <- list(
    output_dir = "docs/dev-log/simulation-artifacts/2026-06-29-count-intercept-denominator-diagnostic-local",
    dashboard_output = "docs/dev-log/dashboard/structured-re-count-intercept-denominator-diagnostic.tsv",
    n_rep = 30L,
    seed_start = 2026062911L,
    cores = 2L,
    backend = "multicore",
    overwrite = FALSE,
    near_zero_threshold = 1e-4
  )
  for (arg in args) {
    if (startsWith(arg, "--output_dir=")) {
      out$output_dir <- sub("^--output_dir=", "", arg)
    } else if (startsWith(arg, "--dashboard_output=")) {
      out$dashboard_output <- sub("^--dashboard_output=", "", arg)
    } else if (startsWith(arg, "--n_rep=")) {
      out$n_rep <- as.integer(sub("^--n_rep=", "", arg))
    } else if (startsWith(arg, "--seed_start=")) {
      out$seed_start <- as.integer(sub("^--seed_start=", "", arg))
    } else if (startsWith(arg, "--cores=")) {
      out$cores <- as.integer(sub("^--cores=", "", arg))
    } else if (startsWith(arg, "--backend=")) {
      out$backend <- sub("^--backend=", "", arg)
    } else if (startsWith(arg, "--near_zero_threshold=")) {
      out$near_zero_threshold <- as.numeric(sub(
        "^--near_zero_threshold=",
        "",
        arg
      ))
    } else if (identical(arg, "--overwrite")) {
      out$overwrite <- TRUE
    } else {
      stop("Unknown argument: ", arg, call. = FALSE)
    }
  }
  if (!is.finite(out$n_rep) || out$n_rep < 1L) {
    stop("`--n_rep` must be a positive integer.", call. = FALSE)
  }
  if (!is.finite(out$seed_start) || out$seed_start < 1L) {
    stop("`--seed_start` must be a positive integer.", call. = FALSE)
  }
  if (!is.finite(out$cores) || out$cores < 1L) {
    stop("`--cores` must be a positive integer.", call. = FALSE)
  }
  if (!out$backend %in% c("none", "multicore")) {
    stop("`--backend` must be `none` or `multicore`.", call. = FALSE)
  }
  if (!is.finite(out$near_zero_threshold) || out$near_zero_threshold <= 0) {
    stop("`--near_zero_threshold` must be a positive number.", call. = FALSE)
  }
  out
}

opts <- parse_args(args)
artifact_dir <- normalizePath(opts$output_dir, mustWork = FALSE)
artifact_url <- opts$output_dir
if (dir.exists(artifact_dir) && !isTRUE(opts$overwrite)) {
  stop(
    "Output directory already exists. Use --overwrite to replace it: ",
    artifact_dir,
    call. = FALSE
  )
}
if (dir.exists(artifact_dir) && isTRUE(opts$overwrite)) {
  unlink(artifact_dir, recursive = TRUE, force = TRUE)
}
dir.create(artifact_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(
  file.path(artifact_dir, "tables"),
  recursive = TRUE,
  showWarnings = FALSE
)
dir.create(
  file.path(artifact_dir, "logs"),
  recursive = TRUE,
  showWarnings = FALSE
)

if (
  file.exists("DESCRIPTION") &&
    requireNamespace("devtools", quietly = TRUE)
) {
  devtools::load_all(quiet = TRUE)
} else {
  library(drmTMB)
}

source("inst/sim/run/sim_run_actions_cell.R", local = globalenv())
phase18_actions_source_dependencies("poisson_phylo_q1_formal")
phase18_actions_source_dependencies("nbinom2_phylo_q1_formal")
phase18_actions_source_dependencies("count_structured_q1")

writeLines(
  c(
    "structured RE count-intercept denominator diagnostic",
    paste("output_dir:", artifact_dir),
    paste("dashboard_output:", opts$dashboard_output),
    paste("n_rep:", opts$n_rep),
    paste("seed_start:", opts$seed_start),
    paste("cores:", opts$cores),
    paste("backend:", opts$backend),
    paste("near_zero_threshold:", opts$near_zero_threshold)
  ),
  file.path(artifact_dir, "run-log.txt")
)

poisson_phylo_conditions <- data.frame(
  diagnostic_condition_id = c(
    "phylo_poisson_medium_balanced",
    "phylo_poisson_medium_mildly_uneven",
    "phylo_poisson_large_denominator",
    "phylo_poisson_stronger_signal"
  ),
  n_species = c(40L, 40L, 40L, 40L),
  n_per_species = c(8L, 8L, 12L, 8L),
  sd_phylo = c(0.60, 0.60, 0.60, 0.90),
  mean_count = c(4.0, 4.0, 6.0, 4.0),
  beta_mu_x = c(-0.20, -0.20, -0.20, -0.20),
  tree_shape = c("balanced", "mildly_uneven", "balanced", "balanced"),
  stringsAsFactors = FALSE
)

nbinom2_phylo_conditions <- data.frame(
  diagnostic_condition_id = c(
    "phylo_nbinom2_medium_balanced",
    "phylo_nbinom2_medium_mildly_uneven",
    "phylo_nbinom2_large_denominator",
    "phylo_nbinom2_stronger_signal"
  ),
  n_species = c(40L, 40L, 40L, 40L),
  n_per_species = c(8L, 8L, 12L, 8L),
  sd_phylo = c(0.60, 0.60, 0.60, 0.90),
  mean_count = c(4.0, 4.0, 6.0, 4.0),
  sigma_baseline = c(0.35, 0.35, 0.35, 0.45),
  beta_mu_x = c(-0.20, -0.20, -0.20, -0.20),
  beta_sigma_z = c(0.15, 0.15, 0.15, 0.15),
  tree_shape = c("balanced", "mildly_uneven", "balanced", "balanced"),
  stringsAsFactors = FALSE
)

spatial_nbinom2_conditions <- data.frame(
  diagnostic_condition_id = c(
    "spatial_nbinom2_large_ring",
    "spatial_nbinom2_more_levels",
    "spatial_nbinom2_stronger_signal",
    "spatial_nbinom2_stretched_check"
  ),
  family = rep("nbinom2", 4L),
  structured_type = rep("spatial", 4L),
  n_level = c(16L, 24L, 16L, 24L),
  n_per_level = c(16L, 12L, 16L, 16L),
  sd_structured = c(0.60, 0.60, 0.90, 0.60),
  mean_count = c(5.0, 5.0, 5.0, 6.0),
  sigma_baseline = c(0.35, 0.35, 0.45, 0.35),
  beta_mu_x = c(-0.20, -0.20, -0.20, -0.20),
  beta_sigma_z = c(0.15, 0.15, 0.15, 0.15),
  geometry = c("ring", "ring", "ring", "stretched"),
  matrix_decay = c(0.40, 0.40, 0.40, 0.40),
  stringsAsFactors = FALSE
)

condition_manifest <- function(
  conditions,
  surface,
  qseries_cell_id,
  family,
  provider
) {
  out <- data.frame(
    internal_cell_id = sprintf("%s_%03d", surface, seq_len(nrow(conditions))),
    qseries_cell_id = qseries_cell_id,
    family = family,
    provider = provider,
    conditions,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  out
}

bind_fill <- function(pieces) {
  cols <- unique(unlist(lapply(pieces, names), use.names = FALSE))
  pieces <- lapply(pieces, function(x) {
    missing <- setdiff(cols, names(x))
    for (col in missing) {
      x[[col]] <- NA
    }
    x[cols]
  })
  do.call(rbind, pieces)
}

condition_manifest_rows <- bind_fill(list(
  condition_manifest(
    poisson_phylo_conditions,
    "poisson_phylo_q1",
    "qseries_phylo_poisson_q1_mu_intercept",
    "poisson()",
    "phylo"
  ),
  condition_manifest(
    nbinom2_phylo_conditions,
    "nbinom2_phylo_q1",
    "qseries_phylo_nbinom2_q1_mu_intercept",
    "nbinom2()",
    "phylo"
  ),
  condition_manifest(
    spatial_nbinom2_conditions,
    "count_structured_q1",
    "qseries_spatial_nbinom2_q1_mu_intercept",
    "nbinom2()",
    "spatial"
  )
))

poisson_phylo_out <- phase18_write_poisson_phylo_q1_formal_grid_outputs(
  output_dir = file.path(artifact_dir, "phylo-poisson"),
  conditions = poisson_phylo_conditions,
  n_rep = opts$n_rep,
  master_seed = opts$seed_start,
  overwrite = TRUE,
  profile_parameters = character(),
  condition_shard = 1L,
  condition_shards = 1L,
  full_condition_count = nrow(poisson_phylo_conditions),
  cores = opts$cores,
  backend = opts$backend
)
nbinom2_phylo_out <- phase18_write_nbinom2_phylo_q1_formal_grid_outputs(
  output_dir = file.path(artifact_dir, "phylo-nbinom2"),
  conditions = nbinom2_phylo_conditions,
  n_rep = opts$n_rep,
  master_seed = opts$seed_start + 100000L,
  overwrite = TRUE,
  profile_parameters = character(),
  condition_shard = 1L,
  condition_shards = 1L,
  full_condition_count = nrow(nbinom2_phylo_conditions),
  cores = opts$cores,
  backend = opts$backend
)
spatial_out <- phase18_write_count_structured_q1_grid_outputs(
  output_dir = file.path(artifact_dir, "spatial-nbinom2"),
  conditions = spatial_nbinom2_conditions,
  n_rep = opts$n_rep,
  master_seed = opts$seed_start + 200000L,
  overwrite = TRUE,
  profile_parameters = character(),
  cores = opts$cores,
  backend = opts$backend
)

read_csv <- function(path) {
  utils::read.csv(path, stringsAsFactors = FALSE, check.names = FALSE)
}

poisson_rows <- read_csv(
  poisson_phylo_out$paths$replicate_csv
)
nbinom2_rows <- read_csv(
  nbinom2_phylo_out$paths$replicate_csv
)
spatial_rows <- read_csv(
  spatial_out$paths$replicate_csv
)

target_rows <- bind_fill(list(
  poisson_rows[poisson_rows$parameter_class == "phylo_sd", , drop = FALSE],
  nbinom2_rows[nbinom2_rows$parameter_class == "phylo_sd", , drop = FALSE],
  spatial_rows[spatial_rows$parameter_class == "structured_sd", , drop = FALSE]
))

manifest_by_internal <- split(
  condition_manifest_rows,
  condition_manifest_rows$internal_cell_id
)

fmt_num <- function(x, digits = 6) {
  if (!is.finite(x)) {
    return("NA")
  }
  format(signif(x, digits), scientific = FALSE, trim = TRUE)
}

truthy <- function(x) {
  as.character(x) %in% c("TRUE", "true", "1")
}

condition_label <- function(meta) {
  parts <- c()
  add <- function(label, value) {
    if (
      !is.null(value) &&
        length(value) &&
        !is.na(value) &&
        nzchar(as.character(value))
    ) {
      parts <<- c(parts, paste0(label, "=", value))
    }
  }
  add("condition", meta$diagnostic_condition_id[[1L]])
  add("tree", meta$tree_shape[[1L]])
  add("n_species", meta$n_species[[1L]])
  add("n_per_species", meta$n_per_species[[1L]])
  add("n_level", meta$n_level[[1L]])
  add("n_per_level", meta$n_per_level[[1L]])
  add(
    "sd",
    if ("sd_phylo" %in% names(meta)) {
      meta$sd_phylo[[1L]]
    } else {
      meta$sd_structured[[1L]]
    }
  )
  add("mean_count", meta$mean_count[[1L]])
  add("sigma", meta$sigma_baseline[[1L]])
  add("geometry", meta$geometry[[1L]])
  paste(parts, collapse = "; ")
}

condition_verdict <- function(
  fit_ok,
  n_rep,
  pdhess_false,
  near_zero_rate,
  boundary_warning
) {
  if ((n_rep - fit_ok) / n_rep > 0.02) {
    return("denominator_fit_caveat")
  }
  if (pdhess_false / n_rep > 0.02) {
    return("denominator_pdhess_caveat")
  }
  if (near_zero_rate >= 0.25) {
    return("denominator_near_zero_caveat")
  }
  if (boundary_warning / n_rep > 0.05) {
    return("denominator_boundary_caveat")
  }
  "denominator_cleared_locally"
}

summarise_one_condition <- function(meta) {
  internal <- meta$internal_cell_id[[1L]]
  rows <- target_rows[target_rows$cell_id == internal, , drop = FALSE]
  estimate <- suppressWarnings(as.numeric(rows$estimate))
  truth <- suppressWarnings(as.numeric(rows$truth))
  fit_ok <- sum(truthy(rows$converged), na.rm = TRUE)
  pdhess_false <- sum(!truthy(rows$pdHess), na.rm = TRUE)
  finite_estimate <- sum(is.finite(estimate), na.rm = TRUE)
  near_zero <- sum(
    is.finite(estimate) & abs(estimate) < opts$near_zero_threshold
  )
  boundary_warning <- if ("sd_boundary_status" %in% names(rows)) {
    sum(grepl("warning|boundary", rows$sd_boundary_status), na.rm = TRUE)
  } else if ("diagnostic_status" %in% names(rows)) {
    sum(grepl("warning|error", rows$diagnostic_status), na.rm = TRUE)
  } else {
    0L
  }
  near_zero_rate <- near_zero / opts$n_rep
  true_sd <- unique(truth[is.finite(truth)])
  true_sd <- if (length(true_sd)) true_sd[[1L]] else NA_real_
  bias_sd <- mean(estimate - truth, na.rm = TRUE)
  rmse_sd <- sqrt(mean((estimate - truth)^2, na.rm = TRUE))
  verdict <- condition_verdict(
    fit_ok = fit_ok,
    n_rep = opts$n_rep,
    pdhess_false = pdhess_false,
    near_zero_rate = near_zero_rate,
    boundary_warning = boundary_warning
  )
  data.frame(
    diagnostic_id = paste0(
      "count_intercept_denominator_",
      gsub("[^A-Za-z0-9]+", "_", meta$qseries_cell_id[[1L]]),
      "_",
      gsub("[^A-Za-z0-9]+", "_", meta$diagnostic_condition_id[[1L]])
    ),
    cell_id = meta$qseries_cell_id[[1L]],
    family = meta$family[[1L]],
    provider = meta$provider[[1L]],
    condition_label = condition_label(meta),
    n_rep = opts$n_rep,
    fit_ok = as.integer(fit_ok),
    nonconverged = as.integer(opts$n_rep - fit_ok),
    pdhess_false = as.integer(pdhess_false),
    finite_estimate_rows = as.integer(finite_estimate),
    near_zero_threshold = "1e-04",
    near_zero_estimate_rows = as.integer(near_zero),
    near_zero_estimate_rate = fmt_num(near_zero_rate),
    boundary_warning_rows = as.integer(boundary_warning),
    true_sd = fmt_num(true_sd),
    mean_sd = fmt_num(mean(estimate, na.rm = TRUE)),
    bias_sd = fmt_num(bias_sd),
    rmse_sd = fmt_num(rmse_sd),
    denominator_verdict = verdict,
    evidence_url = artifact_url,
    claim_boundary = paste(
      "Targeted stronger-denominator diagnostic only; failures remain in the",
      "local denominator. This explains whether a recovery caveat is",
      "design-sensitive, but it does NOT promote interval_status,",
      "coverage_status, inference_ready, supported, REML, AI-REML, q2/q4",
      "count covariance, high-q, bridge support, or public support."
    ),
    next_gate = paste(
      "Use this only to choose the next non-Gaussian recovery top-up or",
      "blocker diagnosis; intervals and coverage remain unsupported until a",
      "separate interval route is designed and validated."
    ),
    stringsAsFactors = FALSE
  )
}

diagnostics <- do.call(
  rbind,
  lapply(manifest_by_internal, summarise_one_condition)
)
diagnostics <- diagnostics[
  order(diagnostics$cell_id, diagnostics$condition_label),
  ,
  drop = FALSE
]
rownames(diagnostics) <- NULL

table_dir <- file.path(artifact_dir, "tables")
utils::write.csv(
  target_rows,
  file.path(table_dir, "count-intercept-denominator-diagnostic-replicates.csv"),
  row.names = FALSE
)
utils::write.csv(
  condition_manifest_rows,
  file.path(
    table_dir,
    "count-intercept-denominator-diagnostic-condition-manifest.csv"
  ),
  row.names = FALSE
)
utils::write.csv(
  diagnostics,
  file.path(table_dir, "count-intercept-denominator-diagnostic-summary.csv"),
  row.names = FALSE,
  na = "NA"
)
utils::write.table(
  diagnostics,
  file.path(table_dir, "count-intercept-denominator-diagnostic-summary.tsv"),
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

dashboard_dir <- dirname(opts$dashboard_output)
dir.create(dashboard_dir, recursive = TRUE, showWarnings = FALSE)
utils::write.table(
  diagnostics,
  file = opts$dashboard_output,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE,
  na = "NA"
)

seed_manifest <- data.frame(
  lane = c("phylo_poisson", "phylo_nbinom2", "spatial_nbinom2"),
  seed_start = c(
    opts$seed_start,
    opts$seed_start + 100000L,
    opts$seed_start + 200000L
  ),
  n_rep = opts$n_rep,
  stringsAsFactors = FALSE
)
utils::write.csv(
  seed_manifest,
  file.path(
    table_dir,
    "count-intercept-denominator-diagnostic-seed-manifest.csv"
  ),
  row.names = FALSE
)
writeLines(
  capture.output(sessionInfo()),
  file.path(artifact_dir, "sessionInfo.txt")
)
git_sha <- tryCatch(
  system2("git", c("rev-parse", "HEAD"), stdout = TRUE, stderr = TRUE),
  error = function(e) "git-sha-unavailable"
)
writeLines(git_sha, file.path(artifact_dir, "git-sha.txt"))
module_list <- tryCatch(
  system2("module", "list", stdout = TRUE, stderr = TRUE),
  error = function(e) "local run; environment modules unavailable"
)
writeLines(module_list, file.path(artifact_dir, "module-list.txt"))

cat(
  "wrote",
  nrow(diagnostics),
  "count-intercept denominator diagnostic rows to",
  opts$dashboard_output,
  "\n"
)
