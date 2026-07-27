# Lane-B interval-campaign readiness helpers.
#
# These helpers deliberately prepare no executable coverage roster.  They make
# the frozen model-surface census, target taxonomy, seed schedule, and
# all-attempt reducer reproducible while requiring every exact DGP/profile
# binding to be supplied before a pregrid can be requested.

phase18_lane_b_expected_cell_id_md5 <- "2db50a43be1a5416e10c9e61a334757e"
phase18_lane_b_expected_target_cell_id_md5 <- "b52b28635fde70db0fac72002d4d97de"

phase18_interval_campaign_manifest <- function(cells_path) {
  if (!is.character(cells_path) || length(cells_path) != 1L ||
      !file.exists(cells_path)) {
    stop("`cells_path` must name an existing capability-ledger cells TSV.", call. = FALSE)
  }

  cells <- utils::read.delim(
    cells_path,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  required <- c(
    "cell_id", "source_order", "axis", "family_route", "dpar",
    "effect_type", "structure_provider", "dimension", "q_gate", "route_variant",
    "estimator", "capability_status", "evidence_tier", "primary_evidence_id", "notes"
  )
  missing <- setdiff(required, names(cells))
  if (length(missing) > 0L) {
    stop("Capability ledger is missing: ", paste(missing, collapse = ", "), ".", call. = FALSE)
  }

  eligible <- cells[
    cells$axis == "model_surface" &
      cells$capability_status == "implemented" &
      cells$evidence_tier == "point_fit_recovery",
    required,
    drop = FALSE
  ]
  eligible <- eligible[order(eligible$source_order, eligible$cell_id), , drop = FALSE]
  rownames(eligible) <- NULL

  phase18_assert_interval_campaign_census(eligible, cells)
  attr(eligible, "source_md5") <- unname(tools::md5sum(cells_path))
  attr(eligible, "manifest_md5") <- phase18_interval_campaign_hash(eligible)
  eligible
}

phase18_assert_interval_campaign_census <- function(manifest, cells = NULL) {
  if (!is.data.frame(manifest)) {
    stop("`manifest` must be a data frame.", call. = FALSE)
  }
  if (nrow(manifest) != 159L) {
    stop("Lane-B campaign census must contain exactly 159 candidates.", call. = FALSE)
  }
  if (sum(manifest$source_order <= 676L) != 158L) {
    stop("Lane-B campaign census must retain exactly 158 original candidates.", call. = FALSE)
  }
  insert <- manifest[manifest$cell_id == "mc-0260m", , drop = FALSE]
  if (nrow(insert) != 1L || insert$source_order[[1L]] != 694L) {
    stop("Lane-B campaign census must contain only the approved mc-0260m insert.", call. = FALSE)
  }
  if (any(manifest$axis != "model_surface")) {
    stop("Lane-B campaign manifest may contain model-surface rows only.", call. = FALSE)
  }
  if (anyDuplicated(manifest$cell_id) ||
      !identical(phase18_interval_campaign_cell_id_hash(manifest), phase18_lane_b_expected_cell_id_md5)) {
    stop("Lane-B campaign census cell IDs differ from the approved frozen cohort.", call. = FALSE)
  }
  if (!is.null(cells) && sum(cells$axis == "missing_response") != 18L) {
    stop("Expected exactly 18 foreign missing-response rows.", call. = FALSE)
  }
  invisible(manifest)
}

phase18_interval_campaign_cell_id_hash <- function(manifest) {
  path <- tempfile("lane-b-interval-cell-ids-", fileext = ".txt")
  on.exit(unlink(path), add = TRUE)
  writeLines(sort(manifest$cell_id), path)
  unname(tools::md5sum(path))
}

phase18_interval_campaign_hash <- function(manifest) {
  path <- tempfile("lane-b-interval-manifest-", fileext = ".tsv")
  on.exit(unlink(path), add = TRUE)
  utils::write.table(
    manifest,
    file = path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = ""
  )
  unname(tools::md5sum(path))
}

phase18_interval_campaign_contracts <- function(manifest) {
  phase18_assert_interval_campaign_census(manifest)
  out <- manifest
  out$estimand_stratum <- vapply(seq_len(nrow(out)), function(i) {
    row <- out[i, , drop = FALSE]
    phase18_interval_campaign_stratum(row)
  }, character(1))
  out$negative_control <- out$q_gate == "q12"
  out$lane_b_target <- out$dpar != "rho12"
  out$contract_status <- ifelse(
    !out$lane_b_target,
    "excluded_foreign_association",
    "needs_exact_dgp_binding"
  )
  out$exclusion_reason <- ifelse(
    out$lane_b_target,
    NA_character_,
    "Association target is outside the Lane-B sd()/interval campaign."
  )
  out$dgp_id <- NA_character_
  out$formula <- NA_character_
  out$true_parameter_scale <- NA_character_
  out$profile_parameter <- NA_character_
  out$information_rung <- NA_character_
  out$profile_channel <- NA_character_
  out$binding_evidence_id <- out$primary_evidence_id
  out
}

phase18_interval_campaign_stratum <- function(row) {
  if (row$dpar[[1L]] == "rho12") {
    return("excluded_foreign_association")
  }
  if (row$effect_type[[1L]] == "fixed") {
    return("fixed_coefficient")
  }
  if (row$effect_type[[1L]] == "ordinary_re_intercept") {
    return("ordinary_re_sd_intercept")
  }
  if (row$effect_type[[1L]] == "ordinary_re_slope") {
    return("ordinary_re_sd_slope")
  }
  if (row$effect_type[[1L]] == "structured") {
    return(paste(
      "structured_candidate", row$structure_provider[[1L]], "component_unbound", row$q_gate[[1L]],
      sep = ":"
    ))
  }
  paste("unclassified", row$effect_type[[1L]], sep = ":")
}

phase18_bind_interval_campaign_contracts <- function(contracts, bindings) {
  phase18_assert_interval_campaign_census(contracts)
  if (!is.data.frame(bindings)) {
    stop("`bindings` must be a data frame.", call. = FALSE)
  }
  required <- c(
    "cell_id", "target_id", "dgp_id", "formula", "true_parameter_scale",
    "profile_parameter", "information_rung"
  )
  missing <- setdiff(required, names(bindings))
  if (length(missing) > 0L) {
    stop("`bindings` is missing: ", paste(missing, collapse = ", "), ".", call. = FALSE)
  }
  binding_key <- paste(bindings$cell_id, bindings$target_id, sep = "\r")
  if (anyDuplicated(binding_key)) {
    stop("`bindings` must contain no duplicate cell/target pairs.", call. = FALSE)
  }
  required_ids <- contracts$cell_id[contracts$lane_b_target]
  if (!all(bindings$cell_id %in% required_ids) ||
      !setequal(unique(bindings$cell_id), required_ids)) {
    stop("`bindings` must cover every and only Lane-B target candidate at least once.", call. = FALSE)
  }
  bindings <- bindings[order(match(bindings$cell_id, required_ids), bindings$target_id), required, drop = FALSE]
  incomplete <- vapply(bindings[required[-1L]], function(x) {
    any(is.na(x) | !nzchar(x))
  }, logical(1))
  if (any(incomplete)) {
    stop(
      "Exact bindings must supply non-empty ",
      paste(names(incomplete)[incomplete], collapse = ", "), ".",
      call. = FALSE
    )
  }

  base <- contracts[match(bindings$cell_id, contracts$cell_id), , drop = FALSE]
  rownames(base) <- NULL
  for (field in required[-1L]) {
    base[[field]] <- bindings[[field]]
  }
  base$profile_channel <- "profile_likelihood"
  base$contract_status <- ifelse(
    base$negative_control,
    "negative_control_bound",
    "bound"
  )
  if (any(!startsWith(base$target_id, paste0(base$cell_id, "::")))) {
    stop("Every target ID must be namespaced by its cell ID.", call. = FALSE)
  }
  attr(base, "source_md5") <- attr(contracts, "source_md5")
  attr(base, "manifest_md5") <- attr(contracts, "manifest_md5")
  attr(base, "contract_md5") <- phase18_interval_campaign_hash(base)
  base
}

phase18_interval_campaign_binding_worklist <- function(contracts, evidence_path) {
  phase18_assert_interval_campaign_census(contracts)
  if (!is.character(evidence_path) || length(evidence_path) != 1L || !file.exists(evidence_path)) {
    stop("`evidence_path` must name an existing capability-ledger evidence TSV.", call. = FALSE)
  }
  evidence <- utils::read.delim(
    evidence_path,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  required <- c("evidence_id", "path_or_url")
  missing <- setdiff(required, names(evidence))
  if (length(missing) > 0L) {
    stop("Evidence ledger is missing: ", paste(missing, collapse = ", "), ".", call. = FALSE)
  }
  active <- contracts[contracts$lane_b_target, , drop = FALSE]
  index <- match(active$primary_evidence_id, evidence$evidence_id)
  if (anyNA(index)) {
    stop("Every Lane-B binding candidate must have a primary evidence record.", call. = FALSE)
  }
  formula_hint <- rep(NA_character_, nrow(active))
  has_hint <- !is.na(active$notes) & grepl("formula:", active$notes, fixed = TRUE)
  formula_hint[has_hint] <- sub(
    ".*formula:[[:space:]]*([^;]+).*",
    "\\1",
    active$notes[has_hint]
  )
  formula_hint[has_hint & !nzchar(formula_hint)] <- NA_character_
  target_id <- if ("target_id" %in% names(active)) active$target_id else rep(NA_character_, nrow(active))
  data.frame(
    cell_id = active$cell_id,
    target_id = target_id,
    estimand_stratum = active$estimand_stratum,
    negative_control = active$negative_control,
    primary_evidence_id = active$primary_evidence_id,
    primary_evidence_path = evidence$path_or_url[index],
    formula_hint = formula_hint,
    required_dgp_id = is.na(active$dgp_id),
    required_formula = is.na(active$formula),
    required_true_parameter_scale = is.na(active$true_parameter_scale),
    required_profile_parameter = is.na(active$profile_parameter),
    required_information_rung = is.na(active$information_rung),
    stringsAsFactors = FALSE
  )
}

phase18_interval_campaign_runtime_receipt <- function(source_sha, source_root) {
  if (!is.character(source_sha) || length(source_sha) != 1L ||
      !grepl("^[0-9a-f]{7,40}$", source_sha)) {
    stop("`source_sha` must be a Git SHA with 7 to 40 lowercase hexadecimal characters.", call. = FALSE)
  }
  if (!is.character(source_root) || length(source_root) != 1L || !dir.exists(source_root)) {
    stop("`source_root` must name an existing Git checkout.", call. = FALSE)
  }
  observed_sha <- trimws(system2("git", c("-C", source_root, "rev-parse", "HEAD"), stdout = TRUE))
  if (!identical(source_sha, observed_sha)) {
    stop("`source_sha` must match the checked-out Git HEAD.", call. = FALSE)
  }
  dlls <- getLoadedDLLs()
  drm_dll <- if ("drmTMB" %in% names(dlls)) dlls[["drmTMB"]][["path"]] else NA_character_
  list(
    source_sha = source_sha,
    R = R.version.string,
    drmTMB = as.character(utils::packageVersion("drmTMB")),
    TMB = as.character(utils::packageVersion("TMB")),
    drmTMB_dll = drm_dll,
    drmTMB_dll_md5 = if (!is.na(drm_dll) && file.exists(drm_dll)) unname(tools::md5sum(drm_dll)) else NA_character_,
    git_status_porcelain = system2("git", c("-C", source_root, "status", "--porcelain"), stdout = TRUE),
    session = utils::sessionInfo()
  )
}

phase18_write_interval_campaign_readiness_packet <- function(
  contracts,
  evidence_path,
  output_dir,
  source_sha,
  source_root = getwd()
) {
  phase18_assert_interval_campaign_census(contracts)
  if (!is.character(output_dir) || length(output_dir) != 1L || !nzchar(output_dir)) {
    stop("`output_dir` must be one non-empty path.", call. = FALSE)
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  manifest_fields <- c(
    "cell_id", "source_order", "axis", "family_route", "dpar", "effect_type",
    "structure_provider", "dimension", "q_gate", "route_variant", "estimator",
    "primary_evidence_id"
  )
  manifest_path <- file.path(output_dir, "lane-b-model-surface-manifest.tsv")
  contracts_path <- file.path(output_dir, "lane-b-profile-contracts.tsv")
  worklist_path <- file.path(output_dir, "lane-b-binding-worklist.tsv")
  receipt_path <- file.path(output_dir, "lane-b-runtime-receipt.rds")
  utils::write.table(
    contracts[manifest_fields], manifest_path, sep = "\t", row.names = FALSE,
    quote = FALSE, na = ""
  )
  utils::write.table(
    contracts, contracts_path, sep = "\t", row.names = FALSE,
    quote = FALSE, na = ""
  )
  utils::write.table(
    phase18_interval_campaign_binding_worklist(contracts, evidence_path),
    worklist_path,
    sep = "\t",
    row.names = FALSE,
    quote = FALSE,
    na = ""
  )
  saveRDS(phase18_interval_campaign_runtime_receipt(source_sha, source_root), receipt_path)
  list(
    manifest = manifest_path,
    contracts = contracts_path,
    binding_worklist = worklist_path,
    runtime_receipt = receipt_path,
    source_md5 = attr(contracts, "source_md5"),
    manifest_md5 = attr(contracts, "manifest_md5"),
    pregrid_authorized = FALSE
  )
}

phase18_interval_campaign_seed_schedule <- function(contracts, n_rep = 150L, master_seed = 20260727L) {
  if (!exists("phase18_seed_table", mode = "function")) {
    stop("Source sim/R/sim_registry.R before requesting a campaign seed schedule.", call. = FALSE)
  }
  active <- phase18_assert_bound_interval_contracts(contracts)
  schedule <- phase18_seed_table(nrow(active), n_rep, master_seed)
  schedule$cell_id <- active$cell_id[schedule$cell_index]
  schedule$target_id <- active$target_id[schedule$cell_index]
  schedule$information_rung <- active$information_rung[schedule$cell_index]
  schedule$negative_control <- active$negative_control[schedule$cell_index]
  schedule$dgp_id <- active$dgp_id[schedule$cell_index]
  schedule$formula <- active$formula[schedule$cell_index]
  schedule$true_parameter_scale <- active$true_parameter_scale[schedule$cell_index]
  schedule$profile_parameter <- active$profile_parameter[schedule$cell_index]
  schedule$manifest_md5 <- attr(contracts, "manifest_md5")
  schedule$contract_md5 <- attr(contracts, "contract_md5")
  schedule[c(
    "cell_id", "target_id", "information_rung", "negative_control",
    "dgp_id", "formula", "true_parameter_scale", "profile_parameter",
    "manifest_md5", "contract_md5", "cell_index", "replicate", "seed"
  )]
}

phase18_assert_bound_interval_contracts <- function(contracts) {
  if (!is.data.frame(contracts) || nrow(contracts) < 158L) {
    stop("Every Lane-B target needs an exact integrity-checked binding before a schedule can be made.", call. = FALSE)
  }
  active <- contracts
  if (any(!active$lane_b_target)) {
    stop("Every Lane-B target needs an exact integrity-checked binding before a schedule can be made.", call. = FALSE)
  }
  expected_ids <- phase18_interval_campaign_manifest_ids(contracts)
  if (!identical(sort(unique(active$cell_id)), expected_ids)) {
    stop("Every Lane-B target needs an exact integrity-checked binding before a schedule can be made.", call. = FALSE)
  }
  required <- c(
    "dgp_id", "formula", "true_parameter_scale", "profile_parameter",
    "information_rung", "profile_channel", "target_id"
  )
  missing <- setdiff(required, names(active))
  valid_text <- length(missing) == 0L && all(vapply(
    active[required],
    function(x) is.character(x) && all(!is.na(x) & nzchar(x)),
    logical(1)
  ))
  valid_status <-
    all(active$profile_channel == "profile_likelihood") &&
    all(active$target_id == paste(active$cell_id, active$profile_parameter, sep = "::")) &&
    all(active$contract_status %in% c("bound", "negative_control_bound")) &&
    all(active$contract_status[active$negative_control] == "negative_control_bound") &&
    all(active$contract_status[!active$negative_control] == "bound")
  authentic <- identical(attr(contracts, "contract_md5"), phase18_interval_campaign_hash(contracts))
  if (!valid_text || !valid_status || !authentic) {
    stop("Every Lane-B target needs an exact integrity-checked binding before a schedule can be made.", call. = FALSE)
  }
  active
}

phase18_interval_campaign_manifest_ids <- function(contracts) {
  # The target table is intentionally one-or-more rows per frozen cell.  Its
  # distinct IDs must still be the exact 158 Lane-B rows (the 159th frozen row
  # is rho12 and remains foreign to this lane).
  ids <- sort(unique(contracts$cell_id))
  path <- tempfile("lane-b-interval-target-cell-ids-", fileext = ".txt")
  on.exit(unlink(path), add = TRUE)
  writeLines(ids, path)
  if (length(ids) != 158L ||
      !identical(unname(tools::md5sum(path)), phase18_lane_b_expected_target_cell_id_md5)) {
    stop("Bound target contracts differ from the frozen 158-row Lane-B cohort.", call. = FALSE)
  }
  ids
}

phase18_reduce_interval_campaign_attempts <- function(schedule, attempts) {
  required_schedule <- c(
    "cell_id", "target_id", "information_rung", "negative_control",
    "replicate", "seed", "manifest_md5", "contract_md5"
  )
  missing_schedule <- setdiff(required_schedule, names(schedule))
  if (length(missing_schedule) > 0L) {
    stop("`schedule` is missing: ", paste(missing_schedule, collapse = ", "), ".", call. = FALSE)
  }
  if (!is.data.frame(attempts)) {
    stop("`attempts` must be a data frame.", call. = FALSE)
  }
  required_attempts <- c(
    "cell_id", "target_id", "information_rung", "replicate",
    "seed", "manifest_md5", "contract_md5", "profile_status", "covered"
  )
  missing_attempts <- setdiff(required_attempts, names(attempts))
  if (length(missing_attempts) > 0L) {
    stop("`attempts` is missing: ", paste(missing_attempts, collapse = ", "), ".", call. = FALSE)
  }
  key <- paste(
    schedule$cell_id, schedule$target_id, schedule$information_rung,
    schedule$replicate, schedule$seed, schedule$manifest_md5, schedule$contract_md5,
    sep = "\r"
  )
  if (anyDuplicated(key)) {
    stop("`schedule` must have one row per cell/replicate attempt.", call. = FALSE)
  }
  attempt_key <- paste(
    attempts$cell_id, attempts$target_id, attempts$information_rung,
    attempts$replicate, attempts$seed, attempts$manifest_md5, attempts$contract_md5,
    sep = "\r"
  )
  if (anyDuplicated(attempt_key) || any(!attempt_key %in% key)) {
    stop("`attempts` must be a unique subset of the scheduled attempts.", call. = FALSE)
  }

  joined <- merge(
    schedule,
    attempts,
    by = c(
      "cell_id", "target_id", "information_rung", "replicate", "seed",
      "manifest_md5", "contract_md5"
    ),
    all.x = TRUE,
    sort = FALSE
  )
  joined$profile_status[is.na(joined$profile_status)] <- "not_run"
  joined$available <- joined$profile_status == "profile"
  joined$noncovering <- !joined$available | !(joined$covered %in% TRUE)
  if (any(joined$negative_control & joined$available)) {
    stop("K=12 negative-control attempts must remain unavailable or incomplete.", call. = FALSE)
  }
  split_rows <- split(joined, paste(joined$cell_id, joined$target_id, joined$information_rung, sep = "\r"))
  do.call(rbind, lapply(split_rows, function(x) {
    data.frame(
      cell_id = x$cell_id[[1L]],
      target_id = x$target_id[[1L]],
      information_rung = x$information_rung[[1L]],
      negative_control = x$negative_control[[1L]],
      all_attempts = nrow(x),
      completed_attempts = sum(x$profile_status != "not_run"),
      available_attempts = sum(x$available),
      covered_attempts = sum(x$available & x$covered %in% TRUE),
      noncovering_attempts = sum(x$noncovering),
      availability = mean(x$available),
      coverage_all_attempts = sum(x$available & x$covered %in% TRUE) / nrow(x),
      stringsAsFactors = FALSE
    )
  }))
}
