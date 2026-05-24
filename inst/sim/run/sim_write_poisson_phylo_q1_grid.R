phase18_write_poisson_phylo_q1_grid_outputs <- function(
  output_dir,
  conditions = phase18_poisson_phylo_q1_conditions(
    n_species = c(20L, 40L),
    n_per_species = 4L,
    sd_phylo = c(0, 0.25, 0.60),
    mean_count = 2.5,
    tree_shape = "balanced"
  ),
  n_rep = 5L,
  master_seed = 20260524L,
  overwrite = FALSE,
  profile_parameters = character(),
  profile_level = 0.70,
  profile_args = list(ystep = 0.50),
  cores = 1L,
  backend = "none"
) {
  phase18_assert_simple_grid_output_dir(output_dir)
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  dirs <- phase18_prepare_simple_grid_dirs(output_dir)
  paths <- phase18_poisson_phylo_q1_grid_paths(dirs$table_dir)
  phase18_assert_simple_grid_overwrite(
    paths,
    overwrite,
    "Poisson phylogenetic q1 grid"
  )

  summary <- phase18_summarise_poisson_phylo_q1_smoke(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    result_dir = dirs$result_dir,
    overwrite = overwrite,
    profile_parameters = profile_parameters,
    profile_level = profile_level,
    profile_args = profile_args,
    cores = cores,
    backend = backend
  )
  phase18_write_poisson_phylo_q1_grid_tables(summary, paths)

  list(
    surface = "poisson_phylo_q1_grid",
    output_dir = dirs$output_dir,
    result_dir = dirs$result_dir,
    table_dir = dirs$table_dir,
    paths = paths,
    artifact_manifest = phase18_grid_artifact_manifest(
      "poisson_phylo_q1_grid",
      paths
    ),
    summary = summary
  )
}

phase18_poisson_phylo_q1_grid_paths <- function(table_dir) {
  c(
    phase18_simple_grid_paths(table_dir, prefix = "poisson-phylo-q1"),
    list(
      wald_intervals_csv = file.path(
        table_dir,
        "poisson-phylo-q1-wald-intervals.csv"
      ),
      wald_coverage_csv = file.path(
        table_dir,
        "poisson-phylo-q1-wald-coverage.csv"
      ),
      profile_targets_csv = file.path(
        table_dir,
        "poisson-phylo-q1-profile-targets.csv"
      ),
      profile_intervals_csv = file.path(
        table_dir,
        "poisson-phylo-q1-profile-intervals.csv"
      ),
      profile_coverage_csv = file.path(
        table_dir,
        "poisson-phylo-q1-profile-coverage.csv"
      ),
      interval_evidence_csv = file.path(
        table_dir,
        "poisson-phylo-q1-interval-evidence.csv"
      ),
      interval_diagnostics_csv = file.path(
        table_dir,
        "poisson-phylo-q1-interval-diagnostics.csv"
      ),
      interval_failures_csv = file.path(
        table_dir,
        "poisson-phylo-q1-interval-failures.csv"
      )
    )
  )
}

phase18_write_poisson_phylo_q1_grid_tables <- function(summary, paths) {
  phase18_write_simple_grid_tables(summary, paths)
  utils::write.csv(
    summary$wald_intervals,
    paths$wald_intervals_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$wald_coverage,
    paths$wald_coverage_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$profile_targets,
    paths$profile_targets_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$profile_intervals,
    paths$profile_intervals_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$profile_coverage,
    paths$profile_coverage_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$interval_evidence,
    paths$interval_evidence_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$interval_diagnostics,
    paths$interval_diagnostics_csv,
    row.names = FALSE
  )
  utils::write.csv(
    summary$interval_failures,
    paths$interval_failures_csv,
    row.names = FALSE
  )
  invisible(paths)
}

phase18_write_poisson_phylo_q1_formal_grid_outputs <- function(
  output_dir,
  conditions = phase18_poisson_phylo_q1_formal_conditions(),
  n_rep = 500L,
  master_seed = 20260601L,
  overwrite = FALSE,
  profile_parameters = character(),
  profile_level = 0.70,
  profile_args = list(ystep = 0.50),
  condition_shard = 1L,
  condition_shards = 1L,
  full_condition_count = nrow(conditions),
  cores = 1L,
  backend = "none"
) {
  phase18_assert_simple_grid_output_dir(output_dir)
  if (!isTRUE(overwrite) && !identical(overwrite, FALSE)) {
    stop("`overwrite` must be TRUE or FALSE.", call. = FALSE)
  }

  dirs <- phase18_prepare_simple_grid_dirs(output_dir)
  paths <- phase18_poisson_phylo_q1_grid_paths(dirs$table_dir)
  paths$formal_spec_csv <- file.path(
    dirs$table_dir,
    "poisson-phylo-q1-formal-spec.csv"
  )
  phase18_assert_simple_grid_overwrite(
    paths,
    overwrite,
    "Poisson phylogenetic q1 formal grid"
  )

  out <- phase18_write_poisson_phylo_q1_grid_outputs(
    output_dir = dirs$output_dir,
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    overwrite = overwrite,
    profile_parameters = profile_parameters,
    profile_level = profile_level,
    profile_args = profile_args,
    cores = cores,
    backend = backend
  )
  formal_spec <- phase18_poisson_phylo_q1_formal_grid_spec(
    conditions = conditions,
    n_rep = n_rep,
    master_seed = master_seed,
    profile_parameters = profile_parameters,
    profile_level = profile_level,
    condition_shard = condition_shard,
    condition_shards = condition_shards,
    full_condition_count = full_condition_count
  )
  utils::write.csv(formal_spec, paths$formal_spec_csv, row.names = FALSE)

  out$surface <- "poisson_phylo_q1_formal_grid"
  out$paths$formal_spec_csv <- paths$formal_spec_csv
  out$artifact_manifest <- phase18_grid_artifact_manifest(
    "poisson_phylo_q1_formal_grid",
    out$paths
  )
  out$formal_spec <- formal_spec
  out
}

phase18_poisson_phylo_q1_formal_conditions <- function(
  n_species = c(20L, 40L, 80L),
  n_per_species = c(4L, 8L),
  sd_phylo = c(0, 0.25, 0.60),
  mean_count = c(1.5, 3.0, 8.0),
  beta_mu_x = c(0, 0.35),
  tree_shape = c("balanced", "mildly_uneven")
) {
  phase18_poisson_phylo_q1_conditions(
    n_species = n_species,
    n_per_species = n_per_species,
    sd_phylo = sd_phylo,
    mean_count = mean_count,
    beta_mu_x = beta_mu_x,
    tree_shape = tree_shape
  )
}

phase18_poisson_phylo_q1_formal_grid_spec <- function(
  conditions,
  n_rep,
  master_seed,
  profile_parameters = character(),
  profile_level = 0.70,
  condition_shard = 1L,
  condition_shards = 1L,
  full_condition_count = nrow(conditions)
) {
  if (!is.data.frame(conditions) || nrow(conditions) == 0L) {
    stop("`conditions` must be a non-empty data frame.", call. = FALSE)
  }
  assert_positive_whole_number(n_rep, "n_rep")
  assert_positive_whole_number(master_seed, "master_seed")
  if (!is.character(profile_parameters) || any(!nzchar(profile_parameters))) {
    stop("`profile_parameters` must be a character vector.", call. = FALSE)
  }
  if (
    !is.numeric(profile_level) ||
      length(profile_level) != 1L ||
      !is.finite(profile_level) ||
      profile_level <= 0 ||
      profile_level >= 1
  ) {
    stop("`profile_level` must be one number between 0 and 1.", call. = FALSE)
  }
  assert_positive_whole_number(condition_shard, "condition_shard")
  assert_positive_whole_number(condition_shards, "condition_shards")
  assert_positive_whole_number(full_condition_count, "full_condition_count")
  if (condition_shard > condition_shards) {
    stop(
      "`condition_shard` must be less than or equal to `condition_shards`.",
      call. = FALSE
    )
  }
  if (full_condition_count < nrow(conditions)) {
    stop(
      "`full_condition_count` must be at least `nrow(conditions)`.",
      call. = FALSE
    )
  }

  out <- conditions
  out$n_rep <- n_rep
  out$master_seed <- master_seed
  out$target_replicates <- nrow(conditions) * n_rep
  out$formal_recovery_gate <- n_rep >= 500L
  out$profile_parameters <- paste(profile_parameters, collapse = ",")
  out$profile_level <- profile_level
  out$condition_shard <- condition_shard
  out$condition_shards <- condition_shards
  out$full_condition_count <- full_condition_count
  out$shard_condition_count <- nrow(conditions)
  out$shard_recovery_gate <- n_rep >= 500L
  out$mcse_required <- TRUE
  out$coverage_claim_allowed <- n_rep >= 500L && condition_shards == 1L
  out
}

phase18_read_poisson_phylo_q1_grid_outputs <- function(
  output_dir,
  require_complete = FALSE
) {
  phase18_assert_simple_grid_output_dir(output_dir)
  if (!isTRUE(require_complete) && !identical(require_complete, FALSE)) {
    stop("`require_complete` must be TRUE or FALSE.", call. = FALSE)
  }
  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  table_dir <- file.path(output_dir, "tables")
  paths <- phase18_poisson_phylo_q1_grid_paths(table_dir)
  optional_spec <- file.path(table_dir, "poisson-phylo-q1-formal-spec.csv")
  if (file.exists(optional_spec)) {
    paths$formal_spec_csv <- optional_spec
  }
  missing <- names(paths)[!file.exists(unlist(paths, use.names = FALSE))]
  if (require_complete && length(missing) > 0L) {
    stop(
      "Missing Poisson phylogenetic q1 artifacts: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  tables <- lapply(paths, phase18_read_poisson_phylo_q1_csv)
  names(tables) <- names(paths)
  qa <- phase18_qa_poisson_phylo_q1_grid_outputs(tables)
  list(
    surface = "poisson_phylo_q1_grid_read",
    output_dir = output_dir,
    table_dir = table_dir,
    paths = paths,
    tables = tables,
    qa = qa
  )
}

phase18_read_poisson_phylo_q1_csv <- function(path) {
  if (!file.exists(path)) {
    return(data.frame())
  }
  if (is.na(file.info(path)$size) || file.info(path)$size == 0L) {
    return(data.frame())
  }
  tryCatch(
    utils::read.csv(path, stringsAsFactors = FALSE),
    error = function(e) data.frame()
  )
}

phase18_qa_poisson_phylo_q1_grid_outputs <- function(
  tables,
  expected_n_rep = NULL
) {
  if (!is.list(tables)) {
    stop("`tables` must be a list of artifact tables.", call. = FALSE)
  }
  if (!is.null(expected_n_rep)) {
    assert_positive_whole_number(expected_n_rep, "expected_n_rep")
  }

  required <- c(
    "aggregate_csv",
    "replicate_csv",
    "manifest_csv",
    "failures_csv",
    "wald_intervals_csv",
    "wald_coverage_csv",
    "profile_targets_csv",
    "profile_intervals_csv",
    "profile_coverage_csv",
    "interval_evidence_csv",
    "interval_diagnostics_csv",
    "interval_failures_csv"
  )
  present <- required %in% names(tables)
  aggregate <- tables$aggregate_csv
  replicates <- tables$replicate_csv
  manifest <- tables$manifest_csv

  aggregate_cells <- if (
    is.data.frame(aggregate) && "cell_id" %in% names(aggregate)
  ) {
    unique(aggregate$cell_id)
  } else {
    character()
  }
  manifest_cells <- if (
    is.data.frame(manifest) && "cell_id" %in% names(manifest)
  ) {
    unique(manifest$cell_id)
  } else {
    character()
  }
  seed_unique <- is.data.frame(manifest) &&
    "seed" %in% names(manifest) &&
    !anyDuplicated(manifest$seed)
  expected_status <- "not_checked"
  expected_message <- "expected_n_rep not supplied"
  if (!is.null(expected_n_rep) && length(manifest_cells) > 0L) {
    replicate_counts <- table(manifest$cell_id)
    expected_ok <- all(as.integer(replicate_counts) == expected_n_rep)
    expected_status <- ifelse(expected_ok, "ok", "failed")
    expected_message <- paste(
      names(replicate_counts),
      as.integer(replicate_counts),
      sep = "=",
      collapse = ","
    )
  }

  out <- data.frame(
    check = c(
      "artifacts_present",
      "manifest_rows",
      "replicate_rows",
      "seed_unique",
      "cell_alignment",
      "expected_replicates"
    ),
    status = c(
      ifelse(all(present), "ok", "failed"),
      ifelse(is.data.frame(manifest) && nrow(manifest) > 0L, "ok", "failed"),
      ifelse(
        is.data.frame(replicates) && nrow(replicates) > 0L,
        "ok",
        "failed"
      ),
      ifelse(seed_unique, "ok", "failed"),
      ifelse(setequal(aggregate_cells, manifest_cells), "ok", "failed"),
      expected_status
    ),
    n = c(
      sum(present),
      if (is.data.frame(manifest)) nrow(manifest) else 0L,
      if (is.data.frame(replicates)) nrow(replicates) else 0L,
      if (is.data.frame(manifest)) length(unique(manifest$seed)) else 0L,
      length(intersect(aggregate_cells, manifest_cells)),
      if (is.null(expected_n_rep)) NA_integer_ else expected_n_rep
    ),
    message = c(
      paste(setdiff(required, names(tables)), collapse = ","),
      "",
      "",
      "",
      paste(
        "aggregate_only=",
        paste(setdiff(aggregate_cells, manifest_cells), collapse = ","),
        "; manifest_only=",
        paste(setdiff(manifest_cells, aggregate_cells), collapse = ","),
        sep = ""
      ),
      expected_message
    ),
    stringsAsFactors = FALSE
  )
  out$message[out$message == ""] <- NA_character_
  out
}

phase18_poisson_phylo_q1_promotion_decision <- function(
  qa,
  formal_spec = NULL
) {
  if (!is.data.frame(qa) || !all(c("check", "status") %in% names(qa))) {
    stop(
      "`qa` must be a QA data frame with `check` and `status`.",
      call. = FALSE
    )
  }
  blocking <- qa$status == "failed"
  formal_ready <- FALSE
  if (
    is.data.frame(formal_spec) &&
      "coverage_claim_allowed" %in% names(formal_spec)
  ) {
    formal_ready <- all(formal_spec$coverage_claim_allowed)
  }
  if (any(blocking)) {
    decision <- "hold"
    reason <- paste(qa$check[blocking], collapse = ", ")
  } else if (formal_ready) {
    decision <- "promote_narrowly"
    reason <- "formal grid artifacts pass QA and meet the replicate gate"
  } else {
    decision <- "hold_smoke_only"
    reason <- "artifacts pass QA but formal recovery replicate gate is not met"
  }
  data.frame(
    surface = "poisson_phylo_q1",
    decision = decision,
    reason = reason,
    stringsAsFactors = FALSE
  )
}
