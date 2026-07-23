# Immutable execution contract for the Phase 18 known-V meta-analysis B3
# campaign. These helpers prepare, authenticate, and reduce a campaign; they
# never dispatch Totoro/DRAC work themselves.

phase18_meta_v_b3_source_relpaths <- function() {
  c(
    "sim/R/sim_utils.R", "sim/R/sim_registry.R", "sim/R/sim_runner.R",
    "sim/R/sim_uncertainty.R", "sim/dgp/sim_dgp_meta_v.R",
    "sim/fit/sim_summarise_meta_v.R", "sim/run/sim_run_meta_v_smoke.R",
    "sim/run/sim_summary_meta_v_smoke.R", "sim/run/sim_meta_v_b3_contract.R"
  )
}

phase18_meta_v_b3_source_files <- function() {
  vapply(phase18_meta_v_b3_source_relpaths(), function(path) {
    system.file(path, package = "drmTMB", mustWork = TRUE)
  }, character(1))
}

phase18_meta_v_b3_formal_registry <- function(
  n_rep = 1200L,
  master_seed = 20260528L
) {
  if (!identical(as.integer(n_rep), 1200L)) {
    stop("B3 formal runs require exactly `n_rep = 1200`.", call. = FALSE)
  }
  phase18_cell_registry(
    surface = "meta_v_b3",
    conditions = phase18_meta_v_b3_conditions(),
    n_rep = n_rep,
    master_seed = master_seed
  )
}

phase18_meta_v_b3_smoke_registry <- function() {
  conditions <- data.frame(
    n_study = c(12L, 36L),
    known_v_type = c("vector", "dense"),
    sigma = c(0.10, 0.35),
    sampling_sd = c(0.12, 0.12),
    sampling_rho = c(0, 0.25),
    beta_mu_intercept = c(0.20, 0.20),
    beta_mu_x = c(0.45, 0.45),
    smoke_role = c("boundary_seed4_sentinel", "interior_positive_control"),
    stringsAsFactors = FALSE
  )
  cells <- data.frame(
    cell_id = sprintf("meta_v_b3_smoke_%03d", seq_len(nrow(conditions))),
    surface = "meta_v_b3_smoke",
    conditions,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  seeds <- data.frame(
    cell_id = cells$cell_id,
    cell_index = seq_len(nrow(cells)),
    replicate = 1L,
    seed = c(4L, 20260722L),
    stringsAsFactors = FALSE
  )
  list(cells = cells, seeds = seeds, n_rep = 1L, master_seed = NA_integer_)
}

phase18_meta_v_b3_shards <- function(registry, n_shard = 96L) {
  if (!is.list(registry) || !is.data.frame(registry$seeds)) {
    stop("`registry` must contain a seed data frame.", call. = FALSE)
  }
  assert_positive_whole_number(n_shard, "n_shard")
  n_attempt <- nrow(registry$seeds)
  if (n_attempt %% n_shard != 0L) {
    stop("B3 attempts must divide evenly across deterministic shards.", call. = FALSE)
  }
  per_shard <- n_attempt %/% n_shard
  out <- registry$seeds
  out$attempt_index <- seq_len(n_attempt)
  out$shard_id <- ((out$attempt_index - 1L) %/% per_shard) + 1L
  out
}

phase18_meta_v_b3_source_hashes <- function(source_files) {
  if (!is.character(source_files) || length(source_files) == 0L ||
      any(!file.exists(source_files))) {
    stop("`source_files` must name existing files.", call. = FALSE)
  }
  data.frame(
    path = normalizePath(source_files, mustWork = TRUE),
    md5 = unname(tools::md5sum(source_files)),
    sha256 = vapply(source_files, phase18_meta_v_b3_sha256, character(1)),
    stringsAsFactors = FALSE
  )
}

phase18_meta_v_b3_contract_fingerprint <- function(contract) {
  # Do not hash R serialization: R 4.5 and R 4.6 can reconstruct equivalent
  # objects with different serialized bytes.  The explicit UTF-8 tabular form
  # is the portable, inspectable contract identity used on every host.
  path <- tempfile("meta-v-b3-contract-fingerprint-", fileext = ".txt")
  on.exit(unlink(path), add = TRUE)
  con <- file(path, open = "w", encoding = "UTF-8")
  on.exit(try(close(con), silent = TRUE), add = TRUE)
  scalar <- c(
    campaign_id = contract$campaign_id,
    source_commit = contract$source_commit,
    estimator = contract$estimator,
    interval_call = contract$interval_call,
    primary_denominator = contract$primary_denominator,
    amendment_policy = contract$amendment_policy,
    n_attempt = as.character(contract$n_attempt),
    n_parameter_attempt = as.character(contract$n_parameter_attempt),
    n_shard = as.character(contract$n_shard),
    attempts_per_shard = as.character(contract$attempts_per_shard)
  )
  writeLines(paste(names(scalar), enc2utf8(scalar), sep = "\t"), con, useBytes = TRUE)
  policy <- unlist(contract$host_policy, use.names = TRUE)
  writeLines(
    paste(names(policy), format(policy, scientific = FALSE, trim = TRUE, digits = 17), sep = "\t"),
    con, useBytes = TRUE
  )
  tables <- list(
    source_hashes = contract$source_hashes,
    registry_cells = contract$registry$cells,
    registry_seeds = contract$registry$seeds,
    shards = contract$shards
  )
  for (name in names(tables)) {
    writeLines(paste0("[", name, "]"), con, useBytes = TRUE)
    utils::write.table(
      tables[[name]], file = con, sep = "\t", row.names = FALSE,
      col.names = TRUE, quote = TRUE, na = "", eol = "\n"
    )
  }
  close(con)
  phase18_meta_v_b3_sha256(path)
}

phase18_meta_v_b3_sha256 <- function(path) {
  command <- if (nzchar(Sys.which("shasum"))) "shasum" else Sys.which("sha256sum")
  if (!nzchar(command)) {
    stop("A SHA-256 command (`shasum` or `sha256sum`) is required.", call. = FALSE)
  }
  args <- if (basename(command) == "shasum") c("-a", "256", path) else path
  output <- system2(command, args = args, stdout = TRUE, stderr = TRUE)
  status <- attr(output, "status")
  if (!is.null(status) && status != 0L) {
    stop("Could not compute SHA-256 for `", path, "`.", call. = FALSE)
  }
  strsplit(output[[1L]], "[[:space:]]+")[[1L]][[1L]]
}

phase18_meta_v_b3_runtime_receipt <- function() {
  list(
    host = unname(Sys.info()[["nodename"]]),
    r_version = R.version.string,
    rng_kind = paste(RNGkind(), collapse = ";"),
    blas_threads = Sys.getenv("OPENBLAS_NUM_THREADS", unset = NA_character_),
    omp_threads = Sys.getenv("OMP_NUM_THREADS", unset = NA_character_),
    tmb_version = if (requireNamespace("TMB", quietly = TRUE)) {
      as.character(utils::packageVersion("TMB"))
    } else {
      NA_character_
    },
    metafor_version = if (requireNamespace("metafor", quietly = TRUE)) {
      as.character(utils::packageVersion("metafor"))
    } else {
      NA_character_
    },
    session = utils::capture.output(utils::sessionInfo())
  )
}

phase18_meta_v_b3_host_policy <- function() {
  list(
    totoro_load_one_max = 96,
    smoke_multiplier = 1.25,
    max_projected_shard_seconds = 6 * 60 * 60,
    attempts_per_shard = 175L,
    workers_max = 96L,
    fallback_host = "DRAC"
  )
}

phase18_meta_v_b3_select_host <- function(
  smoke_elapsed_seconds,
  totoro_load_one,
  totoro_available = TRUE,
  policy = phase18_meta_v_b3_host_policy()
) {
  if (!is.numeric(smoke_elapsed_seconds) || length(smoke_elapsed_seconds) == 0L ||
      any(!is.finite(smoke_elapsed_seconds)) || any(smoke_elapsed_seconds <= 0)) {
    stop("`smoke_elapsed_seconds` must contain positive finite timings.", call. = FALSE)
  }
  if (!is.numeric(totoro_load_one) || length(totoro_load_one) != 1L ||
      !is.finite(totoro_load_one) || totoro_load_one < 0) {
    stop("`totoro_load_one` must be one non-negative finite value.", call. = FALSE)
  }
  projected_shard_seconds <- policy$smoke_multiplier * max(smoke_elapsed_seconds) *
    policy$attempts_per_shard
  host <- if (isTRUE(totoro_available) &&
      totoro_load_one < policy$totoro_load_one_max &&
      projected_shard_seconds <= policy$max_projected_shard_seconds) {
    "Totoro"
  } else {
    policy$fallback_host
  }
  list(
    host = host,
    smoke_elapsed_seconds = as.numeric(smoke_elapsed_seconds),
    totoro_load_one = unname(totoro_load_one),
    totoro_available = isTRUE(totoro_available),
    projected_shard_seconds = projected_shard_seconds,
    policy = policy
  )
}

phase18_validate_meta_v_b3_campaign_host_selection <- function(contract, selection) {
  if (!is.list(selection) || !identical(selection$policy, contract$host_policy)) {
    stop("B3 campaign receipt must retain the frozen host policy.", call. = FALSE)
  }
  expected <- phase18_meta_v_b3_select_host(
    smoke_elapsed_seconds = selection$smoke_elapsed_seconds,
    totoro_load_one = selection$totoro_load_one,
    totoro_available = selection$totoro_available,
    policy = contract$host_policy
  )
  if (!identical(selection$host, expected$host) ||
      !isTRUE(all.equal(selection$projected_shard_seconds, expected$projected_shard_seconds))) {
    stop("B3 campaign host selection does not follow the frozen policy.", call. = FALSE)
  }
  invisible(expected)
}

phase18_validate_meta_v_b3_approval_data <- function(contract, receipt, scope) {
  if (!is.list(receipt) || !identical(receipt$campaign_id, contract$campaign_id) ||
      !identical(receipt$contract_fingerprint, phase18_meta_v_b3_contract_fingerprint(contract)) ||
      !identical(receipt$approved_by, "Shinichi Nakagawa") ||
      !identical(receipt$scope, scope) || !identical(receipt$fisher_verdict, "CLEAR") ||
      !identical(receipt$rose_verdict, "CLEAR")) {
    stop("B3 approval receipt does not authorize this frozen contract and scope.", call. = FALSE)
  }
  invisible(receipt)
}

phase18_meta_v_b3_smoke_evidence <- function(contract, output_dir) {
  if (!is.character(output_dir) || length(output_dir) != 1L || !dir.exists(output_dir)) {
    stop("B3 campaign approval requires retained smoke RDS and receipt artifacts.", call. = FALSE)
  }
  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  paths <- c(
    smoke_rds = file.path(output_dir, "meta-v-b3-smoke.rds"),
    receipt_rds = file.path(output_dir, "meta-v-b3-smoke-receipt.rds")
  )
  if (!all(file.exists(paths))) {
    stop("B3 campaign approval requires retained smoke RDS and receipt artifacts.", call. = FALSE)
  }
  smoke <- readRDS(paths[["smoke_rds"]])
  retained_receipt <- readRDS(paths[["receipt_rds"]])
  phase18_validate_meta_v_b3_smoke(smoke)
  if (!identical(smoke$receipt, retained_receipt) ||
      !identical(smoke$receipt$contract_fingerprint, phase18_meta_v_b3_contract_fingerprint(contract)) ||
      !identical(smoke$receipt$source_hashes$sha256, contract$source_hashes$sha256)) {
    stop("B3 campaign approval smoke artifact does not match the frozen contract.", call. = FALSE)
  }
  smoke_approval <- smoke$receipt$approval_receipt
  approval_path <- smoke_approval$path
  if (!file.exists(approval_path)) {
    approval_path <- file.path(output_dir, "meta-v-b3-smoke-approval.rds")
  }
  if (!is.list(smoke_approval) || !file.exists(approval_path) ||
      !identical(phase18_meta_v_b3_sha256(approval_path), smoke_approval$sha256)) {
    stop("B3 campaign approval smoke artifact lacks an authenticated approval receipt.", call. = FALSE)
  }
  phase18_validate_meta_v_b3_approval_data(contract, readRDS(approval_path), "smoke")
  if (!identical(smoke$receipt$host_label, "Totoro")) {
    stop("B3 campaign approval requires smoke timing produced on Totoro.", call. = FALSE)
  }
  timings <- unique(smoke$wald_intervals[c("cell_id", "seed", "elapsed")])
  if (nrow(timings) != 2L || any(!is.finite(timings$elapsed)) || any(timings$elapsed <= 0)) {
    stop("B3 campaign approval smoke artifact must retain two positive elapsed timings.", call. = FALSE)
  }
  list(
    output_dir = output_dir,
    smoke_sha256 = phase18_meta_v_b3_sha256(paths[["smoke_rds"]]),
    receipt_sha256 = phase18_meta_v_b3_sha256(paths[["receipt_rds"]]),
    approval_sha256 = smoke_approval$sha256,
    elapsed_seconds = timings$elapsed
  )
}

phase18_meta_v_b3_contract <- function(
  source_commit,
  source_files = phase18_meta_v_b3_source_files(),
  master_seed = 20260528L,
  n_shard = 96L,
  interval_call = "confint(fit, parm = 'sigma', method = 'wald', level = 0.95)"
) {
  if (!is.character(source_commit) || length(source_commit) != 1L ||
      !nzchar(source_commit)) {
    stop("`source_commit` must be one non-empty commit identifier.", call. = FALSE)
  }
  expected <- basename(phase18_meta_v_b3_source_relpaths())
  if (!setequal(basename(source_files), expected)) {
    stop("`source_files` must contain the complete B3 required-source list.", call. = FALSE)
  }
  registry <- phase18_meta_v_b3_formal_registry(master_seed = master_seed)
  shards <- phase18_meta_v_b3_shards(registry, n_shard = n_shard)
  list(
    campaign_id = "phase18_meta_v_b3",
    source_commit = source_commit,
    source_hashes = phase18_meta_v_b3_source_hashes(source_files),
    runtime = phase18_meta_v_b3_runtime_receipt(),
    estimator = "Gaussian ML; bf(yi ~ x + meta_V(V = V), sigma ~ 1)",
    interval_call = interval_call,
    primary_denominator = "all_scheduled_attempts",
    amendment_policy = paste(
      "A plumbing change creates a new versioned contract; seeds, cells, estimator,",
      "estimand, interval definition, and denominator cannot change after smoke results."
    ),
    host_policy = phase18_meta_v_b3_host_policy(),
    execution_approval_variable = "DRMTMB_META_V_B3_EXECUTION_APPROVED",
    execution_approval_value = "yes",
    approval_receipt_variable = "DRMTMB_META_V_B3_APPROVAL_RECEIPT",
    registry = registry,
    shards = shards,
    n_attempt = nrow(registry$seeds),
    n_parameter_attempt = 3L * nrow(registry$seeds),
    n_shard = n_shard,
    attempts_per_shard = nrow(registry$seeds) %/% n_shard
  )
}

phase18_write_meta_v_b3_approval_receipt <- function(
  contract,
  path,
  approved_by,
  scope = c("smoke", "campaign"),
  smoke_output_dir = NULL,
  totoro_load_one = NULL,
  totoro_available = TRUE,
  fisher_verdict = "CLEAR",
  rose_verdict = "CLEAR"
) {
  if (!is.list(contract) || !identical(contract$campaign_id, "phase18_meta_v_b3")) {
    stop("`contract` must be a meta_V B3 contract.", call. = FALSE)
  }
  if (!identical(approved_by, "Shinichi Nakagawa")) {
    stop("B3 approval receipt must name Shinichi Nakagawa.", call. = FALSE)
  }
  if (!identical(fisher_verdict, "CLEAR") || !identical(rose_verdict, "CLEAR")) {
    stop("B3 approval receipt requires CLEAR Fisher and Rose verdicts.", call. = FALSE)
  }
  scope <- match.arg(scope)
  if (identical(scope, "campaign")) {
    smoke_evidence <- phase18_meta_v_b3_smoke_evidence(contract, smoke_output_dir)
    host_selection <- phase18_meta_v_b3_select_host(
      smoke_elapsed_seconds = smoke_evidence$elapsed_seconds,
      totoro_load_one = totoro_load_one,
      totoro_available = totoro_available,
      policy = contract$host_policy
    )
    phase18_validate_meta_v_b3_campaign_host_selection(contract, host_selection)
  } else if (!is.null(smoke_output_dir) || !is.null(totoro_load_one) || !isTRUE(totoro_available)) {
    stop("B3 smoke approval must not preselect a campaign host.", call. = FALSE)
  } else {
    smoke_evidence <- NULL
    host_selection <- NULL
  }
  saveRDS(list(
    campaign_id = contract$campaign_id,
    contract_fingerprint = phase18_meta_v_b3_contract_fingerprint(contract),
    approved_by = approved_by,
    approved_at_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
    scope = scope,
    host_selection = host_selection,
    smoke_evidence = smoke_evidence,
    fisher_verdict = fisher_verdict,
    rose_verdict = rose_verdict
  ), path)
  invisible(normalizePath(path, mustWork = TRUE))
}

phase18_assert_meta_v_b3_execution_approved <- function(
  contract,
  scope = c("smoke", "campaign")
) {
  variable <- contract$execution_approval_variable
  required <- contract$execution_approval_value
  if (!identical(Sys.getenv(variable, unset = ""), required)) {
    stop(
      "B3 execution requires explicit maintainer approval via ", variable,
      "=", required, ".", call. = FALSE
    )
  }
  if (!identical(Sys.getenv("OPENBLAS_NUM_THREADS", unset = ""), "1")) {
    stop("B3 execution requires OPENBLAS_NUM_THREADS=1.", call. = FALSE)
  }
  phase18_meta_v_b3_approval_receipt(contract, scope = match.arg(scope))
}

phase18_meta_v_b3_approval_receipt <- function(
  contract,
  scope = c("smoke", "campaign")
) {
  scope <- match.arg(scope)
  path <- Sys.getenv(contract$approval_receipt_variable, unset = "")
  if (!nzchar(path) || !file.exists(path)) {
    stop("B3 execution requires a pre-existing approval receipt.", call. = FALSE)
  }
  receipt <- readRDS(path)
  phase18_validate_meta_v_b3_approval_data(contract, receipt, scope)
  if (identical(scope, "campaign")) {
    phase18_validate_meta_v_b3_campaign_host_selection(contract, receipt$host_selection)
    smoke_evidence <- phase18_meta_v_b3_smoke_evidence(contract, receipt$smoke_evidence$output_dir)
    if (!identical(receipt$smoke_evidence, smoke_evidence)) {
      stop("B3 campaign approval is not bound to the retained smoke artifact.", call. = FALSE)
    }
  }
  list(
    path = normalizePath(path, mustWork = TRUE),
    sha256 = phase18_meta_v_b3_sha256(path),
    receipt = receipt
  )
}

phase18_validate_meta_v_b3_source <- function(
  contract,
  source_files = phase18_meta_v_b3_source_files()
) {
  if (!is.list(contract) || !identical(contract$campaign_id, "phase18_meta_v_b3")) {
    stop("`contract` must be a meta_V B3 contract.", call. = FALSE)
  }
  observed <- phase18_meta_v_b3_source_hashes(source_files)
  expected <- contract$source_hashes
  key <- basename(expected$path)
  observed_key <- basename(observed$path)
  if (!setequal(key, observed_key) ||
      !identical(unname(expected$sha256[match(key, key)]),
                 unname(observed$sha256[match(key, observed_key)]))) {
    stop("Installed B3 source hashes do not match the frozen contract.", call. = FALSE)
  }
  invisible(observed)
}

phase18_write_meta_v_b3_contract <- function(contract, output_dir, overwrite = FALSE) {
  if (!is.list(contract) || !identical(contract$campaign_id, "phase18_meta_v_b3")) {
    stop("`contract` must be a meta_V B3 contract.", call. = FALSE)
  }
  if (!is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)) {
    stop("`output_dir` must be one non-empty path string.", call. = FALSE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  paths <- c(
    contract_rds = file.path(output_dir, "meta-v-b3-contract.rds"),
    conditions_csv = file.path(output_dir, "meta-v-b3-conditions.csv"),
    seeds_csv = file.path(output_dir, "meta-v-b3-seeds.csv"),
    shards_csv = file.path(output_dir, "meta-v-b3-shards.csv"),
    source_hashes_csv = file.path(output_dir, "meta-v-b3-source-hashes.csv")
  )
  existing <- paths[file.exists(paths)]
  if (!isTRUE(overwrite) && length(existing) > 0L) {
    stop("B3 contract output already exists: ", paste(existing, collapse = ", "), call. = FALSE)
  }
  utils::write.csv(contract$registry$cells, paths[["conditions_csv"]], row.names = FALSE)
  utils::write.csv(contract$registry$seeds, paths[["seeds_csv"]], row.names = FALSE)
  utils::write.csv(contract$shards, paths[["shards_csv"]], row.names = FALSE)
  utils::write.csv(contract$source_hashes, paths[["source_hashes_csv"]], row.names = FALSE)
  contract$artifact_hashes <- phase18_meta_v_b3_source_hashes(
    unname(paths[names(paths) != "contract_rds"])
  )
  saveRDS(contract, paths[["contract_rds"]])
  invisible(paths)
}

phase18_meta_v_b3_shard_seeds <- function(contract, shard_id) {
  if (!is.list(contract) || !identical(contract$campaign_id, "phase18_meta_v_b3")) {
    stop("`contract` must be a meta_V B3 contract.", call. = FALSE)
  }
  assert_positive_whole_number(shard_id, "shard_id")
  out <- contract$shards[contract$shards$shard_id == shard_id, , drop = FALSE]
  if (nrow(out) != contract$attempts_per_shard) {
    stop("`shard_id` must select one complete B3 shard.", call. = FALSE)
  }
  out[c("cell_id", "cell_index", "replicate", "seed")]
}

phase18_run_meta_v_b3_shard <- function(
  contract,
  shard_id,
  result_dir,
  overwrite = FALSE
) {
  phase18_validate_meta_v_b3_source(contract)
  approval <- phase18_assert_meta_v_b3_execution_approved(contract, scope = "campaign")
  host_label <- Sys.getenv("DRMTMB_META_V_B3_HOST_LABEL", unset = "")
  if (!identical(host_label, approval$receipt$host_selection$host)) {
    stop("B3 shard host label does not match the campaign approval.", call. = FALSE)
  }
  seeds <- phase18_meta_v_b3_shard_seeds(contract, shard_id)
  dir.create(result_dir, recursive = TRUE, showWarnings = FALSE)
  receipt_path <- file.path(result_dir, sprintf("b3-shard-%03d-receipt.rds", shard_id))
  if (file.exists(receipt_path) && !overwrite) {
    stop("B3 shard receipt already exists: ", receipt_path, call. = FALSE)
  }
  saveRDS(list(
    campaign_id = contract$campaign_id,
    source_commit = contract$source_commit,
    contract_fingerprint = phase18_meta_v_b3_contract_fingerprint(contract),
    shard_id = shard_id,
    source_hashes = phase18_meta_v_b3_source_hashes(phase18_meta_v_b3_source_files()),
    runtime = phase18_meta_v_b3_runtime_receipt(),
    approval_receipt = approval,
    host_label = host_label,
    worker_policy = "one R worker; OPENBLAS_NUM_THREADS=1 required by launcher"
  ), receipt_path)
  phase18_run_replicates(
    cells = contract$registry$cells,
    seeds = seeds,
    dgp_fun = phase18_dgp_meta_v_cell,
    fit_fun = phase18_fit_meta_v,
    summarise_fun = phase18_summarise_meta_v_fit,
    result_dir = result_dir,
    overwrite = overwrite,
    cores = 1L,
    backend = "none"
  )
}

phase18_meta_v_b3_summarise_results <- function(results, cells) {
  successful_summary <- phase18_result_summaries(results)
  replicates <- phase18_meta_v_all_attempt_summary(results, cells, successful_summary)
  intervals <- phase18_add_wald_intervals(
    replicates,
    interval_scale = ifelse(replicates$parameter == "sigma", "public", "formula_coefficient")
  )
  sigma_rows <- intervals$parameter == "sigma"
  for (name in c("conf.low", "conf.high", "interval_method", "interval_status", "conf.status", "interval_message")) {
    intervals[[name]][sigma_rows] <- replicates[[name]][sigma_rows]
  }
  intervals <- phase18_meta_v_classify_attempts(intervals)
  list(
    replicates = replicates,
    wald_intervals = intervals,
    manifest = phase18_meta_v_attempt_manifest(
      intervals, raw_manifest = phase18_result_manifest(results)
    ),
    failures = phase18_result_failures(results),
    finite_and_covering_rate_all_attempt = phase18_meta_v_all_attempt_coverage(
      intervals, by = c("cell_id", "parameter")
    ),
    conditional_finite_interval_coverage = phase18_meta_v_conditional_finite_coverage(
      intervals, by = c("cell_id", "parameter")
    )
  )
}

phase18_run_meta_v_b3_smoke <- function(contract, result_dir = NULL, overwrite = FALSE) {
  phase18_validate_meta_v_b3_source(contract)
  approval <- phase18_assert_meta_v_b3_execution_approved(contract, scope = "smoke")
  host_label <- Sys.getenv("DRMTMB_META_V_B3_HOST_LABEL", unset = "")
  if (!identical(host_label, "Totoro")) {
    stop("B3 smoke timing must be explicitly labelled Totoro.", call. = FALSE)
  }
  registry <- phase18_meta_v_b3_smoke_registry()
  results <- phase18_run_replicates(
    cells = registry$cells, seeds = registry$seeds,
    dgp_fun = phase18_dgp_meta_v_cell, fit_fun = phase18_fit_meta_v,
    summarise_fun = phase18_summarise_meta_v_fit, result_dir = result_dir,
    overwrite = overwrite, cores = 1L, backend = "none"
  )
  out <- c(list(
    registry = registry, results = results,
    receipt = list(
      campaign_id = contract$campaign_id,
      contract_fingerprint = phase18_meta_v_b3_contract_fingerprint(contract),
      source_hashes = phase18_meta_v_b3_source_hashes(phase18_meta_v_b3_source_files()),
      runtime = phase18_meta_v_b3_runtime_receipt(),
      host_label = host_label,
      approval_receipt = approval
    )
  ),
           phase18_meta_v_b3_summarise_results(results, registry$cells))
  phase18_validate_meta_v_b3_smoke(out)
  out
}

phase18_write_meta_v_b3_smoke_outputs <- function(smoke, output_dir, overwrite = FALSE) {
  phase18_validate_meta_v_b3_smoke(smoke)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  paths <- c(
    smoke_rds = file.path(output_dir, "meta-v-b3-smoke.rds"),
    receipt_rds = file.path(output_dir, "meta-v-b3-smoke-receipt.rds"),
    manifest_csv = file.path(output_dir, "meta-v-b3-smoke-manifest.csv"),
    intervals_csv = file.path(output_dir, "meta-v-b3-smoke-wald-intervals.csv"),
    primary_coverage_csv = file.path(output_dir, "meta-v-b3-smoke-primary-coverage.csv"),
    conditional_coverage_csv = file.path(output_dir, "meta-v-b3-smoke-conditional-coverage.csv"),
    approval_rds = file.path(output_dir, "meta-v-b3-smoke-approval.rds")
  )
  if (!isTRUE(overwrite) && any(file.exists(paths))) {
    stop("B3 smoke output already exists.", call. = FALSE)
  }
  saveRDS(smoke, paths[["smoke_rds"]])
  saveRDS(smoke$receipt, paths[["receipt_rds"]])
  if (!file.copy(smoke$receipt$approval_receipt$path, paths[["approval_rds"]], overwrite = overwrite)) {
    stop("Could not retain the B3 smoke approval receipt beside the smoke artifact.", call. = FALSE)
  }
  utils::write.csv(smoke$manifest, paths[["manifest_csv"]], row.names = FALSE)
  utils::write.csv(smoke$wald_intervals, paths[["intervals_csv"]], row.names = FALSE)
  utils::write.csv(smoke$finite_and_covering_rate_all_attempt, paths[["primary_coverage_csv"]], row.names = FALSE)
  utils::write.csv(smoke$conditional_finite_interval_coverage, paths[["conditional_coverage_csv"]], row.names = FALSE)
  invisible(paths)
}

phase18_reduce_meta_v_b3 <- function(contract, result_dir, output_dir, overwrite = FALSE) {
  phase18_validate_meta_v_b3_source(contract)
  phase18_validate_meta_v_b3_shard_receipts(contract, result_dir)
  results <- phase18_read_result_dir(result_dir, pattern = "replicate_[0-9]+[.]rds$")
  summary <- phase18_meta_v_b3_summarise_results(results, contract$registry$cells)
  phase18_validate_meta_v_b3_completion(summary$manifest, summary$wald_intervals, contract)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  paths <- c(
    summary_rds = file.path(output_dir, "meta-v-b3-summary.rds"),
    manifest_csv = file.path(output_dir, "meta-v-b3-manifest.csv"),
    replicates_csv = file.path(output_dir, "meta-v-b3-replicates.csv"),
    intervals_csv = file.path(output_dir, "meta-v-b3-wald-intervals.csv"),
    failures_csv = file.path(output_dir, "meta-v-b3-failures.csv"),
    primary_coverage_csv = file.path(output_dir, "meta-v-b3-primary-coverage.csv"),
    conditional_coverage_csv = file.path(output_dir, "meta-v-b3-conditional-coverage.csv")
  )
  if (!isTRUE(overwrite) && any(file.exists(paths))) {
    stop("B3 reduced output already exists.", call. = FALSE)
  }
  saveRDS(summary, paths[["summary_rds"]])
  utils::write.csv(summary$manifest, paths[["manifest_csv"]], row.names = FALSE)
  utils::write.csv(summary$replicates, paths[["replicates_csv"]], row.names = FALSE)
  utils::write.csv(summary$wald_intervals, paths[["intervals_csv"]], row.names = FALSE)
  utils::write.csv(summary$failures, paths[["failures_csv"]], row.names = FALSE)
  utils::write.csv(summary$finite_and_covering_rate_all_attempt, paths[["primary_coverage_csv"]], row.names = FALSE)
  utils::write.csv(summary$conditional_finite_interval_coverage, paths[["conditional_coverage_csv"]], row.names = FALSE)
  invisible(paths)
}

phase18_validate_meta_v_b3_shard_receipts <- function(contract, result_dir) {
  approval <- phase18_meta_v_b3_approval_receipt(contract, scope = "campaign")
  paths <- sort(list.files(
    result_dir, pattern = "^b3-shard-[0-9]{3}-receipt[.]rds$",
    full.names = TRUE
  ))
  if (length(paths) != contract$n_shard) {
    stop("B3 reduction requires one retained receipt per shard.", call. = FALSE)
  }
  receipts <- lapply(paths, readRDS)
  shard_ids <- vapply(receipts, `[[`, integer(1), "shard_id")
  if (!identical(sort(shard_ids), seq_len(contract$n_shard))) {
    stop("B3 shard receipts must cover each shard exactly once.", call. = FALSE)
  }
  expected_source <- contract$source_hashes$sha256
  fingerprint <- phase18_meta_v_b3_contract_fingerprint(contract)
  valid <- vapply(receipts, function(receipt) {
    is.list(receipt) && identical(receipt$campaign_id, contract$campaign_id) &&
      identical(receipt$contract_fingerprint, fingerprint) &&
      identical(receipt$approval_receipt$sha256, approval$sha256) &&
      identical(receipt$source_hashes$sha256, expected_source) &&
      identical(receipt$host_label, approval$receipt$host_selection$host) &&
      is.list(receipt$runtime) && nzchar(receipt$runtime$host)
  }, logical(1))
  if (!all(valid)) {
    stop("B3 shard receipt provenance does not match the frozen contract.", call. = FALSE)
  }
  invisible(paths)
}

phase18_validate_meta_v_b3_smoke <- function(smoke) {
  if (!is.list(smoke) || !is.data.frame(smoke$manifest) ||
      !is.data.frame(smoke$wald_intervals) ||
      !is.data.frame(smoke$finite_and_covering_rate_all_attempt) ||
      !is.data.frame(smoke$conditional_finite_interval_coverage) ||
      !is.list(smoke$receipt)) {
    stop("`smoke` must contain B3 manifest, interval, and coverage tables.", call. = FALSE)
  }
  if (!identical(smoke$receipt$campaign_id, "phase18_meta_v_b3") ||
      is.null(smoke$receipt$source_hashes) || is.null(smoke$receipt$runtime) ||
      is.null(smoke$receipt$approval_receipt$sha256)) {
    stop("B3 smoke must retain source, runtime, and approval provenance.", call. = FALSE)
  }
  if (nrow(smoke$manifest) != 2L || nrow(smoke$wald_intervals) != 6L) {
    stop("B3 smoke must retain exactly two attempts and six parameter rows.", call. = FALSE)
  }
  boundary <- smoke$wald_intervals[
    smoke$wald_intervals$cell_id == "meta_v_b3_smoke_001" &
      smoke$wald_intervals$parameter == "sigma", , drop = FALSE
  ]
  interior <- smoke$wald_intervals[
    smoke$wald_intervals$cell_id == "meta_v_b3_smoke_002" &
      smoke$wald_intervals$parameter == "sigma", , drop = FALSE
  ]
  if (nrow(boundary) != 1L || boundary$seed[[1L]] != 4L ||
      !identical(boundary$interval_status[[1L]], "degenerate_zero_infinite") ||
      !identical(boundary$attempt_status[[1L]], "degenerate_interval") ||
      isTRUE(boundary$finite_interval[[1L]]) || boundary$conf.low[[1L]] != 0 ||
      !is.infinite(boundary$conf.high[[1L]])) {
    stop("B3 smoke boundary sentinel did not retain the required degenerate interval.", call. = FALSE)
  }
  if (nrow(interior) != 1L || !isTRUE(interior$converged[[1L]]) ||
      !isTRUE(interior$pdHess[[1L]]) || !isTRUE(interior$finite_interval[[1L]])) {
    stop("B3 smoke interior control did not yield a finite accepted interval.", call. = FALSE)
  }
  boundary_manifest <- smoke$manifest[smoke$manifest$cell_id == "meta_v_b3_smoke_001", , drop = FALSE]
  primary <- smoke$finite_and_covering_rate_all_attempt[
    smoke$finite_and_covering_rate_all_attempt$cell_id == "meta_v_b3_smoke_001" &
      smoke$finite_and_covering_rate_all_attempt$parameter == "sigma", , drop = FALSE
  ]
  conditional <- smoke$conditional_finite_interval_coverage[
    smoke$conditional_finite_interval_coverage$cell_id == "meta_v_b3_smoke_001" &
      smoke$conditional_finite_interval_coverage$parameter == "sigma", , drop = FALSE
  ]
  if (nrow(boundary_manifest) != 1L ||
      !identical(as.integer(boundary_manifest$n_interval_degenerate[[1L]]), 1L) ||
      nrow(primary) != 1L ||
      !identical(as.numeric(primary$finite_and_covering_interval_rate_all_attempt[[1L]]), 0) ||
      nrow(conditional) != 1L ||
      !isTRUE(is.na(conditional$conditional_finite_interval_set_coverage[[1L]]))) {
    stop("B3 smoke boundary accounting did not retain the degenerate interval honestly.", call. = FALSE)
  }
  TRUE
}

phase18_validate_meta_v_b3_completion <- function(manifest, replicates, contract) {
  if (!is.list(contract) || !identical(contract$campaign_id, "phase18_meta_v_b3")) {
    stop("`contract` must be a meta_V B3 contract.", call. = FALSE)
  }
  required_manifest <- c(
    "cell_id", "replicate", "seed", "status", "n_parameter_attempt",
    "n_fit_error", "n_nonconverged", "n_pdHess_false", "n_interval_degenerate"
    , "n_nonfinite_estimate", "n_interval_failed"
  )
  required_replicates <- c(
    "cell_id", "replicate", "seed", "parameter", "result_status", "converged",
    "pdHess", "attempt_status", "interval_status", "conf.low", "conf.high"
  )
  phase18_assert_summary_columns(manifest, required_manifest)
  phase18_assert_summary_columns(replicates, required_replicates)
  expected <- contract$registry$seeds
  expected_key <- paste(expected$cell_id, expected$replicate, expected$seed, sep = "\r")
  observed_key <- paste(manifest$cell_id, manifest$replicate, manifest$seed, sep = "\r")
  if (anyDuplicated(observed_key) || !setequal(expected_key, observed_key)) {
    stop("B3 manifest must contain each and only each scheduled attempt.", call. = FALSE)
  }
  if (nrow(replicates) != contract$n_parameter_attempt ||
      anyDuplicated(paste(replicates$cell_id, replicates$replicate, replicates$seed,
                          replicates$parameter, sep = "\r"))) {
    stop("B3 replicate table must contain one unique row per scheduled parameter.", call. = FALSE)
  }
  expected_parameter_key <- paste(
    rep(expected$cell_id, each = 3L), rep(expected$replicate, each = 3L),
    rep(expected$seed, each = 3L), rep(c("mu:(Intercept)", "mu:x", "sigma"), nrow(expected)),
    sep = "\r"
  )
  observed_parameter_key <- paste(
    replicates$cell_id, replicates$replicate, replicates$seed,
    replicates$parameter, sep = "\r"
  )
  if (!setequal(expected_parameter_key, observed_parameter_key)) {
    stop("B3 replicate table must match the scheduled parameter map.", call. = FALSE)
  }
  expected_manifest <- phase18_meta_v_attempt_manifest(replicates)
  manifest_key <- paste(manifest$cell_id, manifest$replicate, manifest$seed, sep = "\r")
  expected_manifest_key <- paste(expected_manifest$cell_id, expected_manifest$replicate,
                                 expected_manifest$seed, sep = "\r")
  ordered <- match(expected_manifest_key, manifest_key)
  for (name in c("status", "n_parameter_attempt", "n_fit_error", "n_nonconverged",
                 "n_pdHess_false", "n_interval_degenerate", "n_nonfinite_estimate",
                 "n_interval_failed")) {
    if (!identical(unname(manifest[[name]][ordered]), unname(expected_manifest[[name]]))) {
      stop("B3 manifest status counts must match retained parameter rows.", call. = FALSE)
    }
  }
  TRUE
}
